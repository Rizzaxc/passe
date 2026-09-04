-- Course activities become RPC-only at the data layer.
--
-- `schema/course.sql` retrofitted `course_id` onto `public.activity` and stated
-- that "everything goes through the SECURITY DEFINER RPCs below; these are
-- defence in depth". That is true of the five `course_*` tables (RLS on, no
-- policies, grants to `service_role` only). It was never true of `activity`,
-- which is `GRANT ALL ... TO authenticated` behind policies written before
-- courses existed that key only on `user_id = auth.uid()` and never mention
-- `course_id`. `propose_course_activity` sets `user_id = v_uid`, so the
-- proposer *owns* the row -- and every coach-only gate around a course session
-- was therefore bypassable with a direct PostgREST write:
--
--   * PATCH your own pending proposal to `proposal_status = 'approved'`,
--     bypassing `respond_course_proposal`'s `fn_is_course_coach` check;
--   * POST a fresh `approved` course activity while merely `inquiring`, which
--     is exactly the gate `course_permission_fixes.sql` tightened
--     (`fn_is_course_member` -> `fn_is_enrolled_course_member`) at the RPC
--     layer only;
--   * PATCH `start_time` on an approved session, skipping the RSVP wipe that
--     `reschedule_course_activity` performs deliberately;
--   * back-date a self-inserted `approved` session, RSVP `going`, leave, and
--     satisfy `submit_course_review`'s "actually attended" gate -- i.e.
--     review-bomb a coach, since `trg_course_review_rollup` feeds
--     `professional.average_rating`;
--   * insert into any course whose UUID is known (it travels in the `data`
--     payload of nine notification kinds and every `course_message`).
--
-- Two layers here, because the first is a policy predicate that a future edit
-- could silently drop:
--
--   1. `course_id IS NULL` on the three ownership policies. Lobby and freeplay
--      activities are unaffected, so the direct writers in
--      `lib/manage_tab/lobby_section/schedule_activity_controller.dart` keep
--      working. The course RPCs are SECURITY DEFINER owned by the table owner
--      and `activity` has no FORCE ROW LEVEL SECURITY, so they bypass RLS and
--      are untouched -- including `end_course`'s `DELETE ... WHERE course_id`.
--   2. A trigger that refuses a course-activity write arriving as a client
--      role at all. `proposal_status` needs no separate guard: the
--      `activity_course_has_proposal_status` CHECK makes it non-null only when
--      `course_id` is.
--
-- Deliberately NOT added: a course-aware SELECT policy. Course reads all go
-- through `course_detail_data` / `my_schedule_data`; the one direct read of
-- `activity` that can see a course session
-- (`manage_tab/schedule_section/controller.dart`) only harvests `lobby_id`,
-- which is null on a course row anyway. Adding one would widen the read
-- surface for nothing.

-- 1. Ownership policies: course rows are out of reach of the client roles.

ALTER POLICY "Users can create their own activities" ON public.activity
  WITH CHECK (user_id = (SELECT auth.uid()) AND course_id IS NULL);

ALTER POLICY "Owner or lobby manager can update activities" ON public.activity
  USING (
    course_id IS NULL
    AND (
      user_id = (SELECT auth.uid())
      OR (lobby_id IS NOT NULL AND public.lobby_can_manage(lobby_id))
    )
  )
  WITH CHECK (
    course_id IS NULL
    AND (
      user_id = (SELECT auth.uid())
      OR (lobby_id IS NOT NULL AND public.lobby_can_manage(lobby_id))
    )
  );

ALTER POLICY "Owner or lobby manager can delete activities" ON public.activity
  USING (
    course_id IS NULL
    AND (
      user_id = (SELECT auth.uid())
      OR (lobby_id IS NOT NULL AND public.lobby_can_manage(lobby_id))
    )
  );

-- 2. Belt and braces: no client role writes a course activity, ever.
--
-- SECURITY INVOKER is load-bearing -- a DEFINER trigger would always report
-- the owner as `current_user` and the check would never fire. Reached from one
-- of the course RPCs (SECURITY DEFINER, owner-owned) `current_user` is the
-- owner; reached from PostgREST it is `authenticated` (or `anon`). Denying
-- exactly those two rather than allowlisting the owner leaves `service_role`
-- and any future maintenance role working as before.

CREATE OR REPLACE FUNCTION public.fn_activity_course_write_guard()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path TO ''
AS $$
BEGIN
  IF NEW.course_id IS NULL
     AND (TG_OP = 'INSERT' OR OLD.course_id IS NULL) THEN
    RETURN NEW;
  END IF;

  IF current_user IN ('authenticated', 'anon') THEN
    RAISE EXCEPTION
      'course activities are managed through the course RPCs, not direct writes';
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.fn_activity_course_write_guard() OWNER TO postgres;

DROP TRIGGER IF EXISTS activity_course_write_guard ON public.activity;
CREATE TRIGGER activity_course_write_guard
  BEFORE INSERT OR UPDATE ON public.activity
  FOR EACH ROW EXECUTE FUNCTION public.fn_activity_course_write_guard();

-- 3. `anon` never had a policy on either table (every one is `TO authenticated`),
-- so these grants are inert -- but they are surface that should not exist.

REVOKE ALL ON TABLE public.activity FROM anon;
REVOKE ALL ON TABLE public.activity_confirmation FROM anon;
