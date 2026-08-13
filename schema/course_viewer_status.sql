-- course_detail_data never told the client the viewer's own membership
-- status, only `is_coach`. An inquiring (unenrolled) student and an
-- enrolled one both got the same payload, so the client had no way to
-- distinguish them: the Planner/History tabs and the "propose a session"
-- button showed for anyone with course access at all, including inquirers,
-- even though propose_course_activity already rejects them server-side
-- (course_permission_fixes.sql). The client should reflect what's allowed,
-- not just find out the hard way after a failed RPC call.
--
-- Needs to be applied to the live Supabase project.

DROP FUNCTION IF EXISTS public.course_detail_data(uuid);

CREATE FUNCTION public.course_detail_data(p_course_id uuid)
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, description text, status text,
  sport_id bigint, professional_id uuid, coach_name text, coach_user_id uuid,
  is_coach boolean, my_member_status text, target_session_count integer,
  held_session_count integer, members jsonb, sessions jsonb, reports jsonb,
  my_review_rating smallint
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
          WHERE rv.course_id = c.id AND rv.student_id = v_uid)
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  WHERE c.id = p_course_id;
END
$$;

REVOKE ALL ON FUNCTION public.course_detail_data(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.course_detail_data(uuid) TO authenticated;
