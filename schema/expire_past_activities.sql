-- Housekeeping: delete past, non-recurring, unconfirmed lobby activities
-- in lobbies the caller belongs to. Called on lobby list load.

CREATE OR REPLACE FUNCTION public.expire_past_activities()
RETURNS int LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
  v_uid   uuid := auth.uid();
  v_count int;
BEGIN
  DELETE FROM public.activity a
  WHERE a.lobby_id IS NOT NULL
    AND a.start_time < now()
    AND a.recurrence_day_of_week IS NULL
    AND NOT public.activity_is_confirmed(a.id)
    AND NOT EXISTS (
      SELECT 1 FROM public.lobby_match lm WHERE lm.activity_id = a.id
    )
    AND EXISTS (
      SELECT 1 FROM public.lobby_member m
      WHERE m.lobby_id = a.lobby_id AND m.user_id = v_uid
    );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.expire_past_activities() TO authenticated;
