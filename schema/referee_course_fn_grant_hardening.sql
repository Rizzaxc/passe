-- Grant hardening for the functions the coaching rework created.
-- Apply AFTER referee_booking_rename.sql and coach_booking_fallout.sql.
--
-- The referee_* functions were created under NEW names by the rename, so they
-- got PostgreSQL's default EXECUTE-to-PUBLIC rather than inheriting the
-- hardened grants their professional_booking_* predecessors carried (see
-- schema/security_definer_grant_hardening.sql) — Supabase's own security
-- advisor flagged all 16 as anon-executable SECURITY DEFINER functions.
--
-- Restores the project's posture:
--   * trigger functions: executable by nobody (they run as the table owner)
--   * client RPCs: anon revoked, authenticated granted
--
-- Idempotent / re-runnable.

DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS signature
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prorettype = 'trigger'::regtype
      AND p.proname IN (
        'fn_activity_attachment_role_check','fn_complete_referee_booking_on_match',
        'fn_course_member_denormalise','fn_course_review_rollup',
        'fn_guard_referee_booking_review','fn_notify_referee_booking_created',
        'fn_notify_referee_booking_status_changed','fn_referee_booking_role_check',
        'lobby_match_referee_role_check','referee_booking_review_updated_trigger_fn',
        'fn_broadcast_message')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated', r.signature);
  END LOOP;

  -- Client-callable referee RPCs: authenticated only. They self-guard on
  -- auth.uid() as well, but anon has no business reaching them at all.
  FOR r IN
    SELECT p.oid::regprocedure AS signature
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'request_referee_booking','accept_referee_booking','reject_referee_booking',
        'cancel_referee_booking','complete_referee_booking','referee_booking_conflicts')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END $$;
