-- Shared messaging layer: one conversation/message model behind every threaded
-- chat in the app. Freeplay seat-request chat migrates onto it (see
-- schema/freeplay_conversation_migration.sql); courses join it in
-- schema/course.sql.
--
-- Replaces the per-feature chat table pattern that started with
-- `freeplay_chat_message` — same message-kind CHECK idiom and the same
-- 2000/500-char limits, generalised to N members.
--
-- Two things here are load-bearing and easy to get wrong:
--
-- 1. `conversation_member` IS the visibility floor. A member reads only
--    messages created inside their own [joined_at, left_at] window. A student
--    added to a course thread on day 30 must not read day 1, and a member who
--    left must not keep reading. This is enforced in SQL — in the RLS policy
--    AND in conversation_data — never client-side.
--
-- 2. `conversation_data` takes `p_since` for reconnect backfill. Realtime
--    delivery is best-effort: a dropped socket silently loses messages, so the
--    client refetches from its newest held timestamp on resubscribe. Do not
--    remove that parameter.
--
-- Idempotent / re-runnable. Needs to be applied to the live Supabase project —
-- schema files here are dumped for review, not auto-applied.

-- ── Enums ────────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='conversation_kind') THEN
    CREATE TYPE public.conversation_kind AS ENUM ('freeplay','course');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='message_kind') THEN
    CREATE TYPE public.message_kind AS ENUM ('text','system','payment_info','poll');
  END IF;
END$$;

-- ── Tables ───────────────────────────────────────────────────────────────────

-- Owner is polymorphic through exactly-one nullable FKs, the same idiom as
-- wall_post's hook and activity_source_exclusivity.
--
-- `course_id` is deliberately FK-less here: schema/course.sql creates the
-- course table and adds the constraint. Phase 1 can ship without it.
CREATE TABLE IF NOT EXISTS public.conversation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind public.conversation_kind NOT NULL,
  freeplay_request_id uuid REFERENCES public.freeplay_request(id) ON DELETE CASCADE,
  course_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT conversation_owner_exclusivity
    CHECK (num_nonnulls(freeplay_request_id, course_id) = 1),
  CONSTRAINT conversation_kind_matches_owner CHECK (
    (kind = 'freeplay' AND freeplay_request_id IS NOT NULL)
    OR (kind = 'course' AND course_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS conversation_one_per_freeplay_request
  ON public.conversation(freeplay_request_id) WHERE freeplay_request_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS conversation_one_per_course
  ON public.conversation(course_id) WHERE course_id IS NOT NULL;

-- The visibility floor. `left_at` NULL means still present; a departed member
-- keeps the row (and their read history) rather than being deleted, so
-- "you can see what happened while you were here" survives.
CREATE TABLE IF NOT EXISTS public.conversation_member (
  conversation_id uuid NOT NULL REFERENCES public.conversation(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  left_at timestamptz,
  last_read_at timestamptz NOT NULL DEFAULT '-infinity',
  PRIMARY KEY (conversation_id, user_id),
  CONSTRAINT conversation_member_window CHECK (left_at IS NULL OR left_at >= joined_at)
);

CREATE INDEX IF NOT EXISTS conversation_member_user_idx
  ON public.conversation_member(user_id);

-- `payload` carries structured detail a plain body can't: poll question/options,
-- and the parameters a localised system event needs (system `body` is a stable
-- code like 'request_accepted', translated client-side — same convention as
-- freeplay's system messages).
CREATE TABLE IF NOT EXISTS public.message (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES public.conversation(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public."user"(id) ON DELETE SET NULL,
  kind public.message_kind NOT NULL,
  body text,
  payload jsonb,
  payment_info_id uuid REFERENCES public.user_payment_info(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT message_shape CHECK (
    (kind = 'text' AND sender_id IS NOT NULL
      AND char_length(btrim(body)) BETWEEN 1 AND 2000
      AND payment_info_id IS NULL AND payload IS NULL)
    OR (kind = 'system' AND sender_id IS NULL
      AND char_length(btrim(body)) BETWEEN 1 AND 500
      AND payment_info_id IS NULL)
    OR (kind = 'payment_info' AND sender_id IS NOT NULL
      AND payment_info_id IS NOT NULL AND body IS NULL AND payload IS NULL)
    OR (kind = 'poll' AND sender_id IS NOT NULL AND body IS NULL
      AND payment_info_id IS NULL
      AND jsonb_typeof(payload->'question') = 'string'
      AND char_length(payload->>'question') BETWEEN 1 AND 200
      AND jsonb_typeof(payload->'options') = 'array'
      AND jsonb_array_length(payload->'options') BETWEEN 2 AND 6)
  )
);

-- Every read is "this conversation, in time order", and the visibility window
-- is a range over created_at — so the composite index is the only one needed.
CREATE INDEX IF NOT EXISTS message_conversation_created_idx
  ON public.message(conversation_id, created_at);

CREATE TABLE IF NOT EXISTS public.message_poll_vote (
  message_id uuid NOT NULL REFERENCES public.message(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
  option_index smallint NOT NULL CHECK (option_index >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (message_id, user_id)
);

-- ── RLS ──────────────────────────────────────────────────────────────────────
-- Reads and writes both go through SECURITY DEFINER RPCs below; these policies
-- are defence in depth for any direct PostgREST access that slips in later.

ALTER TABLE public.conversation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_member ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_poll_vote ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.conversation, public.conversation_member,
  public.message, public.message_poll_vote FROM PUBLIC, anon, authenticated;

-- Membership test, without recursing through conversation_member's own RLS.
CREATE OR REPLACE FUNCTION public.fn_is_conversation_member(
  p_conversation_id uuid, p_uid uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id AND m.user_id = p_uid
  );
$$;
REVOKE ALL ON FUNCTION public.fn_is_conversation_member(uuid,uuid)
  FROM PUBLIC, anon, authenticated;

-- The visibility floor, in one place. Every read path calls this.
CREATE OR REPLACE FUNCTION public.fn_can_see_message(
  p_conversation_id uuid, p_created_at timestamptz, p_uid uuid
) RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id = p_uid
      AND p_created_at >= m.joined_at
      AND (m.left_at IS NULL OR p_created_at <= m.left_at)
  );
$$;
REVOKE ALL ON FUNCTION public.fn_can_see_message(uuid,timestamptz,uuid)
  FROM PUBLIC, anon, authenticated;

DROP POLICY IF EXISTS conversation_member_can_select ON public.conversation;
CREATE POLICY conversation_member_can_select ON public.conversation
  FOR SELECT TO authenticated
  USING (public.fn_is_conversation_member(id, auth.uid()));

DROP POLICY IF EXISTS conversation_member_self_select ON public.conversation_member;
CREATE POLICY conversation_member_self_select ON public.conversation_member
  FOR SELECT TO authenticated
  USING (public.fn_is_conversation_member(conversation_id, auth.uid()));

DROP POLICY IF EXISTS message_visible_select ON public.message;
CREATE POLICY message_visible_select ON public.message
  FOR SELECT TO authenticated
  USING (public.fn_can_see_message(conversation_id, created_at, auth.uid()));

DROP POLICY IF EXISTS message_poll_vote_select ON public.message_poll_vote;
CREATE POLICY message_poll_vote_select ON public.message_poll_vote
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.message m
    WHERE m.id = message_id
      AND public.fn_can_see_message(m.conversation_id, m.created_at, auth.uid())
  ));

-- ── Write gate ───────────────────────────────────────────────────────────────
-- Per-kind rules for "can this user post right now". The freeplay branch keeps
-- the exact windows the old freeplay_chat_can_write enforced (pending → until
-- kickoff; accepted / host-cancelled → 7 days after), including the block check.
-- schema/course.sql REPLACEs this function to add the course branch; until then
-- a course conversation is read-only.
CREATE OR REPLACE FUNCTION public.fn_can_write_conversation(
  p_conversation_id uuid, p_uid uuid
) RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_kind public.conversation_kind; v_request uuid;
BEGIN
  SELECT c.kind, c.freeplay_request_id INTO v_kind, v_request
  FROM public.conversation c WHERE c.id = p_conversation_id;
  IF NOT FOUND THEN RETURN false; END IF;

  -- A member who left can never write again, whatever the owner says.
  IF NOT EXISTS (
    SELECT 1 FROM public.conversation_member m
    WHERE m.conversation_id = p_conversation_id
      AND m.user_id = p_uid AND m.left_at IS NULL
  ) THEN RETURN false; END IF;

  IF v_kind = 'freeplay' THEN
    RETURN coalesce((
      SELECT CASE
        WHEN r.status = 'pending' THEN a.end_time > now()
        WHEN r.status = 'accepted' THEN a.end_time + interval '7 days' > now()
        WHEN r.status = 'host_cancelled' THEN a.end_time + interval '7 days' > now()
        ELSE false END
      FROM public.freeplay_request r
      JOIN public.activity a ON a.id = r.activity_id
      JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
      WHERE r.id = v_request
        AND NOT public.fn_is_blocked(r.user_id, h.user_id)
    ), false);
  END IF;

  RETURN false;  -- course branch lands with schema/course.sql
END
$$;
REVOKE ALL ON FUNCTION public.fn_can_write_conversation(uuid,uuid)
  FROM PUBLIC, anon, authenticated;

-- ── Notification fan-out ─────────────────────────────────────────────────────
-- Push on the "all read → has unread" transition, so the first message of a
-- burst rings and the rest don't. Realtime already carries the message to
-- anyone with the thread open.
--
-- The `_quiet_period` escape hatch matters: without it, a recipient who never
-- opens a thread stays in "has unread" forever and is never pushed again — the
-- exact case where notifying is most useful (a student messages a coach who
-- didn't look; next week's message is silent). With it the rule reads "at most
-- one push per thread per quiet period while you have unread", which is quiet
-- during a live exchange and still audible a day later.
-- The caller passes the kind, and the id of the message it just inserted — the
-- kind because `course_message` doesn't exist as an enum value until phase 2
-- (a literal cast to a not-yet-added value fails when the statement is parsed,
-- for every caller, not just the branch that mentions it), and the id so
-- "already had something unread" can exclude the message being announced.
CREATE OR REPLACE FUNCTION public.fn_notify_new_message(
  p_conversation_id uuid, p_message_id uuid, p_kind public.notification_kind,
  p_sender uuid, p_title text, p_body text, p_data jsonb
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_recipients uuid[]; v_quiet_period constant interval := interval '4 hours';
BEGIN
  SELECT array_agg(m.user_id) INTO v_recipients
  FROM public.conversation_member m
  WHERE m.conversation_id = p_conversation_id
    AND m.user_id <> p_sender
    AND m.left_at IS NULL
    AND (
      -- Nothing unread before this message: the transition worth announcing.
      NOT EXISTS (
        SELECT 1 FROM public.message x
        WHERE x.conversation_id = p_conversation_id
          AND x.id <> p_message_id
          AND x.created_at > m.last_read_at
          AND x.created_at >= m.joined_at
          AND (m.left_at IS NULL OR x.created_at <= m.left_at)
      )
      -- …or they've been sitting on unread long enough to be worth a nudge.
      OR NOT EXISTS (
        SELECT 1 FROM public.notification_outbox o
        WHERE o.recipient_user_id = m.user_id
          AND o.data->>'conversation_id' = p_conversation_id::text
          AND o.created_at > now() - v_quiet_period
      )
    );

  IF v_recipients IS NOT NULL THEN
    PERFORM public.fn_enqueue_notification(p_kind, v_recipients, p_title, p_body,
      coalesce(p_data,'{}'::jsonb) || jsonb_build_object('conversation_id', p_conversation_id));
  END IF;
END
$$;
REVOKE ALL ON FUNCTION public.fn_notify_new_message(uuid,uuid,public.notification_kind,uuid,text,text,jsonb)
  FROM PUBLIC, anon, authenticated;

-- ── Write RPCs ───────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.send_message(p_conversation_id uuid, p_body text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid; v_kind public.conversation_kind;
        v_data jsonb;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF nullif(btrim(p_body),'') IS NULL OR char_length(btrim(p_body)) > 2000 THEN
    RAISE EXCEPTION 'invalid message';
  END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, body)
  VALUES (p_conversation_id, v_uid, 'text', btrim(p_body))
  RETURNING id INTO v_id;

  SELECT c.kind INTO v_kind FROM public.conversation c WHERE c.id = p_conversation_id;

  -- Course conversations notify through their own kind; schema/course.sql
  -- REPLACEs this function once `course_message` exists as an enum value.
  IF v_kind = 'freeplay' THEN
    SELECT jsonb_build_object('activity_id', r.activity_id, 'request_id', r.id)
    INTO v_data FROM public.freeplay_request r
    JOIN public.conversation c ON c.freeplay_request_id = r.id
    WHERE c.id = p_conversation_id;

    PERFORM public.fn_notify_new_message(p_conversation_id, v_id,
      'freeplay_chat_message', v_uid, 'Tin nhắn Xé vé mới', 'Bạn có tin nhắn mới.', v_data);
  END IF;

  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.create_message_poll(
  p_conversation_id uuid, p_question text, p_options text[]
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_id uuid;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF nullif(btrim(p_question),'') IS NULL OR char_length(btrim(p_question)) > 200
     OR cardinality(p_options) NOT BETWEEN 2 AND 6 THEN
    RAISE EXCEPTION 'invalid poll';
  END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, payload)
  VALUES (p_conversation_id, v_uid, 'poll',
    jsonb_build_object('question', btrim(p_question), 'options', to_jsonb(p_options)))
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.vote_message_poll(
  p_message_id uuid, p_option_index smallint
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_conversation uuid; v_options int;
BEGIN
  SELECT m.conversation_id, jsonb_array_length(m.payload->'options')
  INTO v_conversation, v_options
  FROM public.message m WHERE m.id = p_message_id AND m.kind = 'poll';
  IF NOT FOUND THEN RAISE EXCEPTION 'poll not found'; END IF;
  IF NOT coalesce(public.fn_can_write_conversation(v_conversation, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  IF p_option_index < 0 OR p_option_index >= v_options THEN
    RAISE EXCEPTION 'invalid option';
  END IF;

  INSERT INTO public.message_poll_vote(message_id, user_id, option_index)
  VALUES (p_message_id, v_uid, p_option_index)
  ON CONFLICT (message_id, user_id) DO UPDATE SET option_index = excluded.option_index;
END
$$;

-- Host-shares-payment-details. Freeplay-only for now: courses carry no money
-- (the coach states rates on their profile, settlement happens off-app).
CREATE OR REPLACE FUNCTION public.share_conversation_payment_info(p_conversation_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_info uuid; v_id uuid; v_request uuid;
        v_activity uuid; v_recipient uuid;
BEGIN
  IF NOT coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false) THEN
    RAISE EXCEPTION 'chat is read-only';
  END IF;
  SELECT i.id INTO v_info FROM public.user_payment_info i WHERE i.user_id = v_uid;
  IF v_info IS NULL THEN RAISE EXCEPTION 'payment info not configured'; END IF;

  SELECT c.freeplay_request_id INTO v_request
  FROM public.conversation c WHERE c.id = p_conversation_id AND c.kind = 'freeplay';
  IF v_request IS NULL THEN RAISE EXCEPTION 'not a freeplay conversation'; END IF;

  SELECT r.activity_id, r.user_id INTO v_activity, v_recipient
  FROM public.freeplay_request r
  JOIN public.activity a ON a.id = r.activity_id
  JOIN public.freeplay_host h ON h.id = a.freeplay_host_id
  WHERE r.id = v_request AND h.user_id = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'Host access required'; END IF;

  INSERT INTO public.message(conversation_id, sender_id, kind, payment_info_id)
  VALUES (p_conversation_id, v_uid, 'payment_info', v_info)
  RETURNING id INTO v_id;

  PERFORM public.fn_enqueue_notification('freeplay_chat_message', ARRAY[v_recipient],
    'Host đã gửi thông tin thanh toán','Mở chat Xé vé để xem VietQR.',
    jsonb_build_object('activity_id',v_activity,'request_id',v_request,
                       'conversation_id',p_conversation_id));
  RETURN v_id;
END
$$;

CREATE OR REPLACE FUNCTION public.mark_conversation_read(p_conversation_id uuid)
RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path TO '' AS $$
  UPDATE public.conversation_member
  SET last_read_at = now()
  WHERE conversation_id = p_conversation_id AND user_id = auth.uid();
$$;

-- ── Read RPC ─────────────────────────────────────────────────────────────────
-- `p_since` NULL loads the thread; non-NULL fetches only what arrived after
-- that instant — the reconnect backfill path. Both are clamped to the caller's
-- own membership window.
CREATE OR REPLACE FUNCTION public.conversation_data(
  p_conversation_id uuid, p_since timestamptz DEFAULT NULL
) RETURNS TABLE(
  id uuid, sender_id uuid, sender_username text, sender_avatar text,
  kind text, body text, payload jsonb, created_at timestamptz,
  can_write boolean, payment_info jsonb, poll_votes jsonb, my_vote smallint
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_joined timestamptz; v_left timestamptz;
BEGIN
  SELECT m.joined_at, m.left_at INTO v_joined, v_left
  FROM public.conversation_member m
  WHERE m.conversation_id = p_conversation_id AND m.user_id = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'conversation not found'; END IF;

  RETURN QUERY
  -- username is varchar(16) on the table; the explicit cast is required or the
  -- RETURNS TABLE(text) declaration raises "structure of query does not match".
  SELECT m.id, m.sender_id, u.username::text, u.details->>'generatedAvatar',
         m.kind::text, m.body, m.payload, m.created_at,
         coalesce(public.fn_can_write_conversation(p_conversation_id, v_uid), false),
         CASE WHEN m.kind = 'payment_info' THEN jsonb_build_object(
           'id', i.id, 'bank_id', i.bank_id, 'bank_display_name', i.bank_display_name,
           'value', vv.decrypted_secret, 'account_name', vn.decrypted_secret,
           'created_at', i.created_at) END,
         CASE WHEN m.kind = 'poll' THEN
           (SELECT coalesce(jsonb_object_agg(t.option_index, t.c), '{}'::jsonb)
            FROM (SELECT v.option_index, count(*) c FROM public.message_poll_vote v
                  WHERE v.message_id = m.id GROUP BY v.option_index) t) END,
         CASE WHEN m.kind = 'poll' THEN
           (SELECT v.option_index FROM public.message_poll_vote v
            WHERE v.message_id = m.id AND v.user_id = v_uid) END
  FROM public.message m
  LEFT JOIN public."user" u ON u.id = m.sender_id
  LEFT JOIN public.user_payment_info i ON i.id = m.payment_info_id
  LEFT JOIN vault.decrypted_secrets vv ON vv.id = i.value_secret_id
  LEFT JOIN vault.decrypted_secrets vn ON vn.id = i.account_name_secret_id
  WHERE m.conversation_id = p_conversation_id
    AND m.created_at >= v_joined
    AND (v_left IS NULL OR m.created_at <= v_left)
    AND (p_since IS NULL OR m.created_at > p_since)
  ORDER BY m.created_at;
END
$$;

-- ── Grants ───────────────────────────────────────────────────────────────────

DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS signature
           FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
           WHERE n.nspname = 'public' AND p.proname IN (
             'send_message','create_message_poll','vote_message_poll',
             'share_conversation_payment_info','mark_conversation_read',
             'conversation_data')
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon', r.signature);
    EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO authenticated', r.signature);
  END LOOP;
END
$$;
