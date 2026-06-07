-- ============================================================================
-- RLS for lobby_feed_item, lobby_feed_poll_vote, lobby_match
--
-- Visibility model:
--   * Feed items + poll votes + match rows are private to lobby members.
--   * Members can read everything inside their lobby; matches are also
--     visible to the opponent lobby so both sides can review a result.
--
-- Write model:
--   * Personal & photo feed items: any member can post; author must be
--     themselves.
--   * Update / poll feed items: captain only.
--   * System feed items: triggers only (every direct INSERT denied).
--   * Poll votes: a user votes / changes / deletes their own row.
--   * Match rows: only the captain of the home lobby (the row's lobby_id)
--     can write — they own the record.
--
-- All policies use auth.uid() through `( SELECT auth.uid() )` to let
-- Postgres cache the value for the query (matches the style already in
-- passe.sql). `get_my_lobby_ids()` is a SECURITY DEFINER helper that
-- short-circuits the membership check.
-- ============================================================================


-- ─── Enable RLS ────────────────────────────────────────────────

ALTER TABLE public.lobby_feed_item       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lobby_feed_poll_vote  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lobby_match           ENABLE ROW LEVEL SECURITY;


-- ─── lobby_feed_item ───────────────────────────────────────────

DROP POLICY IF EXISTS "Members can read feed items in their lobby"
    ON public.lobby_feed_item;

CREATE POLICY "Members can read feed items in their lobby"
    ON public.lobby_feed_item
    FOR SELECT
    TO authenticated
    USING (lobby_id IN (SELECT public.get_my_lobby_ids()));


DROP POLICY IF EXISTS "Members can post personal or photo items"
    ON public.lobby_feed_item;

-- Personal updates and attached photos can be posted by any member. The
-- author column has to match the caller so people can't ghost-write for
-- each other.
CREATE POLICY "Members can post personal or photo items"
    ON public.lobby_feed_item
    FOR INSERT
    TO authenticated
    WITH CHECK (
        author_id = (SELECT auth.uid())
        AND lobby_id IN (SELECT public.get_my_lobby_ids())
        AND kind IN ('personal', 'photo')
    );


DROP POLICY IF EXISTS "Captain can post updates and polls"
    ON public.lobby_feed_item;

-- Captain-only kinds: scheduled-session updates, coach bookings, polls.
CREATE POLICY "Captain can post updates and polls"
    ON public.lobby_feed_item
    FOR INSERT
    TO authenticated
    WITH CHECK (
        author_id = (SELECT auth.uid())
        AND kind IN ('update', 'poll')
        AND EXISTS (
            SELECT 1 FROM public.lobby l
            WHERE l.id = lobby_feed_item.lobby_id
              AND l.captain_id = (SELECT auth.uid())
        )
    );

-- NB: there's no INSERT policy for kind = 'system'. Those rows should
-- only ever be produced by SECURITY DEFINER triggers / RPC (e.g. the
-- befriend-request flow raising "X xin vào lobby"). RLS denies direct
-- inserts from the API, which is the desired behavior.


DROP POLICY IF EXISTS "Author or captain can delete a feed item"
    ON public.lobby_feed_item;

CREATE POLICY "Author or captain can delete a feed item"
    ON public.lobby_feed_item
    FOR DELETE
    TO authenticated
    USING (
        author_id = (SELECT auth.uid())
        OR EXISTS (
            SELECT 1 FROM public.lobby l
            WHERE l.id = lobby_feed_item.lobby_id
              AND l.captain_id = (SELECT auth.uid())
        )
    );

-- Feed items are append-only by design: no UPDATE policy. Editing a
-- captain announcement after the fact would be confusing — captains
-- should delete + re-post instead.


-- ─── lobby_feed_poll_vote ──────────────────────────────────────

DROP POLICY IF EXISTS "Members can read poll votes in their lobby"
    ON public.lobby_feed_poll_vote;

CREATE POLICY "Members can read poll votes in their lobby"
    ON public.lobby_feed_poll_vote
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.lobby_feed_item fi
            WHERE fi.id = lobby_feed_poll_vote.feed_item_id
              AND fi.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );


DROP POLICY IF EXISTS "Members can cast a vote in their lobby's polls"
    ON public.lobby_feed_poll_vote;

CREATE POLICY "Members can cast a vote in their lobby's polls"
    ON public.lobby_feed_poll_vote
    FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.lobby_feed_item fi
            WHERE fi.id = lobby_feed_poll_vote.feed_item_id
              AND fi.kind = 'poll'
              AND fi.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );


DROP POLICY IF EXISTS "Users can change their own vote"
    ON public.lobby_feed_poll_vote;

CREATE POLICY "Users can change their own vote"
    ON public.lobby_feed_poll_vote
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));


DROP POLICY IF EXISTS "Users can retract their own vote"
    ON public.lobby_feed_poll_vote;

CREATE POLICY "Users can retract their own vote"
    ON public.lobby_feed_poll_vote
    FOR DELETE
    TO authenticated
    USING (user_id = (SELECT auth.uid()));


-- ─── lobby_match ───────────────────────────────────────────────

DROP POLICY IF EXISTS "Members of either lobby can read the match"
    ON public.lobby_match;

-- Both the home lobby and (when set) the opponent lobby see the row,
-- so both teams can review a recorded challenge result. Practice
-- matches without an opponent are only visible to the home lobby.
CREATE POLICY "Members of either lobby can read the match"
    ON public.lobby_match
    FOR SELECT
    TO authenticated
    USING (
        lobby_id IN (SELECT public.get_my_lobby_ids())
        OR (
            opponent_lobby_id IS NOT NULL
            AND opponent_lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );


DROP POLICY IF EXISTS "Captain can record matches for their lobby"
    ON public.lobby_match;

CREATE POLICY "Captain can record matches for their lobby"
    ON public.lobby_match
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.lobby l
            WHERE l.id = lobby_match.lobby_id
              AND l.captain_id = (SELECT auth.uid())
        )
    );


DROP POLICY IF EXISTS "Captain can edit their lobby's matches"
    ON public.lobby_match;

CREATE POLICY "Captain can edit their lobby's matches"
    ON public.lobby_match
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.lobby l
            WHERE l.id = lobby_match.lobby_id
              AND l.captain_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.lobby l
            WHERE l.id = lobby_match.lobby_id
              AND l.captain_id = (SELECT auth.uid())
        )
    );


DROP POLICY IF EXISTS "Captain can delete their lobby's matches"
    ON public.lobby_match;

CREATE POLICY "Captain can delete their lobby's matches"
    ON public.lobby_match
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.lobby l
            WHERE l.id = lobby_match.lobby_id
              AND l.captain_id = (SELECT auth.uid())
        )
    );
