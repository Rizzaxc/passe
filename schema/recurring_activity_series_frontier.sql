-- Fixes a real bug found after schema/recurring_activity_series.sql shipped: cancelling a series'
-- latest occurrence only reliably stops the series on its *first* renewal. Once a series has >= 2
-- materialized rows, the old idempotency check (`NOT EXISTS` a row with a later `start_time`) is
-- derived from *currently existing* rows, which DELETE can undo — the moment the latest occurrence is
-- cancelled, the next-older sibling looks like the frontier again, and its own spawn gate was already
-- satisfied the instant its own (now-cancelled) successor was first spawned. The very next tick
-- silently re-spawns essentially the same slot, defeating the cancel and re-firing a fresh
-- activity_scheduled push + feed item to the whole lobby. Since decision #1 of the recurring-activities
-- feature is "cancelling stops the series entirely" with no other way to stop one, this broke the
-- feature's one control for any series 2+ weeks deep.
--
-- Fix: replace the existence check with a persistent, delete-proof marker of how far each series has
-- ever advanced — this table, bumped by a trigger, never touched by DELETE.
--
-- Also decouples fn_sweep_recurring_activities() off the shared 1-minute fn_cron_tick job onto its own
-- 2-hour cron.schedule job — a recurring occurrence only needs to land within its rolling 4-day
-- materialization window, so 60-second polling bought nothing. Matches the existing
-- expire_past_activities() precedent (schema/audit_maintenance_2026_07.sql), which already runs on its
-- own dedicated 15-minute job rather than the 1-minute tick.

CREATE TABLE public.activity_series_frontier (
    series_id      uuid PRIMARY KEY,
    frontier_start timestamptz NOT NULL
);

ALTER TABLE public.activity_series_frontier ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activity_series_frontier FROM PUBLIC, anon, authenticated;
-- No policies added — deny-all via RLS. Only SECURITY DEFINER functions/triggers touch this table;
-- it has zero legitimate client use and is never queried by the app.

-- Backfill every series that already exists (covers both the original `series_id = id` backfill and
-- any series that has since advanced via the sweep).
INSERT INTO public.activity_series_frontier (series_id, frontier_start)
SELECT series_id, MAX(start_time)
  FROM public.activity
 WHERE series_id IS NOT NULL
 GROUP BY series_id
ON CONFLICT (series_id) DO UPDATE SET frontier_start = EXCLUDED.frontier_start;

-- Keeps the marker current going forward. Fires on every path that touches a series row: a brand-new
-- series (schedule()'s series_id stamp), a one-off promoted to recurring (reschedule()'s stamp), a
-- sweep-spawned successor, and an ordinary reschedule of the still-current occurrence. Plain overwrite,
-- not GREATEST — safe because the only row ever reachable for reschedule() via the UI is the
-- current/future one (lobbyUpcomingActivitiesControllerProvider only surfaces start_time > now() rows),
-- so an UPDATE here is always a legitimate move of the live representative, never a stale historical
-- row. DELETE (the cancel path) never fires this trigger — that immutability-under-deletion is exactly
-- what makes the marker trustworthy.
CREATE OR REPLACE FUNCTION public.fn_bump_series_frontier()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    IF NEW.series_id IS NULL THEN
        RETURN NEW;
    END IF;
    INSERT INTO public.activity_series_frontier (series_id, frontier_start)
    VALUES (NEW.series_id, NEW.start_time)
    ON CONFLICT (series_id) DO UPDATE SET frontier_start = EXCLUDED.frontier_start;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activity_series_frontier_bump ON public.activity;
CREATE TRIGGER activity_series_frontier_bump
    AFTER INSERT OR UPDATE OF series_id, start_time ON public.activity
    FOR EACH ROW WHEN (NEW.series_id IS NOT NULL)
    EXECUTE FUNCTION public.fn_bump_series_frontier();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_sweep_recurring_activities(): swap the idempotency predicate.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Same body as schema/recurring_activity_series.sql, only the loop's WHERE clause changes: "no later
-- sibling currently exists" -> "I am still exactly the frontier". Walking the bug scenario through the
-- fix: week3 spawns -> frontier advances to week3's start. Captain cancels week3 -> frontier STAYS at
-- week3's start (delete doesn't touch it). Next tick looks at week2: week2.start_time = frontier_start?
-- No — frontier is still parked at week3's start, strictly greater. Week2 is correctly, permanently
-- refused. The series stays cancelled.
CREATE OR REPLACE FUNCTION public.fn_sweep_recurring_activities()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    r           record;
    v_new_id    uuid;
    v_new_start timestamptz;
    v_new_end   timestamptz;
    v_wd        text;
    v_fields    jsonb;
BEGIN
    FOR r IN
        SELECT a.*
          FROM public.activity a
         WHERE a.series_id IS NOT NULL
           AND a.recurrence_day_of_week IS NOT NULL
           AND a.end_time IS NOT NULL
           AND a.end_time < now()
           AND now() >= (a.start_time + interval '7 days' - interval '4 days')
           AND a.start_time = (
               SELECT f.frontier_start FROM public.activity_series_frontier f
                WHERE f.series_id = a.series_id)
    LOOP
        v_new_start := r.start_time + interval '7 days';
        v_new_end   := r.end_time + interval '7 days';

        -- Per-occurrence, not template-level: coach_booking_id,
        -- referee_booking_id, challenge_id, manager_confirmed_at are
        -- deliberately NOT copied onto the new row.
        INSERT INTO public.activity (
            user_id, sport_id, lobby_id, start_time, end_time, location_id,
            confirmation_threshold, confirmation_deadline, recurrence_day_of_week,
            cost_type, cost_amount, series_id
        ) VALUES (
            r.user_id, r.sport_id, r.lobby_id, v_new_start, v_new_end, r.location_id,
            r.confirmation_threshold,
            CASE WHEN r.confirmation_deadline IS NULL THEN NULL
                 ELSE r.confirmation_deadline + interval '7 days' END,
            r.recurrence_day_of_week, r.cost_type, r.cost_amount, r.series_id
        )
        RETURNING id INTO v_new_id;

        -- Mirrors ScheduleActivityController.schedule()'s feed item shape
        -- (lib/manage_tab/lobby_section/schedule_activity_controller.dart)
        -- so an auto-spawned occurrence reads identically to a manually
        -- scheduled one. The activity_scheduled_emit trigger on `activity`
        -- (schema/activity_scheduled_notify.sql) already fires on this
        -- INSERT regardless of source, so no notification call is needed
        -- here — same push + feed item as manual scheduling, by design.
        v_wd := (ARRAY['T2','T3','T4','T5','T6','T7','CN'])[
            EXTRACT(ISODOW FROM v_new_start AT TIME ZONE 'Asia/Ho_Chi_Minh')::int];

        v_fields := jsonb_build_array(
            jsonb_build_array('Ngày', v_wd || ', ' ||
                to_char(v_new_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'FMDD/FMMM/YYYY')),
            jsonb_build_array('Giờ',
                to_char(v_new_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI') || ' - ' ||
                to_char(v_new_end AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI')),
            jsonb_build_array('Lặp lại', 'Hằng tuần')
        );
        IF r.cost_type IS NOT NULL AND r.cost_amount IS NOT NULL THEN
            v_fields := v_fields || jsonb_build_array(jsonb_build_array('Chi phí',
                to_char(r.cost_amount, 'FM999999999990') ||
                CASE WHEN r.cost_type = 'per_pax' THEN ' đ/người' ELSE ' đ (tổng)' END));
        END IF;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (
            r.lobby_id, r.user_id, 'update',
            jsonb_build_object(
                'title', 'Lên lịch buổi chơi',
                'kind',  'scheduled',
                'tone',  'blue',
                'fields', v_fields
            )
        );
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_sweep_recurring_activities() FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_cron_tick(): drop the recurring sweep call — it now runs on its own job below.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_cron_tick()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    PERFORM public.fn_sweep_challenges();
    PERFORM public.fn_process_reminders();
    IF EXISTS (SELECT 1 FROM public.notification_outbox
                WHERE status IN ('pending', 'sending')) THEN
        PERFORM public.fn_invoke_send_push();
    END IF;
END;
$$;

-- Dedicated 2-hour job, same pattern as the existing 'expire_past_activities' job
-- (schema/audit_maintenance_2026_07.sql). 2 hours is comfortably inside the 4-day rolling
-- materialization window, so no legitimate spawn is ever at risk of landing late.
select cron.schedule(
    'sweep-recurring-activities',
    '0 */2 * * *',
    $$ select public.fn_sweep_recurring_activities(); $$
);

-- ─────────────────────────────────────────────────────────────────────────────
-- expire_past_activities(): align its exclusion to the same frontier predicate.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- It previously protected a recurring row via the same flawed "later sibling currently exists" check.
-- Once the sweep bug above is fixed, a series' correctly-never-resurrected final occurrence would
-- otherwise never gain a "later sibling" again and would stay wrongly protected forever under the old
-- predicate. Align to frontier-equality instead: protect a row only while it IS the frontier (still
-- eligible for a successor); once the series has moved past it or is truly done, normal expiry rules
-- apply.
CREATE OR REPLACE FUNCTION public.expire_past_activities()
RETURNS int LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_uid   uuid := auth.uid();
  v_count int;
BEGIN
  DELETE FROM public.activity a
  WHERE a.lobby_id IS NOT NULL
    AND a.start_time < now()
    AND NOT (
      a.series_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.activity_series_frontier f
         WHERE f.series_id = a.series_id AND f.frontier_start = a.start_time
      )
    )
    AND NOT public.activity_is_confirmed(a.id)
    AND NOT EXISTS (
      SELECT 1 FROM public.lobby_match lm WHERE lm.activity_id = a.id
    )
    AND EXISTS (
      SELECT 1 FROM public.lobby_member m
      WHERE m.lobby_id = a.lobby_id AND m.user_id = v_uid
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.expire_past_activities() TO authenticated;
