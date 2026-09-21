-- Structured, SQL-filterable sport/amenity columns on `location`.
--
-- Venue sport-scoping is currently done CLIENT-side (`Location.matchesSport`
-- in `lib/core/model/location.dart`) because the raw `tags text[]` holds OSM
-- strings in a "key:[v1, v2]" shape that SQL cannot cleanly filter. The cost
-- is real: the feed fetches a flat `LIMIT 60` and then throws most of it away,
-- so a sport with thin coverage (badminton, pickleball) can render an empty
-- list while matching venues sit on page 2 that was never fetched.
--
-- These columns are populated by the importer (`tool/venue/normalize.py`), not
-- by a generated column: the OSM-value → Sport mapping is a curated dictionary
-- (`sport=football` means soccer, `multi`/`fitness`/`billiards` mean nothing to
-- us) that belongs in one place and shouldn't need a schema redeploy every time
-- OSM throws a new value. Raw `tags` is kept as the provenance record.
--
-- `sport_ids` mirrors the `professional.sports bigint[]` precedent and the
-- project-wide `Sport.index` ⇆ DB-id convention (others=0, soccer=1, …).

ALTER TABLE public.location
    ADD COLUMN IF NOT EXISTS sport_ids bigint[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS amenity_kinds text[] NOT NULL DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS has_declared_sport boolean NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_location_sport_ids
    ON public.location USING gin (sport_ids);

COMMENT ON COLUMN public.location.sport_ids IS
    'Passe sport ids this venue supports, derived from OSM tags by '
    'tool/venue/normalize.py. Empty means "no sport declared", which is NOT '
    'the same as "supports nothing" — see has_declared_sport.';

COMMENT ON COLUMN public.location.has_declared_sport IS
    'Whether the source data declared ANY sport, including sports Passe does '
    'not support (volleyball, swimming, …). This is what distinguishes '
    '"explicitly for a different sport" (hide) from "no sport info" (keep — '
    'could still be a general facility). Filters MUST read it: a bare '
    '`sport_ids && ARRAY[p_sport_id]` silently drops the 433 untagged rows '
    'that the client deliberately keeps today.';

COMMENT ON COLUMN public.location.amenity_kinds IS
    'Recognized facility kinds (pitch, sports_centre, stadium, swimming_pool, '
    'track), as `homeTab.location.amenity.<value>` translation-key suffixes.';
