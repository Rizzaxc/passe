
-- GIN trigram index on name for fast similarity search
CREATE INDEX IF NOT EXISTS idx_location_name_trgm
    ON public.location USING gin (extensions.unaccent(LOWER(name)) extensions.gin_trgm_ops);

-- GIN trigram index on full_address for fast similarity search
CREATE INDEX IF NOT EXISTS idx_location_full_address_trgm
    ON public.location USING gin (extensions.unaccent(LOWER(full_address)) extensions.gin_trgm_ops);

-- Function: search_locations
-- Searches location by name and full_address using trigram word similarity
-- Minimum query length: 8 characters
-- Maximum results: 10
CREATE OR REPLACE FUNCTION public.search_locations(search_term text)
RETURNS TABLE(
    id uuid,
    name text,
    full_address text,
    street_number integer,
    street_name text,
    district text,
    city text
)
LANGUAGE plpgsql
STABLE
SET search_path TO ''
AS $$
BEGIN
    IF char_length(search_term) < 8 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        l.id,
        l.name,
        l.full_address,
        l.street_number,
        l.street_name,
        l.district,
        l.city
    FROM public.location l
    WHERE
        extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(l.name)) > 0.3
        OR extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))) > 0.3
        OR extensions.word_similarity(LOWER(search_term), LOWER(l.full_address)) > 0.3
    ORDER BY
        GREATEST(
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.name))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.name)),
            extensions.word_similarity(extensions.unaccent(LOWER(search_term)), extensions.unaccent(LOWER(l.full_address))),
            extensions.word_similarity(LOWER(search_term), LOWER(l.full_address))
        ) DESC
    LIMIT 10;
END;
$$;

ALTER FUNCTION public.search_locations(text) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.search_locations(text) TO anon;
GRANT EXECUTE ON FUNCTION public.search_locations(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_locations(text) TO service_role;
