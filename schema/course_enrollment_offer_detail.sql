-- Coach flow clarity fixes: testers couldn't tell coaches apart and couldn't
-- accept an enrollment offer at all. Both trace back to these three read RPCs
-- (`schema/course.sql`) never returning data the client already has UI for.
--
-- Each function is replaced in place, keeping its signature and grants — the
-- REVOKE/GRANT pairs are re-issued anyway, same defensive posture as
-- `course_guard_fixes.sql`.

-- 1. `my_courses_data` never selected the coach's user id.
--
-- It returns `coach_name`/`coach_avatar` but no `coach_user_id`, so
-- `CourseSummary.coachUserId` was always null on the student side and
-- `CourseCard`'s `_CourseAvatar` (`id == null ? Text(_initials) :
-- PUserAvatar(...)`) always fell back to plain initials — the coach's real
-- `generatedAvatar` was fetched by the query and then never used.
--
-- All three functions below add columns to an existing `RETURNS TABLE`
-- shape, which `CREATE OR REPLACE` can't do (Postgres: "cannot change return
-- type of existing function") — drop each first.

DROP FUNCTION IF EXISTS public.my_courses_data();
DROP FUNCTION IF EXISTS public.pro_courses_data();
DROP FUNCTION IF EXISTS public.course_detail_data(uuid);

CREATE OR REPLACE FUNCTION public.my_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  member_status text, professional_id uuid, coach_name text, coach_avatar text,
  coach_user_id uuid,
  sport_id bigint, target_session_count integer, held_session_count integer,
  next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer,
  pending_offer_id uuid, pending_rsvp_count integer
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  -- `professional` has no avatar of its own; it comes from the coach's user row.
  -- last_message_kind/_payload travel alongside the body so the client can
  -- localise a system-event preview ('inquiry_started', etc) the same way
  -- the chat thread itself does, instead of rendering the raw stable code.
  SELECT c.id, conv.id, c.name, c.status::text, m.status::text,
         c.professional_id, p.display_name, cu.details->>'generatedAvatar',
         p.linked_user_id,
         c.sport_id, c.target_session_count, public.fn_course_held_sessions(c.id),
         nxt.id, nxt.start_time,
         last_msg.created_at, last_msg.body, last_msg.kind::text, last_msg.payload,
         (SELECT count(*)::integer FROM public.message x
          WHERE x.conversation_id = conv.id
            AND x.created_at > cm.last_read_at
            AND x.created_at >= cm.joined_at
            AND (cm.left_at IS NULL OR x.created_at <= cm.left_at)),
         (SELECT o.id FROM public.course_enrollment_offer o
          WHERE o.course_id = c.id AND o.user_id = m.user_id AND o.status = 'pending'
          LIMIT 1),
         (SELECT count(*)::integer FROM public.activity a
          WHERE a.course_id = c.id AND a.proposal_status = 'approved'
            AND a.start_time > now()
            AND NOT EXISTS (SELECT 1 FROM public.activity_confirmation ac
                            WHERE ac.activity_id = a.id AND ac.user_id = m.user_id))
  FROM public.course_member m
  JOIN public.course c ON c.id = m.course_id
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public."user" cu ON cu.id = p.linked_user_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  LEFT JOIN public.conversation_member cm
         ON cm.conversation_id = conv.id AND cm.user_id = m.user_id
  LEFT JOIN LATERAL (
    SELECT a.id, a.start_time FROM public.activity a
    WHERE a.course_id = c.id AND a.proposal_status = 'approved' AND a.start_time > now()
    ORDER BY a.start_time LIMIT 1
  ) nxt ON true
  LEFT JOIN LATERAL (
    SELECT x.created_at, x.body, x.kind, x.payload FROM public.message x
    WHERE x.conversation_id = conv.id
      AND x.created_at >= cm.joined_at
      AND (cm.left_at IS NULL OR x.created_at <= cm.left_at)
    ORDER BY x.created_at DESC LIMIT 1
  ) last_msg ON true
  WHERE m.user_id = auth.uid() AND m.left_at IS NULL
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;

-- 2. `pro_courses_data` never selected who the student *is*.
--
-- `CourseSummary` already carries `studentName`/`studentUserId`/`studentAvatar`
-- (documented there as "the earliest-joined live member" — lets the coach's
-- card show who's asking before the course has a real `name`) and
-- `CourseCard` already branches on them for `coachSide` — but this RPC never
-- returned them, so every fresh inquiry rendered the same "New enquiry"
-- placeholder title *and* the same placeholder avatar, coach-side, no matter
-- who actually messaged in.

CREATE OR REPLACE FUNCTION public.pro_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  sport_id bigint, student_count integer, inquiring_count integer,
  student_name text, student_user_id uuid, student_avatar text,
  target_session_count integer, held_session_count integer,
  next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer,
  pending_proposal_count integer, pending_report_count integer
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
         -- A report is "pending" for every going-RSVP on a finished session
         -- that hasn't been written up yet.
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
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;

-- 3. `course_detail_data` never returned the caller's own pending enrollment
-- offer. `respond_enrollment_offer` (course.sql) exists and
-- `CourseActionController.respondToOffer` wraps it, but nothing in the client
-- could ever show it — there was no offer id, name, description or target to
-- render, so no accept/decline UI could be built. The `course_enrollment_offer`
-- push just routed to this same course page with nothing to act on.

CREATE OR REPLACE FUNCTION public.course_detail_data(p_course_id uuid)
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, description text, status text,
  sport_id bigint, professional_id uuid, coach_name text, coach_user_id uuid,
  is_coach boolean, my_member_status text, target_session_count integer,
  held_session_count integer, members jsonb, sessions jsonb, reports jsonb,
  my_review_rating smallint,
  pending_offer_id uuid, offer_name text, offer_description text,
  offer_target_session_count integer
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_is_coach boolean;
BEGIN
  v_is_coach := public.fn_is_course_coach(p_course_id, v_uid);
  IF NOT v_is_coach AND NOT public.fn_is_course_member(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'course not found';
  END IF;

  RETURN QUERY
  SELECT c.id, conv.id, c.name, c.description, c.status::text, c.sport_id,
         c.professional_id, p.display_name, p.linked_user_id, v_is_coach,
         (SELECT m.status::text FROM public.course_member m
          WHERE m.course_id = c.id AND m.user_id = v_uid AND m.left_at IS NULL),
         c.target_session_count, public.fn_course_held_sessions(c.id),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'user_id', m.user_id, 'username', u.username,
             'generated_avatar', u.details->>'generatedAvatar',
             'status', m.status::text, 'joined_at', m.joined_at)
             ORDER BY u.username)
           FROM public.course_member m JOIN public."user" u ON u.id = m.user_id
           WHERE m.course_id = c.id AND m.left_at IS NULL), '[]'::jsonb),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', a.id, 'start_time', a.start_time, 'end_time', a.end_time,
             'location_id', a.location_id, 'venue_name', loc.name, 'note', a.note,
             'proposal_status', a.proposal_status::text,
             'proposed_by', a.proposed_by,
             'my_attendance', (SELECT ac.attendance::text FROM public.activity_confirmation ac
                               WHERE ac.activity_id = a.id AND ac.user_id = v_uid),
             'going_count', (SELECT count(*) FROM public.activity_confirmation ac
                             WHERE ac.activity_id = a.id AND ac.attendance = 'going'))
             ORDER BY a.start_time)
           FROM public.activity a
           LEFT JOIN public.location loc ON loc.id = a.location_id
           WHERE a.course_id = c.id
             AND a.proposal_status IN ('approved','pending')), '[]'::jsonb),
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
         offer.id, offer.name, offer.description, offer.target_session_count
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  LEFT JOIN LATERAL (
    SELECT o.id, o.name, o.description, o.target_session_count
    FROM public.course_enrollment_offer o
    WHERE o.course_id = c.id AND o.user_id = v_uid AND o.status = 'pending'
    ORDER BY o.created_at DESC LIMIT 1
  ) offer ON NOT v_is_coach
  WHERE c.id = p_course_id;
END
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname IN (
             'my_courses_data','pro_courses_data','course_detail_data')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;
