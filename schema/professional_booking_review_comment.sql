-- Optional written comment alongside the existing half-star rating — star-only ratings are hard to
-- act on for other students browsing coaches; a short note is what actually drives discovery-page
-- trust. Kept nullable so the star-tap-and-go flow stays frictionless.
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for review, not
-- auto-applied.

ALTER TABLE public.professional_booking_review
    ADD COLUMN IF NOT EXISTS comment text;
