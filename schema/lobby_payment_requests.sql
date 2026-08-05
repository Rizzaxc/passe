-- ============================================================================
-- lobby_payment_requests.sql — Part B of the payment-request feature.
-- Apply schema/lobby_payment_requests_enums.sql FIRST.
--
-- Two flows share one shape — a `lobby_feed_item(kind = 'payment_request')`
-- naming who owes what, plus a per-user "paid" acknowledgment:
--
--   split     — auto-created 15 min after a session ends (fn_sweep_activity_
--               payment_requests, hooked into fn_cron_tick) once the activity
--               was official (manager_confirmed_at set) and carries a cost.
--               Owed to the organizer (activity.user_id); split across every
--               `going` attendee, organizer included in the divisor but not
--               billed themselves (they fronted it).
--   ancillary — any confirmed attendee can start one by hand
--               (create_ancillary_payment_request) against tagged lobby
--               mates, defaulting to the session's attendee list. Owed to
--               whoever started it.
--
-- "Paid" is a self-reported, best-effort ack — a fixed-emoji row in
-- lobby_feed_item_reaction (mirrors wall_post_reaction's shape) rather than a
-- new UI surface, so the feed doesn't get a bespoke checklist widget. No
-- ledger backs this; nothing stops a false ack.
-- ============================================================================

-- ─── Who owes what ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lobby_payment_request_payee (
    feed_item_id uuid NOT NULL
        REFERENCES public.lobby_feed_item(id) ON DELETE CASCADE,
    user_id uuid NOT NULL
        REFERENCES public."user"(id) ON DELETE CASCADE,
    amount_owed numeric(10, 2) NOT NULL CHECK (amount_owed > 0),
    PRIMARY KEY (feed_item_id, user_id)
);

COMMENT ON TABLE public.lobby_payment_request_payee IS
  'Who owes what on a lobby_feed_item(kind = payment_request). Written only by create_ancillary_payment_request() / fn_sweep_activity_payment_requests() — no client INSERT policy.';

CREATE INDEX IF NOT EXISTS lobby_payment_request_payee_user_idx
    ON public.lobby_payment_request_payee (user_id);

ALTER TABLE public.lobby_payment_request_payee ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lobby members can read payment request payees"
    ON public.lobby_payment_request_payee;
CREATE POLICY "Lobby members can read payment request payees"
    ON public.lobby_payment_request_payee
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.lobby_feed_item fi
             WHERE fi.id = lobby_payment_request_payee.feed_item_id
               AND fi.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );


-- ─── "I've paid" acknowledgment ─────────────────────────────────────────────
-- Shaped exactly like wall_post_reaction, scoped to payment_request items by
-- the mark_payment_request_paid() function (not a DB constraint — matches
-- the codebase's preference for function-level validation over cross-table
-- CHECKs; see react_to_wall_post).
CREATE TABLE IF NOT EXISTS public.lobby_feed_item_reaction (
    feed_item_id uuid NOT NULL
        REFERENCES public.lobby_feed_item(id) ON DELETE CASCADE,
    user_id uuid NOT NULL
        REFERENCES public."user"(id) ON DELETE CASCADE,
    emoji text NOT NULL CHECK (char_length(emoji) BETWEEN 1 AND 8),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (feed_item_id, user_id)
);

ALTER TABLE public.lobby_feed_item_reaction ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lobby members can read feed item reactions"
    ON public.lobby_feed_item_reaction;
CREATE POLICY "Lobby members can read feed item reactions"
    ON public.lobby_feed_item_reaction
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.lobby_feed_item fi
             WHERE fi.id = lobby_feed_item_reaction.feed_item_id
               AND fi.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );


-- ─── lobby_feed_data: merge in payment_payees (paid/pending per payee) ──────
-- Return-type change requires DROP + CREATE (CREATE OR REPLACE can't add
-- output columns) — same reason schema/lobby_feed_poll_my_vote.sql exists.
DROP FUNCTION IF EXISTS public.lobby_feed_data(uuid, integer, timestamp with time zone);

CREATE FUNCTION public.lobby_feed_data(
    p_lobby_id  uuid,
    p_page_size integer DEFAULT 50,
    p_before    timestamp with time zone DEFAULT NULL
) RETURNS TABLE(
    id uuid,
    author_id uuid,
    author_username character varying,
    kind public.lobby_feed_item_kind,
    payload jsonb,
    created_at timestamp with time zone,
    poll_tallies jsonb,
    my_vote integer,
    payment_payees jsonb
)
    LANGUAGE plpgsql SET search_path TO ''
AS $$
BEGIN
    RETURN QUERY
        SELECT * FROM (
            SELECT fi.id,
                   fi.author_id,
                   u.username                             AS author_username,
                   fi.kind,
                   fi.payload,
                   fi.created_at,
                   CASE WHEN fi.kind = 'poll' THEN
                       (SELECT jsonb_object_agg(option_index::text, c)
                        FROM (
                            SELECT option_index, COUNT(*) AS c
                            FROM public.lobby_feed_poll_vote v
                            WHERE v.feed_item_id = fi.id
                            GROUP BY option_index
                        ) t)
                   END                                    AS poll_tallies,
                   CASE WHEN fi.kind = 'poll' THEN
                       (SELECT v.option_index
                        FROM public.lobby_feed_poll_vote v
                        WHERE v.feed_item_id = fi.id AND v.user_id = auth.uid())
                   END                                    AS my_vote,
                   CASE WHEN fi.kind = 'payment_request' THEN
                       (SELECT jsonb_agg(jsonb_build_object(
                                  'user_id',     pr.user_id,
                                  'username',    pu.username,
                                  'amount_owed', pr.amount_owed,
                                  'paid',        (r.user_id IS NOT NULL)))
                          FROM public.lobby_payment_request_payee pr
                          JOIN public."user" pu ON pu.id = pr.user_id
                          LEFT JOIN public.lobby_feed_item_reaction r
                                 ON r.feed_item_id = fi.id AND r.user_id = pr.user_id
                         WHERE pr.feed_item_id = fi.id)
                   END                                    AS payment_payees
            FROM public.lobby_feed_item fi
                     LEFT JOIN public."user" u ON u.id = fi.author_id
            WHERE fi.lobby_id = p_lobby_id
              AND fi.kind <> 'photo'
              AND (p_before IS NULL OR fi.created_at < p_before)

            UNION ALL

            SELECT p.id,
                   p.author_id,
                   au.username                            AS author_username,
                   'photo'::public.lobby_feed_item_kind   AS kind,
                   jsonb_build_object(
                       'id',                p.id,
                       'author_id',         p.author_id,
                       'author_username',   au.username,
                       'author_tag_number', au.tag_number,
                       'author_details',    au.details,
                       'sport_id',          p.sport_id,
                       'lobby_id',          p.lobby_id,
                       'source_label',      p.source_label,
                       'source_start_time', p.source_start_time,
                       'source_venue_name', p.source_venue_name,
                       'caption',           p.caption,
                       'image_paths',       to_jsonb(p.image_paths),
                       'created_at',        p.created_at,
                       'expires_at',        p.expires_at,
                       'tags', coalesce((
                           SELECT jsonb_agg(jsonb_build_object(
                                      'user_id', tu.id,
                                      'username', tu.username,
                                      'tag_number', tu.tag_number))
                           FROM public.wall_post_tag t
                           JOIN public."user" tu ON tu.id = t.user_id
                           WHERE t.post_id = p.id
                       ), '[]'::jsonb),
                       'reactions', coalesce((
                           SELECT jsonb_object_agg(r.emoji, r.n)
                           FROM (SELECT emoji, count(*) AS n
                                   FROM public.wall_post_reaction
                                  WHERE post_id = p.id
                                  GROUP BY emoji) r
                       ), '{}'::jsonb),
                       'my_reaction', (
                           SELECT emoji FROM public.wall_post_reaction
                            WHERE post_id = p.id AND user_id = auth.uid())
                   )                                      AS payload,
                   p.created_at,
                   NULL::jsonb                            AS poll_tallies,
                   NULL::integer                          AS my_vote,
                   NULL::jsonb                             AS payment_payees
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

ALTER FUNCTION public.lobby_feed_data(uuid, integer, timestamp with time zone) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION public.lobby_feed_data(uuid, integer, timestamp with time zone) TO authenticated;


-- ─── create_ancillary_payment_request: "đòi tiền trà đá" ────────────────────
-- Any confirmed (going) attendee of p_activity_id can start one, tagging any
-- subset of lobby mates (defaults to that activity's attendee list client-
-- side; not enforced server-side beyond "at least one, excluding yourself").
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

    SELECT a.lobby_id INTO v_lobby_id
      FROM public.activity a
      JOIN public.activity_confirmation ac
        ON ac.activity_id = a.id AND ac.user_id = v_uid AND ac.attendance = 'going'
     WHERE a.id = p_activity_id;

    IF v_lobby_id IS NULL THEN
        RAISE EXCEPTION 'must be a confirmed attendee of this session';
    END IF;

    v_per_person := CEIL(p_total_amount / v_payee_count / 1000) * 1000;

    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
    VALUES (
        v_lobby_id, v_uid, 'payment_request',
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


-- ─── mark_payment_request_paid: the self-report "I've paid" ack ────────────
CREATE OR REPLACE FUNCTION public.mark_payment_request_paid(p_feed_item_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_payload jsonb;
    v_lobby_id uuid;
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
        SELECT payload, lobby_id INTO v_payload, v_lobby_id
          FROM public.lobby_feed_item WHERE id = p_feed_item_id;
        v_recipient := (v_payload->>'recipient_id')::uuid;

        IF v_recipient IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'debt_collected',
                ARRAY[v_recipient],
                'Đã thu đủ tiền',
                'Mọi người đã xác nhận thanh toán',
                jsonb_build_object('lobby_id', v_lobby_id, 'feed_item_id', p_feed_item_id));
        END IF;
    END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_payment_request_paid(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_payment_request_paid(uuid) TO authenticated;


-- ─── fn_sweep_activity_payment_requests: auto "chia tiền" ───────────────────
-- Hooked into fn_cron_tick below, 15 min after a session's end_time, once it
-- was official (manager_confirmed_at set — RSVP quorum alone isn't "official"
-- anywhere else in this codebase either, see the challenge flow) and carries
-- a cost. Scans a rolling 1-day window so this stays cheap forever.
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
        SELECT a.id, a.lobby_id, a.user_id AS organizer_id, a.cost_type, a.cost_amount
          FROM public.activity a
         WHERE a.end_time IS NOT NULL
           AND a.end_time <= now() - interval '15 minutes'
           AND a.end_time >  now() - interval '1 day'
           AND a.cost_type IS NOT NULL
           AND a.manager_confirmed_at IS NOT NULL
           AND a.lobby_id IS NOT NULL
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
        -- n includes the organizer for a fair per-head split even though
        -- they don't get billed themselves below.
        IF v_payee_count = 0 THEN
            CONTINUE;
        END IF;

        v_per_person := CASE r.cost_type
            WHEN 'per_pax' THEN r.cost_amount
            ELSE CEIL(r.cost_amount / v_payee_count / 1000) * 1000
        END;

        v_billable := ARRAY(SELECT u FROM unnest(v_payees) AS u WHERE u <> r.organizer_id);
        IF COALESCE(array_length(v_billable, 1), 0) = 0 THEN
            -- Organizer was the only confirmed attendee — nobody to bill.
            CONTINUE;
        END IF;

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        VALUES (
            r.lobby_id, r.organizer_id, 'payment_request',
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

        INSERT INTO public.lobby_payment_request_payee (feed_item_id, user_id, amount_owed)
        SELECT v_feed_item_id, u, v_per_person FROM unnest(v_billable) AS u;

        PERFORM public.fn_enqueue_notification(
            'payment_requested',
            v_billable,
            'Chia tiền buổi chơi',
            'Mỗi người đóng ' || v_per_person::text || 'đ',
            jsonb_build_object('lobby_id', r.lobby_id, 'feed_item_id', v_feed_item_id));
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_sweep_activity_payment_requests() FROM PUBLIC, anon, authenticated;

-- Hook into the existing 1-minute tick rather than adding a second cron job.
CREATE OR REPLACE FUNCTION public.fn_cron_tick()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    PERFORM public.fn_sweep_challenges();
    PERFORM public.fn_sweep_activity_payment_requests();
    PERFORM public.fn_process_reminders();
    IF EXISTS (SELECT 1 FROM public.notification_outbox
                WHERE status IN ('pending', 'sending')) THEN
        PERFORM public.fn_invoke_send_push();
    END IF;
END;
$$;


-- ─── Enable the new notification kinds ──────────────────────────────────────
INSERT INTO public.enabled_notification_kind (kind, enabled) VALUES
    ('payment_requested', true),
    ('debt_collected',    true)
ON CONFLICT (kind) DO NOTHING;
