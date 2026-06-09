-- Captain actions: delete lobby + transfer captaincy.
-- `lobby` has RLS with only INSERT/SELECT policies, so the captain could neither
-- delete their lobby (delete() was a silent no-op) nor hand it off. Add a
-- captain-scoped DELETE policy (lobby_before_delete still blocks deletion while
-- other members remain) and a validated SECURITY DEFINER transfer RPC.

CREATE POLICY "Captain can delete their lobby" ON public.lobby
  FOR DELETE TO authenticated
  USING (captain_id = (SELECT auth.uid()));

CREATE OR REPLACE FUNCTION public.transfer_lobby_captaincy(
    p_lobby_id uuid, p_new_captain_id uuid
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
    AS $$
DECLARE
    v_captain uuid;
BEGIN
    SELECT captain_id INTO v_captain FROM public.lobby WHERE id = p_lobby_id;
    IF v_captain IS NULL THEN
        RAISE EXCEPTION 'Lobby % not found', p_lobby_id;
    END IF;
    IF v_captain <> auth.uid() THEN
        RAISE EXCEPTION 'Only the captain can transfer captaincy';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_member
        WHERE lobby_id = p_lobby_id AND user_id = p_new_captain_id
    ) THEN
        RAISE EXCEPTION 'New captain must be a member of the lobby';
    END IF;
    UPDATE public.lobby SET captain_id = p_new_captain_id WHERE id = p_lobby_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.transfer_lobby_captaincy(uuid, uuid) TO authenticated;
