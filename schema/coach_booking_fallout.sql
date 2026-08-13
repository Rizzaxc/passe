-- ============================================================================
-- coach_booking_fallout.sql — Part D of the coaching rework.
-- Apply AFTER referee_booking_rename.sql.
--
-- The functions here don't just mention `professional_booking` — they encode
-- the assumption that "a coach lesson is a booking". Under the course model a
-- coach lesson is an ordinary `activity` with a `course_id`, so each of these
-- changes meaning, not just a table name.
--
-- The wall-post change is a genuine simplification: the two-hook model
-- (activity XOR booking) collapses to a single `activity_id`, because a coach
-- lesson now *is* an activity. That removes the exclusivity trigger, the
-- second partial unique index, and a branch of the visibility predicate.
--
-- Idempotent / re-runnable. Needs to be applied to the live Supabase project.
-- ============================================================================

-- ── 1. Attachment guard: referee-only ───────────────────────────────────────
-- The coach branch is gone with `activity.coach_booking_id`.
CREATE OR REPLACE FUNCTION public.fn_activity_attachment_role_check()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
  IF NEW.referee_booking_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.referee_booking pb
      JOIN public.professional p ON p.id = pb.professional_id
      WHERE pb.id = NEW.referee_booking_id
        AND p.professional_role = 'referee'
  ) THEN
    RAISE EXCEPTION 'referee_booking_id % must reference a referee booking', NEW.referee_booking_id;
  END IF;
  RETURN NEW;
END;
$$;

-- Keeps the original trigger name (no `trg_` prefix) so it matches the one
-- schema/activity_professional_attachment.sql created.
DROP TRIGGER IF EXISTS activity_attachment_role_check ON public.activity;
CREATE TRIGGER activity_attachment_role_check
  BEFORE INSERT OR UPDATE OF referee_booking_id ON public.activity
  FOR EACH ROW EXECUTE FUNCTION public.fn_activity_attachment_role_check();

-- ── 2. Wall posts: one hook, not two ────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_wall_post_source_exclusivity ON public.wall_post;
DROP FUNCTION IF EXISTS public.fn_wall_post_source_exclusivity() CASCADE;
DROP INDEX IF EXISTS public.wall_post_one_per_booking;
ALTER TABLE public.wall_post DROP COLUMN IF EXISTS professional_booking_id;

-- `activity_id` is now the only hook, and it must be present at insert.
ALTER TABLE public.wall_post DROP CONSTRAINT IF EXISTS wall_post_requires_activity;
ALTER TABLE public.wall_post ADD CONSTRAINT wall_post_requires_activity
  CHECK (activity_id IS NOT NULL) NOT VALID;

-- Sessions a user may post about: anything they RSVP'd `going` to in the last
-- 7 days. A coach lesson qualifies through the same path as any other activity
-- now, so the old booking UNION branch is gone.
-- `booking_id` is replaced by `course_id`: the composer used the old column
-- only to tell a coach lesson from a lobby session (for the icon and the
-- label), and that distinction now lives on the activity itself.
DROP FUNCTION IF EXISTS public.postable_activities();

CREATE OR REPLACE FUNCTION public.postable_activities()
RETURNS TABLE(
  activity_id uuid, course_id uuid, sport_id bigint, lobby_id uuid,
  source_label text, start_time timestamptz, venue_name text, already_posted boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.id, a.course_id, a.sport_id, a.lobby_id,
    coalesce(l.name, h.display_name, co.name, pr.display_name, 'Xé vé'),
    a.start_time, coalesce(loc.name, fa.venue_name),
    EXISTS(SELECT 1 FROM public.wall_post w
           WHERE w.activity_id = a.id AND w.author_id = auth.uid())
  FROM public.activity a
  JOIN public.activity_confirmation c
    ON c.activity_id = a.id AND c.user_id = auth.uid() AND c.attendance = 'going'
  LEFT JOIN public.lobby l ON l.id = a.lobby_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  LEFT JOIN public.course co ON co.id = a.course_id
  LEFT JOIN public.professional pr ON pr.id = co.professional_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  WHERE a.start_time < now() AND a.start_time > now() - interval '7 days'
    AND (a.course_id IS NULL OR a.proposal_status = 'approved')
  ORDER BY a.start_time DESC
$$;

-- ── 3. Health: the coaching context is a course, not a booking ──────────────
-- Health metrics stay private to the student throughout: nothing here (and no
-- course RPC) exposes them to the coach or to other members.
CREATE OR REPLACE FUNCTION public.health_capture_candidates(p_window_start timestamptz)
RETURNS TABLE(
  activity_id uuid, start_time timestamptz, end_time timestamptz,
  sport_id bigint, source text, confirmed boolean
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY SELECT a.id, a.start_time, a.end_time, a.sport_id,
    CASE WHEN a.course_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    EXISTS(SELECT 1 FROM public.activity_confirmation ac
           WHERE ac.activity_id = a.id AND ac.user_id = v_uid)
  FROM public.activity a
  WHERE a.end_time IS NOT NULL AND a.end_time < now() AND a.end_time >= p_window_start
    AND (a.user_id = v_uid
      OR EXISTS(SELECT 1 FROM public.activity_confirmation ac
                WHERE ac.activity_id = a.id AND ac.user_id = v_uid))
    AND NOT EXISTS(SELECT 1 FROM public.activity_health_metrics m
                   WHERE m.activity_id = a.id AND m.user_id = v_uid)
  ORDER BY a.end_time DESC;
END
$$;

CREATE OR REPLACE FUNCTION public.activity_health_data(p_sport_id bigint)
RETURNS TABLE(
  activity_id uuid, start_time timestamptz, end_time timestamptz,
  duration_minutes integer, location_label text, source text, steps integer,
  distance_meters real, active_calories real, avg_heart_rate integer,
  max_heart_rate integer, min_heart_rate integer, hrv_sdnn_ms real,
  hrv_rmssd_ms real, hr_zone_easy_seconds integer, hr_zone_moderate_seconds integer,
  hr_zone_hard_seconds integer, training_load real, effort_score real,
  workout_type text, recorded_at timestamptz
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY SELECT m.activity_id, a.start_time, a.end_time,
    CASE WHEN a.end_time IS NOT NULL
         THEN (extract(epoch FROM (a.end_time - a.start_time))/60)::int END,
    coalesce(loc.name, fa.venue_name),
    CASE WHEN a.course_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    m.steps, m.distance_meters, m.active_calories, m.avg_heart_rate, m.max_heart_rate,
    m.min_heart_rate, m.hrv_sdnn_ms, m.hrv_rmssd_ms, m.hr_zone_easy_seconds,
    m.hr_zone_moderate_seconds, m.hr_zone_hard_seconds, m.training_load,
    m.effort_score, m.workout_type, m.recorded_at
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  WHERE m.user_id = v_uid AND m.dismissed = false AND a.sport_id = p_sport_id
  ORDER BY a.start_time DESC;
END
$$;

-- ── 4. Schedule: the coach branch becomes course sessions ───────────────────
CREATE OR REPLACE FUNCTION public.my_schedule_data(
  p_sport_id bigint, p_from timestamptz, p_to timestamptz
) RETURNS TABLE(
  id uuid, start_time timestamptz, end_time timestamptz, title text,
  meta text, tone text, recurrence_day_of_week smallint
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
    SELECT a.id, a.start_time, a.end_time, l.name::text,
           COALESCE(loc.name, '')::text, 'sport'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, l.home_ground)
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.lobby_id IN (SELECT lobby_id FROM public.lobby_member WHERE user_id = v_uid)
      AND a.start_time >= p_from AND a.start_time <= p_to

    UNION ALL

    -- Freeplay sessions the caller holds an accepted seat for.
    SELECT a.id, a.start_time, a.end_time,
           coalesce(h.display_name, 'Xé vé')::text,
           COALESCE(loc.name, fa.venue_name, '')::text, 'freeplay'::text,
           a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id = a.id
    LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    LEFT JOIN public.location loc ON loc.id = a.location_id
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND EXISTS (SELECT 1 FROM public.freeplay_request r
                  WHERE r.activity_id = a.id AND r.user_id = v_uid AND r.status = 'accepted')

    UNION ALL

    -- Course sessions: approved only. A pending student proposal is not on
    -- anyone's calendar until the coach approves it.
    SELECT a.id, a.start_time, a.end_time,
           coalesce(c.name, p.display_name)::text,
           COALESCE(loc.name, '')::text, 'coach'::text, a.recurrence_day_of_week
    FROM public.activity a
    JOIN public.course c ON c.id = a.course_id
    JOIN public.professional p ON p.id = c.professional_id
    LEFT JOIN public.location loc ON loc.id = a.location_id
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.proposal_status = 'approved'
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND (
        EXISTS (SELECT 1 FROM public.course_member m
                WHERE m.course_id = c.id AND m.user_id = v_uid AND m.left_at IS NULL)
        OR p.linked_user_id = v_uid
      );
END
$$;

-- ── 5. Reminders: T-1h before a course session ──────────────────────────────
-- Referee bookings keep their own reminder; the coach half now rides on
-- course activities, which have no `reminder_sent_at` of their own — a
-- dedicated table records what's already been sent so the 1-minute cron tick
-- can't double-remind.
CREATE TABLE IF NOT EXISTS public.activity_reminder_sent (
  activity_id uuid PRIMARY KEY REFERENCES public.activity(id) ON DELETE CASCADE,
  sent_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.activity_reminder_sent ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.activity_reminder_sent FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_process_reminders()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE r record;
BEGIN
  -- Referee bookings (iced behind the client flag, but the pipeline stays honest).
  FOR r IN
    SELECT b.id, b.booking_time_start, b.client_user_id
      FROM public.referee_booking b
      WHERE b.reminder_sent_at IS NULL
        AND b.status = 'confirmed'
        AND b.booking_time_start > now()
        AND b.booking_time_start <= now() + interval '1 hour'
      FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.fn_enqueue_notification(
      'pro_session_reminder',
      (SELECT array_agg(uid) FROM (
          SELECT r.client_user_id AS uid
          UNION
          SELECT au.user_id FROM public.referee_booking_additional_users au
          WHERE au.booking_id = r.id
       ) s),
      'Sắp tới giờ trận đấu',
      'Trận đấu bắt đầu lúc '
        || to_char(r.booking_time_start AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      jsonb_build_object('target_id', r.id::text)
    );
    UPDATE public.referee_booking SET reminder_sent_at = now() WHERE id = r.id;
  END LOOP;

  -- Course sessions: remind everyone who said they're going.
  FOR r IN
    SELECT a.id, a.start_time, a.course_id
      FROM public.activity a
      WHERE a.course_id IS NOT NULL
        AND a.proposal_status = 'approved'
        AND a.start_time > now()
        AND a.start_time <= now() + interval '1 hour'
        AND NOT EXISTS (SELECT 1 FROM public.activity_reminder_sent s
                        WHERE s.activity_id = a.id)
      FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.fn_enqueue_notification(
      'pro_session_reminder',
      (SELECT array_agg(ac.user_id) FROM public.activity_confirmation ac
       WHERE ac.activity_id = r.id AND ac.attendance = 'going'),
      'Sắp tới giờ tập với coach',
      'Buổi tập của bạn bắt đầu lúc '
        || to_char(r.start_time AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI'),
      jsonb_build_object('course_id', r.course_id::text, 'activity_id', r.id::text)
    );
    INSERT INTO public.activity_reminder_sent(activity_id) VALUES (r.id)
    ON CONFLICT (activity_id) DO NOTHING;
  END LOOP;
END;
$$;

-- ── 6. Retire the coach-booking notification kinds ──────────────────────────
-- The enum values stay (Postgres can't drop one, and old outbox rows still
-- reference them); the allowlist is what actually silences them.
UPDATE public.enabled_notification_kind SET enabled = false, updated_at = now()
WHERE kind IN ('professional_booking_requested',
               'professional_booking_confirmed',
               'professional_booking_rejected');

INSERT INTO public.enabled_notification_kind (kind, enabled) VALUES
  ('course_message', true),
  ('course_enrollment_offer', true),
  ('course_enrollment_accepted', true),
  ('course_activity_proposed', true),
  ('course_activity_approved', true),
  ('course_activity_changed', true),
  ('course_session_report', true),
  ('course_ended', true),
  ('course_member_removed', true)
ON CONFLICT (kind) DO UPDATE SET enabled = excluded.enabled;

-- ── 7. Tagging: a coach lesson is taggable as an activity ───────────────────
-- The `p_booking_id` branch is retired along with coach bookings; a course
-- session goes through the activity branch like everything else. Callers that
-- still pass the old 2-argument form would silently get the wrong overload, so
-- the old signature is dropped rather than left in place.
DROP FUNCTION IF EXISTS public.taggable_users(uuid, uuid);

CREATE OR REPLACE FUNCTION public.taggable_users(p_activity_id uuid)
RETURNS TABLE(user_id uuid, username text, tag_number text, details jsonb, attended boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_allowed boolean;
BEGIN
    IF v_uid IS NULL OR p_activity_id IS NULL THEN
        RETURN;
    END IF;

    -- Either a lobby mate on that activity, or a member of its course.
    SELECT EXISTS(
        SELECT 1 FROM public.activity a
        JOIN public.lobby_member m ON m.lobby_id = a.lobby_id
        WHERE a.id = p_activity_id AND m.user_id = v_uid
        UNION ALL
        SELECT 1 FROM public.activity a
        JOIN public.course_member cm ON cm.course_id = a.course_id
        WHERE a.id = p_activity_id AND cm.user_id = v_uid AND cm.left_at IS NULL
        UNION ALL
        SELECT 1 FROM public.activity a
        JOIN public.course c ON c.id = a.course_id
        JOIN public.professional p ON p.id = c.professional_id
        WHERE a.id = p_activity_id AND p.linked_user_id = v_uid
    ) INTO v_allowed;

    IF NOT v_allowed THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT u.id, u.username::text, u.tag_number::text, u.details,
           bool_or(x.attended)
    FROM (
        SELECT c.user_id AS uid, true AS attended
            FROM public.activity_confirmation c
            WHERE c.activity_id = p_activity_id AND c.attendance = 'going'
        UNION ALL
        SELECT m.user_id, false
            FROM public.lobby_member m
            JOIN public.activity a ON a.lobby_id = m.lobby_id
            WHERE a.id = p_activity_id
        UNION ALL
        SELECT cm.user_id, false
            FROM public.course_member cm
            JOIN public.activity a ON a.course_id = cm.course_id
            WHERE a.id = p_activity_id AND cm.left_at IS NULL
        UNION ALL
        SELECT p.linked_user_id, true
            FROM public.activity a
            JOIN public.course c ON c.id = a.course_id
            JOIN public.professional p ON p.id = c.professional_id
            WHERE a.id = p_activity_id AND p.linked_user_id IS NOT NULL
    ) x
    JOIN public."user" u ON u.id = x.uid
    WHERE u.id <> v_uid
    GROUP BY u.id, u.username, u.tag_number, u.details
    ORDER BY bool_or(x.attended) DESC, u.username;
END;
$$;

REVOKE ALL ON FUNCTION public.taggable_users(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.taggable_users(uuid) TO authenticated;

-- ── 8. Retire the coach-booking RPCs ────────────────────────────────────────
-- Their referee-facing replacements were created under the new names by
-- referee_booking_rename.sql; these bodies still name a table that no longer
-- exists, so leaving them would just be a trap.
DROP FUNCTION IF EXISTS public.request_professional_booking(uuid, uuid, timestamptz, timestamptz, text, uuid, integer, text, uuid[]) CASCADE;
DROP FUNCTION IF EXISTS public.accept_professional_booking(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.reject_professional_booking(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.cancel_professional_booking(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.complete_professional_booking(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.professional_booking_conflicts(uuid, timestamptz, timestamptz) CASCADE;

-- Anything left over from an older signature: drop by name, whatever the
-- argument list turned out to be.
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS signature
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN ('request_professional_booking','accept_professional_booking',
                        'reject_professional_booking','cancel_professional_booking',
                        'complete_professional_booking','professional_booking_conflicts',
                        'fn_notify_professional_booking_created',
                        'fn_notify_professional_booking_status_changed',
                        'fn_guard_professional_booking_review',
                        'professional_booking_review_updated_trigger_fn',
                        'fn_complete_professional_booking_on_match')
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', r.signature);
  END LOOP;
END $$;

-- ── 9. Re-attach the triggers CASCADE took ──────────────────────────────────
-- Dropping the old function names took their triggers with them; the renamed
-- functions need re-wiring. `professional_booking_increment_package_progress`
-- is deliberately NOT restored — packages are gone.

DROP TRIGGER IF EXISTS referee_booking_created_notify ON public.referee_booking;
CREATE TRIGGER referee_booking_created_notify
  AFTER INSERT ON public.referee_booking
  FOR EACH ROW EXECUTE FUNCTION public.fn_notify_referee_booking_created();

DROP TRIGGER IF EXISTS referee_booking_status_changed_notify ON public.referee_booking;
CREATE TRIGGER referee_booking_status_changed_notify
  AFTER UPDATE ON public.referee_booking
  FOR EACH ROW WHEN (
    new.status IS DISTINCT FROM old.status
    AND new.status = ANY (ARRAY['confirmed'::public.professional_booking_status,
                                'rejected'::public.professional_booking_status])
  )
  EXECUTE FUNCTION public.fn_notify_referee_booking_status_changed();

DROP TRIGGER IF EXISTS referee_booking_review_guard ON public.referee_booking_review;
CREATE TRIGGER referee_booking_review_guard
  BEFORE INSERT OR UPDATE ON public.referee_booking_review
  FOR EACH ROW EXECUTE FUNCTION public.fn_guard_referee_booking_review();

-- Referee reviews and course reviews both roll into professional.average_rating;
-- each trigger recomputes over its own source for the professional it touches.
DROP TRIGGER IF EXISTS professional_review_stats_trigger ON public.referee_booking_review;
CREATE TRIGGER professional_review_stats_trigger
  AFTER INSERT OR DELETE OR UPDATE ON public.referee_booking_review
  FOR EACH ROW EXECUTE FUNCTION public.referee_booking_review_updated_trigger_fn();

-- Recording a challenge result closes the referee's booking.
DROP TRIGGER IF EXISTS lobby_match_complete_referee_booking ON public.lobby_match;
CREATE TRIGGER lobby_match_complete_referee_booking
  AFTER INSERT ON public.lobby_match
  FOR EACH ROW WHEN (new.referee_booking_id IS NOT NULL)
  EXECUTE FUNCTION public.fn_complete_referee_booking_on_match();

-- ── 10. Wall post creation and tag guard ────────────────────────────────────
-- Both still branched on the booking hook. `create_wall_post` keeps its
-- signature (the client passes a null booking id today) but the parameter is
-- retired: a coach lesson arrives as an activity id now.
DROP FUNCTION IF EXISTS public.create_wall_post(uuid, uuid, text[], text, smallint, uuid[]) CASCADE;
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname = 'create_wall_post'
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', r.signature);
  END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.create_wall_post(
  p_activity_id uuid, p_media jsonb, p_caption text DEFAULT NULL::text,
  p_ttl_days smallint DEFAULT 7, p_tagged_users uuid[] DEFAULT '{}'::uuid[]
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_sport bigint; v_lobby uuid;
  v_label text; v_start timestamptz; v_venue text; v_tag uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  IF p_activity_id IS NULL THEN RAISE EXCEPTION 'an activity is required'; END IF;
  IF NOT public.fn_valid_wall_post_media(p_media) THEN
    RAISE EXCEPTION 'a post needs 1-4 media items, each an image or a video under 1 minute';
  END IF;
  IF array_length(p_tagged_users,1) > 5 THEN
    RAISE EXCEPTION 'a post can tag at most 5 people';
  END IF;

  -- A coach lesson is just an activity now, so it resolves through the same
  -- branch as a lobby session or a freeplay game — the course's name (falling
  -- back to the coach's) is the label.
  SELECT a.sport_id, a.lobby_id,
         coalesce(l.name, h.display_name, co.name, pr.display_name, 'Xé vé'),
         a.start_time, coalesce(loc.name, fa.venue_name)
  INTO v_sport, v_lobby, v_label, v_start, v_venue
  FROM public.activity a
  LEFT JOIN public.lobby l ON l.id = a.lobby_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id = a.id
  LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  LEFT JOIN public.course co ON co.id = a.course_id
  LEFT JOIN public.professional pr ON pr.id = co.professional_id
  LEFT JOIN public.location loc ON loc.id = a.location_id
  WHERE a.id = p_activity_id
    AND a.start_time < now() AND a.start_time > now() - interval '7 days'
    AND (a.course_id IS NULL OR a.proposal_status = 'approved')
    AND EXISTS(SELECT 1 FROM public.activity_confirmation c
               WHERE c.activity_id = a.id AND c.user_id = v_uid AND c.attendance = 'going');
  IF v_start IS NULL THEN
    RAISE EXCEPTION 'activity is not postable (must be within 7 days and RSVP''d going)';
  END IF;

  INSERT INTO public.wall_post(author_id, activity_id, sport_id, lobby_id,
    source_label, source_start_time, source_venue_name, caption, media, ttl_days, expires_at)
  VALUES(v_uid, p_activity_id, coalesce(v_sport,0), v_lobby, v_label, v_start, v_venue,
    nullif(btrim(p_caption),''), p_media, p_ttl_days, now() + (p_ttl_days||' days')::interval)
  RETURNING id INTO v_id;

  FOREACH v_tag IN ARRAY coalesce(p_tagged_users,'{}'::uuid[]) LOOP
    INSERT INTO public.wall_post_tag(post_id,user_id) VALUES(v_id,v_tag) ON CONFLICT DO NOTHING;
  END LOOP;
  RETURN v_id;
END
$$;

REVOKE ALL ON FUNCTION public.create_wall_post(uuid, jsonb, text, smallint, uuid[])
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_wall_post(uuid, jsonb, text, smallint, uuid[])
  TO authenticated;

-- Tag guard: the booking branch is gone, and course members join lobby mates
-- and attendees as legitimate tag targets.
CREATE OR REPLACE FUNCTION public.fn_wall_post_tag_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_activity uuid;
    v_lobby    uuid;
    v_count    int;
BEGIN
    SELECT activity_id, lobby_id INTO v_activity, v_lobby
      FROM public.wall_post WHERE id = new.post_id;

    SELECT count(*) INTO v_count
      FROM public.wall_post_tag WHERE post_id = new.post_id;
    IF v_count >= 5 THEN
        RAISE EXCEPTION 'a post can tag at most 5 people';
    END IF;

    IF v_activity IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM public.activity_confirmation c
                WHERE c.activity_id = v_activity AND c.user_id = new.user_id
            UNION ALL
            SELECT 1 FROM public.lobby_member m
                WHERE m.lobby_id = v_lobby AND m.user_id = new.user_id
            UNION ALL
            SELECT 1 FROM public.activity a
                JOIN public.course_member cm ON cm.course_id = a.course_id
                WHERE a.id = v_activity AND cm.user_id = new.user_id AND cm.left_at IS NULL
            UNION ALL
            SELECT 1 FROM public.activity a
                JOIN public.course c ON c.id = a.course_id
                JOIN public.professional p ON p.id = c.professional_id
                WHERE a.id = v_activity AND p.linked_user_id = new.user_id
        ) THEN
            RAISE EXCEPTION 'can only tag attendees, lobby members or course members';
        END IF;
    END IF;

    RETURN new;
END;
$$;

-- ── 11. Two stragglers that still named the coach column ────────────────────
-- Neither showed up in the "references professional_booking" sweep because
-- they only mention `activity.coach_booking_id`, which is now gone.

-- Breaks the RLS recursion between `activity` and the booking table (see
-- schema/fix_activity_professional_booking_rls_recursion.sql); referee-only now.
CREATE OR REPLACE FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid)
RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.activity a
    WHERE a.referee_booking_id = p_booking_id
      AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
  );
END;
$$;

-- The recurring-series sweep only mentioned the coach column in a comment
-- listing what it deliberately does NOT copy to a new occurrence; the comment
-- is corrected so it doesn't send the next reader looking for a dead column.
COMMENT ON FUNCTION public.fn_sweep_recurring_activities() IS
  'Materialises the next occurrence of each recurring series. Per-occurrence '
  'fields (referee_booking_id, challenge_id, manager_confirmed_at, '
  'proposal_status) are deliberately not carried over from the template.';

-- ── 12. Notification centre presentation ────────────────────────────────────
-- `fn_notification_presentation` resolves display detail (time, venue, amount)
-- for a notification-centre row. Its booking branch still named the pre-rename
-- table, which would raise "relation public.professional_booking does not
-- exist" the first time anyone opened a notification carrying a booking_id.
--
-- It didn't surface in the sweeps above because it reads the booking only to
-- decorate a row — nothing about it looked coach-specific.
--
-- Rewritten from the live definition with the single table reference swapped,
-- rather than re-typed, so nothing else in a long function can drift. The
-- guard makes a re-run against an already-fixed database a no-op instead of a
-- silent partial edit.
DO $$
DECLARE v_def text; v_hits int;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO v_def
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'fn_notification_presentation';

  IF v_def IS NULL THEN RETURN; END IF;

  v_hits := (length(v_def) - length(replace(v_def, 'public.professional_booking b', '')))
            / length('public.professional_booking b');
  IF v_hits = 0 THEN RETURN; END IF;
  IF v_hits <> 1 THEN
    RAISE EXCEPTION 'expected exactly one booking-table reference, found %', v_hits;
  END IF;

  EXECUTE replace(v_def, 'public.professional_booking b', 'public.referee_booking b');
END $$;
