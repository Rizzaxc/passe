-- ============================================================================
-- teammate_empty_district_fix.sql
--
-- home_teammate_lobby_data hard-filtered `loc.district = ANY(p_districts)`, so an
-- empty district filter (the default — user picks a city but no district) matched
-- nothing. Make the district filter optional: empty/null p_districts ⇒ all
-- districts in the city cluster. Body is otherwise unchanged.
--
-- Apply with execute_sql / apply_migration. Idempotent (CREATE OR REPLACE).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.home_teammate_lobby_data(
    p_sport_id bigint,
    p_timeslots jsonb,
    p_city integer,
    p_districts character varying[],
    p_page_size integer DEFAULT 10,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid, name text, homeground_name text, playtime jsonb, details jsonb,
    visibility public.lobby_visibility, timeslot_compat_score integer,
    profile_compat_score numeric
)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            l.id,
            l.name::text,
            loc.name::text AS homeground_name,
            l.playtime,
            l.details,
            l.visibility,
            ts_score AS timeslot_compat_score,
            profile_score AS profile_compat_score
        FROM
            public.lobby l
                JOIN
            public.location loc ON l.home_ground = loc.id
                CROSS JOIN LATERAL (
                SELECT public.calculate_timeslot_compat_score(p_timeslots, public.fn_playtime_to_dict(l.playtime)) AS ts_score
                ) ts
                CROSS JOIN LATERAL (
                SELECT public.calculate_profile_compat_score(auth.uid(), l.id, l.sport_id) AS profile_score
                ) ps
        WHERE
            l.sport_id = p_sport_id
          AND l.visibility != 'private'
          AND loc.city_cluster = p_city
          AND (p_districts IS NULL OR cardinality(p_districts) = 0 OR loc.district = ANY(p_districts))
          AND (p_timeslots = '{}'::jsonb OR ts.ts_score >= 4)
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
