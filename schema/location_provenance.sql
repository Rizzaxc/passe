-- Location input redesign: merge typeahead/manual entry into one form and make
-- every manual entry resolve into a real, shared `location` row instead of
-- being dropped or stuck per-record. See the "location input" plan for the
-- full rationale.
--
-- 1. Provenance columns on `location` (not surfaced in the UI — backend
--    moderation only).
-- 2. `create_location`: the single place a manual entry becomes a shared
--    row, called silently by the client.
-- 3. `search_locations`: fix the short-query blackout (many VN venue names
--    are under the old 8-char trigram floor).
-- 4. Clean-break simplification of every RPC/table that used to carry its
--    own bespoke "custom location text" fallback — one location
--    representation (`location_id`, resolved client-side) from here on.

-- ── 1. Provenance columns ──────────────────────────────────────────────
ALTER TABLE public.location
    ADD COLUMN source text NOT NULL DEFAULT 'directory'
        CHECK (source IN ('directory', 'user_submitted')),
    ADD COLUMN submitted_by uuid REFERENCES public."user"(id),
    ADD COLUMN is_verified boolean NOT NULL DEFAULT true;

-- ── 2. create_location ─────────────────────────────────────────────────
CREATE FUNCTION public.create_location(
    p_name text,
    p_street_number text DEFAULT NULL::text,
    p_street_name text DEFAULT NULL::text,
    p_district text DEFAULT NULL::text,
    p_city text DEFAULT NULL::text,
    p_city_cluster bigint DEFAULT NULL::bigint
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id uuid;
    v_loc_id  uuid;
    v_result  jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'create_location: authentication required';
    END IF;
    IF NULLIF(TRIM(COALESCE(p_name, '')), '') IS NULL THEN
        RAISE EXCEPTION 'create_location: name is required';
    END IF;

    INSERT INTO public.location (
        name, street_number, street_name, district, city, city_cluster,
        source, submitted_by, is_verified
    )
    VALUES (
        TRIM(p_name),
        NULLIF(p_street_number, '')::integer,
        NULLIF(p_street_name, ''),
        NULLIF(p_district, ''),
        NULLIF(p_city, ''),
        p_city_cluster,
        'user_submitted',
        v_user_id,
        false
    )
    RETURNING id INTO v_loc_id;

    SELECT row_to_json(l)::jsonb INTO v_result
        FROM public.location l
        WHERE l.id = v_loc_id;

    RETURN v_result;
END;
$$;

ALTER FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) OWNER TO postgres;

GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO authenticated;
GRANT ALL ON FUNCTION public.create_location(p_name text, p_street_number text, p_street_name text, p_district text, p_city text, p_city_cluster bigint) TO service_role;

-- ── 3. search_locations: fix the short-query blackout ─────────────────
CREATE OR REPLACE FUNCTION public.search_locations(search_term text, p_districts character varying[] DEFAULT NULL::character varying[], p_city_cluster bigint DEFAULT NULL::bigint) RETURNS TABLE(id uuid, name text, full_address text, street_number integer, street_name text, district text, city text, lat double precision, lon double precision, tags text[], city_cluster bigint)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.full_address,
        l.street_number,
        l.street_name,
        l.district,
        l.city,
        l.lat,
        l.lon,
        l.tags,
        l.city_cluster
    FROM public.location l
    WHERE
        (p_city_cluster IS NULL OR l.city_cluster = p_city_cluster)
        AND (
            (
                char_length(search_term) >= 8 AND (
                    extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))) > 0.3
                    OR extensions.word_similarity(LOWER(search_term), LOWER(l.name)) > 0.3
                    OR extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
                    OR extensions.word_similarity(LOWER(search_term), LOWER(l.full_address)) > 0.3
                )
            )
            OR (
                char_length(search_term) >= 2 AND (
                    extensions.unaccent(LOWER(l.name)) LIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
                    OR extensions.unaccent(LOWER(COALESCE(l.full_address, ''))) LIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
                )
            )
            OR (p_districts IS NOT NULL AND cardinality(p_districts) > 0 AND l.district = ANY(p_districts))
        )
    ORDER BY
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.full_address))
        ) DESC,
        l.name ASC
    LIMIT 60;
END;
$$;

-- ── 4a. create_lobby_with_location: drop the free-text params ─────────
DROP FUNCTION IF EXISTS public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid, p_location_name text, p_street_number text, p_street_name text, p_district text, p_city text);

CREATE FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text DEFAULT 'discoverable'::text, p_playtime jsonb DEFAULT NULL::jsonb, p_details jsonb DEFAULT NULL::jsonb, p_home_ground_id uuid DEFAULT NULL::uuid) RETURNS jsonb
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

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, home_ground, captain_id)
    VALUES (
        p_name,
        p_sport_id,
        p_visibility::public.lobby_visibility,
        p_playtime,
        p_details,
        p_home_ground_id,
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

ALTER FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO anon;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.create_lobby_with_location(p_name text, p_sport_id integer, p_visibility text, p_playtime jsonb, p_details jsonb, p_home_ground_id uuid) TO service_role;

-- ── 4b. create_freeplay_activity: drop the free-venue params ──────────
DROP FUNCTION IF EXISTS public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid, p_venue_name text, p_street_address text, p_city_cluster bigint, p_ward text);

CREATE FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text DEFAULT ''::text, p_location_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); v_host uuid; v_activity uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT id INTO v_host FROM public.freeplay_host WHERE user_id=v_uid AND status='active';
  IF v_host IS NULL THEN RAISE EXCEPTION 'active Host profile required'; END IF;
  IF p_sport_id NOT BETWEEN 1 AND 5 OR p_end_time <= p_start_time OR p_end_time <= now() THEN
    RAISE EXCEPTION 'invalid activity terms';
  END IF;
  IF p_location_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM public.location WHERE id = p_location_id) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  INSERT INTO public.activity(user_id,sport_id,start_time,end_time,location_id,freeplay_host_id)
  VALUES(v_uid,p_sport_id,p_start_time,p_end_time,p_location_id,v_host) RETURNING id INTO v_activity;
  INSERT INTO public.freeplay_activity(activity_id,description,capacity,male_price,female_price,recommended_skills)
  VALUES(v_activity,coalesce(p_description,''),p_capacity,p_male_price,p_female_price,p_recommended_skills);
  RETURN v_activity;
END
$$;

ALTER FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.create_freeplay_activity(p_sport_id bigint, p_start_time timestamp with time zone, p_end_time timestamp with time zone, p_capacity integer, p_male_price numeric, p_female_price numeric, p_recommended_skills text[], p_description text, p_location_id uuid) TO service_role;

-- NOTE: freeplay_activity.venue_name/street_address/city_cluster/ward are
-- deliberately NOT dropped here — half a dozen read-side RPCs
-- (freeplay_activity_detail_data, freeplay_host_data,
-- freeplay_host_management_data, freeplay_host_open_data,
-- freeplay_my_data, home_freeplay_data, postable_activities,
-- fn_notification_presentation) each `coalesce(loc.name, fa.venue_name)` /
-- `coalesce(loc.full_address, fa.street_address)` to stay compatible with
-- pre-migration rows that have no location_id. Since create_freeplay_activity
-- no longer writes those columns, every new row has location_id set and the
-- coalesce always resolves from `loc.name`/`loc.full_address` first — the
-- fallback simply goes unused for new data without needing to touch those
-- other functions.

-- ── 4c. request_referee_booking: drop the custom-location param ───────
DROP FUNCTION IF EXISTS public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid, p_custom_location_name text);

CREATE FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text DEFAULT NULL::text, p_location_id uuid DEFAULT NULL::uuid, p_participant_user_ids uuid[] DEFAULT '{}'::uuid[], p_existing_package_id uuid DEFAULT NULL::uuid, p_create_package boolean DEFAULT false, p_activity_id uuid DEFAULT NULL::uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_role public.professional_role;
    v_linked_user_id uuid;
    v_sports bigint[];
    v_service_sport bigint;
    v_price_amount numeric;
    v_pricing_kind text;
    v_min_duration integer;
    v_max_participants integer;
    v_session_count integer;
    v_participants uuid[] := COALESCE(p_participant_user_ids, '{}'::uuid[]);
    v_participant_count integer;
    v_agreed_rate numeric(10, 2);
    v_package_total numeric(10, 2);
    v_package_id uuid := p_existing_package_id;
    v_package record;
    v_booking_id uuid;
    v_activity record;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'request_referee_booking: authentication required';
    END IF;
    IF p_end <= p_start THEN
        RAISE EXCEPTION 'request_referee_booking: end must be after start';
    END IF;
    IF p_start <= now() THEN
        RAISE EXCEPTION 'request_referee_booking: start must be in the future';
    END IF;

    SELECT p.professional_role, p.linked_user_id, p.sports,
           s.sport_id, s.price_amount, s.pricing_kind,
           s.min_duration_minutes, COALESCE(s.max_participants, 1),
           s.session_count
    INTO v_role, v_linked_user_id, v_sports,
         v_service_sport, v_price_amount, v_pricing_kind,
         v_min_duration, v_max_participants, v_session_count
    FROM public.professional_service s
    JOIN public.professional p ON p.id = s.professional_id
    WHERE s.id = p_service_id
      AND s.professional_id = p_professional_id
      AND s.is_active
      AND p.is_verified;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'request_referee_booking: service is unavailable';
    END IF;
    IF v_linked_user_id = v_uid THEN
        RAISE EXCEPTION 'request_referee_booking: professionals cannot book themselves';
    END IF;
    IF NOT (v_sports @> ARRAY[v_service_sport]::bigint[]) THEN
        RAISE EXCEPTION 'request_referee_booking: service sport is not offered by professional';
    END IF;
    IF v_min_duration IS NOT NULL
       AND p_end - p_start < make_interval(mins => v_min_duration) THEN
        RAISE EXCEPTION 'request_referee_booking: duration is below service minimum';
    END IF;
    IF p_location_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.location location WHERE location.id = p_location_id
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: location not found';
    END IF;
    IF v_role <> 'referee' THEN
        RAISE EXCEPTION 'request_referee_booking: only referees can be booked';
    END IF;

    IF cardinality(v_participants) <> (
        SELECT count(DISTINCT participant.participant_id)
        FROM unnest(v_participants) AS participant(participant_id)
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: duplicate participants';
    END IF;
    IF v_uid = ANY(v_participants) THEN
        RAISE EXCEPTION 'request_referee_booking: client cannot be an additional participant';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM unnest(v_participants) AS participant(participant_id)
        LEFT JOIN public."user" u ON u.id = participant.participant_id
        WHERE u.id IS NULL
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: participant not found';
    END IF;

    v_participant_count := cardinality(v_participants) + 1;
    IF v_participant_count > v_max_participants THEN
        RAISE EXCEPTION 'request_referee_booking: participant limit exceeded';
    END IF;

    IF v_price_amount IS NOT NULL THEN
        v_agreed_rate := CASE v_pricing_kind
            WHEN 'hourly' THEN round(
                v_price_amount * (extract(epoch FROM (p_end - p_start)) / 3600.0),
                2
            )
            WHEN 'per_session' THEN v_price_amount
            ELSE NULL
        END;
        v_package_total := round(v_agreed_rate * v_session_count, 2);
    END IF;

    IF v_package_id IS NOT NULL OR p_create_package THEN
        RAISE EXCEPTION 'request_referee_booking: packages are not supported';
    END IF;

    INSERT INTO public.referee_booking (
        client_user_id, professional_id, service_id, location_id,
        booking_time_start, booking_time_end,
        agreed_rate, status, client_notes
    ) VALUES (
        v_uid, p_professional_id, p_service_id, p_location_id,
        p_start, p_end,
        v_agreed_rate, 'requested', NULLIF(btrim(p_notes), '')
    )
    RETURNING id INTO v_booking_id;

    IF cardinality(v_participants) > 0 THEN
        INSERT INTO public.referee_booking_additional_users (booking_id, user_id)
        SELECT v_booking_id, participant.participant_id
        FROM unnest(v_participants) AS participant(participant_id);
    END IF;

    IF p_activity_id IS NOT NULL THEN
        SELECT a.id, a.lobby_id, a.sport_id, a.referee_booking_id
        INTO v_activity
        FROM public.activity a
        WHERE a.id = p_activity_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'request_referee_booking: activity not found';
        END IF;
        IF v_activity.lobby_id IS NULL
           OR NOT public.lobby_can_manage(v_activity.lobby_id) THEN
            RAISE EXCEPTION 'request_referee_booking: caller cannot manage activity';
        END IF;
        IF v_activity.sport_id <> v_service_sport THEN
            RAISE EXCEPTION 'request_referee_booking: activity sport does not match service';
        END IF;

        IF v_activity.referee_booking_id IS NOT NULL THEN
            RAISE EXCEPTION 'request_referee_booking: activity already has a referee booking';
        END IF;
        UPDATE public.activity
        SET referee_booking_id = v_booking_id
        WHERE id = p_activity_id;
    END IF;

    RETURN v_booking_id;
END;
$$;

ALTER FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) OWNER TO postgres;

GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text, p_location_id uuid, p_participant_user_ids uuid[], p_existing_package_id uuid, p_create_package boolean, p_activity_id uuid) TO service_role;

-- Drop the now-unused custom-location column (and its CHECK constraint).
ALTER TABLE public.referee_booking
    DROP COLUMN custom_location_name;

-- ── 4d. fn_notification_presentation: drop the one dead fallback ──────
-- Identical to the existing function body, with only the
-- referee_booking.custom_location_name fallback removed (that column is
-- dropped by this migration). The freeplay_activity venue-column fallbacks
-- are untouched — see the note above §4c on why those columns and their
-- read-side fallbacks stay as-is.
CREATE OR REPLACE FUNCTION public.fn_notification_presentation(p_kind public.notification_kind, p_data jsonb, p_body text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_lobby_id       uuid;
    v_activity_id    uuid;
    v_booking_id     uuid;
    v_challenge_id   uuid;
    v_record_id      uuid;
    v_request_id     uuid;
    v_feed_item_id   uuid;
    v_user_id        uuid;
    v_lobby_name     text;
    v_username       text;
    v_location_name  text;
    v_address        text;
    v_amount         text;
    v_start_time     timestamptz;
    v_weekday        text;
    v_time           text;
begin
    v_lobby_id     := nullif(p_data->>'lobby_id', '')::uuid;
    v_activity_id  := nullif(coalesce(p_data->>'activity_id',
                                      case when p_kind = 'activity_confirmed'
                                           then p_data->>'target_id' end), '')::uuid;
    v_booking_id   := nullif(coalesce(p_data->>'booking_id',
                                      case when p_kind = 'pro_session_reminder'
                                           then p_data->>'target_id' end), '')::uuid;
    v_challenge_id := nullif(p_data->>'challenge_id', '')::uuid;
    v_record_id    := nullif(p_data->>'record_id', '')::uuid;
    v_request_id   := nullif(p_data->>'request_id', '')::uuid;
    v_feed_item_id := nullif(p_data->>'feed_item_id', '')::uuid;
    v_user_id      := nullif(p_data->>'user_id', '')::uuid;

    -- Challenge copy names the other lobby, while lobby_id routes into the
    -- recipient's own lobby. Resolve that perspective once, at enqueue time.
    if p_kind in ('challenger_confirmed', 'challenge_received',
                  'challenge_declined', 'challenge_scheduled',
                  'challenge_lapsed', 'match_result_recorded')
       and v_challenge_id is not null then
        select case when c.initiator_lobby_id = v_lobby_id then target.name
                    else initiator.name end,
               c.proposed_time,
               loc.name,
               loc.full_address,
               case when c.agreed_cost is null then null
                    else c.agreed_cost::text || 'đ' end
          into v_lobby_name, v_start_time, v_location_name, v_address, v_amount
          from public.lobby_challenge c
          join public.lobby initiator on initiator.id = c.initiator_lobby_id
          join public.lobby target on target.id = c.target_lobby_id
          left join public.location loc on loc.id = c.proposed_location
         where c.id = v_challenge_id;
    elsif v_lobby_id is not null then
        select l.name into v_lobby_name
          from public.lobby l where l.id = v_lobby_id;
    end if;

    if v_activity_id is not null then
        select coalesce(v_start_time, a.start_time),
               coalesce(v_location_name, loc.name, fa.venue_name),
               coalesce(v_address, loc.full_address, fa.street_address),
               coalesce(v_lobby_name, l.name)
          into v_start_time, v_location_name, v_address, v_lobby_name
          from public.activity a
          left join public.lobby l on l.id = a.lobby_id
          left join public.location loc on loc.id = a.location_id
          left join public.freeplay_activity fa on fa.activity_id = a.id
         where a.id = v_activity_id;
    end if;

    if v_booking_id is not null then
        select b.booking_time_start,
               loc.name,
               loc.full_address,
               case when b.agreed_rate is null then null
                    else b.agreed_rate::text || 'đ' end
          into v_start_time, v_location_name, v_address, v_amount
          from public.referee_booking b
          left join public.location loc on loc.id = b.location_id
         where b.id = v_booking_id;
    end if;

    if p_kind = 'lobby_invite' and v_record_id is not null then
        select r.initiator_user_id, coalesce(v_lobby_id, r.target_lobby_id)
          into v_user_id, v_lobby_id
          from public.lobby_befriend_record r where r.id = v_record_id;
        if v_lobby_name is null then
            select l.name into v_lobby_name
              from public.lobby l where l.id = v_lobby_id;
        end if;
    end if;

    if v_request_id is not null then
        select coalesce(v_user_id, r.user_id), coalesce(v_activity_id, r.activity_id),
               case when r.price_amount is null then null
                    else r.price_amount::text || 'đ' end
          into v_user_id, v_activity_id, v_amount
          from public.freeplay_request r where r.id = v_request_id;
    end if;

    -- A freeplay request is itself what supplies activity_id, so resolve its
    -- venue only after loading the request above.
    if v_request_id is not null and v_activity_id is not null then
        select coalesce(v_start_time, a.start_time),
               coalesce(v_location_name, loc.name, fa.venue_name),
               coalesce(v_address, loc.full_address, fa.street_address)
          into v_start_time, v_location_name, v_address
          from public.activity a
          left join public.location loc on loc.id = a.location_id
          left join public.freeplay_activity fa on fa.activity_id = a.id
         where a.id = v_activity_id;
    end if;

    if v_user_id is not null then
        select u.username || '#' || u.tag_number into v_username
          from public."user" u where u.id = v_user_id;
    end if;

    if v_feed_item_id is not null and v_amount is null then
        select case when f.payload->>'per_person_amount' is null then null
                    else (f.payload->>'per_person_amount') || 'đ' end,
               coalesce(v_lobby_name, l.name)
          into v_amount, v_lobby_name
          from public.lobby_feed_item f
          left join public.lobby l on l.id = f.lobby_id
         where f.id = v_feed_item_id;
    end if;

    if v_start_time is not null then
        v_time := to_char(
            v_start_time at time zone 'Asia/Ho_Chi_Minh',
            'HH24:MI'
        );
        v_weekday := case extract(isodow from v_start_time at time zone 'Asia/Ho_Chi_Minh')
            when 1 then 'thứ Hai'
            when 2 then 'thứ Ba'
            when 3 then 'thứ Tư'
            when 4 then 'thứ Năm'
            when 5 then 'thứ Sáu'
            when 6 then 'thứ Bảy'
            when 7 then 'Chủ Nhật'
        end;
    end if;

    -- Only retain values literally present in the body. This prevents title-
    -- only metadata and generic routing context from being treated as body
    -- emphasis, while preserving an exact, non-regex client contract.
    return jsonb_strip_nulls(jsonb_build_object(
        'lobby_name',    case when strpos(p_body, v_lobby_name) > 0 then v_lobby_name end,
        'username',      case when strpos(p_body, v_username) > 0 then v_username end,
        'weekday',       case when strpos(p_body, v_weekday) > 0 then v_weekday end,
        'time',          case when strpos(p_body, v_time) > 0 then v_time end,
        'amount',        case when strpos(p_body, v_amount) > 0 then v_amount end,
        'location_name', case when strpos(p_body, v_location_name) > 0 then v_location_name end,
        'address',       case when strpos(p_body, v_address) > 0 then v_address end
    ));
exception
    when invalid_text_representation then
        -- Malformed optional routing metadata must never prevent the push.
        return '{}'::jsonb;
end;
$$;
