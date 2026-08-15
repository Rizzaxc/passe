-- ============================================================================
-- activity_threshold_enforcement_enums.sql — Part A of the lobby
-- activity threshold/deadline enforcement feature.
--
-- Postgres cannot use an enum value in the same transaction that adds it, so
-- every ADD VALUE lives here and activity_threshold_enforcement.sql (Part B)
-- consumes them. Same two-step pattern as course_enums.sql /
-- challenge_flow_enums.sql. Apply this file first.
-- ============================================================================

ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'activity_at_risk_organizer';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'activity_at_risk_member';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'activity_cancelled_low_turnout';
