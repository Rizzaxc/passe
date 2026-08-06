-- Teammate feed: tiered schedule-overlap relaxation (cold-start liquidity)
-- ==========================================================================
-- home_teammate_lobby_data had no fallback at all: `p_timeslots = '{}' OR
-- ts_score >= 4` was a hard gate, unlike the challenger feed's MMR window
-- (which tiers 200 -> 400 -> unbounded when the candidate pool is thin, see
-- home_feed_search.sql's home_challenger_lobby_data). With few lobbies per
-- city, that fixed >=4 threshold (a day match + a chunk match, or two day
-- matches) can hard-fail to an empty feed even when lobbies exist that would
-- happily play, just not at the caller's exact preferred time.
--
-- Fix: mirror the challenger pattern -- count candidates at the strict
-- threshold, and if that's short of a page, relax in two steps:
--   1. ts_score >= 4  (day + chunk overlap, or 2 days)       -- as before
--   2. ts_score >= 2  (a day overlaps, chunk needn't align)  -- same city
--   3. ts_score >= 0  (schedule dropped entirely)            -- same city
--
-- city_cluster is deliberately NOT widened here -- HCMC and Hanoi are ~1700km
-- apart, so unlike an Elo/MMR window, "widening" across cities would surface
-- teammates nobody can actually meet up with. City stays a hard, exact
-- filter; only the schedule-fit requirement relaxes.
--
-- The `playtime` match-factor chip keeps its own fixed truthfulness
-- threshold (ts_score >= 4) regardless of which tier actually admitted the
-- row, so a relaxed-tier result never claims a schedule match it doesn't
-- have (see fitscore_factors.sql's "truthful factor chips" fix).
--
-- Signature carries the p_search param added in home_feed_search.sql (the
-- current live signature has 7 args incl. p_search) -- this file's first
-- cut wrongly used the pre-search 6-arg signature, which CREATE OR REPLACE
-- silently accepted as a NEW overload instead of replacing the live one.
-- The DROP below removes that stray overload before recreating the real one.

DROP FUNCTION IF EXISTS public.home_teammate_lobby_data(bigint, jsonb, integer, character varying[], integer, integer);

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
        JOIN public.location loc ON l.home_ground = loc.id
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                       p_timeslots, public.fn_playtime_to_dict(l.playtime)
                   ) AS ts_score
        ) ts
        WHERE l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND loc.city_cluster = p_city
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
            JOIN public.location loc ON l.home_ground = loc.id
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                           p_timeslots, public.fn_playtime_to_dict(l.playtime)
                       ) AS ts_score
            ) ts
            WHERE l.sport_id = p_sport_id
              AND l.visibility != 'private'
              AND loc.city_cluster = p_city
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
