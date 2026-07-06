-- Bug fix: "Users can view their own activities" restricts SELECT on public.activity to
-- user_id = auth.uid() — i.e. only the captain who created the row (activity.user_id is always
-- the scheduler). Every other lobby member is silently unable to see the lobby's own upcoming
-- activity: the pinned hero card, the upcoming-activity query, RSVP, everything downstream reads
-- straight from this table and gets zero rows for a non-captain. This is very likely why the
-- hero card was hardcoded/mocked in the client in the first place.
--
-- Fix: add a policy letting any member of the activity's lobby read it too. Captain-only
-- UPDATE/DELETE stays as-is (correct — only the scheduler/captain should edit or cancel).

CREATE POLICY "Lobby members can view their lobby's activities" ON public.activity
    FOR SELECT TO authenticated
    USING (
        lobby_id IS NOT NULL
        AND lobby_id IN (SELECT public.get_my_lobby_ids())
    );
