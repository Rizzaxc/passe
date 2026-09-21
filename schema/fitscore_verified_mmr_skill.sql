-- FitScore skill: prefer verified rating over the self-declared elo_seed
-- =====================================================================
-- Follow-up to schema/fitscore_skill_from_elo_seed.sql, which pointed the
-- skill component at `<sport>_profile.elo_seed`. `elo_seed` is *self-declared*
-- — it's the honest signal only while a player has no record. Once real
-- results exist, `user_rating.elo` (and a lobby's cached `lobby.mmr`) are
-- strictly better evidence, so the skill component now uses them in
-- preference, and treats two ratings within 100 points as a skill match.
--
-- Precedence, in both the user→user and user→lobby branches:
--
--   1. BOTH sides verified  → |Δrating| <= 100 decides it, match or no match.
--   2. otherwise            → fall back to the elo_seed tier comparison
--                             exactly as before.
--
-- Note case 1 is decisive in *both* directions. Two verified sides more than
-- 100 apart do NOT fall through to the seed: if the record says these players
-- are 400 Elo apart, a shared self-declared "casual" must not manufacture a
-- skill match. The seed only speaks where evidence is missing. (Before this
-- change the seed was the only voice, so this is the one behaviour that can
-- now go from "matched" to "not matched" — always on the strength of real
-- results.)
--
-- "Verified" reuses the two thresholds that already exist rather than
-- inventing a third:
--   * a user is verified at games_played >= 10 — `c_provisional` in
--     fn_apply_match_rating (schema/challenge_flow.sql), the point where the
--     Elo engine itself drops off the high-K provisional ladder;
--   * a lobby is verified at rated_match_count >= 5 —
--     `LobbyFeedItem.provisionalMatchThreshold` (lib/core/model/lobby_feed_item.dart),
--     the cutoff the UI already uses to stop showing MMR as "tạm tính".
-- They differ because they measure different things, and each side matching
-- its own established definition matters more than the two agreeing.
--
-- No new factor code: a match here still emits 'skill' and renders as the
-- existing "Trình độ phù hợp" chip, so no client change is needed.
--
-- NOTE ON IMPACT TODAY: every user_rating row in production currently has
-- games_played = 0 and every lobby has rated_match_count = 0, because no
-- scored+refereed challenge match has been played yet. So path 1 cannot fire
-- on live data and no real FitScore changes as of this migration — it arms
-- itself as matches get recorded. The verification below therefore exercises
-- path 1 on synthetic ratings inside a rolled-back transaction.

-- ---------------------------------------------------------------------------
-- 1. A user's rating, but only once it is settled.
--    `format IS NULL` is the canonical row: it is the only one
--    fn_seed_initial_elo and fn_apply_match_rating ever write, and the unique
--    key is (user_id, sport, format) with NULLs distinct.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_user_verified_elo(p_user_id uuid, p_sport_id bigint) RETURNS integer
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT ur.elo
    FROM public.user_rating ur
    WHERE ur.user_id = p_user_id
      AND ur.sport   = public.fn_sport_name(p_sport_id)
      AND ur.format IS NULL
      AND ur.games_played >= 10
$$;

ALTER FUNCTION public.fn_user_verified_elo(uuid, bigint) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.fn_user_verified_elo(uuid, bigint) FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. A lobby's cached MMR, but only once it is out of provisional.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_lobby_verified_mmr(p_lobby_id uuid) RETURNS integer
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT l.mmr
    FROM public.lobby l
    WHERE l.id = p_lobby_id
      AND l.rated_match_count >= 5
$$;

ALTER FUNCTION public.fn_lobby_verified_mmr(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.fn_lobby_verified_mmr(uuid) FROM PUBLIC, anon, authenticated;

-- Both helpers are internal: calculate_profile_compat is SECURITY DEFINER and
-- runs as postgres, so it reaches them without a client-facing grant. Same
-- posture as public.freeplay_user_skill.

-- ---------------------------------------------------------------------------
-- 3. Redefine calculate_profile_compat with the new skill precedence.
--    Everything outside the two skill blocks is unchanged from
--    schema/fitscore_skill_from_elo_seed.sql §4.
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

    -- Verified-MMR path. NULL on either side means "not verified" and the
    -- self-declared elo_seed tier is used instead.
    c_mmr_match_window constant INTEGER := 100;
    user_elo        INTEGER;
    target_elo      INTEGER;
    target_mmr      INTEGER;
    skill_matched   BOOLEAN;

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

        -- Skill (+3). Prefer verified Elo over the self-declared seed: when
        -- BOTH sides have a settled rating we have hard evidence, and two
        -- ratings within c_mmr_match_window count as a match. When both are
        -- verified and further apart than that, it is a decided NON-match —
        -- we deliberately do NOT fall back to the seed there, because a
        -- shared self-declared tier must not override real results showing a
        -- gap. The seed only speaks when the evidence is absent.
        user_elo   := public.fn_user_verified_elo(p_user_id, p_sport_id);
        target_elo := public.fn_user_verified_elo(p_target_id, p_sport_id);

        IF user_elo IS NOT NULL AND target_elo IS NOT NULL THEN
            skill_matched := abs(user_elo - target_elo) <= c_mmr_match_window;
        ELSE
            target_skill_level := public.fn_user_sport_skill_rank(p_target_id, p_sport_id);
            skill_matched := user_skill_level IS NOT NULL
                         AND target_skill_level IS NOT NULL
                         AND user_skill_level = target_skill_level;
        END IF;

        IF skill_matched THEN
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

        -- Skill (+3). Same precedence as the user-to-user branch: a verified
        -- rating on BOTH sides (the caller's settled Elo vs. the lobby's
        -- non-provisional MMR) decides it outright, within/outside
        -- c_mmr_match_window. Only when either side is still provisional do we
        -- fall back to counting members who share the caller's seed tier.
        user_elo   := public.fn_user_verified_elo(p_user_id, p_sport_id);
        target_mmr := public.fn_lobby_verified_mmr(p_target_id);

        IF user_elo IS NOT NULL AND target_mmr IS NOT NULL THEN
            skill_matched := abs(user_elo - target_mmr) <= c_mmr_match_window;
        ELSIF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
            WHERE lm.lobby_id = p_target_id
              AND public.fn_user_sport_skill_rank(lm.user_id, p_sport_id) = user_skill_level;

            skill_matched := lobby_members_with_same_skill * 2 >= total_lobby_members;
        ELSE
            skill_matched := FALSE;
        END IF;

        IF skill_matched THEN
            raw_score := raw_score + 3;
            factors := array_append(factors, 'skill');
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
