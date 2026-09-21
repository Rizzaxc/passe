-- Groundwork for the lat/lon → ward backfill of `location.district`.
--
-- Today `location.district` is free text from the original scrape holding
-- three incompatible things at once: the pre-2025 quận label ("Quận 7", 436
-- HCMC / 676 Hanoi rows), a prefixed ward name ("Phường Thảo Điền", 425 + 13),
-- and blank (132 + 363). The filter can only compare with `=`, so more than
-- half of HCMC's venues are unreachable by any ward selection no matter how
-- many rows we add. Coordinates, by contrast, are good on 2,047 of 2,050 rows
-- — so the fix is to derive the ward geometrically and write the canonical
-- `District.id` into `district`.
--
-- This migration is the additive, reversible half. The backfill itself is data
-- and runs from `tool/venue/` (see that README), not from here.

-- ── 1. Snapshot the pre-normalization value ────────────────────────────
-- Makes the in-place overwrite reversible with a single UPDATE, and keeps the
-- legacy quận label available as a display/grouping label and as a second
-- filter target (the client sends both forms — see `feed_controller.dart`).
ALTER TABLE public.location
    ADD COLUMN IF NOT EXISTS district_legacy text;

UPDATE public.location
   SET district_legacy = district
 WHERE district_legacy IS NULL;

COMMENT ON COLUMN public.location.district_legacy IS
    'Pre-normalization value of `district` as the original scrape stored it '
    '(a "Quận X" label, a "Phường Y" label, or blank). Kept for reversibility '
    'and as a coarse legacy filter target. `district` itself is the canonical '
    'ward id (`District.id`) once the tool/venue backfill has run.';

-- ── 2. Make `external_id` usable as the import idempotency key ──────────
-- `external_id` is already UNIQUE, but the values are BARE OSM element ids
-- with no type prefix ("227442844"), which are ambiguous: the same integer can
-- name a node, a way and a relation. Our "227442844" is a Hanoi volleyball
-- pitch; OSM's node/227442844 is an unrelated untagged node. So the id alone
-- cannot be matched against a fresh Overpass pull.
--
-- Type resolution needs a live OSM lookup per id, so it is deliberately NOT
-- done here — the importer does it on its first write, once its dry run has
-- established which ids still resolve and to what. What this migration does is
-- the type-independent part: give the 3 rows with a NULL external_id a stable
-- key so every row has one, and record the convention.
UPDATE public.location
   SET external_id = 'legacy:' || id::text
 WHERE external_id IS NULL;

COMMENT ON COLUMN public.location.external_id IS
    'Import idempotency key, namespaced: `osm:<type>/<id>` for OpenStreetMap '
    'elements, `passe:<city>-<slug>` for the hand-curated seed, '
    '`legacy:<uuid>` for pre-existing rows with no resolvable upstream id, and '
    'NULL for rows created by `create_location` (user submissions, which the '
    'importer never overwrites). Bare numeric values are un-renamespaced rows '
    'from the original scrape, pending the tool/venue import.';
