-- Group enrollment from an inquiry thread, and inquiry triage.
-- Apply AFTER course_alumni_review_access.sql (whose `course_detail_data` /
-- `my_courses_data` already surface the cross-course offers this file creates).
--
-- 1. A coach couldn't add someone who had messaged them to a group course.
--    `message_coach` gives every inquirer their own course (Y). Offering
--    that student a seat in the coach's existing group course (X) ran
--    `fn_course_add_member(X, …, 'inquiring')`, which violates
--    `course_member_one_live_thread` (one live thread per user+coach+sport)
--    because the Y row is still live — the coach got a raw unique-violation.
--    In practice "one coach, many students" only worked for cold invites of
--    people who had never messaged.
--
--    Now: when the student already has a live *inquiring* thread with this
--    coach+sport elsewhere, `send_enrollment_offer` does not add them to X.
--    The offer is created on X but surfaces in their existing thread Y (a
--    system message there, the push routed to Y, and the read RPCs picking
--    up cross-course offers). Accepting moves them: Y's row goes `left`, they
--    join X as `enrolled` (visibility floor = now, so no back-story), and Y is
--    ended if it was a bare inquiry with nobody left in it. A student already
--    *enrolled* in another of this coach's courses is refused with a clear
--    error rather than silently moved.
--
--    Accepting any offer also withdraws the student's other pending offers
--    from the same coach+sport — only one can ever be accepted anyway.
--
-- 2. A coach had no way to say no to an inquiry. "Remove member" told the
--    inquirer the coach had "ended the course with you" and left an active,
--    memberless course in the coach's inbox forever. `decline_course_inquiry`
--    removes an inquiring member with neutral copy, withdraws their pending
--    offers, and quietly ends the course if it was never a real course (no
--    name) and has nobody left. `pro_courses_data` hides such shells.
--
-- Needs to be applied to the live Supabase project.

-- ── Helper ──────────────────────────────────────────────────────────────────

-- End a never-named inquiry course once nobody is left in it. A named course
-- losing its last student is the coach's call (fn_course_prompt_if_no_students);
-- an inquiry with nobody in it is just a dead thread.
CREATE OR REPLACE FUNCTION public.fn_course_end_if_empty_inquiry(p_course_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.left_at IS NULL
  ) THEN RETURN; END IF;

  UPDATE public.course SET status = 'ended', ended_at = now()
  WHERE id = p_course_id AND status = 'active' AND name IS NULL;
  IF NOT FOUND THEN RETURN; END IF;

  DELETE FROM public.activity WHERE course_id = p_course_id AND start_time > now();
  UPDATE public.course_enrollment_offer SET status = 'withdrawn', responded_at = now()
  WHERE course_id = p_course_id AND status = 'pending';
END
$$;
REVOKE ALL ON FUNCTION public.fn_course_end_if_empty_inquiry(uuid)
  FROM PUBLIC, anon, authenticated;

-- ── 1a. send_enrollment_offer ───────────────────────────────────────────────
-- Same signature and validation as course_guard_fixes.sql; only the
-- membership step and the notification target change.

CREATE OR REPLACE FUNCTION public.send_enrollment_offer(
  p_course_id uuid, p_user_id uuid, p_name text,
  p_description text DEFAULT NULL::text,
  p_target_session_count integer DEFAULT NULL::integer)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_course record;
        v_thread uuid; v_thread_status public.course_member_status;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  SELECT c.id, c.name, c.professional_id, c.sport_id INTO v_course
  FROM public.course c WHERE c.id = p_course_id AND c.status = 'active';
  IF NOT FOUND THEN RAISE EXCEPTION 'course is not active'; END IF;
  IF nullif(btrim(p_name),'') IS NULL THEN RAISE EXCEPTION 'name required'; END IF;

  IF p_user_id IS NULL THEN RAISE EXCEPTION 'no target user'; END IF;
  IF p_user_id = v_uid THEN RAISE EXCEPTION 'cannot enroll yourself'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public."user" u WHERE u.id = p_user_id) THEN
    RAISE EXCEPTION 'user not found';
  END IF;
  IF public.fn_is_blocked(v_uid, p_user_id) THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  IF NOT public.fn_is_course_member(p_course_id, p_user_id) THEN
    -- Their live thread with this coach+sport, if any, in another course.
    SELECT m.course_id, m.status INTO v_thread, v_thread_status
    FROM public.course_member m
    WHERE m.user_id = p_user_id AND m.professional_id = v_course.professional_id
      AND m.sport_id = v_course.sport_id AND m.left_at IS NULL
      AND m.course_id <> p_course_id
    LIMIT 1;

    IF v_thread_status = 'enrolled' THEN
      RAISE EXCEPTION 'already enrolled in another of your courses';
    ELSIF v_thread IS NULL THEN
      -- Cold invite: nobody to move, so they join X as inquiring directly.
      PERFORM public.fn_course_add_member(p_course_id, p_user_id, 'inquiring');
    END IF;
    -- Otherwise they stay in their inquiry thread until they accept.
  END IF;

  INSERT INTO public.course_enrollment_offer(
    course_id, user_id, name, description, target_session_count)
  VALUES (p_course_id, p_user_id, btrim(p_name), p_description, p_target_session_count)
  RETURNING id INTO v_id;

  IF v_thread IS NOT NULL THEN
    PERFORM public.fn_course_system_message(v_thread, 'enrollment_offer_elsewhere',
      jsonb_build_object('course_name', coalesce(v_course.name, btrim(p_name)),
                         'course_id', p_course_id, 'offer_id', v_id));
  END IF;

  -- Route the push to the thread the student can actually open.
  PERFORM public.fn_enqueue_notification('course_enrollment_offer', ARRAY[p_user_id],
    'Lời mời tham gia khoá học', btrim(p_name),
    jsonb_build_object('course_id', coalesce(v_thread, p_course_id), 'offer_id', v_id));
  RETURN v_id;
END
$$;

-- ── 1b. respond_enrollment_offer — now returns the course the caller is in ──
-- Return type changes (void → uuid), so drop first; grants re-issued below.

DROP FUNCTION IF EXISTS public.respond_enrollment_offer(uuid, boolean);

CREATE FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_offer record; v_coach uuid; v_username text;
        v_thread uuid; v_course_name text;
BEGIN
  SELECT o.*, c.professional_id, c.sport_id, c.name AS course_name INTO v_offer
  FROM public.course_enrollment_offer o
  JOIN public.course c ON c.id = o.course_id
  WHERE o.id = p_offer_id AND o.user_id = v_uid AND o.status = 'pending'
    AND c.status = 'active'
  FOR UPDATE OF o;
  IF NOT FOUND THEN RAISE EXCEPTION 'pending offer not found'; END IF;

  IF NOT p_accept THEN
    UPDATE public.course_enrollment_offer
    SET status = 'declined', responded_at = now() WHERE id = p_offer_id;
    RETURN v_offer.course_id;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.user_id = v_uid AND m.sport_id = v_offer.sport_id
      AND m.status = 'enrolled' AND m.left_at IS NULL
      AND m.course_id <> v_offer.course_id
  ) THEN
    RAISE EXCEPTION 'already enrolled with a coach for this sport';
  END IF;

  UPDATE public.course_enrollment_offer
  SET status = 'accepted', responded_at = now() WHERE id = p_offer_id;

  -- Only one offer from this coach+sport can win.
  UPDATE public.course_enrollment_offer o SET status = 'withdrawn', responded_at = now()
  FROM public.course oc
  WHERE oc.id = o.course_id AND o.user_id = v_uid AND o.status = 'pending'
    AND oc.professional_id = v_offer.professional_id AND oc.sport_id = v_offer.sport_id;

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;
  v_course_name := coalesce(v_offer.course_name, v_offer.name);

  IF public.fn_is_course_member(v_offer.course_id, v_uid) THEN
    UPDATE public.course_member SET status = 'enrolled'
    WHERE course_id = v_offer.course_id AND user_id = v_uid;
  ELSE
    -- Moving out of their inquiry thread. Post the note first: once their
    -- conversation_member row is closed they'd no longer see it.
    SELECT m.course_id INTO v_thread FROM public.course_member m
    WHERE m.user_id = v_uid AND m.professional_id = v_offer.professional_id
      AND m.sport_id = v_offer.sport_id AND m.left_at IS NULL
      AND m.course_id <> v_offer.course_id
    LIMIT 1;

    IF v_thread IS NOT NULL THEN
      PERFORM public.fn_course_system_message(v_thread, 'moved_to_course',
        jsonb_build_object('username', v_username, 'course_name', v_course_name));
      UPDATE public.course_member SET status = 'left', left_at = now()
      WHERE course_id = v_thread AND user_id = v_uid;
      UPDATE public.conversation_member SET left_at = now()
      WHERE user_id = v_uid
        AND conversation_id = (SELECT id FROM public.conversation WHERE course_id = v_thread);
      PERFORM public.fn_course_end_if_empty_inquiry(v_thread);
    END IF;

    PERFORM public.fn_course_add_member(v_offer.course_id, v_uid, 'enrolled');
  END IF;

  -- First acceptance gives the course its identity.
  UPDATE public.course SET
    name = coalesce(name, v_offer.name),
    description = coalesce(description, v_offer.description),
    target_session_count = coalesce(target_session_count, v_offer.target_session_count)
  WHERE id = v_offer.course_id;

  PERFORM public.fn_course_system_message(v_offer.course_id, 'enrollment_accepted',
    jsonb_build_object('username', v_username));

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  WHERE p.id = v_offer.professional_id;
  IF v_coach IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_enrollment_accepted', ARRAY[v_coach],
      'Học viên đã tham gia', coalesce(v_username,'') || ' đã tham gia khoá học.',
      jsonb_build_object('course_id', v_offer.course_id));
  END IF;

  RETURN v_offer.course_id;
END
$$;

-- ── 2a. decline_course_inquiry ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.decline_course_inquiry(p_course_id uuid, p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_username text;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_user_id
      AND m.status = 'inquiring' AND m.left_at IS NULL
  ) THEN RAISE EXCEPTION 'inquiry not found'; END IF;

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = p_user_id;
  -- Before closing their window, so the inquirer sees why the thread went quiet.
  PERFORM public.fn_course_system_message(p_course_id, 'inquiry_declined',
    jsonb_build_object('username', v_username));

  UPDATE public.course_member SET status = 'removed', left_at = now()
  WHERE course_id = p_course_id AND user_id = p_user_id;
  UPDATE public.conversation_member SET left_at = now()
  WHERE user_id = p_user_id
    AND conversation_id = (SELECT id FROM public.conversation WHERE course_id = p_course_id);
  UPDATE public.course_enrollment_offer SET status = 'withdrawn', responded_at = now()
  WHERE course_id = p_course_id AND user_id = p_user_id AND status = 'pending';

  -- `course_member_removed` already routes to the hub client-side; only the
  -- copy differs from remove_course_member's "ended the course with you".
  PERFORM public.fn_enqueue_notification('course_member_removed', ARRAY[p_user_id],
    'Huấn luyện viên đã phản hồi', 'Huấn luyện viên hiện chưa thể nhận thêm học viên.',
    jsonb_build_object('course_id', p_course_id));

  PERFORM public.fn_course_end_if_empty_inquiry(p_course_id);
END
$$;

-- ── 2b. pro_courses_data — hide empty inquiry shells ────────────────────────
-- Same return shape as the live definition; only the WHERE clause changes.

CREATE OR REPLACE FUNCTION public.pro_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text, sport_id bigint,
  student_count integer, inquiring_count integer, student_name text,
  student_user_id uuid, student_avatar text, target_session_count integer,
  held_session_count integer, next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer, pending_proposal_count integer,
  pending_report_count integer
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT c.id, conv.id, c.name, c.status::text, c.sport_id,
         (SELECT count(*)::integer FROM public.course_member m
          WHERE m.course_id = c.id AND m.status = 'enrolled'),
         (SELECT count(*)::integer FROM public.course_member m
          WHERE m.course_id = c.id AND m.status = 'inquiring'),
         earliest.username, earliest.user_id, earliest.generated_avatar,
         c.target_session_count, public.fn_course_held_sessions(c.id),
         nxt.id, nxt.start_time,
         last_msg.created_at, last_msg.body, last_msg.kind::text, last_msg.payload,
         (SELECT count(*)::integer FROM public.message x
          WHERE x.conversation_id = conv.id
            AND x.created_at > cm.last_read_at
            AND x.created_at >= cm.joined_at),
         (SELECT count(*)::integer FROM public.activity a
          WHERE a.course_id = c.id AND a.proposal_status = 'pending'),
         (SELECT count(*)::integer
          FROM public.activity a
          JOIN public.activity_confirmation ac ON ac.activity_id = a.id
          WHERE a.course_id = c.id AND a.proposal_status = 'approved'
            AND coalesce(a.end_time, a.start_time) < now()
            AND ac.attendance = 'going'
            AND NOT EXISTS (SELECT 1 FROM public.course_session_report r
                            WHERE r.activity_id = a.id AND r.student_id = ac.user_id))
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  LEFT JOIN public.conversation_member cm
         ON cm.conversation_id = conv.id AND cm.user_id = auth.uid()
  LEFT JOIN LATERAL (
    SELECT a.id, a.start_time FROM public.activity a
    WHERE a.course_id = c.id AND a.proposal_status = 'approved' AND a.start_time > now()
    ORDER BY a.start_time LIMIT 1
  ) nxt ON true
  LEFT JOIN LATERAL (
    SELECT x.created_at, x.body, x.kind, x.payload FROM public.message x
    WHERE x.conversation_id = conv.id ORDER BY x.created_at DESC LIMIT 1
  ) last_msg ON true
  LEFT JOIN LATERAL (
    SELECT u.username::text, m.user_id, u.details->>'generatedAvatar' AS generated_avatar
    FROM public.course_member m
    JOIN public."user" u ON u.id = m.user_id
    WHERE m.course_id = c.id AND m.left_at IS NULL
    ORDER BY m.joined_at LIMIT 1
  ) earliest ON true
  WHERE p.linked_user_id = auth.uid()
    -- A never-named course with nobody in it is a declined or moved-on
    -- inquiry, not something the coach needs to see.
    AND (c.name IS NOT NULL OR EXISTS (
      SELECT 1 FROM public.course_member m
      WHERE m.course_id = c.id AND m.left_at IS NULL))
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.send_enrollment_offer(uuid, uuid, text, text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_enrollment_offer(uuid, uuid, text, text, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.respond_enrollment_offer(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.respond_enrollment_offer(uuid, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.decline_course_inquiry(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.decline_course_inquiry(uuid, uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.pro_courses_data() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pro_courses_data() TO authenticated;
