-- Recurring activities as a materialized series.
--
-- Previously a "recurring" activity was a single row (recurrence_day_of_week
-- set) whose next occurrence was resolved virtually, client-side, from a
-- stale start_time/end_time anchor. That meant one shared RSVP for every
-- week, a cancel that killed the whole series in one DELETE by accident of
-- implementation (not by design), and a second, independently-reimplemented
-- virtual expander in the Manage▸Schedule calendar.
--
-- Now: each week is its own real `activity` row (own id, own RSVP, own
-- cancel scope, own feed item), grouped by a plain opaque `series_id` tag —
-- deliberately NOT a self-referencing FK (an `id = its own id` FK would
-- ON DELETE SET NULL every sibling the moment the first row is ever
-- deleted). A cron sweep materializes the next occurrence once the current
-- one has ended and no successor exists yet, starting 4 days before the
-- next occurrence's start time.
--
-- Cancelling an occurrence stops the series entirely (no soft-cancel, no
-- "stop repeating" action) — this falls out for free, since the sweep can
-- only spawn a successor from a row that still exists.

ALTER TABLE public.activity ADD COLUMN IF NOT EXISTS series_id uuid;

CREATE INDEX IF NOT EXISTS idx_activity_series_id
    ON public.activity (series_id)
    WHERE series_id IS NOT NULL;

-- Backfill: every existing recurring row becomes a valid series-of-one that
-- the sweep below can extend.
UPDATE public.activity
   SET series_id = id
 WHERE recurrence_day_of_week IS NOT NULL
   AND series_id IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- Sweep: materialize the next occurrence of each due series.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Idempotency: a plain NOT EXISTS guard (no row locking) — same style as
-- fn_sweep_challenges. The row with the latest start_time in a series is
-- definitionally the only one that can ever match, so double-materializing
-- a slot inside a single tick isn't possible.
--
-- Known residual limitation (flagged, not blocking): this NOT EXISTS-only
-- check is exact for a series' first renewal, but once a series has >= 2
-- rows, cancelling the current (latest-spawned) occurrence makes the
-- next-older sibling the new "no-later-sibling" frontier — and because
-- every successor's start is a fixed predecessor.start + 7 days, that older
-- row's own spawn gate is, by construction, already satisfied the instant
-- its own successor (the one just cancelled) had itself been spawned. The
-- next tick will silently re-spawn essentially the same slot, defeating the
-- cancel for any series past its first week. A full fix needs state that
-- survives the deleted row (e.g. a tiny
-- activity_series_frontier(series_id, frontier_start) side table,
-- monotonically advanced, never rewound) — filed as a fast-follow.
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
           AND NOT EXISTS (
               SELECT 1 FROM public.activity nxt
                WHERE nxt.series_id = a.series_id AND nxt.start_time > a.start_time)
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

-- Hook into the existing 1-minute tick rather than adding a second cron job
-- (last defined in schema/challenge_flow.sql).
CREATE OR REPLACE FUNCTION public.fn_cron_tick()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    PERFORM public.fn_sweep_challenges();
    PERFORM public.fn_sweep_recurring_activities();
    PERFORM public.fn_process_reminders();
    IF EXISTS (SELECT 1 FROM public.notification_outbox
                WHERE status IN ('pending', 'sending')) THEN
        PERFORM public.fn_invoke_send_push();
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- expire_past_activities(): narrow the recurring exclusion.
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Previously every recurring row (recurrence_day_of_week IS NOT NULL) was
-- blanket-excluded from this client-triggered ("on lobby list load") sweep.
-- That's no longer earned now that each week is a real, independent row —
-- but removing the exclusion outright would reopen a race: this
-- unpredictably-cadenced sweep could delete an unconfirmed past occurrence
-- *before* the once-a-minute cron sweep gets a chance to spawn its
-- successor, silently killing a series with no explicit cancel ever
-- happening. Fix: protect a row only until its own successor exists — once
-- a successor is materialized, the row is safely historical and expires
-- normally like any other past activity.
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
      AND NOT EXISTS (
        SELECT 1 FROM public.activity nxt
         WHERE nxt.series_id = a.series_id AND nxt.start_time > a.start_time
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
