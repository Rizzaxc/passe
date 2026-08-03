-- ============================================================================
-- Retire `lobby_feed_item.photo` in favour of wall posts.
--
-- The `photo` kind existed in the CHECK but was never wired — there was no
-- storage bucket, so posting one was impossible (see lib/manage_tab/CLAUDE.md,
-- "Photo action was removed rather than wired"). Rather than build a second
-- photo system beside the wall, `lobby_feed_data` now **unions in the wall
-- posts attached to that lobby's activities**, emitted under the existing
-- `photo` kind so the client's (kind, payload) contract is unchanged.
--
-- One source of truth: there are no duplicate rows to keep in sync, and a post
-- deleted or swept by the TTL disappears from the lobby feed at the same time
-- it disappears everywhere else.
--
-- The payload is the same shape `wall_feed_data` returns, so the client parses
-- it with the same `WallPost.fromJson`.
--
-- Visibility: this function is SECURITY INVOKER, so the caller's RLS applies.
-- A lobby member is by definition a lobby mate of the author, so the wall_post
-- SELECT policy already lets them through — no new exposure, but it does mean
-- a post surfaced here is visible to *every* member of that lobby.
--
-- NOTE: the live function returns a `my_vote` column added by
-- schema/lobby_feed_poll_my_vote.sql that `schema/passe.sql` (a stale dump)
-- does not show. It is preserved here — dropping it would silently break poll
-- voting. Postgres refuses to CREATE OR REPLACE with a different OUT-parameter
-- row type, which is what caught this.
--
-- Depends on: schema/wall_post.sql. Idempotent / re-runnable.
-- ============================================================================

create or replace function public.lobby_feed_data(
    p_lobby_id  uuid,
    p_page_size integer default 50,
    p_before    timestamp with time zone default null
) returns table(
    id uuid,
    author_id uuid,
    author_username character varying,
    kind public.lobby_feed_item_kind,
    payload jsonb,
    created_at timestamp with time zone,
    poll_tallies jsonb,
    my_vote integer
)
    language plpgsql set search_path to ''
as $$
BEGIN
    RETURN QUERY
        SELECT * FROM (
            -- ── Native feed items (unchanged) ────────────────────────────
            SELECT fi.id,
                   fi.author_id,
                   u.username                             AS author_username,
                   fi.kind,
                   fi.payload,
                   fi.created_at,
                   CASE WHEN fi.kind = 'poll' THEN
                       (SELECT jsonb_object_agg(option_index::text, c)
                        FROM (
                            SELECT option_index, COUNT(*) AS c
                            FROM public.lobby_feed_poll_vote v
                            WHERE v.feed_item_id = fi.id
                            GROUP BY option_index
                        ) t)
                   END                                    AS poll_tallies,
                   CASE WHEN fi.kind = 'poll' THEN
                       (SELECT v.option_index
                        FROM public.lobby_feed_poll_vote v
                        WHERE v.feed_item_id = fi.id AND v.user_id = auth.uid())
                   END                                    AS my_vote
            FROM public.lobby_feed_item fi
                     LEFT JOIN public."user" u ON u.id = fi.author_id
            WHERE fi.lobby_id = p_lobby_id
              -- Legacy `photo` rows (there should be none — the kind was never
              -- writable) are dropped rather than rendered: the client's photo
              -- branch now expects a wall-post payload.
              AND fi.kind <> 'photo'
              AND (p_before IS NULL OR fi.created_at < p_before)

            UNION ALL

            -- ── Wall posts attached to this lobby ────────────────────────
            SELECT p.id,
                   p.author_id,
                   au.username                            AS author_username,
                   'photo'::public.lobby_feed_item_kind   AS kind,
                   jsonb_build_object(
                       'id',                p.id,
                       'author_id',         p.author_id,
                       'author_username',   au.username,
                       'author_tag_number', au.tag_number,
                       'author_details',    au.details,
                       'sport_id',          p.sport_id,
                       'lobby_id',          p.lobby_id,
                       'source_label',      p.source_label,
                       'source_start_time', p.source_start_time,
                       'source_venue_name', p.source_venue_name,
                       'caption',           p.caption,
                       'image_paths',       to_jsonb(p.image_paths),
                       'created_at',        p.created_at,
                       'expires_at',        p.expires_at,
                       'tags', coalesce((
                           SELECT jsonb_agg(jsonb_build_object(
                                      'user_id', tu.id,
                                      'username', tu.username,
                                      'tag_number', tu.tag_number))
                           FROM public.wall_post_tag t
                           JOIN public."user" tu ON tu.id = t.user_id
                           WHERE t.post_id = p.id
                       ), '[]'::jsonb),
                       'reactions', coalesce((
                           SELECT jsonb_object_agg(r.emoji, r.n)
                           FROM (SELECT emoji, count(*) AS n
                                   FROM public.wall_post_reaction
                                  WHERE post_id = p.id
                                  GROUP BY emoji) r
                       ), '{}'::jsonb),
                       'my_reaction', (
                           SELECT emoji FROM public.wall_post_reaction
                            WHERE post_id = p.id AND user_id = auth.uid())
                   )                                      AS payload,
                   p.created_at,
                   NULL::jsonb                            AS poll_tallies,
                   NULL::integer                          AS my_vote
            FROM public.wall_post p
                     JOIN public."user" au ON au.id = p.author_id
            WHERE p.lobby_id = p_lobby_id
              AND p.hidden_at IS NULL
              AND p.expires_at > now()
              AND (p_before IS NULL OR p.created_at < p_before)
        ) merged
        ORDER BY merged.created_at DESC
        LIMIT p_page_size;
END;
$$;

grant execute on function
    public.lobby_feed_data(uuid, integer, timestamp with time zone)
    to authenticated;
