-- Freeplay integration with Wall posts, Health, and public Host profiles.
-- Requires schema/freeplay.sql.

CREATE OR REPLACE FUNCTION public.edit_freeplay_listing(
  p_activity_id uuid,
  p_capacity integer,
  p_description text,
  p_recommended_skills text[]
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_current integer; v_accepted integer;
BEGIN
  SELECT fa.capacity INTO v_current
  FROM public.freeplay_activity fa
  JOIN public.activity a ON a.id=fa.activity_id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE a.id=p_activity_id AND h.user_id=v_uid AND fa.cancelled_at IS NULL
  FOR UPDATE OF fa;
  IF NOT FOUND THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  SELECT count(*) INTO v_accepted FROM public.freeplay_request
  WHERE activity_id=p_activity_id AND status='accepted';
  IF p_capacity<v_current OR p_capacity<v_accepted THEN
    RAISE EXCEPTION 'capacity can only increase';
  END IF;
  UPDATE public.freeplay_activity SET capacity=p_capacity,
    description=coalesce(p_description,''),recommended_skills=p_recommended_skills,
    updated_at=now() WHERE activity_id=p_activity_id;
END
$$;

CREATE OR REPLACE FUNCTION public.freeplay_host_open_data(p_host_id uuid)
RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text,
  description text, start_time timestamptz, end_time timestamptz,
  venue_name text, street_address text, capacity integer, accepted_count bigint,
  male_price numeric, female_price numeric, recommended_skills text[]
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request r WHERE r.activity_id=a.id AND r.status='accepted'),
    fa.male_price,fa.female_price,fa.recommended_skills
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE h.id=p_host_id AND h.status='active' AND a.end_time>now()
    AND fa.cancelled_at IS NULL AND fa.intake_closed_at IS NULL
    AND (SELECT count(*) FROM public.freeplay_request r WHERE r.activity_id=a.id AND r.status='accepted')<fa.capacity
  ORDER BY a.start_time,a.created_at
$$;

CREATE OR REPLACE FUNCTION public.postable_activities()
RETURNS TABLE(activity_id uuid,booking_id uuid,sport_id bigint,lobby_id uuid,
  source_label text,start_time timestamptz,venue_name text,already_posted boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.id,NULL::uuid,a.sport_id,a.lobby_id,
    coalesce(l.name,h.display_name,'Xé vé'),a.start_time,coalesce(loc.name,fa.venue_name),
    EXISTS(SELECT 1 FROM public.wall_post w WHERE w.activity_id=a.id AND w.author_id=auth.uid())
  FROM public.activity a
  JOIN public.activity_confirmation c ON c.activity_id=a.id AND c.user_id=auth.uid() AND c.attendance='going'
  LEFT JOIN public.lobby l ON l.id=a.lobby_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE a.start_time<now() AND a.start_time>now()-interval '7 days'
  UNION ALL
  SELECT NULL::uuid,b.id,s.sport_id,NULL::uuid,p.display_name,b.booking_time_start,loc.name,
    EXISTS(SELECT 1 FROM public.wall_post w WHERE w.professional_booking_id=b.id AND w.author_id=auth.uid())
  FROM public.professional_booking b JOIN public.professional p ON p.id=b.professional_id
  JOIN public.professional_service s ON s.id=b.service_id LEFT JOIN public.location loc ON loc.id=b.location_id
  WHERE b.client_user_id=auth.uid() AND p.professional_role='coach'
    AND b.status IN ('confirmed','completed') AND b.booking_time_end<now()
    AND b.booking_time_end>now()-interval '7 days'
  ORDER BY start_time DESC
$$;

CREATE OR REPLACE FUNCTION public.create_wall_post(
  p_activity_id uuid,p_booking_id uuid,p_media jsonb,p_caption text DEFAULT NULL,
  p_ttl_days smallint DEFAULT 7,p_tagged_users uuid[] DEFAULT '{}'
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_id uuid; v_sport bigint; v_lobby uuid;
  v_label text; v_start timestamptz; v_venue text; v_tag uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
  IF num_nonnulls(p_activity_id,p_booking_id)<>1 THEN RAISE EXCEPTION 'reference exactly one activity or booking'; END IF;
  IF NOT public.fn_valid_wall_post_media(p_media) THEN
    RAISE EXCEPTION 'a post needs 1-4 media items, each an image or a video under 1 minute';
  END IF;
  IF array_length(p_tagged_users,1)>5 THEN RAISE EXCEPTION 'a post can tag at most 5 people'; END IF;
  IF p_activity_id IS NOT NULL THEN
    SELECT a.sport_id,a.lobby_id,coalesce(l.name,h.display_name,'Xé vé'),a.start_time,
      coalesce(loc.name,fa.venue_name)
    INTO v_sport,v_lobby,v_label,v_start,v_venue
    FROM public.activity a LEFT JOIN public.lobby l ON l.id=a.lobby_id
    LEFT JOIN public.freeplay_activity fa ON fa.activity_id=a.id
    LEFT JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    LEFT JOIN public.location loc ON loc.id=a.location_id
    WHERE a.id=p_activity_id AND a.start_time<now() AND a.start_time>now()-interval '7 days'
      AND EXISTS(SELECT 1 FROM public.activity_confirmation c WHERE c.activity_id=a.id AND c.user_id=v_uid AND c.attendance='going');
    IF v_start IS NULL THEN RAISE EXCEPTION 'activity is not postable (must be within 7 days and RSVP''d going)'; END IF;
  ELSE
    SELECT b.booking_time_start,p.display_name,loc.name,s.sport_id
    INTO v_start,v_label,v_venue,v_sport
    FROM public.professional_booking b JOIN public.professional p ON p.id=b.professional_id
    JOIN public.professional_service s ON s.id=b.service_id LEFT JOIN public.location loc ON loc.id=b.location_id
    WHERE b.id=p_booking_id AND b.client_user_id=v_uid AND p.professional_role='coach'
      AND b.status IN ('confirmed','completed') AND b.booking_time_end<now()
      AND b.booking_time_end>now()-interval '7 days';
    IF v_start IS NULL THEN RAISE EXCEPTION 'lesson is not postable (must be yours and within 7 days)'; END IF;
  END IF;
  INSERT INTO public.wall_post(author_id,activity_id,professional_booking_id,sport_id,lobby_id,
    source_label,source_start_time,source_venue_name,caption,media,ttl_days,expires_at)
  VALUES(v_uid,p_activity_id,p_booking_id,coalesce(v_sport,0),v_lobby,v_label,v_start,v_venue,
    nullif(btrim(p_caption),''),p_media,p_ttl_days,now()+(p_ttl_days||' days')::interval)
  RETURNING id INTO v_id;
  FOREACH v_tag IN ARRAY coalesce(p_tagged_users,'{}'::uuid[]) LOOP
    INSERT INTO public.wall_post_tag(post_id,user_id) VALUES(v_id,v_tag) ON CONFLICT DO NOTHING;
  END LOOP;
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.health_capture_candidates(p_window_start timestamptz)
RETURNS TABLE(activity_id uuid,start_time timestamptz,end_time timestamptz,sport_id bigint,source text,confirmed boolean)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid();
BEGIN
  RETURN QUERY SELECT a.id,a.start_time,a.end_time,a.sport_id,
    CASE WHEN a.professional_booking_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    EXISTS(SELECT 1 FROM public.activity_confirmation ac WHERE ac.activity_id=a.id AND ac.user_id=v_uid)
  FROM public.activity a
  WHERE a.end_time IS NOT NULL AND a.end_time<now() AND a.end_time>=p_window_start
    AND (a.user_id=v_uid OR EXISTS(SELECT 1 FROM public.activity_confirmation ac WHERE ac.activity_id=a.id AND ac.user_id=v_uid)
      OR (a.professional_booking_id IS NOT NULL AND EXISTS(SELECT 1 FROM public.professional_booking pb
        WHERE pb.id=a.professional_booking_id AND (pb.client_user_id=v_uid OR EXISTS(SELECT 1 FROM public.booking_additional_users bau WHERE bau.booking_id=pb.id AND bau.user_id=v_uid)))))
    AND NOT EXISTS(SELECT 1 FROM public.activity_health_metrics m WHERE m.activity_id=a.id AND m.user_id=v_uid)
  ORDER BY a.end_time DESC;
END
$$;

CREATE OR REPLACE FUNCTION public.activity_health_data(p_sport_id bigint)
RETURNS TABLE(activity_id uuid,start_time timestamptz,end_time timestamptz,duration_minutes integer,
  location_label text,source text,steps integer,distance_meters real,active_calories real,
  avg_heart_rate integer,max_heart_rate integer,min_heart_rate integer,hrv_sdnn_ms real,
  hrv_rmssd_ms real,hr_zone_easy_seconds integer,hr_zone_moderate_seconds integer,
  hr_zone_hard_seconds integer,training_load real,effort_score real,workout_type text,recorded_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid();
BEGIN
  RETURN QUERY SELECT m.activity_id,a.start_time,a.end_time,
    CASE WHEN a.end_time IS NOT NULL THEN (extract(epoch FROM(a.end_time-a.start_time))/60)::int END,
    coalesce(loc.name,fa.venue_name),
    CASE WHEN a.professional_booking_id IS NOT NULL THEN 'professional'
      WHEN a.freeplay_host_id IS NOT NULL THEN 'freeplay'
      WHEN a.lobby_id IS NOT NULL THEN 'lobby' ELSE 'self' END,
    m.steps,m.distance_meters,m.active_calories,m.avg_heart_rate,m.max_heart_rate,m.min_heart_rate,
    m.hrv_sdnn_ms,m.hrv_rmssd_ms,m.hr_zone_easy_seconds,m.hr_zone_moderate_seconds,
    m.hr_zone_hard_seconds,m.training_load,m.effort_score,m.workout_type,m.recorded_at
  FROM public.activity_health_metrics m JOIN public.activity a ON a.id=m.activity_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  WHERE m.user_id=v_uid AND m.dismissed=false AND a.sport_id=p_sport_id ORDER BY a.start_time DESC;
END
$$;

REVOKE ALL ON FUNCTION public.edit_freeplay_listing(uuid,integer,text,text[]) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.freeplay_host_open_data(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.edit_freeplay_listing(uuid,integer,text,text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.freeplay_host_open_data(uuid) TO authenticated,anon;
