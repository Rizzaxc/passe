-- location.street_number was `integer`, but real Vietnamese house numbers are
-- routinely non-integer (e.g. "262/13", "12A", "45/6B") — casting user-typed
-- values to integer in create_location threw `invalid_text_representation`
-- (Postgres 22P02) the moment anyone typed a real address manually, which is
-- now the primary path for a missing venue. Store it as free text instead;
-- the Dart client already treats it purely as display text everywhere.

ALTER TABLE public.location
    ALTER COLUMN street_number TYPE text USING street_number::text;

-- Return-type change requires DROP + CREATE, not CREATE OR REPLACE.
DROP FUNCTION IF EXISTS public.search_locations(text, character varying[], bigint);

CREATE FUNCTION public.search_locations(search_term text, p_districts character varying[] DEFAULT NULL::character varying[], p_city_cluster bigint DEFAULT NULL::bigint) RETURNS TABLE(id uuid, name text, full_address text, street_number text, street_name text, district text, city text, lat double precision, lon double precision, tags text[], city_cluster bigint)
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
            OR (
                char_length(search_term) >= 2 AND (
                    extensions.unaccent(LOWER(l.name)) LIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
                    OR extensions.unaccent(LOWER(COALESCE(l.full_address, ''))) LIKE '%' || extensions.unaccent(LOWER(search_term)) || '%'
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

GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO anon;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO authenticated;
GRANT ALL ON FUNCTION public.search_locations(search_term text, p_districts character varying[], p_city_cluster bigint) TO service_role;

CREATE OR REPLACE FUNCTION public.create_location(
    p_name text,
    p_street_number text DEFAULT NULL::text,
    p_street_name text DEFAULT NULL::text,
    p_district text DEFAULT NULL::text,
    p_city text DEFAULT NULL::text,
    p_city_cluster bigint DEFAULT NULL::bigint
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
    AS $$
DECLARE
    v_user_id uuid;
    v_loc_id  uuid;
    v_result  jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'create_location: authentication required';
    END IF;
    IF NULLIF(TRIM(COALESCE(p_name, '')), '') IS NULL THEN
        RAISE EXCEPTION 'create_location: name is required';
    END IF;

    INSERT INTO public.location (
        name, street_number, street_name, district, city, city_cluster,
        source, submitted_by, is_verified
    )
    VALUES (
        TRIM(p_name),
        NULLIF(p_street_number, ''),
        NULLIF(p_street_name, ''),
        NULLIF(p_district, ''),
        NULLIF(p_city, ''),
        p_city_cluster,
        'user_submitted',
        v_user_id,
        false
    )
    RETURNING id INTO v_loc_id;

    SELECT row_to_json(l)::jsonb INTO v_result
        FROM public.location l
        WHERE l.id = v_loc_id;

    RETURN v_result;
END;
$$;
