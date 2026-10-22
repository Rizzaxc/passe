-- activity_health_data: list every sport, and say which sport each row is.
--
-- Why: the app-wide "context sport" (the appbar SportSelector) is gone —
-- only Discover is still sport-scoped. Health's recap list now shows all of a
-- user's sessions, so:
--   * p_sport_id is optional — NULL means every sport (the client now always
--     passes NULL; a non-NULL id still filters, for any old client build).
--   * a new trailing `sport_id` column lets the recap card show the sport.
--
-- Adding a column changes the RETURNS TABLE type, which CREATE OR REPLACE
-- refuses, so this DROPs and re-creates (same as
-- activity_health_data_source_info.sql) and restores the grants.
-- Body otherwise identical to the live definition as of 2026-10-22, plus
-- explicit ::text casts on the varchar-backed columns. Without them RETURN
-- QUERY fails with 42804 ("Returned type character varying(16) does not match
-- expected type text in column 27", i.e. user.username) — and the definition
-- live before this migration had the same mismatch, so the recap list was
-- erroring for every caller.

DROP FUNCTION IF EXISTS public.activity_health_data(bigint);

CREATE FUNCTION public.activity_health_data(p_sport_id bigint DEFAULT NULL)
 RETURNS TABLE(activity_id uuid, start_time timestamp with time zone, end_time timestamp with time zone, duration_minutes integer, location_label text, source text, steps integer, distance_meters real, active_calories real, avg_heart_rate integer, max_heart_rate integer, min_heart_rate integer, hrv_sdnn_ms real, hrv_rmssd_ms real, hr_zone_easy_seconds integer, hr_zone_moderate_seconds integer, hr_zone_hard_seconds integer, training_load real, effort_score real, workout_type text, recorded_at timestamp with time zone, source_name text, lobby_id uuid, course_id uuid, lobby_has_avatar boolean, avatar_user_id uuid, avatar_username text, avatar_generated text, freeplay_avatar_url text, sport_id bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
  SELECT
    m.activity_id,
    a.start_time,
    a.end_time,
    CASE WHEN a.end_time IS NOT NULL
      THEN (EXTRACT(EPOCH FROM (a.end_time - a.start_time)) / 60)::int
      ELSE NULL END AS duration_minutes,
    COALESCE(loc.name, fa.venue_name)::text AS location_label,
    CASE
      WHEN a.course_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby'
      ELSE 'self'
    END AS source,
    m.steps,
    m.distance_meters,
    m.active_calories,
    m.avg_heart_rate,
    m.max_heart_rate,
    m.min_heart_rate,
    m.hrv_sdnn_ms,
    m.hrv_rmssd_ms,
    m.hr_zone_easy_seconds,
    m.hr_zone_moderate_seconds,
    m.hr_zone_hard_seconds,
    m.training_load,
    m.effort_score,
    m.workout_type::text,
    m.recorded_at,
    (CASE
      WHEN a.course_id IS NOT NULL THEN COALESCE(c.name, prof.display_name)
      WHEN a.freeplay_host_id IS NOT NULL THEN fh.display_name
      WHEN a.lobby_id IS NOT NULL THEN l.name
      ELSE NULL
    END)::text AS source_name,
    a.lobby_id,
    a.course_id,
    (l.details->>'hasAvatar')::boolean AS lobby_has_avatar,
    avatar_user.id AS avatar_user_id,
    avatar_user.username::text AS avatar_username,
    avatar_user.details->>'generatedAvatar' AS avatar_generated,
    fh.avatar_url::text AS freeplay_avatar_url,
    a.sport_id::bigint AS sport_id
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  LEFT JOIN public.lobby l ON l.id = a.lobby_id
  LEFT JOIN public.freeplay_host fh ON fh.id = a.freeplay_host_id
  LEFT JOIN public.course c ON c.id = a.course_id
  LEFT JOIN public.professional prof ON prof.id = c.professional_id
  LEFT JOIN public."user" avatar_user ON avatar_user.id = prof.linked_user_id
  WHERE m.user_id = v_uid
    AND m.dismissed = false
    AND (p_sport_id IS NULL OR a.sport_id = p_sport_id)
  ORDER BY a.start_time DESC;
END;
$function$;

REVOKE ALL ON FUNCTION public.activity_health_data(bigint) FROM PUBLIC, anon;
GRANT ALL ON FUNCTION public.activity_health_data(bigint) TO authenticated;
GRANT ALL ON FUNCTION public.activity_health_data(bigint) TO service_role;
