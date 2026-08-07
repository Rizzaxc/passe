-- ============================================================================
-- activity_scoped_feed_items.sql — give lobby_feed_item a real activity_id
-- link so the Planner tab's per-activity ActivityCard can host its own
-- action log (late reports, payment requests) instead of everything landing
-- in the lobby-wide Feed tab.
--
-- `activity_id` is only ever populated for the two write paths that are
-- inherently scoped to one activity: create_ancillary_payment_request /
-- fn_sweep_activity_payment_requests (payment requests), and the client's
-- postPersonalAction when posting a 'late' report. Activity
-- creation/edit/cancel ('update' kind) and the empty-state "remind captain"
-- action deliberately keep activity_id NULL so they keep landing on the
-- general Feed tab. ON DELETE SET NULL mirrors wall_post's "the hook is a
-- label, not integrity" FK pattern — a deleted activity doesn't take its
-- log entries down with it, they just fall back to the general feed.
--
-- Apply with execute_sql / apply_migration.
-- ============================================================================

ALTER TABLE public.lobby_feed_item
    ADD COLUMN IF NOT EXISTS activity_id uuid
        REFERENCES public.activity(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS lobby_feed_item_activity_id_idx
    ON public.lobby_feed_item (activity_id)
    WHERE activity_id IS NOT NULL;

-- ─── "Đến Muộn" gating: one 'late' report per (activity, author) ───────────
-- Backstops the client-side check (a light select-watch on the already-
-- fetched lobby_feed_data list) against a race between two rapid taps.
CREATE UNIQUE INDEX IF NOT EXISTS lobby_feed_item_one_late_per_activity_idx
    ON public.lobby_feed_item (activity_id, author_id)
    WHERE kind = 'personal' AND payload->>'action_kind' = 'late';


-- ─── create_ancillary_payment_request: also set the real activity_id ───────
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


-- ─── fn_sweep_activity_payment_requests: also set the real activity_id ─────
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

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, activity_id, payload)
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


-- ─── lobby_feed_data: surface activity_id ───────────────────────────────────
-- Return-type change requires DROP + CREATE (CREATE OR REPLACE can't add
-- output columns) — same reason schema/lobby_feed_poll_my_vote.sql and
-- schema/lobby_payment_requests.sql did it.
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
    payment_payees jsonb,
    activity_id uuid
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
                   END                                    AS payment_payees,
                   fi.activity_id                          AS activity_id
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
                   NULL::jsonb                             AS payment_payees,
                   NULL::uuid                              AS activity_id
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
