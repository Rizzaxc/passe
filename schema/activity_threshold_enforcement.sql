-- ============================================================================
-- activity_threshold_enforcement.sql — deadline/kickoff enforcement for
-- confirmation_threshold + confirmation_deadline on plain lobby activities.
--
-- Requires activity_threshold_enforcement_enums.sql applied first (new
-- notification_kind values consumed below).
--
-- Two independent mechanisms, both riding the existing 1-minute
-- fn_cron_tick (no new cron job):
--
--  1. Deadline "at risk" prompt — only when confirmation_deadline is set.
--     Once the deadline passes on an activity still under threshold,
--     at_risk_notified_at is stamped (once) and two notifications go out:
--     the organizer (activity.user_id — override-confirm or cancel) and
--     every "maybe"/never-responded member (commit going/out). From that
--     moment, ALL direct writes to activity_confirmation for that activity
--     are frozen (see the RLS policies below) — the only path forward is
--     the two RPCs in this file. Members who are already `going`/`out`
--     freeze too; a going member can no longer back out except via the
--     organizer cancelling.
--  2. Kickoff auto-cancel — general, deadline or not. Any threshold-set
--     activity still under threshold at start_time is hard-deleted (no
--     activity/match row persists), with a feed item + push explaining why
--     to the organizer and everyone who was `going`.
--
-- Scope is strictly plain lobby activities (lobby_id IS NOT NULL AND
-- challenge_id IS NULL). Challenge activities already have their own
-- deadline-driven resolution on the same confirmation_deadline column
-- (manager-confirmation based — schema/challenge_flow.sql's
-- fn_sweep_challenges part (b)); running both against the same column would
-- race. Course activities use coach-approval, not RSVP quorum.
--
-- Apply with execute_sql / apply_migration. Idempotent.
-- ============================================================================


-- ─── 1. New activity columns ────────────────────────────────────────────────

ALTER TABLE public.activity
    ADD COLUMN IF NOT EXISTS at_risk_notified_at timestamptz,
    ADD COLUMN IF NOT EXISTS threshold_override_at timestamptz;

COMMENT ON COLUMN public.activity.at_risk_notified_at IS
  'Set once by fn_sweep_activity_thresholds when confirmation_deadline passes while still under confirmation_threshold. Doubles as the once-only notify flag and the sticky post-deadline RLS freeze on activity_confirmation (see the policies below).';
COMMENT ON COLUMN public.activity.threshold_override_at IS
  'Set by resolve_at_risk_activity_organizer(''confirm''). Once set, activity_is_confirmed() treats the activity as permanently confirmed regardless of going count — same footing as naturally reaching quorum.';


-- ─── 2. activity_is_confirmed(): override short-circuits true ─────────────

CREATE OR REPLACE FUNCTION public.activity_is_confirmed(p_activity_id uuid)
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_threshold int;
    v_override  timestamptz;
    v_count     int;
BEGIN
    SELECT a.confirmation_threshold, a.threshold_override_at
        INTO v_threshold, v_override
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN RETURN false; END IF;
    IF v_override IS NOT NULL THEN RETURN true; END IF;
    IF v_threshold IS NULL THEN RETURN true; END IF;

    SELECT COUNT(*) INTO v_count
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND attendance = 'going';

    RETURN v_count >= v_threshold;
END;
$$;


-- ─── 3. activity_confirmation_status(): expose the freeze flag ────────────
-- Adds `deadline_locked` so the client can tell this apart from the existing
-- quorum-only lock and show the right copy. Also switches activity_confirmed
-- to call activity_is_confirmed() directly instead of duplicating the
-- threshold/count comparison inline, so the override case is honoured here
-- too (the old inline copy would report unconfirmed even after an
-- organizer override).

DROP FUNCTION IF EXISTS public.activity_confirmation_status(uuid);
CREATE FUNCTION public.activity_confirmation_status(p_activity_id uuid)
RETURNS TABLE(
    confirmed_count integer,   -- "going" only
    maybe_count integer,
    threshold integer,
    my_attendance text,        -- 'going' | 'maybe' | 'out' | NULL (no response)
    activity_confirmed boolean,
    deadline_locked boolean    -- at_risk_notified_at IS NOT NULL
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_threshold int;
    v_going     int;
    v_maybe     int;
    v_mine      text;
    v_locked    boolean;
BEGIN
    SELECT a.confirmation_threshold, (a.at_risk_notified_at IS NOT NULL)
        INTO v_threshold, v_locked
        FROM public.activity a WHERE a.id = p_activity_id;

    SELECT COUNT(*) FILTER (WHERE attendance = 'going')::int,
           COUNT(*) FILTER (WHERE attendance = 'maybe')::int
        INTO v_going, v_maybe
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id;

    SELECT attendance::text INTO v_mine
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND user_id = auth.uid();

    RETURN QUERY SELECT
        COALESCE(v_going, 0),
        COALESCE(v_maybe, 0),
        v_threshold,
        v_mine,
        public.activity_is_confirmed(p_activity_id),
        COALESCE(v_locked, false);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.activity_confirmation_status(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.activity_confirmation_status(uuid) TO authenticated;


-- ─── 4. RLS: freeze all activity_confirmation writes once at-risk-notified ──
-- Independent, additionally-AND'd alongside the existing "going + confirmed"
-- lock (schema/activity_confirmation_lock_after_confirmed.sql — that lock's
-- own logic is unchanged, it still applies via activity_is_confirmed()).
-- This one is sticky (keyed off at_risk_notified_at, not a live threshold
-- recheck, so it stays locked through resolution) and covers every
-- attendance state, not just going. Resolution only happens through
-- resolve_at_risk_activity_rsvp / resolve_at_risk_activity_organizer below,
-- both SECURITY DEFINER and therefore unaffected by these policies.

DROP POLICY IF EXISTS "Members can confirm their own attendance" ON public.activity_confirmation;
CREATE POLICY "Members can confirm their own attendance"
    ON public.activity_confirmation
    FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
              AND a.at_risk_notified_at IS NULL
        )
    );

DROP POLICY IF EXISTS "Members can change their own attendance" ON public.activity_confirmation;
CREATE POLICY "Members can change their own attendance"
    ON public.activity_confirmation
    FOR UPDATE
    TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        AND NOT (
            attendance = 'going'
            AND public.activity_is_confirmed(activity_id)
        )
        AND NOT EXISTS (
            SELECT 1 FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.at_risk_notified_at IS NOT NULL
        )
    )
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );

DROP POLICY IF EXISTS "Members can retract their own confirmation" ON public.activity_confirmation;
CREATE POLICY "Members can retract their own confirmation"
    ON public.activity_confirmation
    FOR DELETE
    TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        AND NOT (
            attendance = 'going'
            AND public.activity_is_confirmed(activity_id)
        )
        AND NOT EXISTS (
            SELECT 1 FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.at_risk_notified_at IS NOT NULL
        )
    );


-- ─── 5. RPC: "maybe" / never-responded member commits going or out ────────

CREATE OR REPLACE FUNCTION public.resolve_at_risk_activity_rsvp(
    p_activity_id uuid,
    p_attendance  text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid      uuid := auth.uid();
    v_lobby_id uuid;
    v_at_risk  timestamptz;
    v_override timestamptz;
    v_current  text;
BEGIN
    IF p_attendance NOT IN ('going', 'out') THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: invalid attendance %', p_attendance;
    END IF;

    SELECT a.lobby_id, a.at_risk_notified_at, a.threshold_override_at
        INTO v_lobby_id, v_at_risk, v_override
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: activity not found';
    END IF;
    IF v_at_risk IS NULL OR v_override IS NOT NULL THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: activity is not awaiting resolution';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = v_lobby_id AND lm.user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: caller is not a lobby member';
    END IF;

    SELECT attendance::text INTO v_current
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND user_id = v_uid;
    IF v_current = 'out' THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_rsvp: already opted out';
    END IF;

    INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
    VALUES (p_activity_id, v_uid, p_attendance::public.activity_attendance)
    ON CONFLICT (activity_id, user_id) DO UPDATE SET attendance = excluded.attendance;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_at_risk_activity_rsvp(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_at_risk_activity_rsvp(uuid, text) TO authenticated;


-- ─── 6. RPC: organizer override-confirms or cancels ────────────────────────
-- Authorization is lobby_can_manage() (any captain/coordinator), matching
-- every other manage-tier RPC in the codebase — the notification above only
-- targets the specific scheduler (activity.user_id), but if they're
-- unreachable another coordinator can still resolve this.

CREATE OR REPLACE FUNCTION public.resolve_at_risk_activity_organizer(
    p_activity_id uuid,
    p_action      text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid              uuid := auth.uid();
    v_lobby_id         uuid;
    v_lobby_name       text;
    v_at_risk          timestamptz;
    v_override         timestamptz;
    v_going_recipients uuid[];
BEGIN
    IF p_action NOT IN ('confirm', 'cancel') THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: invalid action %', p_action;
    END IF;

    SELECT a.lobby_id, a.at_risk_notified_at, a.threshold_override_at
        INTO v_lobby_id, v_at_risk, v_override
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: activity not found';
    END IF;
    IF v_at_risk IS NULL OR v_override IS NOT NULL THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: activity is not awaiting resolution';
    END IF;
    IF NOT public.lobby_can_manage(v_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'resolve_at_risk_activity_organizer: caller cannot manage this lobby';
    END IF;

    SELECT name INTO v_lobby_name FROM public.lobby WHERE id = v_lobby_id;

    IF p_action = 'confirm' THEN
        UPDATE public.activity SET threshold_override_at = now() WHERE id = p_activity_id;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (v_lobby_id, v_uid, 'update',
            jsonb_build_object(
                'title', 'Đã xác nhận dù chưa đủ người',
                'kind',  'threshold_confirmed',
                'tone',  'blue',
                'fields', jsonb_build_array()));
    ELSE
        SELECT array_agg(DISTINCT ac.user_id) INTO v_going_recipients
            FROM public.activity_confirmation ac
            WHERE ac.activity_id = p_activity_id AND ac.attendance = 'going';

        DELETE FROM public.activity WHERE id = p_activity_id;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (v_lobby_id, v_uid, 'update',
            jsonb_build_object(
                'title', 'Đã hủy buổi chơi',
                'kind',  'cancelled',
                'tone',  'crimson',
                'fields', jsonb_build_array()));

        IF v_going_recipients IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'activity_cancelled_low_turnout',
                v_going_recipients,
                'Buổi chơi đã bị hủy',
                COALESCE(v_lobby_name, 'Lobby') || ' đã hủy buổi chơi do không đủ người xác nhận',
                jsonb_build_object('lobby_id', v_lobby_id::text));
        END IF;
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_at_risk_activity_organizer(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.resolve_at_risk_activity_organizer(uuid, text) TO authenticated;


-- ─── 7. Sweep: at-risk prompt (once) + kickoff auto-cancel ─────────────────

CREATE OR REPLACE FUNCTION public.fn_sweep_activity_thresholds()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    r            record;
    v_lobby_name text;
    v_recipients uuid[];
BEGIN
    -- (a) Deadline passed, still under threshold, not yet notified, and not
    -- ALSO already past kickoff (that case is handled by pass (b) below —
    -- no point prompting for an activity that's being auto-cancelled in the
    -- same tick, e.g. after the cron job missed a beat).
    FOR r IN
        SELECT a.id, a.user_id AS organizer_id, a.lobby_id
          FROM public.activity a
         WHERE a.lobby_id IS NOT NULL
           AND a.challenge_id IS NULL
           AND a.confirmation_threshold IS NOT NULL
           AND a.confirmation_deadline IS NOT NULL
           AND a.confirmation_deadline <= now()
           AND a.start_time > now()
           AND a.at_risk_notified_at IS NULL
           AND NOT public.activity_is_confirmed(a.id)
    LOOP
        UPDATE public.activity SET at_risk_notified_at = now() WHERE id = r.id;

        SELECT l.name INTO v_lobby_name FROM public.lobby l WHERE l.id = r.lobby_id;

        PERFORM public.fn_enqueue_notification(
            'activity_at_risk_organizer',
            ARRAY[r.organizer_id],
            'Buổi chơi chưa đủ người',
            COALESCE(v_lobby_name, 'Lobby') || ' chưa đủ xác nhận trước hạn chót — xác nhận hoặc hủy',
            jsonb_build_object('target_id', r.id::text, 'lobby_id', r.lobby_id::text));

        -- "maybe" holders and never-responded members (no row at all) — NOT
        -- "out" (already decided), NOT "going" (nothing for them to do), and
        -- NOT the organizer (they already got their own organizer-tier
        -- notification above — as a lobby member who never RSVP'd on their
        -- own activity they'd otherwise also match "never-responded" here).
        SELECT array_agg(DISTINCT lm.user_id) INTO v_recipients
            FROM public.lobby_member lm
            LEFT JOIN public.activity_confirmation ac
                   ON ac.activity_id = r.id AND ac.user_id = lm.user_id
            WHERE lm.lobby_id = r.lobby_id
              AND lm.user_id <> r.organizer_id
              AND (ac.attendance IS NULL OR ac.attendance = 'maybe');

        IF v_recipients IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'activity_at_risk_member',
                v_recipients,
                'Xác nhận tham gia?',
                COALESCE(v_lobby_name, 'Lobby') || ' cần thêm người xác nhận trước giờ chơi',
                jsonb_build_object('target_id', r.id::text, 'lobby_id', r.lobby_id::text));
        END IF;
    END LOOP;

    -- (b) Kickoff passed, still unconfirmed — covers both an activity with
    -- no deadline at all, and an at-risk activity nobody resolved in time.
    -- Hard-delete (no activity/match record persists), but leave a feed
    -- item + push explaining why.
    FOR r IN
        SELECT a.id, a.user_id AS organizer_id, a.lobby_id
          FROM public.activity a
         WHERE a.lobby_id IS NOT NULL
           AND a.challenge_id IS NULL
           AND a.confirmation_threshold IS NOT NULL
           AND a.start_time <= now()
           AND NOT public.activity_is_confirmed(a.id)
    LOOP
        SELECT l.name INTO v_lobby_name FROM public.lobby l WHERE l.id = r.lobby_id;

        SELECT array_agg(DISTINCT u) INTO v_recipients
            FROM unnest(
                ARRAY[r.organizer_id] || COALESCE((
                    SELECT array_agg(ac.user_id)
                    FROM public.activity_confirmation ac
                    WHERE ac.activity_id = r.id AND ac.attendance = 'going'
                ), ARRAY[]::uuid[])
            ) AS u;

        DELETE FROM public.activity WHERE id = r.id;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (r.lobby_id, r.organizer_id, 'update',
            jsonb_build_object(
                'title', 'Đã hủy buổi chơi',
                'kind',  'cancelled',
                'tone',  'crimson',
                'fields', jsonb_build_array(
                    jsonb_build_array('Lý do', 'Không đủ người xác nhận trước giờ chơi'))));

        PERFORM public.fn_enqueue_notification(
            'activity_cancelled_low_turnout',
            v_recipients,
            'Buổi chơi đã bị hủy',
            COALESCE(v_lobby_name, 'Lobby') || ' đã tự động hủy do không đủ người xác nhận',
            jsonb_build_object('lobby_id', r.lobby_id::text));
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_sweep_activity_thresholds() FROM PUBLIC, anon, authenticated;


-- ─── 8. Wire into the existing 1-minute cron tick ──────────────────────────
-- Full body carried forward from the live definition (schema/course.sql's
-- redefinition, the latest before this one) plus the new sweep call.

CREATE OR REPLACE FUNCTION public.fn_cron_tick()
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  PERFORM public.fn_sweep_challenges();
  PERFORM public.fn_sweep_activity_thresholds();
  PERFORM public.fn_sweep_activity_payment_requests();
  PERFORM public.fn_sweep_freeplay();
  PERFORM public.fn_sweep_course_targets();
  PERFORM public.fn_process_reminders();
  IF EXISTS (SELECT 1 FROM public.notification_outbox WHERE status IN ('pending','sending')) THEN
    PERFORM public.fn_invoke_send_push();
  END IF;
END;
$$;


-- ─── 9. Rollout allowlist ───────────────────────────────────────────────────

INSERT INTO public.enabled_notification_kind (kind, enabled) VALUES
    ('activity_at_risk_organizer',    true),
    ('activity_at_risk_member',       true),
    ('activity_cancelled_low_turnout', true)
ON CONFLICT (kind) DO NOTHING;
