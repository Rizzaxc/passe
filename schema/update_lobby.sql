-- Migration: SECURITY DEFINER RPC for captain to edit their lobby.
-- There is no UPDATE RLS on public.lobby, so direct updates are blocked.
-- This function enforces the captain check and performs the update.
CREATE OR REPLACE FUNCTION public.update_lobby(
    p_lobby_id       uuid,
    p_name           text,
    p_visibility     text,
    p_playtime       jsonb DEFAULT NULL,
    p_details        jsonb DEFAULT NULL,
    p_home_ground_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby WHERE id = p_lobby_id AND captain_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'update_lobby: caller is not the lobby captain';
    END IF;

    UPDATE public.lobby
    SET name        = p_name,
        visibility  = p_visibility::public.lobby_visibility,
        playtime    = p_playtime,
        details     = p_details,
        home_ground = p_home_ground_id
    WHERE id = p_lobby_id;
END;
$$;

ALTER FUNCTION public.update_lobby(uuid, text, text, jsonb, jsonb, uuid) OWNER TO postgres;
