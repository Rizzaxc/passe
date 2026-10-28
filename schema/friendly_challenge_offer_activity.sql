-- ============================================================================
-- friendly_challenge_offer_activity.sql — Part I of the friendly-challenge
-- build. Apply AFTER friendly_challenge_followups.sql.
--
-- Posting a challenge offer used to tell the lobby nothing: no feed item, no
-- session, no push. Members first heard of the fixture when a manager accepted
-- an opponent, and the only place the offers lived was two rows deep in the
-- lobby info sheet. Now publishing an offer:
--
--   * creates home's activity right away, linked by activity.challenge_offer_id
--     — it shows on the Planner (and every member's calendar) and members
--     RSVP to it like any session, starting with the publisher;
--   * posts a `challenge_offered` feed item;
--   * sends NO push. Nothing is confirmed yet; the feed and the Planner are
--     enough until a match is locked in (challenge_scheduled still pushes).
--
-- Accepting a challenger turns that same activity into the match (sets its
-- challenge_id) instead of creating a new one, so the RSVPs carry over.
-- Re-publishing a slot moves the activity to the new offer, clearing RSVPs
-- only when the time or venue changed. When an offer can no longer produce a
-- match — withdrawn, or expired with nobody left waiting — its activity is
-- deleted by trigger, so every lapse path (withdraw, expiry sweep, home's
-- cutoff, decline, a challenger withdrawing) is covered without each one
-- having to remember.
--
-- While an offer is unmatched its activity is NOT "confirmed"
-- (activity_is_confirmed), so a `going` member can still back out — the RSVP
-- lock exists for sessions that are actually on.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. The link
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.activity
    ADD COLUMN IF NOT EXISTS challenge_offer_id uuid
        REFERENCES public.lobby_challenge_offer(id) ON DELETE SET NULL;
CREATE UNIQUE INDEX IF NOT EXISTS activity_challenge_offer_idx
    ON public.activity (challenge_offer_id) WHERE challenge_offer_id IS NOT NULL;
COMMENT ON COLUMN public.activity.challenge_offer_id IS
'Home''s fixture for a friendly challenge offer, created on publish so members '
'can see and RSVP to it. challenge_id is set on the same row when an opponent '
'is accepted; until then the activity is an open offer.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. An open offer is not a confirmed session
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.activity_is_confirmed(p_activity_id uuid) RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_threshold int;
    v_override  timestamptz;
    v_offer     uuid;
    v_challenge uuid;
    v_count     int;
BEGIN
    SELECT a.confirmation_threshold, a.threshold_override_at, a.challenge_offer_id, a.challenge_id
        INTO v_threshold, v_override, v_offer, v_challenge
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN RETURN false; END IF;
    -- No opponent yet: nothing to lock anyone into.
    IF v_offer IS NOT NULL AND v_challenge IS NULL THEN RETURN false; END IF;
    IF v_override IS NOT NULL THEN RETURN true; END IF;
    IF v_threshold IS NULL THEN RETURN true; END IF;

    SELECT COUNT(*) INTO v_count
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND attendance = 'going';

    RETURN v_count >= v_threshold;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. No push on publish
-- ─────────────────────────────────────────────────────────────────────────────
-- Same body as activity_scheduled_notify.sql plus the offer guard.
CREATE OR REPLACE FUNCTION public.fn_emit_activity_scheduled() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_recipients     uuid[];
    v_lobby_name     text;
    v_location_name  text;
begin
    if new.lobby_id is null or new.challenge_id is not null
       or new.challenge_offer_id is not null then
        return new;
    end if;

    select array_agg(lm.user_id) into v_recipients
        from public.lobby_member lm
        where lm.lobby_id = new.lobby_id and lm.user_id <> new.user_id;

    if v_recipients is null or array_length(v_recipients, 1) = 0 then
        return new;
    end if;

    select l.name into v_lobby_name from public.lobby l where l.id = new.lobby_id;
    select loc.name into v_location_name from public.location loc where loc.id = new.location_id;

    perform public.fn_enqueue_notification(
        'activity_scheduled',
        v_recipients,
        coalesce(v_lobby_name, 'Lobby') || ' vừa lên lịch buổi chơi mới',
        'Lúc ' || to_char(new.start_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI DD/MM')
            || coalesce(' tại ' || v_location_name, '') || ' — xác nhận tham gia nhé',
        jsonb_build_object('lobby_id', new.lobby_id, 'activity_id', new.id)
    );

    return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Retiring an offer's fixture
-- ─────────────────────────────────────────────────────────────────────────────
-- Deletes the open-offer activity once its offer can no longer produce a match.
-- Called by trigger on every status change that could make that true; it is a
-- no-op while the offer is open or taken, or while any challenger is still
-- gathering players or waiting on home.
CREATE OR REPLACE FUNCTION public.fn_retire_offer_activity(p_offer_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE o record; v_act uuid;
BEGIN
    SELECT id, lobby_id, status INTO o FROM public.lobby_challenge_offer WHERE id = p_offer_id;
    IF o.id IS NULL OR o.status IN ('open', 'taken') THEN RETURN; END IF;
    IF EXISTS (SELECT 1 FROM public.lobby_challenge
                WHERE offer_id = p_offer_id AND status IN ('requested', 'pending_home')) THEN
        RETURN;
    END IF;

    DELETE FROM public.activity
     WHERE challenge_offer_id = p_offer_id AND challenge_id IS NULL
    RETURNING id INTO v_act;
    IF v_act IS NULL THEN RETURN; END IF;

    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
    SELECT l.id, l.captain_id, 'update',
           jsonb_build_object(
               'title', 'Huỷ trận thách đấu',
               'kind',  'cancelled',
               'tone',  'crimson',
               'fields', jsonb_build_array(
                   jsonb_build_array('Lý do', CASE o.status
                       WHEN 'withdrawn' THEN 'Đã gỡ lời mời thách đấu'
                       ELSE 'Không chốt được đối thủ' END)))
      FROM public.lobby l WHERE l.id = o.lobby_id;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_retire_offer_activity(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.trg_offer_status_retire() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    PERFORM public.fn_retire_offer_activity(NEW.id);
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.trg_offer_status_retire() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS lobby_challenge_offer_retire_activity ON public.lobby_challenge_offer;
CREATE TRIGGER lobby_challenge_offer_retire_activity
    AFTER UPDATE OF status ON public.lobby_challenge_offer
    FOR EACH ROW WHEN (NEW.status IN ('withdrawn', 'expired'))
    EXECUTE FUNCTION public.trg_offer_status_retire();

CREATE OR REPLACE FUNCTION public.trg_challenge_status_retire() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    PERFORM public.fn_retire_offer_activity(NEW.offer_id);
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.trg_challenge_status_retire() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS lobby_challenge_retire_offer_activity ON public.lobby_challenge;
CREATE TRIGGER lobby_challenge_retire_offer_activity
    AFTER UPDATE OF status ON public.lobby_challenge
    FOR EACH ROW WHEN (NEW.offer_id IS NOT NULL
                       AND OLD.status IN ('requested', 'pending_home')
                       AND NEW.status IN ('declined', 'lapsed', 'cancelled'))
    EXECUTE FUNCTION public.trg_challenge_status_retire();

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. No seats sold into a fixture
-- ─────────────────────────────────────────────────────────────────────────────
-- The client already hides the freeplay block on a challenge card; this makes
-- it a rule. A team-vs-team match — or an offer for one — has no spare seats.
CREATE OR REPLACE FUNCTION public.fn_freeplay_not_on_fixture() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.activity a
                WHERE a.id = NEW.activity_id
                  AND (a.challenge_id IS NOT NULL OR a.challenge_offer_id IS NOT NULL)) THEN
        RAISE EXCEPTION 'a challenge fixture cannot be listed for freeplay';
    END IF;
    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_freeplay_not_on_fixture() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS freeplay_activity_not_on_fixture ON public.freeplay_activity;
CREATE TRIGGER freeplay_activity_not_on_fixture
    BEFORE INSERT ON public.freeplay_activity
    FOR EACH ROW EXECUTE FUNCTION public.fn_freeplay_not_on_fixture();

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Publish creates the fixture; accept links it
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.publish_challenge_offer(
    p_lobby_id        uuid,
    p_slot            smallint,
    p_kickoff         timestamptz,
    p_location        uuid,
    p_expires_at      timestamptz DEFAULT NULL,
    p_venue_cost      numeric     DEFAULT NULL,
    p_cost_split      text        DEFAULT 'none',
    p_bounty_kind     text        DEFAULT 'none',
    p_bounty_amount   numeric     DEFAULT NULL,
    p_ruleset         text        DEFAULT 'standard',
    p_ruleset_param   smallint    DEFAULT NULL,
    p_handicap_side   text        DEFAULT 'none',
    p_handicap_amount smallint    DEFAULT NULL,
    p_terms_note      text        DEFAULT NULL,
    p_mode            text        DEFAULT 'friendly'
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid     uuid := auth.uid();
    v_expires timestamptz;
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
        (lobby_id, mode, slot, kickoff, location_id, expires_at, venue_cost,
         cost_split, bounty_kind, bounty_amount, ruleset, ruleset_param,
         handicap_side, handicap_amount, terms_note, created_by)
    VALUES (p_lobby_id, p_mode::public.lobby_challenge_mode, p_slot, p_kickoff,
            p_location, v_expires, p_venue_cost,
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
               end_time = p_kickoff + interval '90 minutes',
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
                p_kickoff + interval '90 minutes', p_location,
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

CREATE OR REPLACE FUNCTION public.respond_friendly_challenge(
    p_challenge_id uuid,
    p_action       text
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    c_match_minutes constant integer := 90;
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
                    c.proposed_time, c.proposed_time + make_interval(mins => c_match_minutes),
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

-- The fixture's own card is not a clash with itself.
CREATE OR REPLACE FUNCTION public.pending_home_challengers(p_lobby_id uuid)
RETURNS TABLE(
    challenge_id uuid, offer_id uuid, offer_slot smallint,
    initiator_lobby_id uuid, initiator_name text, initiator_mmr integer,
    trust_score integer, rated_match_count integer, member_count integer,
    going_count integer, confirmation_threshold integer,
    kickoff timestamptz, location_name text, note text,
    created_at timestamptz, description text, homeground_name text,
    recommendation_counts jsonb,
    home_decide_by timestamptz, has_clash boolean)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
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
           -- Another live session of ours overlapping this 90-minute fixture.
           -- A warning only; three offer slots make overlap easy to miss.
           EXISTS (
               SELECT 1 FROM public.activity a2
                LEFT JOIN public.lobby_challenge c2 ON c2.id = a2.challenge_id
                WHERE a2.lobby_id = p_lobby_id
                  AND a2.challenge_offer_id IS DISTINCT FROM c.offer_id
                  AND (c2.id IS NULL
                       OR c2.status NOT IN ('declined', 'lapsed', 'cancelled'))
                  AND a2.start_time < c.proposed_time + interval '90 minutes'
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Backfill
-- ─────────────────────────────────────────────────────────────────────────────
-- Open offers published before this file get their fixture now (no RSVP, no
-- feed item — nobody is publishing them at this moment).
INSERT INTO public.activity
    (user_id, sport_id, lobby_id, start_time, end_time, location_id,
     cost_type, cost_amount, challenge_offer_id)
SELECT l.captain_id, l.sport_id, o.lobby_id, o.kickoff, o.kickoff + interval '90 minutes',
       o.location_id,
       CASE WHEN public.fn_challenge_side_cost(o.venue_cost, o.cost_split, true) IS NOT NULL
            THEN 'total'::public.activity_cost_type END,
       public.fn_challenge_side_cost(o.venue_cost, o.cost_split, true),
       o.id
  FROM public.lobby_challenge_offer o
  JOIN public.lobby l ON l.id = o.lobby_id
 WHERE o.status = 'open' AND o.kickoff > now()
   AND NOT EXISTS (SELECT 1 FROM public.activity a WHERE a.challenge_offer_id = o.id);
