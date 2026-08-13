-- Part F of the coaching rework: three permission bugs live testing found
-- (all downstream of, but independent from, the interaction rework in
-- course_inquiry_notify.sql).
--
-- 1. `propose_course_activity` gated on `fn_is_course_member`, which only
--    checks `left_at IS NULL` — true for a merely-`inquiring` student, not
--    just an `enrolled` one. An inquiring, unenrolled student could schedule
--    a session. `fn_is_course_member` itself is correct and stays as-is
--    (course_detail_data's viewing gate legitimately wants "any live member,
--    inquiring included" — an inquirer needs to see the coach's course
--    before deciding to enroll). Scheduling gets its own, stricter helper.
--
-- 2. `activity_confirmation`'s RLS policies (schema/passe.sql, predating
--    courses) are all scoped to `a.lobby_id IN get_my_lobby_ids()`. A course
--    activity has `lobby_id IS NULL`, so none of the four policies ever
--    match one — RSVP on a course session was silently blocked by RLS the
--    whole time, found by audit while fixing #1, not from a report.
--
-- 3. `ConversationController._load()`: on the very first load of a
--    message-less thread, `conversation_data` legitimately returns zero
--    rows, so there's no row to read `can_write` off. The client fell back
--    to `state.value?.canWrite ?? false` — on a *first* load `state.value`
--    is null, so a brand-new empty thread defaulted to permanently
--    read-only, with no way to break out of it since the composer that
--    would let you send is the very thing that's disabled. Under the
--    reworked flow a course conversation is never empty (message_coach
--    inserts the first message in the same transaction that creates it),
--    but freeplay conversations legitimately can be (a chat opened before
--    either side has typed) — this is a real, live bug independent of the
--    course rework.
--
-- Needs to be applied to the live Supabase project.

-- ── 1. Scheduling requires enrollment, not just live membership ────────────

CREATE OR REPLACE FUNCTION public.fn_is_enrolled_course_member(
  p_course_id uuid, p_uid uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid
      AND m.status = 'enrolled' AND m.left_at IS NULL
  );
$$;
REVOKE ALL ON FUNCTION public.fn_is_enrolled_course_member(uuid,uuid)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.propose_course_activity(
  p_course_id uuid, p_start timestamptz, p_end timestamptz,
  p_location_id uuid DEFAULT NULL, p_note text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_is_coach boolean; v_sport bigint;
        v_coach uuid; v_username text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RAISE EXCEPTION 'course is not active';
  END IF;
  v_is_coach := public.fn_is_course_coach(p_course_id, v_uid);
  IF NOT v_is_coach AND NOT public.fn_is_enrolled_course_member(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'course access required';
  END IF;
  IF p_end IS NOT NULL AND p_end <= p_start THEN RAISE EXCEPTION 'invalid time range'; END IF;
  IF p_start <= now() THEN RAISE EXCEPTION 'cannot schedule in the past'; END IF;

  SELECT c.sport_id INTO v_sport FROM public.course c WHERE c.id = p_course_id;

  INSERT INTO public.activity(
    user_id, sport_id, start_time, end_time, location_id, note,
    course_id, proposed_by, proposal_status)
  VALUES (v_uid, v_sport, p_start, p_end, p_location_id, nullif(btrim(p_note),''),
          p_course_id, v_uid,
          (CASE WHEN v_is_coach THEN 'approved' ELSE 'pending' END)
            ::public.activity_proposal_status)
  RETURNING id INTO v_id;

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;

  IF v_is_coach THEN
    PERFORM public.fn_course_system_message(p_course_id, 'activity_scheduled',
      jsonb_build_object('activity_id', v_id));
    PERFORM public.fn_enqueue_notification('course_activity_approved',
      (SELECT array_agg(m.user_id) FROM public.course_member m
       WHERE m.course_id = p_course_id AND m.status = 'enrolled'),
      'Buổi tập mới', 'Huấn luyện viên đã đặt lịch một buổi tập.',
      jsonb_build_object('course_id', p_course_id, 'activity_id', v_id));
  ELSE
    PERFORM public.fn_course_system_message(p_course_id, 'activity_proposed',
      jsonb_build_object('activity_id', v_id, 'username', v_username));
    SELECT p.linked_user_id INTO v_coach FROM public.professional p
    JOIN public.course c ON c.professional_id = p.id WHERE c.id = p_course_id;
    IF v_coach IS NOT NULL THEN
      PERFORM public.fn_enqueue_notification('course_activity_proposed', ARRAY[v_coach],
        'Đề xuất buổi tập', coalesce(v_username,'') || ' đề xuất một buổi tập.',
        jsonb_build_object('course_id', p_course_id, 'activity_id', v_id));
    END IF;
  END IF;

  RETURN v_id;
END
$$;

-- ── 2. RSVP on a course activity — missing entirely until now ──────────────

-- Unlike the other fn_* helpers in this file, this one is referenced
-- DIRECTLY inside RLS policy expressions below — a policy's USING/WITH CHECK
-- runs as the querying role (authenticated) itself, not inside another
-- SECURITY DEFINER call, so authenticated needs its own EXECUTE grant here
-- or every policy evaluation fails with "permission denied for function"
-- (same subtlety as fn_can_receive_conversation_topic in
-- messaging_realtime.sql). The nested calls to fn_is_enrolled_course_member /
-- fn_is_course_coach stay revoked-from-authenticated as normal, since they
-- only ever run from inside this function's own SECURITY DEFINER context.
CREATE OR REPLACE FUNCTION public.fn_can_access_course_activity(
  p_activity_id uuid, p_uid uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.id = p_activity_id AND a.course_id IS NOT NULL
      AND (
        public.fn_is_enrolled_course_member(a.course_id, p_uid)
        OR public.fn_is_course_coach(a.course_id, p_uid)
      )
  );
$$;
REVOKE ALL ON FUNCTION public.fn_can_access_course_activity(uuid,uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_can_access_course_activity(uuid,uuid)
  TO authenticated;

-- No lock-in condition here on purpose: course sessions have no
-- confirmation_threshold/quorum ("this is attendance intent only" —
-- course_controller.dart's rsvp() comment), unlike the lobby policies this
-- mirrors, which check activity_is_confirmed() to freeze a locked-in RSVP.

DROP POLICY IF EXISTS "Course members can view attendance" ON public.activity_confirmation;
CREATE POLICY "Course members can view attendance"
ON public.activity_confirmation FOR SELECT TO authenticated
USING (public.fn_can_access_course_activity(activity_id, (SELECT auth.uid())));

DROP POLICY IF EXISTS "Course members can set own attendance" ON public.activity_confirmation;
CREATE POLICY "Course members can set own attendance"
ON public.activity_confirmation FOR INSERT TO authenticated
WITH CHECK (
  user_id = (SELECT auth.uid())
  AND public.fn_can_access_course_activity(activity_id, (SELECT auth.uid()))
);

DROP POLICY IF EXISTS "Course members can change own attendance" ON public.activity_confirmation;
CREATE POLICY "Course members can change own attendance"
ON public.activity_confirmation FOR UPDATE TO authenticated
USING (
  user_id = (SELECT auth.uid())
  AND public.fn_can_access_course_activity(activity_id, (SELECT auth.uid()))
)
WITH CHECK (
  user_id = (SELECT auth.uid())
  AND public.fn_can_access_course_activity(activity_id, (SELECT auth.uid()))
);

DROP POLICY IF EXISTS "Course members can retract own attendance" ON public.activity_confirmation;
CREATE POLICY "Course members can retract own attendance"
ON public.activity_confirmation FOR DELETE TO authenticated
USING (
  user_id = (SELECT auth.uid())
  AND public.fn_can_access_course_activity(activity_id, (SELECT auth.uid()))
);

-- ── 3. can_write_conversation: a standalone read so an empty thread never
--    has to guess ─────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.can_write_conversation(p_conversation_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT coalesce(public.fn_can_write_conversation(p_conversation_id, auth.uid()), false);
$$;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname = 'can_write_conversation'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;
