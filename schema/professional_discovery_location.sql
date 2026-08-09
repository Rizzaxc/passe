-- Surface the location signals already used by professional discovery so the
-- client can explain why a result is relevant. The filter remains soft: a
-- professional with no declared service area can still appear, but the UI no
-- longer presents every result as geographically equivalent.

DROP FUNCTION IF EXISTS public.home_professional_data(
    bigint, jsonb, integer, text[], text, integer, integer
);

CREATE FUNCTION public.home_professional_data(
    p_sport_id bigint,
    p_timeslots jsonb DEFAULT '{}'::jsonb,
    p_city integer DEFAULT NULL,
    p_districts text[] DEFAULT NULL,
    p_search text DEFAULT NULL,
    p_page_size integer DEFAULT 20,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid,
    display_name text,
    professional_role public.professional_role,
    bio text,
    sports bigint[],
    experience_years integer,
    average_rating numeric,
    review_count integer,
    is_verified boolean,
    price_from numeric,
    price_from_kind text,
    timeslot_compat_score integer,
    preferred_city_cluster bigint,
    preferred_districts text[],
    preferred_location_names text[]
)
LANGUAGE plpgsql
STABLE
SET search_path TO ''
AS $$
BEGIN
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
            SELECT p.id, p.display_name::text, p.professional_role, p.bio,
                   p.sports, p.experience_years, p.average_rating,
                   p.review_count, p.is_verified,
                   price.price_amount, price.pricing_kind,
                   COALESCE(ts.ts_score, 0),
                   p.preferred_city_cluster,
                   COALESCE(p.preferred_districts, ARRAY[]::text[]),
                   courts.names
            FROM public.professional p
            CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                    p_timeslots,
                    public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
                ) AS ts_score
            ) ts
            LEFT JOIN LATERAL (
                SELECT ps.price_amount, ps.pricing_kind
                FROM public.professional_service ps
                WHERE ps.professional_id = p.id
                  AND ps.sport_id = p_sport_id
                  AND ps.is_active
                ORDER BY ps.price_amount NULLS LAST, ps.created_at, ps.id
                LIMIT 1
            ) price ON true
            CROSS JOIN LATERAL (
                SELECT ARRAY(
                    SELECT COALESCE(NULLIF(BTRIM(loc.name), ''), loc.full_address)
                    FROM public.professional_preferred_location ppl
                    JOIN public.location loc ON loc.id = ppl.location_id
                    WHERE ppl.professional_id = p.id
                      AND COALESCE(NULLIF(BTRIM(loc.name), ''), loc.full_address) IS NOT NULL
                    ORDER BY COALESCE(NULLIF(BTRIM(loc.name), ''), loc.full_address)
                ) AS names
            ) courts
            WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
              AND (
                  p.display_name ILIKE '%' || p_search || '%'
                  OR extensions.unaccent(p.display_name)
                     ILIKE '%' || extensions.unaccent(p_search) || '%'
              )
            ORDER BY p.is_verified DESC, p.average_rating DESC,
                     p.review_count DESC
            LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
        RETURN;
    END IF;

    RETURN QUERY
        SELECT p.id, p.display_name::text, p.professional_role, p.bio,
               p.sports, p.experience_years, p.average_rating,
               p.review_count, p.is_verified,
               price.price_amount, price.pricing_kind,
               COALESCE(ts.ts_score, 0),
               p.preferred_city_cluster,
               COALESCE(p.preferred_districts, ARRAY[]::text[]),
               courts.names
        FROM public.professional p
        CROSS JOIN LATERAL (
            SELECT public.calculate_timeslot_compat_score(
                p_timeslots,
                public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
            ) AS ts_score
        ) ts
        LEFT JOIN LATERAL (
            SELECT ps.price_amount, ps.pricing_kind
            FROM public.professional_service ps
            WHERE ps.professional_id = p.id
              AND ps.sport_id = p_sport_id
              AND ps.is_active
            ORDER BY ps.price_amount NULLS LAST, ps.created_at, ps.id
            LIMIT 1
        ) price ON true
        CROSS JOIN LATERAL (
            SELECT ARRAY(
                SELECT COALESCE(NULLIF(BTRIM(loc.name), ''), loc.full_address)
                FROM public.professional_preferred_location ppl
                JOIN public.location loc ON loc.id = ppl.location_id
                WHERE ppl.professional_id = p.id
                  AND COALESCE(NULLIF(BTRIM(loc.name), ''), loc.full_address) IS NOT NULL
                ORDER BY COALESCE(NULLIF(BTRIM(loc.name), ''), loc.full_address)
            ) AS names
        ) courts
        WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
          AND (
              p_city IS NULL
              OR p.preferred_city_cluster IS NULL
              OR p.preferred_city_cluster = p_city
          )
          AND (
              p_districts IS NULL OR cardinality(p_districts) = 0
              OR p.preferred_districts IS NULL
              OR cardinality(p.preferred_districts) = 0
              OR p.preferred_districts && p_districts
              OR cardinality(courts.names) > 0
          )
          AND (
              p_timeslots = '{}'::jsonb
              OR p.schedule IS NULL
              OR p.schedule = '[]'::jsonb
              OR ts.ts_score >= 4
          )
        ORDER BY p.is_verified DESC, p.average_rating DESC,
                 p.review_count DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

REVOKE ALL ON FUNCTION public.home_professional_data(
    bigint, jsonb, integer, text[], text, integer, integer
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.home_professional_data(
    bigint, jsonb, integer, text[], text, integer, integer
) TO anon, authenticated, service_role;
