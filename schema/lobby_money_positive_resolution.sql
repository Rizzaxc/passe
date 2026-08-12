-- Allow either side of an outstanding pairwise balance to confirm that the
-- out-of-app transfer is complete. The settlement still records the actual
-- net debtor as payer, even when the recipient is the member confirming it.

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
    v_payer_id uuid;
    v_recipient_id uuid;
    v_payer_gross numeric(12, 2);
    v_recipient_gross numeric(12, 2);
    v_transfer numeric(12, 2);
    v_payer_name text;
    v_recipient_name text;
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

    -- The confirmer can be either the payer or recipient, so the retry lookup
    -- cannot assume that auth.uid() is the settlement's payer.
    SELECT s.id INTO v_existing_id
      FROM public.lobby_payment_settlement s
     WHERE s.lobby_id = p_lobby_id
       AND s.idempotency_key = p_idempotency_key
       AND (
           s.payer_id = v_uid
           OR s.recipient_id = v_uid
       );
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
        RAISE EXCEPTION 'nothing to settle';
    END IF;

    IF v_i_owe >= v_they_owe THEN
        v_payer_id := v_uid;
        v_recipient_id := p_counterparty_id;
        v_payer_gross := v_i_owe;
        v_recipient_gross := v_they_owe;
    ELSE
        v_payer_id := p_counterparty_id;
        v_recipient_id := v_uid;
        v_payer_gross := v_they_owe;
        v_recipient_gross := v_i_owe;
    END IF;
    v_transfer := v_payer_gross - v_recipient_gross;

    INSERT INTO public.lobby_payment_settlement (
        lobby_id, payer_id, recipient_id, payer_gross, recipient_gross,
        transferred_amount, idempotency_key
    ) VALUES (
        p_lobby_id, v_payer_id, v_recipient_id, v_payer_gross,
        v_recipient_gross, v_transfer, p_idempotency_key
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

    SELECT u.username::text INTO v_payer_name
      FROM public."user" u WHERE u.id = v_payer_id;
    SELECT u.username::text INTO v_recipient_name
      FROM public."user" u WHERE u.id = v_recipient_id;

    IF v_transfer = 0 THEN
        v_text := v_payer_name || ' và ' || v_recipient_name ||
            ' đã trừ các khoản qua lại — huề rồi';
    ELSE
        v_text := v_payer_name || ' và ' || v_recipient_name ||
            ' đã tính tiền xong · ' || v_payer_name || ' gửi ' ||
            v_recipient_name || ' ' ||
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
            'payer_id', v_payer_id,
            'recipient_id', v_recipient_id,
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
