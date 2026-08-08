-- ============================================================================
-- payment_request_notification_activity_id.sql — payment_requested /
-- debt_collected pushes never carried an activity id, only feed_item_id
-- (which nothing on the client reads — notification_router.dart only reads
-- `record_id`). Add `activity_id` to the notification `data` payload so a
-- tap can route to (and highlight) the specific activity card, the same
-- convention `fn_emit_activity_scheduled` already uses.
--
-- Apply with execute_sql / apply_migration.
-- ============================================================================

-- ─── create_ancillary_payment_request: add activity_id to the push data ────
CREATE OR REPLACE FUNCTION public.create_ancillary_payment_request(
    p_activity_id uuid,
    p_total_amount numeric,
    p_note text,
    p_tagged_users uuid[]
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_lobby_id uuid;
    v_end_time timestamptz;
    v_start_time timestamptz;
    v_tagged uuid[];
    v_payee_count int;
    v_per_person numeric(10, 2);
    v_feed_item_id uuid;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;

    IF p_total_amount IS NULL OR p_total_amount <= 0 THEN
        RAISE EXCEPTION 'amount must be positive';
    END IF;

    v_tagged := ARRAY(SELECT DISTINCT u FROM unnest(p_tagged_users) AS u WHERE u <> v_uid);
    v_payee_count := COALESCE(array_length(v_tagged, 1), 0);
    IF v_payee_count = 0 THEN
        RAISE EXCEPTION 'must tag at least one lobby mate';
    END IF;

    SELECT a.lobby_id, a.end_time, a.start_time
      INTO v_lobby_id, v_end_time, v_start_time
      FROM public.activity a
      JOIN public.activity_confirmation ac
        ON ac.activity_id = a.id AND ac.user_id = v_uid AND ac.attendance = 'going'
     WHERE a.id = p_activity_id;

    IF v_lobby_id IS NULL THEN
        RAISE EXCEPTION 'must be a confirmed attendee of this session';
    END IF;

    IF COALESCE(v_end_time, v_start_time) > now() THEN
        RAISE EXCEPTION 'session has not ended yet';
    END IF;

    v_per_person := CEIL(p_total_amount / v_payee_count / 1000) * 1000;

    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, activity_id, payload)
    VALUES (
        v_lobby_id, v_uid, 'payment_request', p_activity_id,
        jsonb_build_object(
            'type',               'ancillary',
            'source_activity_id', p_activity_id,
            'recipient_id',       v_uid,
            'total_amount',       p_total_amount,
            'per_person_amount',  v_per_person,
            'note',               p_note
        )
    )
    RETURNING id INTO v_feed_item_id;

    INSERT INTO public.lobby_payment_request_payee (feed_item_id, user_id, amount_owed)
    SELECT v_feed_item_id, u, v_per_person FROM unnest(v_tagged) AS u;

    PERFORM public.fn_enqueue_notification(
        'payment_requested',
        v_tagged,
        'Yêu cầu thanh toán',
        COALESCE(p_note, 'Bạn được yêu cầu thanh toán ' || v_per_person::text || 'đ'),
        jsonb_build_object(
            'lobby_id', v_lobby_id,
            'feed_item_id', v_feed_item_id,
            'activity_id', p_activity_id
        ));

    RETURN v_feed_item_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ancillary_payment_request(uuid, numeric, text, uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_ancillary_payment_request(uuid, numeric, text, uuid[]) TO authenticated;


-- ─── fn_sweep_activity_payment_requests: same ───────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_sweep_activity_payment_requests()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    r record;
    v_payees uuid[];
    v_billable uuid[];
    v_payee_count int;
    v_per_person numeric(10, 2);
    v_feed_item_id uuid;
BEGIN
    FOR r IN
        SELECT a.id, a.lobby_id, a.user_id AS organizer_id,
               a.cost_type, a.cost_amount
          FROM public.activity a
         WHERE a.end_time IS NOT NULL
           AND a.end_time <= now() - interval '15 minutes'
           AND a.end_time >  now() - interval '1 day'
           AND a.cost_type IS NOT NULL
           AND a.lobby_id IS NOT NULL
           AND (
                (a.challenge_id IS NULL
                 AND public.activity_is_confirmed(a.id))
                OR
                (a.challenge_id IS NOT NULL
                 AND a.manager_confirmed_at IS NOT NULL)
           )
           AND NOT EXISTS (
               SELECT 1 FROM public.lobby_feed_item fi
                WHERE fi.kind = 'payment_request'
                  AND fi.payload->>'type' = 'split'
                  AND fi.payload->>'source_activity_id' = a.id::text
           )
    LOOP
        SELECT array_agg(ac.user_id) INTO v_payees
          FROM public.activity_confirmation ac
         WHERE ac.activity_id = r.id AND ac.attendance = 'going';

        v_payee_count := COALESCE(array_length(v_payees, 1), 0);
        IF v_payee_count = 0 THEN
            CONTINUE;
        END IF;

        v_per_person := CASE r.cost_type
            WHEN 'per_pax' THEN r.cost_amount
            ELSE CEIL(r.cost_amount / v_payee_count / 1000) * 1000
        END;

        v_billable := ARRAY(
            SELECT u FROM unnest(v_payees) AS u WHERE u <> r.organizer_id
        );
        IF COALESCE(array_length(v_billable, 1), 0) = 0 THEN
            CONTINUE;
        END IF;

        INSERT INTO public.lobby_feed_item
            (lobby_id, author_id, kind, activity_id, payload)
        VALUES (
            r.lobby_id, r.organizer_id, 'payment_request', r.id,
            jsonb_build_object(
                'type',               'split',
                'source_activity_id', r.id,
                'recipient_id',       r.organizer_id,
                'cost_type',          r.cost_type,
                'total_amount',       r.cost_amount,
                'per_person_amount',  v_per_person
            )
        )
        RETURNING id INTO v_feed_item_id;

        INSERT INTO public.lobby_payment_request_payee
            (feed_item_id, user_id, amount_owed)
        SELECT v_feed_item_id, u, v_per_person FROM unnest(v_billable) AS u;

        PERFORM public.fn_enqueue_notification(
            'payment_requested',
            v_billable,
            'Chia tiền buổi chơi',
            'Mỗi người đóng ' || v_per_person::text || 'đ',
            jsonb_build_object(
                'lobby_id', r.lobby_id,
                'feed_item_id', v_feed_item_id,
                'activity_id', r.id
            )
        );
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_sweep_activity_payment_requests() FROM PUBLIC, anon, authenticated;


-- ─── mark_payment_request_paid: same, reading activity_id off the feed item
--     row itself (the column, not the payload's source_activity_id text) ───
CREATE OR REPLACE FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_payload jsonb;
    v_lobby_id uuid;
    v_activity_id uuid;
    v_recipient uuid;
    v_total_payees int;
    v_total_paid int;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_payment_request_payee
         WHERE feed_item_id = p_feed_item_id AND user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'not a payer on this request';
    END IF;

    INSERT INTO public.lobby_feed_item_reaction (feed_item_id, user_id, emoji)
    VALUES (p_feed_item_id, v_uid, '✅')
    ON CONFLICT (feed_item_id, user_id) DO NOTHING;

    SELECT count(*) INTO v_total_payees
      FROM public.lobby_payment_request_payee WHERE feed_item_id = p_feed_item_id;

    SELECT count(*) INTO v_total_paid
      FROM public.lobby_feed_item_reaction r
     WHERE r.feed_item_id = p_feed_item_id
       AND EXISTS (
           SELECT 1 FROM public.lobby_payment_request_payee pr
            WHERE pr.feed_item_id = r.feed_item_id AND pr.user_id = r.user_id
       );

    IF v_total_payees > 0 AND v_total_paid >= v_total_payees THEN
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

REVOKE ALL ON FUNCTION public.mark_payment_request_paid(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_payment_request_paid(uuid) TO authenticated;
