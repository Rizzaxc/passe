-- ============================================================================
-- course_enums.sql — Part A of the coaching-course build.
--
-- Postgres cannot use an enum value in the same transaction that adds it, so
-- every ADD VALUE lives here and `course.sql` (Part B) consumes them. Same
-- two-step pattern as `challenge_flow_enums.sql`.
--
-- Apply order for the whole rework:
--   messaging.sql → messaging_realtime.sql → freeplay_conversation_migration.sql
--   → course_enums.sql → course.sql → referee_booking_rename.sql
-- ============================================================================

-- ─── New enum types ─────────────────────────────────────────────────────────
-- These are CREATE TYPE (not ADD VALUE), so they could live in course.sql —
-- they're here to keep the whole vocabulary in one readable place.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='course_status') THEN
    CREATE TYPE public.course_status AS ENUM ('active','ended');
  END IF;

  -- `inquiring` is the pre-enrollment state: someone messaged a coach and no
  -- offer has been accepted yet. It is a real membership (they can chat) but
  -- not an enrollment, so it does not consume the one-coach-per-sport slot.
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='course_member_status') THEN
    CREATE TYPE public.course_member_status AS ENUM
      ('inquiring','enrolled','left','removed');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='course_offer_status') THEN
    CREATE TYPE public.course_offer_status AS ENUM
      ('pending','accepted','declined','withdrawn');
  END IF;

  -- Coach-created activities are born `approved`; student proposals start
  -- `pending` and only the coach moves them.
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='activity_proposal_status') THEN
    CREATE TYPE public.activity_proposal_status AS ENUM
      ('pending','approved','rejected','withdrawn');
  END IF;
END$$;

-- ─── Notification kinds ─────────────────────────────────────────────────────
-- `course_message` is consumed by fn_notify_new_message, which messaging.sql
-- deliberately left freeplay-only for exactly this reason.
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_message';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_enrollment_offer';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_enrollment_accepted';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_activity_proposed';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_activity_approved';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_activity_changed';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_session_report';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_ended';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_member_removed';
