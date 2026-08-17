-- Vitality Score: a general gamified fitness score (0-100) that balances
-- intensity and consistency, normalized against each user's own trailing
-- history so casual/non-competitive players score as well as heavy trainers
-- who match their own pace. See CLAUDE.md "Vitality Score" for the design.
--
-- Mirrors schema/achievement_gamification.sql conventions: sole-mutator
-- SECURITY DEFINER evaluator, RLS-locked history tables, curve lives only in
-- SQL.

CREATE TABLE IF NOT EXISTS public.vitality_daily_load (
  user_id       uuid        NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  date          date        NOT NULL,
  session_load  real        NOT NULL DEFAULT 0,
  session_count integer     NOT NULL DEFAULT 0,
  computed_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_vitality_daily_load_user_date
  ON public.vitality_daily_load (user_id, date DESC);

ALTER TABLE public.vitality_daily_load ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.vitality_daily_load TO authenticated;
GRANT ALL    ON TABLE public.vitality_daily_load TO service_role;

DROP POLICY IF EXISTS "Users see their own daily load" ON public.vitality_daily_load;
CREATE POLICY "Users see their own daily load"
  ON public.vitality_daily_load FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE TABLE IF NOT EXISTS public.vitality_score (
  user_id                uuid        NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  date                   date        NOT NULL,
  score                  real,
  consistency_component  real,
  load_component         real,
  recovery_component     real,
  volume_component       real,
  streak_bonus           real        NOT NULL DEFAULT 0,
  ctl                    real,
  atl                    real,
  computed_at            timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_vitality_score_user_date
  ON public.vitality_score (user_id, date DESC);

ALTER TABLE public.vitality_score ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.vitality_score TO authenticated;
GRANT ALL    ON TABLE public.vitality_score TO service_role;

DROP POLICY IF EXISTS "Users see their own vitality score" ON public.vitality_score;
CREATE POLICY "Users see their own vitality score"
  ON public.vitality_score FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- Zero-filled daily session_load series, the shared resolver both the EWMA
-- function and the evaluator's baseline windows read from.
CREATE OR REPLACE FUNCTION public._vitality_daily_load_series(
  p_user_id uuid, p_from date, p_to date
) RETURNS TABLE(date date, session_load real)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT gs.d::date, COALESCE(vdl.session_load, 0)
  FROM generate_series(p_from, p_to, interval '1 day') AS gs(d)
  LEFT JOIN public.vitality_daily_load vdl
    ON vdl.user_id = p_user_id AND vdl.date = gs.d::date
  ORDER BY gs.d;
$$;

-- EWMA over the daily load series (tau=42 -> CTL, tau=7 -> ATL), seeded at 0
-- a few time-constants before p_as_of so it has room to converge.
CREATE OR REPLACE FUNCTION public._vitality_ewma(
  p_user_id uuid, p_as_of date, p_window_days integer
) RETURNS real
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  WITH RECURSIVE series AS (
    SELECT date, session_load
    FROM public._vitality_daily_load_series(
      p_user_id, p_as_of - (p_window_days * 3), p_as_of
    )
  ),
  ewma AS (
    SELECT date, session_load::real AS value
    FROM series WHERE date = (SELECT MIN(date) FROM series)
    UNION ALL
    SELECT s.date,
      (e.value + (s.session_load - e.value) / p_window_days)::real
    FROM series s
    JOIN ewma e ON s.date = e.date + 1
  )
  SELECT value FROM ewma WHERE date = p_as_of;
$$;

-- Piecewise-linear lookup: maps an absolute weekly rate (frequency, training
-- load, or calories) onto a 0-100 tier. Absolute, not self-relative, so the
-- score reads like a real fitness tier (casual ~50-60, athletic ~60-70,
-- highly committed ~80-90) rather than everyone converging on ~100 once they
-- match their own steady pace. Breakpoints are -- TUNABLE.
CREATE OR REPLACE FUNCTION public._vitality_scale(
  p_value real, p_breaks real[], p_scores real[]
) RETURNS real LANGUAGE plpgsql IMMUTABLE SET search_path TO '' AS $$
DECLARE
  n integer := array_length(p_breaks, 1);
BEGIN
  IF p_value <= p_breaks[1] THEN RETURN p_scores[1]; END IF;
  IF p_value >= p_breaks[n] THEN RETURN p_scores[n]; END IF;
  FOR i IN 1..n - 1 LOOP
    IF p_value >= p_breaks[i] AND p_value <= p_breaks[i + 1] THEN
      RETURN p_scores[i] + (p_value - p_breaks[i])
        / (p_breaks[i + 1] - p_breaks[i]) * (p_scores[i + 1] - p_scores[i]);
    END IF;
  END LOOP;
  RETURN p_scores[n];
END;
$$;

-- Sole mutator: recomputes today's vitality_daily_load + vitality_score for
-- the caller. Self-only guard mirrors evaluate_achievements.
CREATE OR REPLACE FUNCTION public.evaluate_vitality_score(p_user_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_today             date := now()::date;
  v_eligible_from      date;
  v_has_prior_load     boolean;
  v_recompute_from     date;
  v_has_any_session    boolean;

  -- Stored for observability / a future trend notification — no longer the
  -- driver of the load component (see below).
  v_ctl_today          real;
  v_ctl_28ago          real;
  v_atl_today          real;

  v_sessions_28d       integer;
  v_freq_weekly        real;
  v_consistency        real;

  v_load_28d           real;
  v_load_weekly        real;
  v_load               real;

  v_rhr_7d             real;
  v_rhr_56d            real;
  v_rhr_stddev         real;
  v_rhr_z              real;
  v_recovery           real;

  v_cal_28d            real;
  v_cal_weekly         real;
  v_volume             real;

  v_streak_weeks       integer;
  v_streak_bonus       real;

  v_score_sum          real;
  v_weight_sum         real;
  v_score              real;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT GREATEST(u.created_at::date, v_today - 90)
    INTO v_eligible_from
    FROM public."user" u WHERE u.id = p_user_id;

  -- Step 1: upsert vitality_daily_load. First-ever sync backfills the whole
  -- eligible window (needed so later EWMA lookbacks past 7 days aren't
  -- silently zero-filled); later syncs only touch the trailing week.
  v_has_prior_load := EXISTS(
    SELECT 1 FROM public.vitality_daily_load WHERE user_id = p_user_id
  );
  v_recompute_from := GREATEST(
    CASE WHEN v_has_prior_load THEN v_today - 7 ELSE v_eligible_from END,
    v_eligible_from
  );

  INSERT INTO public.vitality_daily_load (user_id, date, session_load, session_count, computed_at)
  SELECT
    p_user_id,
    a.start_time::date,
    SUM(public._activity_metric_value(m, 'session_load')),
    COUNT(*),
    now()
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  WHERE m.user_id = p_user_id AND NOT m.dismissed
    AND a.start_time::date BETWEEN v_recompute_from AND v_today
  GROUP BY a.start_time::date
  ON CONFLICT (user_id, date) DO UPDATE
    SET session_load  = EXCLUDED.session_load,
        session_count = EXCLUDED.session_count,
        computed_at   = now();

  -- Rest days in the recompute window with no activity row at all still need
  -- an explicit zero row so the EWMA series doesn't skip them.
  INSERT INTO public.vitality_daily_load (user_id, date, session_load, session_count, computed_at)
  SELECT p_user_id, gs.d::date, 0, 0, now()
  FROM generate_series(v_recompute_from, v_today, interval '1 day') AS gs(d)
  ON CONFLICT (user_id, date) DO NOTHING;

  -- Step 2: CTL/ATL — stored for observability / a future trend notification.
  v_ctl_today := public._vitality_ewma(p_user_id, v_today, 42);
  v_ctl_28ago := public._vitality_ewma(p_user_id, v_today - 28, 42);
  v_atl_today := public._vitality_ewma(p_user_id, v_today, 7);

  -- Component A: consistency — absolute session frequency over the trailing
  -- 28 days, mapped to a tier. Absolute (not vs. the user's own history) so
  -- a casual once-or-twice-a-week player reads as genuinely "casual" rather
  -- than capping out at 100 just for matching their own steady pace.
  SELECT COUNT(*) INTO v_sessions_28d
    FROM public.activity_health_metrics m
    JOIN public.activity a ON a.id = m.activity_id
    WHERE m.user_id = p_user_id AND NOT m.dismissed
      AND a.start_time::date BETWEEN v_today - 27 AND v_today;

  v_freq_weekly := v_sessions_28d / 4.0;
  v_consistency := public._vitality_scale(
    v_freq_weekly,
    ARRAY[0, 1, 2, 3, 4, 5, 6],
    ARRAY[20, 45, 55, 65, 75, 85, 92]
  );

  -- Component B: training load — absolute weekly session_load (3-zone TRIMP)
  -- over the trailing 28 days, mapped to a tier. High weekly load (frequent,
  -- hard sessions) is what actually separates a casual player from someone
  -- semi-professionally committed.
  SELECT COALESCE(SUM(public._activity_metric_value(m, 'session_load')), 0) INTO v_load_28d
    FROM public.activity_health_metrics m
    JOIN public.activity a ON a.id = m.activity_id
    WHERE m.user_id = p_user_id AND NOT m.dismissed
      AND a.start_time::date BETWEEN v_today - 27 AND v_today;

  v_load_weekly := v_load_28d / 4.0;
  v_load := public._vitality_scale(
    v_load_weekly,
    ARRAY[0, 60, 120, 200, 320, 450],
    ARRAY[20, 38, 55, 68, 80, 92]
  );

  -- Component C: recovery — 7d resting HR mean vs. 56d baseline, normalized
  -- by the user's own stddev. Self-relative (RHR has no universal "good"
  -- absolute value across individuals). NULL if no RHR data at all.
  SELECT AVG(resting_heart_rate) INTO v_rhr_7d
    FROM public.daily_health_summary
    WHERE user_id = p_user_id AND date BETWEEN v_today - 6 AND v_today
      AND resting_heart_rate IS NOT NULL;

  SELECT AVG(resting_heart_rate), STDDEV(resting_heart_rate) INTO v_rhr_56d, v_rhr_stddev
    FROM public.daily_health_summary
    WHERE user_id = p_user_id AND date BETWEEN v_today - 55 AND v_today
      AND resting_heart_rate IS NOT NULL;

  IF v_rhr_7d IS NULL OR v_rhr_56d IS NULL THEN
    v_recovery := NULL;
  ELSE
    v_rhr_z := (v_rhr_56d - v_rhr_7d) / GREATEST(COALESCE(v_rhr_stddev, 0), 2.0);
    v_recovery := LEAST(100, GREATEST(0, 50 + v_rhr_z * 25));
  END IF;

  -- Component D: active volume — absolute weekly active calories over the
  -- trailing 28 days, mapped to a tier. NULL if no calorie data at all.
  SELECT SUM(active_calories) INTO v_cal_28d
    FROM public.daily_health_summary
    WHERE user_id = p_user_id AND date BETWEEN v_today - 27 AND v_today;

  IF v_cal_28d IS NULL THEN
    v_volume := NULL;
  ELSE
    v_cal_weekly := v_cal_28d / 4.0;
    v_volume := public._vitality_scale(
      v_cal_weekly,
      ARRAY[0, 500, 1000, 2000, 3200, 4500],
      ARRAY[20, 35, 55, 70, 85, 93]
    );
  END IF;

  -- Streak bonus: +3 flat if the last 4+ consecutive ISO weeks each had a
  -- session.
  v_streak_weeks := 0;
  FOR i IN 0..7 LOOP
    EXIT WHEN NOT EXISTS(
      SELECT 1 FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND date_trunc('week', a.start_time::date)
          = date_trunc('week', v_today) - (i || ' weeks')::interval
    );
    v_streak_weeks := v_streak_weeks + 1;
  END LOOP;
  v_streak_bonus := CASE WHEN v_streak_weeks >= 4 THEN 3 ELSE 0 END;

  -- Combine with weight-renormalization across whichever components have data.
  v_score_sum := v_consistency * 0.40;
  v_weight_sum := 0.40;
  v_score_sum := v_score_sum + v_load * 0.30;
  v_weight_sum := v_weight_sum + 0.30;
  IF v_recovery IS NOT NULL THEN
    v_score_sum := v_score_sum + v_recovery * 0.15;
    v_weight_sum := v_weight_sum + 0.15;
  END IF;
  IF v_volume IS NOT NULL THEN
    v_score_sum := v_score_sum + v_volume * 0.15;
    v_weight_sum := v_weight_sum + 0.15;
  END IF;

  -- _vitality_scale floors an input of exactly 0 to scores[1] (20, the
  -- "casual" tier), not 0/null — correct for someone genuinely-but-rarely
  -- active, wrong for someone who has never captured a single real session.
  -- The 14-day gate above only checks account age, so a long-time account's
  -- very first sync (zero data) would otherwise ship that floor value as a
  -- real-looking score. Require at least one real capture before scoring.
  SELECT EXISTS(
    SELECT 1 FROM public.activity_health_metrics m
    WHERE m.user_id = p_user_id AND NOT m.dismissed
  ) INTO v_has_any_session;

  IF (v_today - v_eligible_from) < 14 OR NOT v_has_any_session THEN
    v_score := NULL;
  ELSE
    v_score := LEAST(100, (v_score_sum / v_weight_sum) + v_streak_bonus);
  END IF;

  INSERT INTO public.vitality_score (
    user_id, date, score, consistency_component, load_component,
    recovery_component, volume_component, streak_bonus, ctl, atl, computed_at
  ) VALUES (
    p_user_id, v_today, v_score, v_consistency, v_load,
    v_recovery, v_volume, v_streak_bonus, v_ctl_today, v_atl_today, now()
  )
  ON CONFLICT (user_id, date) DO UPDATE
    SET score                 = EXCLUDED.score,
        consistency_component = EXCLUDED.consistency_component,
        load_component        = EXCLUDED.load_component,
        recovery_component    = EXCLUDED.recovery_component,
        volume_component      = EXCLUDED.volume_component,
        streak_bonus          = EXCLUDED.streak_bonus,
        ctl                   = EXCLUDED.ctl,
        atl                   = EXCLUDED.atl,
        computed_at           = now();

  RETURN jsonb_build_object(
    'date', v_today,
    'score', v_score,
    'consistency_component', v_consistency,
    'load_component', v_load,
    'recovery_component', v_recovery,
    'volume_component', v_volume,
    'streak_bonus', v_streak_bonus,
    'ctl', v_ctl_today,
    'atl', v_atl_today
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.evaluate_vitality_score(uuid) TO authenticated;

-- Client-facing read: most recent score row for the caller.
CREATE OR REPLACE FUNCTION public.vitality_score_summary(p_user_id uuid)
RETURNS TABLE(
  date date, score real, consistency_component real, load_component real,
  recovery_component real, volume_component real, streak_bonus real,
  ctl real, atl real
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT date, score, consistency_component, load_component,
         recovery_component, volume_component, streak_bonus, ctl, atl
  FROM public.vitality_score
  WHERE user_id = p_user_id AND user_id = auth.uid()
  ORDER BY date DESC
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.vitality_score_summary(uuid) TO authenticated;
