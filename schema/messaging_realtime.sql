-- Realtime delivery for the shared messaging layer (schema/messaging.sql).
--
-- Broadcast-from-database, not postgres_changes: a trigger on `message` pushes
-- to a private topic per conversation, and one RLS policy on realtime.messages
-- authorizes the topic at subscribe time. postgres_changes would re-evaluate
-- row RLS per subscriber per change, which is the known scaling cliff; this
-- costs one EXISTS per subscribe instead.
--
-- Two deliberate omissions:
--
-- 1. There is NO INSERT policy on realtime.messages. Clients receive on these
--    topics but cannot broadcast into them — every message goes through
--    send_message() so the write gate, the char limits and the notification
--    fan-out can't be bypassed by a client that just opens a channel.
--
-- 2. `payment_info` messages broadcast a signal only, never their content.
--    The decrypted bank details live behind conversation_data's vault join;
--    putting them in a broadcast payload would copy them into
--    realtime.messages, where they'd sit for the 3 days Supabase retains
--    broadcast rows.
--
-- Note on the visibility floor: a topic-level policy can't express "only
-- messages after you joined". It doesn't need to — broadcasts only fire on
-- INSERT, so everything delivered live is by definition newer than any
-- existing member's joined_at. History is what needs clamping, and
-- conversation_data does that. A member who LEFT is excluded here explicitly
-- (left_at IS NULL), since they'd otherwise keep receiving.
--
-- Needs to be applied to the live Supabase project — schema files here are
-- dumped for review, not auto-applied.

-- ── Authorization ────────────────────────────────────────────────────────────
-- The check goes through a SECURITY DEFINER helper rather than reading
-- conversation_member inline (as the Supabase docs' example does). This layer
-- REVOKEs table grants from `authenticated`, so an inline read fails the
-- subscribe with "permission denied for table conversation_member" — every
-- channel, for every user.
--
-- Comparing the topic string to a built one also avoids casting realtime.topic()
-- to uuid: this policy is evaluated for EVERY private topic in the app, and a
-- cast would raise on any topic that isn't ours.
CREATE OR REPLACE FUNCTION public.fn_can_receive_conversation_topic(
  p_topic text, p_uid uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_member cm
    WHERE cm.user_id = p_uid
      AND cm.left_at IS NULL
      AND p_topic = 'conversation:' || cm.conversation_id::text
  );
$$;
REVOKE ALL ON FUNCTION public.fn_can_receive_conversation_topic(text,uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fn_can_receive_conversation_topic(text,uuid)
  TO authenticated;

DROP POLICY IF EXISTS conversation_member_can_receive_broadcast ON realtime.messages;
CREATE POLICY conversation_member_can_receive_broadcast
ON realtime.messages
FOR SELECT
TO authenticated
USING (
  realtime.messages.extension = 'broadcast'
  AND public.fn_can_receive_conversation_topic(
        (SELECT realtime.topic()), (SELECT auth.uid()))
);

-- ── Broadcast trigger ────────────────────────────────────────────────────────
-- The payload carries what a message bubble needs to render, so the common case
-- costs no follow-up fetch. Sender display fields are resolved here because
-- they live on `user`, not on the message row, and a group thread has to label
-- who said what.
CREATE OR REPLACE FUNCTION public.fn_broadcast_message()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_payload jsonb; v_username text; v_avatar text;
BEGIN
  SELECT u.username::text, u.details->>'generatedAvatar'
  INTO v_username, v_avatar
  FROM public."user" u WHERE u.id = NEW.sender_id;

  v_payload := jsonb_build_object(
    'id', NEW.id,
    'conversation_id', NEW.conversation_id,
    'sender_id', NEW.sender_id,
    'sender_username', v_username,
    'sender_avatar', v_avatar,
    'kind', NEW.kind::text,
    'created_at', NEW.created_at
  );

  -- Content for the kinds that are safe to carry; payment_info is a signal
  -- only (see the header) and the client refetches it.
  IF NEW.kind IN ('text','system') THEN
    v_payload := v_payload || jsonb_build_object('body', NEW.body, 'payload', NEW.payload);
  ELSIF NEW.kind = 'poll' THEN
    v_payload := v_payload || jsonb_build_object('payload', NEW.payload);
  END IF;

  PERFORM realtime.send(
    v_payload,
    'new_message',
    'conversation:' || NEW.conversation_id::text,
    true  -- private; must match the client's RealtimeChannelConfig(private: true)
  );
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_broadcast_message ON public.message;
CREATE TRIGGER trg_broadcast_message
  AFTER INSERT ON public.message
  FOR EACH ROW EXECUTE FUNCTION public.fn_broadcast_message();

REVOKE ALL ON FUNCTION public.fn_broadcast_message() FROM PUBLIC, anon, authenticated;
