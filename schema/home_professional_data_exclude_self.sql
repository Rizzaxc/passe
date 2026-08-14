-- A user who is also a registered professional (coach/referee) was showing
-- up in their own Home > Neutrals discovery feed, and could tap through to
-- their own detail page and reach the "Message" flow — message_coach()
-- already rejects that server-side ('cannot coach yourself'), but nothing
-- kept the self-listing out of the feed in the first place. Excluding it at
-- the source is simpler than teaching every consumer of this RPC to filter
-- its own row out client-side.
CREATE OR REPLACE FUNCTION public.home_professional_data(p_sport_id bigint, p_timeslots jsonb DEFAULT '{}'::jsonb, p_city integer DEFAULT NULL::integer, p_districts text[] DEFAULT NULL::text[], p_search text DEFAULT NULL::text, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, display_name text, professional_role public.professional_role, bio text, sports bigint[], experience_years integer, average_rating numeric, review_count integer, is_verified boolean, price_from numeric, price_from_kind text, timeslot_compat_score integer)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
BEGIN
    IF p_search IS NOT NULL AND p_search <> '' THEN
        RETURN QUERY
            SELECT p.id, p.display_name::text, p.professional_role, p.bio,
                   p.sports, p.experience_years, p.average_rating,
                   p.review_count, p.is_verified,
                   price.price_amount, price.pricing_kind,
                   COALESCE(ts.ts_score, 0)
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
            WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
              AND p.linked_user_id IS DISTINCT FROM auth.uid()
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
               COALESCE(ts.ts_score, 0)
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
        WHERE p.sports @> ARRAY[p_sport_id]::bigint[]
          AND p.linked_user_id IS DISTINCT FROM auth.uid()
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
