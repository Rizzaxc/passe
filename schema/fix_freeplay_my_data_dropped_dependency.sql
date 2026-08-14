-- `freeplay_conversation_migration.sql` moved freeplay chat onto the shared
-- messaging layer and dropped `freeplay_chat_can_write(uuid,uuid)`, but never
-- updated `freeplay_my_data`, which still called it to populate its unused
-- `can_write` column. Postgres inlines LANGUAGE SQL function bodies at parse
-- time, so every call to `freeplay_my_data` — the Manage tab's "Xe ve"
-- (freeplay tickets) list — fails with "function ... does not exist" before
-- it even runs, regardless of row count. PostgREST surfaces this as an
-- immediate error, which the Flutter client's default Riverpod retry policy
-- then hammers with exponential backoff, showing an endless loading spinner
-- that occasionally blips to a blank state instead of resolving.
--
-- `can_write` is dead output: `FreeplayActivity.fromJson` never reads it
-- (the client now computes chat-writability itself in
-- `freeplay/detail_page.dart` from request status/timing). Keep the column
-- for signature stability, just stop it from calling the missing function.

CREATE OR REPLACE FUNCTION public.freeplay_my_data(p_history boolean DEFAULT false)
RETURNS TABLE(
  request_id uuid, request_status text, activity_id uuid, host_id uuid, host_name text, description text,
  start_time timestamptz, end_time timestamptz, venue_name text, street_address text, capacity integer,
  accepted_count bigint, price_amount numeric, recommended_skills text[], can_write boolean
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT r.id,r.status::text,a.id,h.id,h.display_name,fa.description,a.start_time,a.end_time,
    coalesce(loc.name,fa.venue_name),coalesce(loc.full_address,fa.street_address),fa.capacity,
    (SELECT count(*) FROM public.freeplay_request x WHERE x.activity_id=a.id AND x.status='accepted'),
    r.price_amount,fa.recommended_skills,false
  FROM public.freeplay_request r JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_activity fa ON fa.activity_id=a.id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  LEFT JOIN public.location loc ON loc.id=a.location_id
  WHERE r.user_id=auth.uid() AND CASE WHEN p_history THEN
    (a.end_time<=now() OR r.status NOT IN ('pending','accepted'))
    ELSE (a.end_time>now() AND r.status IN ('pending','accepted')) END
  ORDER BY CASE WHEN p_history THEN NULL ELSE a.start_time END,
    CASE WHEN p_history THEN coalesce(r.resolved_at,a.end_time) END DESC
$$;
