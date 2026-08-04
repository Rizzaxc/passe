-- Social achievements — extends the achievement-criteria grammar
-- (schema/achievement_gamification.sql) with a `social` source.
--
-- Wall posts and reactions are ephemeral (1/3/7-day TTL sweep + `ON DELETE
-- CASCADE` from post to reaction), so a lifetime/monthly badge can't be
-- computed by querying `wall_post`/`wall_post_reaction` directly the way
-- health badges query `daily_health_summary`/`activity_health_metrics` (which
-- are never deleted) — the rows the criteria need to count would vanish out
-- from under it. `social_event` is a small append-only log, populated by
-- triggers at write time, that survives the post's own deletion.
--
-- Self-reactions (author reacting to their own post) are deliberately not
-- logged — RLS allows it (an author can always see their own post), but
-- counting it would let "reactions received" / "posts reacted to" be farmed
-- with zero other participants.
--
-- Depends on: schema/wall_post.sql, schema/achievement_gamification.sql.
-- Idempotent / re-runnable.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. social_event: append-only log, independent of wall_post's lifecycle.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.social_event (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  kind       text NOT NULL CHECK (kind IN ('post_created', 'reaction_received', 'reaction_given')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS social_event_user_kind_idx
  ON public.social_event (user_id, kind, created_at);

-- Internal bookkeeping only — no client read/write path. The evaluator
-- reads it via SECURITY DEFINER (table owner bypasses RLS), same pattern as
-- `wall_post_gc`.
ALTER TABLE public.social_event ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.social_event FROM anon, authenticated, public;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Triggers that populate the log. AFTER INSERT only: `react_to_wall_post`
--    upserts (`ON CONFLICT DO UPDATE`), and Postgres fires the row-level
--    UPDATE trigger (not INSERT) when the upsert hits the conflict path — so
--    changing your emoji, or clearing then re-reacting via UPDATE, never
--    re-logs an event. A delete-then-reinsert (clear, then react again) does
--    log a second time; that's an accepted, rare edge case.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public._fn_social_event_on_post()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  INSERT INTO public.social_event (user_id, kind) VALUES (NEW.author_id, 'post_created');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_social_event_on_post ON public.wall_post;
CREATE TRIGGER trg_social_event_on_post
  AFTER INSERT ON public.wall_post
  FOR EACH ROW EXECUTE FUNCTION public._fn_social_event_on_post();

CREATE OR REPLACE FUNCTION public._fn_social_event_on_reaction()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_author uuid;
BEGIN
  SELECT author_id INTO v_author FROM public.wall_post WHERE id = NEW.post_id;

  IF v_author IS NOT NULL AND v_author IS DISTINCT FROM NEW.user_id THEN
    INSERT INTO public.social_event (user_id, kind) VALUES (v_author, 'reaction_received');
    INSERT INTO public.social_event (user_id, kind) VALUES (NEW.user_id, 'reaction_given');
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_social_event_on_reaction ON public.wall_post_reaction;
CREATE TRIGGER trg_social_event_on_reaction
  AFTER INSERT ON public.wall_post_reaction
  FOR EACH ROW EXECUTE FUNCTION public._fn_social_event_on_reaction();

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Widen the criteria grammar: add 'social' as a valid source.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.achievement
  DROP CONSTRAINT IF EXISTS achievement_criteria_valid,
  ADD CONSTRAINT achievement_criteria_valid CHECK (
    criteria IS NULL OR (
      (criteria->>'source') IN ('daily','activity','special','social')
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Evaluator: add the 'social' branch. Re-declares the whole function (same
--    signature as schema/achievement_gamification.sql) with one added IF arm;
--    metric is a social_event.kind value (post_created | reaction_received |
--    reaction_given), agg is always 'count'.
-- ─────────────────────────────────────────────────────────────────────────────
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

  IF v_source = 'social' THEN
    IF v_agg = 'count' THEN
      SELECT COUNT(*) INTO v_result
      FROM public.social_event e
      WHERE e.user_id = p_user_id AND e.kind = v_metric
        AND e.created_at >= v_start AND e.created_at <= now();
    END IF;
    RETURN v_result;
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
