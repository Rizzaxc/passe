-- Teammate feed: surface lobbies with no home_ground set
-- ==========================================================================
-- home_teammate_lobby_data used a plain INNER JOIN from lobby to location on
-- home_ground, plus a hard `loc.city_cluster = p_city` predicate. Since
-- lobby.home_ground is a nullable uuid (a lobby can be created with no
-- preferred location -- the create-lobby form's HomeGroundField has no
-- validator forcing one, unlike the name field right above it), every lobby
-- with home_ground IS NULL was silently dropped from the teammate feed for
-- every caller, regardless of sport/city/filter combination. Reported as:
-- "I have a public lobby with no preferred setting, and an empty filter --
-- nothing ever shows up."
--
-- Fix mirrors home_professional_data's existing handling of "no location
-- preference": a NULL-permissive soft filter, not a hard exclusion, so a
-- lobby with no stated home ground always shows up regardless of the
-- searcher's city filter. The client already tolerates a null location
-- gracefully (LobbyFeedItem.homegroundName is String?, lobby_feed_card.dart
-- guards its display), so no client change is needed.
--
-- The district filter is left untouched -- it's already conditional on
-- p_districts being non-empty, and correctly does NOT surface a
-- location-unknown lobby when the searcher has explicitly narrowed to a
-- specific district (can't verify a district match without a location).
--
-- Same three-occurrence structure as teammate_schedule_relaxation.sql (two
-- count(*) pre-checks for the tiered timeslot-relaxation fallback, plus the
-- final RETURN QUERY) -- all three get the same LEFT JOIN + NULL-permissive
-- city predicate. Signature is unchanged from that migration, so
-- CREATE OR REPLACE cleanly replaces the existing overload.

CREATE OR REPLACE FUNCTION public.home_teammate_lobby_data(
    p_sport_id bigint,
    p_timeslots jsonb,
    p_city integer,
    p_districts character varying[],
    p_search text DEFAULT NULL,
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
DECLARE
    v_ts_floor integer := 4;
    v_cnt      integer;
BEGIN
    IF p_timeslots <> '{}'::jsonb THEN
        SELECT count(*) INTO v_cnt
        FROM public.lobby l
        LEFT JOIN public.location loc ON l.home_ground = loc.id
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                       p_timeslots, public.fn_playtime_to_dict(l.playtime)
                   ) AS ts_score
        ) ts
        WHERE l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND (loc.city_cluster = p_city OR loc.id IS NULL)
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND (
                p_search IS NULL OR p_search = ''
                OR l.name ILIKE '%' || p_search || '%'
                OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                OR l.searchable_id ILIKE '%' || p_search || '%'
            )
          AND ts.ts_score >= v_ts_floor
          AND NOT EXISTS (
                SELECT 1 FROM public.lobby_befriend_record r
                WHERE r.initiator_user_id = auth.uid()
                  AND r.target_lobby_id = l.id
                  AND r.interaction_type = 'request'
                  AND r.status = 'declined'
            );

        IF v_cnt < p_page_size THEN
            v_ts_floor := 2;
            SELECT count(*) INTO v_cnt
            FROM public.lobby l
            LEFT JOIN public.location loc ON l.home_ground = loc.id
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                           p_timeslots, public.fn_playtime_to_dict(l.playtime)
                       ) AS ts_score
            ) ts
            WHERE l.sport_id = p_sport_id
              AND l.visibility != 'private'
              AND (loc.city_cluster = p_city OR loc.id IS NULL)
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
              AND (
                    p_search IS NULL OR p_search = ''
                    OR l.name ILIKE '%' || p_search || '%'
                    OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                    OR l.searchable_id ILIKE '%' || p_search || '%'
                )
              AND ts.ts_score >= v_ts_floor
              AND NOT EXISTS (
                    SELECT 1 FROM public.lobby_befriend_record r
                    WHERE r.initiator_user_id = auth.uid()
                      AND r.target_lobby_id = l.id
                      AND r.interaction_type = 'request'
                      AND r.status = 'declined'
                );

            IF v_cnt < p_page_size THEN
                v_ts_floor := 0;
            END IF;
        END IF;
    END IF;

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
                LEFT JOIN
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
          AND (loc.city_cluster = p_city OR loc.id IS NULL)
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND (
                p_search IS NULL OR p_search = ''
                OR l.name ILIKE '%' || p_search || '%'
                OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                OR l.searchable_id ILIKE '%' || p_search || '%'
            )
          AND (p_timeslots = '{}'::jsonb OR ts.ts_score >= v_ts_floor)
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

ALTER FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) OWNER TO postgres;

GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text, p_page_size integer, p_page_number integer) TO service_role;
