-- FitScore (profile_compat_score) redesign
-- =========================================
-- Two changes vs. the previous version:
--
-- 1. Rebaseline the band. The old function rescaled raw points 0..8 onto
--    [1, 5], so a lobby with *no* shared signal scored 1.0/5 — which reads as
--    "poor fit" when it is really just "neutral / we don't know each other yet".
--    The new band is [2.5, 5]: 2.5 is the neutral "ok fit" floor, and shared
--    signals push toward 5. Nothing reads as a bad match anymore.
--
-- 2. Add demographic affinity:
--    - Age group: bump when the user shares an age group with the target /
--      with at least half of a lobby's members.
--    - Gender comfort: bump a FEMALE user when the target user is female, or
--      when a lobby has at least one female member. (Male users are neutral on
--      gender — this exists to surface women-friendly lobbies for women.)
--
-- Raw weights (sum to ~max_raw so a fully-aligned target reaches 5.0):
--   network shared            +3   (user-user)  / +2..+4 (user-lobby)
--   network active (non-alumni)+1
--   industry shared (fallback) +2   (user-user only, when no shared network)
--   skill match                +3
--   age-group match            +1.5
--   gender comfort (F↔F)       +2
--
-- Signature is unchanged, so home_teammate_lobby_data / home_challenger_lobby_data
-- pick this up automatically.

CREATE OR REPLACE FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS numeric
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    raw_score   NUMERIC := 0;
    max_raw     NUMERIC := 10;    -- raw points that map to the top of the band
    base_score  NUMERIC := 2.5;   -- neutral "ok fit" baseline (no shared signal)
    top_score   NUMERIC := 5;     -- best possible fit
    final_score NUMERIC;

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

    -- Is the target another user, or a lobby?
    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    -- Source user attributes
    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    IF user_details->'sport' ? sport_id_text AND user_details->'sport'->sport_id_text ? 'skill' THEN
        user_skill_level := (user_details->'sport'->sport_id_text->>'skill')::INTEGER;
    END IF;
    user_gender := user_details->>'gender';
    user_age    := user_details->>'ageGroup';

    IF is_user THEN
        -- =============================================
        -- USER-TO-USER COMPATIBILITY
        -- =============================================
        SELECT details INTO target_details FROM public."user" WHERE id = p_target_id;

        -- Shared network (+3), and active / non-alumni on both sides (+1)
        SELECT COUNT(*) INTO shared_network_count
        FROM public.user_network un1
                 JOIN public.user_network un2 ON un1.network_id = un2.network_id
        WHERE un1.user_id = p_user_id AND un2.user_id = p_target_id;

        IF shared_network_count > 0 THEN
            raw_score := raw_score + 3;

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
            -- No shared network — fall back to shared industry (+2)
            SELECT COUNT(*) INTO shared_industry_count
            FROM public.user_industry ui1
                     JOIN public.user_industry ui2 ON ui1.industry_id = ui2.industry_id
            WHERE ui1.user_id = p_user_id AND ui2.user_id = p_target_id;

            IF shared_industry_count > 0 THEN
                raw_score := raw_score + 2;
            END IF;
        END IF;

        -- Same skill level for the context sport (+3)
        IF user_skill_level IS NOT NULL AND
           target_details->'sport' ? sport_id_text AND
           target_details->'sport'->sport_id_text ? 'skill' AND
           user_skill_level = (target_details->'sport'->sport_id_text->>'skill')::INTEGER THEN
            raw_score := raw_score + 3;
        END IF;

        -- Same age group (+1.5)
        IF user_age IS NOT NULL AND user_age = (target_details->>'ageGroup') THEN
            raw_score := raw_score + 1.5;
        END IF;

        -- Gender comfort: female user matched with a female target (+2)
        IF user_gender = 'female' AND (target_details->>'gender') = 'female' THEN
            raw_score := raw_score + 2;
        END IF;

    ELSE
        -- =============================================
        -- USER-TO-LOBBY COMPATIBILITY
        -- =============================================
        SELECT COUNT(*) INTO total_lobby_members
        FROM public.lobby_member
        WHERE lobby_id = p_target_id;

        SELECT captain_id INTO host_id
        FROM public.lobby
        WHERE id = p_target_id;

        -- A solo lobby (just the captain) behaves like a user-to-user match
        IF total_lobby_members = 1 AND host_id IS NOT NULL THEN
            RETURN public.calculate_profile_compat_score(p_user_id, host_id, p_sport_id);
        END IF;

        -- Empty / unknown lobby — neutral fit
        IF total_lobby_members = 0 THEN
            RETURN base_score;
        END IF;

        -- Members sharing a network with the user
        SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_shared_network
        FROM public.lobby_member lm
                 JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                 JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
        WHERE lm.lobby_id = p_target_id
          AND un_user.user_id = p_user_id;

        IF lobby_members_with_shared_network >= 3 THEN
            raw_score := raw_score + 4;
        ELSIF lobby_members_with_shared_network >= 1 THEN
            raw_score := raw_score + 2;

            -- At least one of those shared ties is active on both sides (+1)
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

        -- At least half the members share the user's skill level (+3)
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
            END IF;
        END IF;

        -- At least half the members share the user's age group (+1.5)
        IF user_age IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_same_age
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND (u.details->>'ageGroup') = user_age;

            IF lobby_members_same_age * 2 >= total_lobby_members THEN
                raw_score := raw_score + 1.5;
            END IF;
        END IF;

        -- Gender comfort: a female user matched with a lobby that already has
        -- at least one female member (+2)
        IF user_gender = 'female' THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_female_members
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND (u.details->>'gender') = 'female';

            IF lobby_female_members >= 1 THEN
                raw_score := raw_score + 2;
            END IF;
        END IF;
    END IF;

    -- Map raw points [0, max_raw] onto the band [base_score, top_score].
    final_score := base_score + (LEAST(raw_score, max_raw) / max_raw) * (top_score - base_score);
    final_score := GREATEST(base_score, LEAST(top_score, final_score));

    RETURN ROUND(final_score, 1);
END;
$$;
