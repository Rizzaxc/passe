-- FitScore factors — make the feed-card "vibe" chips truthful
-- ===========================================================
-- Before this, the card *inferred* which match factors to show from score
-- thresholds (e.g. score >= 2.0 ⇒ "Chung mạng lưới"). After the [2.5, 5]
-- rebaseline, 2.0 sits BELOW the 2.5 floor, so that chip fired on every lobby —
-- a lobby at the neutral floor (no real signal) still showed factor chips.
--
-- Fix: the scoring functions now also return the *actual* factor codes that
-- contributed, and the RPCs surface them as `match_factors text[]`. The card
-- renders those directly instead of guessing.
--
-- Factor codes: network | industry | skill | age | gender | playtime | location
--
-- Also rebaselines the challenger feed's inline compat score from [1, 5] to
-- [2.5, 5] so both feeds share the same band / floor.

-- ---------------------------------------------------------------------------
-- 1. Core: compute score + factors together. Returns {"score", "factors"}.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS jsonb
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    raw_score   NUMERIC := 0;
    max_raw     NUMERIC := 10;
    base_score  NUMERIC := 2.5;
    top_score   NUMERIC := 5;
    final_score NUMERIC;
    factors     TEXT[] := ARRAY[]::TEXT[];

    is_user BOOLEAN;
    host_id UUID;
    user_details   JSONB;
    target_details JSONB;
    sport_id_text  TEXT;

    user_skill_level INTEGER;
    user_gender   TEXT;
    user_age      TEXT;

    shared_network_count        INTEGER := 0;
    active_shared_network_count INTEGER := 0;
    shared_industry_count       INTEGER := 0;

    total_lobby_members               INTEGER := 0;
    lobby_members_with_shared_network INTEGER := 0;
    lobby_members_with_same_skill     INTEGER := 0;
    lobby_members_same_age            INTEGER := 0;
    lobby_female_members              INTEGER := 0;
    has_active_shared_member          BOOLEAN := FALSE;
BEGIN
    sport_id_text := p_sport_id::TEXT;

    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    IF user_details->'sport' ? sport_id_text AND user_details->'sport'->sport_id_text ? 'skill' THEN
        user_skill_level := (user_details->'sport'->sport_id_text->>'skill')::INTEGER;
    END IF;
    user_gender := user_details->>'gender';
    user_age    := user_details->>'ageGroup';

    IF is_user THEN
        -- USER-TO-USER
        SELECT details INTO target_details FROM public."user" WHERE id = p_target_id;

        SELECT COUNT(*) INTO shared_network_count
        FROM public.user_network un1
                 JOIN public.user_network un2 ON un1.network_id = un2.network_id
        WHERE un1.user_id = p_user_id AND un2.user_id = p_target_id;

        IF shared_network_count > 0 THEN
            raw_score := raw_score + 3;
            factors := array_append(factors, 'network');

            SELECT COUNT(*) INTO active_shared_network_count
            FROM public.user_network un1
                     JOIN public.user_network un2 ON un1.network_id = un2.network_id
            WHERE un1.user_id = p_user_id
              AND un2.user_id = p_target_id
              AND NOT un1.alumni
              AND NOT un2.alumni;

            IF active_shared_network_count > 0 THEN
                raw_score := raw_score + 1;
            END IF;
        ELSE
            SELECT COUNT(*) INTO shared_industry_count
            FROM public.user_industry ui1
                     JOIN public.user_industry ui2 ON ui1.industry_id = ui2.industry_id
            WHERE ui1.user_id = p_user_id AND ui2.user_id = p_target_id;

            IF shared_industry_count > 0 THEN
                raw_score := raw_score + 2;
                factors := array_append(factors, 'industry');
            END IF;
        END IF;

        IF user_skill_level IS NOT NULL AND
           target_details->'sport' ? sport_id_text AND
           target_details->'sport'->sport_id_text ? 'skill' AND
           user_skill_level = (target_details->'sport'->sport_id_text->>'skill')::INTEGER THEN
            raw_score := raw_score + 3;
            factors := array_append(factors, 'skill');
        END IF;

        IF user_age IS NOT NULL AND user_age = (target_details->>'ageGroup') THEN
            raw_score := raw_score + 1.5;
            factors := array_append(factors, 'age');
        END IF;

        IF user_gender = 'female' AND (target_details->>'gender') = 'female' THEN
            raw_score := raw_score + 2;
            factors := array_append(factors, 'gender');
        END IF;

    ELSE
        -- USER-TO-LOBBY
        SELECT COUNT(*) INTO total_lobby_members
        FROM public.lobby_member
        WHERE lobby_id = p_target_id;

        SELECT captain_id INTO host_id
        FROM public.lobby
        WHERE id = p_target_id;

        IF total_lobby_members = 1 AND host_id IS NOT NULL THEN
            RETURN public.calculate_profile_compat(p_user_id, host_id, p_sport_id);
        END IF;

        IF total_lobby_members = 0 THEN
            RETURN jsonb_build_object('score', base_score, 'factors', factors);
        END IF;

        SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_shared_network
        FROM public.lobby_member lm
                 JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                 JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
        WHERE lm.lobby_id = p_target_id
          AND un_user.user_id = p_user_id;

        IF lobby_members_with_shared_network >= 3 THEN
            raw_score := raw_score + 4;
            factors := array_append(factors, 'network');
        ELSIF lobby_members_with_shared_network >= 1 THEN
            raw_score := raw_score + 2;
            factors := array_append(factors, 'network');

            SELECT EXISTS (
                SELECT 1
                FROM public.lobby_member lm
                         JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                         JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
                WHERE lm.lobby_id = p_target_id
                  AND un_user.user_id = p_user_id
                  AND NOT un_member.alumni
                  AND NOT un_user.alumni
            ) INTO has_active_shared_member;

            IF has_active_shared_member THEN
                raw_score := raw_score + 1;
            END IF;
        END IF;

        IF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND u.details->'sport' ? sport_id_text
              AND u.details->'sport'->sport_id_text ? 'skill'
              AND (u.details->'sport'->sport_id_text->>'skill')::INTEGER = user_skill_level;

            IF lobby_members_with_same_skill * 2 >= total_lobby_members THEN
                raw_score := raw_score + 3;
                factors := array_append(factors, 'skill');
            END IF;
        END IF;

        IF user_age IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_same_age
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND (u.details->>'ageGroup') = user_age;

            IF lobby_members_same_age * 2 >= total_lobby_members THEN
                raw_score := raw_score + 1.5;
                factors := array_append(factors, 'age');
            END IF;
        END IF;

        IF user_gender = 'female' THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_female_members
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND (u.details->>'gender') = 'female';

            IF lobby_female_members >= 1 THEN
                raw_score := raw_score + 2;
                factors := array_append(factors, 'gender');
            END IF;
        END IF;
    END IF;

    final_score := base_score + (LEAST(raw_score, max_raw) / max_raw) * (top_score - base_score);
    final_score := GREATEST(base_score, LEAST(top_score, final_score));

    RETURN jsonb_build_object('score', ROUND(final_score, 1), 'factors', factors);
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. Backward-compatible score-only wrapper (other callers keep working).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS numeric
    LANGUAGE sql
    STABLE
    SET search_path TO ''
    AS $$
    SELECT (public.calculate_profile_compat(p_user_id, p_target_id, p_sport_id)->>'score')::numeric;
$$;

GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO anon;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO service_role;

-- ---------------------------------------------------------------------------
-- 3. Teammate feed: surface match_factors (profile factors + playtime).
--    DROP required: the RETURNS TABLE shape gains a column.
-- ---------------------------------------------------------------------------
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
    visibility public.lobby_visibility, timeslot_compat_score integer,
    profile_compat_score numeric, match_factors text[]
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
            ts.ts_score AS timeslot_compat_score,
            (ps.compat->>'score')::numeric AS profile_compat_score,
            (
                ARRAY(SELECT jsonb_array_elements_text(ps.compat->'factors'))
                || CASE WHEN ts.ts_score >= 4 THEN ARRAY['playtime'] ELSE ARRAY[]::text[] END
            ) AS match_factors
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
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. Challenger feed: rebaseline to [2.5, 5] + surface match_factors.
--    DROP required: the RETURNS TABLE shape gains a column.
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.home_challenger_lobby_data(uuid, bigint, integer, character varying[], integer, integer, integer);

CREATE OR REPLACE FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, visibility public.lobby_visibility, member_count integer, lobby_mmr integer, favorability text, profile_compat_score numeric, match_factors text[])
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
    SELECT l.mmr, l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys, loc.lat, loc.lon
      INTO v_mmr, v_net, v_active, v_ind, v_pt, v_lat, v_lon
      FROM public.lobby l
      LEFT JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    SELECT count(*) INTO v_cnt
      FROM public.lobby l
      JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
       AND loc.city_cluster = p_city AND l.id <> p_context_lobby_id
       AND l.id NOT IN (SELECT public.get_my_lobby_ids())
       AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
    IF v_cnt < p_page_size THEN
        v_window := v_window * 2;
        SELECT count(*) INTO v_cnt
          FROM public.lobby l
          JOIN public.location loc ON l.home_ground = loc.id
         WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
           AND loc.city_cluster = p_city AND l.id <> p_context_lobby_id
           AND l.id NOT IN (SELECT public.get_my_lobby_ids())
           AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window;
        IF v_cnt < p_page_size THEN
            v_window := 1000000;
        END IF;
    END IF;

    RETURN QUERY
    WITH candidate AS (
        SELECT
            l.id, l.name, loc.name AS homeground_name, l.playtime, l.details, l.visibility,
            l.member_count, l.mmr AS cand_mmr,
            l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
            loc.district, loc.lat, loc.lon
        FROM public.lobby l
        JOIN public.location loc ON l.home_ground = loc.id
        WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
          AND loc.city_cluster = p_city AND l.id <> p_context_lobby_id
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
    ),
    scored AS (
        SELECT
            c.*,
            1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
            (c.network_ids && v_net)            AS f_network,
            ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
            ((c.district = ANY(p_districts))
                OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                    AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
            (c.industry_ids && v_ind)           AS f_industry,
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
        ], NULL) AS match_factors
    FROM scored s
    ORDER BY (
        c_w_compat * (s.compat_raw / 9.0)
      + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
    ) DESC
    LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
