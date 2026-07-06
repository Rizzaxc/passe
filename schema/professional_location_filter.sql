-- Professional discovery: preferred location + schedule filtering.
--
-- Adds a preferred-location model to `professional` (mirroring a user's
-- details.location shape: one city cluster + up to a few districts) and a
-- `home_professional_data` RPC that applies the shared home filter
-- (city / district / schedule) the same way `home_teammate_lobby_data` does —
-- except location/schedule are treated as SOFT for pros: a professional with
-- no stated preference always shows; one with a preference must match.
--
-- `professional.schedule jsonb` already exists; it stores the same array shape
-- as lobby playtime: [{"dayOfWeek":"mon","dayChunk":"night"}, ...].

-- ── 1. Preferred-location columns ──────────────────────────────────────────
ALTER TABLE public.professional
    ADD COLUMN IF NOT EXISTS preferred_city_cluster bigint
        REFERENCES public.supported_city_cluster(id),
    ADD COLUMN IF NOT EXISTS preferred_districts text[];

CREATE INDEX IF NOT EXISTS idx_professional_preferred_city_cluster
    ON public.professional USING btree (preferred_city_cluster);

-- ── 2. Discovery RPC ───────────────────────────────────────────────────────
-- Returns the professional rows for the context sport, ranked verified →
-- rating → reviews, with the cheapest active service rate rolled up as
-- `price_from` and a `timeslot_compat_score` for the requested schedule.
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
            -- Districts: soft (same rationale). Array overlap when both sides
            -- have districts.
          AND (
                p_districts IS NULL OR cardinality(p_districts) = 0
                OR p.preferred_districts IS NULL
                OR cardinality(p.preferred_districts) = 0
                OR p.preferred_districts && p_districts
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

GRANT EXECUTE ON FUNCTION public.home_professional_data(
    bigint, jsonb, integer, text[], integer, integer
) TO anon, authenticated;

-- ── 3. Seed preferred location + schedule for the mocked pros ──────────────
-- Idempotent: only touches mocked_ rows. Gives each a HCM district (varied, so
-- district filtering visibly narrows) and broad availability (so the
-- schedule filter, active by default from the user's playtime, doesn't empty
-- the feed). Real pros are populated via their own onboarding.
DO $$
DECLARE
    v_districts text[] := ARRAY[
        'hcm_q1','hcm_q3','hcm_q5','hcm_q7','hcm_binhthanh',
        'hcm_phunhuan','hcm_govap','hcm_thuduc','hcm_tanbinh','hcm_q10'
    ];
    -- Fully-available schedule: every day × every chunk.
    v_schedule jsonb := (
        SELECT jsonb_agg(jsonb_build_object('dayOfWeek', d, 'dayChunk', c))
        FROM unnest(ARRAY['mon','tue','wed','thu','fri','sat','sun']) AS d
        CROSS JOIN unnest(ARRAY['early','midday','noon','night']) AS c
    );
BEGIN
    -- The mocked pros are named 'mocked_HLV <n>' / 'mocked_Trọng tài <n>'
    -- with n in 1..10; use that suffix to pick a district.
    UPDATE public.professional
    SET preferred_city_cluster = 1,                           -- Ho Chi Minh
        preferred_districts =
            ARRAY[v_districts[(regexp_replace(display_name, '\D', '', 'g'))::int]],
        schedule = v_schedule
    WHERE display_name LIKE 'mocked_%'
      AND NULLIF(regexp_replace(display_name, '\D', '', 'g'), '') IS NOT NULL
      AND (regexp_replace(display_name, '\D', '', 'g'))::int BETWEEN 1 AND 10;
END $$;
