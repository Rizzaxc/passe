-- Make wall_feed_data's pagination 1-based, matching every other feed RPC.
--
-- Six paginated feed RPCs take `p_page_number` as 1-based
-- (`OFFSET (p_page_number - 1) * p_page_size`): home_teammate_lobby_data,
-- home_challenger_lobby_data, home_professional_data, home_freeplay_data,
-- friendly_offer_feed_data and lobby_match_history_data. Every client call site
-- passes a literal `1` for the first page.
--
-- wall_feed_data was the odd one out, 0-based with a 0 default. Nothing was
-- broken by it -- FeedController was internally consistent, asking for page 0
-- first and starting `_nextPage` at 1 -- but the convention is a trap: passing
-- 1 for "the first page", the way every other feed in this codebase does,
-- silently skips the first page and returns an empty list. That reads exactly
-- like "no data", and it cost real time during the App Store seed work.
--
-- This migration flips the SQL side; lib/feed_tab/feed_controller.dart moves
-- with it in the same commit. THE TWO MUST SHIP TOGETHER: the function is
-- SECURITY DEFINER and called from exactly one controller (verified -- no other
-- SQL function references it either). Deploying this without the client would
-- make the Feed skip its first five posts.
--
-- user_wall_data is also 0-based and is deliberately left alone: it is dead
-- code. lib/feed_tab/CLAUDE.md records that the /user/:id wall was dropped and
-- that "that RPC and provider no longer exist"; the function survived in the
-- database but has no caller in lib/ and no SQL caller. Changing dead code's
-- signature buys nothing; removing it is a separate decision.
--
-- The body below is the live definition verbatim apart from the paging lines.

CREATE OR REPLACE FUNCTION public.wall_feed_data(
    p_sport_id bigint DEFAULT NULL,
    p_page_size integer DEFAULT 20,
    p_page_number integer DEFAULT 1
)
RETURNS TABLE(
    id uuid,
    author_id uuid,
    author_username text,
    author_tag_number text,
    author_details jsonb,
    sport_id bigint,
    lobby_id uuid,
    source_label text,
    source_start_time timestamptz,
    source_venue_name text,
    caption text,
    media jsonb,
    created_at timestamptz,
    expires_at timestamptz,
    tags jsonb,
    reactions jsonb,
    my_reactions jsonb
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_page_size integer := LEAST(GREATEST(COALESCE(p_page_size, 20), 1), 50);
    v_page_number integer := COALESCE(p_page_number, 1);
BEGIN
    IF v_page_number < 1 OR v_page_number > 100 THEN
        RETURN;
    END IF;

    RETURN QUERY
    WITH me AS (SELECT auth.uid() AS uid),
    friends AS (SELECT uid FROM public.get_my_friend_ids() AS uid),
    lobbymates AS (SELECT uid FROM public.get_my_lobbymate_ids() AS uid),
    visible AS (
        SELECT p.*
        FROM public.wall_post p, me
        WHERE p.hidden_at IS NULL
          AND p.expires_at > now()
          AND NOT public.fn_is_blocked(me.uid, p.author_id)
          AND (p_sport_id IS NULL OR p.sport_id = p_sport_id)
          AND (
              p.author_id = me.uid
              OR p.author_id IN (SELECT uid FROM friends)
              OR p.author_id IN (SELECT uid FROM lobbymates)
              OR EXISTS (
                  SELECT 1
                  FROM public.wall_post_tag t
                  WHERE t.post_id = p.id
                    AND (
                        t.user_id = me.uid
                        OR t.user_id IN (SELECT uid FROM friends)
                    )
              )
          )
    )
    SELECT
        v.id,
        v.author_id,
        u.username::text,
        u.tag_number::text,
        u.details,
        v.sport_id,
        v.lobby_id,
        v.source_label,
        v.source_start_time,
        v.source_venue_name,
        v.caption,
        v.media,
        v.created_at,
        v.expires_at,
        COALESCE((
            SELECT jsonb_agg(jsonb_build_object(
                'user_id', tu.id,
                'username', tu.username,
                'tag_number', tu.tag_number
            ))
            FROM public.wall_post_tag t
            JOIN public."user" tu ON tu.id = t.user_id
            WHERE t.post_id = v.id
        ), '[]'::jsonb),
        COALESCE((
            SELECT jsonb_object_agg(r.emoji, r.n)
            FROM (
                SELECT emoji, count(*) AS n
                FROM public.wall_post_reaction
                WHERE post_id = v.id
                GROUP BY emoji
            ) r
        ), '{}'::jsonb),
        COALESCE((
            SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
            FROM public.wall_post_reaction r
            WHERE r.post_id = v.id
              AND r.user_id = (SELECT uid FROM me)
        ), '[]'::jsonb)
    FROM visible v
    JOIN public."user" u ON u.id = v.author_id
    ORDER BY v.created_at DESC
    LIMIT v_page_size
    OFFSET (v_page_number - 1) * v_page_size;
END;
$$;

REVOKE ALL ON FUNCTION public.wall_feed_data(bigint, integer, integer)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.wall_feed_data(bigint, integer, integer)
    TO authenticated;

COMMENT ON FUNCTION public.wall_feed_data(bigint, integer, integer) IS
    'Returns visible wall posts. Page size clamps to 1..50; p_page_number is '
    '1-BASED and restricted to 1..100, matching home_teammate_lobby_data and '
    'every other paginated feed RPC.';
