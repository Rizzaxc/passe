-- my_schedule_data: return each row's source ids (lobby_id, course_id).
--
-- The Manage ▸ Schedule card routes a tap to the session's hub: the lobby
-- page, the course page, or the freeplay detail. The client used to recover
-- `lobby_id` with a second direct `activity` select, which also could have
-- carried `course_id` — except a student cannot SELECT a coach-proposed
-- course session at all (no course-member policy on `activity`; only the
-- proposer's own `user_id` row is visible). So course sessions came back
-- with no id and their cards were untappable. This function is already
-- SECURITY DEFINER and already decides who sees which row, so it is the
-- right place to hand the ids over; the client's extra query is gone.
--
-- Same body as schema/schedule_all_sports.sql + the two trailing columns.
-- A RETURNS TABLE change needs DROP first (the table desugars to OUT params).

DROP FUNCTION IF EXISTS public.my_schedule_data(bigint, timestamptz, timestamptz);

CREATE FUNCTION public.my_schedule_data(
  p_sport_id bigint,
  p_from timestamptz,
  p_to timestamptz
) RETURNS TABLE (
  id uuid,
  start_time timestamptz,
  end_time timestamptz,
  title text,
  meta text,
  tone text,
  recurrence_day_of_week smallint,
  lobby_id uuid,
  course_id uuid
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
    SELECT a.id, a.start_time, a.end_time, l.name::text,
           COALESCE(loc.name, '')::text, 'sport'::text, a.recurrence_day_of_week,
           a.lobby_id, NULL::uuid
    FROM public.activity a
    JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, public.lobby_primary_homeground_id(l.id))
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.lobby_id IN (SELECT lm.lobby_id FROM public.lobby_member lm WHERE lm.user_id = v_uid)
      AND a.start_time >= p_from AND a.start_time <= p_to

    UNION ALL

    -- A freeplay card opens the freeplay detail by activity id; lobby_id is
    -- only informational here (a seat holder needn't be a lobby member).
    SELECT a.id, a.start_time, a.end_time,
           coalesce(h.display_name, l.name::text, 'Xé vé')::text,
           COALESCE(loc.name, fa.venue_name, '')::text, 'freeplay'::text,
           a.recurrence_day_of_week,
           a.lobby_id, NULL::uuid
    FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id = a.id
    LEFT JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    LEFT JOIN public.lobby l ON l.id = a.lobby_id
    LEFT JOIN public.location loc ON loc.id = COALESCE(a.location_id, public.lobby_primary_homeground_id(l.id))
    WHERE (p_sport_id IS NULL OR a.sport_id = p_sport_id)
      AND a.start_time >= p_from AND a.start_time <= p_to
      AND EXISTS (SELECT 1 FROM public.freeplay_request r
                  WHERE r.activity_id = a.id AND r.user_id = v_uid AND r.status = 'accepted')

    UNION ALL

    SELECT a.id, a.start_time, a.end_time,
           coalesce(c.name, p.display_name)::text,
           COALESCE(loc.name, '')::text, 'coach'::text, a.recurrence_day_of_week,
           NULL::uuid, a.course_id
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
$function$;

REVOKE ALL ON FUNCTION public.my_schedule_data(bigint, timestamptz, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_schedule_data(bigint, timestamptz, timestamptz) TO authenticated, service_role;
