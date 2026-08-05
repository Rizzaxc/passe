-- ============================================================================
-- challenge_flow_enums.sql — Part A of the challenger-flow build.
--
-- Postgres cannot use an enum value in the same transaction that adds it, so
-- every ADD VALUE lives here as its own migration and `challenge_flow.sql`
-- (Part B) consumes them. Same two-step pattern as `lobby_challenge.sql`.
--
-- Apply this FIRST, then `challenge_flow.sql`.
-- ============================================================================

-- ─── Match results gain a draw ──────────────────────────────────────────────
-- win/loss/practice had no way to record a level scoreline, which soccer and
-- basketball challenge matches need — and the rating engine needs an S = 0.5.
ALTER TYPE public.lobby_match_result ADD VALUE IF NOT EXISTS 'draw';

-- ─── Challenge lifecycle gains its terminal states ──────────────────────────
-- `accepted` was the last state a challenge could reach, so accepted rows
-- accumulated in the challenges sheet forever with no notion of the match
-- actually being locked in, played, or having fallen through.
--   scheduled — both sides hit their RSVP threshold and a manager confirmed
--   played    — a result was recorded (or the match passed unrefereed)
--   lapsed    — a side never confirmed by the deadline; both activities voided
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'scheduled';
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'played';
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'lapsed';

-- ─── Notification kinds ─────────────────────────────────────────────────────
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'challenge_lapsed';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'match_result_recorded';
-- Added in a follow-up pass once quorum-only `activity_confirmed` was found to
-- be a misleading "it's locked in" signal for a challenge activity (quorum is
-- only half of official — see fn_emit_activity_confirmed's challenge_id guard
-- in challenge_flow.sql). This is the real "both sides confirmed" signal.
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'challenge_scheduled';
