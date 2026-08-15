-- Follow-up to course_pro_inbox_student_name.sql: the coach's inbox now
-- shows the real student name, but the card avatar was still initials-only
-- for every student. Unlike a coach (fronted by a `professional` row that
-- may or may not have a linked `user`), a student's `course_member.user_id`
-- *is* a real `public.user` row directly — no indirection needed.
--
-- Fix: `pro_courses_data`'s representative-member lateral also returns the
-- student's own id + `details->>'generatedAvatar'`, so the coach-side card
-- can mount `PUserAvatar` the same way the player-side card now does for
-- the coach.
--
-- Needs to be applied to the live Supabase project.

DROP FUNCTION IF EXISTS public.pro_courses_data();

CREATE OR REPLACE FUNCTION public.pro_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  sport_id bigint, student_count integer, inquiring_count integer,
  target_session_count integer, held_session_count integer,
  next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer,
  pending_proposal_count integer, pending_report_count integer,
  student_name text, student_user_id uuid, student_avatar text
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT c.id, conv.id, c.name, c.status::text, c.sport_id,
         (SELECT count(*)::integer FROM public.course_member m
          WHERE m.course_id = c.id AND m.status = 'enrolled'),
         (SELECT count(*)::integer FROM public.course_member m
          WHERE m.course_id = c.id AND m.status = 'inquiring'),
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
                            WHERE r.activity_id = a.id AND r.student_id = ac.user_id)),
         student.username, student.user_id, student.avatar
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
    SELECT cu.id AS user_id, cu.username::text AS username,
           cu.details->>'generatedAvatar' AS avatar
    FROM public.course_member m
    JOIN public."user" cu ON cu.id = m.user_id
    WHERE m.course_id = c.id AND m.left_at IS NULL
    ORDER BY m.joined_at ASC
    LIMIT 1
  ) student ON true
  WHERE p.linked_user_id = auth.uid()
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;

REVOKE ALL ON FUNCTION public.pro_courses_data() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pro_courses_data() TO authenticated;
