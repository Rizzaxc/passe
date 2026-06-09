-- Health achievements & gamification.
--
-- Adds the achievement-criteria grammar, per-user unlock ledger, denormalized
-- XP/level on `user`, and the evaluator/read RPCs. The evaluator RPC is the
-- SOLE mutator of all gamification state — RLS gives clients no write path.
--
-- Curve: cumulative XP to reach level L = 25·L·(L−1); cap L50 (= 61,250 XP).
-- See lib/health_tab/CLAUDE.md and the design spec for the full rationale.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. user: created_at (join date, the achievement backfill floor) + denormalized
--    xp / level (maintained only by evaluate_achievements).
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public."user"
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS xp        bigint      NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS level     integer     NOT NULL DEFAULT 1;

-- Backfill the true signup time from auth.users (DEFAULT now() is wrong for
-- existing rows).
UPDATE public."user" u
SET created_at = au.created_at
FROM auth.users au
WHERE au.id = u.id;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. achievement: criteria grammar + tier metadata + stable code slug.
--    Fix the over-permissive grant (catalog is read-only reference data).
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.achievement
  ADD COLUMN IF NOT EXISTS code        text,
  ADD COLUMN IF NOT EXISTS criteria    jsonb,
  ADD COLUMN IF NOT EXISTS difficulty  smallint,
  ADD COLUMN IF NOT EXISTS consistency smallint;

CREATE UNIQUE INDEX IF NOT EXISTS achievement_code_key ON public.achievement (code);

ALTER TABLE public.achievement
  DROP CONSTRAINT IF EXISTS achievement_tier_valid,
  ADD CONSTRAINT achievement_tier_valid CHECK (
    (difficulty IS NULL OR difficulty BETWEEN 1 AND 3) AND
    (consistency IS NULL OR consistency BETWEEN 1 AND 3)
  );

ALTER TABLE public.achievement
  DROP CONSTRAINT IF EXISTS achievement_criteria_valid,
  ADD CONSTRAINT achievement_criteria_valid CHECK (
    criteria IS NULL OR (
      (criteria->>'source') IN ('daily','activity','special')
      AND (criteria->>'agg') IN ('sum','count','max','session_streak','special')
      AND ((criteria->>'window') IS NULL OR (criteria->>'window') IN ('day','week','month','all_time'))
      -- repeatable badges must use a calendar window with a stable period_key
      AND (repeatable IS NOT TRUE OR (criteria->>'window') IN ('week','month'))
      -- session_streak qualifies per-session over activity data
      AND ((criteria->>'agg') <> 'session_streak'
           OR ((criteria->>'source') = 'activity' AND criteria ? 'session_min'))
      -- the 'special' source (e.g. wearable linked) stands alone
      AND (((criteria->>'source') = 'special') = ((criteria->>'agg') = 'special'))
    )
  );

-- Catalog is read-only reference data: clients SELECT, never mutate.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON TABLE public.achievement FROM anon, authenticated;

DROP POLICY IF EXISTS "Enable read access for all users" ON public.achievement;
CREATE POLICY "Enable read access for all users"
  ON public.achievement FOR SELECT USING (true);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. user_achievement: the unlock ledger. One row per earned instance, keyed by
--    period. Owner-read only; no client write path (evaluator is SECURITY DEFINER).
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_achievement (
  id             uuid        DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
  user_id        uuid        NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  achievement_id uuid        NOT NULL REFERENCES public.achievement(id) ON DELETE CASCADE,
  period_key     text        NOT NULL,           -- 'all' | '2026-06' | '2026-W23'
  xp_granted     bigint      NOT NULL,           -- snapshot of xp_reward at earn time
  earned_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, achievement_id, period_key)
);

COMMENT ON TABLE public.user_achievement IS
  'Per-user achievement unlock ledger; xp_granted snapshots achievement.xp_reward at earn time.';

ALTER TABLE public.user_achievement ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON TABLE public.user_achievement TO authenticated;
GRANT ALL    ON TABLE public.user_achievement TO service_role;

DROP POLICY IF EXISTS "Users see their own achievements" ON public.user_achievement;
CREATE POLICY "Users see their own achievements"
  ON public.user_achievement FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Level curve — single source of truth. C(L) = 25·L·(L−1), cap L50.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public._achievement_level_floor(p_level integer)
RETURNS bigint LANGUAGE sql IMMUTABLE SET search_path TO '' AS $$
  SELECT (25 * p_level * (p_level - 1))::bigint;
$$;

CREATE OR REPLACE FUNCTION public._achievement_level_for_xp(p_xp bigint)
RETURNS integer LANGUAGE sql IMMUTABLE SET search_path TO '' AS $$
  -- largest L (capped 1..50) with 25·L·(L−1) <= xp.
  SELECT LEAST(50, GREATEST(1,
    floor((25 + sqrt(625 + 100 * GREATEST(p_xp, 0)::numeric)) / 50)::int));
$$;

CREATE OR REPLACE FUNCTION public.user_level_summary(p_user_id uuid)
RETURNS TABLE(level integer, xp_total bigint, current_floor bigint, next_floor bigint)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_xp bigint; v_level int;
BEGIN
  SELECT COALESCE(u.xp, 0) INTO v_xp FROM public."user" u WHERE u.id = p_user_id;
  v_xp := COALESCE(v_xp, 0);
  v_level := public._achievement_level_for_xp(v_xp);
  RETURN QUERY SELECT
    v_level,
    v_xp,
    public._achievement_level_floor(v_level),
    CASE WHEN v_level >= 50 THEN NULL
         ELSE public._achievement_level_floor(v_level + 1) END;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Evaluator internals — the criteria interpreter.
-- ─────────────────────────────────────────────────────────────────────────────

-- Per-session metric resolver (incl. the virtual 3-zone TRIMP `session_load`).
CREATE OR REPLACE FUNCTION public._activity_metric_value(
  m public.activity_health_metrics, p_metric text
) RETURNS numeric LANGUAGE sql IMMUTABLE SET search_path TO '' AS $$
  SELECT CASE p_metric
    WHEN 'session_load' THEN
      (COALESCE(m.hr_zone_easy_seconds,0)
       + 2 * COALESCE(m.hr_zone_moderate_seconds,0)
       + 3 * COALESCE(m.hr_zone_hard_seconds,0)) / 60.0
    WHEN 'active_calories'          THEN COALESCE(m.active_calories,0)::numeric
    WHEN 'distance_meters'          THEN COALESCE(m.distance_meters,0)::numeric
    WHEN 'steps'                    THEN COALESCE(m.steps,0)::numeric
    WHEN 'hr_zone_hard_seconds'     THEN COALESCE(m.hr_zone_hard_seconds,0)::numeric
    WHEN 'hr_zone_moderate_seconds' THEN COALESCE(m.hr_zone_moderate_seconds,0)::numeric
    WHEN 'hr_zone_easy_seconds'     THEN COALESCE(m.hr_zone_easy_seconds,0)::numeric
    WHEN 'effort_score'             THEN COALESCE(m.effort_score,0)::numeric
    WHEN 'training_load'            THEN COALESCE(m.training_load,0)::numeric
    ELSE 0 END;
$$;

-- The period key a badge banks under, derived from its window.
CREATE OR REPLACE FUNCTION public._achievement_period_key(p_criteria jsonb)
RETURNS text LANGUAGE sql STABLE SET search_path TO '' AS $$
  SELECT CASE p_criteria->>'window'
    WHEN 'week'  THEN to_char(now(), 'IYYY"-W"IW')
    WHEN 'month' THEN to_char(now(), 'YYYY-MM')
    ELSE 'all'
  END;
$$;

-- Current aggregate value for one criteria, for one user, within the eligible
-- window. `p_eligible_from` = greatest(user.created_at, now()−90d).
CREATE OR REPLACE FUNCTION public._achievement_current_value(
  p_user_id uuid, p_criteria jsonb, p_eligible_from timestamptz
) RETURNS numeric LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_source      text    := p_criteria->>'source';
  v_agg         text    := p_criteria->>'agg';
  v_metric      text    := p_criteria->>'metric';
  v_window      text    := COALESCE(p_criteria->>'window', 'all_time');
  v_session_min numeric := (p_criteria->>'session_min')::numeric;
  v_row_min     numeric := COALESCE((p_criteria->>'row_min')::numeric, 1);
  v_start       timestamptz;
  v_result      numeric := 0;
BEGIN
  v_start := CASE v_window
    WHEN 'week'  THEN date_trunc('week',  now())
    WHEN 'month' THEN date_trunc('month', now())
    WHEN 'day'   THEN date_trunc('day',   now())
    ELSE p_eligible_from
  END;
  v_start := GREATEST(v_start, p_eligible_from);

  IF v_source = 'special' THEN
    RETURN CASE WHEN EXISTS(
      SELECT 1 FROM public.user_health_link l WHERE l.user_id = p_user_id
    ) THEN 1 ELSE 0 END;
  END IF;

  IF v_source = 'daily' THEN
    IF v_agg = 'sum' THEN
      SELECT COALESCE(SUM(CASE v_metric
        WHEN 'steps'                  THEN d.steps::numeric
        WHEN 'active_calories'        THEN d.active_calories::numeric
        WHEN 'distance_meters'        THEN d.distance_meters::numeric
        WHEN 'total_calories'         THEN d.total_calories::numeric
        WHEN 'total_activity_minutes' THEN d.total_activity_minutes::numeric
        WHEN 'sleep_minutes'          THEN d.sleep_minutes::numeric
        ELSE 0 END), 0) INTO v_result
      FROM public.daily_health_summary d
      WHERE d.user_id = p_user_id AND d.date >= v_start::date;
    ELSIF v_agg = 'count' THEN
      SELECT COUNT(*) INTO v_result
      FROM public.daily_health_summary d
      WHERE d.user_id = p_user_id AND d.date >= v_start::date
        AND (CASE v_metric
          WHEN 'activity_count' THEN d.activity_count::numeric
          WHEN 'steps'          THEN d.steps::numeric
          WHEN 'sleep_minutes'  THEN d.sleep_minutes::numeric
          WHEN 'active_calories'THEN d.active_calories::numeric
          ELSE 0 END) >= v_row_min;
    ELSIF v_agg = 'max' THEN
      SELECT COALESCE(MAX(CASE v_metric
        WHEN 'steps'           THEN d.steps::numeric
        WHEN 'active_calories' THEN d.active_calories::numeric
        WHEN 'distance_meters' THEN d.distance_meters::numeric
        ELSE 0 END), 0) INTO v_result
      FROM public.daily_health_summary d
      WHERE d.user_id = p_user_id AND d.date >= v_start::date;
    END IF;
    RETURN v_result;
  END IF;

  IF v_source = 'activity' THEN
    IF v_agg = 'sum' THEN
      SELECT COALESCE(SUM(public._activity_metric_value(m, v_metric)), 0) INTO v_result
      FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND a.start_time >= v_start AND a.start_time <= now();
    ELSIF v_agg = 'count' THEN
      SELECT COUNT(*) INTO v_result
      FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND a.start_time >= v_start AND a.start_time <= now();
    ELSIF v_agg = 'max' THEN
      SELECT COALESCE(MAX(public._activity_metric_value(m, v_metric)), 0) INTO v_result
      FROM public.activity_health_metrics m
      JOIN public.activity a ON a.id = m.activity_id
      WHERE m.user_id = p_user_id AND NOT m.dismissed
        AND a.start_time >= v_start AND a.start_time <= now();
    ELSIF v_agg = 'session_streak' THEN
      -- longest run of consecutive qualifying sessions (islands-and-gaps).
      WITH s AS (
        SELECT a.start_time,
          CASE WHEN public._activity_metric_value(m, v_metric) >= v_session_min
               THEN 1 ELSE 0 END AS ok
        FROM public.activity_health_metrics m
        JOIN public.activity a ON a.id = m.activity_id
        WHERE m.user_id = p_user_id AND NOT m.dismissed
          AND a.start_time >= v_start AND a.start_time <= now()
      ),
      grp AS (
        SELECT ok,
          row_number() OVER (ORDER BY start_time)
          - row_number() OVER (PARTITION BY ok ORDER BY start_time) AS g
        FROM s
      )
      SELECT COALESCE(MAX(cnt), 0) INTO v_result
      FROM (SELECT COUNT(*) AS cnt FROM grp WHERE ok = 1 GROUP BY g) t;
    END IF;
    RETURN v_result;
  END IF;

  RETURN 0;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Read RPC: per-badge progress + state for the achievements subtab.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.achievement_progress(p_user_id uuid)
RETURNS TABLE(
  achievement_id uuid, code text, name text, description text,
  difficulty smallint, consistency smallint, xp_reward bigint, repeatable boolean,
  current_value numeric, threshold numeric, progress numeric, state text, period_key text
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_eligible_from timestamptz;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT GREATEST(u.created_at, now() - interval '90 days')
    INTO v_eligible_from FROM public."user" u WHERE u.id = p_user_id;

  RETURN QUERY
  SELECT
    a.id, a.code, a.name, a.description, a.difficulty, a.consistency, a.xp_reward, a.repeatable,
    cv.val,
    th.thr,
    LEAST(1.0, CASE WHEN th.thr > 0 THEN cv.val / th.thr ELSE 0 END),
    CASE
      WHEN ua.id IS NOT NULL AND a.repeatable THEN 'earned_period'
      WHEN ua.id IS NOT NULL                  THEN 'done'
      WHEN cv.val <= 0                         THEN 'not_started'
      ELSE 'in_progress'
    END,
    pk.pkey
  FROM public.achievement a
  CROSS JOIN LATERAL (SELECT public._achievement_current_value(p_user_id, a.criteria, v_eligible_from) AS val) cv
  CROSS JOIN LATERAL (SELECT COALESCE((a.criteria->>'threshold')::numeric, 1) AS thr) th
  CROSS JOIN LATERAL (SELECT public._achievement_period_key(a.criteria) AS pkey) pk
  LEFT JOIN public.user_achievement ua
    ON ua.user_id = p_user_id AND ua.achievement_id = a.id AND ua.period_key = pk.pkey;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Write RPC: evaluate, persist unlocks, bank XP, recompute level.
--    Called at the end of HealthSyncController.syncNow(). Sole mutator.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.evaluate_achievements(p_user_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_eligible_from timestamptz;
  v_prev_level int;
  v_prev_xp    bigint;
  v_new_xp     bigint;
  v_new_level  int;
  a            RECORD;
  v_val        numeric;
  v_thr        numeric;
  v_cmp        text;
  v_pk         text;
  v_met        boolean;
  v_newly      jsonb := '[]'::jsonb;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  SELECT GREATEST(u.created_at, now() - interval '90 days'),
         COALESCE(u.xp, 0), COALESCE(u.level, 1)
    INTO v_eligible_from, v_prev_xp, v_prev_level
    FROM public."user" u WHERE u.id = p_user_id;

  FOR a IN SELECT * FROM public.achievement WHERE criteria IS NOT NULL LOOP
    v_thr := COALESCE((a.criteria->>'threshold')::numeric, 1);
    v_cmp := COALESCE(a.criteria->>'comparator', '>=');
    v_pk  := public._achievement_period_key(a.criteria);

    -- Already earned for this period? skip.
    CONTINUE WHEN EXISTS(
      SELECT 1 FROM public.user_achievement ua
      WHERE ua.user_id = p_user_id AND ua.achievement_id = a.id AND ua.period_key = v_pk
    );

    v_val := public._achievement_current_value(p_user_id, a.criteria, v_eligible_from);
    v_met := CASE WHEN v_cmp = '>' THEN v_val > v_thr ELSE v_val >= v_thr END;

    IF v_met THEN
      INSERT INTO public.user_achievement(user_id, achievement_id, period_key, xp_granted)
      VALUES (p_user_id, a.id, v_pk, a.xp_reward)
      ON CONFLICT (user_id, achievement_id, period_key) DO NOTHING;

      IF FOUND THEN
        v_newly := v_newly || jsonb_build_object(
          'code', a.code, 'name', a.name, 'xp', a.xp_reward,
          'difficulty', a.difficulty, 'consistency', a.consistency,
          'repeatable', a.repeatable);
      END IF;
    END IF;
  END LOOP;

  -- Authoritative recompute from the ledger.
  SELECT COALESCE(SUM(xp_granted), 0) INTO v_new_xp
    FROM public.user_achievement WHERE user_id = p_user_id;
  v_new_level := public._achievement_level_for_xp(v_new_xp);

  UPDATE public."user" SET xp = v_new_xp, level = v_new_level WHERE id = p_user_id;

  RETURN jsonb_build_object(
    'newly_unlocked', v_newly,
    'xp_total',       v_new_xp,
    'level',          v_new_level,
    'previous_level', v_prev_level,
    'leveled_up',     v_new_level > v_prev_level,
    'xp_gained',      v_new_xp - v_prev_xp
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.user_level_summary(uuid)   TO authenticated;
GRANT EXECUTE ON FUNCTION public.achievement_progress(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.evaluate_achievements(uuid) TO authenticated;
