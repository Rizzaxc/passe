-- Revoke direct client access to SECURITY DEFINER helpers that were never
-- meant to be called from outside another SECURITY DEFINER function's body.
-- Flagged by the Supabase security advisor as executable by anon/authenticated;
-- confirmed exploitable, not false positives (unlike the `RETURNS trigger`
-- functions the advisor also flags, which Postgres already refuses to invoke
-- outside trigger context).
--
-- Every one of these is only ever called via `PERFORM public.fn_x(...)` from
-- inside another SECURITY DEFINER function, which executes as that function's
-- owner (postgres) — so revoking anon/authenticated/PUBLIC here doesn't touch
-- any real call path. service_role and postgres already have EXECUTE and are
-- untouched.
--
-- fn_enqueue_notification / fn_claim_outbox: no auth.uid() check at all.
-- Directly callable, this let any client inject arbitrary push/in-app
-- notifications to any recipient (fn_enqueue_notification), or read every
-- other user's queued notification title/body/data and corrupt the outbox's
-- retry bookkeeping (fn_claim_outbox).
--
-- _achievement_current_value / _vitality_daily_load_series / _vitality_ewma:
-- the `_`-prefixed naming signals "internal helper", but Postgres/PostgREST
-- don't honor naming conventions, only grants. Each takes an arbitrary
-- p_user_id with no ownership check, so calling them directly (bypassing the
-- achievement_progress / evaluate_achievements / evaluate_vitality_score RPCs
-- that DO check `p_user_id = auth.uid()`) leaked raw health and social
-- metrics — steps, sleep minutes, calories, workout counts, post/reaction
-- counts, daily training load — for any user by uuid.

REVOKE EXECUTE ON FUNCTION public.fn_enqueue_notification(notification_kind, uuid[], text, text, jsonb)
    FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.fn_claim_outbox(integer, integer, text)
    FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public._achievement_current_value(uuid, jsonb, timestamp with time zone)
    FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public._vitality_daily_load_series(uuid, date, date)
    FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public._vitality_ewma(uuid, date, integer)
    FROM PUBLIC, anon, authenticated;
