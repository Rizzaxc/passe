-- Availability conflict checking. Soft-blocks in the booking sheet (a client can still submit an
-- overlapping request — RLS already allows that, same as today), hard-blocked at accept time by
-- `accept_professional_booking` (schema/professional_booking_actions.sql), since only a *confirmed*
-- booking should ever exclude another.
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for review, not
-- auto-applied.

CREATE OR REPLACE FUNCTION public.professional_booking_conflicts(
    p_professional_id uuid,
    p_start timestamptz,
    p_end timestamptz
) RETURNS TABLE(
    id uuid,
    booking_time_start timestamptz,
    booking_time_end timestamptz
)
    LANGUAGE sql
    STABLE
    SET search_path TO ''
    AS $$
    SELECT pb.id, pb.booking_time_start, pb.booking_time_end
    FROM public.professional_booking pb
    WHERE pb.professional_id = p_professional_id
      AND pb.status = 'confirmed'
      AND pb.booking_time_start < p_end
      AND pb.booking_time_end > p_start;
$$;

GRANT EXECUTE ON FUNCTION public.professional_booking_conflicts(uuid, timestamptz, timestamptz)
    TO authenticated;
