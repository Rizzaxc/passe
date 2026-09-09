-- Lobby description: optional free-text "about us" for a lobby.
-- =================================================================
-- New top-level `lobby.description` column (not nested in `details` jsonb —
-- it's a primary content field like `name`, not per-user-style metadata).
-- Capped at 3000 chars (Facebook Group's own description limit).
--
-- Threaded through:
--   - create_lobby_with_location / update_lobby (settable at creation, editable after)
--   - home_teammate_lobby_data / home_challenger_lobby_data (card preview)
--   - a new get_lobby_public_preview RPC — a SECURITY DEFINER, anon-callable
--     lookup for the Discover card's "tap to see everything" public preview,
--     following the same shape as get_lobby_invite_preview /
--     get_lobby_befriend_invite_preview. It also aggregates member
--     demographics (gender/age-group makeup, top networks/industries) since
--     non-members/guests cannot read lobby_member/user/user_network/
--     user_industry directly under RLS (lobby_member's SELECT policy is
--     membership-gated; user/user_network/user_industry are
--     `TO authenticated` only, no anon policy).
--
-- update_lobby's authorization is ALSO widened here from captain-only to
-- lobby_can_manage() (captain OR coordinator) — it's one atomic RPC that
-- saves the whole form, so description's "captain + coordinator can edit"
-- requirement can't be gated separately from the rest of the fields it
-- already saves (name/visibility/playtime/details/home_ground). This means
-- coordinators now have edit access to the whole lobby form, not just
-- description — an intentional, confirmed widening of the coordinator tier.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).

-- ── 1. Column + CHECK ───────────────────────────────────────────────────

ALTER TABLE public.lobby
    ADD COLUMN description text,
    ADD CONSTRAINT lobby_description_length
        CHECK (description IS NULL OR char_length(description) <= 3000);

-- ── 2. create_lobby_with_location — add p_description ──────────────────

DROP FUNCTION IF EXISTS public.create_lobby_with_location(text, integer, text, jsonb, jsonb, uuid);

CREATE FUNCTION public.create_lobby_with_location(
    p_name text,
    p_sport_id integer,
    p_visibility text DEFAULT 'discoverable'::text,
    p_playtime jsonb DEFAULT NULL::jsonb,
    p_details jsonb DEFAULT NULL::jsonb,
    p_home_ground_id uuid DEFAULT NULL::uuid,
    p_description text DEFAULT NULL::text
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id  uuid;
    v_lobby_id uuid;
    v_result   jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, home_ground, captain_id, description)
    VALUES (
        p_name, p_sport_id, p_visibility::public.lobby_visibility,
        p_playtime, p_details, p_home_ground_id, v_user_id,
        NULLIF(p_description, '')
    )
    RETURNING id INTO v_lobby_id;

    SELECT row_to_json(l)::jsonb INTO v_result FROM public.lobby l WHERE l.id = v_lobby_id;
    RETURN v_result;
END;
$$;

ALTER FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_description text) OWNER TO postgres;

GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_description text) TO anon;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_description text) TO authenticated;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_description text) TO service_role;

-- ── 3. update_lobby — add p_description, widen auth to lobby_can_manage ─

DROP FUNCTION IF EXISTS public.update_lobby(uuid, text, text, jsonb, jsonb, uuid);

CREATE OR REPLACE FUNCTION public.update_lobby(
    p_lobby_id       uuid,
    p_name           text,
    p_visibility     text,
    p_playtime       jsonb DEFAULT NULL,
    p_details        jsonb DEFAULT NULL,
    p_home_ground_id uuid DEFAULT NULL,
    p_description    text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
BEGIN
    IF NOT public.lobby_can_manage(p_lobby_id, auth.uid()) THEN
        RAISE EXCEPTION 'update_lobby: caller is not authorized to manage this lobby';
    END IF;

    UPDATE public.lobby
    SET name        = p_name,
        visibility  = p_visibility::public.lobby_visibility,
        playtime    = p_playtime,
        details     = p_details,
        home_ground = p_home_ground_id,
        description = NULLIF(p_description, '')
    WHERE id = p_lobby_id;
END;
$$;

ALTER FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid, text) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid, text) TO authenticated;

-- ── 4. home_teammate_lobby_data — add description to the card feed ─────

DROP FUNCTION IF EXISTS public.home_teammate_lobby_data(bigint, jsonb, integer, character varying[], text, integer, integer);

CREATE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text DEFAULT NULL, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, description text, visibility public.lobby_visibility, member_count integer, timeslot_compat_score integer, profile_compat_score numeric, match_factors text[], already_requested boolean)
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
                l.description,
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
            l.description,
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

-- ── 5. home_challenger_lobby_data — add description to the card feed ───

DROP FUNCTION IF EXISTS public.home_challenger_lobby_data(uuid, bigint, integer, character varying[], text, integer, integer, integer);

CREATE FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text DEFAULT NULL, p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, description text, visibility public.lobby_visibility, member_count integer, lobby_mmr integer, favorability text, profile_compat_score numeric, match_factors text[], offer_time timestamp with time zone, offer_location_name text, offer_cost numeric, rated_match_count integer)
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
                l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.description, l.visibility,
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
            s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.description, s.visibility,
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
            l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.description, l.visibility,
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
        s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.description, s.visibility,
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

-- ── 6. get_lobby_public_preview — guest-callable public lobby preview ──
-- No auth required, same rationale as get_lobby_invite_preview: a guest
-- browsing Discover has no Supabase session at all. Defensively re-checks
-- visibility <> 'private' server-side (this RPC is directly callable, not
-- just reached through the already-filtered feed), and collapses "doesn't
-- exist" and "is private" into the same response shape so a guessed uuid
-- can't be used to probe which lobbies exist.
--
-- Aggregation (gender/age-group makeup, top networks/industries) happens
-- entirely in SQL — the same lobby_member -> user / user_network /
-- user_industry join shape calculate_profile_compat's lobby branch already
-- uses (schema/fitscore_factors.sql), adapted from "overlap with one target
-- user" into a GROUP BY/COUNT across every member. Percentages are left to
-- the client to compute from the raw counts — that's plain arithmetic, not
-- privileged data access.

CREATE OR REPLACE FUNCTION public.get_lobby_public_preview(
    p_lobby_id uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_lobby      record;
    v_members    integer;
    v_gender     jsonb;
    v_age        jsonb;
    v_networks   jsonb;
    v_industries jsonb;
BEGIN
    SELECT l.id, l.name, l.sport_id, l.description, l.playtime,
           l.mmr, l.rated_match_count,
           loc.name AS homeground_name, loc.lat, loc.lon
      INTO v_lobby
      FROM public.lobby l
      LEFT JOIN public.location loc ON loc.id = l.home_ground
     WHERE l.id = p_lobby_id
       AND l.visibility <> 'private';

    IF v_lobby IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    SELECT count(*) INTO v_members
      FROM public.lobby_member
     WHERE lobby_id = p_lobby_id;

    SELECT jsonb_build_object(
        'male',    count(*) FILTER (WHERE u.details->>'gender' = 'male'),
        'female',  count(*) FILTER (WHERE u.details->>'gender' = 'female'),
        'unknown', count(*) FILTER (WHERE u.details->>'gender' IS NULL)
    ) INTO v_gender
      FROM public.lobby_member lm
      JOIN public."user" u ON u.id = lm.user_id
     WHERE lm.lobby_id = p_lobby_id;

    SELECT coalesce(jsonb_object_agg(age_group, cnt), '{}'::jsonb) INTO v_age
      FROM (
          SELECT coalesce(u.details->>'ageGroup', 'unknown') AS age_group, count(*) AS cnt
            FROM public.lobby_member lm
            JOIN public."user" u ON u.id = lm.user_id
           WHERE lm.lobby_id = p_lobby_id
           GROUP BY 1
      ) t;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
               'id', network_id, 'name', name, 'category', category, 'count', cnt
           ) ORDER BY cnt DESC), '[]'::jsonb) INTO v_networks
      FROM (
          SELECT n.id AS network_id, n.name, n.category, count(*) AS cnt
            FROM public.lobby_member lm
            JOIN public.user_network un ON un.user_id = lm.user_id
            JOIN public.network n ON n.id = un.network_id
           WHERE lm.lobby_id = p_lobby_id
           GROUP BY n.id, n.name, n.category
           ORDER BY cnt DESC
           LIMIT 5
      ) t;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
               'industry_id', industry_id, 'count', cnt
           ) ORDER BY cnt DESC), '[]'::jsonb) INTO v_industries
      FROM (
          SELECT ui.industry_id, count(*) AS cnt
            FROM public.lobby_member lm
            JOIN public.user_industry ui ON ui.user_id = lm.user_id
           WHERE lm.lobby_id = p_lobby_id
           GROUP BY ui.industry_id
           ORDER BY cnt DESC
           LIMIT 5
      ) t;

    RETURN jsonb_build_object(
        'valid', true,
        'id', v_lobby.id,
        'name', v_lobby.name,
        'sport_id', v_lobby.sport_id,
        'description', v_lobby.description,
        'member_count', v_members,
        'playtime', v_lobby.playtime,
        'homeground_name', v_lobby.homeground_name,
        'homeground_lat', v_lobby.lat,
        'homeground_lon', v_lobby.lon,
        'mmr', v_lobby.mmr,
        'rated_match_count', v_lobby.rated_match_count,
        'gender_breakdown', v_gender,
        'age_group_breakdown', v_age,
        'top_networks', v_networks,
        'top_industries', v_industries
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_lobby_public_preview(uuid) TO anon, authenticated;
