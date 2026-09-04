-- Authorization gaps in the course RPCs, found vetting the coach flow.
--
-- Each function is replaced in place, keeping its signature, SECURITY DEFINER
-- and `search_path TO ''`. `CREATE OR REPLACE` preserves grants, but the
-- REVOKE/GRANT pairs are re-issued anyway: `referee_course_fn_grant_hardening.sql`
-- exists because a rename once reset these to the `EXECUTE TO PUBLIC` default,
-- and re-stating them is cheaper than discovering that again.
--
-- Deliberately NOT done here:
--   * an `is_verified` gate on `message_coach`. `request_referee_booking` has
--     one, but `home_professional_data` only *sorts* by `is_verified` -- it
--     does not filter -- so unverified coaches are legitimately discoverable
--     by authenticated users today. Adding the gate would break messaging for
--     coaches the app itself still lists.
--   * a rate limit on `message_coach`. The real fix needs per-user state to
--     count against; `course_member_one_live_thread` plus the new
--     sport-offered check below already cap a spammer at one thread per sport
--     the coach actually teaches.

-- 1. `send_enrollment_offer` took an arbitrary `p_user_id`.
--
-- It was coach-gated but recipient-unvalidated: `fn_course_add_member` would
-- force-join *any* uuid in the system to the course and to its conversation,
-- with no consent step and -- the part that matters -- no block check. That
-- let a coach reach a user who had blocked them, bypassing the `fn_is_blocked`
-- gate `message_coach` enforces on the way in, and (via `course_detail_data`,
-- which admits `inquiring` members) hand that stranger the full student roster.
-- The cold-invite case stays supported: it backs the offer sheet's username
-- search, which is the only way to enroll someone who never messaged first.

CREATE OR REPLACE FUNCTION public.send_enrollment_offer(
  p_course_id uuid, p_user_id uuid, p_name text,
  p_description text DEFAULT NULL::text,
  p_target_session_count integer DEFAULT NULL::integer)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RAISE EXCEPTION 'course is not active';
  END IF;
  IF nullif(btrim(p_name),'') IS NULL THEN RAISE EXCEPTION 'name required'; END IF;

  IF p_user_id IS NULL THEN RAISE EXCEPTION 'no target user'; END IF;
  IF p_user_id = v_uid THEN RAISE EXCEPTION 'cannot enroll yourself'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public."user" u WHERE u.id = p_user_id) THEN
    RAISE EXCEPTION 'user not found';
  END IF;
  IF public.fn_is_blocked(v_uid, p_user_id) THEN
    RAISE EXCEPTION 'not allowed';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_user_id AND m.left_at IS NULL
  ) THEN
    PERFORM public.fn_course_add_member(p_course_id, p_user_id, 'inquiring');
  END IF;

  INSERT INTO public.course_enrollment_offer(
    course_id, user_id, name, description, target_session_count)
  VALUES (p_course_id, p_user_id, btrim(p_name), p_description, p_target_session_count)
  RETURNING id INTO v_id;

  PERFORM public.fn_enqueue_notification('course_enrollment_offer', ARRAY[p_user_id],
    'Lời mời tham gia khoá học', btrim(p_name),
    jsonb_build_object('course_id', p_course_id, 'offer_id', v_id));
  RETURN v_id;
END
$$;

REVOKE ALL ON FUNCTION public.send_enrollment_offer(uuid, uuid, text, text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_enrollment_offer(uuid, uuid, text, text, integer) TO authenticated;

-- 2. `course_activity_conflicts` had no authorization at all.
--
-- Its own header argued a student "must not be able to probe who else their
-- coach teaches, or when" and then returned times for any `p_professional_id`,
-- to any authenticated caller, over any range -- i.e. any coach's entire
-- approved calendar, for all time. Caller must now be that coach or a live
-- member of one of their courses, and the window is capped.
--
-- Returning no rows (rather than raising) for a caller who fails the check is
-- deliberate: the client reads this as "no clash", and the whole feature warns
-- but never blocks, so failing closed here degrades to today's warn-nothing
-- behaviour instead of an error toast on a legitimate scheduling attempt.

CREATE OR REPLACE FUNCTION public.course_activity_conflicts(
  p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone)
RETURNS TABLE(start_time timestamp with time zone, end_time timestamp with time zone)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
  SELECT a.start_time, coalesce(a.end_time, a.start_time)
  FROM public.activity a
  JOIN public.course c ON c.id = a.course_id
  WHERE c.professional_id = p_professional_id
    AND a.proposal_status = 'approved'
    AND a.start_time < p_end
    AND coalesce(a.end_time, a.start_time) > p_start
    AND p_end > p_start
    AND p_end - p_start <= interval '31 days'
    AND (
      EXISTS (
        SELECT 1 FROM public.professional pr
        WHERE pr.id = p_professional_id AND pr.linked_user_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM public.course_member cm
        WHERE cm.professional_id = p_professional_id
          AND cm.user_id = auth.uid() AND cm.left_at IS NULL
      )
    );
$$;

REVOKE ALL ON FUNCTION public.course_activity_conflicts(uuid, timestamp with time zone, timestamp with time zone) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.course_activity_conflicts(uuid, timestamp with time zone, timestamp with time zone) TO authenticated;

-- 3. The course branch of `fn_can_write_conversation` had no block check.
--
-- The freeplay branch carries `NOT fn_is_blocked(...)`; the course branch
-- returned true for any live member of an active course, so a coach and a
-- student who had blocked each other kept messaging indefinitely. Only the
-- coach edge is tested: a course thread is coach <-> student(s), and
-- student-to-student blocking inside one course is a separate question.

CREATE OR REPLACE FUNCTION public.fn_can_write_conversation(p_conversation_id uuid, p_uid uuid)
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_kind public.conversation_kind; v_request uuid; v_course uuid;
BEGIN
  SELECT c.kind, c.freeplay_request_id, c.course_id
  INTO v_kind, v_request, v_course
  FROM public.conversation c WHERE c.id = p_conversation_id;
  IF NOT FOUND THEN RETURN false; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id = p_uid AND m.left_at IS NULL
  ) THEN RETURN false; END IF;

  IF v_kind = 'freeplay' THEN
    RETURN coalesce((
      SELECT CASE
        WHEN r.status = 'pending' THEN a.end_time > now()
        WHEN r.status = 'accepted' THEN a.end_time + interval '7 days' > now()
        WHEN r.status = 'host_cancelled' THEN a.end_time + interval '7 days' > now()
        ELSE false END
      FROM public.freeplay_request r
      JOIN public.activity a ON a.id = r.activity_id
      JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
      WHERE r.id = v_request
        AND NOT public.fn_is_blocked(r.user_id, h.user_id)
    ), false);
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.course c
    JOIN public.professional p ON p.id = c.professional_id
    WHERE c.id = v_course
      AND c.status = 'active'
      AND (p.linked_user_id IS NULL OR NOT public.fn_is_blocked(p_uid, p.linked_user_id))
  );
END
$$;

REVOKE ALL ON FUNCTION public.fn_can_write_conversation(uuid, uuid) FROM PUBLIC, anon, authenticated;

-- 4. `respond_enrollment_offer` never checked the course was still active.
--
-- `end_course` demotes every member to 'left' with `left_at` set, but leaves
-- pending offers pending. Accepting one then tried to set that member back to
-- 'enrolled' with `left_at` still populated, tripping
-- `course_member_departed_has_timestamp` -- the caller saw a raw CHECK
-- violation instead of "this offer is gone".

CREATE OR REPLACE FUNCTION public.respond_enrollment_offer(p_offer_id uuid, p_accept boolean)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_uid uuid := auth.uid(); v_offer record; v_coach uuid; v_username text;
BEGIN
  SELECT o.*, c.professional_id, c.sport_id INTO v_offer
  FROM public.course_enrollment_offer o
  JOIN public.course c ON c.id = o.course_id
  WHERE o.id = p_offer_id AND o.user_id = v_uid AND o.status = 'pending'
    AND c.status = 'active'
  FOR UPDATE OF o;
  IF NOT FOUND THEN RAISE EXCEPTION 'pending offer not found'; END IF;

  IF NOT p_accept THEN
    UPDATE public.course_enrollment_offer
    SET status = 'declined', responded_at = now() WHERE id = p_offer_id;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.user_id = v_uid AND m.sport_id = v_offer.sport_id
      AND m.status = 'enrolled' AND m.course_id <> v_offer.course_id
  ) THEN
    RAISE EXCEPTION 'already enrolled with a coach for this sport';
  END IF;

  UPDATE public.course_enrollment_offer
  SET status = 'accepted', responded_at = now() WHERE id = p_offer_id;

  UPDATE public.course_member SET status = 'enrolled'
  WHERE course_id = v_offer.course_id AND user_id = v_uid;

  UPDATE public.course SET
    name = coalesce(name, v_offer.name),
    description = coalesce(description, v_offer.description),
    target_session_count = coalesce(target_session_count, v_offer.target_session_count)
  WHERE id = v_offer.course_id;

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;
  PERFORM public.fn_course_system_message(v_offer.course_id, 'enrollment_accepted',
    jsonb_build_object('username', v_username));

  SELECT p.linked_user_id INTO v_coach FROM public.professional p
  WHERE p.id = v_offer.professional_id;
  IF v_coach IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_enrollment_accepted', ARRAY[v_coach],
      'Học viên đã tham gia', coalesce(v_username,'') || ' đã tham gia khoá học.',
      jsonb_build_object('course_id', v_offer.course_id));
  END IF;
END
$$;

REVOKE ALL ON FUNCTION public.respond_enrollment_offer(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.respond_enrollment_offer(uuid, boolean) TO authenticated;

-- 5. `reschedule_course_activity` could move a session into the past.
--
-- `propose_course_activity` rejects `p_start <= now()`; this one did not. A
-- session dragged backwards is instantly "held" by `fn_course_held_sessions`,
-- which drives the target sweep and the "attended a finished session" gate on
-- `submit_course_review`.

CREATE OR REPLACE FUNCTION public.reschedule_course_activity(
  p_activity_id uuid, p_start timestamp with time zone,
  p_end timestamp with time zone, p_location_id uuid DEFAULT NULL::uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'approved session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
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

REVOKE ALL ON FUNCTION public.reschedule_course_activity(uuid, timestamp with time zone, timestamp with time zone, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reschedule_course_activity(uuid, timestamp with time zone, timestamp with time zone, uuid) TO authenticated;

-- 6. `message_coach` never checked the coach teaches the requested sport.
--
-- The client always sends the context sport (`professional/main.dart`'s
-- `_messageCoach`), which has nothing to do with what the coach is listed for,
-- so viewing a badminton coach with soccer selected created a soccer course
-- that coach never offered. `request_referee_booking` already enforces the
-- equivalent (`v_sports @> ARRAY[v_service_sport]`).

CREATE OR REPLACE FUNCTION public.message_coach(
  p_professional_id uuid, p_sport_id bigint, p_body text)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_coach uuid; v_conversation uuid;
        v_sports bigint[];
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;

  SELECT p.linked_user_id, p.sports INTO v_coach, v_sports
  FROM public.professional p
  WHERE p.id = p_professional_id AND p.professional_role = 'coach';
  IF NOT FOUND THEN RAISE EXCEPTION 'coach not found'; END IF;
  IF v_coach = v_uid THEN RAISE EXCEPTION 'cannot coach yourself'; END IF;
  IF NOT (v_sports @> ARRAY[p_sport_id]) THEN
    RAISE EXCEPTION 'coach does not teach this sport';
  END IF;
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

REVOKE ALL ON FUNCTION public.message_coach(uuid, bigint, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.message_coach(uuid, bigint, text) TO authenticated;

-- 7. Two `authenticated`-granted helpers took a caller-supplied `p_uid`.
--
-- Both exist to be evaluated inside RLS `USING`/`WITH CHECK`, which runs as the
-- querying role, so they must stay granted -- but every call site passes
-- `auth.uid()`. Left as-is they were membership oracles: "is user X enrolled in
-- the course owning activity Y", "is user X live in conversation Z", for any
-- uuid a caller knows. The signatures stay (the policies reference them).

CREATE OR REPLACE FUNCTION public.fn_can_access_course_activity(p_activity_id uuid, p_uid uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
  SELECT p_uid IS NOT DISTINCT FROM auth.uid() AND EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.id = p_activity_id AND a.course_id IS NOT NULL
      AND (
        public.fn_is_enrolled_course_member(a.course_id, p_uid)
        OR public.fn_is_course_coach(a.course_id, p_uid)
      )
  );
$$;

REVOKE ALL ON FUNCTION public.fn_can_access_course_activity(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_can_access_course_activity(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_can_receive_conversation_topic(p_topic text, p_uid uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
  SELECT p_uid IS NOT DISTINCT FROM auth.uid() AND EXISTS (
    SELECT 1 FROM public.conversation_member cm
    WHERE cm.user_id = p_uid
      AND cm.left_at IS NULL
      AND p_topic = 'conversation:' || cm.conversation_id::text
  );
$$;

REVOKE ALL ON FUNCTION public.fn_can_receive_conversation_topic(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_can_receive_conversation_topic(text, uuid) TO authenticated;

-- 8. `taggable_users` was the one course-adjacent SECURITY DEFINER function
-- declared `SET search_path TO 'public'` instead of `''`. Every reference in it
-- is already schema-qualified, so this is not a live exploit -- it is the
-- invariant the rest of this layer relies on, restored. Body unchanged.

ALTER FUNCTION public.taggable_users(uuid) SET search_path TO '';

-- 9. `trg_course_member_denormalise` was BEFORE INSERT only.
--
-- `course_member.professional_id` / `sport_id` are denormalised copies that back
-- both partial unique indexes -- `course_member_one_coach_per_sport` and
-- `course_member_one_live_thread`, i.e. "one enrolled coach per sport" and "one
-- live thread per coach+sport". An UPDATE moving `course_id` left them stale and
-- silently broke both. Nothing does that today; the invariant should not depend
-- on that staying true.

DROP TRIGGER IF EXISTS trg_course_member_denormalise ON public.course_member;
CREATE TRIGGER trg_course_member_denormalise
  BEFORE INSERT OR UPDATE OF course_id ON public.course_member
  FOR EACH ROW EXECUTE FUNCTION public.fn_course_member_denormalise();
