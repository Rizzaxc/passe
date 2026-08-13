-- ============================================================================
-- course.sql — Part B of the coaching-course build. Apply AFTER course_enums.sql
-- (and after messaging.sql / messaging_realtime.sql, which this builds on).
--
-- A **course** replaces per-lesson coach bookings as the container for a
-- coaching relationship: one coach, one fixed sport, many students, a
-- persistent thread, and sessions the coach approves.
--
-- Shape decisions worth knowing before editing:
--
-- * **The thread is the course.** Messaging a coach creates the course in
--   `inquiring` state; accepting an enrollment offer promotes the member. A
--   course that never gets an offer is simply an inquiry that went nowhere —
--   there is no separate "inquiry" object.
--
-- * **Late joiners don't get the back-story.** Members are added to the shared
--   `conversation_member` with `joined_at = now()`, and the visibility floor in
--   messaging.sql clamps their reads. A student enrolled on day 30 cannot read
--   the coach's day-1 exchange with a different student.
--
-- * **One enrolled coach per sport is a partial unique index**, not a trigger,
--   so concurrent accepts can't both win. That needs `sport_id` and
--   `professional_id` denormalised onto `course_member` (trigger-maintained).
--
-- * **Sessions are `activity` rows**, not a new table — RSVP
--   (`activity_confirmation`), health metrics, wall posts and the schedule all
--   already key off `activity`.
--
-- * **Courses carry no money.** No rate, no payment flow; a coach states rates
--   on their profile and settles off-app.
--
-- Idempotent / re-runnable. Needs to be applied to the live Supabase project.
-- ============================================================================

-- ── Tables ───────────────────────────────────────────────────────────────────

-- name/description/target are NULL until the first enrollment offer is
-- accepted — an inquiry has no course identity yet.
CREATE TABLE IF NOT EXISTS public.course (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  professional_id uuid NOT NULL REFERENCES public.professional(id) ON DELETE CASCADE,
  sport_id bigint NOT NULL REFERENCES public.sport(id),
  name text CHECK (name IS NULL OR char_length(btrim(name)) BETWEEN 1 AND 80),
  description text CHECK (description IS NULL OR char_length(description) <= 2000),
  target_session_count integer
    CHECK (target_session_count IS NULL OR target_session_count BETWEEN 1 AND 200),
  status public.course_status NOT NULL DEFAULT 'active',
  -- Set when the "you've hit your target" prompt is posted, so it fires once
  -- rather than on every session after the target.
  target_reached_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  CONSTRAINT course_ended_has_timestamp CHECK (
    (status = 'ended') = (ended_at IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS course_professional_idx
  ON public.course(professional_id, status);

-- professional_id / sport_id are denormalised copies of the parent course's,
-- maintained by trigger — they exist so the two rules below can be plain
-- partial unique indexes instead of race-prone triggers.
CREATE TABLE IF NOT EXISTS public.course_member (
  course_id uuid NOT NULL REFERENCES public.course(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  status public.course_member_status NOT NULL DEFAULT 'inquiring',
  professional_id uuid NOT NULL,
  sport_id bigint NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  PRIMARY KEY (course_id, user_id),
  CONSTRAINT course_member_departed_has_timestamp CHECK (
    (status IN ('left','removed')) = (left_at IS NOT NULL)
  )
);

-- A student may have only one enrolled coach per sport.
CREATE UNIQUE INDEX IF NOT EXISTS course_member_one_coach_per_sport
  ON public.course_member(user_id, sport_id) WHERE status = 'enrolled';

-- …and only one live thread with a given coach in a given sport, so "message
-- this coach" is idempotent rather than spawning a thread per tap.
CREATE UNIQUE INDEX IF NOT EXISTS course_member_one_live_thread
  ON public.course_member(user_id, professional_id, sport_id)
  WHERE status IN ('inquiring','enrolled');

CREATE INDEX IF NOT EXISTS course_member_user_idx ON public.course_member(user_id);

CREATE OR REPLACE FUNCTION public.fn_course_member_denormalise()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $$
BEGIN
  SELECT c.professional_id, c.sport_id INTO NEW.professional_id, NEW.sport_id
  FROM public.course c WHERE c.id = NEW.course_id;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_course_member_denormalise ON public.course_member;
CREATE TRIGGER trg_course_member_denormalise
  BEFORE INSERT ON public.course_member
  FOR EACH ROW EXECUTE FUNCTION public.fn_course_member_denormalise();

CREATE TABLE IF NOT EXISTS public.course_enrollment_offer (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL REFERENCES public.course(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  description text CHECK (description IS NULL OR char_length(description) <= 2000),
  target_session_count integer
    CHECK (target_session_count IS NULL OR target_session_count BETWEEN 1 AND 200),
  status public.course_offer_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz
);

CREATE UNIQUE INDEX IF NOT EXISTS course_offer_one_pending
  ON public.course_enrollment_offer(course_id, user_id) WHERE status = 'pending';

-- Private coach→student note on one session. Immutable: no UPDATE/DELETE
-- policies and the grants below withhold both.
CREATE TABLE IF NOT EXISTS public.course_session_report (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL REFERENCES public.course(id) ON DELETE CASCADE,
  activity_id uuid NOT NULL REFERENCES public.activity(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  body text NOT NULL CHECK (char_length(btrim(body)) BETWEEN 1 AND 1000),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (activity_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.course_review (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid NOT NULL REFERENCES public.course(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment text CHECK (comment IS NULL OR char_length(comment) <= 1000),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (course_id, student_id)
);

-- ── Activity extension ───────────────────────────────────────────────────────

ALTER TABLE public.activity ADD COLUMN IF NOT EXISTS course_id uuid
  REFERENCES public.course(id) ON DELETE CASCADE;
ALTER TABLE public.activity ADD COLUMN IF NOT EXISTS proposed_by uuid
  REFERENCES public."user"(id) ON DELETE SET NULL;
ALTER TABLE public.activity ADD COLUMN IF NOT EXISTS proposal_status
  public.activity_proposal_status;
-- Currently only written by course activities; kept generically named because
-- nothing about it is course-specific.
ALTER TABLE public.activity ADD COLUMN IF NOT EXISTS note text;

ALTER TABLE public.activity DROP CONSTRAINT IF EXISTS activity_note_length;
ALTER TABLE public.activity ADD CONSTRAINT activity_note_length
  CHECK (note IS NULL OR char_length(note) <= 280);

-- Built from the columns that actually exist: referee_booking_rename.sql drops
-- `professional_booking_id` later, and naming it unconditionally would make
-- this file fail on a re-run against an already-migrated database.
DO $$
DECLARE v_columns text;
BEGIN
  SELECT string_agg(c.column_name, ', ' ORDER BY c.column_name)
  INTO v_columns
  FROM information_schema.columns c
  WHERE c.table_schema = 'public' AND c.table_name = 'activity'
    AND c.column_name IN ('lobby_id','professional_booking_id','freeplay_host_id','course_id');

  EXECUTE 'ALTER TABLE public.activity DROP CONSTRAINT IF EXISTS activity_source_exclusivity';
  EXECUTE format(
    'ALTER TABLE public.activity ADD CONSTRAINT activity_source_exclusivity CHECK (num_nonnulls(%s) <= 1)',
    v_columns);
END$$;

-- A course activity always carries a proposal state; nothing else does.
ALTER TABLE public.activity DROP CONSTRAINT IF EXISTS activity_course_has_proposal_status;
ALTER TABLE public.activity ADD CONSTRAINT activity_course_has_proposal_status CHECK (
  (course_id IS NULL) = (proposal_status IS NULL)
);

CREATE INDEX IF NOT EXISTS activity_course_idx
  ON public.activity(course_id, start_time) WHERE course_id IS NOT NULL;

-- Wire the conversation FK now that `course` exists (messaging.sql leaves the
-- column FK-less so it can ship first).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'conversation_course_id_fkey'
  ) THEN
    ALTER TABLE public.conversation
      ADD CONSTRAINT conversation_course_id_fkey
      FOREIGN KEY (course_id) REFERENCES public.course(id) ON DELETE CASCADE;
  END IF;
END$$;

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Everything goes through the SECURITY DEFINER RPCs below; these are defence
-- in depth, matching the freeplay/messaging posture.

ALTER TABLE public.course ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_enrollment_offer ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_session_report ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.course_review ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.course, public.course_member, public.course_enrollment_offer,
  public.course_session_report, public.course_review FROM PUBLIC, anon, authenticated;

-- ── Helpers ──────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_is_course_coach(p_course_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course c
    JOIN public.professional p ON p.id = c.professional_id
    WHERE c.id = p_course_id AND p.linked_user_id = p_uid
  );
$$;
REVOKE ALL ON FUNCTION public.fn_is_course_coach(uuid,uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_is_course_member(p_course_id uuid, p_uid uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.course_member m
    WHERE m.course_id = p_course_id AND m.user_id = p_uid AND m.left_at IS NULL
  );
$$;
REVOKE ALL ON FUNCTION public.fn_is_course_member(uuid,uuid) FROM PUBLIC, anon, authenticated;

-- Held = approved, not cancelled, already finished. Cancelled sessions are
-- deleted outright (they stay in the feed as a system message), so "not
-- cancelled" needs no column.
CREATE OR REPLACE FUNCTION public.fn_course_held_sessions(p_course_id uuid)
RETURNS integer LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT count(*)::integer FROM public.activity a
  WHERE a.course_id = p_course_id
    AND a.proposal_status = 'approved'
    AND coalesce(a.end_time, a.start_time) < now();
$$;
REVOKE ALL ON FUNCTION public.fn_course_held_sessions(uuid) FROM PUBLIC, anon, authenticated;

-- Post a system event into the course thread. Body is a stable code the client
-- translates; payload carries the parameters.
CREATE OR REPLACE FUNCTION public.fn_course_system_message(
  p_course_id uuid, p_code text, p_payload jsonb DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_conversation uuid;
BEGIN
  SELECT c.id INTO v_conversation FROM public.conversation c WHERE c.course_id = p_course_id;
  IF v_conversation IS NULL THEN RETURN; END IF;
  INSERT INTO public.message(conversation_id, kind, body, payload)
  VALUES (v_conversation, 'system', p_code, p_payload);
END
$$;
REVOKE ALL ON FUNCTION public.fn_course_system_message(uuid,text,jsonb)
  FROM PUBLIC, anon, authenticated;

-- Add a member to both the course and its thread. `joined_at = now()` on the
-- conversation side is the visibility floor — deliberately not backdated.
CREATE OR REPLACE FUNCTION public.fn_course_add_member(
  p_course_id uuid, p_user_id uuid, p_status public.course_member_status
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_conversation uuid;
BEGIN
  INSERT INTO public.course_member(course_id, user_id, status)
  VALUES (p_course_id, p_user_id, p_status)
  ON CONFLICT (course_id, user_id) DO UPDATE
    SET status = excluded.status, left_at = NULL;

  SELECT c.id INTO v_conversation FROM public.conversation c WHERE c.course_id = p_course_id;
  IF v_conversation IS NOT NULL THEN
    INSERT INTO public.conversation_member(conversation_id, user_id)
    VALUES (v_conversation, p_user_id)
    ON CONFLICT (conversation_id, user_id) DO UPDATE SET left_at = NULL;
  END IF;
END
$$;
REVOKE ALL ON FUNCTION public.fn_course_add_member(uuid,uuid,public.course_member_status)
  FROM PUBLIC, anon, authenticated;

-- ── Write gate: teach fn_can_write_conversation about courses ────────────────
-- messaging.sql defines this freeplay-only and returns false for courses; this
-- REPLACE adds the course branch. Keep both branches in sync if either moves.
CREATE OR REPLACE FUNCTION public.fn_can_write_conversation(
  p_conversation_id uuid, p_uid uuid
) RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
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

  -- Course: an ended course is read-only for everyone, coach included.
  RETURN EXISTS (
    SELECT 1 FROM public.course c
    WHERE c.id = v_course AND c.status = 'active'
  );
END
$$;
REVOKE ALL ON FUNCTION public.fn_can_write_conversation(uuid,uuid)
  FROM PUBLIC, anon, authenticated;

-- Same story for send_message: messaging.sql only knows how to notify a
-- freeplay thread because `course_message` didn't exist as an enum value yet.
CREATE OR REPLACE FUNCTION public.send_message(p_conversation_id uuid, p_body text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_kind public.conversation_kind;
        v_data jsonb;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF nullif(btrim(p_body),'') IS NULL OR char_length(btrim(p_body)) > 2000 THEN
    RAISE EXCEPTION 'invalid message';
  END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, body)
  VALUES (p_conversation_id, v_uid, 'text', btrim(p_body))
  RETURNING id INTO v_id;

  SELECT c.kind INTO v_kind FROM public.conversation c WHERE c.id = p_conversation_id;

  IF v_kind = 'freeplay' THEN
    SELECT jsonb_build_object('activity_id', r.activity_id, 'request_id', r.id)
    INTO v_data FROM public.freeplay_request r
    JOIN public.conversation c ON c.freeplay_request_id = r.id
    WHERE c.id = p_conversation_id;
    PERFORM public.fn_notify_new_message(p_conversation_id, v_id,
      'freeplay_chat_message', v_uid, 'Tin nhắn Xé vé mới', 'Bạn có tin nhắn mới.', v_data);
  ELSE
    SELECT jsonb_build_object('course_id', c.course_id) INTO v_data
    FROM public.conversation c WHERE c.id = p_conversation_id;
    PERFORM public.fn_notify_new_message(p_conversation_id, v_id,
      'course_message', v_uid, 'Tin nhắn mới', 'Bạn có tin nhắn mới.', v_data);
  END IF;

  RETURN v_id;
END
$$;

-- ── Lifecycle RPCs ───────────────────────────────────────────────────────────

-- Messaging a coach is handled by `find_course_with_coach` (read-only fast
-- path to an existing thread) and `message_coach` (creates the course on
-- first contact and sends the first message atomically) in
-- schema/course_inquiry_notify.sql. There used to be a `start_course_inquiry`
-- here that materialised the course the instant "Nhắn tin" was tapped, before
-- any message existed — retired: a student who opened the thread and backed
-- out left the coach a course-list entry with no message, no sender, and no
-- notification, with no way to act on or dismiss it. Nothing is written to
-- `course`/`conversation`/`conversation_member` now until a real first
-- message exists — see that file for the actual definitions.

-- Also the invite path: offering to someone who isn't in the course yet adds
-- them as `inquiring` first.
CREATE OR REPLACE FUNCTION public.send_enrollment_offer(
  p_course_id uuid, p_user_id uuid, p_name text,
  p_description text DEFAULT NULL, p_target_session_count integer DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.course WHERE id = p_course_id AND status = 'active') THEN
    RAISE EXCEPTION 'course is not active';
  END IF;
  IF nullif(btrim(p_name),'') IS NULL THEN RAISE EXCEPTION 'name required'; END IF;

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

CREATE OR REPLACE FUNCTION public.respond_enrollment_offer(
  p_offer_id uuid, p_accept boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_offer record; v_coach uuid; v_username text;
BEGIN
  SELECT o.*, c.professional_id, c.sport_id INTO v_offer
  FROM public.course_enrollment_offer o
  JOIN public.course c ON c.id = o.course_id
  WHERE o.id = p_offer_id AND o.user_id = v_uid AND o.status = 'pending'
  FOR UPDATE OF o;
  IF NOT FOUND THEN RAISE EXCEPTION 'pending offer not found'; END IF;

  IF NOT p_accept THEN
    UPDATE public.course_enrollment_offer
    SET status = 'declined', responded_at = now() WHERE id = p_offer_id;
    RETURN;
  END IF;

  -- The one-coach-per-sport index is the real gate; this check exists to give
  -- a comprehensible error instead of a unique-violation.
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

  -- First acceptance gives the course its identity.
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

-- A departure only matters here if it was an *enrolled* student leaving —
-- an inquiring lead going cold isn't "the course losing its last student".
-- Mirrors fn_sweep_course_targets' posture exactly: prompt, never
-- auto-close. Only the coach ends a course (see end_course) — that
-- invariant holds even when the roster hits zero.
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
    -- Reuses the 'course_ended' kind, same as the target-reached sweep — the
    -- client already renders it as a generic "look at this course" prompt.
    PERFORM public.fn_enqueue_notification('course_ended', ARRAY[v_coach],
      'Khoá học không còn học viên', 'Bạn có thể mời học viên mới hoặc kết thúc khoá học.',
      jsonb_build_object('course_id', p_course_id));
  END IF;
END
$$;
REVOKE ALL ON FUNCTION public.fn_course_prompt_if_no_students(uuid,boolean)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.leave_course(p_course_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_username text; v_was_enrolled boolean;
BEGIN
  SELECT (m.status = 'enrolled') INTO v_was_enrolled FROM public.course_member m
  WHERE m.course_id = p_course_id AND m.user_id = v_uid AND m.left_at IS NULL;

  UPDATE public.course_member SET status = 'left', left_at = now()
  WHERE course_id = p_course_id AND user_id = v_uid AND left_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'membership not found'; END IF;

  UPDATE public.conversation_member SET left_at = now()
  WHERE user_id = v_uid
    AND conversation_id = (SELECT id FROM public.conversation WHERE course_id = p_course_id);

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = v_uid;
  PERFORM public.fn_course_system_message(p_course_id, 'member_left',
    jsonb_build_object('username', v_username));

  PERFORM public.fn_course_prompt_if_no_students(p_course_id, coalesce(v_was_enrolled, false));
END
$$;

CREATE OR REPLACE FUNCTION public.remove_course_member(p_course_id uuid, p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_username text; v_was_enrolled boolean;
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  SELECT (m.status = 'enrolled') INTO v_was_enrolled FROM public.course_member m
  WHERE m.course_id = p_course_id AND m.user_id = p_user_id AND m.left_at IS NULL;

  UPDATE public.course_member SET status = 'removed', left_at = now()
  WHERE course_id = p_course_id AND user_id = p_user_id AND left_at IS NULL;
  IF NOT FOUND THEN RAISE EXCEPTION 'membership not found'; END IF;

  UPDATE public.conversation_member SET left_at = now()
  WHERE user_id = p_user_id
    AND conversation_id = (SELECT id FROM public.conversation WHERE course_id = p_course_id);

  SELECT u.username::text INTO v_username FROM public."user" u WHERE u.id = p_user_id;
  PERFORM public.fn_course_system_message(p_course_id, 'member_removed',
    jsonb_build_object('username', v_username));
  PERFORM public.fn_enqueue_notification('course_member_removed', ARRAY[p_user_id],
    'Bạn đã rời khoá học', 'Huấn luyện viên đã kết thúc khoá học với bạn.',
    jsonb_build_object('course_id', p_course_id));

  PERFORM public.fn_course_prompt_if_no_students(p_course_id, coalesce(v_was_enrolled, false));
END
$$;

CREATE OR REPLACE FUNCTION public.end_course(p_course_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_students uuid[];
BEGIN
  IF NOT public.fn_is_course_coach(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  UPDATE public.course SET status = 'ended', ended_at = now()
  WHERE id = p_course_id AND status = 'active';
  IF NOT FOUND THEN RAISE EXCEPTION 'active course not found'; END IF;

  -- Upcoming approved sessions can't survive the course.
  DELETE FROM public.activity
  WHERE course_id = p_course_id AND start_time > now();

  PERFORM public.fn_course_system_message(p_course_id, 'course_ended');

  SELECT array_agg(m.user_id) INTO v_students FROM public.course_member m
  WHERE m.course_id = p_course_id AND m.status = 'enrolled';
  IF v_students IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_ended', v_students,
      'Khoá học đã kết thúc', 'Bạn có thể đánh giá huấn luyện viên.',
      jsonb_build_object('course_id', p_course_id));
  END IF;
END
$$;

-- ── Sessions ─────────────────────────────────────────────────────────────────

-- Overlap warning for a coach's own diary. Soft — the client warns, it never
-- blocks (same posture as the booking sheet's conflict check). Deliberately
-- returns times only: a student proposing a slot must not be able to probe
-- who else their coach teaches, or when.
CREATE OR REPLACE FUNCTION public.course_activity_conflicts(
  p_professional_id uuid, p_start timestamptz, p_end timestamptz
) RETURNS TABLE(start_time timestamptz, end_time timestamptz)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.start_time, coalesce(a.end_time, a.start_time)
  FROM public.activity a
  JOIN public.course c ON c.id = a.course_id
  WHERE c.professional_id = p_professional_id
    AND a.proposal_status = 'approved'
    AND a.start_time < p_end
    AND coalesce(a.end_time, a.start_time) > p_start;
$$;

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
  IF NOT v_is_coach AND NOT public.fn_is_course_member(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'course access required';
  END IF;
  IF p_end IS NOT NULL AND p_end <= p_start THEN RAISE EXCEPTION 'invalid time range'; END IF;
  IF p_start <= now() THEN RAISE EXCEPTION 'cannot schedule in the past'; END IF;

  SELECT c.sport_id INTO v_sport FROM public.course c WHERE c.id = p_course_id;

  -- The sport is the course's, never the caller's choice.
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

CREATE OR REPLACE FUNCTION public.respond_course_proposal(
  p_activity_id uuid, p_approve boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_proposer uuid;
BEGIN
  SELECT a.course_id, a.proposed_by INTO v_course, v_proposer
  FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'pending' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'pending proposal not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;

  UPDATE public.activity
  SET proposal_status = (CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END)
        ::public.activity_proposal_status
  WHERE id = p_activity_id;

  PERFORM public.fn_course_system_message(v_course,
    CASE WHEN p_approve THEN 'activity_approved' ELSE 'activity_rejected' END,
    jsonb_build_object('activity_id', p_activity_id));

  IF p_approve THEN
    PERFORM public.fn_enqueue_notification('course_activity_approved',
      (SELECT array_agg(m.user_id) FROM public.course_member m
       WHERE m.course_id = v_course AND m.status = 'enrolled'),
      'Buổi tập đã được duyệt', 'Đề xuất buổi tập đã được duyệt.',
      jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
  ELSIF v_proposer IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification('course_activity_changed', ARRAY[v_proposer],
      'Đề xuất bị từ chối', 'Huấn luyện viên đã từ chối đề xuất của bạn.',
      jsonb_build_object('course_id', v_course, 'activity_id', p_activity_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.withdraw_course_proposal(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'pending'
    AND a.proposed_by = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'own pending proposal not found'; END IF;

  UPDATE public.activity SET proposal_status = 'withdrawn' WHERE id = p_activity_id;
  PERFORM public.fn_course_system_message(v_course, 'activity_withdrawn',
    jsonb_build_object('activity_id', p_activity_id));
END
$$;

-- Rescheduling clears RSVPs: "going" answered a different question.
CREATE OR REPLACE FUNCTION public.reschedule_course_activity(
  p_activity_id uuid, p_start timestamptz, p_end timestamptz,
  p_location_id uuid DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid;
BEGIN
  SELECT a.course_id INTO v_course FROM public.activity a
  WHERE a.id = p_activity_id AND a.proposal_status = 'approved' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'approved session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
  END IF;
  IF p_end IS NOT NULL AND p_end <= p_start THEN RAISE EXCEPTION 'invalid time range'; END IF;

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

-- Cancelled sessions leave the schedule but stay in the feed as a system
-- event, and never count toward the target.
CREATE OR REPLACE FUNCTION public.cancel_course_activity(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_course uuid; v_start timestamptz;
BEGIN
  SELECT a.course_id, a.start_time INTO v_course, v_start FROM public.activity a
  WHERE a.id = p_activity_id AND a.course_id IS NOT NULL FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'course session not found'; END IF;
  IF NOT public.fn_is_course_coach(v_course, v_uid) THEN
    RAISE EXCEPTION 'coach access required';
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

-- ── Reports & reviews (both immutable) ───────────────────────────────────────

-- One report per (session, student), coach-authored, only for students who
-- RSVP'd `going`. No deadline, no edit, no delete.
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
  IF NOT EXISTS (
    SELECT 1 FROM public.activity_confirmation ac
    WHERE ac.activity_id = p_activity_id AND ac.user_id = p_student_id
      AND ac.attendance = 'going'
  ) THEN RAISE EXCEPTION 'student did not attend'; END IF;
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

-- One review per student per course. Available once the course has ended OR
-- the student has left/been removed — and only if they actually attended a
-- session, so a review always reflects real coaching.
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
    JOIN public.activity_confirmation ac ON ac.activity_id = a.id
    WHERE a.course_id = p_course_id AND ac.user_id = v_uid
      AND ac.attendance = 'going' AND a.proposal_status = 'approved'
      AND coalesce(a.end_time, a.start_time) < now()
  ) THEN RAISE EXCEPTION 'no attended session to review'; END IF;

  -- A review is final. The unique index is the real guard; this turns the
  -- constraint violation into something the client can show a user.
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

-- Roll a course review up into the professional's headline rating — the same
-- job professional_booking_review's trigger did for bookings.
CREATE OR REPLACE FUNCTION public.fn_course_review_rollup()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_professional uuid;
BEGIN
  SELECT c.professional_id INTO v_professional
  FROM public.course c WHERE c.id = NEW.course_id;

  UPDATE public.professional p SET
    average_rating = sub.avg_rating,
    review_count = sub.total
  FROM (
    SELECT avg(r.rating)::numeric(3,2) AS avg_rating, count(*) AS total
    FROM public.course_review r
    JOIN public.course c ON c.id = r.course_id
    WHERE c.professional_id = v_professional
  ) sub
  WHERE p.id = v_professional;
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_course_review_rollup ON public.course_review;
CREATE TRIGGER trg_course_review_rollup
  AFTER INSERT ON public.course_review
  FOR EACH ROW EXECUTE FUNCTION public.fn_course_review_rollup();

-- ── Target-reached sweep ─────────────────────────────────────────────────────
-- "Sessions held" only changes as time passes, so no trigger can catch it —
-- this rides the existing 1-minute cron tick. `target_reached_at` makes it
-- fire once; reaching the target prompts, it never closes the course.
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
      PERFORM public.fn_enqueue_notification('course_ended', ARRAY[v_coach],
        'Khoá học đã đủ số buổi', 'Bạn có thể gia hạn hoặc kết thúc khoá học.',
        jsonb_build_object('course_id', r.id));
    END IF;
  END LOOP;
END
$$;
REVOKE ALL ON FUNCTION public.fn_sweep_course_targets() FROM PUBLIC, anon, authenticated;

-- Re-emitted with the course sweep appended. Keep in sync with the definition
-- in schema/freeplay.sql if either changes.
CREATE OR REPLACE FUNCTION public.fn_cron_tick()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  PERFORM public.fn_sweep_challenges();
  PERFORM public.fn_sweep_activity_payment_requests();
  PERFORM public.fn_sweep_freeplay();
  PERFORM public.fn_sweep_course_targets();
  PERFORM public.fn_process_reminders();
  IF EXISTS(SELECT 1 FROM public.notification_outbox WHERE status IN ('pending','sending')) THEN
    PERFORM public.fn_invoke_send_push();
  END IF;
END
$$;

-- ── Read RPCs ────────────────────────────────────────────────────────────────

-- Player-side hub: every course/inquiry the caller belongs to.
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
  -- `professional` has no avatar of its own; it comes from the coach's user row.
  -- last_message_kind/_payload travel alongside the body so the client can
  -- localise a system-event preview ('inquiry_started', etc) the same way
  -- the chat thread itself does, instead of rendering the raw stable code.
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

-- Coach-side inbox: same shape, from the other end of the relationship.
-- `pending_proposal_count` and `pending_report_count` are the coach's to-do.
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

-- One course: header, roster, and every session the caller may see.
-- Reports are filtered to the caller's own unless they're the coach — a
-- student must never read another student's write-up.
-- `my_member_status` (null for the coach) lets the client tell an inquiring
-- (unenrolled) student apart from an enrolled one — see
-- course_viewer_status.sql for why that matters.
CREATE OR REPLACE FUNCTION public.course_detail_data(p_course_id uuid)
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

-- ── Grants ───────────────────────────────────────────────────────────────────

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname IN (
             'send_enrollment_offer','respond_enrollment_offer',
             'leave_course','remove_course_member','end_course',
             'propose_course_activity','respond_course_proposal','withdraw_course_proposal',
             'reschedule_course_activity','cancel_course_activity',
             'submit_session_report','submit_course_review','course_activity_conflicts',
             'my_courses_data','pro_courses_data','course_detail_data')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;
