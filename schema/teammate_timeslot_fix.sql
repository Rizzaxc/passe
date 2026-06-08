-- Fix: home_teammate_lobby_data always returned zero rows.
--
-- Root cause: it called calculate_timeslot_compat_score(p_timeslots, l.playtime), but
-- p_timeslots arrives from Dart as the dict shape {"mon": ["night"]} (Timeslot.listToJson,
-- composite days pre-expanded) while l.playtime is stored as the array-of-objects shape
-- [{"dayOfWeek": "wkn", "dayChunk": "night"}] (Timeslot.toJson(), can contain composite day
-- codes). calculate_timeslot_compat_score assumes both sides are dicts — `target ? source_day`
-- is always false against an array of objects — so ts_score was deterministically 0 and the
-- `ts_score >= 4` gate excluded every row, including the empty-filter case.
--
-- Fix: convert l.playtime to the dict shape at the call site (new fn_playtime_to_dict, mirroring
-- fn_lobby_playtime_keys's composite-day expansion), and relax the gate so an empty schedule
-- filter (p_timeslots = '{}', which is exactly "user has no schedule criteria" — FilterData has
-- no synthetic default for `schedule` the way it does for `city`) falls back to ranking by
-- profile_compat_score alone instead of being hard-excluded.

--
-- Name: fn_playtime_to_dict(jsonb); Type: FUNCTION; Schema: public
--

CREATE OR REPLACE FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) RETURNS jsonb
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    SELECT COALESCE(jsonb_object_agg(base_day, chunks), '{}'::jsonb)
    FROM (
        SELECT
            base_day,
            jsonb_agg(DISTINCT chunk) AS chunks
        FROM (
            SELECT
                elem->>'dayChunk' AS chunk,
                unnest(CASE elem->>'dayOfWeek'
                           WHEN 'all' THEN ARRAY['mon','tue','wed','thu','fri','sat','sun']
                           WHEN 'mwf' THEN ARRAY['mon','wed','fri']
                           WHEN 'tts' THEN ARRAY['tue','thu','sat']
                           WHEN 'wkn' THEN ARRAY['sat','sun']
                           ELSE ARRAY[elem->>'dayOfWeek']
                       END) AS base_day
            FROM jsonb_array_elements(
                     CASE WHEN jsonb_typeof(COALESCE(p_playtime, '[]'::jsonb)) = 'array'
                          THEN p_playtime ELSE '[]'::jsonb END
                 ) AS elem
            WHERE elem->>'dayChunk' IS NOT NULL AND elem->>'dayOfWeek' IS NOT NULL
        ) expanded
        GROUP BY base_day
    ) grouped;
$$;

--
-- Name: home_teammate_lobby_data(...); Type: FUNCTION; Schema: public
-- (CREATE OR REPLACE — signature/return type unchanged, no DROP needed)
--

CREATE OR REPLACE FUNCTION public.home_teammate_lobby_data(p_sport_id bigint, p_timeslots jsonb, p_city integer, p_districts character varying[], p_page_size integer DEFAULT 10, p_page_number integer DEFAULT 1) RETURNS TABLE(id uuid, name character varying, homeground_name character varying, playtime jsonb, details jsonb, visibility public.lobby_visibility, timeslot_compat_score integer, profile_compat_score numeric)
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
    RETURN QUERY
        SELECT
            l.id,
            l.name,
            loc.name AS homeground_name,
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
          AND loc.district = ANY(p_districts)
          AND (p_timeslots = '{}'::jsonb OR ts.ts_score >= 4)
        ORDER BY
            profile_compat_score DESC,
            timeslot_compat_score DESC
        LIMIT p_page_size
            OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

--
-- Grants — match the existing grants on calculate_timeslot_compat_score / fn_lobby_playtime_keys
-- (client-callable helper, same trust level as fn_lobby_playtime_keys which is also IMMUTABLE SQL
-- with no cross-row reads).
--

GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO anon;
GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO authenticated;
GRANT ALL ON FUNCTION public.fn_playtime_to_dict(p_playtime jsonb) TO service_role;
