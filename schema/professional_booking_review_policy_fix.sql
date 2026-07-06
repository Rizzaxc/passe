-- Bug fix: `professional_booking_status_check` on `professional_booking` is
-- `CHECK (status <> 'completed')` — a blanket constraint that forbids ANY row from
-- ever being set to `completed`, via INSERT or UPDATE, by anyone (CHECK constraints are
-- enforced unconditionally; RLS/SECURITY DEFINER can't bypass them). But the review
-- policy below required exactly `status = 'completed'` to insert a review — a condition
-- that can never be satisfied. The review flow was unreachable dead policy.
--
-- Fix: gate reviews on "confirmed and the session's end time has passed" instead of an
-- explicit completed handshake — the natural signal that a session actually happened,
-- given nothing in the client ever flips a booking to `completed`. This does not touch
-- the CHECK constraint or existing data, only swaps the INSERT policy.
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for
-- review, not auto-applied.

DROP POLICY IF EXISTS "Clients can create reviews for their completed bookings" ON public.professional_booking_review;

CREATE POLICY "Clients can create reviews for past confirmed bookings" ON public.professional_booking_review
    FOR INSERT TO authenticated
    WITH CHECK (
        reviewer_user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.professional_booking pb
            WHERE pb.id = professional_booking_review.booking_id
              AND pb.client_user_id = (SELECT auth.uid())
              AND pb.status = 'confirmed'
              AND pb.booking_time_end < now()
        )
    );
