-- Part E of the coaching rework: rework the very first interaction with a
-- coach.
--
-- `start_course_inquiry` (course.sql) materialised the course + conversation
-- + membership the instant a student tapped "Nhắn tin", before they had
-- typed anything. That produced exactly the bugs live testing found: a
-- student who opened the thread and backed out left the coach a course-list
-- entry with no message and no way to tell who it was from, and zero
-- notification ever fired (nothing to notify about) — a permanent, inert
-- "ghost" the coach had no way to act on or dismiss.
--
-- Reworked so the inquiry is ephemeral client-side until a real first
-- message exists: nothing is written to `course`/`conversation`/
-- `conversation_member` until the student actually sends something.
-- `message_coach` does course-creation-if-needed and the first send in one
-- transaction, so "the first message atomically creates the course thread"
-- (the original spec's wording) is now literally true, not just aspirational.
--
-- Needs to be applied to the live Supabase project.

DROP FUNCTION IF EXISTS public.start_course_inquiry(uuid, bigint);

-- Read-only fast path: does the caller already have a live (inquiring or
-- enrolled) thread with this coach for this sport? Lets the client skip
-- straight to the existing course instead of re-entering the compose sheet.
CREATE OR REPLACE FUNCTION public.find_course_with_coach(
  p_professional_id uuid, p_sport_id bigint
) RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT m.course_id FROM public.course_member m
  WHERE m.user_id = auth.uid() AND m.professional_id = p_professional_id
    AND m.sport_id = p_sport_id AND m.status IN ('inquiring','enrolled')
  LIMIT 1;
$$;

-- The only way a course conversation can come into existence. Creates the
-- course/conversation/membership if this is a first contact, then delegates
-- the actual insert + notification to send_message — one code path for
-- "what happens when a message lands", not two. If a live thread already
-- exists (idempotent re-entry, or a race with find_course_with_coach), this
-- just posts into it rather than erroring.
CREATE OR REPLACE FUNCTION public.message_coach(
  p_professional_id uuid, p_sport_id bigint, p_body text
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_coach uuid; v_conversation uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  WHERE p.id = p_professional_id AND p.professional_role = 'coach';
  IF NOT FOUND THEN RAISE EXCEPTION 'coach not found'; END IF;
  IF v_coach = v_uid THEN RAISE EXCEPTION 'cannot coach yourself'; END IF;
  IF v_coach IS NOT NULL AND public.fn_is_blocked(v_uid, v_coach) THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  SELECT m.course_id INTO v_course FROM public.course_member m
  WHERE m.user_id = v_uid AND m.professional_id = p_professional_id
    AND m.sport_id = p_sport_id AND m.status IN ('inquiring','enrolled');

  IF v_course IS NULL THEN
    INSERT INTO public.course(professional_id, sport_id)
    VALUES (p_professional_id, p_sport_id) RETURNING id INTO v_course;

    INSERT INTO public.conversation(kind, course_id) VALUES ('course', v_course)
    RETURNING id INTO v_conversation;

    -- The coach is a conversation member but never a course_member: they own
    -- the course, they aren't enrolled in it.
    IF v_coach IS NOT NULL THEN
      INSERT INTO public.conversation_member(conversation_id, user_id)
      VALUES (v_conversation, v_coach);
    END IF;
    PERFORM public.fn_course_add_member(v_course, v_uid, 'inquiring');
  ELSE
    SELECT c.id INTO v_conversation FROM public.conversation c WHERE c.course_id = v_course;
  END IF;

  PERFORM public.send_message(v_conversation, p_body);

  RETURN v_course;
END
$$;

-- ── Read RPCs: carry the message kind/payload alongside the preview body ────
-- `course_card.dart` was rendering last_message_body raw. A system message's
-- body is a stable code ('member_left', 'enrollment_accepted', …), not
-- prose — without the kind, the card would leak the raw code. Under the
-- reworked flow a course's first message is always real text, so this isn't
-- needed to fix the "blank entry" bug any more, but it's still correct and
-- needed for every OTHER system event that can legitimately become "the last
-- message" later in a course's life. Same localisation contract as the chat
-- thread's own system rows (messaging.system.<code>, named args from payload).

-- Both functions gain columns in the middle of their return shape, which
-- Postgres won't allow via a bare CREATE OR REPLACE ("cannot change return
-- type of existing function") — drop first. This also resets their grants
-- back to the CREATE default (EXECUTE TO PUBLIC), so the grants DO block at
-- the end of this file explicitly includes both to restore
-- authenticated-only access.
DROP FUNCTION IF EXISTS public.my_courses_data();
DROP FUNCTION IF EXISTS public.pro_courses_data();

CREATE OR REPLACE FUNCTION public.my_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  member_status text, professional_id uuid, coach_name text, coach_avatar text,
  sport_id bigint, target_session_count integer, held_session_count integer,
  next_activity_id uuid, next_start_time timestamptz,
  last_message_at timestamptz, last_message_body text, last_message_kind text,
  last_message_payload jsonb, unread_count integer,
  pending_offer_id uuid, pending_rsvp_count integer
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT c.id, conv.id, c.name, c.status::text, m.status::text,
         c.professional_id, p.display_name, cu.details->>'generatedAvatar',
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

CREATE OR REPLACE FUNCTION public.pro_courses_data()
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, status text,
  sport_id bigint, student_count integer, inquiring_count integer,
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
  WHERE p.linked_user_id = auth.uid()
  ORDER BY coalesce(last_msg.created_at, c.created_at) DESC;
$$;

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname IN
             ('find_course_with_coach', 'message_coach',
              'my_courses_data', 'pro_courses_data')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;
