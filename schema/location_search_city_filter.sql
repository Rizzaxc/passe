-- `search_locations` (schema/home_feed_search.sql) OR's the district filter
-- against the fuzzy name/address match but never applied `p_city` — so
-- picking a district (or typing a search term) while a city was selected in
-- the shared home filter could return venues from the *other* supported
-- city too, whenever a district label happened to coincide across cities.
-- Adds `p_city_cluster`, applied as a hard AND (unlike the search/district
-- OR) since city is the outer scope both of those narrow within.
--
-- Re-dump `schema/passe.sql` after applying (do not hand-edit the dump).

DROP FUNCTION IF EXISTS public.search_locations(text, character varying[]);

CREATE FUNCTION public.search_locations(search_term text, p_districts character varying[] DEFAULT NULL, p_city_cluster bigint DEFAULT NULL)
    RETURNS TABLE(
        id uuid,
        name text,
        full_address text,
        street_number integer,
        street_name text,
        district text,
        city text,
        lat double precision,
        lon double precision,
        tags text[],
        city_cluster bigint
    )
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.full_address,
        l.street_number,
        l.street_name,
        l.district,
        l.city,
        l.lat,
        l.lon,
        l.tags,
        l.city_cluster
    FROM public.location l
    WHERE
        (p_city_cluster IS NULL OR l.city_cluster = p_city_cluster)
        AND (
            (
                char_length(search_term) >= 8 AND (
                    extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))) > 0.3
                    OR extensions.word_similarity(LOWER(search_term), LOWER(l.name)) > 0.3
                    OR extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
                    OR extensions.word_similarity(LOWER(search_term), LOWER(l.full_address)) > 0.3
                )
            )
            OR (p_districts IS NOT NULL AND cardinality(p_districts) > 0 AND l.district = ANY(p_districts))
        )
    ORDER BY
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.full_address))
        ) DESC,
        l.name ASC
    LIMIT 60;
END;
$$;

ALTER FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) OWNER TO postgres;

GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO anon;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO authenticated;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO service_role;
