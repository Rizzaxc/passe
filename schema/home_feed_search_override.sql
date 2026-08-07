-- Home filter search box — override, not narrow
-- =================================================
-- `p_search` previously was AND'd into every other filter condition on the
-- teammate/challenger/professional RPCs (schema/home_feed_search.sql), so a
-- correctly-typed SearchID or exact lobby/professional name would still be
-- hidden if it fell outside the current city/district/schedule filters.
-- Intended behavior: a non-empty search is a MODE SWITCH — it drops
-- city/district/timeslot-compat/MMR-window narrowing entirely and returns
-- only text-matched rows — except three gates that must always hold:
--   1. sport gate (every tab) — never show a result outside the selected
--      context sport, even on an exact hit.
--   2. challenger gate (challenger tab only) — `open_to_challengers` +
--      unexpired `challenge_offer_time`.
--   3. structural/identity exclusions that aren't UI-exposed filter knobs:
--      visibility != 'private', "not my own lobby"
--      (`get_my_lobby_ids()`/`p_context_lobby_id`), teammate's
--      previously-`declined` exclusion.
-- Location's `search_locations` already does the right thing (district OR's
-- with search, city stays a hard AND) — untouched here.
--
-- Implementation: an early `IF p_search <> '' THEN RETURN QUERY <search
-- query>; RETURN; END IF;` branch ahead of the existing logic, which is
-- otherwise left byte-for-byte unchanged (teammate's ts-floor relaxation
-- loop and challenger's MMR-window widening loop must not run at all in
-- search mode, so a single merged WHERE with CASE would be wrong here).
--
-- Re-dump `schema/passe.sql` after applying (do not hand-edit the dump).

-- ── home_teammate_lobby_data ────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.home_teammate_lobby_data(bigint, jsonb, integer, character varying[], text, integer, integer);

CREATE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text DEFAULT NULL, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, timeslot_compat_score integer, profile_compat_score numeric, match_factors text[], already_requested boolean)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    v_ts_floor integer := 4;
    v_cnt      integer;
BEGIN
    -- ── Search mode: sport + visibility + identity gates only ──
    IF p_search IS NOT NULL AND p_search <> '' THEN
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
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (
                    l.name ILIKE '%' || p_search || '%'
                    OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                    OR l.searchable_id ILIKE '%' || p_search || '%'
                )
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
        RETURN;
    END IF;

    -- ── Non-search mode: existing logic, unchanged ──
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

-- ── home_challenger_lobby_data ──────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.home_challenger_lobby_data(uuid, bigint, integer, character varying[], text, integer, integer, integer);

CREATE FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text DEFAULT NULL, p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, lobby_mmr integer, favorability text, profile_compat_score numeric, match_factors text[], offer_time timestamp with time zone, offer_location_name text, offer_cost numeric, rated_match_count integer)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    c_home_adv  constant integer := 50;
    c_w_compat  constant numeric := 0.6;
    c_w_even    constant numeric := 0.4;
    v_mmr     integer;
    v_net     bigint[];
    v_active  bigint[];
    v_ind     integer[];
    v_pt      text[];
    v_lat     double precision;
    v_lon     double precision;
    v_window  integer := p_mmr_window;
    v_cnt     integer;
BEGIN
    SELECT l.mmr, l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
           loc.lat, loc.lon
      INTO v_mmr, v_net, v_active, v_ind, v_pt, v_lat, v_lon
      FROM public.lobby l
      LEFT JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    -- ── Search mode: sport + challenger gate + visibility + identity gates only ──
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
        WITH candidate AS (
            SELECT
                l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.visibility,
                l.member_count, l.mmr AS cand_mmr,
                l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
                l.challenge_offer_time, l.challenge_offer_cost, l.rated_match_count,
                oloc.name AS offer_location_name,
                oloc.district, oloc.lat, oloc.lon
            FROM public.lobby l
            JOIN public.location oloc ON oloc.id = l.challenge_offer_location
            LEFT JOIN public.location hloc ON hloc.id = l.home_ground
            WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
              AND l.challenge_offer_time > now()
              AND l.id <> p_context_lobby_id
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (
                   l.name ILIKE '%' || p_search || '%'
                   OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                   OR l.searchable_id ILIKE '%' || p_search || '%'
              )
        ),
        scored AS (
            SELECT
                c.*,
                1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
                (c.network_ids && v_net) AS f_network,
                ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
                ((c.district = ANY(p_districts))
                    OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                        AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
                (c.industry_ids && v_ind) AS f_industry,
                (
                    (CASE WHEN c.network_ids && v_net THEN 3 ELSE 0 END)
                  + (CASE WHEN c.active_network_ids && v_active THEN 2 ELSE 0 END)
                  + LEAST(2, cardinality(ARRAY(
                        SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt))))
                  + (CASE WHEN (c.district = ANY(p_districts))
                            OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                                AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)
                          THEN 1 ELSE 0 END)
                  + (CASE WHEN c.industry_ids && v_ind THEN 1 ELSE 0 END)
                )::numeric AS compat_raw
            FROM candidate c
        )
        SELECT
            s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.visibility,
            s.member_count, s.cand_mmr AS lobby_mmr,
            CASE WHEN s.away_expected > 0.55 THEN 'favored'
                 WHEN s.away_expected < 0.45 THEN 'underdog'
                 ELSE 'even' END AS favorability,
            (2.5 + (s.compat_raw / 9.0) * 2.5) AS profile_compat_score,
            ARRAY_REMOVE(ARRAY[
                CASE WHEN s.f_network  THEN 'network'  END,
                CASE WHEN s.f_playtime THEN 'playtime' END,
                CASE WHEN s.f_location THEN 'location' END,
                CASE WHEN s.f_industry THEN 'industry' END
            ], NULL) AS match_factors,
            s.challenge_offer_time, s.offer_location_name::text, s.challenge_offer_cost,
            s.rated_match_count
        FROM scored s
        ORDER BY (
            c_w_compat * (s.compat_raw / 9.0)
          + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
        ) DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    -- ── Non-search mode: existing logic, unchanged ──
    SELECT count(*) INTO v_cnt
      FROM public.lobby l
      JOIN public.location oloc ON oloc.id = l.challenge_offer_location
     WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
       AND l.challenge_offer_time > now()
       AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
       AND l.id NOT IN (SELECT public.get_my_lobby_ids())
       AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
    IF v_cnt < p_page_size THEN
        v_window := v_window * 2;
        SELECT count(*) INTO v_cnt
          FROM public.lobby l
          JOIN public.location oloc ON oloc.id = l.challenge_offer_location
         WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
           AND l.challenge_offer_time > now()
           AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
           AND l.id NOT IN (SELECT public.get_my_lobby_ids())
           AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
        IF v_cnt < p_page_size THEN
            v_window := 1000000;
        END IF;
    END IF;

    RETURN QUERY
    WITH candidate AS (
        SELECT
            l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.visibility,
            l.member_count, l.mmr AS cand_mmr,
            l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
            l.challenge_offer_time, l.challenge_offer_cost, l.rated_match_count,
            oloc.name AS offer_location_name,
            oloc.district, oloc.lat, oloc.lon
        FROM public.lobby l
        JOIN public.location oloc ON oloc.id = l.challenge_offer_location
        LEFT JOIN public.location hloc ON hloc.id = l.home_ground
        WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
          AND l.challenge_offer_time > now()
          AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
    ),
    scored AS (
        SELECT
            c.*,
            1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
            (c.network_ids && v_net) AS f_network,
            ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
            ((c.district = ANY(p_districts))
                OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                    AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
            (c.industry_ids && v_ind) AS f_industry,
            (
                (CASE WHEN c.network_ids && v_net THEN 3 ELSE 0 END)
              + (CASE WHEN c.active_network_ids && v_active THEN 2 ELSE 0 END)
              + LEAST(2, cardinality(ARRAY(
                    SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt))))
              + (CASE WHEN (c.district = ANY(p_districts))
                        OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                            AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)
                      THEN 1 ELSE 0 END)
              + (CASE WHEN c.industry_ids && v_ind THEN 1 ELSE 0 END)
            )::numeric AS compat_raw
        FROM candidate c
    )
    SELECT
        s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.visibility,
        s.member_count, s.cand_mmr AS lobby_mmr,
        CASE WHEN s.away_expected > 0.55 THEN 'favored'
             WHEN s.away_expected < 0.45 THEN 'underdog'
             ELSE 'even' END AS favorability,
        (2.5 + (s.compat_raw / 9.0) * 2.5) AS profile_compat_score,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN s.f_network  THEN 'network'  END,
            CASE WHEN s.f_playtime THEN 'playtime' END,
            CASE WHEN s.f_location THEN 'location' END,
            CASE WHEN s.f_industry THEN 'industry' END
        ], NULL) AS match_factors,
        s.challenge_offer_time, s.offer_location_name::text, s.challenge_offer_cost,
        s.rated_match_count
    FROM scored s
    ORDER BY (
        c_w_compat * (s.compat_raw / 9.0)
      + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
    ) DESC
    LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

ALTER FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) OWNER TO postgres;

GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text, p_mmr_window integer, p_page_size integer, p_page_number integer) TO service_role;

-- ── home_professional_data ──────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.home_professional_data(bigint, jsonb, integer, text[], text, integer, integer);

CREATE FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb DEFAULT '{}'::jsonb, p_city integer DEFAULT NULL::integer, p_districts text[] DEFAULT NULL::text[], p_search text DEFAULT NULL, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, display_name text, professional_role public.professional_role, bio text, sports bigint[], experience_years integer, average_rating numeric, review_count integer, is_verified boolean, price_from numeric, timeslot_compat_score integer)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    -- ── Search mode: sport gate only ──
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
            SELECT
                p.id,
                p.display_name::text,
                p.professional_role,
                p.bio,
                p.sports,
                p.experience_years,
                p.average_rating,
                p.review_count,
                p.is_verified,
                (
                    SELECT min(ps.hourly_rate)
                    FROM public.professional_service ps
                    WHERE ps.professional_id = p.id
                      AND ps.sport_id = p_sport_id
                      AND ps.is_active
                ) AS price_from,
                COALESCE(ts.ts_score, 0) AS timeslot_compat_score
            FROM
                public.professional p
                    CROSS JOIN LATERAL (
                    SELECT public.calculate_timeslot_compat_score(
                               p_timeslots,
                               public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
                           ) AS ts_score
                    ) ts
            WHERE
                p.sports @> ARRAY[p_sport_id]::bigint[]
              AND (
                    p.display_name ILIKE '%' || p_search || '%'
                    OR extensions.unaccent(p.display_name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                )
            ORDER BY
                p.is_verified DESC,
                p.average_rating DESC,
                p.review_count DESC
            LIMIT p_page_size
                OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    -- ── Non-search mode: existing logic, unchanged ──
    RETURN QUERY
        SELECT
            p.id,
            p.display_name::text,
            p.professional_role,
            p.bio,
            p.sports,
            p.experience_years,
            p.average_rating,
            p.review_count,
            p.is_verified,
            (
                SELECT min(ps.hourly_rate)
                FROM public.professional_service ps
                WHERE ps.professional_id = p.id
                  AND ps.sport_id = p_sport_id
                  AND ps.is_active
            ) AS price_from,
            COALESCE(ts.ts_score, 0) AS timeslot_compat_score
        FROM
            public.professional p
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                           p_timeslots,
                           public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
                       ) AS ts_score
                ) ts
        WHERE
            p.sports @> ARRAY[p_sport_id]::bigint[]
          AND (
                p_city IS NULL
                OR p.preferred_city_cluster IS NULL
                OR p.preferred_city_cluster = p_city
            )
          AND (
                p_districts IS NULL OR cardinality(p_districts) = 0
                OR p.preferred_districts IS NULL
                OR cardinality(p.preferred_districts) = 0
                OR p.preferred_districts && p_districts
            )
          AND (
                p_timeslots = '{}'::jsonb
                OR p.schedule IS NULL
                OR p.schedule = '[]'::jsonb
                OR ts.ts_score >= 4
            )
        ORDER BY
            p.is_verified DESC,
            p.average_rating DESC,
            p.review_count DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

ALTER FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) OWNER TO postgres;

GRANT ALL ON FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) TO anon;
GRANT ALL ON FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) TO authenticated;
GRANT ALL ON FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts text[], p_search text, p_page_size integer, p_page_number integer) TO service_role;
