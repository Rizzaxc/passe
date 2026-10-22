-- Coach flow, round three. Apply AFTER course_notification_kinds.sql (enum
-- prelude) and course_group_enrollment.sql.
--
-- 1. RSVP was never locked. The course RSVP policies
--    (course_permission_fixes.sql) check only "enrolled member or coach", so a
--    student could set `going` on a session that had already happened. RSVP
--    was the only "who attended" signal, and it gates session reports, review
--    eligibility and alumni read access — i.e. anyone enrolled could make
--    themselves review-eligible after the fact. RSVP writes on a course
--    session now close at its start time.
--
-- 2. Coach-marked attendance. RSVP is intent, not presence: a student who
--    showed up without tapping "going" could never get a report; one who
--    tapped it and no-showed could. `course_session_attendance` holds the
--    coach's mark for a started session (`mark_course_attendance`), and
--    `fn_course_attended` is the single answer to "did they attend" — the
--    coach's mark when there is one, the `going` RSVP otherwise. Reports,
--    reviews, alumni access and the coach's pending-report count all use it.
--    Unlike reports, a mark is correctable: it's the coach's own bookkeeping.
--
-- 3. Editable course. Name/description/target were frozen at the first
--    accepted offer, yet the target-reached push told the coach "Bạn có thể
--    gia hạn" with no way to do it. `update_course` edits them; raising the
--    target past the held count re-arms the target sweep.
--
-- 4. Distinct notification kinds for "target reached" and "no students
--    left" (both reused `course_ended`).
--
-- 5. `course_detail_data` gains `coach_rates` (the coach's listed coaching
--    services for this sport — courses carry no money, but "how much?" still
--    needs an answer), plus per-session attendance: `my_attended` for a
--    student, and for the coach a `roster` of who was in the course at the
--    session's start with their RSVP and mark.
--
-- 6. A started session can't be rescheduled either. reschedule_course_activity
--    blocked moving a session *into* the past, but not moving an
--    already-held one into the future — which wiped its RSVPs.
--
-- 7. Course reminders also reach the coach (they only went to `going`
--    students), and `fn_process_reminders` / `fn_invoke_send_push` — both
--    cron/trigger internals reached only from SECURITY DEFINER callers — lose
--    their EXECUTE grants to PUBLIC/anon/authenticated.
--
-- Needs to be applied to the live Supabase project.

INSERT INTO public.enabled_notification_kind(kind, enabled)
VALUES ('course_target_reached', true), ('course_no_students', true)
ON CONFLICT (kind) DO NOTHING;

-- ── 1. RSVP closes at start ─────────────────────────────────────────────────

-- Separate from fn_can_access_course_activity, which also backs the SELECT
-- policy — reading attendance after a session is fine.
CREATE OR REPLACE FUNCTION public.fn_can_rsvp_course_activity(p_activity_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT public.fn_can_access_course_activity(p_activity_id, p_uid) AND EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.id = p_activity_id AND a.start_time > now()
  );
$$;
-- Referenced directly in policy expressions, so authenticated needs EXECUTE
-- (same reason as fn_can_access_course_activity).
REVOKE ALL ON FUNCTION public.fn_can_rsvp_course_activity(uuid,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_can_rsvp_course_activity(uuid,uuid) TO authenticated;

ALTER POLICY "Course members can set own attendance" ON public.activity_confirmation
  WITH CHECK ((user_id = (SELECT auth.uid()))
    AND public.fn_can_rsvp_course_activity(activity_id, (SELECT auth.uid())));
ALTER POLICY "Course members can change own attendance" ON public.activity_confirmation
  USING ((user_id = (SELECT auth.uid()))
    AND public.fn_can_rsvp_course_activity(activity_id, (SELECT auth.uid())))
  WITH CHECK ((user_id = (SELECT auth.uid()))
    AND public.fn_can_rsvp_course_activity(activity_id, (SELECT auth.uid())));
ALTER POLICY "Course members can retract own attendance" ON public.activity_confirmation
  USING ((user_id = (SELECT auth.uid()))
    AND public.fn_can_rsvp_course_activity(activity_id, (SELECT auth.uid())));

-- ── 2. Coach-marked attendance ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.course_session_attendance (
  activity_id uuid NOT NULL REFERENCES public.activity(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  attended boolean NOT NULL,
  marked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (activity_id, student_id)
);
ALTER TABLE public.course_session_attendance ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.course_session_attendance FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_course_attended(p_activity_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT coalesce(
    (SELECT s.attended FROM public.course_session_attendance s
     WHERE s.activity_id = p_activity_id AND s.student_id = p_uid),
    EXISTS (SELECT 1 FROM public.activity_confirmation ac
            WHERE ac.activity_id = p_activity_id AND ac.user_id = p_uid
              AND ac.attendance = 'going'));
$$;
REVOKE ALL ON FUNCTION public.fn_course_attended(uuid,uuid) FROM PUBLIC, anon, authenticated;

-- Who was in the course when a session started — the only people whose
-- attendance means anything for it.
CREATE OR REPLACE FUNCTION public.fn_course_member_at(p_course_id uuid, p_uid uuid, p_at timestamptz)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid
      AND m.status <> 'inquiring'
      AND m.joined_at <= p_at AND (m.left_at IS NULL OR m.left_at > p_at)
  );
$$;
REVOKE ALL ON FUNCTION public.fn_course_member_at(uuid,uuid,timestamptz) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.mark_course_attendance(
  p_activity_id uuid, p_student_id uuid, p_attended boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_start timestamptz;
BEGIN
  SELECT a.course_id, a.start_time INTO v_course, v_start FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved' AND a.start_time <= now();
  IF NOT FOUND THEN RAISE EXCEPTION 'started session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF p_attended IS NULL THEN RAISE EXCEPTION 'attended required'; END IF;
  IF NOT public.fn_course_member_at(v_course, p_student_id, v_start) THEN
    RAISE EXCEPTION 'student was not in the course';
  END IF;

  INSERT INTO public.course_session_attendance(activity_id, student_id, attended)
  VALUES (p_activity_id, p_student_id, p_attended)
  ON CONFLICT (activity_id, student_id) DO UPDATE
    SET attended = excluded.attended, marked_at = now();
END
$$;

CREATE OR REPLACE FUNCTION public.submit_session_report(
  p_activity_id uuid, p_student_id uuid, p_body text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_id uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved'
    AND coalesce(a.end_time, a.start_time) < now();
  IF NOT FOUND THEN RAISE EXCEPTION 'finished session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF NOT public.fn_course_attended(p_activity_id, p_student_id) THEN
    RAISE EXCEPTION 'student did not attend';
  END IF;
  IF nullif(btrim(p_body),'') IS NULL OR char_length(btrim(p_body)) > 1000 THEN
    RAISE EXCEPTION 'invalid report';
  END IF;

  INSERT INTO public.course_session_report(course_id, activity_id, student_id, body)
  VALUES (v_course, p_activity_id, p_student_id, btrim(p_body))
  RETURNING id INTO v_id;

  PERFORM public.fn_enqueue_notification('course_session_report', ARRAY[p_student_id],
    'Nhận xét buổi tập', 'Huấn luyện viên đã gửi nhận xét cho bạn.',
    jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.submit_course_review(
  p_course_id uuid, p_rating smallint, p_comment text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_eligible boolean;
BEGIN
  IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION 'invalid rating';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    JOIN public.course c ON c.id = m.course_id
    WHERE m.course_id = p_course_id AND m.user_id = v_uid
      AND (c.status = 'ended' OR m.status IN ('left','removed'))
  ) INTO v_eligible;
  IF NOT v_eligible THEN RAISE EXCEPTION 'course not reviewable yet'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.course_id = p_course_id AND a.proposal_status = 'approved'
      AND coalesce(a.end_time, a.start_time) < now()
      AND public.fn_course_attended(a.id, v_uid)
  ) THEN RAISE EXCEPTION 'no attended session to review'; END IF;

  IF EXISTS (
    SELECT 1 FROM public.course_review r
    WHERE r.course_id = p_course_id AND r.student_id = v_uid
  ) THEN RAISE EXCEPTION 'already reviewed'; END IF;

  INSERT INTO public.course_review(course_id, student_id, rating, comment)
  VALUES (p_course_id, v_uid, p_rating, nullif(btrim(p_comment),''))
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.fn_is_course_alumnus(p_course_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid
      AND m.left_at IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.activity a
        WHERE a.course_id = p_course_id AND a.proposal_status = 'approved'
          AND coalesce(a.end_time, a.start_time) < now()
          AND public.fn_course_attended(a.id, p_uid)
      )
  );
$$;

-- ── 3. update_course ────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_course(
  p_course_id uuid, p_name text, p_description text DEFAULT NULL,
  p_target_session_count integer DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF nullif(btrim(p_name),'') IS NULL THEN RAISE EXCEPTION 'name required'; END IF;

  UPDATE public.course SET
    name = btrim(p_name),
    description = nullif(btrim(p_description), ''),
    target_session_count = p_target_session_count,
    -- Re-arm the sweep when the new target is still ahead of us ("gia hạn").
    target_reached_at = CASE
      WHEN p_target_session_count IS NULL THEN NULL
      WHEN p_target_session_count > public.fn_course_held_sessions(p_course_id) THEN NULL
      ELSE target_reached_at END
  WHERE id = p_course_id AND status = 'active';
  IF NOT FOUND THEN RAISE EXCEPTION 'course is not active'; END IF;

  PERFORM public.fn_course_system_message(p_course_id, 'course_updated');
END
$$;

-- ── 4. Distinct kinds ───────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_course_prompt_if_no_students(
  p_course_id uuid, p_was_enrolled boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_coach uuid;
BEGIN
  IF NOT p_was_enrolled THEN RETURN; END IF;
  IF EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.status = 'enrolled' AND m.left_at IS NULL
  ) THEN RETURN; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RETURN;
  END IF;

  PERFORM public.fn_course_system_message(p_course_id, 'no_students_left');

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  JOIN public.course c ON c.professional_id = p.id WHERE c.id = p_course_id;
  IF v_coach IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_no_students', ARRAY[v_coach],
      'Khoá học không còn học viên', 'Bạn có thể mời học viên mới hoặc kết thúc khoá học.',
      jsonb_build_object('course_id', p_course_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.fn_sweep_course_targets()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE r record; v_coach uuid;
BEGIN
  FOR r IN
    SELECT c.id, c.professional_id, c.target_session_count
    FROM public.course c
    WHERE c.status = 'active'
      AND c.target_session_count IS NOT NULL
      AND c.target_reached_at IS NULL
      AND public.fn_course_held_sessions(c.id) >= c.target_session_count
  LOOP
    UPDATE public.course SET target_reached_at = now() WHERE id = r.id;
    PERFORM public.fn_course_system_message(r.id, 'target_reached',
      jsonb_build_object('target', r.target_session_count));

    SELECT p.linked_user_id INTO v_coach FROM public.professional p
    WHERE p.id = r.professional_id;
    IF v_coach IS NOT NULL THEN
      PERFORM public.fn_enqueue_notification('course_target_reached', ARRAY[v_coach],
        'Khoá học đã đủ số buổi', 'Bạn có thể gia hạn hoặc kết thúc khoá học.',
        jsonb_build_object('course_id', r.id));
    END IF;
  END LOOP;
END
$$;

-- ── 5. course_detail_data: coach rates + attendance ─────────────────────────
-- Adds a column, so drop first; grants re-issued below.

DROP FUNCTION IF EXISTS public.course_detail_data(uuid);

CREATE FUNCTION public.course_detail_data(p_course_id uuid)
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, description text, status text,
  sport_id bigint, professional_id uuid, coach_name text, coach_user_id uuid,
  is_coach boolean, my_member_status text, target_session_count integer,
  held_session_count integer, members jsonb, sessions jsonb, reports jsonb,
  my_review_rating smallint, pending_offer_id uuid, offer_name text,
  offer_description text, offer_target_session_count integer, coach_rates jsonb
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_is_coach boolean; v_is_alumnus boolean := false;
        v_left_at timestamptz;
BEGIN
  v_is_coach := public.fn_is_course_coach(p_course_id, v_uid);
  IF NOT v_is_coach AND NOT public.fn_is_course_member(p_course_id, v_uid) THEN
    v_is_alumnus := public.fn_is_course_alumnus(p_course_id, v_uid);
    IF NOT v_is_alumnus THEN RAISE EXCEPTION 'course not found'; END IF;
    SELECT m.left_at INTO v_left_at FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = v_uid;
  END IF;

  RETURN QUERY
  SELECT c.id, conv.id, c.name, c.description, c.status::text, c.sport_id,
         c.professional_id, p.display_name, p.linked_user_id, v_is_coach,
         (SELECT m.status::text FROM public.course_member m
          WHERE m.course_id = c.id AND m.user_id = v_uid),
         c.target_session_count, public.fn_course_held_sessions(c.id),
         CASE WHEN v_is_alumnus THEN '[]'::jsonb ELSE coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'user_id', m.user_id, 'username', u.username,
             'generated_avatar', u.details->>'generatedAvatar',
             'status', m.status::text, 'joined_at', m.joined_at)
             ORDER BY u.username)
           FROM public.course_member m JOIN public."user" u ON u.id = m.user_id
           WHERE m.course_id = c.id AND m.left_at IS NULL), '[]'::jsonb) END,
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', a.id, 'start_time', a.start_time, 'end_time', a.end_time,
             'location_id', a.location_id,
             'venue_name', loc.name,
             'street_address', coalesce(
               nullif(btrim(loc.full_address), ''),
               nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
                 nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
                 nullif(btrim(loc.city), '')), '')
             ),
             'location_street_number', loc.street_number,
             'location_street_name', loc.street_name,
             'location_district', loc.district,
             'location_city', loc.city,
             'location_lat', loc.lat, 'location_lon', loc.lon,
             'note', a.note, 'proposal_status', a.proposal_status::text,
             'proposed_by', a.proposed_by,
             'my_attendance', (SELECT ac.attendance::text FROM public.activity_confirmation ac
                               WHERE ac.activity_id = a.id AND ac.user_id = v_uid),
             'my_attended', CASE WHEN a.start_time <= now() AND NOT v_is_coach
                              THEN public.fn_course_attended(a.id, v_uid) END,
             'going_count', (SELECT count(*) FROM public.activity_confirmation ac
                             WHERE ac.activity_id = a.id AND ac.attendance = 'going'),
             -- Coach only, once the session has started: everyone who was in
             -- the course at kickoff, with their RSVP, the coach's mark (null
             -- = unmarked) and the effective answer.
             'roster', CASE WHEN v_is_coach AND a.proposal_status = 'approved'
                             AND a.start_time <= now() THEN coalesce((
               SELECT jsonb_agg(jsonb_build_object(
                 'user_id', m.user_id, 'username', u.username,
                 'generated_avatar', u.details->>'generatedAvatar',
                 'rsvp', (SELECT ac.attendance::text FROM public.activity_confirmation ac
                          WHERE ac.activity_id = a.id AND ac.user_id = m.user_id),
                 'marked', (SELECT s.attended FROM public.course_session_attendance s
                            WHERE s.activity_id = a.id AND s.student_id = m.user_id),
                 'attended', public.fn_course_attended(a.id, m.user_id))
                 ORDER BY u.username)
               FROM public.course_member m JOIN public."user" u ON u.id = m.user_id
               WHERE m.course_id = c.id
                 AND public.fn_course_member_at(c.id, m.user_id, a.start_time)),
               '[]'::jsonb) END)
             ORDER BY a.start_time)
           FROM public.activity a
           LEFT JOIN public.location loc ON loc.id = a.location_id
           WHERE a.course_id = c.id
             AND (CASE WHEN v_is_alumnus
                       THEN a.proposal_status = 'approved' AND a.start_time <= v_left_at
                       ELSE a.proposal_status IN ('approved','pending') END)), '[]'::jsonb),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', r.activity_id, 'student_id', r.student_id,
             'body', r.body, 'created_at', r.created_at)
             ORDER BY r.created_at DESC)
           FROM public.course_session_report r
           WHERE r.course_id = c.id
             AND (v_is_coach OR r.student_id = v_uid)), '[]'::jsonb),
         (SELECT rv.rating FROM public.course_review rv
          WHERE rv.course_id = c.id AND rv.student_id = v_uid),
         offer.id, offer.name, offer.description, offer.target_session_count,
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'price_amount', s.price_amount, 'pricing_kind', s.pricing_kind,
             'min_duration_minutes', s.min_duration_minutes,
             'max_participants', s.max_participants,
             'description', s.service_description)
             ORDER BY s.price_amount)
           FROM public.professional_service s
           WHERE s.professional_id = c.professional_id AND s.sport_id = c.sport_id
             AND s.service_type = 'coaching' AND s.is_active), '[]'::jsonb)
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  LEFT JOIN LATERAL (
    SELECT o.id, o.name, o.description, o.target_session_count
    FROM public.course_enrollment_offer o
    JOIN public.course oc ON oc.id = o.course_id
    WHERE o.user_id = v_uid AND o.status = 'pending'
      AND (o.course_id = c.id OR (
        oc.professional_id = c.professional_id AND oc.sport_id = c.sport_id
        AND oc.status = 'active'
        AND NOT public.fn_is_course_member(oc.id, v_uid)))
    ORDER BY (o.course_id = c.id) DESC, o.created_at DESC LIMIT 1
  ) offer ON NOT v_is_coach AND NOT v_is_alumnus
  WHERE c.id = p_course_id;
END
$$;

-- Coach's pending-report count now follows effective attendance.
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
          JOIN public.course_member m ON m.course_id = a.course_id
          WHERE a.course_id = c.id AND a.proposal_status = 'approved'
            AND coalesce(a.end_time, a.start_time) < now()
            AND public.fn_course_member_at(c.id, m.user_id, a.start_time)
            AND public.fn_course_attended(a.id, m.user_id)
            AND NOT EXISTS (SELECT 1 FROM public.course_session_report r
                            WHERE r.activity_id = a.id AND r.student_id = m.user_id))
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
    AND (c.name IS NOT NULL OR EXISTS (
      SELECT 1 FROM public.course_member m
      WHERE m.course_id = c.id AND m.left_at IS NULL))
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;

-- ── 6. reschedule: a started session is history ─────────────────────────────

CREATE OR REPLACE FUNCTION public.reschedule_course_activity(
  p_activity_id uuid, p_start timestamptz, p_end timestamptz,
  p_location_id uuid DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_old_start timestamptz;
BEGIN
  SELECT a.course_id, a.start_time INTO v_course, v_old_start FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'approved session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF v_old_start <= now() THEN RAISE EXCEPTION 'session already started'; END IF;
  IF p_end IS NOT NULL AND p_end <= p_start THEN RAISE EXCEPTION 'invalid time range'; END IF;
  IF p_start <= now() THEN RAISE EXCEPTION 'cannot schedule in the past'; END IF;

  UPDATE public.activity
  SET start_time = p_start, end_time = p_end,
      location_id = coalesce(p_location_id, location_id)
  WHERE id = p_activity_id;

  DELETE FROM public.activity_confirmation WHERE activity_id = p_activity_id;

  PERFORM public.fn_course_system_message(v_course, 'activity_rescheduled',
    jsonb_build_object('activity_id', p_activity_id));
  PERFORM public.fn_enqueue_notification('course_activity_changed',
    (SELECT array_agg(m.user_id) FROM public.course_member m
     WHERE m.course_id = v_course AND m.status = 'enrolled'),
    'Buổi tập đổi giờ', 'Huấn luyện viên đã dời buổi tập.',
    jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
END
$$;

-- ── 7. Reminders reach the coach; internals lose public EXECUTE ─────────────

CREATE OR REPLACE FUNCTION public.fn_process_reminders()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT b.id, b.booking_time_start, b.client_user_id
      FROM public.referee_booking b
      WHERE b.reminder_sent_at IS NULL
        AND b.status = 'confirmed'
        AND b.booking_time_start > now()
        AND b.booking_time_start <= now() + interval '1 hour'
      FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.fn_enqueue_notification(
      'pro_session_reminder',
      (SELECT array_agg(uid) FROM (
          SELECT r.client_user_id AS uid
          UNION
          SELECT au.user_id FROM public.referee_booking_additional_users au
          WHERE au.booking_id = r.id
       ) s),
      'Sắp tới giờ trận đấu',
      'Trận đấu bắt đầu lúc '
        || to_char(r.booking_time_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      jsonb_build_object('target_id', r.id::text)
    );
    UPDATE public.referee_booking SET reminder_sent_at = now() WHERE id = r.id;
  END LOOP;

  FOR r IN
    SELECT a.id, a.start_time, a.course_id
      FROM public.activity a
      WHERE a.course_id IS NOT NULL
        AND a.proposal_status = 'approved'
        AND a.start_time > now()
        AND a.start_time <= now() + interval '1 hour'
        AND NOT EXISTS (SELECT 1 FROM public.activity_reminder_sent s
                        WHERE s.activity_id = a.id)
      FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.fn_enqueue_notification(
      'pro_session_reminder',
      (SELECT array_agg(uid) FROM (
          SELECT ac.user_id AS uid FROM public.activity_confirmation ac
          WHERE ac.activity_id = r.id AND ac.attendance = 'going'
          UNION
          SELECT p.linked_user_id FROM public.course c
          JOIN public.professional p ON p.id = c.professional_id
          WHERE c.id = r.course_id AND p.linked_user_id IS NOT NULL
       ) s),
      'Sắp tới giờ tập với coach',
      'Buổi tập của bạn bắt đầu lúc '
        || to_char(r.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      jsonb_build_object('course_id', r.course_id::text, 'activity_id', r.id::text)
    );
    INSERT INTO public.activity_reminder_sent(activity_id) VALUES (r.id)
    ON CONFLICT (activity_id) DO NOTHING;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_process_reminders() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_invoke_send_push() FROM PUBLIC, anon, authenticated;

-- ── Grants ───────────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.mark_course_attendance(uuid, uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_course_attendance(uuid, uuid, boolean) TO authenticated;
REVOKE ALL ON FUNCTION public.update_course(uuid, text, text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_course(uuid, text, text, integer) TO authenticated;
REVOKE ALL ON FUNCTION public.submit_session_report(uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_session_report(uuid, uuid, text) TO authenticated;
REVOKE ALL ON FUNCTION public.submit_course_review(uuid, smallint, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.submit_course_review(uuid, smallint, text) TO authenticated;
REVOKE ALL ON FUNCTION public.reschedule_course_activity(uuid, timestamptz, timestamptz, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reschedule_course_activity(uuid, timestamptz, timestamptz, uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.course_detail_data(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.course_detail_data(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.pro_courses_data() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pro_courses_data() TO authenticated;
REVOKE ALL ON FUNCTION public.fn_course_prompt_if_no_students(uuid, boolean) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_sweep_course_targets() FROM PUBLIC, anon, authenticated;
