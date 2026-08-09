-- lobby_money.sql — friendly, lobby-scoped bill tracking and pairwise clearing.
--
-- Payment requests already create one row per tagged member. This migration
-- makes those rows authoritative: every new row starts outstanding, individual
-- confirmation clears one row, and the lobby Feed can clear all outstanding
-- rows between two members after subtracting the two directions.
--
-- This is VND bookkeeping for payments made outside Passe. It intentionally
-- has no dependency on the iced đá prototype in lib/currency/.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type WHERE typname = 'lobby_payment_status'
    ) THEN
        CREATE TYPE public.lobby_payment_status AS ENUM (
            'outstanding',
            'paid_direct',
            'cleared_together'
        );
    END IF;
END
$$;

ALTER TABLE public.lobby_payment_request_payee
    ADD COLUMN IF NOT EXISTS id uuid NOT NULL DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS recipient_id uuid,
    ADD COLUMN IF NOT EXISTS status public.lobby_payment_status
        NOT NULL DEFAULT 'outstanding',
    ADD COLUMN IF NOT EXISTS paid_at timestamptz;

UPDATE public.lobby_payment_request_payee pr
   SET recipient_id = (fi.payload->>'recipient_id')::uuid
  FROM public.lobby_feed_item fi
 WHERE fi.id = pr.feed_item_id
   AND pr.recipient_id IS NULL;

UPDATE public.lobby_payment_request_payee pr
   SET status = 'paid_direct',
       paid_at = COALESCE(pr.paid_at, r.created_at)
  FROM public.lobby_feed_item_reaction r
 WHERE r.feed_item_id = pr.feed_item_id
   AND r.user_id = pr.user_id
   AND pr.status = 'outstanding';

ALTER TABLE public.lobby_payment_request_payee
    ALTER COLUMN recipient_id SET NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'lobby_payment_request_payee_id_key'
    ) THEN
        ALTER TABLE public.lobby_payment_request_payee
            ADD CONSTRAINT lobby_payment_request_payee_id_key UNIQUE (id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'lobby_payment_request_payee_recipient_id_fkey'
    ) THEN
        ALTER TABLE public.lobby_payment_request_payee
            ADD CONSTRAINT lobby_payment_request_payee_recipient_id_fkey
            FOREIGN KEY (recipient_id) REFERENCES public."user"(id)
            ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
         WHERE conname = 'lobby_payment_request_payee_status_time_check'
    ) THEN
        ALTER TABLE public.lobby_payment_request_payee
            ADD CONSTRAINT lobby_payment_request_payee_status_time_check CHECK (
                (status = 'outstanding' AND paid_at IS NULL)
                OR
                (status IN ('paid_direct', 'cleared_together') AND paid_at IS NOT NULL)
            );
    END IF;
END
$$;

CREATE INDEX IF NOT EXISTS lobby_payment_request_payee_outstanding_user_idx
    ON public.lobby_payment_request_payee (user_id, recipient_id)
    WHERE status = 'outstanding';

CREATE INDEX IF NOT EXISTS lobby_payment_request_payee_recipient_idx
    ON public.lobby_payment_request_payee (recipient_id);

CREATE OR REPLACE FUNCTION public.fn_fill_payment_request_recipient()
    RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_recipient_id uuid;
BEGIN
    SELECT (fi.payload->>'recipient_id')::uuid
      INTO v_recipient_id
      FROM public.lobby_feed_item fi
     WHERE fi.id = NEW.feed_item_id
       AND fi.kind = 'payment_request';

    IF v_recipient_id IS NULL THEN
        RAISE EXCEPTION 'payment request recipient is missing';
    END IF;
    IF v_recipient_id = NEW.user_id THEN
        RAISE EXCEPTION 'a member cannot owe themselves';
    END IF;

    NEW.recipient_id := v_recipient_id;
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_fill_payment_request_recipient()
    FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS fill_payment_request_recipient
    ON public.lobby_payment_request_payee;
CREATE TRIGGER fill_payment_request_recipient
    BEFORE INSERT OR UPDATE OF feed_item_id, user_id
    ON public.lobby_payment_request_payee
    FOR EACH ROW EXECUTE FUNCTION public.fn_fill_payment_request_recipient();

CREATE TABLE IF NOT EXISTS public.lobby_payment_settlement (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lobby_id uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    payer_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
    recipient_id uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
    payer_gross numeric(12, 2) NOT NULL CHECK (payer_gross >= 0),
    recipient_gross numeric(12, 2) NOT NULL CHECK (recipient_gross >= 0),
    transferred_amount numeric(12, 2) NOT NULL CHECK (transferred_amount >= 0),
    idempotency_key uuid NOT NULL,
    feed_item_id uuid UNIQUE REFERENCES public.lobby_feed_item(id)
        ON DELETE SET NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT lobby_payment_settlement_people_check
        CHECK (payer_id <> recipient_id),
    CONSTRAINT lobby_payment_settlement_amount_check CHECK (
        payer_gross > 0
        AND payer_gross >= recipient_gross
        AND transferred_amount = payer_gross - recipient_gross
    ),
    CONSTRAINT lobby_payment_settlement_idempotency_key
        UNIQUE (payer_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS public.lobby_payment_settlement_item (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    settlement_id uuid NOT NULL
        REFERENCES public.lobby_payment_settlement(id) ON DELETE CASCADE,
    obligation_id uuid UNIQUE
        REFERENCES public.lobby_payment_request_payee(id) ON DELETE SET NULL,
    source_feed_item_id uuid,
    source_activity_id uuid,
    debtor_id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    amount numeric(10, 2) NOT NULL CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS lobby_payment_settlement_lobby_idx
    ON public.lobby_payment_settlement (lobby_id);
CREATE INDEX IF NOT EXISTS lobby_payment_settlement_recipient_idx
    ON public.lobby_payment_settlement (recipient_id);
CREATE INDEX IF NOT EXISTS lobby_payment_settlement_item_settlement_idx
    ON public.lobby_payment_settlement_item (settlement_id);

ALTER TABLE public.lobby_payment_settlement ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lobby_payment_settlement_item ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.lobby_payment_settlement,
    public.lobby_payment_settlement_item FROM PUBLIC, anon, authenticated;

-- One row per other member, from the caller's point of view. Positive means
-- they need to send the caller money; negative means the caller needs to send
-- them money. Entries are never deduplicated: every request remains a row,
-- even when dates or source activities match.
CREATE OR REPLACE FUNCTION public.lobby_money_data(p_lobby_id uuid)
    RETURNS TABLE(
        counterparty_id uuid,
        username text,
        generated_avatar text,
        signed_total numeric,
        entries jsonb
    )
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;
    IF p_lobby_id NOT IN (SELECT public.get_my_lobby_ids()) THEN
        RAISE EXCEPTION 'not a lobby member';
    END IF;

    RETURN QUERY
    WITH relevant AS (
        SELECT pr.id AS obligation_id,
               fi.id AS source_feed_item_id,
               fi.activity_id AS source_activity_id,
               COALESCE(a.start_time, fi.created_at) AS source_date,
               CASE
                   WHEN pr.user_id = v_uid THEN pr.recipient_id
                   ELSE pr.user_id
               END AS other_id,
               CASE
                   WHEN pr.user_id = v_uid THEN -pr.amount_owed
                   ELSE pr.amount_owed
               END AS signed_amount
          FROM public.lobby_payment_request_payee pr
          JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
          LEFT JOIN public.activity a ON a.id = fi.activity_id
         WHERE fi.lobby_id = p_lobby_id
           AND pr.status = 'outstanding'
           AND (
               pr.user_id = v_uid
               OR pr.recipient_id = v_uid
           )
    )
    SELECT r.other_id,
           u.username::text,
           u.details->>'generatedAvatar',
           SUM(r.signed_amount),
           jsonb_agg(
               jsonb_build_object(
                   'obligation_id', r.obligation_id,
                   'feed_item_id', r.source_feed_item_id,
                   'activity_id', r.source_activity_id,
                   'activity_date', r.source_date,
                   'signed_amount', r.signed_amount
               )
               ORDER BY r.source_date, r.obligation_id
           )
      FROM relevant r
      JOIN public."user" u ON u.id = r.other_id
     GROUP BY r.other_id, u.username, u.details->>'generatedAvatar'
     ORDER BY u.username;
END;
$$;

REVOKE ALL ON FUNCTION public.lobby_money_data(uuid)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.lobby_money_data(uuid) TO authenticated;
ALTER FUNCTION public.lobby_money_data(uuid) SECURITY INVOKER;

CREATE OR REPLACE FUNCTION public.settle_lobby_money(
    p_lobby_id uuid,
    p_counterparty_id uuid,
    p_idempotency_key uuid
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_existing_id uuid;
    v_settlement_id uuid;
    v_feed_item_id uuid;
    v_i_owe numeric(12, 2);
    v_they_owe numeric(12, 2);
    v_transfer numeric(12, 2);
    v_my_name text;
    v_other_name text;
    v_text text;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;
    IF p_counterparty_id IS NULL OR p_counterparty_id = v_uid THEN
        RAISE EXCEPTION 'invalid counterparty';
    END IF;
    IF p_idempotency_key IS NULL THEN
        RAISE EXCEPTION 'idempotency key is required';
    END IF;
    IF p_lobby_id NOT IN (SELECT public.get_my_lobby_ids()) THEN
        RAISE EXCEPTION 'not a lobby member';
    END IF;

    SELECT s.id INTO v_existing_id
      FROM public.lobby_payment_settlement s
     WHERE s.payer_id = v_uid
       AND s.idempotency_key = p_idempotency_key;
    IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
    END IF;

    -- Serialize direct confirmations and pair settlements on the same rows.
    PERFORM 1
      FROM public.lobby_payment_request_payee pr
      JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
     WHERE fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       )
     FOR UPDATE OF pr;

    SELECT COALESCE(SUM(pr.amount_owed) FILTER (
               WHERE pr.user_id = v_uid
                 AND pr.recipient_id = p_counterparty_id
           ), 0),
           COALESCE(SUM(pr.amount_owed) FILTER (
               WHERE pr.user_id = p_counterparty_id
                 AND pr.recipient_id = v_uid
           ), 0)
      INTO v_i_owe, v_they_owe
      FROM public.lobby_payment_request_payee pr
      JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
     WHERE fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       );

    IF v_i_owe = 0 AND v_they_owe = 0 THEN
        RAISE EXCEPTION 'nothing to send';
    END IF;
    IF v_i_owe < v_they_owe THEN
        RAISE EXCEPTION 'the other member needs to send you';
    END IF;

    v_transfer := v_i_owe - v_they_owe;

    INSERT INTO public.lobby_payment_settlement (
        lobby_id, payer_id, recipient_id, payer_gross, recipient_gross,
        transferred_amount, idempotency_key
    ) VALUES (
        p_lobby_id, v_uid, p_counterparty_id, v_i_owe, v_they_owe,
        v_transfer, p_idempotency_key
    ) RETURNING id INTO v_settlement_id;

    INSERT INTO public.lobby_payment_settlement_item (
        settlement_id, obligation_id, source_feed_item_id,
        source_activity_id, debtor_id, recipient_id, amount
    )
    SELECT v_settlement_id, pr.id, fi.id, fi.activity_id,
           pr.user_id, pr.recipient_id, pr.amount_owed
      FROM public.lobby_payment_request_payee pr
      JOIN public.lobby_feed_item fi ON fi.id = pr.feed_item_id
     WHERE fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       );

    UPDATE public.lobby_payment_request_payee pr
       SET status = 'cleared_together',
           paid_at = now()
      FROM public.lobby_feed_item fi
     WHERE fi.id = pr.feed_item_id
       AND fi.lobby_id = p_lobby_id
       AND pr.status = 'outstanding'
       AND (
           (pr.user_id = v_uid AND pr.recipient_id = p_counterparty_id)
           OR
           (pr.user_id = p_counterparty_id AND pr.recipient_id = v_uid)
       );

    SELECT u.username::text INTO v_my_name
      FROM public."user" u WHERE u.id = v_uid;
    SELECT u.username::text INTO v_other_name
      FROM public."user" u WHERE u.id = p_counterparty_id;

    IF v_transfer = 0 THEN
        v_text := v_my_name || ' và ' || v_other_name ||
            ' đã trừ các khoản qua lại — huề rồi';
    ELSE
        v_text := v_my_name || ' và ' || v_other_name ||
            ' đã tính tiền xong · ' || v_my_name || ' gửi ' ||
            v_other_name || ' ' ||
            replace(to_char(v_transfer, 'FM999,999,999,990'), ',', '.') || 'đ';
    END IF;

    INSERT INTO public.lobby_feed_item (
        lobby_id, author_id, kind, payload
    ) VALUES (
        p_lobby_id, v_uid, 'system',
        jsonb_build_object(
            'text', v_text,
            'event_kind', 'money_settlement',
            'settlement_id', v_settlement_id,
            'payer_id', v_uid,
            'recipient_id', p_counterparty_id,
            'transferred_amount', v_transfer
        )
    ) RETURNING id INTO v_feed_item_id;

    UPDATE public.lobby_payment_settlement
       SET feed_item_id = v_feed_item_id
     WHERE id = v_settlement_id;

    RETURN v_settlement_id;
END;
$$;

REVOKE ALL ON FUNCTION public.settle_lobby_money(uuid, uuid, uuid)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.settle_lobby_money(uuid, uuid, uuid)
    TO authenticated;

-- Individual confirmation is only valid while the request line is still
-- outstanding. A line already cleared in a combined payment cannot be paid
-- twice through the original activity card.
CREATE OR REPLACE FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_status public.lobby_payment_status;
    v_payload jsonb;
    v_lobby_id uuid;
    v_activity_id uuid;
    v_recipient uuid;
    v_total_payees int;
    v_total_resolved int;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;

    SELECT pr.status INTO v_status
      FROM public.lobby_payment_request_payee pr
     WHERE pr.feed_item_id = p_feed_item_id
       AND pr.user_id = v_uid
     FOR UPDATE;

    IF v_status IS NULL THEN
        RAISE EXCEPTION 'not a payer on this request';
    END IF;
    IF v_status = 'paid_direct' THEN
        RETURN;
    END IF;
    IF v_status <> 'outstanding' THEN
        RAISE EXCEPTION 'payment was already cleared together';
    END IF;

    UPDATE public.lobby_payment_request_payee
       SET status = 'paid_direct', paid_at = now()
     WHERE feed_item_id = p_feed_item_id AND user_id = v_uid;

    INSERT INTO public.lobby_feed_item_reaction (feed_item_id, user_id, emoji)
    VALUES (p_feed_item_id, v_uid, '✅')
    ON CONFLICT (feed_item_id, user_id) DO NOTHING;

    SELECT count(*), count(*) FILTER (WHERE status <> 'outstanding')
      INTO v_total_payees, v_total_resolved
      FROM public.lobby_payment_request_payee
     WHERE feed_item_id = p_feed_item_id;

    IF v_total_payees > 0 AND v_total_resolved >= v_total_payees THEN
        SELECT payload, lobby_id, activity_id
          INTO v_payload, v_lobby_id, v_activity_id
          FROM public.lobby_feed_item WHERE id = p_feed_item_id;
        v_recipient := (v_payload->>'recipient_id')::uuid;

        IF v_recipient IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'debt_collected',
                ARRAY[v_recipient],
                'Đã thu đủ tiền',
                'Mọi người đã xác nhận thanh toán',
                jsonb_build_object(
                    'lobby_id', v_lobby_id,
                    'feed_item_id', p_feed_item_id,
                    'activity_id', v_activity_id
                ));
        END IF;
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_payment_request_paid(uuid)
    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_payment_request_paid(uuid)
    TO authenticated;

-- Keep the existing RPC signature; enrich each payment line with its
-- authoritative status while retaining `paid` for older clients.
CREATE OR REPLACE FUNCTION public.lobby_feed_data(
    p_lobby_id uuid,
    p_page_size integer DEFAULT 50,
    p_before timestamptz DEFAULT NULL
) RETURNS TABLE(
    id uuid,
    author_id uuid,
    author_username varchar,
    kind public.lobby_feed_item_kind,
    payload jsonb,
    created_at timestamptz,
    poll_tallies jsonb,
    my_vote integer,
    payment_payees jsonb,
    author_generated_avatar text,
    activity_id uuid
) LANGUAGE plpgsql SET search_path TO ''
AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM (
        SELECT fi.id, fi.author_id, u.username, fi.kind, fi.payload, fi.created_at,
               CASE WHEN fi.kind = 'poll' THEN (
                   SELECT jsonb_object_agg(option_index::text, c)
                     FROM (
                         SELECT option_index, count(*) AS c
                           FROM public.lobby_feed_poll_vote v
                          WHERE v.feed_item_id = fi.id
                          GROUP BY option_index
                     ) t
               ) END,
               CASE WHEN fi.kind = 'poll' THEN (
                   SELECT v.option_index
                     FROM public.lobby_feed_poll_vote v
                    WHERE v.feed_item_id = fi.id AND v.user_id = auth.uid()
               ) END,
               CASE WHEN fi.kind = 'payment_request' THEN (
                   SELECT jsonb_agg(
                       jsonb_build_object(
                           'user_id', pr.user_id,
                           'username', pu.username,
                           'generated_avatar', pu.details->>'generatedAvatar',
                           'amount_owed', pr.amount_owed,
                           'status', pr.status::text,
                           'paid', pr.status <> 'outstanding'
                       ) ORDER BY pu.username, pr.user_id
                   )
                     FROM public.lobby_payment_request_payee pr
                     JOIN public."user" pu ON pu.id = pr.user_id
                    WHERE pr.feed_item_id = fi.id
               ) END,
               u.details->>'generatedAvatar', fi.activity_id
          FROM public.lobby_feed_item fi
          LEFT JOIN public."user" u ON u.id = fi.author_id
         WHERE fi.lobby_id = p_lobby_id
           AND fi.kind <> 'photo'
           AND (p_before IS NULL OR fi.created_at < p_before)

        UNION ALL

        SELECT p.id, p.author_id, au.username,
               'photo'::public.lobby_feed_item_kind,
               jsonb_build_object(
                   'id', p.id,
                   'author_id', p.author_id,
                   'author_username', au.username,
                   'author_tag_number', au.tag_number,
                   'author_details', au.details,
                   'sport_id', p.sport_id,
                   'lobby_id', p.lobby_id,
                   'source_label', p.source_label,
                   'source_start_time', p.source_start_time,
                   'source_venue_name', p.source_venue_name,
                   'caption', p.caption,
                   'media', p.media,
                   'created_at', p.created_at,
                   'expires_at', p.expires_at,
                   'tags', COALESCE((
                       SELECT jsonb_agg(jsonb_build_object(
                           'user_id', tu.id,
                           'username', tu.username,
                           'tag_number', tu.tag_number
                       ))
                         FROM public.wall_post_tag t
                         JOIN public."user" tu ON tu.id = t.user_id
                        WHERE t.post_id = p.id
                   ), '[]'::jsonb),
                   'reactions', COALESCE((
                       SELECT jsonb_object_agg(r.emoji, r.n)
                         FROM (
                             SELECT emoji, count(*) AS n
                               FROM public.wall_post_reaction
                              WHERE post_id = p.id
                              GROUP BY emoji
                         ) r
                   ), '{}'::jsonb),
                   'my_reactions', COALESCE((
                       SELECT jsonb_agg(r.emoji ORDER BY r.created_at)
                         FROM public.wall_post_reaction r
                        WHERE r.post_id = p.id
                          AND r.user_id = auth.uid()
                   ), '[]'::jsonb)
               ),
               p.created_at,
               NULL::jsonb,
               NULL::integer,
               NULL::jsonb,
               au.details->>'generatedAvatar',
               NULL::uuid
          FROM public.wall_post p
          JOIN public."user" au ON au.id = p.author_id
         WHERE p.lobby_id = p_lobby_id
           AND p.hidden_at IS NULL
           AND p.expires_at > now()
           AND (p_before IS NULL OR p.created_at < p_before)
    ) merged
    ORDER BY merged.created_at DESC
    LIMIT p_page_size;
END;
$$;

ALTER FUNCTION public.lobby_feed_data(uuid, integer, timestamptz)
    OWNER TO postgres;
REVOKE ALL ON FUNCTION public.lobby_feed_data(uuid, integer, timestamptz)
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.lobby_feed_data(uuid, integer, timestamptz)
    TO authenticated;
