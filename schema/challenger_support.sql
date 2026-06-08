-- Challenger subtab support — lobby-vs-lobby discovery + lobby MMR (hybrid Elo) + compat.
--
-- Rating model: players keep their per-sport Elo (public.user_rating, seeded by fn_seed_initial_elo).
-- A lobby's MMR is the top-N of its current members' Elo (N = LEAST(5, member_count)). All
-- match-likelihood inputs (MMR, member_count, member networks/industries, playtime) are CACHED on the
-- lobby row and refreshed by triggers, so the client-facing read RPC stays SECURITY INVOKER and never
-- needs to read RLS-restricted opponent lobby_member rows.
--
-- SECURITY DEFINER is confined to the write-time recompute helper + its triggers (they read a lobby's
-- full roster / cross-user ratings, which RLS would otherwise hide). search_path is pinned to '' on
-- every function for definer-safety. Match->rating propagation (blowout logic) is a SEPARATE later
-- migration; this file is read-side only.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Cached columns on lobby
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.lobby
    ADD COLUMN IF NOT EXISTS open_to_challengers boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS mmr                integer  NOT NULL DEFAULT 1000,
    ADD COLUMN IF NOT EXISTS member_count       integer  NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS network_ids        bigint[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS active_network_ids bigint[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS industry_ids       integer[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS playtime_keys      text[]   NOT NULL DEFAULT '{}';

-- Windowed MMR scan support.
CREATE INDEX IF NOT EXISTS lobby_open_challenger_mmr_idx
    ON public.lobby (sport_id, mmr)
    WHERE open_to_challengers;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- Map a lobby's bigint sport_id to the text key used in user_rating.sport
-- (mirrors the Dart Sport enum order; 'others'=0 has no rating).
CREATE OR REPLACE FUNCTION public.fn_sport_name(p_sport_id bigint)
    RETURNS text
    LANGUAGE sql
    IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT CASE p_sport_id
               WHEN 1 THEN 'soccer'
               WHEN 2 THEN 'basketball'
               WHEN 3 THEN 'badminton'
               WHEN 4 THEN 'tennis'
               WHEN 5 THEN 'pickleball'
               ELSE NULL
           END;
$$;

-- Normalise a lobby.playtime (array of {dayOfWeek, dayChunk}) into 'day:chunk'
-- tokens with composite days expanded, for cheap overlap scoring.
CREATE OR REPLACE FUNCTION public.fn_lobby_playtime_keys(p_playtime jsonb)
    RETURNS text[]
    LANGUAGE sql
    IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT COALESCE(array_agg(DISTINCT base_day || ':' || chunk), '{}')
    FROM (
        SELECT
            elem->>'dayChunk' AS chunk,
            unnest(CASE elem->>'dayOfWeek'
                       WHEN 'all' THEN ARRAY['mon','tue','wed','thu','fri','sat','sun']
                       WHEN 'mwf' THEN ARRAY['mon','wed','fri']
                       WHEN 'tts' THEN ARRAY['tue','thu','sat']
                       WHEN 'wkn' THEN ARRAY['sat','sun']
                       ELSE ARRAY[elem->>'dayOfWeek']
                   END) AS base_day
        FROM jsonb_array_elements(
                 CASE WHEN jsonb_typeof(COALESCE(p_playtime, '[]'::jsonb)) = 'array'
                      THEN p_playtime ELSE '[]'::jsonb END
             ) AS elem
        WHERE elem->>'dayChunk' IS NOT NULL AND elem->>'dayOfWeek' IS NOT NULL
    ) expanded;
$$;

-- Recompute every member-derived cached column for one lobby.
CREATE OR REPLACE FUNCTION public.fn_lobby_recompute_stats(p_lobby_id uuid)
    RETURNS void
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_sport      text;
    v_mmr        integer;
    v_count      integer;
    v_net        bigint[];
    v_active_net bigint[];
    v_ind        integer[];
BEGIN
    SELECT public.fn_sport_name(l.sport_id) INTO v_sport
    FROM public.lobby l WHERE l.id = p_lobby_id;

    SELECT count(*)::integer INTO v_count
    FROM public.lobby_member WHERE lobby_id = p_lobby_id;

    -- MMR: top-5 of members' Elo for the sport (unrated member = 1000).
    WITH member_elo AS (
        SELECT COALESCE(MAX(ur.elo), 1000) AS elo
        FROM public.lobby_member lm
        LEFT JOIN public.user_rating ur
            ON ur.user_id = lm.user_id AND ur.sport = v_sport
        WHERE lm.lobby_id = p_lobby_id
        GROUP BY lm.user_id
    ),
    top_n AS (SELECT elo FROM member_elo ORDER BY elo DESC LIMIT 5)
    SELECT COALESCE(ROUND(AVG(elo))::integer, 1000) INTO v_mmr FROM top_n;

    SELECT COALESCE(array_agg(DISTINCT un.network_id), '{}')
    INTO v_net
    FROM public.lobby_member lm
    JOIN public.user_network un ON un.user_id = lm.user_id
    WHERE lm.lobby_id = p_lobby_id;

    SELECT COALESCE(array_agg(DISTINCT un.network_id), '{}')
    INTO v_active_net
    FROM public.lobby_member lm
    JOIN public.user_network un ON un.user_id = lm.user_id
    WHERE lm.lobby_id = p_lobby_id AND NOT un.alumni;

    SELECT COALESCE(array_agg(DISTINCT ui.industry_id), '{}')
    INTO v_ind
    FROM public.lobby_member lm
    JOIN public.user_industry ui ON ui.user_id = lm.user_id
    WHERE lm.lobby_id = p_lobby_id;

    UPDATE public.lobby
       SET mmr                = v_mmr,
           member_count       = v_count,
           network_ids        = v_net,
           active_network_ids = v_active_net,
           industry_ids       = v_ind
     WHERE id = p_lobby_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Triggers
-- ─────────────────────────────────────────────────────────────────────────────

-- lobby_member change → recompute the affected lobby(ies).
CREATE OR REPLACE FUNCTION public.trg_lobby_member_recompute()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        PERFORM public.fn_lobby_recompute_stats(OLD.lobby_id);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.lobby_id IS DISTINCT FROM OLD.lobby_id THEN
            PERFORM public.fn_lobby_recompute_stats(OLD.lobby_id);
        END IF;
        PERFORM public.fn_lobby_recompute_stats(NEW.lobby_id);
        RETURN NEW;
    ELSE
        PERFORM public.fn_lobby_recompute_stats(NEW.lobby_id);
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS lobby_member_recompute_stats ON public.lobby_member;
CREATE TRIGGER lobby_member_recompute_stats
    AFTER INSERT OR UPDATE OR DELETE ON public.lobby_member
    FOR EACH ROW EXECUTE FUNCTION public.trg_lobby_member_recompute();

-- user_rating.elo change → recompute that user's lobbies in the affected sport.
-- Hooks the EFFECT (elo changed), so every future Elo writer keeps the cache correct.
CREATE OR REPLACE FUNCTION public.trg_user_rating_recompute()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r record;
BEGIN
    IF TG_OP = 'UPDATE' AND NOT (OLD.elo IS DISTINCT FROM NEW.elo) THEN
        RETURN NEW; -- elo unchanged
    END IF;
    FOR r IN
        SELECT lm.lobby_id
        FROM public.lobby_member lm
        JOIN public.lobby l ON l.id = lm.lobby_id
        WHERE lm.user_id = NEW.user_id
          AND public.fn_sport_name(l.sport_id) = NEW.sport
    LOOP
        PERFORM public.fn_lobby_recompute_stats(r.lobby_id);
    END LOOP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS user_rating_recompute_lobby ON public.user_rating;
CREATE TRIGGER user_rating_recompute_lobby
    AFTER INSERT OR UPDATE OF elo ON public.user_rating
    FOR EACH ROW EXECUTE FUNCTION public.trg_user_rating_recompute();

-- user_network / user_industry change → recompute all of that user's lobbies.
CREATE OR REPLACE FUNCTION public.trg_user_affiliation_recompute()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    r record;
    v_user uuid := COALESCE(NEW.user_id, OLD.user_id);
BEGIN
    FOR r IN
        SELECT lobby_id FROM public.lobby_member WHERE user_id = v_user
    LOOP
        PERFORM public.fn_lobby_recompute_stats(r.lobby_id);
    END LOOP;
    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS user_network_recompute_lobby ON public.user_network;
CREATE TRIGGER user_network_recompute_lobby
    AFTER INSERT OR UPDATE OR DELETE ON public.user_network
    FOR EACH ROW EXECUTE FUNCTION public.trg_user_affiliation_recompute();

DROP TRIGGER IF EXISTS user_industry_recompute_lobby ON public.user_industry;
CREATE TRIGGER user_industry_recompute_lobby
    AFTER INSERT OR UPDATE OR DELETE ON public.user_industry
    FOR EACH ROW EXECUTE FUNCTION public.trg_user_affiliation_recompute();

-- lobby.playtime change → refresh the cached playtime_keys (lobby-local, no DEFINER).
CREATE OR REPLACE FUNCTION public.trg_lobby_playtime_keys()
    RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    NEW.playtime_keys := public.fn_lobby_playtime_keys(NEW.playtime);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS lobby_playtime_keys_biu ON public.lobby;
CREATE TRIGGER lobby_playtime_keys_biu
    BEFORE INSERT OR UPDATE OF playtime ON public.lobby
    FOR EACH ROW EXECUTE FUNCTION public.trg_lobby_playtime_keys();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. One-time backfill of the cached columns for existing lobbies
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.lobby SET playtime_keys = public.fn_lobby_playtime_keys(playtime);

DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT id FROM public.lobby LOOP
        PERFORM public.fn_lobby_recompute_stats(r.id);
    END LOOP;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Challenger feed RPC (SECURITY INVOKER — reads cached columns only)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.home_challenger_lobby_data(
    p_context_lobby_id uuid,
    p_sport_id bigint,
    p_city integer,
    p_districts character varying[],
    p_mmr_window integer DEFAULT 200,
    p_page_size integer DEFAULT 10,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid,
    name text,
    homeground_name text,
    playtime jsonb,
    details jsonb,
    visibility public.lobby_visibility,
    member_count integer,
    lobby_mmr integer,
    favorability text,
    profile_compat_score numeric
)
    LANGUAGE plpgsql
    SECURITY INVOKER
    SET search_path TO ''
    AS $$
DECLARE
    c_home_adv constant integer := 50;  -- home-court edge applied to the OPPONENT; the away
                                        -- (context) team is the disadvantaged side. An equal-MMR
                                        -- opponent reads as a slight underdog; an even matchup is one
                                        -- vs a ~c_home_adv weaker opponent. (~7% at parity.)
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

    -- Tiered widening so a thin/lopsided pool still returns the nearest opponents.
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
            v_window := 1000000; -- effectively unbounded
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
        (1.0 + (s.compat_raw / 9.0) * 4.0) AS profile_compat_score
    FROM scored s
    ORDER BY (
        c_w_compat * (((1.0 + (s.compat_raw / 9.0) * 4.0) - 1.0) / 4.0)
      + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
    ) DESC
    LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

GRANT EXECUTE ON FUNCTION public.home_challenger_lobby_data(
    uuid, bigint, integer, character varying[], integer, integer, integer
) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Least-privilege: the recompute helper + trigger fns run only via their
--    triggers, never as a client RPC. Revoke the default PUBLIC execute grant
--    so they're not exposed to anon/authenticated. (Triggers still fire — they
--    execute in the owner's context regardless of EXECUTE grants.)
-- ─────────────────────────────────────────────────────────────────────────────
-- Supabase grants EXECUTE directly to anon/authenticated (not only via PUBLIC),
-- so revoke from all three.
REVOKE ALL ON FUNCTION public.fn_lobby_recompute_stats(uuid)       FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trg_lobby_member_recompute()         FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trg_user_rating_recompute()          FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trg_user_affiliation_recompute()     FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trg_lobby_playtime_keys()            FROM PUBLIC, anon, authenticated;
