-- ============================================================================
-- challenge_accept_cost_fix.sql — Part G of the friendly-challenge build.
-- Apply AFTER friendly_challenge_sweep.sql.
--
-- Two things:
--   1. A STANDING BUG in the refereed flow, unrelated to friendly mode but
--      fatal to both: respond_challenge's accept branch still inserts
--      prepayment_required / payment_type / prepayment_amount and casts
--      'manual'::activity_payment_type. All three columns and that enum were
--      dropped by schema/activity_cost_rework.sql, so accepting ANY challenge
--      currently raises `column "prepayment_required" does not exist`. The
--      refereed flow has been dead at its second step; nothing downstream of
--      accept (confirm, referee, Elo, history) was reachable.
--   2. The offer-shaped Discover feed for friendly mode.
--
-- NOT done here, deliberately: dropping lobby.challenge_offer_time/_location/
-- _cost and lobby.open_to_challengers. home_challenger_lobby_data still reads
-- them to serve the refereed (flag-gated) feed, and rewriting that function's
-- ranking maths is a change with its own blast radius. They are dead weight for
-- friendly mode, not a hazard — the offer table is the truth for anything
-- friendly. Clean them up when the refereed feed is next touched.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.respond_challenge(p_challenge_id uuid, p_action text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    c_match_minutes constant integer := 90;
    v_uid    uuid := auth.uid();
    v_init   uuid; v_target uuid; v_sport bigint; v_status public.lobby_challenge_status;
    v_time   timestamptz; v_loc uuid; v_cost numeric;
    v_end    timestamptz; v_deadline timestamptz;
    v_init_name text; v_target_name text;
    v_recipients uuid[];
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT initiator_lobby_id, target_lobby_id, sport_id, status,
           proposed_time, proposed_location, agreed_cost
      INTO v_init, v_target, v_sport, v_status, v_time, v_loc, v_cost
      FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;

    IF v_init IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF v_status <> 'requested' THEN RAISE EXCEPTION 'challenge already answered'; END IF;
    IF NOT public.lobby_can_manage(v_target, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the target lobby';
    END IF;

    SELECT name INTO v_init_name   FROM public.lobby WHERE id = v_init;
    SELECT name INTO v_target_name FROM public.lobby WHERE id = v_target;

    IF p_action = 'accept' THEN
        v_end := v_time + make_interval(mins => c_match_minutes);
        -- Normally 2 days out, matching the scheduling sheet's fixed default —
        -- but a challenge accepted for tomorrow must not be born already past
        -- its own deadline, so clamp it to an hour from now.
        v_deadline := GREATEST(v_time - interval '2 days', now() + interval '1 hour');
        IF v_deadline >= v_time THEN
            v_deadline := v_time - interval '1 minute';
        END IF;

        UPDATE public.lobby_challenge
            SET status = 'accepted', updated_at = now() WHERE id = p_challenge_id;

        -- One activity per side, same challenge_id — that link IS the pairing.
        -- THE FIX: cost_type/cost_amount, the columns that actually exist. The
        -- agreed cost is a stated, informational figure settled after the
        -- session (schema/activity_cost_rework.sql), never a charge.
        INSERT INTO public.activity
            (user_id, sport_id, lobby_id, challenge_id, start_time, end_time, location_id,
             cost_type, cost_amount, confirmation_threshold, confirmation_deadline)
        SELECT l.captain_id, v_sport, l.id, p_challenge_id, v_time, v_end, v_loc,
               CASE WHEN COALESCE(v_cost, 0) > 0 THEN 'total'::public.activity_cost_type END,
               CASE WHEN COALESCE(v_cost, 0) > 0 THEN v_cost END,
               GREATEST(2, ceil(l.member_count / 2.0)::integer),
               v_deadline
          FROM public.lobby l
         WHERE l.id IN (v_init, v_target);

        -- The offer is consumed: clear it and drop the target's other pending
        -- challenges, so one lobby can't accept five matches for one evening.
        UPDATE public.lobby
           SET open_to_challengers      = false,
               challenge_offer_time     = NULL,
               challenge_offer_location = NULL,
               challenge_offer_cost     = NULL
         WHERE id = v_target;

        UPDATE public.lobby_challenge
           SET status = 'declined', updated_at = now()
         WHERE target_lobby_id = v_target
           AND status = 'requested'
           AND id <> p_challenge_id;

        SELECT array_agg(user_id) INTO v_recipients
            FROM public.lobby_member WHERE lobby_id = v_init;
        PERFORM public.fn_enqueue_notification(
            'challenger_confirmed', v_recipients,
            'Thách đấu được chấp nhận',
            COALESCE(v_target_name, 'Đối thủ') || ' đã chấp nhận lời thách đấu',
            jsonb_build_object('lobby_id', v_init, 'challenge_id', p_challenge_id));

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        SELECT l.id, l.captain_id, 'update',
               jsonb_build_object(
                   'title', 'Trận thách đấu',
                   'kind',  'scheduled',
                   'tone',  'blue',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Đối thủ',
                           CASE WHEN l.id = v_target THEN COALESCE(v_init_name, '—')
                                ELSE COALESCE(v_target_name, '—') END),
                       jsonb_build_array('Sân', COALESCE(
                           (SELECT loc.name FROM public.location loc WHERE loc.id = v_loc), '—'))
                   ))
          FROM public.lobby l
         WHERE l.id IN (v_init, v_target);

    ELSIF p_action = 'decline' THEN
        UPDATE public.lobby_challenge
            SET status = 'declined', updated_at = now() WHERE id = p_challenge_id;
        SELECT array_agg(uid) INTO v_recipients FROM (
            SELECT captain_id AS uid FROM public.lobby WHERE id = v_init
            UNION
            SELECT user_id FROM public.lobby_member
                WHERE lobby_id = v_init AND role = 'coordinator'
        ) s;
        PERFORM public.fn_enqueue_notification(
            'challenge_declined', v_recipients,
            'Thách đấu bị từ chối',
            COALESCE(v_target_name, 'Đối thủ') || ' đã từ chối lời thách đấu',
            jsonb_build_object('lobby_id', v_init, 'challenge_id', p_challenge_id));
    ELSE
        RAISE EXCEPTION 'invalid action %', p_action;
    END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.respond_challenge(uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- The friendly Discover feed — one row per OFFER, not per lobby
-- ─────────────────────────────────────────────────────────────────────────────
-- Separate from home_challenger_lobby_data rather than a rewrite of it: that
-- function returns one row per lobby, which cannot represent a lobby
-- advertising three different fixtures. Its MMR-window ranking maths is kept
-- here (same c_home_adv constant fn_apply_match_rating uses, so the card's
-- favorability and the rating that follows agree with each other) but the
-- unit of the feed is the fixture, which is what a challenger is choosing.
CREATE OR REPLACE FUNCTION public.friendly_offer_feed_data(
    p_context_lobby_id uuid,
    p_sport_id         bigint,
    p_city             integer DEFAULT NULL,
    p_districts        character varying[] DEFAULT NULL,
    p_search           text DEFAULT NULL,
    p_mmr_window       integer DEFAULT 200,
    p_page_size        integer DEFAULT 20,
    p_page_number      integer DEFAULT 1
) RETURNS TABLE(
    offer_id uuid, slot smallint, lobby_id uuid, lobby_name text,
    lobby_mmr integer, trust_score integer, rated_match_count integer,
    member_count integer, description text, homeground_name text,
    kickoff timestamptz, expires_at timestamptz, location_name text,
    venue_cost numeric, cost_split public.challenge_cost_split,
    bounty_kind public.challenge_bounty_kind, bounty_amount numeric,
    ruleset public.challenge_ruleset, ruleset_param smallint,
    handicap_side public.challenge_handicap_side, handicap_amount smallint,
    terms_note text, favorability text, recommendation_counts jsonb,
    already_challenged boolean)
    LANGUAGE plpgsql STABLE SET search_path TO ''
AS $$
DECLARE
    c_home_adv constant integer := 50;
    v_mmr integer;
BEGIN
    SELECT l.mmr INTO v_mmr FROM public.lobby l WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    RETURN QUERY
    SELECT o.id, o.slot, l.id, l.name::text,
           l.mmr, l.trust_score, l.rated_match_count,
           l.member_count, l.description,
           (SELECT loc2.name FROM public.lobby_homeground hg
              JOIN public.location loc2 ON loc2.id = hg.location_id
             WHERE hg.lobby_id = l.id AND hg.is_primary LIMIT 1),
           o.kickoff, o.expires_at, loc.name::text,
           o.venue_cost, o.cost_split, o.bounty_kind, o.bounty_amount,
           o.ruleset, o.ruleset_param, o.handicap_side, o.handicap_amount,
           o.terms_note,
           -- Stated from the CHALLENGER's point of view, and honouring the same
           -- home advantage the rating engine will apply if this match happens.
           CASE
               WHEN (l.mmr + c_home_adv) - v_mmr >  p_mmr_window THEN 'harder'
               WHEN v_mmr - (l.mmr + c_home_adv) >  p_mmr_window THEN 'easier'
               ELSE 'even'
           END::text,
           public.lobby_recommendation_counts(l.id),
           EXISTS (SELECT 1 FROM public.lobby_challenge c
                    WHERE c.offer_id = o.id
                      AND c.initiator_lobby_id = p_context_lobby_id
                      AND c.status IN ('requested', 'pending_home'))
      FROM public.lobby_challenge_offer o
      JOIN public.lobby l ON l.id = o.lobby_id
      JOIN public.location loc ON loc.id = o.location_id
     WHERE o.status = 'open'
       AND o.mode = 'friendly'
       AND o.expires_at > now()
       AND l.sport_id = p_sport_id
       AND l.visibility <> 'private'
       AND l.id <> COALESCE(p_context_lobby_id, '00000000-0000-0000-0000-000000000000'::uuid)
       AND (p_city IS NULL OR loc.city_cluster = p_city)
       AND (p_districts IS NULL OR array_length(p_districts, 1) IS NULL
            OR loc.district = ANY(p_districts))
       AND (p_search IS NULL OR btrim(p_search) = ''
            OR l.name ILIKE '%' || btrim(p_search) || '%')
     ORDER BY abs((l.mmr + c_home_adv) - v_mmr), o.kickoff
     LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
GRANT EXECUTE ON FUNCTION public.friendly_offer_feed_data(
    uuid, bigint, integer, character varying[], text, integer, integer, integer)
    TO anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- Least privilege on the user-facing RPCs
-- ─────────────────────────────────────────────────────────────────────────────
-- Postgres grants EXECUTE to PUBLIC by default on CREATE FUNCTION, and PUBLIC
-- includes anon. Every RPC below gates on auth.uid() so anon only ever earned
-- a 'not authenticated' exception, but a mutation has no business being
-- reachable by an unauthenticated role. The explicit GRANT ... TO authenticated
-- on each of these still stands.
REVOKE ALL ON FUNCTION public.publish_challenge_offer(
    uuid, smallint, timestamptz, uuid, timestamptz, numeric, text, text, numeric,
    text, smallint, text, smallint, text, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.withdraw_challenge_offer(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.renew_challenge_offer(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.send_friendly_challenge(uuid, uuid, integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.respond_friendly_challenge(uuid, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.claim_no_show(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.counter_no_show(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.report_match_result(uuid, text, jsonb, uuid, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.recommend_lobby(uuid, uuid, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.pending_home_challengers(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.friendly_challenge_data(uuid) FROM PUBLIC, anon;
