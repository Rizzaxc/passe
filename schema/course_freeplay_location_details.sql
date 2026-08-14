-- Carry the shared location row's complete handoff/edit details through
-- Course and Freeplay. Manual entries are already resolved client-side via
-- create_location, so activity.location_id remains the single source of
-- truth; these functions only expose that row and allow a Host to replace it.

-- ── Course detail ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.course_detail_data(p_course_id uuid)
RETURNS TABLE(
  course_id uuid, conversation_id uuid, name text, description text, status text,
  sport_id bigint, professional_id uuid, coach_name text, coach_user_id uuid,
  is_coach boolean, my_member_status text, target_session_count integer,
  held_session_count integer, members jsonb, sessions jsonb, reports jsonb,
  my_review_rating smallint
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_is_coach boolean;
BEGIN
  v_is_coach := public.fn_is_course_coach(p_course_id, v_uid);
  IF NOT v_is_coach AND NOT public.fn_is_course_member(p_course_id, v_uid) THEN
    RAISE EXCEPTION 'course not found';
  END IF;

  RETURN QUERY
  SELECT c.id, conv.id, c.name, c.description, c.status::text, c.sport_id,
         c.professional_id, p.display_name, p.linked_user_id, v_is_coach,
         (SELECT m.status::text FROM public.course_member m
          WHERE m.course_id = c.id AND m.user_id = v_uid AND m.left_at IS NULL),
         c.target_session_count, public.fn_course_held_sessions(c.id),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'user_id', m.user_id, 'username', u.username,
             'generated_avatar', u.details->>'generatedAvatar',
             'status', m.status::text, 'joined_at', m.joined_at)
             ORDER BY u.username)
           FROM public.course_member m JOIN public."user" u ON u.id = m.user_id
           WHERE m.course_id = c.id AND m.left_at IS NULL), '[]'::jsonb),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', a.id, 'start_time', a.start_time, 'end_time', a.end_time,
             'location_id', a.location_id,
             'venue_name', loc.name,
             'street_address', coalesce(
               nullif(btrim(loc.full_address), ''),
               nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
                 nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
                 nullif(btrim(loc.city), '')), '')
             ),
             'location_street_number', loc.street_number,
             'location_street_name', loc.street_name,
             'location_district', loc.district,
             'location_city', loc.city,
             'location_lat', loc.lat, 'location_lon', loc.lon,
             'note', a.note, 'proposal_status', a.proposal_status::text,
             'proposed_by', a.proposed_by,
             'my_attendance', (SELECT ac.attendance::text FROM public.activity_confirmation ac
                               WHERE ac.activity_id = a.id AND ac.user_id = v_uid),
             'going_count', (SELECT count(*) FROM public.activity_confirmation ac
                             WHERE ac.activity_id = a.id AND ac.attendance = 'going'))
             ORDER BY a.start_time)
           FROM public.activity a
           LEFT JOIN public.location loc ON loc.id = a.location_id
           WHERE a.course_id = c.id
             AND a.proposal_status IN ('approved','pending')), '[]'::jsonb),
         coalesce((
           SELECT jsonb_agg(jsonb_build_object(
             'activity_id', r.activity_id, 'student_id', r.student_id,
             'body', r.body, 'created_at', r.created_at)
             ORDER BY r.created_at DESC)
           FROM public.course_session_report r
           WHERE r.course_id = c.id
             AND (v_is_coach OR r.student_id = v_uid)), '[]'::jsonb),
         (SELECT rv.rating FROM public.course_review rv
          WHERE rv.course_id = c.id AND rv.student_id = v_uid)
  FROM public.course c
  JOIN public.professional p ON p.id = c.professional_id
  LEFT JOIN public.conversation conv ON conv.course_id = c.id
  WHERE c.id = p_course_id;
END
$$;

REVOKE ALL ON FUNCTION public.course_detail_data(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.course_detail_data(uuid) TO authenticated;

-- ── Freeplay detail + Host management ──────────────────────────────────────

DROP FUNCTION IF EXISTS public.freeplay_activity_detail_data(uuid);

CREATE FUNCTION public.freeplay_activity_detail_data(p_activity_id uuid)
RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text,
  description text, start_time timestamptz, end_time timestamptz,
  location_id uuid, venue_name text, street_address text,
  location_street_number text, location_street_name text,
  location_district text, location_city text,
  location_lat double precision, location_lon double precision,
  capacity integer, accepted_count bigint, male_price numeric, female_price numeric,
  recommended_skills text[], my_request_id uuid, my_request_status text, roster jsonb
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_allowed boolean;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.activity a
    JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    WHERE a.id=p_activity_id AND (
      h.status='active' OR h.user_id=v_uid OR EXISTS(
        SELECT 1 FROM public.freeplay_request r
        WHERE r.activity_id=a.id AND r.user_id=v_uid)))
  INTO v_allowed;
  IF NOT v_allowed THEN RETURN; END IF;

  RETURN QUERY
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    a.location_id, coalesce(loc.name,fa.venue_name),
    coalesce(
      nullif(btrim(loc.full_address), ''),
      nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
        nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
        nullif(btrim(loc.city), '')), ''),
      fa.street_address
    ),
    loc.street_number,loc.street_name,loc.district,loc.city,loc.lat,loc.lon,
    fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x
     WHERE x.activity_id=a.id AND x.status='accepted'),
    fa.male_price,fa.female_price,fa.recommended_skills,mr.id,mr.status::text,
    CASE WHEN h.user_id=v_uid OR mr.status='accepted' THEN
      (SELECT coalesce(jsonb_agg(jsonb_build_object(
        'id',u.id,'username',u.username,
        'generatedAvatar',u.details->>'generatedAvatar','skill',x.skill)
        ORDER BY u.username),'[]'::jsonb)
       FROM public.freeplay_request x JOIN public."user" u ON u.id=x.user_id
       WHERE x.activity_id=a.id AND x.status='accepted')
    ELSE '[]'::jsonb END
  FROM public.activity a
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN LATERAL(
    SELECT r.id,r.status FROM public.freeplay_request r
    WHERE r.activity_id=a.id AND r.user_id=v_uid
    ORDER BY r.created_at DESC LIMIT 1
  ) mr ON true
  WHERE a.id=p_activity_id;
END
$$;

REVOKE ALL ON FUNCTION public.freeplay_activity_detail_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.freeplay_activity_detail_data(uuid)
  TO authenticated, anon;

DROP FUNCTION IF EXISTS public.freeplay_host_management_data(boolean);

CREATE FUNCTION public.freeplay_host_management_data(p_history boolean DEFAULT false)
RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text,
  description text, start_time timestamptz, end_time timestamptz,
  location_id uuid, venue_name text, street_address text,
  location_street_number text, location_street_name text,
  location_district text, location_city text,
  location_lat double precision, location_lon double precision,
  capacity integer, accepted_count bigint, pending_count bigint,
  male_price numeric, female_price numeric, recommended_skills text[],
  intake_closed boolean, cancelled boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    a.location_id,coalesce(loc.name,fa.venue_name),
    coalesce(
      nullif(btrim(loc.full_address), ''),
      nullif(concat_ws(', ', nullif(btrim(loc.street_number), ''),
        nullif(btrim(loc.street_name), ''), nullif(btrim(loc.district), ''),
        nullif(btrim(loc.city), '')), ''),
      fa.street_address
    ),
    loc.street_number,loc.street_name,loc.district,loc.city,loc.lat,loc.lon,
    fa.capacity,
    count(r.id) FILTER(WHERE r.status='accepted'),
    count(r.id) FILTER(WHERE r.status='pending'),
    fa.male_price,fa.female_price,fa.recommended_skills,
    fa.intake_closed_at IS NOT NULL,fa.cancelled_at IS NOT NULL
  FROM public.activity a
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN public.freeplay_request r ON r.activity_id=a.id
  WHERE h.user_id=auth.uid()
    AND (p_history=(a.end_time<=now() OR fa.cancelled_at IS NOT NULL))
  GROUP BY a.id,fa.activity_id,h.id,loc.id
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN a.end_time END DESC
$$;

REVOKE ALL ON FUNCTION public.freeplay_host_management_data(boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.freeplay_host_management_data(boolean) TO authenticated;

-- Hosts may replace the location only while nobody has an active request.
-- Capacity/description/skills retain the existing edit rules.
DROP FUNCTION IF EXISTS public.edit_freeplay_listing(uuid,integer,text,text[]);

CREATE FUNCTION public.edit_freeplay_listing(
  p_activity_id uuid,
  p_capacity integer,
  p_description text,
  p_recommended_skills text[],
  p_location_id uuid DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_current_capacity integer;
  v_current_location uuid;
  v_accepted integer;
  v_has_requests boolean;
BEGIN
  SELECT fa.capacity,a.location_id INTO v_current_capacity,v_current_location
  FROM public.freeplay_activity fa
  JOIN public.activity a ON a.id=fa.activity_id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE a.id=p_activity_id AND h.user_id=v_uid AND fa.cancelled_at IS NULL
  FOR UPDATE OF fa,a;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;

  SELECT count(*)::integer INTO v_accepted
  FROM public.freeplay_request
  WHERE activity_id=p_activity_id AND status='accepted';
  v_has_requests := EXISTS(
    SELECT 1 FROM public.freeplay_request
    WHERE activity_id=p_activity_id AND status IN ('pending','accepted'));

  IF p_capacity<v_current_capacity OR p_capacity<v_accepted THEN
    RAISE EXCEPTION 'capacity can only increase';
  END IF;
  IF p_location_id IS NOT NULL
     AND NOT EXISTS(SELECT 1 FROM public.location WHERE id=p_location_id) THEN
    RAISE EXCEPTION 'location not found';
  END IF;
  IF v_has_requests
     AND p_location_id IS DISTINCT FROM v_current_location
     AND p_location_id IS NOT NULL THEN
    RAISE EXCEPTION 'location cannot change after requests';
  END IF;

  IF p_location_id IS NOT NULL THEN
    UPDATE public.activity SET location_id=p_location_id WHERE id=p_activity_id;
  END IF;
  UPDATE public.freeplay_activity
  SET capacity=p_capacity,
      description=coalesce(p_description,''),
      recommended_skills=p_recommended_skills,
      updated_at=now()
  WHERE activity_id=p_activity_id;
END
$$;

REVOKE ALL ON FUNCTION public.edit_freeplay_listing(uuid,integer,text,text[],uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.edit_freeplay_listing(uuid,integer,text,text[],uuid)
  TO authenticated;
