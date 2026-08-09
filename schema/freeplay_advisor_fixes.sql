-- Advisor follow-up for Freeplay: document RPC-only RLS, tighten grants,
-- and cover every new foreign key used by joins/deletes.

CREATE INDEX IF NOT EXISTS activity_freeplay_host_idx
  ON public.activity(freeplay_host_id) WHERE freeplay_host_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS freeplay_activity_city_cluster_idx
  ON public.freeplay_activity(city_cluster) WHERE city_cluster IS NOT NULL;
CREATE INDEX IF NOT EXISTS freeplay_chat_message_payment_info_idx
  ON public.freeplay_chat_message(payment_info_id) WHERE payment_info_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS freeplay_chat_message_sender_idx
  ON public.freeplay_chat_message(sender_id) WHERE sender_id IS NOT NULL;

DROP POLICY IF EXISTS "Freeplay Host is RPC only" ON public.freeplay_host;
CREATE POLICY "Freeplay Host is RPC only" ON public.freeplay_host
  AS RESTRICTIVE FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "Freeplay Activity is RPC only" ON public.freeplay_activity;
CREATE POLICY "Freeplay Activity is RPC only" ON public.freeplay_activity
  AS RESTRICTIVE FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "Freeplay Request is RPC only" ON public.freeplay_request;
CREATE POLICY "Freeplay Request is RPC only" ON public.freeplay_request
  AS RESTRICTIVE FOR ALL TO public USING (false) WITH CHECK (false);
DROP POLICY IF EXISTS "Freeplay Chat is RPC only" ON public.freeplay_chat_message;
CREATE POLICY "Freeplay Chat is RPC only" ON public.freeplay_chat_message
  AS RESTRICTIVE FOR ALL TO public USING (false) WITH CHECK (false);

REVOKE ALL ON FUNCTION public.fn_freeplay_block_cleanup() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.postable_activities() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.create_wall_post(uuid,uuid,jsonb,text,smallint,uuid[]) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.health_capture_candidates(timestamptz) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.activity_health_data(bigint) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.postable_activities() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_wall_post(uuid,uuid,jsonb,text,smallint,uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.health_capture_candidates(timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activity_health_data(bigint) TO authenticated;

-- These are intentionally public, read-only discovery surfaces. Their
-- SECURITY DEFINER bodies expose a fixed projection and never return a roster
-- unless the caller is the Host or an accepted participant.
GRANT EXECUTE ON FUNCTION public.freeplay_host_profile_data(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.freeplay_activity_detail_data(uuid) TO anon;
