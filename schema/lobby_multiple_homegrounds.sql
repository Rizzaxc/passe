-- Multiple homegrounds per lobby.
-- =================================================================
-- `lobby.home_ground` was a single FK to `location`. Replaced by `lobby_homeground`,
-- a lobby <-> location join table with one row per venue and exactly one row per
-- lobby flagged `is_primary`. The primary homeground is what every existing
-- single-venue call site (activity scheduling default, challenge-offer seed,
-- freeplay-expose seed, feed/preview display, invite preview) keeps reading —
-- no behavior regression there. `home_teammate_lobby_data`'s geo filter is
-- upgraded to match on ANY of a lobby's homegrounds, not just the primary one.
--
-- API shape: every write path takes an ORDERED `uuid[]` of location ids where
-- the FIRST element is primary (no separate "which one is primary" param) —
-- this mirrors directly into an ordered `List<String>` client-side, so "make
-- it primary" is just "move it to the front".
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).

-- ── 1. lobby_homeground table + RLS + helper ────────────────────────────

CREATE TABLE public.lobby_homeground (
    lobby_id    uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    location_id uuid NOT NULL REFERENCES public.location(id),
    is_primary  boolean NOT NULL DEFAULT false,
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (lobby_id, location_id)
);

CREATE UNIQUE INDEX lobby_homeground_one_primary_idx ON public.lobby_homeground (lobby_id) WHERE is_primary;
CREATE INDEX idx_lobby_homeground_location ON public.lobby_homeground (location_id);

ALTER TABLE public.lobby_homeground ENABLE ROW LEVEL SECURITY;

-- mirrors lobby's own "Enable read access for all users" policy
CREATE POLICY "Enable read access for all users" ON public.lobby_homeground FOR SELECT USING (true);

-- manage-tier (captain or coordinator), matching update_lobby's own authorization.
-- Split per-action (not FOR ALL) to match `lobby`'s own policy shape and avoid
-- double-evaluating against the SELECT policy above; auth.uid() wrapped in a
-- subselect so the planner evaluates it once instead of per row.
CREATE POLICY "Lobby manager can add homegrounds" ON public.lobby_homeground
    FOR INSERT TO authenticated
    WITH CHECK (public.lobby_can_manage(lobby_id, (select auth.uid())));

CREATE POLICY "Lobby manager can update homegrounds" ON public.lobby_homeground
    FOR UPDATE TO authenticated
    USING (public.lobby_can_manage(lobby_id, (select auth.uid())))
    WITH CHECK (public.lobby_can_manage(lobby_id, (select auth.uid())));

CREATE POLICY "Lobby manager can remove homegrounds" ON public.lobby_homeground
    FOR DELETE TO authenticated
    USING (public.lobby_can_manage(lobby_id, (select auth.uid())));

-- single reusable expression for every "the lobby's default venue" call site
CREATE OR REPLACE FUNCTION public.lobby_primary_homeground_id(p_lobby_id uuid)
RETURNS uuid LANGUAGE sql STABLE SET search_path TO 'public' AS $$
  SELECT location_id FROM public.lobby_homeground WHERE lobby_id = p_lobby_id AND is_primary LIMIT 1;
$$;

-- ── 2. Migrate existing single values, then drop the old column ─────────

INSERT INTO public.lobby_homeground (lobby_id, location_id, is_primary)
SELECT id, home_ground, true FROM public.lobby WHERE home_ground IS NOT NULL;

ALTER TABLE public.lobby DROP CONSTRAINT lobby_home_ground_fkey;
DROP INDEX public.idx_lobby_home_ground;
ALTER TABLE public.lobby DROP COLUMN home_ground;

-- ── 3. create_lobby_with_location — p_home_ground_id -> p_home_ground_ids ─

DROP FUNCTION IF EXISTS public.create_lobby_with_location(text, integer, text, jsonb, jsonb, uuid, text);

CREATE FUNCTION public.create_lobby_with_location(
    p_name text,
    p_sport_id integer,
    p_visibility text DEFAULT 'discoverable'::text,
    p_playtime jsonb DEFAULT NULL::jsonb,
    p_details jsonb DEFAULT NULL::jsonb,
    p_home_ground_ids uuid[] DEFAULT NULL::uuid[],
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
    IF p_home_ground_ids IS NOT NULL AND cardinality(p_home_ground_ids) > 5 THEN
        RAISE EXCEPTION 'create_lobby_with_location: at most 5 homegrounds allowed';
    END IF;

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, captain_id, description)
    VALUES (
        p_name, p_sport_id, p_visibility::public.lobby_visibility,
        p_playtime, p_details, v_user_id,
        NULLIF(p_description, '')
    )
    RETURNING id INTO v_lobby_id;

    IF p_home_ground_ids IS NOT NULL AND cardinality(p_home_ground_ids) > 0 THEN
        INSERT INTO public.lobby_homeground (lobby_id, location_id, is_primary)
        SELECT v_lobby_id, loc_id, (ord = 1)
          FROM unnest(p_home_ground_ids) WITH ORDINALITY AS t(loc_id, ord)
        ON CONFLICT (lobby_id, location_id) DO NOTHING;
    END IF;

    SELECT row_to_json(l)::jsonb INTO v_result FROM public.lobby l WHERE l.id = v_lobby_id;
    RETURN v_result;
END;
$$;

ALTER FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_ids uuid[], p_description text) OWNER TO postgres;

GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_ids uuid[], p_description text) TO anon;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_ids uuid[], p_description text) TO authenticated;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_ids uuid[], p_description text) TO service_role;

-- ── 4. update_lobby — p_home_ground_id -> p_home_ground_ids, replace-the-set ─

DROP FUNCTION IF EXISTS public.update_lobby(uuid, text, text, jsonb, jsonb, uuid, text);

CREATE FUNCTION public.update_lobby(
    p_lobby_id        uuid,
    p_name            text,
    p_visibility      text,
    p_playtime        jsonb DEFAULT NULL,
    p_details         jsonb DEFAULT NULL,
    p_home_ground_ids uuid[] DEFAULT NULL,
    p_description     text DEFAULT NULL
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
    IF p_home_ground_ids IS NOT NULL AND cardinality(p_home_ground_ids) > 5 THEN
        RAISE EXCEPTION 'update_lobby: at most 5 homegrounds allowed';
    END IF;

    UPDATE public.lobby
    SET name        = p_name,
        visibility  = p_visibility::public.lobby_visibility,
        playtime    = p_playtime,
        details     = p_details,
        description = NULLIF(p_description, '')
    WHERE id = p_lobby_id;

    DELETE FROM public.lobby_homeground WHERE lobby_id = p_lobby_id;
    IF p_home_ground_ids IS NOT NULL AND cardinality(p_home_ground_ids) > 0 THEN
        INSERT INTO public.lobby_homeground (lobby_id, location_id, is_primary)
        SELECT p_lobby_id, loc_id, (ord = 1)
          FROM unnest(p_home_ground_ids) WITH ORDINALITY AS t(loc_id, ord)
        ON CONFLICT (lobby_id, location_id) DO NOTHING;
    END IF;
END;
$$;

ALTER FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid[], text) OWNER TO postgres;

GRANT ALL ON FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid[], text) TO anon;
GRANT ALL ON FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid[], text) TO authenticated;
GRANT ALL ON FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid[], text) TO service_role;

-- ── 5. home_teammate_lobby_data — display off primary, geo filter off ANY ─

CREATE OR REPLACE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_search text DEFAULT NULL::text, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, description text, visibility public.lobby_visibility, member_count integer, timeslot_compat_score integer, profile_compat_score numeric, match_factors text[], already_requested boolean)
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
                    LEFT JOIN public.lobby_homeground plhg ON plhg.lobby_id = l.id AND plhg.is_primary
                    LEFT JOIN public.location loc ON loc.id = plhg.location_id
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

    -- ── Non-search mode: matches p_city/p_districts against ANY of the
    -- lobby's homegrounds now (a lobby with none still passes through,
    -- same as before) ──
    IF p_timeslots <> '{}'::jsonb THEN
        SELECT count(*) INTO v_cnt
        FROM public.lobby l
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                       p_timeslots, public.fn_playtime_to_dict(l.playtime)
                   ) AS ts_score
        ) ts
        WHERE l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND (
                NOT EXISTS (SELECT 1 FROM public.lobby_homeground gh WHERE gh.lobby_id = l.id)
                OR EXISTS (
                    SELECT 1 FROM public.lobby_homeground gh
                    JOIN public.location gloc ON gloc.id = gh.location_id
                    WHERE gh.lobby_id = l.id
                      AND gloc.city_cluster = p_city
                      AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR gloc.district = ANY(p_districts))
                )
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
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                           p_timeslots, public.fn_playtime_to_dict(l.playtime)
                       ) AS ts_score
            ) ts
            WHERE l.sport_id = p_sport_id
              AND l.visibility != 'private'
              AND l.id NOT IN (SELECT public.get_my_lobby_ids())
              AND (
                    NOT EXISTS (SELECT 1 FROM public.lobby_homeground gh WHERE gh.lobby_id = l.id)
                    OR EXISTS (
                        SELECT 1 FROM public.lobby_homeground gh
                        JOIN public.location gloc ON gloc.id = gh.location_id
                        WHERE gh.lobby_id = l.id
                          AND gloc.city_cluster = p_city
                          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR gloc.district = ANY(p_districts))
                    )
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
                LEFT JOIN public.lobby_homeground plhg ON plhg.lobby_id = l.id AND plhg.is_primary
                LEFT JOIN public.location loc ON loc.id = plhg.location_id
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
                NOT EXISTS (SELECT 1 FROM public.lobby_homeground gh WHERE gh.lobby_id = l.id)
                OR EXISTS (
                    SELECT 1 FROM public.lobby_homeground gh
                    JOIN public.location gloc ON gloc.id = gh.location_id
                    WHERE gh.lobby_id = l.id
                      AND gloc.city_cluster = p_city
                      AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR gloc.district = ANY(p_districts))
                )
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

-- ── 6. home_challenger_lobby_data — display off primary (home_ground here is
-- only ever a label; the real geo anchor is challenge_offer_location) ──────

CREATE OR REPLACE FUNCTION public.home_challenger_lobby_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer, p_districts character varying[], p_search text DEFAULT NULL::text, p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name text, homeground_name text, playtime jsonb, details jsonb, description text, visibility public.lobby_visibility, member_count integer, lobby_mmr integer, favorability text, profile_compat_score numeric, match_factors text[], offer_time timestamp with time zone, offer_location_name text, offer_cost numeric, rated_match_count integer)
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
      LEFT JOIN public.location loc ON loc.id = public.lobby_primary_homeground_id(l.id)
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
            LEFT JOIN public.location hloc ON hloc.id = public.lobby_primary_homeground_id(l.id)
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
        LEFT JOIN public.location hloc ON hloc.id = public.lobby_primary_homeground_id(l.id)
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

-- ── 7. get_lobby_public_preview — keep primary as the default pin, add the
-- full list so the sheet can show/plot all of a lobby's homegrounds ────────

CREATE OR REPLACE FUNCTION public.get_lobby_public_preview(
    p_lobby_id uuid
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_lobby       record;
    v_members     integer;
    v_gender      jsonb;
    v_age         jsonb;
    v_networks    jsonb;
    v_industries  jsonb;
    v_homegrounds jsonb;
BEGIN
    SELECT l.id, l.name, l.sport_id, l.description, l.playtime,
           l.mmr, l.rated_match_count,
           loc.name AS homeground_name, loc.lat, loc.lon
      INTO v_lobby
      FROM public.lobby l
      LEFT JOIN public.lobby_homeground plhg ON plhg.lobby_id = l.id AND plhg.is_primary
      LEFT JOIN public.location loc ON loc.id = plhg.location_id
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

    SELECT coalesce(jsonb_agg(jsonb_build_object(
               'id', gloc.id, 'name', gloc.name, 'lat', gloc.lat, 'lon', gloc.lon
           ) ORDER BY gh.is_primary DESC, gh.created_at), '[]'::jsonb) INTO v_homegrounds
      FROM public.lobby_homeground gh
      JOIN public.location gloc ON gloc.id = gh.location_id
     WHERE gh.lobby_id = p_lobby_id;

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
        'homegrounds', v_homegrounds,
        'mmr', v_lobby.mmr,
        'rated_match_count', v_lobby.rated_match_count,
        'gender_breakdown', v_gender,
        'age_group_breakdown', v_age,
        'top_networks', v_networks,
        'top_industries', v_industries
    );
END;
$$;

ALTER FUNCTION public.get_lobby_public_preview(p_lobby_id uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.get_lobby_public_preview(p_lobby_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_lobby_public_preview(p_lobby_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_lobby_public_preview(p_lobby_id uuid) TO service_role;

-- ── 8. my_schedule_data — default venue off the primary homeground ─────

CREATE OR REPLACE FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) RETURNS TABLE(id uuid, start_time timestamp with time zone, end_time timestamp with time zone, title text, meta text, tone text, recurrence_day_of_week smallint)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
    SELECT a.id, a.start_time, a.end_time, l.name::text,
           COALESCE(loc.name, '')::text, 'sport'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, public.lobby_primary_homeground_id(l.id))
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.lobby_id IN (SELECT lobby_id FROM public.lobby_member WHERE user_id = v_uid)
      AND a.start_time >= p_from AND a.start_time <= p_to

    UNION ALL

    SELECT a.id, a.start_time, a.end_time,
           coalesce(h.display_name, l.name::text, 'Xé vé')::text,
           COALESCE(loc.name, fa.venue_name, '')::text, 'freeplay'::text,
           a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id = a.id
    LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    LEFT JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, public.lobby_primary_homeground_id(l.id))
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND EXISTS (SELECT 1 FROM public.freeplay_request r
                  WHERE r.activity_id = a.id AND r.user_id = v_uid AND r.status = 'accepted')

    UNION ALL

    SELECT a.id, a.start_time, a.end_time,
           coalesce(c.name, p.display_name)::text,
           COALESCE(loc.name, '')::text, 'coach'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.course c ON c.id = a.course_id
    JOIN public.professional p ON p.id = c.professional_id
    LEFT JOIN public.location loc ON loc.id = a.location_id
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.proposal_status = 'approved'
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND (
        EXISTS (SELECT 1 FROM public.course_member m
                WHERE m.course_id = c.id AND m.user_id = v_uid AND m.left_at IS NULL)
        OR p.linked_user_id = v_uid
      );
END
$$;

ALTER FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) FROM PUBLIC;
GRANT ALL ON FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) TO authenticated;
GRANT ALL ON FUNCTION public.my_schedule_data(p_sport_id bigint, p_from timestamp with time zone, p_to timestamp with time zone) TO service_role;

-- ── 9. expose_lobby_activity_freeplay — fall back to the primary homeground ─

CREATE OR REPLACE FUNCTION public.expose_lobby_activity_freeplay(p_activity_id uuid, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text DEFAULT ''::text, p_location_id uuid DEFAULT NULL::uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_a record; v_loc uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;

  SELECT a.id, a.lobby_id, a.location_id
  INTO v_a
  FROM public.activity a JOIN public.lobby l ON l.id = a.lobby_id
  WHERE a.id = p_activity_id FOR UPDATE OF a;
  IF NOT FOUND THEN RAISE EXCEPTION 'lobby activity not found'; END IF;

  IF NOT public.lobby_can_manage(v_a.lobby_id, v_uid) THEN
    RAISE EXCEPTION 'caller is not authorized to manage this lobby';
  END IF;
  IF EXISTS (SELECT 1 FROM public.freeplay_activity WHERE activity_id = p_activity_id) THEN
    RAISE EXCEPTION 'activity is already exposed';
  END IF;

  -- Venue materialisation. A lobby activity may carry no `location_id` at all
  -- and lean on the lobby's primary home ground, but `home_freeplay_data`
  -- filters on a concrete city cluster it resolves through
  -- `activity.location_id` — so pin one now rather than teach the feed a
  -- second fallback. `p_location_id` is the last resort for a lobby with no
  -- home ground either.
  v_loc := coalesce(v_a.location_id, public.lobby_primary_homeground_id(v_a.lobby_id), p_location_id);
  IF v_loc IS NULL THEN
    RAISE EXCEPTION 'a listing needs a venue: set one on the activity or pick one here';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.location WHERE id = v_loc) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  IF v_a.location_id IS DISTINCT FROM v_loc THEN
    UPDATE public.activity SET location_id = v_loc WHERE id = p_activity_id;
  END IF;

  -- Every free-venue column stays NULL, which is the shape
  -- `freeplay_free_venue_complete` expects (and what live Host rows look like)
  -- — the address is read off `location` at query time.
  INSERT INTO public.freeplay_activity(activity_id, description, capacity, male_price,
    female_price, recommended_skills)
  VALUES (p_activity_id, coalesce(p_description,''), p_capacity, p_male_price,
    p_female_price, p_recommended_skills);
END
$$;

ALTER FUNCTION public.expose_lobby_activity_freeplay(p_activity_id uuid, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) OWNER TO postgres;

REVOKE ALL ON FUNCTION public.expose_lobby_activity_freeplay(p_activity_id uuid, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.expose_lobby_activity_freeplay(p_activity_id uuid, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.expose_lobby_activity_freeplay(p_activity_id uuid, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO service_role;

-- ── 10. get_lobby_befriend_invite_preview — home_ground_name off primary ─

CREATE OR REPLACE FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_rec record;
    v_result jsonb;
    v_friend_status public.lobby_befriend_status;
    v_addressee uuid;
    v_relationship text;
BEGIN
    IF v_uid IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    SELECT bfr.status, bfr.target_lobby_id,
           l.name AS lobby_name, l.details AS lobby_details, l.visibility,
           l.sport_id, l.captain_id, l.playtime, l.mmr,
           cap.username AS captain_username,
           ini.username AS inviter_username
      INTO v_rec
      FROM public.lobby_befriend_record bfr
      JOIN public.lobby l ON l.id = bfr.target_lobby_id
      JOIN public."user" cap ON cap.id = l.captain_id
      JOIN public."user" ini ON ini.id = bfr.initiator_user_id
     WHERE bfr.id = p_record_id
       AND bfr.target_user_id = v_uid
       AND bfr.interaction_type = 'invite';

    IF v_rec IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    -- Base tier: shown regardless of the lobby's visibility.
    v_result := jsonb_build_object(
        'valid', true,
        'status', v_rec.status,
        'lobby_id', v_rec.target_lobby_id,
        'lobby_name', v_rec.lobby_name,
        'has_avatar', coalesce((v_rec.lobby_details ->> 'hasAvatar')::boolean, false),
        'visibility', v_rec.visibility,
        'inviter_username', v_rec.inviter_username
    );

    IF v_rec.visibility IN ('discoverable', 'public') THEN
        SELECT f.status, f.addressee_id INTO v_friend_status, v_addressee
          FROM public.friendship f
         WHERE f.status IN ('pending', 'accepted')
           AND least(f.requester_id, f.addressee_id) = least(v_uid, v_rec.captain_id)
           AND greatest(f.requester_id, f.addressee_id) = greatest(v_uid, v_rec.captain_id);

        v_relationship := CASE
            WHEN public.fn_is_blocked(v_uid, v_rec.captain_id) THEN 'blocked'
            WHEN v_friend_status = 'accepted' THEN 'friend'
            WHEN v_friend_status = 'pending' AND v_addressee = v_uid THEN 'incoming'
            WHEN v_friend_status = 'pending' THEN 'outgoing'
            ELSE 'none'
        END;

        v_result := v_result || jsonb_build_object(
            'member_count', (
                SELECT count(*) FROM public.lobby_member lm
                 WHERE lm.lobby_id = v_rec.target_lobby_id
            ),
            'captain_username', v_rec.captain_username,
            'relationship', v_relationship,
            'fitscore', public.calculate_profile_compat_score(
                v_uid, v_rec.target_lobby_id, v_rec.sport_id
            )
        );
    END IF;

    IF v_rec.visibility = 'public' THEN
        v_result := v_result || jsonb_build_object(
            'home_ground_name', (
                SELECT loc.name FROM public.location loc
                 WHERE loc.id = public.lobby_primary_homeground_id(v_rec.target_lobby_id)
            ),
            'playtime', v_rec.playtime,
            'mmr', v_rec.mmr,
            'is_mmr_calibrated', EXISTS(
                SELECT 1 FROM public.lobby_match lm
                 WHERE lm.lobby_id = v_rec.target_lobby_id
                   AND lm.opponent_lobby_id IS NOT NULL
            ),
            'members', (
                SELECT coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'username', u.username, 'tag_number', u.tag_number
                        ) ORDER BY u.username
                    ),
                    '[]'::jsonb
                )
                  FROM public.lobby_member lm2
                  JOIN public."user" u ON u.id = lm2.user_id
                 WHERE lm2.lobby_id = v_rec.target_lobby_id
            )
        );
    END IF;

    RETURN v_result;
END;
$$;

ALTER FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_lobby_befriend_invite_preview(p_record_id uuid) TO service_role;
