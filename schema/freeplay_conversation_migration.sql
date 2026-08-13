-- Move freeplay seat-request chat onto the shared messaging layer
-- (schema/messaging.sql). Apply AFTER messaging.sql and messaging_realtime.sql.
--
-- Freeplay was the first feature to grow a chat, so it grew its own table.
-- Courses need the same thing for N members, and a second bespoke
-- implementation would be the third by the time anything else needs one — so
-- freeplay moves onto the shared layer and `freeplay_chat_message` goes away.
--
-- The backfill below is written to be a no-op on an empty table but correct if
-- rows exist, so this is safe to apply whatever the live state turns out to be.
-- Member `joined_at` is set to the request's own created_at, never now(), or
-- the visibility floor would hide every message that predates the migration.
--
-- Idempotent / re-runnable. Needs to be applied to the live Supabase project.

-- ── Conversation provisioning ────────────────────────────────────────────────
-- A freeplay thread has exactly two members: the requester and the host.
CREATE OR REPLACE FUNCTION public.fn_ensure_freeplay_conversation(p_request_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_id uuid; v_requester uuid; v_host uuid; v_created timestamptz;
BEGIN
  SELECT c.id INTO v_id FROM public.conversation c
  WHERE c.freeplay_request_id = p_request_id;
  IF v_id IS NOT NULL THEN RETURN v_id; END IF;

  SELECT r.user_id, h.user_id, r.created_at INTO v_requester, v_host, v_created
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id = r.activity_id
  JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  WHERE r.id = p_request_id;
  IF v_requester IS NULL THEN RAISE EXCEPTION 'freeplay request not found'; END IF;

  -- conversation_one_per_freeplay_request is a PARTIAL unique index, so the
  -- predicate has to be restated here or inference fails with "no unique or
  -- exclusion constraint matching the ON CONFLICT specification".
  INSERT INTO public.conversation(kind, freeplay_request_id)
  VALUES ('freeplay', p_request_id)
  ON CONFLICT (freeplay_request_id) WHERE freeplay_request_id IS NOT NULL
  DO NOTHING
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    SELECT c.id INTO v_id FROM public.conversation c
    WHERE c.freeplay_request_id = p_request_id;
    RETURN v_id;
  END IF;

  INSERT INTO public.conversation_member(conversation_id, user_id, joined_at)
  VALUES (v_id, v_requester, v_created), (v_id, v_host, v_created)
  ON CONFLICT DO NOTHING;

  RETURN v_id;
END
$$;
REVOKE ALL ON FUNCTION public.fn_ensure_freeplay_conversation(uuid)
  FROM PUBLIC, anon, authenticated;

-- Client entry point: the chat sheet holds a request id and needs the thread.
CREATE OR REPLACE FUNCTION public.freeplay_conversation_id(p_request_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.freeplay_request r
    JOIN public.activity a ON a.id = r.activity_id
    JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
    WHERE r.id = p_request_id AND (r.user_id = v_uid OR h.user_id = v_uid)
  ) THEN RAISE EXCEPTION 'chat not found'; END IF;

  -- Provision lazily too: a request created before this migration has no
  -- conversation until someone opens it.
  v_id := public.fn_ensure_freeplay_conversation(p_request_id);
  RETURN v_id;
END
$$;

-- ── Lifecycle functions, repointed at `message` ──────────────────────────────
-- Bodies are otherwise unchanged from schema/freeplay.sql; only the chat
-- inserts move. System messages keep their stable codes so the client's
-- existing translations still resolve.

CREATE OR REPLACE FUNCTION public.request_freeplay_seat(p_activity_id uuid, p_message text DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_gender text; v_skill text; v_id uuid;
        v_count integer; v_conversation uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT a.sport_id,a.end_time,fa.capacity,fa.male_price,fa.female_price,fa.intake_closed_at,fa.cancelled_at,
    h.user_id host_user_id INTO v_row
  FROM public.activity a JOIN public.freeplay_activity fa ON fa.activity_id=a.id
  JOIN public.freeplay_host h ON h.id=a.freeplay_host_id AND h.status='active'
  WHERE a.id=p_activity_id FOR UPDATE OF fa;
  IF NOT FOUND OR v_row.cancelled_at IS NOT NULL OR v_row.end_time<=now() OR v_row.intake_closed_at IS NOT NULL THEN
    RAISE EXCEPTION 'activity is not accepting requests';
  END IF;
  IF v_uid=v_row.host_user_id OR public.fn_is_blocked(v_uid,v_row.host_user_id) THEN RAISE EXCEPTION 'request not allowed'; END IF;
  IF EXISTS(SELECT 1 FROM public.freeplay_request WHERE activity_id=p_activity_id AND user_id=v_uid AND status='declined') THEN
    RAISE EXCEPTION 'declined request is terminal';
  END IF;
  IF EXISTS(SELECT 1 FROM public.freeplay_request WHERE activity_id=p_activity_id AND user_id=v_uid AND status IN ('pending','accepted')) THEN
    RAISE EXCEPTION 'active request already exists';
  END IF;
  SELECT count(*) INTO v_count FROM public.freeplay_request WHERE activity_id=p_activity_id AND status='accepted';
  IF v_count>=v_row.capacity THEN RAISE EXCEPTION 'activity is full'; END IF;
  SELECT coalesce(details->>'gender','male') INTO v_gender FROM public."user" WHERE id=v_uid;
  IF v_gender NOT IN ('male','female') THEN v_gender:='male'; END IF;
  v_skill:=public.freeplay_user_skill(v_uid,v_row.sport_id);
  INSERT INTO public.freeplay_request(activity_id,user_id,price_amount,gender,skill)
  VALUES(p_activity_id,v_uid,CASE WHEN v_gender='female' THEN v_row.female_price ELSE v_row.male_price END,v_gender,v_skill)
  RETURNING id INTO v_id;

  v_conversation := public.fn_ensure_freeplay_conversation(v_id);
  IF nullif(btrim(p_message),'') IS NOT NULL THEN
    INSERT INTO public.message(conversation_id,sender_id,kind,body)
    VALUES(v_conversation,v_uid,'text',btrim(p_message));
  END IF;

  PERFORM public.fn_enqueue_notification('freeplay_request_received',ARRAY[v_row.host_user_id],
    'Yêu cầu Xé vé mới','Có người muốn tham gia buổi chơi của bạn.',
    jsonb_build_object('activity_id',p_activity_id,'request_id',v_id));
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.respond_freeplay_request(p_request_id uuid, p_accept boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_count integer; v_conversation uuid;
BEGIN
  SELECT r.*,fa.capacity,a.end_time,h.user_id host_user_id INTO v_row
  FROM public.freeplay_request r JOIN public.freeplay_activity fa ON fa.activity_id=r.activity_id
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND h.user_id=v_uid FOR UPDATE OF r,fa;
  IF NOT FOUND OR v_row.status<>'pending' THEN RAISE EXCEPTION 'pending request not found'; END IF;
  IF v_row.end_time<=now() THEN RAISE EXCEPTION 'activity ended'; END IF;
  v_conversation := public.fn_ensure_freeplay_conversation(p_request_id);
  IF p_accept THEN
    SELECT count(*) INTO v_count FROM public.freeplay_request WHERE activity_id=v_row.activity_id AND status='accepted';
    IF v_count>=v_row.capacity THEN RAISE EXCEPTION 'activity is full'; END IF;
    UPDATE public.freeplay_request SET status='accepted',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.activity_confirmation(activity_id,user_id,attendance)
    VALUES(v_row.activity_id,v_row.user_id,'going') ON CONFLICT(activity_id,user_id)
    DO UPDATE SET attendance='going',confirmed_at=now();
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(v_conversation,'system','request_accepted');
    PERFORM public.fn_enqueue_notification('freeplay_request_accepted',ARRAY[v_row.user_id],
      'Đã nhận chỗ Xé vé','Host đã duyệt yêu cầu của bạn.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  ELSE
    UPDATE public.freeplay_request SET status='declined',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(v_conversation,'system','request_declined');
    PERFORM public.fn_enqueue_notification('freeplay_request_declined',ARRAY[v_row.user_id],
      'Yêu cầu Xé vé bị từ chối','Host đã từ chối yêu cầu của bạn.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.cancel_freeplay_request(p_request_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_row record; v_conversation uuid;
BEGIN
  SELECT r.*,a.end_time,h.user_id host_user_id INTO v_row FROM public.freeplay_request r
  JOIN public.activity a ON a.id=r.activity_id JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
  WHERE r.id=p_request_id AND r.user_id=v_uid FOR UPDATE OF r;
  IF NOT FOUND OR v_row.status NOT IN ('pending','accepted') OR v_row.end_time<=now() THEN
    RAISE EXCEPTION 'active request not found';
  END IF;
  UPDATE public.freeplay_request SET status='cancelled',resolved_at=now(),updated_at=now() WHERE id=p_request_id;
  DELETE FROM public.activity_confirmation WHERE activity_id=v_row.activity_id AND user_id=v_uid;
  v_conversation := public.fn_ensure_freeplay_conversation(p_request_id);
  INSERT INTO public.message(conversation_id,kind,body)
  VALUES(v_conversation,'system','request_cancelled');
  PERFORM public.fn_enqueue_notification('freeplay_request_cancelled',ARRAY[v_row.host_user_id],
    'Người chơi đã huỷ','Một người chơi đã huỷ yêu cầu Xé vé.',jsonb_build_object('activity_id',v_row.activity_id,'request_id',p_request_id));
END
$$;

CREATE OR REPLACE FUNCTION public.cancel_freeplay_activity(p_activity_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid:=auth.uid(); v_user_ids uuid[]; v_request record;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.activity a JOIN public.freeplay_host h ON h.id=a.freeplay_host_id
    WHERE a.id=p_activity_id AND h.user_id=v_uid) THEN RAISE EXCEPTION 'activity not found or not owned'; END IF;
  UPDATE public.freeplay_activity SET cancelled_at=coalesce(cancelled_at,now()),intake_closed_at=coalesce(intake_closed_at,now()),updated_at=now()
  WHERE activity_id=p_activity_id;
  UPDATE public.freeplay_request SET status='host_cancelled',resolved_at=now(),updated_at=now()
  WHERE activity_id=p_activity_id AND status IN ('pending','accepted');
  DELETE FROM public.activity_confirmation WHERE activity_id=p_activity_id;

  -- One system message per affected thread. The loop replaces a set-based
  -- INSERT because each request needs its conversation provisioned first.
  FOR v_request IN SELECT id FROM public.freeplay_request WHERE activity_id=p_activity_id
  LOOP
    INSERT INTO public.message(conversation_id,kind,body)
    VALUES(public.fn_ensure_freeplay_conversation(v_request.id),'system','activity_cancelled');
  END LOOP;

  SELECT array_agg(DISTINCT user_id) INTO v_user_ids FROM public.freeplay_request WHERE activity_id=p_activity_id;
  IF cardinality(v_user_ids)>0 THEN
    PERFORM public.fn_enqueue_notification('freeplay_activity_cancelled',v_user_ids,'Buổi Xé vé đã huỷ',
      'Host đã huỷ buổi chơi.',jsonb_build_object('activity_id',p_activity_id));
  END IF;
END
$$;

-- ── Backfill ─────────────────────────────────────────────────────────────────
-- The broadcast trigger is suppressed for the duration: carrying history over
-- is not a live event, and leaving it armed would push every migrated message
-- to any connected client as if it had just been sent (and copy them all into
-- realtime.messages, where they'd sit for the 3 days Supabase retains them).
DO $$
DECLARE r record; v_conversation uuid; v_has_trigger boolean;
BEGIN
  IF to_regclass('public.freeplay_chat_message') IS NULL THEN RETURN; END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.message'::regclass AND tgname = 'trg_broadcast_message'
  ) INTO v_has_trigger;
  IF v_has_trigger THEN
    ALTER TABLE public.message DISABLE TRIGGER trg_broadcast_message;
  END IF;

  FOR r IN SELECT DISTINCT request_id FROM public.freeplay_chat_message
  LOOP
    v_conversation := public.fn_ensure_freeplay_conversation(r.request_id);

    INSERT INTO public.message(conversation_id, sender_id, kind, body, payment_info_id, created_at)
    SELECT v_conversation, m.sender_id, m.kind::text::public.message_kind,
           m.body, m.payment_info_id, m.created_at
    FROM public.freeplay_chat_message m
    WHERE m.request_id = r.request_id
      -- Re-runnable: skip anything already carried over.
      AND NOT EXISTS (
        SELECT 1 FROM public.message x
        WHERE x.conversation_id = v_conversation
          AND x.created_at = m.created_at
          AND x.kind = m.kind::text::public.message_kind
          AND x.body IS NOT DISTINCT FROM m.body
      );
  END LOOP;

  IF v_has_trigger THEN
    ALTER TABLE public.message ENABLE TRIGGER trg_broadcast_message;
  END IF;
END $$;

-- ── Retire the old chat ──────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.freeplay_chat_data(uuid);
DROP FUNCTION IF EXISTS public.send_freeplay_message(uuid, text);
DROP FUNCTION IF EXISTS public.share_freeplay_payment_info(uuid);
DROP FUNCTION IF EXISTS public.freeplay_chat_can_write(uuid, uuid);
DROP TABLE IF EXISTS public.freeplay_chat_message;

-- ── Grants ───────────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname = 'freeplay_conversation_id'
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;
