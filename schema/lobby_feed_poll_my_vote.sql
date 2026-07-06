-- Add `my_vote` to lobby_feed_data so the client can render "you voted for X" and
-- pre-select the caller's own choice, instead of the poll card faking a vote with local
-- setState() that never touches lobby_feed_poll_vote (see lib/manage_tab/lobby_section/activity/feed.dart).
--
-- Return-type change requires DROP + CREATE (CREATE OR REPLACE can't add output columns).

DROP FUNCTION IF EXISTS public.lobby_feed_data(uuid, integer, timestamp with time zone);

CREATE FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone)
RETURNS TABLE(id uuid, author_id uuid, author_username character varying, kind public.lobby_feed_item_kind, payload jsonb, created_at timestamp with time zone, poll_tallies jsonb, my_vote integer)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT fi.id,
               fi.author_id,
               u.username                             AS author_username,
               fi.kind,
               fi.payload,
               fi.created_at,
               -- Poll tallies: {option_index: count, …}. Null for non-polls.
               CASE WHEN fi.kind = 'poll' THEN
                   (SELECT jsonb_object_agg(option_index::text, c)
                    FROM (
                        SELECT option_index, COUNT(*) AS c
                        FROM public.lobby_feed_poll_vote v
                        WHERE v.feed_item_id = fi.id
                        GROUP BY option_index
                    ) t)
               END                                    AS poll_tallies,
               -- The caller's own vote (option_index), null if they haven't voted / not a poll.
               CASE WHEN fi.kind = 'poll' THEN
                   (SELECT v.option_index
                    FROM public.lobby_feed_poll_vote v
                    WHERE v.feed_item_id = fi.id AND v.user_id = auth.uid())
               END                                    AS my_vote
        FROM public.lobby_feed_item fi
                 LEFT JOIN public."user" u ON u.id = fi.author_id
        WHERE fi.lobby_id = p_lobby_id
          AND (p_before IS NULL OR fi.created_at < p_before)
        ORDER BY fi.created_at DESC
        LIMIT p_page_size;
END;
$$;

ALTER FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) OWNER TO postgres;

GRANT ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) TO anon;
GRANT ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer, p_before timestamp with time zone) TO service_role;
