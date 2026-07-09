-- Increments professional_booking_package.sessions_used when the session against it completes.
-- This is what the client uses to decide (a) whether to prompt for the next session in a rolling
-- package, and (b) whether a completed session is the *last* one in its package (review-eligible)
-- — review eligibility for package bookings only applies to the final session, not every one.

CREATE OR REPLACE FUNCTION public.fn_increment_package_sessions_used()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    IF NEW.package_id IS NOT NULL THEN
        UPDATE public.professional_booking_package
        SET sessions_used = sessions_used + 1,
            updated_at = now()
        WHERE id = NEW.package_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER professional_booking_increment_package_progress
    AFTER UPDATE ON public.professional_booking
    FOR EACH ROW
    WHEN (NEW.status = 'completed' AND OLD.status IS DISTINCT FROM 'completed'
          AND NEW.package_id IS NOT NULL)
    EXECUTE FUNCTION public.fn_increment_package_sessions_used();
