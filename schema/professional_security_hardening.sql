-- Harden the professional/coach flow against client-controlled state, pricing,
-- verification, and review attribution.
--
-- This migration intentionally replaces broad ALL policies with operation-
-- specific policies and moves booking writes behind validated RPCs. RLS scopes
-- rows; column privileges keep linked professionals from changing admin-owned
-- fields on their public profile.

-- ---------------------------------------------------------------------------
-- 1. Professional profiles: linked users may edit only the self-service fields.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Linked users can manage their own professional profile"
    ON public.professional;

CREATE POLICY "Linked users can update their own professional details"
    ON public.professional
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = linked_user_id)
    WITH CHECK ((SELECT auth.uid()) = linked_user_id);

REVOKE INSERT, UPDATE, DELETE ON TABLE public.professional FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.professional FROM authenticated;
GRANT UPDATE (bio, contact_details, schedule, schedule_note)
    ON TABLE public.professional TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. Booking/package/participant rows: reads stay row-scoped; writes go
--    through the RPCs below so status, price, ownership, and relationships are
--    validated atomically.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Clients can manage their own bookings"
    ON public.professional_booking;
DROP POLICY IF EXISTS "Linked professionals can manage their bookings"
    ON public.professional_booking;

CREATE POLICY "Clients can view their own bookings"
    ON public.professional_booking
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = client_user_id);

CREATE POLICY "Linked professionals can view their bookings"
    ON public.professional_booking
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.professional p
            WHERE p.id = professional_booking.professional_id
              AND p.linked_user_id = (SELECT auth.uid())
        )
    );

REVOKE INSERT, UPDATE, DELETE ON TABLE public.professional_booking FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.professional_booking FROM authenticated;
GRANT SELECT ON TABLE public.professional_booking TO authenticated;

DROP POLICY IF EXISTS "Clients can manage their own booking packages"
    ON public.professional_booking_package;

CREATE POLICY "Clients can view their own booking packages"
    ON public.professional_booking_package
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = client_user_id);

REVOKE INSERT, UPDATE, DELETE ON TABLE public.professional_booking_package FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.professional_booking_package FROM authenticated;
GRANT SELECT ON TABLE public.professional_booking_package TO authenticated;

DROP POLICY IF EXISTS "Client can manage additional users for their bookings"
    ON public.booking_additional_users;

CREATE POLICY "Clients can view additional users for their bookings"
    ON public.booking_additional_users
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.professional_booking pb
            WHERE pb.id = booking_additional_users.booking_id
              AND pb.client_user_id = (SELECT auth.uid())
        )
    );

REVOKE INSERT, UPDATE, DELETE ON TABLE public.booking_additional_users FROM anon;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.booking_additional_users FROM authenticated;
GRANT SELECT ON TABLE public.booking_additional_users TO authenticated;

CREATE OR REPLACE FUNCTION public.request_professional_booking(
    p_professional_id uuid,
    p_service_id uuid,
    p_start timestamptz,
    p_end timestamptz,
    p_notes text DEFAULT NULL,
    p_location_id uuid DEFAULT NULL,
    p_participant_user_ids uuid[] DEFAULT '{}'::uuid[],
    p_existing_package_id uuid DEFAULT NULL,
    p_create_package boolean DEFAULT false,
    p_activity_id uuid DEFAULT NULL
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
    v_hourly_rate numeric;
    v_min_duration integer;
    v_max_participants integer;
    v_session_count integer;
    v_pricing_mode text;
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
        RAISE EXCEPTION 'request_professional_booking: authentication required';
    END IF;
    IF p_end <= p_start THEN
        RAISE EXCEPTION 'request_professional_booking: end must be after start';
    END IF;
    IF p_start <= now() THEN
        RAISE EXCEPTION 'request_professional_booking: start must be in the future';
    END IF;

    SELECT p.professional_role, p.linked_user_id, p.sports,
           s.sport_id, s.hourly_rate, s.min_duration_minutes,
           COALESCE(s.max_participants, 1), s.session_count, s.pricing_mode
    INTO v_role, v_linked_user_id, v_sports,
         v_service_sport, v_hourly_rate, v_min_duration,
         v_max_participants, v_session_count, v_pricing_mode
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
    IF v_role = 'coach' AND p_location_id IS NULL THEN
        RAISE EXCEPTION 'request_professional_booking: coach bookings require a location';
    END IF;
    IF p_location_id IS NOT NULL AND NOT EXISTS (
        SELECT 1
        FROM public.professional_preferred_location ppl
        WHERE ppl.professional_id = p_professional_id
          AND ppl.location_id = p_location_id
    ) THEN
        RAISE EXCEPTION 'request_professional_booking: location is not offered by professional';
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

    IF v_hourly_rate IS NOT NULL THEN
        IF v_pricing_mode = 'wholesale' THEN
            v_agreed_rate := v_hourly_rate;
            v_package_total := v_hourly_rate;
        ELSE
            v_agreed_rate := round(
                v_hourly_rate
                * (extract(epoch FROM (p_end - p_start)) / 3600.0)
                * CASE WHEN v_max_participants > 1 THEN v_participant_count ELSE 1 END,
                2
            );
            v_package_total := round(v_agreed_rate * v_session_count, 2);
        END IF;
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
        booking_time_start, booking_time_end, agreed_rate,
        status, client_notes, package_id
    ) VALUES (
        v_uid, p_professional_id, p_service_id, p_location_id,
        p_start, p_end, v_agreed_rate,
        'requested', NULLIF(btrim(p_notes), ''), v_package_id
    )
    RETURNING id INTO v_booking_id;

    IF cardinality(v_participants) > 0 THEN
        INSERT INTO public.booking_additional_users (booking_id, user_id)
        SELECT v_booking_id, participant.participant_id
        FROM unnest(v_participants) AS participant(participant_id);
    END IF;

    IF p_activity_id IS NOT NULL THEN
        SELECT a.id, a.user_id, a.lobby_id, a.sport_id,
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
    uuid, uuid, timestamptz, timestamptz, text, uuid, uuid[], uuid, boolean, uuid
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_professional_booking(
    uuid, uuid, timestamptz, timestamptz, text, uuid, uuid[], uuid, boolean, uuid
) TO authenticated;

CREATE OR REPLACE FUNCTION public.cancel_professional_booking(p_booking_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'cancel_professional_booking: authentication required';
    END IF;

    SELECT pb.client_user_id, pb.status
    INTO v_booking
    FROM public.professional_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND OR v_booking.client_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'cancel_professional_booking: booking not found';
    END IF;
    IF v_booking.status NOT IN ('requested', 'confirmed') THEN
        RAISE EXCEPTION 'cancel_professional_booking: invalid status transition';
    END IF;

    UPDATE public.professional_booking
    SET status = 'cancelled_by_client'
    WHERE id = p_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_professional_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_professional_booking(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.complete_professional_booking(p_booking_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'complete_professional_booking: authentication required';
    END IF;

    SELECT pb.client_user_id, pb.professional_id, pb.status, pb.booking_time_end,
           p.linked_user_id
    INTO v_booking
    FROM public.professional_booking pb
    JOIN public.professional p ON p.id = pb.professional_id
    WHERE pb.id = p_booking_id
    FOR UPDATE OF pb;

    IF NOT FOUND
       OR (v_booking.client_user_id <> auth.uid()
           AND v_booking.linked_user_id <> auth.uid()) THEN
        RAISE EXCEPTION 'complete_professional_booking: booking not found';
    END IF;
    IF v_booking.status <> 'confirmed' OR v_booking.booking_time_end > now() THEN
        RAISE EXCEPTION 'complete_professional_booking: invalid status transition';
    END IF;

    UPDATE public.professional_booking
    SET status = 'completed'
    WHERE id = p_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_professional_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_professional_booking(uuid) TO authenticated;

-- Accept/reject remain professional-only, but now lock and validate the source
-- state so a stale request cannot resurrect a cancelled/completed booking.
CREATE OR REPLACE FUNCTION public.accept_professional_booking(p_booking_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'accept_professional_booking: authentication required';
    END IF;

    SELECT pb.professional_id, pb.status,
           pb.booking_time_start, pb.booking_time_end
    INTO v_booking
    FROM public.professional_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'accept_professional_booking: booking % not found', p_booking_id;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.professional p
        WHERE p.id = v_booking.professional_id
          AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'accept_professional_booking: caller is not the linked professional';
    END IF;
    IF v_booking.status <> 'requested' OR v_booking.booking_time_start <= now() THEN
        RAISE EXCEPTION 'accept_professional_booking: request is no longer actionable';
    END IF;

    PERFORM pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(v_booking.professional_id::text, 0)
    );

    IF EXISTS (
        SELECT 1
        FROM public.professional_booking pb2
        WHERE pb2.professional_id = v_booking.professional_id
          AND pb2.id <> p_booking_id
          AND pb2.status = 'confirmed'
          AND pb2.booking_time_start < v_booking.booking_time_end
          AND pb2.booking_time_end > v_booking.booking_time_start
    ) THEN
        RAISE EXCEPTION 'accept_professional_booking: overlaps another confirmed booking';
    END IF;

    UPDATE public.professional_booking
    SET status = 'confirmed'
    WHERE id = p_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_professional_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_professional_booking(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.reject_professional_booking(
    p_booking_id uuid,
    p_reason text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'reject_professional_booking: authentication required';
    END IF;

    SELECT pb.professional_id, pb.status
    INTO v_booking
    FROM public.professional_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'reject_professional_booking: booking % not found', p_booking_id;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.professional p
        WHERE p.id = v_booking.professional_id
          AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'reject_professional_booking: caller is not the linked professional';
    END IF;
    IF v_booking.status <> 'requested' THEN
        RAISE EXCEPTION 'reject_professional_booking: request is no longer actionable';
    END IF;

    UPDATE public.professional_booking
    SET status = 'rejected',
        professional_notes = NULLIF(btrim(p_reason), '')
    WHERE id = p_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.reject_professional_booking(uuid, text)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_professional_booking(uuid, text)
    TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Reviews: the reviewer, booking, and professional must describe the same
--    completed engagement. The trigger is defense in depth for every writer;
--    the RLS policy protects the exposed client insert path.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Clients can create reviews for past confirmed bookings"
    ON public.professional_booking_review;
DROP POLICY IF EXISTS "Clients can create reviews for their completed bookings"
    ON public.professional_booking_review;
DROP POLICY IF EXISTS "Clients can view their own booking reviews"
    ON public.professional_booking_review;

CREATE POLICY "Clients can create reviews for their completed bookings"
    ON public.professional_booking_review
    FOR INSERT TO authenticated
    WITH CHECK (
        reviewer_user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.professional_booking pb
            WHERE pb.id = professional_booking_review.booking_id
              AND pb.client_user_id = (SELECT auth.uid())
              AND pb.professional_id = professional_booking_review.professional_id
              AND pb.status = 'completed'
        )
    );

CREATE POLICY "Clients can view their own booking reviews"
    ON public.professional_booking_review
    FOR SELECT TO authenticated
    USING (reviewer_user_id = (SELECT auth.uid()));

REVOKE ALL ON TABLE public.professional_booking_review FROM anon;
REVOKE UPDATE, DELETE ON TABLE public.professional_booking_review FROM authenticated;
GRANT SELECT, INSERT ON TABLE public.professional_booking_review TO authenticated;

CREATE OR REPLACE FUNCTION public.fn_guard_professional_booking_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
DECLARE
    v_booking record;
BEGIN
    SELECT pb.client_user_id, pb.professional_id, pb.status
    INTO v_booking
    FROM public.professional_booking pb
    WHERE pb.id = NEW.booking_id;

    IF NOT FOUND
       OR NEW.reviewer_user_id <> v_booking.client_user_id
       OR NEW.professional_id <> v_booking.professional_id
       OR v_booking.status <> 'completed' THEN
        RAISE EXCEPTION 'professional_booking_review: booking attribution is invalid';
    END IF;

    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_guard_professional_booking_review()
    FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS professional_booking_review_guard
    ON public.professional_booking_review;
CREATE TRIGGER professional_booking_review_guard
    BEFORE INSERT OR UPDATE ON public.professional_booking_review
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_guard_professional_booking_review();
