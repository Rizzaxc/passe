-- Rich Host-owned listing feed used by Manage ▸ Schedule / Freeplay.

CREATE OR REPLACE FUNCTION public.freeplay_host_management_data(p_history boolean DEFAULT false)
RETURNS TABLE(
  activity_id uuid, host_id uuid, host_name text, host_avatar_url text,
  description text, start_time timestamptz, end_time timestamptz,
  venue_name text, street_address text, capacity integer, accepted_count bigint,
  pending_count bigint, male_price numeric, female_price numeric,
  recommended_skills text[], intake_closed boolean, cancelled boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT a.id,h.id,h.display_name,h.avatar_url,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    count(r.id) FILTER(WHERE r.status='accepted'),count(r.id) FILTER(WHERE r.status='pending'),
    fa.male_price,fa.female_price,fa.recommended_skills,
    fa.intake_closed_at IS NOT NULL,fa.cancelled_at IS NOT NULL
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  LEFT JOIN public.freeplay_request r ON r.activity_id=a.id
  WHERE h.user_id=auth.uid()
    AND (p_history=(a.end_time<=now() OR fa.cancelled_at IS NOT NULL))
  GROUP BY a.id,fa.activity_id,h.id,loc.name,loc.full_address
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN a.end_time END DESC
$$;

REVOKE ALL ON FUNCTION public.freeplay_host_management_data(boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.freeplay_host_management_data(boolean) TO authenticated;
