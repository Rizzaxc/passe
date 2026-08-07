-- A confirmed lesson can only be cancelled by its client before it starts.
-- Requested lessons may still be withdrawn after their proposed time so stale
-- requests can be cleaned up.

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

    SELECT pb.client_user_id, pb.status, pb.booking_time_start
    INTO v_booking
    FROM public.professional_booking pb
    WHERE pb.id = p_booking_id
    FOR UPDATE;

    IF NOT FOUND OR v_booking.client_user_id <> auth.uid() THEN
        RAISE EXCEPTION 'cancel_professional_booking: booking not found';
    END IF;
    IF v_booking.status NOT IN ('requested', 'confirmed')
       OR (v_booking.status = 'confirmed'
           AND v_booking.booking_time_start <= now()) THEN
        RAISE EXCEPTION 'cancel_professional_booking: invalid status transition';
    END IF;

    UPDATE public.professional_booking
    SET status = 'cancelled_by_client'
    WHERE id = p_booking_id;
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_professional_booking(uuid)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_professional_booking(uuid)
    TO authenticated;
