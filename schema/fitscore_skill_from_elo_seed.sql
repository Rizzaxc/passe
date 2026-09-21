-- FitScore: read skill from <sport>_profile.elo_seed, not user.details->'sport'
-- ============================================================================
-- `calculate_profile_compat` (and through it the thin
-- `calculate_profile_compat_score` wrapper) read the caller's / target's skill
-- level from
--
--     user.details -> 'sport' -> <sport_id> ->> 'skill'   ::INTEGER
--
-- That path has **no writer**. Nothing in the Flutter client ever populates
-- `details.sport`, the `user_details_schema` CHECK doesn't even declare a
-- `sport` property, and `select ... from public."user" where details ? 'sport'`
-- returns zero rows in production. Consequences:
--
--   * the skill component was permanently inert — worth +3 raw (user→user) and
--     +3 raw (user→lobby) out of a max_raw of 10, i.e. every real FitScore was
--     depressed by up to 0.75 on the final [2.5, 5] band;
--   * the 'skill' match factor could never be emitted, so the feed card's
--     "Trình độ phù hợp" chip (lib/discover_tab/lobby_feed_card.dart) was dead
--     code on real data.
--
-- Real per-sport skill lives in `<sport>_profile.elo_seed`
-- (beginner|casual|fair|good|advanced, see schema/elo_seed_five_tiers.sql),
-- which the profile editor actually writes. This migration points the compat
-- function there and drops the json path entirely.
--
-- The seed is mapped to its ordinal (beginner=0 … advanced=4) so the existing
-- integer equality stays exactly as it was: skill matches on an *exact* tier,
-- not on adjacency. Weights, band and factor codes are unchanged — the only
-- behavioural difference is that the skill component can now actually fire.
--
-- `calculate_profile_compat_score` is already a one-line SQL wrapper over
-- `calculate_profile_compat` (schema/fitscore_factors.sql §2), so it picks this
-- up with no redefinition. Likewise home_teammate_lobby_data /
-- home_challenger_lobby_data — signatures are untouched.

-- ---------------------------------------------------------------------------
-- 1. elo_seed → ordinal rank.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_elo_seed_rank(p_seed text) RETURNS integer
    LANGUAGE sql
    IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT CASE p_seed
        WHEN 'beginner' THEN 0
        WHEN 'casual'   THEN 1
        WHEN 'fair'     THEN 2
        WHEN 'good'     THEN 3
        WHEN 'advanced' THEN 4
    END
$$;

ALTER FUNCTION public.fn_elo_seed_rank(text) OWNER TO postgres;
GRANT ALL ON FUNCTION public.fn_elo_seed_rank(text) TO anon;
GRANT ALL ON FUNCTION public.fn_elo_seed_rank(text) TO authenticated;
GRANT ALL ON FUNCTION public.fn_elo_seed_rank(text) TO service_role;

-- ---------------------------------------------------------------------------
-- 2. (user, sport) → skill rank, dispatching over the five profile tables.
--    Mirrors public.freeplay_user_skill, but returns the ordinal and is
--    callable by ordinary clients (freeplay_user_skill is REVOKEd from
--    anon/authenticated and only usable from SECURITY DEFINER callers, while
--    calculate_profile_compat runs as the invoker).
--    NULL when the user has no profile row for that sport, or hasn't declared
--    a seed — the caller treats NULL as "no signal", same as before.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_user_sport_skill_rank(p_user_id uuid, p_sport_id bigint) RETURNS integer
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT public.fn_elo_seed_rank(
        CASE p_sport_id
            WHEN 1 THEN (SELECT elo_seed FROM public.soccer_profile     WHERE user_id = p_user_id)
            WHEN 2 THEN (SELECT elo_seed FROM public.basketball_profile WHERE user_id = p_user_id)
            WHEN 3 THEN (SELECT elo_seed FROM public.badminton_profile  WHERE user_id = p_user_id)
            WHEN 4 THEN (SELECT elo_seed FROM public.tennis_profile     WHERE user_id = p_user_id)
            WHEN 5 THEN (SELECT elo_seed FROM public.pickleball_profile WHERE user_id = p_user_id)
        END
    )
$$;

ALTER FUNCTION public.fn_user_sport_skill_rank(uuid, bigint) OWNER TO postgres;
GRANT ALL ON FUNCTION public.fn_user_sport_skill_rank(uuid, bigint) TO anon;
GRANT ALL ON FUNCTION public.fn_user_sport_skill_rank(uuid, bigint) TO authenticated;
GRANT ALL ON FUNCTION public.fn_user_sport_skill_rank(uuid, bigint) TO service_role;

-- ---------------------------------------------------------------------------
-- 3. Redefine calculate_profile_compat against the real skill source.
--    Identical to schema/fitscore_factors.sql §1 except for the three skill
--    reads (and the now-unused sport_id_text local, dropped).
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

    user_skill_level   INTEGER;
    target_skill_level INTEGER;
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
    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    -- Skill comes from <sport>_profile.elo_seed, mapped to its ordinal.
    user_skill_level := public.fn_user_sport_skill_rank(p_user_id, p_sport_id);
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

        -- Same declared skill tier for the context sport (+3)
        target_skill_level := public.fn_user_sport_skill_rank(p_target_id, p_sport_id);

        IF user_skill_level IS NOT NULL
           AND target_skill_level IS NOT NULL
           AND user_skill_level = target_skill_level THEN
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

        -- At least half the members share the user's skill tier (+3)
        IF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
            WHERE lm.lobby_id = p_target_id
              AND public.fn_user_sport_skill_rank(lm.user_id, p_sport_id) = user_skill_level;

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

ALTER FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) OWNER TO postgres;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO anon;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO service_role;

-- ---------------------------------------------------------------------------
-- 4. Make calculate_profile_compat SECURITY DEFINER.
--
--    Pointing the skill read at elo_seed is necessary but NOT sufficient: the
--    function ran as the invoker, and `lobby_member` RLS only exposes rows for
--    lobbies you are already a member of. So inside home_teammate_lobby_data
--    (also SECURITY INVOKER) the user→lobby branch saw
--    total_lobby_members = 0 for every candidate lobby — which short-circuits
--    to the neutral base_score with an empty factor array. Every lobby on the
--    teammate feed scored exactly 2.5 with no chips, regardless of network,
--    skill, age or gender. (The user→user branch and
--    get_lobby_befriend_invite_preview were unaffected: that RPC is already
--    SECURITY DEFINER, so its nested compat call bypassed RLS.)
--
--    Running as definer is safe here because the function returns only a
--    number and a set of factor *codes* — never a member id, name or profile.
--    The candidate lobbies are already publicly listed by the feed
--    (visibility <> 'private').
--
--    The one thing definer adds is the ability to probe *someone else's*
--    compatibility by passing an arbitrary p_user_id, so the guard below pins
--    it to the caller. Both existing callers already pass auth.uid()
--    (home_teammate_lobby_data directly, get_lobby_befriend_invite_preview via
--    its v_uid), so nothing legitimate changes.
--
--    The guard keys off `request.jwt.claims` being set rather than off
--    auth.uid() being non-null: the anon role reaches PostgREST with a JWT
--    whose role is 'anon' and no `sub`, so auth.uid() is NULL there — an
--    `auth.uid() IS NOT NULL` guard would let any guest probe any user. No
--    request.jwt.claims means no PostgREST request at all (psql, pg_cron, a
--    nested call from another definer function's own session), which is
--    trusted and left unrestricted.
--
--    NOTE the `nullif(..., '')`: an unset `request.jwt.claims` reads back as
--    the EMPTY STRING, not NULL, on any backend where the GUC has ever been
--    materialised (which, behind the connection pooler, varies from one
--    session to the next). A bare `IS NOT NULL` test therefore treats a
--    trusted server-side session as an untrusted request *sometimes*, and
--    every such call silently returns the neutral floor. Empty string and
--    NULL must both count as "no request context".
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_profile_compat(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS jsonb
    LANGUAGE plpgsql
    SECURITY DEFINER
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

    user_skill_level   INTEGER;
    target_skill_level INTEGER;
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
    -- Definer guard: inside a PostgREST request, a client may only score itself.
    IF nullif(current_setting('request.jwt.claims', true), '') IS NOT NULL
       AND p_user_id IS DISTINCT FROM auth.uid() THEN
        RETURN jsonb_build_object('score', base_score, 'factors', factors);
    END IF;

    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    -- Skill comes from <sport>_profile.elo_seed, mapped to its ordinal.
    user_skill_level := public.fn_user_sport_skill_rank(p_user_id, p_sport_id);
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

        -- Same declared skill tier for the context sport (+3)
        target_skill_level := public.fn_user_sport_skill_rank(p_target_id, p_sport_id);

        IF user_skill_level IS NOT NULL
           AND target_skill_level IS NOT NULL
           AND user_skill_level = target_skill_level THEN
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

        -- At least half the members share the user's skill tier (+3)
        IF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
            WHERE lm.lobby_id = p_target_id
              AND public.fn_user_sport_skill_rank(lm.user_id, p_sport_id) = user_skill_level;

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

ALTER FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) OWNER TO postgres;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO anon;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO authenticated;
GRANT ALL ON FUNCTION public.calculate_profile_compat(uuid, uuid, bigint) TO service_role;
