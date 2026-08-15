-- Part G of the coaching rework: fix the dedup logic around an ended course.
--
-- `end_course` flipped `course.status` to 'ended' but never touched the
-- roster's `course_member` rows — every member stayed 'inquiring'/'enrolled'
-- forever, which is exactly the status set that
-- `course_member_one_coach_per_sport` (one *enrolled* coach per sport) and
-- `course_member_one_live_thread` (one live thread per coach+sport) key off
-- of. Concretely: a student whose coach ended their course could never
-- enroll with a *different* coach in that sport again —
-- `respond_enrollment_offer`'s own "already enrolled with a coach for this
-- sport" check (schema/course.sql) fires against the dead course's stale
-- 'enrolled' row, which is also what the unique index itself would raise a
-- bare violation on if that check weren't there.
--
-- Fix: `end_course` now demotes every live member row to 'left' (the same
-- terminal status `leave_course` uses — "the course is over" reads the same
-- as "you left it" for dedup purposes), freeing both partial unique
-- indexes. No new `course_member_status` enum value needed. Re-messaging
-- the same coach afterwards now correctly opens a brand new inquiry rather
-- than silently reusing a dead course's conversation.
--
-- Needs to be applied to the live Supabase project.

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

  -- Free the one-coach-per-sport / one-live-thread partial unique indexes —
  -- an ended course's membership is no longer "live". Mirrors leave_course's
  -- own transition, just applied to the whole roster at once.
  UPDATE public.course_member SET status = 'left', left_at = now()
  WHERE course_id = p_course_id AND status IN ('inquiring','enrolled');
END
$$;
