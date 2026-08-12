-- Bound wall_feed_data pagination at the trust boundary.
--
-- The app currently requests five rows at a time, but authenticated callers
-- can invoke RPCs directly. Keep a generous upper page-size bound while
-- preventing unbounded LIMIT/OFFSET work. Out-of-range page numbers return an
-- empty set (rather than silently clamping and repeating page 100 forever).

CREATE OR REPLACE FUNCTION public.wall_feed_data(
    p_sport_id bigint DEFAULT NULL,
    p_page_size integer DEFAULT 20,
    p_page_number integer DEFAULT 0
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
    v_page_number integer := COALESCE(p_page_number, 0);
BEGIN
    IF v_page_number < 0 OR v_page_number > 100 THEN
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
    OFFSET v_page_number * v_page_size;
END;
$$;

REVOKE ALL ON FUNCTION public.wall_feed_data(bigint, integer, integer)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.wall_feed_data(bigint, integer, integer)
    TO authenticated;

COMMENT ON FUNCTION public.wall_feed_data(bigint, integer, integer) IS
    'Returns visible wall posts with page size clamped to 1..50 and page number restricted to 0..100.';
