-- ============================================================================
-- referee_booking_rename.sql — Part C of the coaching rework.
-- Apply AFTER course_enums.sql / course.sql.
--
-- `professional_booking` was the single engagement table for BOTH hireable
-- roles. Coaching has moved to courses, so what's left is refereeing — and the
-- table is renamed to say so.
--
-- This is deliberately NOT a delete. A scored challenge match requires a
-- referee booking (`lobby_match_referee_required_for_scored_challenge`), and
-- that CHECK is what gates `fn_apply_match_rating` — the only writer of live
-- ELO in the app. Dropping the table would silently take the rating system
-- with it.
--
-- What actually goes away here is the **coach** half:
--   * `professional_booking_package` (coach lesson packages — courses carry a
--     target session count instead, and courses have no money at all)
--   * `activity.coach_booking_id` and `activity.professional_booking_id`
--     (a coach lesson is now an ordinary course `activity`)
--   * the coach branch of the attachment role-check
--
-- Renaming a table does NOT rewrite the function bodies that reference it —
-- prosrc is stored as text and re-parsed at call time — so every dependent
-- function is re-emitted below against the new name. The mechanical ones were
-- generated from the live catalogue; the ones whose *meaning* changes
-- (schedule, health, wall posts, reminders, attachment guard) are rewritten by
-- hand in schema/coach_booking_fallout.sql.
--
-- Client entry points for referee hiring are gated behind
-- `ClientFeatureFlags.refereeFlow` (the same `ENABLE_CHALLENGER_FLOW` define
-- as the challenger flow) — refereeing is iced, not deleted.
--
-- Idempotent / re-runnable. Needs to be applied to the live Supabase project.
-- ============================================================================

-- ── 1. Coach-only objects go ────────────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_increment_package_sessions_used ON public.professional_booking;
DROP FUNCTION IF EXISTS public.fn_increment_package_sessions_used() CASCADE;
DROP TABLE IF EXISTS public.professional_booking_package CASCADE;

-- ── 2. Rename ───────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF to_regclass('public.professional_booking') IS NOT NULL
     AND to_regclass('public.referee_booking') IS NULL THEN
    ALTER TABLE public.professional_booking RENAME TO referee_booking;
  END IF;

  IF to_regclass('public.professional_booking_review') IS NOT NULL
     AND to_regclass('public.referee_booking_review') IS NULL THEN
    ALTER TABLE public.professional_booking_review RENAME TO referee_booking_review;
  END IF;

  IF to_regclass('public.booking_additional_users') IS NOT NULL
     AND to_regclass('public.referee_booking_additional_users') IS NULL THEN
    ALTER TABLE public.booking_additional_users
      RENAME TO referee_booking_additional_users;
  END IF;
END$$;

-- Coach attachment columns. `referee_booking_id` stays — it is the challenge
-- flow's link to the official who records the result.
--
-- The attachment policy names `coach_booking_id`, so it has to go first;
-- section 3 re-creates it referee-only.
DROP POLICY IF EXISTS "Linked professionals can view their attached activities"
  ON public.activity;

-- The attachment trigger is declared `UPDATE OF coach_booking_id, ...`, so it
-- depends on the column too. coach_booking_fallout.sql re-creates it
-- referee-only.
DROP TRIGGER IF EXISTS activity_attachment_role_check ON public.activity;

ALTER TABLE public.activity DROP COLUMN IF EXISTS coach_booking_id;
ALTER TABLE public.activity DROP COLUMN IF EXISTS professional_booking_id;

ALTER TABLE public.activity DROP CONSTRAINT IF EXISTS activity_source_exclusivity;
ALTER TABLE public.activity ADD CONSTRAINT activity_source_exclusivity CHECK (
  num_nonnulls(lobby_id, freeplay_host_id, course_id) <= 1
);

-- Referee-only from here on: a coach must never end up with a booking row
-- again, or the two systems would quietly overlap.
CREATE OR REPLACE FUNCTION public.fn_referee_booking_role_check()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.professional p
    WHERE p.id = NEW.professional_id AND p.professional_role = 'referee'
  ) THEN
    RAISE EXCEPTION 'referee_booking.professional_id % must reference a referee', NEW.professional_id;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_referee_booking_role_check ON public.referee_booking;
CREATE TRIGGER trg_referee_booking_role_check
  BEFORE INSERT OR UPDATE OF professional_id ON public.referee_booking
  FOR EACH ROW EXECUTE FUNCTION public.fn_referee_booking_role_check();

-- ── 3. Policies ─────────────────────────────────────────────────────────────
-- Policies follow their table through a rename, but the ones whose bodies name
-- another renamed table have to be re-emitted.

DROP POLICY IF EXISTS "Linked professionals can view their attached activities" ON public.activity;
CREATE POLICY "Linked professionals can view their attached activities"
ON public.activity FOR SELECT TO authenticated
USING (
  referee_booking_id IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.referee_booking pb
    JOIN public.professional pr ON pr.id = pb.professional_id
    WHERE pb.id = activity.referee_booking_id
      AND pr.linked_user_id = (SELECT auth.uid())
  )
);

DROP POLICY IF EXISTS "Clients can view additional users for their bookings"
  ON public.referee_booking_additional_users;
CREATE POLICY "Clients can view additional users for their bookings"
ON public.referee_booking_additional_users FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.referee_booking pb
    WHERE pb.id = referee_booking_additional_users.booking_id
      AND pb.client_user_id = (SELECT auth.uid())
  )
);

DROP POLICY IF EXISTS "Linked professionals can view their bookings" ON public.referee_booking;
CREATE POLICY "Linked professionals can view their bookings"
ON public.referee_booking FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.professional p
    WHERE p.id = referee_booking.professional_id
      AND p.linked_user_id = (SELECT auth.uid())
  )
);

DROP POLICY IF EXISTS "Clients can create reviews for their completed bookings"
  ON public.referee_booking_review;
CREATE POLICY "Clients can create reviews for their completed bookings"
ON public.referee_booking_review FOR INSERT TO authenticated
WITH CHECK (
  reviewer_user_id = (SELECT auth.uid())
  AND EXISTS (
    SELECT 1 FROM public.referee_booking pb
    WHERE pb.id = referee_booking_review.booking_id
      AND pb.client_user_id = (SELECT auth.uid())
      AND pb.professional_id = referee_booking_review.professional_id
      AND pb.status = 'completed'::public.professional_booking_status
  )
);

-- ── 4. Dependent functions (mechanical rename, generated from the catalogue) ─

CREATE OR REPLACE FUNCTION public.request_referee_booking(p_professional_id uuid, p_service_id uuid, p_start timestamp with time zone, p_end timestamp with time zone, p_notes text DEFAULT NULL::text, p_location_id uuid DEFAULT NULL::uuid, p_participant_user_ids uuid[] DEFAULT '{}'::uuid[], p_existing_package_id uuid DEFAULT NULL::uuid, p_create_package boolean DEFAULT false, p_activity_id uuid DEFAULT NULL::uuid, p_custom_location_name text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
        RAISE EXCEPTION 'request_referee_booking: authentication required';
    END IF;
    IF p_end <= p_start THEN
        RAISE EXCEPTION 'request_referee_booking: end must be after start';
    END IF;
    IF p_start <= now() THEN
        RAISE EXCEPTION 'request_referee_booking: start must be in the future';
    END IF;
    IF v_custom_location_name IS NOT NULL
       AND char_length(v_custom_location_name) > 200 THEN
        RAISE EXCEPTION 'request_referee_booking: custom location is too long';
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
    IF p_location_id IS NOT NULL AND v_custom_location_name IS NOT NULL THEN
        RAISE EXCEPTION 'request_referee_booking: choose a saved or custom location, not both';
    END IF;
    IF p_location_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.location location WHERE location.id = p_location_id
    ) THEN
        RAISE EXCEPTION 'request_referee_booking: location not found';
    END IF;
    -- Only referees can be booked now; a coach relationship is a course.
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

    -- Packages were a coach concept (a block of lessons paid up front) and
    -- went with `professional_booking_package`. A referee books one match at a
    -- time. The parameters survive only so an older client build gets a clear
    -- error instead of silently having them ignored.
    IF v_package_id IS NOT NULL OR p_create_package THEN
        RAISE EXCEPTION 'request_referee_booking: packages are not supported';
    END IF;

    INSERT INTO public.referee_booking (
        client_user_id, professional_id, service_id, location_id,
        custom_location_name, booking_time_start, booking_time_end,
        agreed_rate, status, client_notes
    ) VALUES (
        v_uid, p_professional_id, p_service_id, p_location_id,
        v_custom_location_name, p_start, p_end,
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
$function$;

CREATE OR REPLACE FUNCTION public.accept_referee_booking(p_booking_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'accept_referee_booking: authentication required';
    END IF;

    SELECT pb.professional_id, pb.status,
           pb.booking_time_start, pb.booking_time_end
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'accept_referee_booking: booking % not found', p_booking_id;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.professional p
        WHERE p.id = v_booking.professional_id
          AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'accept_referee_booking: caller is not the linked professional';
    END IF;
    IF v_booking.status <> 'requested' OR v_booking.booking_time_start <= now() THEN
        RAISE EXCEPTION 'accept_referee_booking: request is no longer actionable';
    END IF;

    PERFORM pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(v_booking.professional_id::text, 0)
    );

    IF EXISTS (
        SELECT 1
        FROM public.referee_booking pb2
        WHERE pb2.professional_id = v_booking.professional_id
          AND pb2.id <> p_booking_id
          AND pb2.status = 'confirmed'
          AND pb2.booking_time_start < v_booking.booking_time_end
          AND pb2.booking_time_end > v_booking.booking_time_start
    ) THEN
        RAISE EXCEPTION 'accept_referee_booking: overlaps another confirmed booking';
    END IF;

    UPDATE public.referee_booking
    SET status = 'confirmed'
    WHERE id = p_booking_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reject_referee_booking(p_booking_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'reject_referee_booking: authentication required';
    END IF;

    SELECT pb.professional_id, pb.status
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'reject_referee_booking: booking % not found', p_booking_id;
    END IF;
    IF NOT EXISTS (
        SELECT 1
        FROM public.professional p
        WHERE p.id = v_booking.professional_id
          AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'reject_referee_booking: caller is not the linked professional';
    END IF;
    IF v_booking.status <> 'requested' THEN
        RAISE EXCEPTION 'reject_referee_booking: request is no longer actionable';
    END IF;

    UPDATE public.referee_booking
    SET status = 'rejected',
        professional_notes = NULLIF(btrim(p_reason), '')
    WHERE id = p_booking_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_referee_booking(p_booking_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'cancel_referee_booking: authentication required';
    END IF;

    SELECT pb.client_user_id, pb.status, pb.booking_time_start
    INTO v_booking
    FROM public.referee_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND OR v_booking.client_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'cancel_referee_booking: booking not found';
    END IF;
    IF v_booking.status NOT IN ('requested', 'confirmed')
       OR (v_booking.status = 'confirmed'
           AND v_booking.booking_time_start <= now()) THEN
        RAISE EXCEPTION 'cancel_referee_booking: invalid status transition';
    END IF;

    UPDATE public.referee_booking
    SET status = 'cancelled_by_client'
    WHERE id = p_booking_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.complete_referee_booking(p_booking_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_booking record;
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'complete_referee_booking: authentication required';
    END IF;

    SELECT pb.client_user_id, pb.professional_id, pb.status, pb.booking_time_end,
           p.linked_user_id
    INTO v_booking
    FROM public.referee_booking pb
    JOIN public.professional p ON p.id = pb.professional_id
    WHERE pb.id = p_booking_id
    FOR UPDATE OF pb;

    IF NOT FOUND
       OR (v_booking.client_user_id <> auth.uid()
           AND v_booking.linked_user_id <> auth.uid()) THEN
        RAISE EXCEPTION 'complete_referee_booking: booking not found';
    END IF;
    IF v_booking.status <> 'confirmed' OR v_booking.booking_time_end > now() THEN
        RAISE EXCEPTION 'complete_referee_booking: invalid status transition';
    END IF;

    UPDATE public.referee_booking
    SET status = 'completed'
    WHERE id = p_booking_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.referee_booking_conflicts(p_professional_id uuid, p_start timestamp with time zone, p_end timestamp with time zone)
 RETURNS TABLE(id uuid, booking_time_start timestamp with time zone, booking_time_end timestamp with time zone)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
    SELECT pb.id, pb.booking_time_start, pb.booking_time_end
    FROM public.referee_booking pb
    WHERE pb.professional_id = p_professional_id
      AND pb.status = 'confirmed'
      AND pb.booking_time_start < p_end
      AND pb.booking_time_end > p_start;
$function$;

CREATE OR REPLACE FUNCTION public.fn_notify_referee_booking_created()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_professional_user_id uuid;
    v_client_name text;
BEGIN
    SELECT linked_user_id INTO v_professional_user_id
    FROM public.professional
    WHERE id = NEW.professional_id;

    IF v_professional_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT u.username INTO v_client_name
    FROM public."user" u WHERE u.id = NEW.client_user_id;

    PERFORM public.fn_enqueue_notification(
        'professional_booking_requested',
        ARRAY[v_professional_user_id],
        COALESCE(v_client_name, 'Một học viên') || ' vừa gửi yêu cầu đặt lịch',
        'Chạm để xem chi tiết và xác nhận',
        jsonb_build_object('booking_id', NEW.id)
    );

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_notify_referee_booking_status_changed()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_professional_name text;
BEGIN
    SELECT display_name INTO v_professional_name
    FROM public.professional WHERE id = NEW.professional_id;

    IF NEW.status = 'confirmed' THEN
        PERFORM public.fn_enqueue_notification(
            'professional_booking_confirmed',
            ARRAY[NEW.client_user_id],
            COALESCE(v_professional_name, 'Chuyên gia') || ' đã xác nhận lịch hẹn',
            'Buổi tập của bạn đã được xác nhận',
            jsonb_build_object('booking_id', NEW.id)
        );
    ELSIF NEW.status = 'rejected' THEN
        PERFORM public.fn_enqueue_notification(
            'professional_booking_rejected',
            ARRAY[NEW.client_user_id],
            COALESCE(v_professional_name, 'Chuyên gia') || ' đã từ chối yêu cầu đặt lịch',
            COALESCE(NEW.professional_notes, 'Bạn có thể thử đặt một khung giờ khác'),
            jsonb_build_object('booking_id', NEW.id)
        );
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_guard_referee_booking_review()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_booking record;
BEGIN
    SELECT pb.client_user_id, pb.professional_id, pb.status, pb.package_id
    INTO v_booking
    FROM public.referee_booking pb
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
$function$;

CREATE OR REPLACE FUNCTION public.referee_booking_review_updated_trigger_fn()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.referee_booking_review
                WHERE professional_id = NEW.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.referee_booking_review
                WHERE professional_id = NEW.professional_id
            )
        WHERE id = NEW.professional_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.professional
        SET
            average_rating = (
                SELECT COALESCE(AVG(rating), 0.00)
                FROM public.referee_booking_review
                WHERE professional_id = OLD.professional_id
            ),
            review_count = (
                SELECT COUNT(*)
                FROM public.referee_booking_review
                WHERE professional_id = OLD.professional_id
            )
        WHERE id = OLD.professional_id;
    END IF;
    RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.fn_complete_referee_booking_on_match()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
    IF NEW.referee_booking_id IS NOT NULL THEN
        UPDATE public.referee_booking
        SET status = 'completed'
        WHERE id = NEW.referee_booking_id
          AND status = 'confirmed';
    END IF;
    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.lobby_match_referee_role_check()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
DECLARE
    booked_role public.professional_role;
BEGIN
    IF NEW.referee_booking_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT p.professional_role
        INTO booked_role
        FROM public.referee_booking pb
                 JOIN public.professional p ON p.id = pb.professional_id
        WHERE pb.id = NEW.referee_booking_id;

    IF booked_role IS DISTINCT FROM 'referee' THEN
        RAISE EXCEPTION
            'lobby_match.referee_booking_id must reference a booking whose professional is a referee (got: %)',
            booked_role;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.lobby_match_history_data(p_lobby_id uuid, p_page_size integer DEFAULT 50, p_page_number integer DEFAULT 1)
 RETURNS TABLE(id uuid, activity_id uuid, opponent_lobby_id uuid, opponent_name text, opponent_tag text, result lobby_match_result, sets jsonb, mvp_username character varying, note text, venue_label text, played_at timestamp with time zone, duration_label text, member_usernames text[], referee_booking_id uuid, referee_name text)
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
BEGIN
    RETURN QUERY
    WITH mine AS (
        SELECT m.*, false AS flipped, m.opponent_lobby_id AS other_id
          FROM public.lobby_match m
         WHERE m.lobby_id = p_lobby_id
        UNION ALL
        SELECT m.*, true AS flipped, m.lobby_id AS other_id
          FROM public.lobby_match m
         WHERE m.opponent_lobby_id = p_lobby_id
    )
    SELECT x.id,
           x.activity_id,
           x.other_id AS opponent_lobby_id,
           ol.name::text AS opponent_name,
           (CASE WHEN x.flipped THEN COALESCE(ol.name, x.opponent_tag) ELSE x.opponent_tag END)::text,
           CASE WHEN NOT x.flipped THEN x.result
                WHEN x.result = 'win'  THEN 'loss'::public.lobby_match_result
                WHEN x.result = 'loss' THEN 'win'::public.lobby_match_result
                ELSE x.result END AS result,
           CASE WHEN NOT x.flipped OR x.sets IS NULL THEN x.sets
                ELSE (SELECT jsonb_agg(jsonb_build_array(s->1, s->0))
                        FROM jsonb_array_elements(x.sets) s) END AS sets,
           u.username AS mvp_username,
           x.note,
           x.venue_label,
           x.played_at,
           x.duration_label,
           ARRAY(
               SELECT mu.username::text
                 FROM public.lobby_member lm
                 JOIN public."user" mu ON mu.id = lm.user_id
                WHERE lm.lobby_id = p_lobby_id
           ) AS member_usernames,
           x.referee_booking_id,
           ref.display_name AS referee_name
      FROM mine x
      LEFT JOIN public.lobby ol ON ol.id = x.other_id
      LEFT JOIN public."user" u ON u.id = x.mvp_user_id
      LEFT JOIN public.referee_booking rb ON rb.id = x.referee_booking_id
      LEFT JOIN public.professional ref ON ref.id = rb.professional_id
     ORDER BY x.played_at DESC
     LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$function$;

CREATE OR REPLACE FUNCTION public.record_challenge_match(p_challenge_id uuid, p_result text, p_sets jsonb DEFAULT NULL::jsonb, p_mvp_user_id uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_uid        uuid := auth.uid();
    v_home       uuid;
    v_away       uuid;
    v_status     public.lobby_challenge_status;
    v_home_act   uuid;
    v_end        timestamptz;
    v_start      timestamptz;
    v_ref_book   uuid;
    v_venue      text;
    v_match      uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_result NOT IN ('win', 'loss', 'draw') THEN
        RAISE EXCEPTION 'invalid result %', p_result;
    END IF;

    SELECT target_lobby_id, initiator_lobby_id, status
      INTO v_home, v_away, v_status
      FROM public.lobby_challenge WHERE id = p_challenge_id;
    IF v_home IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF v_status = 'played' THEN RAISE EXCEPTION 'this match already has a result'; END IF;
    IF v_status NOT IN ('accepted', 'scheduled') THEN
        RAISE EXCEPTION 'challenge is not in a playable state';
    END IF;

    SELECT a.id, a.start_time, a.end_time, a.referee_booking_id
      INTO v_home_act, v_start, v_end, v_ref_book
      FROM public.activity a
     WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_home;

    IF v_ref_book IS NULL THEN
        SELECT a.referee_booking_id INTO v_ref_book
          FROM public.activity a
         WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_away
           AND a.referee_booking_id IS NOT NULL;
    END IF;
    IF v_ref_book IS NULL THEN
        RAISE EXCEPTION 'no referee is booked for this match';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM public.referee_booking pb
          JOIN public.professional pr ON pr.id = pb.professional_id
         WHERE pb.id = v_ref_book AND pr.linked_user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'only the booked referee can record this result';
    END IF;

    IF COALESCE(v_end, v_start) > now() THEN
        RAISE EXCEPTION 'the match has not finished yet';
    END IF;

    SELECT loc.name INTO v_venue
      FROM public.activity a
      LEFT JOIN public.location loc ON loc.id = a.location_id
     WHERE a.id = v_home_act;

    INSERT INTO public.lobby_match
        (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result, sets,
         mvp_user_id, note, venue_label, played_at, referee_booking_id)
    VALUES (v_home, v_home_act, v_away,
            COALESCE((SELECT name FROM public.lobby WHERE id = v_away), '—'),
            p_result::public.lobby_match_result, p_sets,
            p_mvp_user_id, p_note, COALESCE(v_venue, '—'),
            COALESCE(v_start, now()), v_ref_book)
    RETURNING id INTO v_match;

    UPDATE public.lobby_challenge
       SET status = 'played', updated_at = now() WHERE id = p_challenge_id;

    PERFORM public.fn_enqueue_notification(
        'match_result_recorded',
        ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_home),
        'Kết quả trận đấu',
        'Trọng tài đã ghi nhận kết quả trận thách đấu',
        jsonb_build_object('lobby_id', v_home, 'challenge_id', p_challenge_id));
    PERFORM public.fn_enqueue_notification(
        'match_result_recorded',
        ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_away),
        'Kết quả trận đấu',
        'Trọng tài đã ghi nhận kết quả trận thách đấu',
        jsonb_build_object('lobby_id', v_away, 'challenge_id', p_challenge_id));

    RETURN v_match;
END;
$function$;

