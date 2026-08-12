-- Resolves the other party's id for a freeplay chat thread, so the client can look up
-- their optional contact info (`user_contact`, e.g. Zalo) for a "message via Zalo" deep
-- link. Kept separate from freeplay_chat_data (which is per-message) since a thread can
-- have zero messages yet (e.g. right after requesting a seat) and the counterpart still
-- needs to be resolved. Deliberately does NOT return the contact info itself — that read
-- goes through a normal client-side select against `user_contact`, so its RLS (friends /
-- freeplay-host-is-public) is the single source of truth for who can see it, rather than
-- this SECURITY DEFINER function re-implementing (and risking drifting from) that rule.
CREATE OR REPLACE FUNCTION public.freeplay_chat_counterpart_data(p_request_id uuid)
RETURNS TABLE(counterpart_id uuid)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid();
BEGIN
  RETURN QUERY
  SELECT CASE WHEN r.user_id=v_uid THEN h.user_id ELSE r.user_id END
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND (r.user_id=v_uid OR h.user_id=v_uid);
END
$$;

REVOKE ALL ON FUNCTION public.freeplay_chat_counterpart_data(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.freeplay_chat_counterpart_data(uuid) TO authenticated;
