-- Teammate feed: request-state filtering + already_requested flag
-- ===============================================================
-- Two fixes to the teammate join flow:
--
-- 1. Hide lobbies the user has been DECLINED from (the lobby rejected the join
--    request). The before-insert trigger also blocks a fresh request while a
--    declined record exists, so showing them is pointless and confusing.
--
-- 2. Return `already_requested` (a PENDING request from the caller exists) so
--    the card can show the persistent "Đã gửi" + Undo state instead of an
--    active Join button — which, after an app restart (the optimistic set is
--    per-session), let the user re-request and hit the trigger's
--    "identical request already exists in pending state" error.
--
-- `accepted` requests need no handling: the accept-trigger adds the user as a
-- member and the RPC already excludes `get_my_lobby_ids()`. `cancelled` (the
-- Undo state) is intentionally NOT filtered, so a cancelled lobby reappears as
-- joinable.
--
-- DROP required: the RETURNS TABLE shape gains a column.

DROP FUNCTION IF EXISTS public.home_teammate_lobby_data(bigint, jsonb, integer, character varying[], integer, integer);

CREATE OR REPLACE FUNCTION public.home_teammate_lobby_data(
    p_sport_id bigint,
    p_timeslots jsonb,
    p_city integer,
    p_districts character varying[],
    p_page_size integer DEFAULT 10,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid, name text, homeground_name text, playtime jsonb, details jsonb,
    visibility public.lobby_visibility, member_count integer,
    timeslot_compat_score integer, profile_compat_score numeric,
    match_factors text[], already_requested boolean
)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            l.id,
            l.name::text,
            loc.name::text AS homeground_name,
            l.playtime,
            l.details,
            l.visibility,
            l.member_count,
            ts.ts_score AS timeslot_compat_score,
            (ps.compat->>'score')::numeric AS profile_compat_score,
            (
                ARRAY(SELECT jsonb_array_elements_text(ps.compat->'factors'))
                || CASE WHEN ts.ts_score >= 4 THEN ARRAY['playtime'] ELSE ARRAY[]::text[] END
            ) AS match_factors,
            EXISTS (
                SELECT 1 FROM public.lobby_befriend_record r
                WHERE r.initiator_user_id = auth.uid()
                  AND r.target_lobby_id = l.id
                  AND r.interaction_type = 'request'
                  AND r.status = 'pending'
            ) AS already_requested
        FROM
            public.lobby l
                JOIN
            public.location loc ON l.home_ground = loc.id
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(p_timeslots, public.fn_playtime_to_dict(l.playtime)) AS ts_score
                ) ts
                CROSS JOIN LATERAL (
                SELECT public.calculate_profile_compat(auth.uid(), l.id, l.sport_id) AS compat
                ) ps
        WHERE
            l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND loc.city_cluster = p_city
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND (p_timeslots = '{}'::jsonb OR ts.ts_score >= 4)
          AND NOT EXISTS (
                SELECT 1 FROM public.lobby_befriend_record r
                WHERE r.initiator_user_id = auth.uid()
                  AND r.target_lobby_id = l.id
                  AND r.interaction_type = 'request'
                  AND r.status = 'declined'
            )
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
