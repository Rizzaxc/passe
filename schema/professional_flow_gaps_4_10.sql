-- Remaining professional-flow hardening and contract cleanup:
--   * explicit hourly/per-session pricing
--   * booking-scoped free-text locations
--   * one review per rolling package

-- ---------------------------------------------------------------------------
-- Pricing: replace the ambiguous hourly_rate + package pricing_mode pair with
-- one amount and one billing kind. Existing per_session rows were historically
-- calculated as hourly, so they migrate to hourly. A legacy wholesale package
-- is converted to an equivalent per-session amount to preserve its total.
-- ---------------------------------------------------------------------------

ALTER TABLE public.professional_service
    RENAME COLUMN hourly_rate TO price_amount;
ALTER TABLE public.professional_service
    RENAME COLUMN pricing_mode TO pricing_kind;

ALTER TABLE public.professional_service
    DROP CONSTRAINT IF EXISTS professional_service_hourly_rate_check;
ALTER TABLE public.professional_service
    DROP CONSTRAINT IF EXISTS professional_service_pricing_mode_check;

UPDATE public.professional_service
SET price_amount = CASE
        WHEN pricing_kind = 'wholesale' AND session_count > 1
            THEN round(price_amount / session_count, 2)
        ELSE price_amount
    END,
    pricing_kind = CASE
        WHEN pricing_kind = 'wholesale' THEN 'per_session'
        ELSE 'hourly'
    END;

ALTER TABLE public.professional_service
    ALTER COLUMN pricing_kind SET DEFAULT 'hourly',
    ADD CONSTRAINT professional_service_price_amount_check
        CHECK (price_amount >= 0),
    ADD CONSTRAINT professional_service_pricing_kind_check
        CHECK (pricing_kind IN ('hourly', 'per_session'));

COMMENT ON COLUMN public.professional_service.price_amount IS
    'Advertised amount charged according to pricing_kind.';
COMMENT ON COLUMN public.professional_service.pricing_kind IS
    'hourly scales price_amount by session duration; per_session is a fixed session price.';

-- ---------------------------------------------------------------------------
-- A client-suggested free-text venue belongs to one booking, not the shared
-- venue directory. Existing location rows continue to use location_id.
-- ---------------------------------------------------------------------------

ALTER TABLE public.professional_booking
    ADD COLUMN custom_location_name text,
    ADD CONSTRAINT professional_booking_custom_location_name_check
        CHECK (
            custom_location_name IS NULL
            OR (char_length(btrim(custom_location_name)) BETWEEN 1 AND 200)
        );

COMMENT ON COLUMN public.professional_booking.custom_location_name IS
    'Client-suggested booking-scoped venue when no canonical location row is selected.';

-- ---------------------------------------------------------------------------
-- Reviews: copy the booking package onto the review and use a partial unique
-- index for race-safe one-review-per-package enforcement.
-- ---------------------------------------------------------------------------

ALTER TABLE public.professional_booking_review
    ADD COLUMN package_id uuid,
    ADD CONSTRAINT professional_booking_review_package_id_fkey
        FOREIGN KEY (package_id)
        REFERENCES public.professional_booking_package(id)
        ON DELETE RESTRICT;

UPDATE public.professional_booking_review review
SET package_id = booking.package_id
FROM public.professional_booking booking
WHERE booking.id = review.booking_id
  AND booking.package_id IS NOT NULL;

CREATE UNIQUE INDEX professional_booking_review_one_per_package
    ON public.professional_booking_review (package_id)
    WHERE package_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.fn_guard_professional_booking_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_booking record;
BEGIN
    SELECT pb.client_user_id, pb.professional_id, pb.status, pb.package_id
    INTO v_booking
    FROM public.professional_booking pb
    WHERE pb.id = NEW.booking_id;

    IF NOT FOUND
       OR NEW.reviewer_user_id <> v_booking.client_user_id
       OR NEW.professional_id <> v_booking.professional_id
       OR v_booking.status <> 'completed' THEN
        RAISE EXCEPTION 'professional_booking_review: booking attribution is invalid';
    END IF;

    NEW.package_id := v_booking.package_id;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_guard_professional_booking_review()
    FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Atomic booking request, updated for explicit pricing and custom locations.
-- ---------------------------------------------------------------------------

DROP FUNCTION public.request_professional_booking(
    uuid, uuid, timestamptz, timestamptz, text, uuid, uuid[], uuid, boolean, uuid
);

CREATE FUNCTION public.request_professional_booking(
    p_professional_id uuid,
    p_service_id uuid,
    p_start timestamptz,
    p_end timestamptz,
    p_notes text DEFAULT NULL,
    p_location_id uuid DEFAULT NULL,
    p_participant_user_ids uuid[] DEFAULT '{}'::uuid[],
    p_existing_package_id uuid DEFAULT NULL,
    p_create_package boolean DEFAULT false,
    p_activity_id uuid DEFAULT NULL,
    p_custom_location_name text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
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
    v_custom_location_name text := NULLIF(btrim(p_custom_location_name), '');
    v_package record;
    v_booking_id uuid;
    v_activity record;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'request_professional_booking: authentication required';
    END IF;
    IF p_end <= p_start THEN
        RAISE EXCEPTION 'request_professional_booking: end must be after start';
    END IF;
    IF p_start <= now() THEN
        RAISE EXCEPTION 'request_professional_booking: start must be in the future';
    END IF;
    IF v_custom_location_name IS NOT NULL
       AND char_length(v_custom_location_name) > 200 THEN
        RAISE EXCEPTION 'request_professional_booking: custom location is too long';
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
        RAISE EXCEPTION 'request_professional_booking: service is unavailable';
    END IF;
    IF v_linked_user_id = v_uid THEN
        RAISE EXCEPTION 'request_professional_booking: professionals cannot book themselves';
    END IF;
    IF NOT (v_sports @> ARRAY[v_service_sport]::bigint[]) THEN
        RAISE EXCEPTION 'request_professional_booking: service sport is not offered by professional';
    END IF;
    IF v_min_duration IS NOT NULL
       AND p_end - p_start < make_interval(mins => v_min_duration) THEN
        RAISE EXCEPTION 'request_professional_booking: duration is below service minimum';
    END IF;
    IF p_location_id IS NOT NULL AND v_custom_location_name IS NOT NULL THEN
        RAISE EXCEPTION 'request_professional_booking: choose a saved or custom location, not both';
    END IF;
    IF p_location_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.location location WHERE location.id = p_location_id
    ) THEN
        RAISE EXCEPTION 'request_professional_booking: location not found';
    END IF;
    IF v_role = 'coach'
       AND p_location_id IS NULL
       AND v_custom_location_name IS NULL THEN
        RAISE EXCEPTION 'request_professional_booking: coach bookings require a location';
    END IF;

    IF cardinality(v_participants) <> (
        SELECT count(DISTINCT participant.participant_id)
        FROM unnest(v_participants) AS participant(participant_id)
    ) THEN
        RAISE EXCEPTION 'request_professional_booking: duplicate participants';
    END IF;
    IF v_uid = ANY(v_participants) THEN
        RAISE EXCEPTION 'request_professional_booking: client cannot be an additional participant';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM unnest(v_participants) AS participant(participant_id)
        LEFT JOIN public."user" u ON u.id = participant.participant_id
        WHERE u.id IS NULL
    ) THEN
        RAISE EXCEPTION 'request_professional_booking: participant not found';
    END IF;

    v_participant_count := cardinality(v_participants) + 1;
    IF v_participant_count > v_max_participants THEN
        RAISE EXCEPTION 'request_professional_booking: participant limit exceeded';
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

    IF v_package_id IS NOT NULL THEN
        IF p_create_package THEN
            RAISE EXCEPTION 'request_professional_booking: choose an existing or new package, not both';
        END IF;

        SELECT * INTO v_package
        FROM public.professional_booking_package pkg
        WHERE pkg.id = v_package_id
        FOR UPDATE;

        IF NOT FOUND
           OR v_package.client_user_id <> v_uid
           OR v_package.professional_id <> p_professional_id
           OR v_package.service_id <> p_service_id
           OR v_package.status <> 'active'
           OR v_package.sessions_used >= v_package.sessions_total THEN
            RAISE EXCEPTION 'request_professional_booking: package is unavailable';
        END IF;
        IF EXISTS (
            SELECT 1
            FROM public.professional_booking pb
            WHERE pb.package_id = v_package_id
              AND pb.status IN ('requested', 'confirmed')
        ) THEN
            RAISE EXCEPTION 'request_professional_booking: package already has an active session';
        END IF;

        -- The package total was agreed on its first booking; later sessions
        -- must not look like a new charge at the professional's current rate.
        v_agreed_rate := NULL;
    ELSIF p_create_package THEN
        IF v_session_count <= 1 THEN
            RAISE EXCEPTION 'request_professional_booking: service is not a package';
        END IF;

        INSERT INTO public.professional_booking_package (
            client_user_id, professional_id, service_id,
            sessions_total, total_price, status
        ) VALUES (
            v_uid, p_professional_id, p_service_id,
            v_session_count, v_package_total, 'active'
        )
        RETURNING id INTO v_package_id;
    ELSIF v_session_count > 1 THEN
        RAISE EXCEPTION 'request_professional_booking: package service requires a package';
    END IF;

    INSERT INTO public.professional_booking (
        client_user_id, professional_id, service_id, location_id,
        custom_location_name, booking_time_start, booking_time_end,
        agreed_rate, status, client_notes, package_id
    ) VALUES (
        v_uid, p_professional_id, p_service_id, p_location_id,
        v_custom_location_name, p_start, p_end,
        v_agreed_rate, 'requested', NULLIF(btrim(p_notes), ''), v_package_id
    )
    RETURNING id INTO v_booking_id;

    IF cardinality(v_participants) > 0 THEN
        INSERT INTO public.booking_additional_users (booking_id, user_id)
        SELECT v_booking_id, participant.participant_id
        FROM unnest(v_participants) AS participant(participant_id);
    END IF;

    IF p_activity_id IS NOT NULL THEN
        SELECT a.id, a.lobby_id, a.sport_id,
               a.coach_booking_id, a.referee_booking_id
        INTO v_activity
        FROM public.activity a
        WHERE a.id = p_activity_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'request_professional_booking: activity not found';
        END IF;
        IF v_activity.lobby_id IS NULL
           OR NOT public.lobby_can_manage(v_activity.lobby_id) THEN
            RAISE EXCEPTION 'request_professional_booking: caller cannot manage activity';
        END IF;
        IF v_activity.sport_id <> v_service_sport THEN
            RAISE EXCEPTION 'request_professional_booking: activity sport does not match service';
        END IF;

        IF v_role = 'coach' THEN
            IF v_activity.coach_booking_id IS NOT NULL THEN
                RAISE EXCEPTION 'request_professional_booking: activity already has a coach booking';
            END IF;
            UPDATE public.activity
            SET coach_booking_id = v_booking_id
            WHERE id = p_activity_id;
        ELSE
            IF v_activity.referee_booking_id IS NOT NULL THEN
                RAISE EXCEPTION 'request_professional_booking: activity already has a referee booking';
            END IF;
            UPDATE public.activity
            SET referee_booking_id = v_booking_id
            WHERE id = p_activity_id;
        END IF;
    END IF;

    RETURN v_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.request_professional_booking(
    uuid, uuid, timestamptz, timestamptz, text, uuid, uuid[], uuid, boolean,
    uuid, text
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_professional_booking(
    uuid, uuid, timestamptz, timestamptz, text, uuid, uuid[], uuid, boolean,
    uuid, text
) TO authenticated;

-- ---------------------------------------------------------------------------
-- Discovery returns the kind paired with the selected cheapest amount so the
-- client never labels a per-session amount as hourly.
-- ---------------------------------------------------------------------------

DROP FUNCTION public.home_professional_data(
    bigint, jsonb, integer, text[], text, integer, integer
);

CREATE FUNCTION public.home_professional_data(
    p_sport_id bigint,
    p_timeslots jsonb DEFAULT '{}'::jsonb,
    p_city integer DEFAULT NULL,
    p_districts text[] DEFAULT NULL,
    p_search text DEFAULT NULL,
    p_page_size integer DEFAULT 20,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid,
    display_name text,
    professional_role public.professional_role,
    bio text,
    sports bigint[],
    experience_years integer,
    average_rating numeric,
    review_count integer,
    is_verified boolean,
    price_from numeric,
    price_from_kind text,
    timeslot_compat_score integer
)
LANGUAGE plpgsql
STABLE
SET search_path TO ''
AS $$
BEGIN
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
            SELECT p.id, p.display_name::text, p.professional_role, p.bio,
                   p.sports, p.experience_years, p.average_rating,
                   p.review_count, p.is_verified,
                   price.price_amount, price.pricing_kind,
                   COALESCE(ts.ts_score, 0)
            FROM public.professional p
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                    p_timeslots,
                    public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
                ) AS ts_score
            ) ts
            LEFT JOIN LATERAL (
                SELECT ps.price_amount, ps.pricing_kind
                FROM public.professional_service ps
                WHERE ps.professional_id = p.id
                  AND ps.sport_id = p_sport_id
                  AND ps.is_active
                ORDER BY ps.price_amount NULLS LAST, ps.created_at, ps.id
                LIMIT 1
            ) price ON true
            WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
              AND (
                  p.display_name ILIKE '%' || p_search || '%'
                  OR extensions.unaccent(p.display_name)
                     ILIKE '%' || extensions.unaccent(p_search) || '%'
              )
            ORDER BY p.is_verified DESC, p.average_rating DESC,
                     p.review_count DESC
            LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    RETURN QUERY
        SELECT p.id, p.display_name::text, p.professional_role, p.bio,
               p.sports, p.experience_years, p.average_rating,
               p.review_count, p.is_verified,
               price.price_amount, price.pricing_kind,
               COALESCE(ts.ts_score, 0)
        FROM public.professional p
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                p_timeslots,
                public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
            ) AS ts_score
        ) ts
        LEFT JOIN LATERAL (
            SELECT ps.price_amount, ps.pricing_kind
            FROM public.professional_service ps
            WHERE ps.professional_id = p.id
              AND ps.sport_id = p_sport_id
              AND ps.is_active
            ORDER BY ps.price_amount NULLS LAST, ps.created_at, ps.id
            LIMIT 1
        ) price ON true
        WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
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
        ORDER BY p.is_verified DESC, p.average_rating DESC,
                 p.review_count DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

REVOKE ALL ON FUNCTION public.home_professional_data(
    bigint, jsonb, integer, text[], text, integer, integer
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.home_professional_data(
    bigint, jsonb, integer, text[], text, integer, integer
) TO anon, authenticated, service_role;
