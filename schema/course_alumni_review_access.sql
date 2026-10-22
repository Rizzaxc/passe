-- Two lifecycle holes in the coach flow, found sanity-checking it end to end.
--
-- 1. A student could never review their coach.
--    `end_course` (course_end_membership_fix.sql) and `leave_course` both set
--    `course_member.left_at`, and every student-facing read gates on
--    `fn_is_course_member`, which requires `left_at IS NULL`. So the moment a
--    course became reviewable it also became unreachable:
--    `course_detail_data` raised 'course not found', `my_courses_data` dropped
--    the row from the hub, and the `course_ended` push ("Bạn có thể đánh giá
--    huấn luyện viên") opened an error page. `submit_course_review` itself was
--    fine — nothing could ever call it — so `course_review` stayed empty and
--    `professional.average_rating` never moved from courses.
--
--    Fix: an **alumnus** — a departed member who actually attended a held
--    session, i.e. exactly the people `submit_course_review` admits — keeps
--    read-only access. They see their own history, reports and review state,
--    but not the current roster or anything scheduled after they left.
--    `fn_is_course_member` is unchanged: every write path keeps requiring a
--    live membership.
--
-- 2. `cancel_course_activity` had no time guard.
--    Cancelling *deletes* the activity, and `course_session_report.activity_id`
--    is ON DELETE CASCADE — so a coach "cancelling" a session that already
--    happened silently destroyed the reports this schema calls immutable,
--    along with the RSVPs that gate reports and reviews, and decremented the
--    held-session count. An approved session that has started can no longer
--    be cancelled. A still-pending proposal can (the coach declining it late
--    destroys nothing).
--
-- Also restores the session location fields (`street_address`,
-- `location_*`) that course_freeplay_location_details.sql added to
-- `course_detail_data` and course_enrollment_offer_detail.sql's later
-- redefinition dropped — the live function had silently lost them, so the
-- client's address/directions row was always empty.
--
-- Return shapes are unchanged, so CREATE OR REPLACE keeps the grants; they're
-- re-issued anyway, same posture as course_guard_fixes.sql.
-- Needs to be applied to the live Supabase project.

-- ── Helper ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_is_course_alumnus(p_course_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid
      AND m.left_at IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.activity a
        JOIN public.activity_confirmation ac ON ac.activity_id = a.id
        WHERE a.course_id = p_course_id AND ac.user_id = p_uid
          AND ac.attendance = 'going' AND a.proposal_status = 'approved'
          AND coalesce(a.end_time, a.start_time) < now()
      )
  );
$$;
REVOKE ALL ON FUNCTION public.fn_is_course_alumnus(uuid,uuid) FROM PUBLIC, anon, authenticated;

-- ── 1a. course_detail_data: read-only alumni access ─────────────────────────

CREATE OR REPLACE FUNCTION public.course_detail_data(p_course_id uuid)
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, description text, status text,
  sport_id bigint, professional_id uuid, coach_name text, coach_user_id uuid,
  is_coach boolean, my_member_status text, target_session_count integer,
  held_session_count integer, members jsonb, sessions jsonb, reports jsonb,
  my_review_rating smallint, pending_offer_id uuid, offer_name text,
  offer_description text, offer_target_session_count integer
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
         -- (course_id, user_id) is the PK, so this is the viewer's one row —
         -- 'left'/'removed' for an alumnus, which the client reads as read-only.
         (SELECT m.status::text FROM public.course_member m
          WHERE m.course_id = c.id AND m.user_id = v_uid),
         c.target_session_count, public.fn_course_held_sessions(c.id),
         -- An alumnus doesn't get to keep watching who's in the course now.
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
             'going_count', (SELECT count(*) FROM public.activity_confirmation ac
                             WHERE ac.activity_id = a.id AND ac.attendance = 'going'))
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
         offer.id, offer.name, offer.description, offer.target_session_count
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  -- Also an offer into *another* of this coach's courses (same sport) that
  -- the viewer isn't a member of yet: course_group_enrollment.sql surfaces a
  -- group-course offer in the student's existing inquiry thread rather than
  -- adding them to the group (which the one-live-thread index forbids).
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

-- ── 1b. my_courses_data: alumni stay in the hub ─────────────────────────────

CREATE OR REPLACE FUNCTION public.my_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  member_status text, professional_id uuid, coach_name text, coach_avatar text,
  coach_user_id uuid, sport_id bigint, target_session_count integer,
  held_session_count integer, next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer,
  pending_offer_id uuid, pending_rsvp_count integer
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT c.id, conv.id, c.name, c.status::text, m.status::text,
         c.professional_id, p.display_name, cu.details->>'generatedAvatar',
         p.linked_user_id,
         c.sport_id, c.target_session_count, public.fn_course_held_sessions(c.id),
         -- Nothing upcoming or actionable for someone who has left.
         CASE WHEN m.left_at IS NULL THEN nxt.id END,
         CASE WHEN m.left_at IS NULL THEN nxt.start_time END,
         last_msg.created_at, last_msg.body, last_msg.kind::text, last_msg.payload,
         (SELECT count(*)::integer FROM public.message x
          WHERE x.conversation_id = conv.id
            AND x.created_at > cm.last_read_at
            AND x.created_at >= cm.joined_at
            AND (cm.left_at IS NULL OR x.created_at <= cm.left_at)),
         CASE WHEN m.left_at IS NULL THEN
           -- Same cross-course rule as course_detail_data's offer lateral.
           (SELECT o.id FROM public.course_enrollment_offer o
            JOIN public.course oc ON oc.id = o.course_id
            WHERE o.user_id = m.user_id AND o.status = 'pending'
              AND (o.course_id = c.id OR (
                oc.professional_id = c.professional_id AND oc.sport_id = c.sport_id
                AND oc.status = 'active'
                AND NOT public.fn_is_course_member(oc.id, m.user_id)))
            LIMIT 1) END,
         CASE WHEN m.left_at IS NULL THEN
           (SELECT count(*)::integer FROM public.activity a
            WHERE a.course_id = c.id AND a.proposal_status = 'approved'
              AND a.start_time > now()
              AND NOT EXISTS (SELECT 1 FROM public.activity_confirmation ac
                              WHERE ac.activity_id = a.id AND ac.user_id = m.user_id))
         ELSE 0 END
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
  WHERE m.user_id = auth.uid()
    AND (m.left_at IS NULL OR public.fn_is_course_alumnus(c.id, m.user_id))
  -- Live courses first; finished ones sink below as history.
  ORDER BY (m.left_at IS NOT NULL), coalesce(last_msg.created_at, c.created_at) DESC;
$$;

-- ── 2. cancel_course_activity: a held session is history, not cancellable ───

CREATE OR REPLACE FUNCTION public.cancel_course_activity(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_start timestamptz;
        v_status public.activity_proposal_status;
BEGIN
  SELECT a.course_id, a.start_time, a.proposal_status INTO v_course, v_start, v_status
  FROM public.activity a
  WHERE a.id = p_activity_id AND a.course_id IS NOT NULL FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'course session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  -- Deleting a session that has started would cascade away its RSVPs and
  -- its immutable session reports.
  IF v_status = 'approved' AND v_start <= now() THEN
    RAISE EXCEPTION 'session already started';
  END IF;

  DELETE FROM public.activity WHERE id = p_activity_id;

  PERFORM public.fn_course_system_message(v_course, 'activity_cancelled',
    jsonb_build_object('start_time', v_start));
  PERFORM public.fn_enqueue_notification('course_activity_changed',
    (SELECT array_agg(m.user_id) FROM public.course_member m
     WHERE m.course_id = v_course AND m.status = 'enrolled'),
    'Buổi tập đã huỷ', 'Huấn luyện viên đã huỷ một buổi tập.',
    jsonb_build_object('course_id', v_course));
END
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────

REVOKE ALL ON FUNCTION public.course_detail_data(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.course_detail_data(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.my_courses_data() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_courses_data() TO authenticated;
REVOKE ALL ON FUNCTION public.cancel_course_activity(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_course_activity(uuid) TO authenticated;
