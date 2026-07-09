-- Preferred courts: a coach can have specific venues (`location` rows) they teach at. Students
-- booking a session pick from that list or suggest a different address (booking sheet, wired
-- separately in the client). This is more specific than the existing `preferred_districts` coarse
-- discovery filter (`schema/professional_location_filter.sql`) — once a coach has real courts, the
-- district filter becomes redundant for them and is skipped entirely for discovery matching.
--
-- Preferred courts are set out-of-app (admin/DB-direct), same as `professional.linked_user_id` —
-- no client INSERT/UPDATE/DELETE policy on this table by design.
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for review, not
-- auto-applied.

CREATE TABLE public.professional_preferred_location (
    professional_id uuid NOT NULL,
    location_id uuid NOT NULL,
    CONSTRAINT professional_preferred_location_pkey PRIMARY KEY (professional_id, location_id),
    CONSTRAINT professional_preferred_location_professional_id_fkey
        FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE,
    CONSTRAINT professional_preferred_location_location_id_fkey
        FOREIGN KEY (location_id) REFERENCES public.location(id) ON DELETE CASCADE
);

COMMENT ON TABLE public.professional_preferred_location IS
    'Courts a coach teaches at, surfaced in the booking sheet for the student to pick from. Set
     out-of-app (admin/DB-direct) — no self-service UI in this pass, mirrors linked_user_id.';

CREATE INDEX idx_professional_preferred_location_location
    ON public.professional_preferred_location USING btree (location_id);

ALTER TABLE public.professional_preferred_location ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for all users" ON public.professional_preferred_location
    FOR SELECT USING (true);

-- ── Discovery precedence: skip the district soft-filter once real courts exist ─────────────────
CREATE OR REPLACE FUNCTION public.home_professional_data(
    p_sport_id bigint,
    p_timeslots jsonb DEFAULT '{}'::jsonb,
    p_city integer DEFAULT NULL,
    p_districts text[] DEFAULT NULL,
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
    timeslot_compat_score integer
)
    LANGUAGE plpgsql
    STABLE
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            p.id,
            p.display_name::text,
            p.professional_role,
            p.bio,
            p.sports,
            p.experience_years,
            p.average_rating,
            p.review_count,
            p.is_verified,
            (
                SELECT min(ps.hourly_rate)
                FROM public.professional_service ps
                WHERE ps.professional_id = p.id
                  AND ps.sport_id = p_sport_id
                  AND ps.is_active
            ) AS price_from,
            COALESCE(ts.ts_score, 0) AS timeslot_compat_score
        FROM
            public.professional p
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(
                           p_timeslots,
                           public.fn_playtime_to_dict(COALESCE(p.schedule, '[]'::jsonb))
                       ) AS ts_score
                ) ts
        WHERE
            p.sports @> ARRAY[p_sport_id]::bigint[]
            -- City: soft. A pro with no preferred city is location-agnostic and
            -- always shows; one with a preference must match the filter.
          AND (
                p_city IS NULL
                OR p.preferred_city_cluster IS NULL
                OR p.preferred_city_cluster = p_city
            )
            -- Districts: soft (same rationale) — but skipped entirely once the pro has real
            -- preferred courts (professional_preferred_location), since actual venues are a
            -- stronger, more specific signal than a coarse district array.
          AND (
                p_districts IS NULL OR cardinality(p_districts) = 0
                OR p.preferred_districts IS NULL
                OR cardinality(p.preferred_districts) = 0
                OR p.preferred_districts && p_districts
                OR EXISTS (
                    SELECT 1 FROM public.professional_preferred_location ppl
                    WHERE ppl.professional_id = p.id
                )
            )
            -- Schedule: soft. Pros with no stated schedule always show; those
            -- with one must share ≥1 day+chunk with the requested timeslots
            -- (score ≥ 4), matching the teammate feed's threshold.
          AND (
                p_timeslots = '{}'::jsonb
                OR p.schedule IS NULL
                OR p.schedule = '[]'::jsonb
                OR ts.ts_score >= 4
            )
        ORDER BY
            p.is_verified DESC,
            p.average_rating DESC,
            p.review_count DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
