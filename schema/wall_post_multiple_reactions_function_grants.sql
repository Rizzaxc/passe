-- The migration that rebuilt these RPCs receives Postgres's default PUBLIC
-- EXECUTE privilege. Feed reactions and reads are signed-in features only.
REVOKE EXECUTE ON FUNCTION public.react_to_wall_post(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.react_to_wall_post(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.wall_feed_data(bigint, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.wall_feed_data(bigint, integer, integer) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.user_wall_data(uuid, text, integer, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.user_wall_data(uuid, text, integer, integer) TO authenticated;
