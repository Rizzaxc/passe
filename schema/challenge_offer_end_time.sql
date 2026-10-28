-- ============================================================================
-- challenge_offer_end_time.sql — a friendly offer states how long the match
-- runs. Apply AFTER friendly_challenge_offer_activity.sql.
--
-- The offer form asked for a kickoff and nothing else, and every fixture it
-- produced was silently given 90 minutes: home's Planner session on publish,
-- the challenger's on send, the accept fallback, renew, and the chooser's clash
-- check. 90 minutes is a soccer match; it is not a pickleball morning or a
-- three-rubber badminton tie, and members plan their day around the end time.
--
--   * lobby_challenge_offer.end_time — backfilled to kickoff + 90 min, so
--     every existing offer keeps the session it already has;
--   * publish_challenge_offer takes p_end_time as a new LAST argument
--     (DEFAULT NULL -> kickoff + 90 min), so renew's positional call and any
--     client still on the old build keep working;
--   * every place that hard-coded the 90 minutes for a friendly offer now
--     reads it from the offer.
--
-- The refereed flow (respond_challenge, flag-gated) keeps its own 90 minutes;
-- it doesn't use this table.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

ALTER TABLE public.lobby_challenge_offer
    ADD COLUMN IF NOT EXISTS end_time timestamptz;
UPDATE public.lobby_challenge_offer
   SET end_time = kickoff + interval '90 minutes'
 WHERE end_time IS NULL;
ALTER TABLE public.lobby_challenge_offer
    ALTER COLUMN end_time SET NOT NULL;
ALTER TABLE public.lobby_challenge_offer
    DROP CONSTRAINT IF EXISTS lobby_challenge_offer_end_after_kickoff;
ALTER TABLE public.lobby_challenge_offer
    ADD CONSTRAINT lobby_challenge_offer_end_after_kickoff
    CHECK (end_time > kickoff AND end_time <= kickoff + interval '3 hours');

-- A new trailing argument is a new signature: drop the old one so the two
-- can't coexist as ambiguous overloads.
DROP FUNCTION IF EXISTS public.publish_challenge_offer(
    uuid, smallint, timestamptz, uuid, timestamptz, numeric, text, text, numeric,
    text, smallint, text, smallint, text, text);

CREATE OR REPLACE FUNCTION public.publish_challenge_offer(p_lobby_id uuid, p_slot smallint, p_kickoff timestamp with time zone, p_location uuid, p_expires_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_venue_cost numeric DEFAULT NULL::numeric, p_cost_split text DEFAULT 'none'::text, p_bounty_kind text DEFAULT 'none'::text, p_bounty_amount numeric DEFAULT NULL::numeric, p_ruleset text DEFAULT 'standard'::text, p_ruleset_param smallint DEFAULT NULL::smallint, p_handicap_side text DEFAULT 'none'::text, p_handicap_amount smallint DEFAULT NULL::smallint, p_terms_note text DEFAULT NULL::text, p_mode text DEFAULT 'friendly'::text, p_end_time timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid     uuid := auth.uid();
    v_expires timestamptz;
    v_end     timestamptz;
    v_old     uuid;
    v_id      uuid;
    v_act     uuid;
    v_moved   boolean := false;
    v_captain uuid;
    v_sport   bigint;
    v_cost    numeric;
    v_venue   text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF NOT public.lobby_can_manage(p_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;
    IF p_slot IS NULL OR p_slot NOT BETWEEN 1 AND 3 THEN
        RAISE EXCEPTION 'a lobby has three offer slots';
    END IF;
    IF p_kickoff IS NULL OR p_kickoff <= now() THEN
        RAISE EXCEPTION 'the offered kickoff is in the past';
    END IF;
    IF p_location IS NULL THEN
        RAISE EXCEPTION 'an offer needs a venue';
    END IF;

    -- The publisher states how long the match runs. A caller that predates
    -- the field gets the 90 minutes every offer used to be assumed to last.
    v_end := COALESCE(p_end_time, p_kickoff + interval '90 minutes');
    IF v_end <= p_kickoff THEN
        RAISE EXCEPTION 'the match must end after kickoff';
    END IF;
    IF v_end > p_kickoff + interval '3 hours' THEN
        RAISE EXCEPTION 'the match is too long';
    END IF;

    -- Clamped for a short-notice offer: at least an hour of gathering, and
    -- always before kickoff.
    v_expires := COALESCE(p_expires_at,
                          GREATEST(p_kickoff - interval '36 hours',
                                   LEAST(now() + interval '1 hour',
                                         p_kickoff - interval '1 minute')));
    IF v_expires >= p_kickoff THEN
        RAISE EXCEPTION 'the offer must close before kickoff';
    END IF;
    IF v_expires <= now() THEN
        RAISE EXCEPTION 'the offer would close in the past';
    END IF;

    SELECT id INTO v_old FROM public.lobby_challenge_offer
     WHERE lobby_id = p_lobby_id AND slot = p_slot AND status = 'open'
     FOR UPDATE;
    IF v_old IS NOT NULL THEN
        -- Detach the fixture before the old offer is withdrawn, or the retire
        -- trigger would delete the very session this edit is about to move.
        UPDATE public.activity SET challenge_offer_id = NULL
         WHERE challenge_offer_id = v_old AND challenge_id IS NULL
        RETURNING id INTO v_act;
        UPDATE public.lobby_challenge_offer SET status = 'withdrawn' WHERE id = v_old;
        PERFORM public.fn_lapse_offer_challenges(v_old, 'Đội chủ nhà đã thay đổi lời mời');
    END IF;

    INSERT INTO public.lobby_challenge_offer
        (lobby_id, mode, slot, kickoff, end_time, location_id, expires_at, venue_cost,
         cost_split, bounty_kind, bounty_amount, ruleset, ruleset_param,
         handicap_side, handicap_amount, terms_note, created_by)
    VALUES (p_lobby_id, p_mode::public.lobby_challenge_mode, p_slot, p_kickoff,
            v_end, p_location, v_expires, p_venue_cost,
            p_cost_split::public.challenge_cost_split,
            p_bounty_kind::public.challenge_bounty_kind, p_bounty_amount,
            p_ruleset::public.challenge_ruleset, p_ruleset_param,
            p_handicap_side::public.challenge_handicap_side, p_handicap_amount,
            nullif(btrim(coalesce(p_terms_note, '')), ''), v_uid)
    RETURNING id INTO v_id;

    -- The refereed flow (flag-gated) materialises its own activities on accept.
    IF p_mode <> 'friendly' THEN RETURN v_id; END IF;

    -- The fixture on our own Planner: members see it and RSVP from the start,
    -- instead of first hearing about it when a match is locked in.
    SELECT captain_id, sport_id INTO v_captain, v_sport FROM public.lobby WHERE id = p_lobby_id;
    v_cost := public.fn_challenge_side_cost(p_venue_cost,
                                            p_cost_split::public.challenge_cost_split, true);

    IF v_act IS NOT NULL THEN
        -- An edit keeps its card. RSVPs survive only if the when and where did:
        -- a yes to Saturday 8pm at one pitch is not a yes to anything else.
        IF EXISTS (SELECT 1 FROM public.activity
                    WHERE id = v_act
                      AND (start_time <> p_kickoff OR location_id IS DISTINCT FROM p_location)) THEN
            DELETE FROM public.activity_confirmation WHERE activity_id = v_act;
        END IF;
        UPDATE public.activity
           SET challenge_offer_id = v_id,
               start_time = p_kickoff,
               end_time = v_end,
               location_id = p_location,
               cost_type = CASE WHEN v_cost IS NOT NULL THEN 'total'::public.activity_cost_type END,
               cost_amount = v_cost
         WHERE id = v_act;
        v_moved := true;
    ELSE
        INSERT INTO public.activity
            (user_id, sport_id, lobby_id, start_time, end_time, location_id,
             cost_type, cost_amount, challenge_offer_id)
        VALUES (v_captain, v_sport, p_lobby_id, p_kickoff,
                v_end, p_location,
                CASE WHEN v_cost IS NOT NULL THEN 'total'::public.activity_cost_type END,
                v_cost, v_id)
        RETURNING id INTO v_act;
    END IF;

    -- The publisher is the first yes, as schedule() does for a plain session.
    INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
    VALUES (v_act, v_uid, 'going')
    ON CONFLICT DO NOTHING;

    SELECT name INTO v_venue FROM public.location WHERE id = p_location;
    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
    VALUES (p_lobby_id, v_uid, 'update',
            jsonb_build_object(
                'title', CASE WHEN v_moved THEN 'Đã sửa lời mời thách đấu'
                              ELSE 'Đang tìm đối thủ' END,
                'kind',  'challenge_offered',
                'tone',  'amber',
                'activity_id', v_act,
                'fields', jsonb_build_array(
                    jsonb_build_array('Sân', COALESCE(v_venue, '—')),
                    jsonb_build_array('Trạng thái', 'Đang chờ đội khác nhận lời'))));

    RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.publish_challenge_offer(
    uuid, smallint, timestamptz, uuid, timestamptz, numeric, text, text, numeric,
    text, smallint, text, smallint, text, text, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.publish_challenge_offer(
    uuid, smallint, timestamptz, uuid, timestamptz, numeric, text, text, numeric,
    text, smallint, text, smallint, text, text, timestamptz) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.renew_challenge_offer(p_offer_id uuid) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE v_uid uuid := auth.uid(); o record; v_id uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO o FROM public.lobby_challenge_offer WHERE id = p_offer_id;
    IF o.id IS NULL THEN RAISE EXCEPTION 'offer not found'; END IF;
    IF NOT public.lobby_can_manage(o.lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;
    IF o.status = 'open' THEN RAISE EXCEPTION 'that offer is still open'; END IF;
    IF o.status = 'taken' THEN RAISE EXCEPTION 'that offer was already matched'; END IF;
    IF EXISTS (SELECT 1 FROM public.lobby_challenge_offer
                WHERE renewed_from = p_offer_id AND status = 'open') THEN
        RAISE EXCEPTION 'that offer was already renewed';
    END IF;

    v_id := public.publish_challenge_offer(
        o.lobby_id, o.slot, o.kickoff + interval '7 days', o.location_id,
        o.expires_at + interval '7 days', o.venue_cost, o.cost_split::text,
        o.bounty_kind::text, o.bounty_amount, o.ruleset::text, o.ruleset_param,
        o.handicap_side::text, o.handicap_amount, o.terms_note, o.mode::text,
        o.end_time + interval '7 days');

    UPDATE public.lobby_challenge_offer SET renewed_from = p_offer_id WHERE id = v_id;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.send_friendly_challenge(p_initiator_lobby uuid, p_offer_id uuid, p_threshold integer, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid     uuid := auth.uid();
    o         record;
    v_sport   bigint;
    v_members integer;
    v_captain uuid;
    v_name    text;
    v_home    text;
    v_venue   text;
    v_cost    numeric;
    v_id      uuid;
    v_act     uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF NOT public.lobby_can_manage(p_initiator_lobby, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;

    SELECT * INTO o FROM public.lobby_challenge_offer WHERE id = p_offer_id FOR UPDATE;
    IF o.id IS NULL OR o.status <> 'open' THEN
        RAISE EXCEPTION 'that offer is no longer open';
    END IF;
    IF o.expires_at <= now() THEN
        RAISE EXCEPTION 'that offer has closed';
    END IF;
    IF o.mode <> 'friendly' THEN
        RAISE EXCEPTION 'that offer is not a friendly challenge';
    END IF;
    IF o.lobby_id = p_initiator_lobby THEN
        RAISE EXCEPTION 'a lobby cannot challenge itself';
    END IF;
    -- One person on both sides could send, accept, and file the only report.
    IF public.fn_lobbies_share_manager(p_initiator_lobby, o.lobby_id) THEN
        RAISE EXCEPTION 'the two lobbies share a manager';
    END IF;

    SELECT sport_id, captain_id, member_count, name
      INTO v_sport, v_captain, v_members, v_name
      FROM public.lobby WHERE id = p_initiator_lobby;
    IF v_sport IS DISTINCT FROM (SELECT sport_id FROM public.lobby WHERE id = o.lobby_id) THEN
        RAISE EXCEPTION 'the two lobbies play different sports';
    END IF;

    IF p_threshold IS NULL OR p_threshold < 1 THEN
        RAISE EXCEPTION 'the confirmation threshold must be at least 1';
    END IF;
    IF p_threshold > GREATEST(v_members, 1) THEN
        RAISE EXCEPTION 'the threshold is larger than the lobby';
    END IF;

    IF EXISTS (SELECT 1 FROM public.lobby_challenge
                WHERE initiator_lobby_id = p_initiator_lobby AND offer_id = p_offer_id
                  AND status IN ('requested', 'pending_home')) THEN
        RAISE EXCEPTION 'you already have an open challenge on this offer';
    END IF;

    INSERT INTO public.lobby_challenge
        (initiator_lobby_id, target_lobby_id, sport_id, status, mode, offer_id,
         proposed_time, proposed_location, agreed_cost, note,
         venue_cost, cost_split, bounty_kind, bounty_amount,
         ruleset, ruleset_param, handicap_side, handicap_amount, terms_note)
    VALUES (p_initiator_lobby, o.lobby_id, v_sport, 'requested', 'friendly', p_offer_id,
            o.kickoff, o.location_id, o.venue_cost,
            nullif(btrim(coalesce(p_note, '')), ''),
            o.venue_cost, o.cost_split, o.bounty_kind, o.bounty_amount,
            o.ruleset, o.ruleset_param, o.handicap_side, o.handicap_amount, o.terms_note)
    RETURNING id INTO v_id;

    -- Our share of the pitch, not the whole bill.
    v_cost := public.fn_challenge_side_cost(o.venue_cost, o.cost_split, false);

    INSERT INTO public.activity
        (user_id, sport_id, lobby_id, challenge_id, start_time, end_time,
         location_id, cost_type, cost_amount,
         confirmation_threshold, confirmation_deadline)
    VALUES (v_captain, v_sport, p_initiator_lobby, v_id,
            o.kickoff, o.end_time,
            o.location_id,
            CASE WHEN v_cost IS NOT NULL THEN 'total'::public.activity_cost_type END,
            v_cost,
            p_threshold, o.expires_at)
    RETURNING id INTO v_act;

    SELECT name INTO v_home FROM public.lobby WHERE id = o.lobby_id;
    SELECT name INTO v_venue FROM public.location WHERE id = o.location_id;

    -- Everyone else on the roster: the handshake waits on THEIR RSVPs, so they
    -- are the people who most need to know it exists. activity_scheduled's
    -- routing already lands on the Planner card by activity id.
    PERFORM public.fn_enqueue_notification(
        'activity_scheduled',
        ARRAY(SELECT user_id FROM public.lobby_member
               WHERE lobby_id = p_initiator_lobby AND user_id <> v_uid),
        COALESCE(v_name, 'Đội bạn') || ' thách đấu ' || COALESCE(v_home, 'một đội'),
        'Cần ' || p_threshold || ' người xác nhận trước '
            || public.fn_vn_time_label(o.expires_at) || ' — vào xác nhận nhé',
        jsonb_build_object('lobby_id', p_initiator_lobby, 'activity_id', v_act,
                           'challenge_id', v_id));

    -- The durable copy of that push, for whoever dismissed it.
    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
    VALUES (p_initiator_lobby, v_uid, 'update',
            jsonb_build_object(
                'title', 'Đang gom quân thách đấu',
                'kind',  'challenge_gathering',
                'tone',  'amber',
                'fields', jsonb_build_array(
                    jsonb_build_array('Đối thủ', COALESCE(v_home, '—')),
                    jsonb_build_array('Sân', COALESCE(v_venue, '—')),
                    jsonb_build_array('Cần xác nhận', p_threshold::text || ' người'))));

    -- The sender is the first yes. Last, because it can complete a threshold
    -- of 1 — and the quorum trigger it fires expects the rows above to exist.
    INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
    VALUES (v_act, v_uid, 'going')
    ON CONFLICT DO NOTHING;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.respond_friendly_challenge(p_challenge_id uuid, p_action text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_uid  uuid := auth.uid();
    c      record;
    v_home_captain uuid;
    v_init_name text;
    v_home_name text;
    v_cost numeric;
    v_act  uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF c.mode <> 'friendly' THEN RAISE EXCEPTION 'not a friendly challenge'; END IF;
    IF c.status <> 'pending_home' THEN
        RAISE EXCEPTION 'this challenge is not waiting on you';
    END IF;
    IF NOT public.lobby_can_manage(c.target_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the home lobby';
    END IF;
    -- The sweep lapses it within the minute; this closes the gap before then.
    IF c.home_decide_by IS NOT NULL AND now() > c.home_decide_by THEN
        RAISE EXCEPTION 'the decision window has closed';
    END IF;

    SELECT name INTO v_init_name FROM public.lobby WHERE id = c.initiator_lobby_id;
    SELECT name, captain_id INTO v_home_name, v_home_captain
      FROM public.lobby WHERE id = c.target_lobby_id;

    IF p_action = 'accept' THEN
        -- A manager may have joined the other side since the challenge was sent.
        IF public.fn_lobbies_share_manager(c.initiator_lobby_id, c.target_lobby_id) THEN
            RAISE EXCEPTION 'the two lobbies share a manager';
        END IF;

        UPDATE public.lobby_challenge
           SET status = 'scheduled', updated_at = now() WHERE id = p_challenge_id;

        -- Home's fixture has been on its Planner since the offer was posted,
        -- RSVPs and all; accepting turns it into the match. Offers published
        -- before that existed get one created here, as before.
        UPDATE public.activity SET challenge_id = p_challenge_id
         WHERE challenge_offer_id = c.offer_id AND challenge_id IS NULL
        RETURNING id INTO v_act;

        IF v_act IS NULL THEN
            v_cost := public.fn_challenge_side_cost(c.venue_cost, c.cost_split, true);
            INSERT INTO public.activity
                (user_id, sport_id, lobby_id, challenge_id, start_time, end_time,
                 location_id, cost_type, cost_amount)
            VALUES (v_home_captain, c.sport_id, c.target_lobby_id, p_challenge_id,
                    c.proposed_time, COALESCE((SELECT o.end_time FROM public.lobby_challenge_offer o
                               WHERE o.id = c.offer_id),
                             c.proposed_time + interval '90 minutes'),
                    c.proposed_location,
                    CASE WHEN v_cost IS NOT NULL THEN 'total'::public.activity_cost_type END,
                    v_cost)
            RETURNING id INTO v_act;
        END IF;

        -- Rating moves only for `going` RSVPs. Whoever said yes is coming.
        INSERT INTO public.activity_confirmation (activity_id, user_id, attendance)
        VALUES (v_act, v_uid, 'going')
        ON CONFLICT DO NOTHING;

        UPDATE public.lobby_challenge_offer
           SET status = 'taken' WHERE id = c.offer_id;

        PERFORM public.fn_lapse_offer_challenges(c.offer_id,
            COALESCE(v_home_name, 'Đội chủ nhà') || ' đã nhận lời thách đấu của đội khác');

        PERFORM public.fn_enqueue_notification(
            'challenger_confirmed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = c.initiator_lobby_id),
            'Thách đấu được chấp nhận',
            COALESCE(v_home_name, 'Đối thủ') || ' đã nhận lời — giữ xác nhận tham gia để được tính MMR',
            jsonb_build_object('lobby_id', c.initiator_lobby_id, 'challenge_id', p_challenge_id));
        PERFORM public.fn_enqueue_notification(
            'challenge_scheduled',
            ARRAY(SELECT user_id FROM public.lobby_member
                   WHERE lobby_id = c.target_lobby_id AND user_id <> v_uid),
            'Trận đấu đã chốt',
            'Gặp ' || COALESCE(v_init_name, 'đối thủ') || ' lúc '
                || public.fn_vn_time_label(c.proposed_time)
                || ' — xác nhận tham gia để được tính MMR',
            jsonb_build_object('lobby_id', c.target_lobby_id, 'challenge_id', p_challenge_id));

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        SELECT l.id, l.captain_id, 'update',
               jsonb_build_object(
                   'title', 'Trận giao hữu',
                   'kind',  'scheduled',
                   'tone',  'blue',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Đối thủ',
                           CASE WHEN l.id = c.target_lobby_id THEN COALESCE(v_init_name, '—')
                                ELSE COALESCE(v_home_name, '—') END),
                       jsonb_build_array('Sân', COALESCE(
                           (SELECT loc.name FROM public.location loc
                             WHERE loc.id = c.proposed_location), '—'))))
          FROM public.lobby l
         WHERE l.id IN (c.initiator_lobby_id, c.target_lobby_id);

    ELSIF p_action = 'decline' THEN
        UPDATE public.lobby_challenge
           SET status = 'declined', updated_at = now() WHERE id = p_challenge_id;

        PERFORM public.fn_enqueue_notification(
            'challenge_declined',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = c.initiator_lobby_id),
            'Thách đấu bị từ chối',
            COALESCE(v_home_name, 'Đối thủ') || ' đã từ chối lời thách đấu',
            jsonb_build_object('lobby_id', c.initiator_lobby_id, 'challenge_id', p_challenge_id));
    ELSE
        RAISE EXCEPTION 'invalid action %', p_action;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.pending_home_challengers(p_lobby_id uuid) RETURNS TABLE(challenge_id uuid, offer_id uuid, offer_slot smallint, initiator_lobby_id uuid, initiator_name text, initiator_mmr integer, trust_score integer, rated_match_count integer, member_count integer, going_count integer, confirmation_threshold integer, kickoff timestamp with time zone, location_name text, note text, created_at timestamp with time zone, description text, homeground_name text, recommendation_counts jsonb, home_decide_by timestamp with time zone, has_clash boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    SELECT c.id, c.offer_id, o.slot,
           c.initiator_lobby_id, l.name, l.mmr,
           l.trust_score, l.rated_match_count, l.member_count,
           (SELECT count(*)::integer FROM public.activity_confirmation ac
             JOIN public.activity a ON a.id = ac.activity_id
            WHERE a.challenge_id = c.id AND a.lobby_id = c.initiator_lobby_id
              AND ac.attendance = 'going'),
           (SELECT a.confirmation_threshold FROM public.activity a
             WHERE a.challenge_id = c.id AND a.lobby_id = c.initiator_lobby_id),
           c.proposed_time,
           (SELECT loc.name FROM public.location loc WHERE loc.id = c.proposed_location),
           c.note, c.created_at, l.description,
           (SELECT loc2.name FROM public.lobby_homeground hg
              JOIN public.location loc2 ON loc2.id = hg.location_id
             WHERE hg.lobby_id = l.id AND hg.is_primary LIMIT 1),
           public.lobby_recommendation_counts(l.id),
           c.home_decide_by,
           -- Another live session of ours overlapping this fixture.
           -- A warning only; three offer slots make overlap easy to miss.
           EXISTS (
               SELECT 1 FROM public.activity a2
                LEFT JOIN public.lobby_challenge c2 ON c2.id = a2.challenge_id
                WHERE a2.lobby_id = p_lobby_id
                  AND a2.challenge_offer_id IS DISTINCT FROM c.offer_id
                  AND (c2.id IS NULL
                       OR c2.status NOT IN ('declined', 'lapsed', 'cancelled'))
                  AND a2.start_time < COALESCE(o.end_time, c.proposed_time + interval '90 minutes')
                  AND COALESCE(a2.end_time, a2.start_time + interval '90 minutes')
                      > c.proposed_time)
      FROM public.lobby_challenge c
      JOIN public.lobby l ON l.id = c.initiator_lobby_id
      LEFT JOIN public.lobby_challenge_offer o ON o.id = c.offer_id
     WHERE c.target_lobby_id = p_lobby_id
       AND c.mode = 'friendly'
       AND c.status = 'pending_home'
       AND public.lobby_can_manage(p_lobby_id, auth.uid())
     ORDER BY c.proposed_time, c.created_at;
$$;
