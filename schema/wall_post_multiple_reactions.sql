-- Allow each user to add more than one distinct emoji to a wall post.
--
-- The former key `(post_id, user_id)` made a second emoji overwrite the
-- first. Existing rows remain valid when the key expands to include `emoji`.

ALTER TABLE public.wall_post_reaction
    DROP CONSTRAINT IF EXISTS wall_post_reaction_pkey;

ALTER TABLE public.wall_post_reaction
    ADD PRIMARY KEY (post_id, user_id, emoji);

-- Toggle a single emoji without affecting the caller's other reactions.
CREATE OR REPLACE FUNCTION public.react_to_wall_post(
    p_post_id uuid,
    p_emoji   text
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    IF auth.uid() IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_emoji IS NULL OR char_length(p_emoji) NOT BETWEEN 1 AND 8 THEN
        RAISE EXCEPTION 'reaction emoji must be 1-8 characters';
    END IF;
    IF NOT public.fn_can_see_wall_post(p_post_id) THEN
        RAISE EXCEPTION 'post not visible';
    END IF;

    DELETE FROM public.wall_post_reaction
    WHERE post_id = p_post_id
      AND user_id = auth.uid()
      AND emoji = p_emoji;

    IF NOT FOUND THEN
        INSERT INTO public.wall_post_reaction (post_id, user_id, emoji)
        VALUES (p_post_id, auth.uid(), p_emoji);
    END IF;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.react_to_wall_post(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.react_to_wall_post(uuid, text) TO authenticated;

-- The wall-feed read functions and the lobby-feed payload now expose the
-- caller's selected emoji set as `my_reactions`. The deployed definitions in
-- `wall_post_video.sql` are superseded below.
DROP FUNCTION IF EXISTS public.wall_feed_data(bigint, integer, integer);
CREATE FUNCTION public.wall_feed_data(
    p_sport_id bigint DEFAULT NULL,
    p_page_size integer DEFAULT 20,
    p_page_number integer DEFAULT 0
) RETURNS TABLE(
    id uuid, author_id uuid, author_username text, author_tag_number text,
    author_details jsonb, sport_id bigint, lobby_id uuid, source_label text,
    source_start_time timestamptz, source_venue_name text, caption text,
    media jsonb, created_at timestamptz, expires_at timestamptz, tags jsonb,
    reactions jsonb, my_reactions jsonb
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
    WITH me AS (SELECT auth.uid() AS uid),
    friends AS (SELECT uid FROM public.get_my_friend_ids() AS uid),
    lobbymates AS (SELECT uid FROM public.get_my_lobbymate_ids() AS uid),
    visible AS (
        SELECT p.* FROM public.wall_post p, me
        WHERE p.hidden_at IS NULL AND p.expires_at > now()
          AND NOT public.fn_is_blocked(me.uid, p.author_id)
          AND (p_sport_id IS NULL OR p.sport_id = p_sport_id)
          AND (p.author_id = me.uid OR p.author_id IN (SELECT uid FROM friends)
               OR p.author_id IN (SELECT uid FROM lobbymates)
               OR EXISTS (SELECT 1 FROM public.wall_post_tag t
                          WHERE t.post_id = p.id AND (t.user_id = me.uid
                            OR t.user_id IN (SELECT uid FROM friends))))
    )
    SELECT v.id, v.author_id, u.username::text, u.tag_number::text, u.details,
           v.sport_id, v.lobby_id, v.source_label, v.source_start_time,
           v.source_venue_name, v.caption, v.media, v.created_at, v.expires_at,
           COALESCE((SELECT jsonb_agg(jsonb_build_object('user_id', tu.id,
                'username', tu.username, 'tag_number', tu.tag_number))
             FROM public.wall_post_tag t JOIN public."user" tu ON tu.id = t.user_id
             WHERE t.post_id = v.id), '[]'::jsonb),
           COALESCE((SELECT jsonb_object_agg(r.emoji, r.n)
             FROM (SELECT emoji, count(*) AS n FROM public.wall_post_reaction
                   WHERE post_id = v.id GROUP BY emoji) r), '{}'::jsonb),
           COALESCE((SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
             FROM public.wall_post_reaction r
             WHERE r.post_id = v.id AND r.user_id = (SELECT uid FROM me)), '[]'::jsonb)
    FROM visible v JOIN public."user" u ON u.id = v.author_id
    ORDER BY v.created_at DESC
    LIMIT greatest(p_page_size, 1)
    OFFSET greatest(p_page_number, 0) * greatest(p_page_size, 1);
$$;
REVOKE EXECUTE ON FUNCTION public.wall_feed_data(bigint, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.wall_feed_data(bigint, integer, integer) TO authenticated;

DROP FUNCTION IF EXISTS public.user_wall_data(uuid, text, integer, integer);
CREATE FUNCTION public.user_wall_data(
    p_user_id uuid, p_mode text DEFAULT 'authored', p_page_size integer DEFAULT 20,
    p_page_number integer DEFAULT 0
) RETURNS TABLE(
    id uuid, author_id uuid, author_username text, author_tag_number text,
    author_details jsonb, sport_id bigint, lobby_id uuid, source_label text,
    source_start_time timestamptz, source_venue_name text, caption text,
    media jsonb, created_at timestamptz, expires_at timestamptz, tags jsonb,
    reactions jsonb, my_reactions jsonb
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $$
    SELECT p.id, p.author_id, u.username::text, u.tag_number::text, u.details,
           p.sport_id, p.lobby_id, p.source_label, p.source_start_time,
           p.source_venue_name, p.caption, p.media, p.created_at, p.expires_at,
           COALESCE((SELECT jsonb_agg(jsonb_build_object('user_id', tu.id,
                'username', tu.username, 'tag_number', tu.tag_number))
             FROM public.wall_post_tag t JOIN public."user" tu ON tu.id = t.user_id
             WHERE t.post_id = p.id), '[]'::jsonb),
           COALESCE((SELECT jsonb_object_agg(r.emoji, r.n)
             FROM (SELECT emoji, count(*) AS n FROM public.wall_post_reaction
                   WHERE post_id = p.id GROUP BY emoji) r), '{}'::jsonb),
           COALESCE((SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
             FROM public.wall_post_reaction r
             WHERE r.post_id = p.id AND r.user_id = auth.uid()), '[]'::jsonb)
    FROM public.wall_post p JOIN public."user" u ON u.id = p.author_id
    WHERE public.fn_can_see_wall_post(p.id)
      AND CASE WHEN p_mode = 'tagged' THEN EXISTS (
            SELECT 1 FROM public.wall_post_tag t
            WHERE t.post_id = p.id AND t.user_id = p_user_id)
          ELSE p.author_id = p_user_id END
    ORDER BY p.created_at DESC
    LIMIT greatest(p_page_size, 1)
    OFFSET greatest(p_page_number, 0) * greatest(p_page_size, 1);
$$;
REVOKE EXECUTE ON FUNCTION public.user_wall_data(uuid, text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.user_wall_data(uuid, text, integer, integer) TO authenticated;

-- `lobby_feed_data` keeps its signature: only a JSON payload field changes.
-- Redefine its latest implementation with the singular subquery replaced.
CREATE OR REPLACE FUNCTION public.lobby_feed_data(
    p_lobby_id uuid, p_page_size integer DEFAULT 50,
    p_before timestamptz DEFAULT NULL
) RETURNS TABLE(
    id uuid, author_id uuid, author_username varchar, kind lobby_feed_item_kind,
    payload jsonb, created_at timestamptz, poll_tallies jsonb, my_vote integer,
    payment_payees jsonb, author_generated_avatar text, activity_id uuid
) LANGUAGE plpgsql SET search_path TO ''
AS $function$
BEGIN
    RETURN QUERY
    SELECT * FROM (
        SELECT fi.id, fi.author_id, u.username, fi.kind, fi.payload, fi.created_at,
               CASE WHEN fi.kind = 'poll' THEN (SELECT jsonb_object_agg(option_index::text, c)
                    FROM (SELECT option_index, count(*) AS c FROM public.lobby_feed_poll_vote v
                          WHERE v.feed_item_id = fi.id GROUP BY option_index) t) END,
               CASE WHEN fi.kind = 'poll' THEN (SELECT v.option_index FROM public.lobby_feed_poll_vote v
                    WHERE v.feed_item_id = fi.id AND v.user_id = auth.uid()) END,
               CASE WHEN fi.kind = 'payment_request' THEN (SELECT jsonb_agg(jsonb_build_object(
                    'user_id', pr.user_id, 'username', pu.username,
                    'generated_avatar', pu.details ->> 'generatedAvatar',
                    'amount_owed', pr.amount_owed, 'paid', r.user_id IS NOT NULL))
                    FROM public.lobby_payment_request_payee pr JOIN public."user" pu ON pu.id = pr.user_id
                    LEFT JOIN public.lobby_feed_item_reaction r ON r.feed_item_id = fi.id AND r.user_id = pr.user_id
                    WHERE pr.feed_item_id = fi.id) END,
               u.details ->> 'generatedAvatar', fi.activity_id
        FROM public.lobby_feed_item fi LEFT JOIN public."user" u ON u.id = fi.author_id
        WHERE fi.lobby_id = p_lobby_id AND fi.kind <> 'photo'
          AND (p_before IS NULL OR fi.created_at < p_before)
        UNION ALL
        SELECT p.id, p.author_id, au.username, 'photo'::public.lobby_feed_item_kind,
               jsonb_build_object(
                    'id', p.id, 'author_id', p.author_id, 'author_username', au.username,
                    'author_tag_number', au.tag_number, 'author_details', au.details,
                    'sport_id', p.sport_id, 'lobby_id', p.lobby_id, 'source_label', p.source_label,
                    'source_start_time', p.source_start_time, 'source_venue_name', p.source_venue_name,
                    'caption', p.caption, 'media', p.media, 'created_at', p.created_at,
                    'expires_at', p.expires_at, 'tags', COALESCE((SELECT jsonb_agg(jsonb_build_object(
                        'user_id', tu.id, 'username', tu.username, 'tag_number', tu.tag_number))
                        FROM public.wall_post_tag t JOIN public."user" tu ON tu.id = t.user_id
                        WHERE t.post_id = p.id), '[]'::jsonb),
                    'reactions', COALESCE((SELECT jsonb_object_agg(r.emoji, r.n)
                        FROM (SELECT emoji, count(*) AS n FROM public.wall_post_reaction
                              WHERE post_id = p.id GROUP BY emoji) r), '{}'::jsonb),
                    'my_reactions', COALESCE((SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
                        FROM public.wall_post_reaction r
                        WHERE r.post_id = p.id AND r.user_id = auth.uid()), '[]'::jsonb)),
               p.created_at, NULL::jsonb, NULL::integer, NULL::jsonb,
               au.details ->> 'generatedAvatar', NULL::uuid
        FROM public.wall_post p JOIN public."user" au ON au.id = p.author_id
        WHERE p.lobby_id = p_lobby_id AND p.hidden_at IS NULL AND p.expires_at > now()
          AND (p_before IS NULL OR p.created_at < p_before)
    ) merged
    ORDER BY merged.created_at DESC
    LIMIT p_page_size;
END;
$function$;
