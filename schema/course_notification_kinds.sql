-- Enum prelude for course_attendance_and_editing.sql — apply first, in its
-- own transaction (a new enum value can't be used in the transaction that
-- adds it).
--
-- The target-reached sweep and the no-students prompt both reused the
-- `course_ended` kind, so a coach got "course ended"-kind pushes (and
-- notification-centre rows) for courses that were still running. Each gets
-- its own kind now.
-- Needs to be applied to the live Supabase project.

ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_target_reached';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'course_no_students';
