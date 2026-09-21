-- Allow `source = 'curated'` alongside 'directory' and 'user_submitted'.
--
-- 'directory' means "arrived in a bulk third-party import of unknown quality"
-- — which is the entire reason the venue overhaul exists (20% of those rows
-- are nameless, 26% of the HCMC ones are actually in Đồng Nai/Bình Dương).
-- Hand-verified venues folded into 'directory' would destroy the one signal
-- that says a human confirmed this place is real and is where we claim it is,
-- which is exactly what ranking and fallback want to read.
--
-- No client change: `source` is not part of the Dart `Location` model.

ALTER TABLE public.location DROP CONSTRAINT location_source_check;

ALTER TABLE public.location ADD CONSTRAINT location_source_check
    CHECK (source IN ('directory', 'user_submitted', 'curated'));
