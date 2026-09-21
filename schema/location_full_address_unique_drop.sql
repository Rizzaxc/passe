-- `location_full_address_key UNIQUE (full_address)` is a blocker for any bulk
-- venue import, and was never a correct constraint in the first place.
--
-- `full_address` holds a Nominatim reverse-geocode string, not an identity.
-- Two real, distinct venues legitimately share one — courts inside a single
-- complex ("Nhà thi đấu Phú Thọ, 219 Lý Thường Kiệt, …" describes a badminton
-- hall and a swimming pool), and Nominatim coarsens to the street when it has
-- nothing finer, so an entire alley's worth of pitches collapses to one string.
-- The constraint has survived only because the original scrape happened to
-- produce distinct strings; the moment a second source (OSM re-scrape, curated
-- seed) inserts, it hard-fails the whole statement. It is also a second
-- conflict target fighting the real idempotency key, `external_id`.
--
-- Identity is `external_id` (unique, namespaced) and, failing that, proximity +
-- name similarity resolved in the importer. Keep an index for lookup speed;
-- drop the uniqueness.

ALTER TABLE public.location DROP CONSTRAINT IF EXISTS location_full_address_key;

CREATE INDEX IF NOT EXISTS idx_location_full_address
    ON public.location (full_address);
