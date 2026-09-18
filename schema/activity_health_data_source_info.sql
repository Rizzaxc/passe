-- Extends activity_health_data with everything the recap card/sheet need to
-- show the *actual* lobby/coach/host identity instead of a generic label or
-- icon, and to link an activity back to its own hub:
--   - source_name: the lobby/coach/host display name
--   - lobby_id / course_id: link targets (a freeplay activity needs no extra
--     column — FreeplayDetailRoute takes the activity id directly, already
--     returned as activity_id)
--   - lobby_has_avatar: pairs with lobby_id/source_name for LobbyAvatar
--   - avatar_user_id/avatar_username/avatar_generated: the coach's *linked
--     user* identity (professional.linked_user_id), for PUserAvatar — null
--     when the coach profile isn't linked to a user account
--   - freeplay_avatar_url: freeplay_host.avatar_url directly
-- All of these are NULL for a 'self' (standalone) activity, which has
-- nothing to name, link, or show an avatar for — the recap UI leaves the
-- generic activity-icon badge in place for that case.
--
-- Postgres refuses `CREATE OR REPLACE` here even for an appended OUT column
-- ("cannot change return type of existing function" — the table desugars to
-- OUT parameters, which can't be changed in place). Drop first.
DROP FUNCTION public.activity_health_data(bigint);

CREATE FUNCTION public.activity_health_data(p_sport_id bigint)
  RETURNS TABLE(
    activity_id              uuid,
    start_time               timestamp with time zone,
    end_time                 timestamp with time zone,
    duration_minutes         integer,
    location_label           text,
    source                   text,
    steps                    integer,
    distance_meters          real,
    active_calories          real,
    avg_heart_rate           integer,
    max_heart_rate           integer,
    min_heart_rate           integer,
    hrv_sdnn_ms              real,
    hrv_rmssd_ms             real,
    hr_zone_easy_seconds     integer,
    hr_zone_moderate_seconds integer,
    hr_zone_hard_seconds     integer,
    training_load            real,
    effort_score             real,
    workout_type             text,
    recorded_at              timestamp with time zone,
    source_name              text,
    lobby_id                 uuid,
    course_id                uuid,
    lobby_has_avatar         boolean,
    avatar_user_id           uuid,
    avatar_username          text,
    avatar_generated         text,
    freeplay_avatar_url      text
  )
  LANGUAGE plpgsql STABLE SECURITY DEFINER
  SET search_path TO ''
  AS $$
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
    COALESCE(loc.name, fa.venue_name) AS location_label,
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
    m.workout_type,
    m.recorded_at,
    CASE
      WHEN a.course_id IS NOT NULL THEN COALESCE(c.name, prof.display_name)
      WHEN a.freeplay_host_id IS NOT NULL THEN fh.display_name
      WHEN a.lobby_id IS NOT NULL THEN l.name
      ELSE NULL
    END AS source_name,
    a.lobby_id,
    a.course_id,
    (l.details->>'hasAvatar')::boolean AS lobby_has_avatar,
    avatar_user.id AS avatar_user_id,
    avatar_user.username AS avatar_username,
    avatar_user.details->>'generatedAvatar' AS avatar_generated,
    fh.avatar_url AS freeplay_avatar_url
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
    AND a.sport_id = p_sport_id
  ORDER BY a.start_time DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.activity_health_data(bigint) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.activity_health_data(bigint) TO authenticated;
