-- ============================================================================
-- ancillary_payment_request_requires_ended_activity.sql — server-side backstop
-- so "Đòi Tiền" (create_ancillary_payment_request) can only be fired for a
-- session that has actually ended.
--
-- The client already only exposes this action from the History tab's
-- completed-activity card (_PastActivityCard in
-- lib/manage_tab/lobby_section/history/view.dart), which by construction
-- (LobbyMatchHistoryController._rowToPastActivity) only ever represents an
-- activity whose end_time — or start_time, for the rare row with none — has
-- already passed. This mirrors that check server-side (same reasoning as the
-- existing "must be a confirmed attendee of this session" guard right next
-- to it) so a direct RPC call can't request payment ahead of the session.
--
-- Apply with execute_sql / apply_migration.
-- ============================================================================

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
        jsonb_build_object('lobby_id', v_lobby_id, 'feed_item_id', v_feed_item_id));

    RETURN v_feed_item_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_ancillary_payment_request(uuid, numeric, text, uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_ancillary_payment_request(uuid, numeric, text, uuid[]) TO authenticated;
