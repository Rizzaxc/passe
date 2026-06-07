--
-- PostgreSQL database dump
--

\restrict JOwmkov8MW2zBOd27rqiadHRXT4iMCnKrdeslTpbfc4pHXU3J8FAay1KTX2ZRp2

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.9 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: country; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.country AS ENUM (
    'VN'
);


--
-- Name: gender; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.gender AS ENUM (
    'M',
    'F'
);


--
-- Name: health_platform; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.health_platform AS ENUM (
    'apple_health',
    'google_fit',
    'health_connect'
);


--
-- Name: lobby_befriend_interaction; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.lobby_befriend_interaction AS ENUM (
    'request',
    'invite',
    'pair'
);


--
-- Name: lobby_befriend_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.lobby_befriend_status AS ENUM (
    'pending',
    'accepted',
    'declined',
    'cancelled'
);


--
-- Name: lobby_feed_item_kind; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.lobby_feed_item_kind AS ENUM (
    'update',
    'personal',
    'system',
    'poll',
    'photo'
);


--
-- Name: lobby_match_result; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.lobby_match_result AS ENUM (
    'win',
    'loss',
    'practice'
);


--
-- Name: lobby_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.lobby_visibility AS ENUM (
    'private',
    'discoverable',
    'public'
);


--
-- Name: professional_booking_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.professional_booking_status AS ENUM (
    'requested',
    'rejected',
    'confirmed',
    'cancelled_by_client',
    'cancelled_by_pro',
    'completed'
);


--
-- Name: professional_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.professional_role AS ENUM (
    'coach',
    'referee'
);


--
-- Name: calculate_profile_compat_score(uuid, uuid, bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_profile_compat_score(p_user_id uuid, p_target_id uuid, p_sport_id bigint) RETURNS numeric
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    score NUMERIC := 0;
    max_raw_score NUMERIC := 8; -- Maximum possible raw score before rescaling
    max_final_score NUMERIC := 5; -- Desired maximum score after rescaling
    min_score NUMERIC := 1;
    is_user BOOLEAN;
    host_id UUID;
    user_details JSONB;
    target_details JSONB;
    sport_id_text TEXT;
    shared_network_count INTEGER := 0;
    active_shared_network_count INTEGER := 0;
    shared_industry_count INTEGER := 0;
    lobby_members_with_shared_network INTEGER := 0;
    total_lobby_members INTEGER := 0;
    lobby_members_with_same_skill INTEGER := 0;
    user_skill_level INTEGER;
    has_active_shared_member BOOLEAN := FALSE;
BEGIN
    -- Convert sport ID to text for accessing JSON
    sport_id_text := p_sport_id::TEXT;

    -- Determine if target is a user or a lobby
    SELECT EXISTS(SELECT 1 FROM public."user" WHERE id = p_target_id) INTO is_user;

    -- Get user details
    SELECT details INTO user_details FROM public."user" WHERE id = p_user_id;

    -- Extract user's skill level for the context sport - adjusted to match schema
    IF user_details->'sport' ? sport_id_text AND user_details->'sport'->sport_id_text ? 'skill' THEN
        user_skill_level := (user_details->'sport'->sport_id_text->>'skill')::INTEGER;
    ELSE
        user_skill_level := NULL;
    END IF;

    IF is_user THEN
        -- =============================================
        -- USER-TO-USER COMPATIBILITY CALCULATION
        -- =============================================

        -- Get target user details
        SELECT details INTO target_details FROM public."user" WHERE id = p_target_id;

        -- Check if they share at least one network (+3)
        SELECT COUNT(*) INTO shared_network_count
        FROM public.user_network un1
                 JOIN public.user_network un2 ON un1.network_id = un2.network_id
        WHERE un1.user_id = p_user_id AND un2.user_id = p_target_id;

        IF shared_network_count > 0 THEN
            score := score + 3;

            -- Check if they're both currently members of a shared network (not alumni) (+2)
            SELECT COUNT(*) INTO active_shared_network_count
            FROM public.user_network un1
                     JOIN public.user_network un2 ON un1.network_id = un2.network_id
            WHERE un1.user_id = p_user_id
              AND un2.user_id = p_target_id
              AND NOT un1.alumni
              AND NOT un2.alumni;

            IF active_shared_network_count > 0 THEN
                score := score + 2;
            END IF;
        ELSE
            -- If they don't share a network, check if they share an industry (+2)
            SELECT COUNT(*) INTO shared_industry_count
            FROM public.user_industry ui1
                     JOIN public.user_industry ui2 ON ui1.industry_id = ui2.industry_id
            WHERE ui1.user_id = p_user_id AND ui2.user_id = p_target_id;

            IF shared_industry_count > 0 THEN
                score := score + 2;
            END IF;
        END IF;

        -- Check if they are at the same skill level for the context sport (+2)
        -- Updated to match the JSON schema structure
        IF user_skill_level IS NOT NULL AND
           target_details->'sport' ? sport_id_text AND
           target_details->'sport'->sport_id_text ? 'skill' AND
           user_skill_level = (target_details->'sport'->sport_id_text->>'skill')::INTEGER THEN
            score := score + 2;
        END IF;

    ELSE
        -- =============================================
        -- USER-TO-LOBBY COMPATIBILITY CALCULATION
        -- =============================================

        -- Get lobby details and count members
        SELECT COUNT(*) INTO total_lobby_members
        FROM public.lobby_member
        WHERE lobby_id = p_target_id;

        -- Get the lobby host/captain ID
        SELECT captain_id INTO host_id
        FROM public.lobby
        WHERE id = p_target_id;

        -- If there's only one member (the host), treat as user-to-user interaction
        IF total_lobby_members = 1 AND host_id IS NOT NULL THEN
            -- Recursive call with the host's ID
            RETURN public.calculate_profile_compat_score(p_user_id, host_id, p_sport_id);
        END IF;

        -- Count lobby members who share a network with the user
        SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_shared_network
        FROM public.lobby_member lm
                 JOIN public.user_network un_member ON lm.user_id = un_member.user_id
                 JOIN public.user_network un_user ON un_member.network_id = un_user.network_id
        WHERE lm.lobby_id = p_target_id
          AND un_user.user_id = p_user_id;

        -- Check if at least one lobby member shares a network with the user
        -- and is not an alumni (+1 for shared network, +1 for active member)
        IF lobby_members_with_shared_network >= 1 THEN
            -- Check if they have at least 3 shared members (+4)
            IF lobby_members_with_shared_network >= 3 THEN
                score := score + 4;
            ELSE
                -- If less than 3 shared members, give +1 for at least one shared network
                score := score + 1;

                -- Check if any of the shared members are active (both user and member are not alumni)
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
                    score := score + 1;
                END IF;
            END IF;
        END IF;

        -- Count lobby members with the same skill level as the user
        -- Updated to match the JSON schema structure
        IF user_skill_level IS NOT NULL THEN
            SELECT COUNT(DISTINCT lm.user_id) INTO lobby_members_with_same_skill
            FROM public.lobby_member lm
                     JOIN public."user" u ON lm.user_id = u.id
            WHERE lm.lobby_id = p_target_id
              AND u.details->'sport' ? sport_id_text
              AND u.details->'sport'->sport_id_text ? 'skill'
              AND (u.details->'sport'->sport_id_text->>'skill')::INTEGER = user_skill_level;

            -- If at least half of the lobby members are at the same skill level as the user (+4)
            IF lobby_members_with_same_skill >= (total_lobby_members / 2) THEN
                score := score + 4;
            END IF;
        END IF;
    END IF;

    -- Properly rescale score to range from min_score to max_final_score
    -- Formula: rescaled = min + (score/max_raw_score) * (max_final_score - min_score)
    score := min_score + (score / max_raw_score) * (max_final_score - min_score);

    -- Ensure we don't go below minimum
    score := GREATEST(min_score, score);

    RETURN score;
END;
$$;


--
-- Name: calculate_timeslot_compat_score(jsonb, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_timeslot_compat_score(source jsonb, target jsonb) RETURNS integer
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    total_score INTEGER := 0;
    source_day TEXT;
    source_chunks JSONB;
    target_chunks JSONB;
    chunk TEXT;
BEGIN
    FOR source_day, source_chunks IN SELECT * FROM jsonb_each(source)
        LOOP
            IF target ? source_day THEN
                -- Day match: 2 points
                total_score := total_score + 2;

                -- Check for matching chunks
                target_chunks := target->source_day;

                IF jsonb_typeof(source_chunks) = 'array' AND jsonb_typeof(target_chunks) = 'array' THEN
                    FOR chunk IN SELECT jsonb_array_elements_text(source_chunks)
                        LOOP
                            IF target_chunks @> jsonb_build_array(chunk) THEN
                                -- Chunk match: 2 additional points
                                total_score := total_score + 2;
                            END IF;
                        END LOOP;
                END IF;
            END IF;
        END LOOP;

    RETURN total_score;
END;
$$;


--
-- Name: create_lobby_with_location(text, integer, text, jsonb, jsonb, uuid, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text DEFAULT 'discoverable'::text, p_playtime jsonb DEFAULT NULL::jsonb, p_details jsonb DEFAULT NULL::jsonb, p_home_ground_id uuid DEFAULT NULL::uuid, p_location_name text DEFAULT NULL::text, p_street_number text DEFAULT NULL::text, p_street_name text DEFAULT NULL::text, p_district text DEFAULT NULL::text, p_city text DEFAULT NULL::text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id  uuid;
    v_loc_id   uuid;
    v_lobby_id uuid;
    v_result   jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_home_ground_id IS NOT NULL THEN
        v_loc_id := p_home_ground_id;
    ELSIF p_location_name IS NOT NULL OR p_street_name IS NOT NULL OR p_city IS NOT NULL THEN
        INSERT INTO public.location (name, street_number, street_name, district, city)
        VALUES (
            NULLIF(TRIM(COALESCE(p_location_name, '')), ''),
            NULLIF(p_street_number, '')::integer,
            NULLIF(p_street_name,   ''),
            NULLIF(p_district,      ''),
            NULLIF(p_city,          '')
        )
        RETURNING id INTO v_loc_id;
    END IF;

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, home_ground, captain_id)
    VALUES (
        p_name,
        p_sport_id,
        p_visibility::public.lobby_visibility,
        p_playtime,
        p_details,
        v_loc_id,
        v_user_id
    )
    RETURNING id INTO v_lobby_id;

    -- Captain → lobby_member is handled by the lobby_add_captain_as_member
    -- AFTER INSERT trigger.

    SELECT row_to_json(l)::jsonb
        INTO v_result
        FROM public.lobby l
        WHERE l.id = v_lobby_id;

    RETURN v_result;
END;
$$;


--
-- Name: fn_seed_initial_elo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_seed_initial_elo() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_sport     text;
  v_elo       int;
begin
  -- Only act on first-time elo_seed set (null → value)
  if NEW.elo_seed is null then
    return NEW;
  end if;
  if OLD is not null and OLD.elo_seed is not null then
    return NEW;  -- already seeded, don't touch Elo
  end if;

  -- Derive sport from table name: 'soccer_profile' → 'soccer'
  v_sport := replace(TG_TABLE_NAME, '_profile', '');

  -- Map seed to starting Elo
  v_elo := case NEW.elo_seed
    when 'beginner' then  700
    when 'casual'   then 1000
    when 'tryhard'  then 1300
    else                 1000
  end;

  -- Insert only if no rating exists yet for this user+sport
  if not exists (
    select 1 from public.user_rating
    where user_id = NEW.user_id
      and sport   = v_sport
  ) then
    insert into public.user_rating (user_id, sport, elo, games_played)
    values (NEW.user_id, v_sport, v_elo, 0);
  end if;

  return NEW;
end;
$$;


--
-- Name: get_my_lobby_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_my_lobby_ids() RETURNS SETOF uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT lobby_id FROM public.lobby_member WHERE user_id = auth.uid();
$$;


--
-- Name: get_popular_networks(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_popular_networks(limit_count integer DEFAULT 5) RETURNS TABLE(id bigint, name text, category text)
    LANGUAGE sql
    SET search_path TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category
FROM public.network n
         LEFT JOIN public.user_network un ON n.id = un.network_id
GROUP BY n.id, n.name, n.category
ORDER BY COUNT(un.user_id) DESC, n.name
LIMIT limit_count;
$$;


--
-- Name: home_teammate_lobby_data(bigint, jsonb, integer, character varying[], integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name character varying, homeground_name character varying, playtime jsonb, details jsonb, visibility public.lobby_visibility, timeslot_compat_score integer, profile_compat_score numeric)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            l.id,
            l.name,
            loc.name AS homeground_name,
            l.playtime,
            l.details,
            l.visibility,
            ts_score AS timeslot_compat_score,
            profile_score AS profile_compat_score
        FROM
            public.lobby l
                JOIN
            public.location loc ON l.home_ground = loc.id
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(p_timeslots, l.playtime) AS ts_score
                ) ts
                CROSS JOIN LATERAL (
                SELECT public.calculate_profile_compat_score(auth.uid(), l.id, l.sport_id) AS profile_score
                ) ps
        WHERE
            l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND loc.city_cluster = p_city
          AND loc.district = ANY(p_districts)
          AND ts.ts_score >= 4
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


--
-- Name: immutable_unaccent(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.immutable_unaccent(text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $_$
SELECT extensions.unaccent($1)
$_$;


--
-- Name: lobby_add_captain_as_member(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_add_captain_as_member() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    INSERT INTO public.lobby_member (user_id, lobby_id)
    VALUES (NEW.captain_id, NEW.id)
    ON CONFLICT (user_id, lobby_id) DO NOTHING;
    RETURN NEW;
END;
$$;


--
-- Name: lobby_before_delete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_before_delete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_other_members int;
BEGIN
    SELECT COUNT(*)
        INTO v_other_members
        FROM public.lobby_member
        WHERE lobby_id = OLD.id
          AND user_id <> OLD.captain_id;

    IF v_other_members > 0 THEN
        RAISE EXCEPTION
            'Cannot delete lobby % while % other member(s) remain — they must leave first',
            OLD.id, v_other_members;
    END IF;

    -- Whitelist the captain-leave check for the cascade that's about
    -- to run on lobby_member. `true` makes the setting tx-local.
    PERFORM set_config('app.lobby_being_deleted', OLD.id::text, true);

    RETURN OLD;
END;
$$;


--
-- Name: lobby_befriend_accepted_trigger_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_befriend_accepted_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    new_lobby_id       uuid;
    initiator_username text;
    target_username    text;
    lobby_name         text;
    sport_id           bigint;
BEGIN
    IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN

        -- 'request' / 'invite' add the relevant user to an existing lobby.
        IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
            INSERT INTO public.lobby_member (user_id, lobby_id)
            VALUES (NEW.initiator_user_id, NEW.target_lobby_id)
            ON CONFLICT DO NOTHING;

        ELSIF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL THEN
            INSERT INTO public.lobby_member (user_id, lobby_id)
            VALUES (NEW.target_user_id, NEW.target_lobby_id)
            ON CONFLICT DO NOTHING;

        -- 'pair' creates a brand-new lobby. The captain (initiator) is
        -- joined automatically by lobby_add_captain_as_member; we only
        -- need to add the OTHER user.
        ELSIF NEW.interaction_type = 'pair' AND NEW.target_user_id IS NOT NULL THEN
            IF NEW.details ? 'sport_id' THEN
                sport_id := (NEW.details ->> 'sport_id')::bigint;

                SELECT username INTO initiator_username
                    FROM public."user" WHERE id = NEW.initiator_user_id;
                SELECT username INTO target_username
                    FROM public."user" WHERE id = NEW.target_user_id;
                lobby_name := initiator_username || ' & ' || target_username;

                INSERT INTO public.lobby (captain_id, name, sport_id)
                VALUES (NEW.initiator_user_id, lobby_name, sport_id)
                RETURNING id INTO new_lobby_id;

                INSERT INTO public.lobby_member (user_id, lobby_id)
                VALUES (NEW.target_user_id, new_lobby_id)
                ON CONFLICT DO NOTHING;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: lobby_befriend_record_before_insert_trigger_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_befriend_record_before_insert_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    existing_record            lobby_befriend_record%ROWTYPE;
    lobby_member_exists        BOOLEAN := FALSE;
    target_lobby_member_exists BOOLEAN := FALSE;
BEGIN
    -- Requests: Check if initiator is a member of target lobby
    IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
        SELECT EXISTS(SELECT 1
                      FROM lobby_member lm
                      WHERE lm.lobby_id = NEW.target_lobby_id
                        AND lm.user_id = NEW.initiator_user_id)
        INTO lobby_member_exists;

        IF lobby_member_exists THEN
            RAISE EXCEPTION 'Cannot create request: user is already a member of the target lobby';
        END IF;
    END IF;

    -- Invites: Check if target user is a member of target lobby
    IF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL THEN
        SELECT EXISTS(SELECT 1
                      FROM lobby_member lm
                      WHERE lm.lobby_id = NEW.target_lobby_id AND lm.user_id = NEW.target_user_id)
        INTO target_lobby_member_exists;

        IF target_lobby_member_exists THEN
            RAISE EXCEPTION 'Cannot create invite: target user is already a member of the lobby';
        END IF;
    END IF;

    -- Check for existing identical record in pending or declined state
    SELECT *
    INTO existing_record
    FROM lobby_befriend_record
    WHERE initiator_user_id = NEW.initiator_user_id
      AND (
        (target_user_id = NEW.target_user_id AND NEW.target_user_id IS NOT NULL) OR
        (target_lobby_id = NEW.target_lobby_id AND NEW.target_lobby_id IS NOT NULL)
        )
      AND interaction_type = NEW.interaction_type
      AND status IN ('pending', 'declined');

    IF FOUND THEN
        RAISE EXCEPTION 'Cannot create record: identical % already exists in % state',
            NEW.interaction_type, existing_record.status;
    END IF;

    -- Check for reciprocal invite/request to auto-accept
    IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
        -- Look for pending invite from anyone to this user for this specific lobby
        SELECT *
        INTO existing_record
        FROM lobby_befriend_record lbr
        WHERE lbr.target_user_id = NEW.initiator_user_id
          AND lbr.target_lobby_id = NEW.target_lobby_id
          AND lbr.interaction_type = 'invite'
          AND lbr.status = 'pending';

        IF FOUND THEN
            -- Update existing invite to accepted instead of creating new record
            UPDATE lobby_befriend_record
            SET status     = 'accepted',
                updated_at = NOW()
            WHERE id = existing_record.id;

            -- Return NULL to cancel the insert
            RETURN NULL;
        END IF;
    END IF;

    IF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL AND NEW.target_lobby_id IS NOT NULL THEN
        -- Look for pending request from target user to this specific lobby
        SELECT *
        INTO existing_record
        FROM lobby_befriend_record lbr
        WHERE lbr.initiator_user_id = NEW.target_user_id
          AND lbr.target_lobby_id = NEW.target_lobby_id
          AND lbr.interaction_type = 'request'
          AND lbr.status = 'pending';

        IF FOUND THEN
            -- Update existing request to accepted instead of creating new record
            UPDATE lobby_befriend_record
            SET status     = 'accepted',
                updated_at = NOW()
            WHERE id = existing_record.id;

            -- Return NULL to cancel the insert
            RETURN NULL;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: lobby_feed_data(uuid, integer, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_feed_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_before timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(id uuid, author_id uuid, author_username character varying, kind public.lobby_feed_item_kind, payload jsonb, created_at timestamp with time zone, poll_tallies jsonb)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT fi.id,
               fi.author_id,
               u.username                             AS author_username,
               fi.kind,
               fi.payload,
               fi.created_at,
               -- Poll tallies: {option_index: count, …}. Null for non-polls.
               CASE WHEN fi.kind = 'poll' THEN
                   (SELECT jsonb_object_agg(option_index::text, c)
                    FROM (
                        SELECT option_index, COUNT(*) AS c
                        FROM public.lobby_feed_poll_vote v
                        WHERE v.feed_item_id = fi.id
                        GROUP BY option_index
                    ) t)
               END                                    AS poll_tallies
        FROM public.lobby_feed_item fi
                 LEFT JOIN public."user" u ON u.id = fi.author_id
        WHERE fi.lobby_id = p_lobby_id
          AND (p_before IS NULL OR fi.created_at < p_before)
        ORDER BY fi.created_at DESC
        LIMIT p_page_size;
END;
$$;


--
-- Name: lobby_match_history_data(uuid, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, activity_id uuid, opponent_lobby_id uuid, opponent_name text, opponent_tag text, result public.lobby_match_result, sets jsonb, mvp_username character varying, note text, venue_label text, played_at timestamp with time zone, duration_label text, member_usernames text[], referee_booking_id uuid, referee_name text)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT m.id,
               m.activity_id,
               m.opponent_lobby_id,
               ol.name                                AS opponent_name,
               m.opponent_tag,
               m.result,
               m.sets,
               u.username                             AS mvp_username,
               m.note,
               m.venue_label,
               m.played_at,
               m.duration_label,
               ARRAY(
                   SELECT mu.username
                   FROM public.lobby_member lm
                            JOIN public."user" mu ON mu.id = lm.user_id
                   WHERE lm.lobby_id = m.lobby_id
               )                                      AS member_usernames,
               m.referee_booking_id,
               ref.display_name                       AS referee_name
        FROM public.lobby_match m
                 LEFT JOIN public.lobby ol ON ol.id = m.opponent_lobby_id
                 LEFT JOIN public."user" u ON u.id = m.mvp_user_id
                 LEFT JOIN public.professional_booking rb
                     ON rb.id = m.referee_booking_id
                 LEFT JOIN public.professional ref
                     ON ref.id = rb.professional_id
        WHERE m.lobby_id = p_lobby_id
        ORDER BY m.played_at DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;


--
-- Name: lobby_match_referee_role_check(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_match_referee_role_check() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    booked_role public.professional_role;
BEGIN
    IF NEW.referee_booking_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT p.professional_role
        INTO booked_role
        FROM public.professional_booking pb
                 JOIN public.professional p ON p.id = pb.professional_id
        WHERE pb.id = NEW.referee_booking_id;

    IF booked_role IS DISTINCT FROM 'referee' THEN
        RAISE EXCEPTION
            'lobby_match.referee_booking_id must reference a booking whose professional is a referee (got: %)',
            booked_role;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: lobby_member_prevent_captain_leave(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lobby_member_prevent_captain_leave() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
    v_captain_id     uuid;
    v_being_deleted  text;
BEGIN
    SELECT captain_id
        INTO v_captain_id
        FROM public.lobby
        WHERE id = OLD.lobby_id;

    -- Lobby is already gone (e.g. a different cascade path) — let the
    -- delete through.
    IF v_captain_id IS NULL THEN
        RETURN OLD;
    END IF;

    -- Non-captain leaving: always OK.
    IF v_captain_id <> OLD.user_id THEN
        RETURN OLD;
    END IF;

    -- Captain leaving: only allowed when the lobby itself is being
    -- deleted in this same transaction (signal set by lobby_before_delete).
    v_being_deleted := current_setting('app.lobby_being_deleted', true);
    IF v_being_deleted = OLD.lobby_id::text THEN
        RETURN OLD;
    END IF;

    RAISE EXCEPTION
        'Captain cannot leave lobby % — transfer captaincy first', OLD.lobby_id;
END;
$$;


--
-- Name: nanoid(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nanoid(size integer DEFAULT 10, alphabet text DEFAULT '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'::text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
    SELECT extensions.nanoid(size, alphabet);
$$;


--
-- Name: new_user_created_trigger_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.new_user_created_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    insert into public.user(id, username)
    values (new.id,
            substring(split_part(new.email, '@', 1), 1, 16));
    return new;
end;
$$;


--
-- Name: professional_booking_review_updated_trigger_fn(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.professional_booking_review_updated_trigger_fn() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.professional_booking_review
                WHERE professional_id = NEW.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.professional_booking_review
                WHERE professional_id = NEW.professional_id
            )
        WHERE id = NEW.professional_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.professional_booking_review
                WHERE professional_id = OLD.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.professional_booking_review
                WHERE professional_id = OLD.professional_id
            )
        WHERE id = OLD.professional_id;
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search_locations(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_locations(search_term text) RETURNS TABLE(id uuid, name text, full_address text, street_number integer, street_name text, district text, city text)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    IF char_length(search_term) < 8 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.full_address,
        l.street_number,
        l.street_name,
        l.district,
        l.city
    FROM public.location l
    WHERE
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(l.name)) > 0.3
        OR extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(l.full_address)) > 0.3
    ORDER BY
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.full_address))
        ) DESC
    LIMIT 10;
END;
$$;


--
-- Name: search_networks_unaccent(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_networks_unaccent(search_term text, result_limit integer DEFAULT 20) RETURNS TABLE(id bigint, name text, category text, city text)
    LANGUAGE sql
    SET search_path TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category,
    scc.name AS city
FROM public.network n
JOIN public.supported_city_cluster scc on n.city = scc.id
WHERE
    -- Try both accented and unaccented matching for Vietnamese text
    (extensions.unaccent(LOWER(n.name)) ILIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
        OR LOWER(n.name) ILIKE '%' || LOWER(search_term) || '%')
ORDER BY
    -- Prioritize exact matches, then prefix matches, then contains
    CASE
        WHEN LOWER(n.name) = LOWER(search_term) THEN 1
        WHEN LOWER(n.name) LIKE LOWER(search_term) || '%' THEN 2
        WHEN extensions.unaccent(LOWER(n.name)) LIKE extensions.unaccent(LOWER(search_term)) || '%' THEN 3
        ELSE 4
        END,
    n.name
LIMIT result_limit;
$$;


--
-- Name: search_networks_unaccent(text, integer, bigint[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.search_networks_unaccent(search_term text, result_limit integer DEFAULT 20, filter_cities bigint[] DEFAULT NULL::bigint[], filter_categories text[] DEFAULT NULL::text[]) RETURNS TABLE(id bigint, name text, category text, city bigint)
    LANGUAGE sql
    SET search_path TO ''
    AS $$
SELECT
    n.id,
    n.name,
    n.category, n.city
FROM public.network n
WHERE
    char_length(search_term) >= 3
    AND (
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(n.name))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(n.name)) > 0.3
    )
    AND (coalesce(cardinality(filter_cities), 0) = 0 OR n.city = ANY(filter_cities))
    AND (coalesce(cardinality(filter_categories), 0) = 0 OR n.category = ANY(filter_categories))
ORDER BY
    greatest(
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(n.name))),
        extensions.word_similarity(LOWER(search_term), LOWER(n.name))
    ) DESC,
    n.name
LIMIT result_limit;
$$;


--
-- Name: vietnamese; Type: TEXT SEARCH CONFIGURATION; Schema: public; Owner: -
--

CREATE TEXT SEARCH CONFIGURATION public.vietnamese (
    PARSER = pg_catalog."default" );

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR asciiword WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR word WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR numword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR email WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR url WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR host WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR sfloat WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR version WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword_numpart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword_part WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword_asciipart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR numhword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR asciihword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR hword WITH extensions.unaccent, simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR url_path WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR file WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR "float" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR "int" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.vietnamese
    ADD MAPPING FOR uint WITH simple;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: achievement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.achievement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    sport bigint,
    xp_reward bigint NOT NULL,
    repeatable boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE achievement; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.achievement IS 'activities for users to earn XP and level up';


--
-- Name: activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    lobby_id uuid,
    professional_booking_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT activity_source_exclusivity CHECK ((NOT ((lobby_id IS NOT NULL) AND (professional_booking_id IS NOT NULL)))),
    CONSTRAINT activity_time_validity CHECK (((end_time IS NULL) OR (end_time > start_time)))
);


--
-- Name: TABLE activity; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.activity IS 'User activity sessions - can be linked to lobby or professional booking';


--
-- Name: activity_health_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_health_metrics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    activity_id uuid NOT NULL,
    steps integer,
    distance_meters real,
    active_calories real,
    avg_heart_rate integer,
    max_heart_rate integer,
    min_heart_rate integer,
    hrv_sdnn_ms real,
    hrv_rmssd_ms real,
    hr_zone_1_seconds integer,
    hr_zone_2_seconds integer,
    hr_zone_3_seconds integer,
    hr_zone_4_seconds integer,
    hr_zone_5_seconds integer,
    training_load real,
    effort_score real,
    weight_kg real,
    workout_type text,
    recorded_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT heart_rate_validity CHECK ((((avg_heart_rate IS NULL) OR ((avg_heart_rate >= 30) AND (avg_heart_rate <= 250))) AND ((max_heart_rate IS NULL) OR ((max_heart_rate >= 30) AND (max_heart_rate <= 250))) AND ((min_heart_rate IS NULL) OR ((min_heart_rate >= 30) AND (min_heart_rate <= 250)))))
);


--
-- Name: TABLE activity_health_metrics; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.activity_health_metrics IS 'Aggregated health metrics for user activities';


--
-- Name: activity_hr_sample; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_hr_sample (
    id bigint NOT NULL,
    activity_id uuid NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    bpm smallint NOT NULL,
    CONSTRAINT hr_sample_bpm_validity CHECK (((bpm >= 30) AND (bpm <= 250)))
);


--
-- Name: TABLE activity_hr_sample; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.activity_hr_sample IS 'Raw heart rate samples during activities - enables HR curve reconstruction and detailed analysis';


--
-- Name: activity_hr_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.activity_hr_sample ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.activity_hr_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: badminton_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badminton_profile (
    user_id uuid NOT NULL,
    dominant_hand text,
    discipline text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: basketball_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.basketball_profile (
    user_id uuid NOT NULL,
    "position" text[] DEFAULT '{}'::text[] NOT NULL,
    pitch text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: booking_additional_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.booking_additional_users (
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: daily_health_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.daily_health_summary (
    user_id uuid NOT NULL,
    date date NOT NULL,
    resting_heart_rate integer,
    hrv_sdnn_ms real,
    steps integer,
    distance_meters real,
    active_calories real,
    total_calories real,
    sleep_minutes integer,
    sleep_quality_score real,
    weight_kg real,
    activity_count integer DEFAULT 0,
    total_activity_minutes integer DEFAULT 0,
    synced_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT resting_hr_validity CHECK (((resting_heart_rate IS NULL) OR ((resting_heart_rate >= 30) AND (resting_heart_rate <= 150))))
);


--
-- Name: TABLE daily_health_summary; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.daily_health_summary IS 'Daily health metrics for long-term trend analysis';


--
-- Name: industry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.industry (
    id integer NOT NULL,
    name character varying(128) NOT NULL
);


--
-- Name: industry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.industry_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: industry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.industry_id_seq OWNED BY public.industry.id;


--
-- Name: lobby; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lobby (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    captain_id uuid NOT NULL,
    searchable_id text DEFAULT public.nanoid(8) NOT NULL,
    name text NOT NULL,
    sport_id bigint NOT NULL,
    playtime jsonb,
    details jsonb,
    home_ground uuid,
    visibility public.lobby_visibility DEFAULT 'discoverable'::public.lobby_visibility
);


--
-- Name: lobby_befriend_record; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lobby_befriend_record (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    initiator_user_id uuid NOT NULL,
    target_user_id uuid,
    target_lobby_id uuid,
    interaction_type public.lobby_befriend_interaction NOT NULL,
    status public.lobby_befriend_status DEFAULT 'pending'::public.lobby_befriend_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now(),
    details jsonb,
    CONSTRAINT befriend_record_invite_conditions CHECK (((interaction_type <> 'invite'::public.lobby_befriend_interaction) OR (target_user_id IS NOT NULL))),
    CONSTRAINT befriend_record_pair_conditions CHECK (((interaction_type <> 'pair'::public.lobby_befriend_interaction) OR ((target_user_id IS NOT NULL) AND (target_lobby_id IS NULL) AND (initiator_user_id <> target_user_id)))),
    CONSTRAINT befriend_record_request_conditions CHECK (((interaction_type <> 'request'::public.lobby_befriend_interaction) OR ((target_user_id IS NULL) AND (target_lobby_id IS NOT NULL))))
);


--
-- Name: lobby_feed_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lobby_feed_item (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    author_id uuid,
    kind public.lobby_feed_item_kind NOT NULL,
    payload jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lobby_feed_item_payload_shape CHECK ((((kind = 'update'::public.lobby_feed_item_kind) AND (payload ? 'title'::text) AND (payload ? 'kind'::text) AND (payload ? 'tone'::text) AND (payload ? 'fields'::text)) OR ((kind = 'personal'::public.lobby_feed_item_kind) AND (payload ? 'action_kind'::text)) OR ((kind = 'system'::public.lobby_feed_item_kind) AND (payload ? 'text'::text)) OR ((kind = 'poll'::public.lobby_feed_item_kind) AND (payload ? 'question'::text) AND (payload ? 'options'::text)) OR ((kind = 'photo'::public.lobby_feed_item_kind) AND (payload ? 'storage_path'::text))))
);


--
-- Name: TABLE lobby_feed_item; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.lobby_feed_item IS 'Action-stream entries for a lobby''s activity tab. Payload shape varies by kind — see CHECK constraint and lib/manage_tab/lobby_section/activity/feed.dart for the canonical schemas.';


--
-- Name: lobby_feed_poll_vote; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lobby_feed_poll_vote (
    feed_item_id uuid NOT NULL,
    user_id uuid NOT NULL,
    option_index integer NOT NULL,
    voted_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lobby_feed_poll_vote_option_index_check CHECK ((option_index >= 0))
);


--
-- Name: TABLE lobby_feed_poll_vote; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.lobby_feed_poll_vote IS 'Member votes against a feed-item poll. option_index points into the payload.options array of the parent lobby_feed_item.';


--
-- Name: lobby_match; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lobby_match (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lobby_id uuid NOT NULL,
    activity_id uuid,
    opponent_lobby_id uuid,
    opponent_tag text NOT NULL,
    result public.lobby_match_result NOT NULL,
    sets jsonb,
    mvp_user_id uuid,
    note text,
    venue_label text NOT NULL,
    played_at timestamp with time zone NOT NULL,
    duration_label text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    referee_booking_id uuid,
    CONSTRAINT lobby_match_referee_required_for_challenge CHECK (((opponent_lobby_id IS NULL) OR (referee_booking_id IS NOT NULL))),
    CONSTRAINT lobby_match_sets_only_when_decided CHECK ((((result = 'practice'::public.lobby_match_result) AND (sets IS NULL)) OR (result <> 'practice'::public.lobby_match_result)))
);


--
-- Name: TABLE lobby_match; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.lobby_match IS 'Recorded match results for a lobby. sets is a JSON array of [us, them] tuples; venue_label / duration_label are denormalised copies for fast list rendering.';


--
-- Name: COLUMN lobby_match.referee_booking_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.lobby_match.referee_booking_id IS 'FK to the professional_booking that hired the referee for this match. Required for challenge matches (see lobby_match_referee_required_for_challenge). RESTRICT on delete because the booking row is the historical record of the hire — deleting it would orphan the audit trail.';


--
-- Name: lobby_member; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lobby_member (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    lobby_id uuid NOT NULL
);


--
-- Name: TABLE lobby_member; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.lobby_member IS 'join table between user and lobby';


--
-- Name: lobby_member_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.lobby_member ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.lobby_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: location; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.location (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    external_id text,
    name text NOT NULL,
    full_address text,
    street_number integer,
    street_name text,
    district text,
    city text,
    lat double precision,
    lon double precision,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    city_cluster bigint
);


--
-- Name: COLUMN location.lat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.location.lat IS 'latitude';


--
-- Name: COLUMN location.lon; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.location.lon IS 'longitude';


--
-- Name: network; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.network (
    id bigint NOT NULL,
    name text NOT NULL,
    category text,
    city bigint,
    name_fts tsvector GENERATED ALWAYS AS (to_tsvector('public.vietnamese'::regconfig, public.immutable_unaccent(name))) STORED,
    CONSTRAINT network_category_check CHECK ((category = ANY (ARRAY['high school'::text, 'gifted high school'::text, 'university'::text, 'company'::text])))
);


--
-- Name: TABLE network; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.network IS 'entities/ organizations that users may share';


--
-- Name: network_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.network ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.network_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pickleball_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pickleball_profile (
    user_id uuid NOT NULL,
    dominant_hand text,
    discipline text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: professional; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.professional (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    linked_user_id uuid,
    professional_role public.professional_role NOT NULL,
    display_name text NOT NULL,
    bio text,
    contact_details jsonb,
    certifications jsonb,
    schedule jsonb,
    schedule_note text,
    is_verified boolean DEFAULT false NOT NULL,
    sports bigint[] NOT NULL,
    experience_years integer,
    average_rating numeric(3,2) DEFAULT 0.00,
    review_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT professional_experience_years_check CHECK ((experience_years >= 0)),
    CONSTRAINT professional_sports_check CHECK ((array_length(sports, 1) > 0))
);


--
-- Name: professional_booking; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.professional_booking (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_user_id uuid NOT NULL,
    service_id uuid NOT NULL,
    professional_id uuid NOT NULL,
    event_id uuid,
    location_id uuid,
    booking_time_start timestamp with time zone NOT NULL,
    booking_time_end timestamp with time zone NOT NULL,
    agreed_rate numeric(10,2),
    status public.professional_booking_status DEFAULT 'requested'::public.professional_booking_status NOT NULL,
    client_notes text,
    professional_notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT booking_times_validity CHECK ((booking_time_end > booking_time_start)),
    CONSTRAINT professional_booking_agreed_rate_check CHECK ((agreed_rate >= (0)::numeric)),
    CONSTRAINT professional_booking_status_check CHECK ((status <> 'completed'::public.professional_booking_status))
);


--
-- Name: professional_booking_review; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.professional_booking_review (
    booking_id uuid NOT NULL,
    reviewer_user_id uuid NOT NULL,
    professional_id uuid NOT NULL,
    rating numeric(2,1) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT professional_booking_review_rating_check CHECK (((rating >= 0.5) AND (rating <= 5.0) AND ((rating * (2)::numeric) = floor((rating * (2)::numeric)))))
);


--
-- Name: professional_service; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.professional_service (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    professional_id uuid NOT NULL,
    sport_id bigint NOT NULL,
    service_type text NOT NULL,
    service_description text,
    hourly_rate numeric(10,2),
    min_duration_minutes integer,
    max_participants integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT professional_service_hourly_rate_check CHECK ((hourly_rate >= (0)::numeric)),
    CONSTRAINT professional_service_max_participants_check CHECK ((max_participants >= 1)),
    CONSTRAINT professional_service_min_duration_minutes_check CHECK ((min_duration_minutes > 0))
);


--
-- Name: soccer_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.soccer_profile (
    user_id uuid NOT NULL,
    "position" text[] DEFAULT '{}'::text[] NOT NULL,
    pitch text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: sport; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sport (
    id bigint NOT NULL,
    name text NOT NULL
);


--
-- Name: sport_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.sport ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.sport_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: supported_city_cluster; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supported_city_cluster (
    id bigint NOT NULL,
    country public.country DEFAULT 'VN'::public.country NOT NULL,
    name text NOT NULL
);


--
-- Name: supported_city_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.supported_city_cluster ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.supported_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tennis_profile; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tennis_profile (
    user_id uuid NOT NULL,
    dominant_hand text,
    discipline text[] DEFAULT '{}'::text[] NOT NULL,
    elo_seed text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    id uuid DEFAULT auth.uid() NOT NULL,
    username character varying(16) DEFAULT public.nanoid(16) NOT NULL,
    tag_number character varying(4) DEFAULT lpad((((floor((random() * (10000)::double precision)))::integer)::character varying)::text, 4, '0'::text) NOT NULL,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT user_details_schema CHECK (extensions.jsonb_matches_schema('{
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "description": "Freeform data for user profile",
      "type": "object",
      "properties": {
        "gender":         { "type": "string" },
        "ageGroup":       { "type": "string" },
        "playtime":       { "type": "array" },
        "generatedAvatar":{ "type": "string" },
        "location": {
          "type": "object",
          "properties": {
            "city":      { "type": "integer" },
            "districts": { "type": "array", "items": { "type": "string" } }
          }
        }
      }
    }'::json, details)),
    CONSTRAINT user_username_alphanumeric CHECK (((username)::text ~ '^[a-zA-Z0-9]+$'::text))
);


--
-- Name: user_health_link; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_health_link (
    user_id uuid NOT NULL,
    platform public.health_platform NOT NULL,
    linked_at timestamp with time zone DEFAULT now() NOT NULL,
    last_sync_at timestamp with time zone
);


--
-- Name: TABLE user_health_link; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_health_link IS 'Tracks user health service (Apple Health/Google Fit) linking status';


--
-- Name: user_industry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_industry (
    id bigint NOT NULL,
    user_id uuid,
    industry_id integer
);


--
-- Name: TABLE user_industry; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_industry IS 'join table for `user` and `industry`';


--
-- Name: user_industry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.user_industry ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_industry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_network; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_network (
    id bigint NOT NULL,
    user_id uuid,
    network_id bigint,
    alumni boolean DEFAULT true NOT NULL
);


--
-- Name: TABLE user_network; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_network IS 'join table for `user` and `network`';


--
-- Name: user_network_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.user_network ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_network_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_rating; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_rating (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    sport text NOT NULL,
    format text,
    elo integer NOT NULL,
    games_played integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: industry id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.industry ALTER COLUMN id SET DEFAULT nextval('public.industry_id_seq'::regclass);


--
-- Name: achievement achievement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievement
    ADD CONSTRAINT achievement_pkey PRIMARY KEY (id);


--
-- Name: activity_health_metrics activity_health_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_pkey PRIMARY KEY (id);


--
-- Name: activity_health_metrics activity_health_metrics_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_unique UNIQUE (user_id, activity_id);


--
-- Name: activity_hr_sample activity_hr_sample_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_hr_sample
    ADD CONSTRAINT activity_hr_sample_pkey PRIMARY KEY (id);


--
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (id);


--
-- Name: badminton_profile badminton_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badminton_profile
    ADD CONSTRAINT badminton_profile_pkey PRIMARY KEY (user_id);


--
-- Name: basketball_profile basketball_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.basketball_profile
    ADD CONSTRAINT basketball_profile_pkey PRIMARY KEY (user_id);


--
-- Name: booking_additional_users booking_additional_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_additional_users
    ADD CONSTRAINT booking_additional_users_pkey PRIMARY KEY (booking_id, user_id);


--
-- Name: daily_health_summary daily_health_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_health_summary
    ADD CONSTRAINT daily_health_summary_pkey PRIMARY KEY (user_id, date);


--
-- Name: industry industry_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.industry
    ADD CONSTRAINT industry_name_key UNIQUE (name);


--
-- Name: industry industry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.industry
    ADD CONSTRAINT industry_pkey PRIMARY KEY (id);


--
-- Name: lobby_befriend_record lobby_befriend_record_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_pkey PRIMARY KEY (id);


--
-- Name: lobby_feed_item lobby_feed_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_pkey PRIMARY KEY (id);


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_pkey PRIMARY KEY (feed_item_id, user_id);


--
-- Name: lobby_match lobby_match_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_pkey PRIMARY KEY (id);


--
-- Name: lobby_member lobby_member_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_pkey PRIMARY KEY (id);


--
-- Name: lobby_member lobby_member_user_lobby_uniq; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_user_lobby_uniq UNIQUE (user_id, lobby_id);


--
-- Name: lobby lobby_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_pkey PRIMARY KEY (id);


--
-- Name: location location_external_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_external_id_key UNIQUE (external_id);


--
-- Name: location location_full_address_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_full_address_key UNIQUE (full_address);


--
-- Name: location location_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (id);


--
-- Name: network network_name_city_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_name_city_key UNIQUE (name, city);


--
-- Name: network network_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_pkey PRIMARY KEY (id);


--
-- Name: pickleball_profile pickleball_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pickleball_profile
    ADD CONSTRAINT pickleball_profile_pkey PRIMARY KEY (user_id);


--
-- Name: professional_booking professional_booking_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_pkey PRIMARY KEY (id);


--
-- Name: professional_booking_review professional_booking_review_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_pkey PRIMARY KEY (booking_id);


--
-- Name: professional professional_linked_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_linked_user_id_key UNIQUE (linked_user_id);


--
-- Name: professional professional_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_pkey PRIMARY KEY (id);


--
-- Name: professional_service professional_service_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_service
    ADD CONSTRAINT professional_service_pkey PRIMARY KEY (id);


--
-- Name: soccer_profile soccer_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.soccer_profile
    ADD CONSTRAINT soccer_profile_pkey PRIMARY KEY (user_id);


--
-- Name: sport sport_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sport
    ADD CONSTRAINT sport_name_key UNIQUE (name);


--
-- Name: sport sport_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sport
    ADD CONSTRAINT sport_pkey PRIMARY KEY (id);


--
-- Name: supported_city_cluster supported_city_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supported_city_cluster
    ADD CONSTRAINT supported_city_pkey PRIMARY KEY (id);


--
-- Name: tennis_profile tennis_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tennis_profile
    ADD CONSTRAINT tennis_profile_pkey PRIMARY KEY (user_id);


--
-- Name: user_health_link user_health_link_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_health_link
    ADD CONSTRAINT user_health_link_pkey PRIMARY KEY (user_id);


--
-- Name: user_industry user_industry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_industry
    ADD CONSTRAINT user_industry_pkey PRIMARY KEY (id);


--
-- Name: user_network user_network_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_network
    ADD CONSTRAINT user_network_pkey PRIMARY KEY (id);


--
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk UNIQUE (username, tag_number);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: user_rating user_rating_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_pkey PRIMARY KEY (id);


--
-- Name: user_rating user_rating_user_id_sport_format_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_user_id_sport_format_key UNIQUE (user_id, sport, format);


--
-- Name: basketball_profile_pitch_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX basketball_profile_pitch_idx ON public.basketball_profile USING gin (pitch);


--
-- Name: basketball_profile_position_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX basketball_profile_position_idx ON public.basketball_profile USING gin ("position");


--
-- Name: idx_activity_health_metrics_activity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_health_metrics_activity_id ON public.activity_health_metrics USING btree (activity_id);


--
-- Name: idx_activity_health_metrics_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_health_metrics_user_id ON public.activity_health_metrics USING btree (user_id);


--
-- Name: idx_activity_hr_sample_activity_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_hr_sample_activity_timestamp ON public.activity_hr_sample USING btree (activity_id, "timestamp");


--
-- Name: idx_activity_sport_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_sport_id ON public.activity USING btree (sport_id);


--
-- Name: idx_activity_start_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_start_time ON public.activity USING btree (start_time);


--
-- Name: idx_activity_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_activity_user_id ON public.activity USING btree (user_id);


--
-- Name: idx_booking_additional_users_booking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_booking_additional_users_booking_id ON public.booking_additional_users USING btree (booking_id);


--
-- Name: idx_booking_additional_users_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_booking_additional_users_user_id ON public.booking_additional_users USING btree (user_id);


--
-- Name: idx_bookings_client_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_client_user_id ON public.professional_booking USING btree (client_user_id);


--
-- Name: idx_bookings_professional_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_professional_id ON public.professional_booking USING btree (professional_id);


--
-- Name: idx_bookings_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_service_id ON public.professional_booking USING btree (service_id);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_bookings_status ON public.professional_booking USING btree (status);


--
-- Name: idx_daily_health_summary_user_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_daily_health_summary_user_date ON public.daily_health_summary USING btree (user_id, date DESC);


--
-- Name: idx_listed_professionals_is_verified; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_listed_professionals_is_verified ON public.professional USING btree (is_verified);


--
-- Name: idx_listed_professionals_linked_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_listed_professionals_linked_user_id ON public.professional USING btree (linked_user_id) WHERE (linked_user_id IS NOT NULL);


--
-- Name: idx_listed_professionals_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_listed_professionals_role ON public.professional USING btree (professional_role);


--
-- Name: idx_lobby_befriend_record_initiator; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_befriend_record_initiator ON public.lobby_befriend_record USING btree (initiator_user_id);


--
-- Name: idx_lobby_befriend_record_interaction_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_befriend_record_interaction_type ON public.lobby_befriend_record USING btree (interaction_type);


--
-- Name: idx_lobby_befriend_record_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_befriend_record_status ON public.lobby_befriend_record USING btree (status);


--
-- Name: idx_lobby_befriend_record_target_lobby; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_befriend_record_target_lobby ON public.lobby_befriend_record USING btree (target_lobby_id);


--
-- Name: idx_lobby_befriend_record_target_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_befriend_record_target_user ON public.lobby_befriend_record USING btree (target_user_id);


--
-- Name: idx_lobby_captain_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_captain_id ON public.lobby USING btree (captain_id);


--
-- Name: idx_lobby_home_ground; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_home_ground ON public.lobby USING btree (home_ground);


--
-- Name: idx_lobby_member_lobby_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_member_lobby_id ON public.lobby_member USING btree (lobby_id);


--
-- Name: idx_lobby_member_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_member_user_id ON public.lobby_member USING btree (user_id);


--
-- Name: idx_lobby_sport_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lobby_sport_id ON public.lobby USING btree (sport_id);


--
-- Name: idx_location_city_cluster; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_location_city_cluster ON public.location USING btree (city_cluster);


--
-- Name: idx_location_full_address_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_location_full_address_trgm ON public.location USING gin (public.immutable_unaccent(lower(full_address)) extensions.gin_trgm_ops);


--
-- Name: idx_location_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_location_name_trgm ON public.location USING gin (public.immutable_unaccent(lower(name)) extensions.gin_trgm_ops);


--
-- Name: idx_network_city; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_network_city ON public.network USING btree (city);


--
-- Name: idx_professional_booking_location_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_professional_booking_location_id ON public.professional_booking USING btree (location_id);


--
-- Name: idx_professional_review_professional_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_professional_review_professional_id ON public.professional_booking_review USING btree (professional_id);


--
-- Name: idx_professional_review_reviewer_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_professional_review_reviewer_user_id ON public.professional_booking_review USING btree (reviewer_user_id);


--
-- Name: idx_professional_services_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_professional_services_is_active ON public.professional_service USING btree (is_active);


--
-- Name: idx_professional_services_listed_professional_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_professional_services_listed_professional_id ON public.professional_service USING btree (professional_id);


--
-- Name: idx_professional_services_sport_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_professional_services_sport_id ON public.professional_service USING btree (sport_id);


--
-- Name: idx_user_industry_industry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_industry_industry_id ON public.user_industry USING btree (industry_id);


--
-- Name: idx_user_industry_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_industry_user_id ON public.user_industry USING btree (user_id);


--
-- Name: idx_user_network_network_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_network_network_id ON public.user_network USING btree (network_id);


--
-- Name: idx_user_network_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_network_user_id ON public.user_network USING btree (user_id);


--
-- Name: lobby_feed_item_lobby_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lobby_feed_item_lobby_idx ON public.lobby_feed_item USING btree (lobby_id, created_at DESC);


--
-- Name: lobby_match_lobby_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX lobby_match_lobby_idx ON public.lobby_match USING btree (lobby_id, played_at DESC);


--
-- Name: network_name_lower_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX network_name_lower_idx ON public.network USING btree (lower(name) text_pattern_ops);


--
-- Name: network_name_partial_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX network_name_partial_idx ON public.network USING btree (name text_pattern_ops);


--
-- Name: network_name_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX network_name_trgm_idx ON public.network USING gin (lower(name) extensions.gin_trgm_ops);


--
-- Name: network_name_unaccent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX network_name_unaccent_idx ON public.network USING btree (public.immutable_unaccent(lower(name)) text_pattern_ops);


--
-- Name: network_name_unaccent_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX network_name_unaccent_trgm_idx ON public.network USING gin (public.immutable_unaccent(lower(name)) extensions.gin_trgm_ops);


--
-- Name: soccer_profile_pitch_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX soccer_profile_pitch_idx ON public.soccer_profile USING gin (pitch);


--
-- Name: soccer_profile_position_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX soccer_profile_position_idx ON public.soccer_profile USING gin ("position");


--
-- Name: user_rating_user_sport_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_rating_user_sport_idx ON public.user_rating USING btree (user_id, sport);


--
-- Name: badminton_profile badminton_elo_seed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER badminton_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.badminton_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: basketball_profile basketball_elo_seed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER basketball_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.basketball_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: lobby lobby_add_captain_as_member; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lobby_add_captain_as_member AFTER INSERT ON public.lobby FOR EACH ROW EXECUTE FUNCTION public.lobby_add_captain_as_member();


--
-- Name: lobby lobby_before_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lobby_before_delete BEFORE DELETE ON public.lobby FOR EACH ROW EXECUTE FUNCTION public.lobby_before_delete();


--
-- Name: lobby_befriend_record lobby_befriend_accepted_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lobby_befriend_accepted_trigger AFTER UPDATE ON public.lobby_befriend_record FOR EACH ROW EXECUTE FUNCTION public.lobby_befriend_accepted_trigger_fn();


--
-- Name: lobby_befriend_record lobby_befriend_record_before_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lobby_befriend_record_before_insert BEFORE INSERT ON public.lobby_befriend_record FOR EACH ROW EXECUTE FUNCTION public.lobby_befriend_record_before_insert_trigger_fn();


--
-- Name: lobby_match lobby_match_referee_role_check; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lobby_match_referee_role_check BEFORE INSERT OR UPDATE OF referee_booking_id ON public.lobby_match FOR EACH ROW EXECUTE FUNCTION public.lobby_match_referee_role_check();


--
-- Name: lobby_member lobby_member_prevent_captain_leave; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER lobby_member_prevent_captain_leave BEFORE DELETE ON public.lobby_member FOR EACH ROW EXECUTE FUNCTION public.lobby_member_prevent_captain_leave();


--
-- Name: pickleball_profile pickleball_elo_seed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER pickleball_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.pickleball_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: professional_booking_review professional_review_stats_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER professional_review_stats_trigger AFTER INSERT OR DELETE OR UPDATE ON public.professional_booking_review FOR EACH ROW EXECUTE FUNCTION public.professional_booking_review_updated_trigger_fn();


--
-- Name: soccer_profile soccer_elo_seed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER soccer_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.soccer_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: tennis_profile tennis_elo_seed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tennis_elo_seed AFTER INSERT OR UPDATE OF elo_seed ON public.tennis_profile FOR EACH ROW EXECUTE FUNCTION public.fn_seed_initial_elo();


--
-- Name: achievement achievement_sport_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.achievement
    ADD CONSTRAINT achievement_sport_fkey FOREIGN KEY (sport) REFERENCES public.sport(id);


--
-- Name: activity_health_metrics activity_health_metrics_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity_health_metrics activity_health_metrics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_health_metrics
    ADD CONSTRAINT activity_health_metrics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: activity_hr_sample activity_hr_sample_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_hr_sample
    ADD CONSTRAINT activity_hr_sample_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE CASCADE;


--
-- Name: activity activity_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE SET NULL;


--
-- Name: activity activity_professional_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_professional_booking_id_fkey FOREIGN KEY (professional_booking_id) REFERENCES public.professional_booking(id) ON DELETE SET NULL;


--
-- Name: activity activity_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: activity activity_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity
    ADD CONSTRAINT activity_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: badminton_profile badminton_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badminton_profile
    ADD CONSTRAINT badminton_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: basketball_profile basketball_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.basketball_profile
    ADD CONSTRAINT basketball_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: booking_additional_users booking_additional_users_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_additional_users
    ADD CONSTRAINT booking_additional_users_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.professional_booking(id) ON DELETE CASCADE;


--
-- Name: booking_additional_users booking_additional_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.booking_additional_users
    ADD CONSTRAINT booking_additional_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: daily_health_summary daily_health_summary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.daily_health_summary
    ADD CONSTRAINT daily_health_summary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_initiator_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_initiator_user_id_fkey FOREIGN KEY (initiator_user_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_target_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_target_lobby_id_fkey FOREIGN KEY (target_lobby_id) REFERENCES public.lobby(id) ON UPDATE CASCADE;


--
-- Name: lobby_befriend_record lobby_befriend_record_target_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_befriend_record
    ADD CONSTRAINT lobby_befriend_record_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby lobby_captain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_captain_id_fkey FOREIGN KEY (captain_id) REFERENCES public."user"(id) ON UPDATE CASCADE;


--
-- Name: lobby_feed_item lobby_feed_item_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_author_id_fkey FOREIGN KEY (author_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: lobby_feed_item lobby_feed_item_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_feed_item
    ADD CONSTRAINT lobby_feed_item_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_feed_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_feed_item_id_fkey FOREIGN KEY (feed_item_id) REFERENCES public.lobby_feed_item(id) ON DELETE CASCADE;


--
-- Name: lobby_feed_poll_vote lobby_feed_poll_vote_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_feed_poll_vote
    ADD CONSTRAINT lobby_feed_poll_vote_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: lobby lobby_home_ground_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_home_ground_fkey FOREIGN KEY (home_ground) REFERENCES public.location(id);


--
-- Name: lobby_match lobby_match_activity_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activity(id) ON DELETE SET NULL;


--
-- Name: lobby_match lobby_match_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_match lobby_match_mvp_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_mvp_user_id_fkey FOREIGN KEY (mvp_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: lobby_match lobby_match_opponent_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_opponent_lobby_id_fkey FOREIGN KEY (opponent_lobby_id) REFERENCES public.lobby(id) ON DELETE SET NULL;


--
-- Name: lobby_match lobby_match_referee_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_match
    ADD CONSTRAINT lobby_match_referee_booking_id_fkey FOREIGN KEY (referee_booking_id) REFERENCES public.professional_booking(id) ON DELETE RESTRICT;


--
-- Name: lobby_member lobby_member_lobby_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


--
-- Name: lobby_member lobby_member_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby_member
    ADD CONSTRAINT lobby_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: lobby lobby_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lobby
    ADD CONSTRAINT lobby_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: location location_city_cluster_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.location
    ADD CONSTRAINT location_city_cluster_fkey FOREIGN KEY (city_cluster) REFERENCES public.supported_city_cluster(id);


--
-- Name: network network_city_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.network
    ADD CONSTRAINT network_city_fkey FOREIGN KEY (city) REFERENCES public.supported_city_cluster(id);


--
-- Name: pickleball_profile pickleball_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pickleball_profile
    ADD CONSTRAINT pickleball_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: professional_booking professional_booking_client_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_client_user_id_fkey FOREIGN KEY (client_user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: professional_booking professional_booking_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.location(id);


--
-- Name: professional_booking professional_booking_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id);


--
-- Name: professional_booking_review professional_booking_review_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.professional_booking(id) ON DELETE RESTRICT;


--
-- Name: professional_booking_review professional_booking_review_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: professional_booking_review professional_booking_review_reviewer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking_review
    ADD CONSTRAINT professional_booking_review_reviewer_user_id_fkey FOREIGN KEY (reviewer_user_id) REFERENCES public."user"(id) ON DELETE RESTRICT;


--
-- Name: professional_booking professional_booking_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_booking
    ADD CONSTRAINT professional_booking_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.professional_service(id);


--
-- Name: professional professional_linked_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional
    ADD CONSTRAINT professional_linked_user_id_fkey FOREIGN KEY (linked_user_id) REFERENCES public."user"(id) ON DELETE SET NULL;


--
-- Name: professional_service professional_service_professional_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_service
    ADD CONSTRAINT professional_service_professional_id_fkey FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE;


--
-- Name: professional_service professional_service_sport_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.professional_service
    ADD CONSTRAINT professional_service_sport_id_fkey FOREIGN KEY (sport_id) REFERENCES public.sport(id);


--
-- Name: soccer_profile soccer_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.soccer_profile
    ADD CONSTRAINT soccer_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: tennis_profile tennis_profile_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tennis_profile
    ADD CONSTRAINT tennis_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_health_link user_health_link_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_health_link
    ADD CONSTRAINT user_health_link_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id) ON DELETE CASCADE;


--
-- Name: user user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON UPDATE CASCADE;


--
-- Name: user_industry user_industry_industry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_industry
    ADD CONSTRAINT user_industry_industry_id_fkey FOREIGN KEY (industry_id) REFERENCES public.industry(id);


--
-- Name: user_industry user_industry_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_industry
    ADD CONSTRAINT user_industry_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: user_network user_network_network_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_network
    ADD CONSTRAINT user_network_network_id_fkey FOREIGN KEY (network_id) REFERENCES public.network(id);


--
-- Name: user_network user_network_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_network
    ADD CONSTRAINT user_network_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(id);


--
-- Name: user_rating user_rating_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_rating
    ADD CONSTRAINT user_rating_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: booking_additional_users Additional users can see bookings they are part of; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Additional users can see bookings they are part of" ON public.booking_additional_users FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_feed_item Author or captain can delete a feed item; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Author or captain can delete a feed item" ON public.lobby_feed_item FOR DELETE TO authenticated USING (((author_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_feed_item.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: lobby_match Captain can delete their lobby's matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Captain can delete their lobby's matches" ON public.lobby_match FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: lobby_match Captain can edit their lobby's matches; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Captain can edit their lobby's matches" ON public.lobby_match FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: lobby_feed_item Captain can post updates and polls; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Captain can post updates and polls" ON public.lobby_feed_item FOR INSERT TO authenticated WITH CHECK (((author_id = ( SELECT auth.uid() AS uid)) AND (kind = ANY (ARRAY['update'::public.lobby_feed_item_kind, 'poll'::public.lobby_feed_item_kind])) AND (EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_feed_item.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid)))))));


--
-- Name: lobby_match Captain can record matches for their lobby; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Captain can record matches for their lobby" ON public.lobby_match FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.lobby l
  WHERE ((l.id = lobby_match.lobby_id) AND (l.captain_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: booking_additional_users Client can manage additional users for their bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Client can manage additional users for their bookings" ON public.booking_additional_users TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional_booking pb
  WHERE ((pb.id = booking_additional_users.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional_booking pb
  WHERE ((pb.id = booking_additional_users.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional_booking_review Clients can create reviews for their completed bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Clients can create reviews for their completed bookings" ON public.professional_booking_review FOR INSERT TO authenticated WITH CHECK (((reviewer_user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.professional_booking pb
  WHERE ((pb.id = professional_booking_review.booking_id) AND (pb.client_user_id = ( SELECT auth.uid() AS uid)) AND (pb.status = 'completed'::public.professional_booking_status))))));


--
-- Name: professional_booking Clients can manage their own bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Clients can manage their own bookings" ON public.professional_booking TO authenticated USING ((( SELECT auth.uid() AS uid) = client_user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = client_user_id));


--
-- Name: lobby Enable insert for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users only" ON public.lobby FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: industry Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.industry FOR SELECT USING (true);


--
-- Name: lobby Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.lobby FOR SELECT USING (true);


--
-- Name: location Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.location FOR SELECT USING (true);


--
-- Name: network Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.network FOR SELECT USING (true);


--
-- Name: sport Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.sport FOR SELECT USING (true);


--
-- Name: supported_city_cluster Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.supported_city_cluster FOR SELECT USING (true);


--
-- Name: user_industry Enable read access for authenticated user; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated user" ON public.user_industry FOR SELECT TO authenticated USING (true);


--
-- Name: user Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public."user" FOR SELECT TO authenticated USING (true);


--
-- Name: user_network Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.user_network FOR SELECT TO authenticated USING (true);


--
-- Name: professional Enable read access for verified professional profiles; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for verified professional profiles" ON public.professional FOR SELECT TO anon USING ((is_verified = true));


--
-- Name: professional_service Enable read for active services by verified professionals; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read for active services by verified professionals" ON public.professional_service FOR SELECT TO anon, authenticated USING (((is_active = true) AND (EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.is_verified = true))))));


--
-- Name: user Enable user to update their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable user to update their own profile" ON public."user" FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = id)) WITH CHECK ((( SELECT auth.uid() AS uid) = id));


--
-- Name: professional_booking Linked professionals can manage their bookings; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Linked professionals can manage their bookings" ON public.professional_booking TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_booking.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_booking.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional_service Linked professionals can manage their own services; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Linked professionals can manage their own services" ON public.professional_service TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.professional p
  WHERE ((p.id = professional_service.professional_id) AND (p.linked_user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: professional Linked users can manage their own professional profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Linked users can manage their own professional profile" ON public.professional TO authenticated USING ((( SELECT auth.uid() AS uid) = linked_user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = linked_user_id));


--
-- Name: lobby_member Lobby membership deletion policy; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Lobby membership deletion policy" ON public.lobby_member FOR DELETE TO authenticated USING ((((user_id = ( SELECT auth.uid() AS uid)) AND (NOT (EXISTS ( SELECT 1
   FROM public.lobby
  WHERE ((lobby.id = lobby_member.lobby_id) AND (lobby.captain_id = ( SELECT auth.uid() AS uid))))))) OR ((user_id <> ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.lobby
  WHERE ((lobby.id = lobby_member.lobby_id) AND (lobby.captain_id = ( SELECT auth.uid() AS uid))))))));


--
-- Name: lobby_feed_poll_vote Members can cast a vote in their lobby's polls; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can cast a vote in their lobby's polls" ON public.lobby_feed_poll_vote FOR INSERT TO authenticated WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (EXISTS ( SELECT 1
   FROM public.lobby_feed_item fi
  WHERE ((fi.id = lobby_feed_poll_vote.feed_item_id) AND (fi.kind = 'poll'::public.lobby_feed_item_kind) AND (fi.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))))));


--
-- Name: lobby_feed_item Members can post personal or photo items; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can post personal or photo items" ON public.lobby_feed_item FOR INSERT TO authenticated WITH CHECK (((author_id = ( SELECT auth.uid() AS uid)) AND (lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) AND (kind = ANY (ARRAY['personal'::public.lobby_feed_item_kind, 'photo'::public.lobby_feed_item_kind]))));


--
-- Name: lobby_feed_item Members can read feed items in their lobby; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can read feed items in their lobby" ON public.lobby_feed_item FOR SELECT TO authenticated USING ((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)));


--
-- Name: lobby_feed_poll_vote Members can read poll votes in their lobby; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members can read poll votes in their lobby" ON public.lobby_feed_poll_vote FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.lobby_feed_item fi
  WHERE ((fi.id = lobby_feed_poll_vote.feed_item_id) AND (fi.lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids))))));


--
-- Name: lobby_match Members of either lobby can read the match; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Members of either lobby can read the match" ON public.lobby_match FOR SELECT TO authenticated USING (((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)) OR ((opponent_lobby_id IS NOT NULL) AND (opponent_lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)))));


--
-- Name: lobby_feed_poll_vote Users can change their own vote; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can change their own vote" ON public.lobby_feed_poll_vote FOR UPDATE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_befriend_record Users can create befriend records with restrictions; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create befriend records with restrictions" ON public.lobby_befriend_record FOR INSERT TO authenticated WITH CHECK ((true AND ((interaction_type <> 'request'::public.lobby_befriend_interaction) OR (NOT (EXISTS ( SELECT 1
   FROM public.lobby
  WHERE ((lobby.id = lobby_befriend_record.target_lobby_id) AND (lobby.visibility = 'private'::public.lobby_visibility))))))));


--
-- Name: activity Users can create their own activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can create their own activities" ON public.activity FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_hr_sample Users can delete HR samples for their activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete HR samples for their activities" ON public.activity_hr_sample FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_hr_sample.activity_id) AND (a.user_id = auth.uid())))));


--
-- Name: activity Users can delete their own activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own activities" ON public.activity FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_industry Users can delete their own data; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own data" ON public.user_industry FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: user_health_link Users can delete their own health link; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own health link" ON public.user_health_link FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can delete their own health metrics; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own health metrics" ON public.activity_health_metrics FOR DELETE TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_network Users can delete their own rows; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete their own rows" ON public.user_network FOR DELETE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: activity_hr_sample Users can insert HR samples for their activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert HR samples for their activities" ON public.activity_hr_sample FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_hr_sample.activity_id) AND (a.user_id = auth.uid())))));


--
-- Name: user_industry Users can insert their own data; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own data" ON public.user_industry FOR INSERT TO authenticated WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: user_health_link Users can insert their own health link; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own health link" ON public.user_health_link FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can insert their own health metrics; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own health metrics" ON public.activity_health_metrics FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_network Users can insert their own rows; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own rows" ON public.user_network FOR INSERT TO authenticated WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: lobby_feed_poll_vote Users can retract their own vote; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can retract their own vote" ON public.lobby_feed_poll_vote FOR DELETE TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: lobby_member Users can see lobby members in shared lobbies; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can see lobby members in shared lobbies" ON public.lobby_member FOR SELECT TO authenticated USING ((lobby_id IN ( SELECT public.get_my_lobby_ids() AS get_my_lobby_ids)));


--
-- Name: activity Users can update their own activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own activities" ON public.activity FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: daily_health_summary Users can update their own daily summaries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own daily summaries" ON public.daily_health_summary FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_health_link Users can update their own health link; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own health link" ON public.user_health_link FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can update their own health metrics; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own health metrics" ON public.activity_health_metrics FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: user_network Users can update their own rows; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own rows" ON public.user_network FOR UPDATE TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id)) WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: daily_health_summary Users can upsert their own daily summaries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can upsert their own daily summaries" ON public.daily_health_summary FOR INSERT TO authenticated WITH CHECK ((user_id = auth.uid()));


--
-- Name: activity_hr_sample Users can view HR samples for their activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view HR samples for their activities" ON public.activity_hr_sample FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.activity a
  WHERE ((a.id = activity_hr_sample.activity_id) AND (a.user_id = auth.uid())))));


--
-- Name: lobby_befriend_record Users can view befriend records; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view befriend records" ON public.lobby_befriend_record FOR SELECT TO authenticated USING (((( SELECT auth.uid() AS uid) = target_user_id) OR (( SELECT auth.uid() AS uid) = initiator_user_id) OR (target_lobby_id IN ( SELECT lobby_member.lobby_id
   FROM public.lobby_member
  WHERE (lobby_member.user_id = ( SELECT auth.uid() AS uid))))));


--
-- Name: activity Users can view their own activities; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own activities" ON public.activity FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: daily_health_summary Users can view their own daily summaries; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own daily summaries" ON public.daily_health_summary FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_health_link Users can view their own health link; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own health link" ON public.user_health_link FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: activity_health_metrics Users can view their own health metrics; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own health metrics" ON public.activity_health_metrics FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: lobby_befriend_record Users involved can update befriend record status; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users involved can update befriend record status" ON public.lobby_befriend_record FOR UPDATE TO authenticated USING (((( SELECT auth.uid() AS uid) = initiator_user_id) OR (( SELECT auth.uid() AS uid) = target_user_id) OR ((target_lobby_id IS NOT NULL) AND (target_lobby_id IN ( SELECT lobby.id
   FROM public.lobby
  WHERE (lobby.captain_id = ( SELECT auth.uid() AS uid))))))) WITH CHECK (true);


--
-- Name: achievement; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.achievement ENABLE ROW LEVEL SECURITY;

--
-- Name: activity; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.activity ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_health_metrics; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.activity_health_metrics ENABLE ROW LEVEL SECURITY;

--
-- Name: activity_hr_sample; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.activity_hr_sample ENABLE ROW LEVEL SECURITY;

--
-- Name: badminton_profile badminton profiles are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "badminton profiles are publicly readable" ON public.badminton_profile FOR SELECT USING (true);


--
-- Name: badminton_profile; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.badminton_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: basketball_profile basketball profiles are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "basketball profiles are publicly readable" ON public.basketball_profile FOR SELECT USING (true);


--
-- Name: basketball_profile; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.basketball_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: booking_additional_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.booking_additional_users ENABLE ROW LEVEL SECURITY;

--
-- Name: daily_health_summary; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.daily_health_summary ENABLE ROW LEVEL SECURITY;

--
-- Name: user_rating elo ratings are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "elo ratings are publicly readable" ON public.user_rating FOR SELECT USING (true);


--
-- Name: industry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.industry ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lobby ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_befriend_record; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lobby_befriend_record ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_feed_item; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lobby_feed_item ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_feed_poll_vote; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lobby_feed_poll_vote ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_match; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lobby_match ENABLE ROW LEVEL SECURITY;

--
-- Name: lobby_member; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.lobby_member ENABLE ROW LEVEL SECURITY;

--
-- Name: location; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.location ENABLE ROW LEVEL SECURITY;

--
-- Name: network; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.network ENABLE ROW LEVEL SECURITY;

--
-- Name: pickleball_profile pickleball profiles are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "pickleball profiles are publicly readable" ON public.pickleball_profile FOR SELECT USING (true);


--
-- Name: pickleball_profile; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pickleball_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: professional; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.professional ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_booking; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.professional_booking ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_booking_review; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.professional_booking_review ENABLE ROW LEVEL SECURITY;

--
-- Name: professional_service; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.professional_service ENABLE ROW LEVEL SECURITY;

--
-- Name: soccer_profile; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.soccer_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: sport; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sport ENABLE ROW LEVEL SECURITY;

--
-- Name: soccer_profile sport profiles are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "sport profiles are publicly readable" ON public.soccer_profile FOR SELECT USING (true);


--
-- Name: supported_city_cluster; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supported_city_cluster ENABLE ROW LEVEL SECURITY;

--
-- Name: tennis_profile tennis profiles are publicly readable; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "tennis profiles are publicly readable" ON public.tennis_profile FOR SELECT USING (true);


--
-- Name: tennis_profile; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tennis_profile ENABLE ROW LEVEL SECURITY;

--
-- Name: user; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public."user" ENABLE ROW LEVEL SECURITY;

--
-- Name: user_health_link; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_health_link ENABLE ROW LEVEL SECURITY;

--
-- Name: user_industry; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_industry ENABLE ROW LEVEL SECURITY;

--
-- Name: user_network; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_network ENABLE ROW LEVEL SECURITY;

--
-- Name: user_rating; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_rating ENABLE ROW LEVEL SECURITY;

--
-- Name: badminton_profile users manage own badminton profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users manage own badminton profile" ON public.badminton_profile USING ((auth.uid() = user_id));


--
-- Name: basketball_profile users manage own basketball profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users manage own basketball profile" ON public.basketball_profile USING ((auth.uid() = user_id));


--
-- Name: pickleball_profile users manage own pickleball profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users manage own pickleball profile" ON public.pickleball_profile USING ((auth.uid() = user_id));


--
-- Name: soccer_profile users manage own soccer profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users manage own soccer profile" ON public.soccer_profile USING ((auth.uid() = user_id));


--
-- Name: tennis_profile users manage own tennis profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "users manage own tennis profile" ON public.tennis_profile USING ((auth.uid() = user_id));


--
-- PostgreSQL database dump complete
--

\unrestrict JOwmkov8MW2zBOd27rqiadHRXT4iMCnKrdeslTpbfc4pHXU3J8FAay1KTX2ZRp2

