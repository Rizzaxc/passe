-- Bug fix: `professional_booking_status_check` (`CHECK (status <> 'completed')`) made the
-- `completed` status permanently unreachable — the review flow had to fake "done" via
-- "confirmed and past end time" instead (see `schema/professional_booking_review_policy_fix.sql`).
-- This drops the stale constraint and gives `completed` a real meaning:
--   - Coach bookings: either the client or the linked professional taps "mark complete" once the
--     session's end time has passed — first tap wins, no mutual confirmation. Both already have
--     unrestricted UPDATE rights on their own bookings via the existing "Clients can manage their
--     own bookings" / "Linked professionals can manage their bookings" policies, so no new RLS is
--     needed here — only the CHECK constraint was blocking it.
--   - Referee bookings: completion is derived from match recording, not a manual tap — a trigger
--     on `lobby_match` flips the referenced `professional_booking` to `completed` when a match
--     citing it is inserted.
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for review, not
-- auto-applied.

ALTER TABLE public.professional_booking
    DROP CONSTRAINT professional_booking_status_check;

CREATE OR REPLACE FUNCTION public.fn_complete_professional_booking_on_match()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    IF NEW.referee_booking_id IS NOT NULL THEN
        UPDATE public.professional_booking
        SET status = 'completed'
        WHERE id = NEW.referee_booking_id
          AND status = 'confirmed';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER lobby_match_complete_referee_booking
    AFTER INSERT ON public.lobby_match
    FOR EACH ROW
    WHEN (NEW.referee_booking_id IS NOT NULL)
    EXECUTE FUNCTION public.fn_complete_professional_booking_on_match();

-- Revert the review-policy workaround now that `completed` is reachable: gate reviews on the real
-- status instead of "confirmed and the session's end time has passed".
DROP POLICY IF EXISTS "Clients can create reviews for past confirmed bookings" ON public.professional_booking_review;
DROP POLICY IF EXISTS "Clients can create reviews for their completed bookings" ON public.professional_booking_review;

CREATE POLICY "Clients can create reviews for their completed bookings" ON public.professional_booking_review
    FOR INSERT TO authenticated
    WITH CHECK (
        reviewer_user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.professional_booking pb
            WHERE pb.id = professional_booking_review.booking_id
              AND pb.client_user_id = (SELECT auth.uid())
              AND pb.status = 'completed'
        )
    );
