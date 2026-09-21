-- Move venue sport-scoping and ward matching into `search_locations`, and
-- give the client a single code path.
--
-- Four changes, each fixing something measured against prod:
--
-- 1. `p_sport_id` — sport filtering was CLIENT-side (`Location.matchesSport`),
--    applied AFTER a flat `LIMIT 60`. For a thin sport (badminton had 28 HCMC
--    venues, pickleball 14) that renders an empty list while matching venues
--    sit past the limit, never fetched.
--
-- 2. A match-all branch. With an empty `search_term` and no districts the old
--    WHERE matched NOTHING — which is the only reason `feed_controller.dart`
--    carried a second, direct `.from('location')` query. That second path
--    can't express the sport predicate cleanly, so it becomes one path here.
--
-- 3. Diacritic-insensitive district compare. `l.district = ANY(p_districts)`
--    is exact, so "Phường Thảo Điền" vs "Phường Thao Dien" silently dropped
--    rows. Both sides are unaccented here, so the client keeps sending the
--    labels it already sends — no client coupling.
--
-- 4. Out-of-footprint rows (the 263 Đồng Nai/Bình Dương venues filed under
--    city_cluster=1, marked is_verified=false by the importer) are hidden
--    when BROWSING but not when SEARCHING. If someone types a venue's name
--    they asked for it specifically; hiding it then is just a broken search.
--    User submissions are never hidden either way — `create_location` writes
--    is_verified=false for all of them, so a blanket verified-only filter
--    would break the manual-entry flow that location_provenance.sql exists
--    for.
--
-- Return-type change ⇒ DROP + CREATE; CREATE OR REPLACE cannot alter a
-- RETURNS TABLE shape.

DROP FUNCTION IF EXISTS public.search_locations(text, character varying[], bigint);

CREATE FUNCTION public.search_locations(
    search_term text,
    p_districts character varying[] DEFAULT NULL::character varying[],
    p_city_cluster bigint DEFAULT NULL::bigint,
    p_sport_id bigint DEFAULT NULL::bigint
) RETURNS TABLE(
    id uuid, name text, full_address text, street_number text, street_name text,
    district text, city text, lat double precision, lon double precision,
    tags text[], city_cluster bigint, sport_ids bigint[],
    has_declared_sport boolean, is_verified boolean, district_legacy text
)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
DECLARE
    v_term text := COALESCE(search_term, '');
    v_has_districts boolean := p_districts IS NOT NULL AND cardinality(p_districts) > 0;
    v_wards text[];
BEGIN
    IF v_has_districts THEN
        SELECT array_agg(extensions.unaccent(LOWER(x)))
          INTO v_wards
          FROM unnest(p_districts) AS x;
    END IF;

    RETURN QUERY
    SELECT
        l.id, l.name, l.full_address, l.street_number, l.street_name,
        l.district, l.city, l.lat, l.lon, l.tags, l.city_cluster,
        l.sport_ids, l.has_declared_sport, l.is_verified, l.district_legacy
    FROM public.location l
    WHERE
        (p_city_cluster IS NULL OR l.city_cluster = p_city_cluster)
        -- `has_declared_sport` is what keeps untagged venues visible. A bare
        -- `sport_ids && ARRAY[p_sport_id]` would silently drop the ~433 rows
        -- with no sport tag, which the client deliberately keeps today
        -- because "no sport info" is not "wrong sport".
        AND (
            p_sport_id IS NULL
            OR NOT l.has_declared_sport
            OR l.sport_ids && ARRAY[p_sport_id]::bigint[]
        )
        AND (
            char_length(v_term) >= 2
            OR l.is_verified
            OR l.source = 'user_submitted'
        )
        AND (
            (
                char_length(v_term) >= 8 AND (
                    extensions.word_similarity(extensions.unaccent(LOWER(v_term)), extensions.unaccent(LOWER(l.name))) > 0.3
                    OR extensions.word_similarity(LOWER(v_term), LOWER(l.name)) > 0.3
                    OR extensions.word_similarity(extensions.unaccent(LOWER(v_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
                    OR extensions.word_similarity(LOWER(v_term), LOWER(l.full_address)) > 0.3
                )
            )
            OR (
                char_length(v_term) >= 2 AND (
                    extensions.unaccent(LOWER(l.name)) LIKE '%' || extensions.unaccent(LOWER(v_term)) || '%'
                    OR extensions.unaccent(LOWER(COALESCE(l.full_address, ''))) LIKE '%' || extensions.unaccent(LOWER(v_term)) || '%'
                )
            )
            -- District BROADENS rather than narrows: picking a ward should
            -- add its venues to a name search, not intersect with it.
            OR (v_has_districts AND extensions.unaccent(LOWER(l.district)) = ANY(v_wards))
            -- Match-all: plain browse, no term and no ward.
            OR (char_length(v_term) < 2 AND NOT v_has_districts)
        )
    ORDER BY
        -- Venues explicitly tagged for the context sport first; untagged ones
        -- trail behind. Reproduces the stable sort the client used to do.
        (p_sport_id IS NOT NULL AND l.sport_ids && ARRAY[p_sport_id]::bigint[]) DESC,
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(v_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(v_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(v_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(v_term), LOWER(l.full_address))
        ) DESC,
        l.name ASC
    LIMIT 60;
END;
$$;

GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint, p_sport_id bigint) TO anon;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint, p_sport_id bigint) TO authenticated;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint, p_sport_id bigint) TO service_role;
