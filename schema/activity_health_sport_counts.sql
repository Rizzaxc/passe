-- Per-sport report counts for the signed-in user, so the Activity Data subtab
-- can hint "you have N reports for <sport>" when the *context* sport has no
-- captured reports but another sport does — otherwise an empty recap list
-- looks identical whether the user has never synced or just has reports
-- filed under a sport they aren't currently viewing.
CREATE OR REPLACE FUNCTION public.activity_health_sport_counts()
RETURNS TABLE(sport_id bigint, report_count bigint)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid();
BEGIN
  RETURN QUERY
  SELECT a.sport_id, count(*)::bigint
  FROM public.activity_health_metrics m
  JOIN public.activity a ON a.id = m.activity_id
  WHERE m.user_id = v_uid AND m.dismissed = false
  GROUP BY a.sport_id;
END
$$;

REVOKE ALL ON FUNCTION public.activity_health_sport_counts() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.activity_health_sport_counts() TO authenticated;
