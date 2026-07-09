-- Accept/reject for the professional side of a booking. Plain client UPDATEs already work under
-- the existing "Linked professionals can manage their bookings" RLS policy for the reject path, but
-- accept needs an atomic overlap check (two clients could request the same slot before either is
-- confirmed) that a bare UPDATE can't express — hence a validated SECURITY DEFINER function for
-- both, for symmetry.
--
-- No counter-proposing a different time — accept confirms the exact requested slot, reject is
-- final (the client re-books a different time from scratch). Reject reason is optional free text
-- (client_notes/professional_notes columns already exist). No request expiry.
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for review, not
-- auto-applied.

CREATE OR REPLACE FUNCTION public.accept_professional_booking(p_booking_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_professional_id uuid;
    v_start timestamptz;
    v_end timestamptz;
BEGIN
    SELECT pb.professional_id, pb.booking_time_start, pb.booking_time_end
    INTO v_professional_id, v_start, v_end
    FROM public.professional_booking pb
    WHERE pb.id = p_booking_id;

    IF v_professional_id IS NULL THEN
        RAISE EXCEPTION 'accept_professional_booking: booking % not found', p_booking_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.professional p
        WHERE p.id = v_professional_id AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'accept_professional_booking: caller is not the linked professional';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.professional_booking pb2
        WHERE pb2.professional_id = v_professional_id
          AND pb2.id <> p_booking_id
          AND pb2.status = 'confirmed'
          AND pb2.booking_time_start < v_end
          AND pb2.booking_time_end > v_start
    ) THEN
        RAISE EXCEPTION 'accept_professional_booking: overlaps another confirmed booking';
    END IF;

    UPDATE public.professional_booking
    SET status = 'confirmed'
    WHERE id = p_booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_professional_booking(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.reject_professional_booking(
    p_booking_id uuid,
    p_reason text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_professional_id uuid;
BEGIN
    SELECT pb.professional_id INTO v_professional_id
    FROM public.professional_booking pb
    WHERE pb.id = p_booking_id;

    IF v_professional_id IS NULL THEN
        RAISE EXCEPTION 'reject_professional_booking: booking % not found', p_booking_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.professional p
        WHERE p.id = v_professional_id AND p.linked_user_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'reject_professional_booking: caller is not the linked professional';
    END IF;

    UPDATE public.professional_booking
    SET status = 'rejected',
        professional_notes = p_reason
    WHERE id = p_booking_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reject_professional_booking(uuid, text) TO authenticated;
