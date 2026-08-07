-- Ordinary lobby activities never set manager_confirmed_at; that column is
-- the explicit second confirmation step for challenge activities only.
-- Consequently the previous sweep silently skipped every ordinary paid
-- session. Use the canonical derived confirmation for ordinary activities,
-- while retaining manager confirmation for challenges.

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
                'feed_item_id', v_feed_item_id
            )
        );
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_sweep_activity_payment_requests()
    FROM PUBLIC, anon, authenticated;
