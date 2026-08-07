-- ============================================================================
-- fix_lobby_feed_data_media_column.sql — hotfix for a regression introduced
-- by schema/activity_scoped_feed_items.sql.
--
-- That migration's DROP + CREATE was based on schema/lobby_payment_requests.sql
-- (needed to add the `activity_id` output column), but two later migrations
-- had already moved lobby_feed_data past that point:
--   - schema/lobby_feed_author_avatar.sql added `author_generated_avatar`
--     (+ `generated_avatar` inside each payment_payees entry).
--   - schema/wall_post_video.sql renamed wall_post.image_paths -> media
--     (jsonb) and updated the wall_post union branch to select `media`.
-- Recreating from the stale base silently dropped author_generated_avatar
-- and reverted the wall_post branch to `p.image_paths`, a column that no
-- longer exists — crashing every lobby_feed_data call with
-- `column p.image_paths does not exist` (42703).
--
-- This restores the full latest body (schema/wall_post_video.sql's version)
-- with `activity_id` appended at the end, alongside the existing
-- `author_generated_avatar` column added there. No signature change from
-- what schema/activity_scoped_feed_items.sql already established, so
-- CREATE OR REPLACE is enough this time — no DROP needed.
--
-- Apply with execute_sql / apply_migration.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.lobby_feed_data(
    p_lobby_id  uuid,
    p_page_size integer DEFAULT 50,
    p_before    timestamp with time zone DEFAULT NULL
) RETURNS TABLE(
    id uuid,
    author_id uuid,
    author_username character varying,
    kind public.lobby_feed_item_kind,
    payload jsonb,
    created_at timestamp with time zone,
    poll_tallies jsonb,
    my_vote integer,
    payment_payees jsonb,
    author_generated_avatar text,
    activity_id uuid
)
    LANGUAGE plpgsql SET search_path TO ''
AS $$
BEGIN
    RETURN QUERY
        SELECT * FROM (
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
                   END                                    AS my_vote,
                   CASE WHEN fi.kind = 'payment_request' THEN
                       (SELECT jsonb_agg(jsonb_build_object(
                                  'user_id',          pr.user_id,
                                  'username',         pu.username,
                                  'generated_avatar', pu.details ->> 'generatedAvatar',
                                  'amount_owed',       pr.amount_owed,
                                  'paid',              (r.user_id IS NOT NULL)))
                          FROM public.lobby_payment_request_payee pr
                          JOIN public."user" pu ON pu.id = pr.user_id
                          LEFT JOIN public.lobby_feed_item_reaction r
                                 ON r.feed_item_id = fi.id AND r.user_id = pr.user_id
                         WHERE pr.feed_item_id = fi.id)
                   END                                    AS payment_payees,
                   (u.details ->> 'generatedAvatar')      AS author_generated_avatar,
                   fi.activity_id                          AS activity_id
            FROM public.lobby_feed_item fi
                     LEFT JOIN public."user" u ON u.id = fi.author_id
            WHERE fi.lobby_id = p_lobby_id
              AND fi.kind <> 'photo'
              AND (p_before IS NULL OR fi.created_at < p_before)

            UNION ALL

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
                       'media',             p.media,
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
                   NULL::integer                          AS my_vote,
                   NULL::jsonb                             AS payment_payees,
                   (au.details ->> 'generatedAvatar')     AS author_generated_avatar,
                   NULL::uuid                              AS activity_id
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

ALTER FUNCTION public.lobby_feed_data(uuid, integer, timestamp with time zone) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.lobby_feed_data(uuid, integer, timestamp with time zone) TO authenticated;
