-- Health Tab Phase 1 migration.
-- Reshapes the (empty) health rollup tables for the 3-zone LT model, adds the
-- dismissal tombstone + optional personal thresholds, and defines the two read RPCs.
-- Tables have never held a row, so the column drops/renames are risk-free.

-- ── activity_health_metrics: 5-zone (%-based) → 3-zone (LT-based) + dismissal tombstone ──
ALTER TABLE public.activity_health_metrics
  DROP COLUMN hr_zone_4_seconds,
  DROP COLUMN hr_zone_5_seconds;

ALTER TABLE public.activity_health_metrics
  RENAME COLUMN hr_zone_1_seconds TO hr_zone_easy_seconds;
ALTER TABLE public.activity_health_metrics
  RENAME COLUMN hr_zone_2_seconds TO hr_zone_moderate_seconds;
ALTER TABLE public.activity_health_metrics
  RENAME COLUMN hr_zone_3_seconds TO hr_zone_hard_seconds;

ALTER TABLE public.activity_health_metrics
  ADD COLUMN dismissed boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.activity_health_metrics.dismissed IS
  'Tombstone: true rows carry no metrics and mark a detected workout the user dismissed, so it is not re-prompted. Excluded from activity_health_data.';

-- ── user_health_link: optional personal HR thresholds (willing users set them) ──
ALTER TABLE public.user_health_link
  ADD COLUMN max_heart_rate integer,
  ADD COLUMN lt1_bpm integer,
  ADD COLUMN lt2_bpm integer;

COMMENT ON COLUMN public.user_health_link.lt1_bpm IS
  'User-declared aerobic threshold (bpm). NULL → app estimates ~80% of max HR and renders zones as "estimated".';
COMMENT ON COLUMN public.user_health_link.lt2_bpm IS
  'User-declared anaerobic threshold (bpm). NULL → app estimates ~88% of max HR.';

-- ── RPC: capture candidates ────────────────────────────────────────────────
-- Activities the caller had an intent-relationship with (confirmed / proposed /
-- coach booking), that have ended within the window, and that have NO existing
-- activity_health_metrics row (attached OR dismissed tombstone). The device — not
-- this RPC — decides whether exercise actually happened; this just narrows the set.
CREATE OR REPLACE FUNCTION public.health_capture_candidates(p_window_start timestamp with time zone)
  RETURNS TABLE(
    activity_id uuid,
    start_time  timestamp with time zone,
    end_time    timestamp with time zone,
    sport_id    bigint,
    source      text,
    confirmed   boolean
  )
  LANGUAGE plpgsql STABLE SECURITY DEFINER
  SET search_path TO ''
  AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.start_time,
    a.end_time,
    a.sport_id,
    CASE
      WHEN a.professional_booking_id IS NOT NULL THEN 'professional'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby'
      ELSE 'self'
    END AS source,
    EXISTS (
      SELECT 1 FROM public.activity_confirmation ac
      WHERE ac.activity_id = a.id AND ac.user_id = v_uid
    ) AS confirmed
  FROM public.activity a
  WHERE a.end_time IS NOT NULL
    AND a.end_time < now()
    AND a.end_time >= p_window_start
    AND (
      a.user_id = v_uid
      OR EXISTS (
        SELECT 1 FROM public.activity_confirmation ac
        WHERE ac.activity_id = a.id AND ac.user_id = v_uid
      )
      OR (
        a.professional_booking_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.professional_booking pb
          WHERE pb.id = a.professional_booking_id
            AND (
              pb.client_user_id = v_uid
              OR EXISTS (
                SELECT 1 FROM public.booking_additional_users bau
                WHERE bau.booking_id = pb.id AND bau.user_id = v_uid
              )
            )
        )
      )
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.activity_health_metrics m
      WHERE m.activity_id = a.id AND m.user_id = v_uid
    )
  ORDER BY a.end_time DESC;
END;
$$;

-- ── RPC: activity recap list (sport-scoped) ────────────────────────────────
-- The caller's captured metrics (non-dismissed, real) joined to activity context.
CREATE OR REPLACE FUNCTION public.activity_health_data(p_sport_id bigint)
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
    hr_zone_easy_seconds     integer,
    hr_zone_moderate_seconds integer,
    hr_zone_hard_seconds     integer,
    training_load            real,
    effort_score             real,
    workout_type             text,
    recorded_at              timestamp with time zone
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
    loc.name AS location_label,
    CASE
      WHEN a.professional_booking_id IS NOT NULL THEN 'professional'
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
    m.hr_zone_easy_seconds,
    m.hr_zone_moderate_seconds,
    m.hr_zone_hard_seconds,
    m.training_load,
    m.effort_score,
    m.workout_type,
    m.recorded_at
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  WHERE m.user_id = v_uid
    AND m.dismissed = false
    AND a.sport_id = p_sport_id
  ORDER BY a.start_time DESC;
END;
$$;
