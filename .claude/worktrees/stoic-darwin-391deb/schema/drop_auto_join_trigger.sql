-- Drop the auto-join trigger and its function; the RPC create_lobby_with_location
-- now handles inserting the captain as the first lobby member atomically.
DROP TRIGGER IF EXISTS lobby_captain_auto_join_trigger ON public.lobby;
DROP FUNCTION IF EXISTS public.lobby_captain_auto_join_trigger_fn();
