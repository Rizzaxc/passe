-- ============================================================================
-- friendly_challenge_followups.sql — Part H of the friendly-challenge build.
-- Apply AFTER challenge_accept_cost_fix.sql (and, independently,
-- friendly_challenge_dead_fixture_fix.sql).
--
-- What a review of the shipped flow found at its hand-off points, fixed in one
-- file because every item redefines the same handful of RPCs:
--
--   1. Gathering players. Sending a challenge commits the challenger's own
--      members, but nobody told them: no push (fn_emit_activity_scheduled skips
--      challenge activities), no feed item, and not even the sender's own RSVP.
--      The handshake could only reach home if members happened to open the
--      Planner. Now the sender is RSVP'd `going`, the rest get an
--      `activity_scheduled` push, and the feed says what's being asked of them.
--
--   2. Home's decision window. The offer's expires_at closed BOTH phases, so a
--      challenger that reached quorum an hour before expiry was lapsed an hour
--      later with "chưa có đội nào nhận lời" sent to home — false, they had a
--      team waiting. Now expires_at closes only the gathering phase
--      (`requested`), its default moves to kickoff − 36h, and home answers by
--      `lobby_challenge.home_decide_by` (kickoff − 24h; see fn_home_decide_by),
--      with a reminder an hour before.
--
--   3. Both sides rated. Elo moves only for `going` RSVPs, and home's fixture
--      is created at accept with nobody RSVP'd and a push that never asked. The
--      accepting manager is now RSVP'd and both pushes ask for the RSVP.
--
--   4. Self-play. A person managing both lobbies could send, accept, and file
--      the only report (report_match_result resolves them to home), which the
--      24h sweep then rated. Lobbies sharing any manager (captain or
--      coordinator) can no longer meet.
--
--   5. No-show claims settle at the reporting deadline, not 10 minutes after
--      the claim. The 10-minute window landed mid-match on the managers of the
--      team that WAS playing. The claim now files the claimant's report; the
--      accused has the ordinary 24h to answer — counter (dispute), concede
--      (`concede_no_show`, settles at once), or report — and silence settles it
--      as a forfeit through the same sweep pass as any one-sided report.
--
--   6. Per-side cost. Both activities carried the full venue cost whatever the
--      split said, so a `home_pays` fixture told the away side it owed the
--      pitch. Each side's activity now carries its own share (or nothing).
--
--   7. Clash warning. pending_home_challengers flags a fixture that overlaps
--      another live session of the home lobby (three slots make that easy).
--
--   8. Append-only offer amendments: `amend_challenge_offer` adds to the note
--      without re-publishing, so a clarification no longer lapses everyone who
--      already committed. Structural terms still go through publish.
--
-- Notification kinds are all reused (activity_scheduled, challenge_ready_for_
-- home, challenge_lapsed), so there is no enum prelude.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 0. Columns
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.lobby_challenge
    -- When home must have answered a `pending_home` challenge. Set once, by the
    -- quorum trigger, so a slow member flipping back and forth cannot move it.
    ADD COLUMN IF NOT EXISTS home_decide_by   timestamptz,
    -- When the challenger reached quorum. Only used to decide whether the
    -- one-hour reminder is worth sending (it isn't if quorum was minutes ago).
    ADD COLUMN IF NOT EXISTS ready_at         timestamptz,
    ADD COLUMN IF NOT EXISTS home_reminded_at timestamptz;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- Manage tier = captain or coordinator, the same set lobby_can_manage admits.
CREATE OR REPLACE FUNCTION public.fn_lobbies_share_manager(p_a uuid, p_b uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
    WITH ma AS (
        SELECT captain_id AS uid FROM public.lobby WHERE id = p_a
        UNION
        SELECT user_id FROM public.lobby_member
         WHERE lobby_id = p_a AND role = 'coordinator'
    ), mb AS (
        SELECT captain_id AS uid FROM public.lobby WHERE id = p_b
        UNION
        SELECT user_id FROM public.lobby_member
         WHERE lobby_id = p_b AND role = 'coordinator'
    )
    SELECT EXISTS (SELECT 1 FROM ma JOIN mb USING (uid));
$$;
REVOKE ALL ON FUNCTION public.fn_lobbies_share_manager(uuid, uuid)
    FROM PUBLIC, anon, authenticated;

-- One side's share of the pitch, for its own activity row. NULL when that
-- side owes nothing up front — including `loser_pays`, which nobody can know
-- before the result; the challenge block states that split in words instead.
CREATE OR REPLACE FUNCTION public.fn_challenge_side_cost(
    p_venue_cost numeric, p_split public.challenge_cost_split, p_is_home boolean)
RETURNS numeric LANGUAGE sql IMMUTABLE SET search_path TO '' AS $$
    SELECT NULLIF(CASE p_split
        WHEN 'split_even' THEN round(COALESCE(p_venue_cost, 0) / 2, 2)
        WHEN 'home_pays'  THEN CASE WHEN p_is_home     THEN COALESCE(p_venue_cost, 0) ELSE 0 END
        WHEN 'away_pays'  THEN CASE WHEN NOT p_is_home THEN COALESCE(p_venue_cost, 0) ELSE 0 END
        ELSE 0
    END, 0);
$$;

-- Home answers by kickoff − 24h, but never in under an hour from quorum, and
-- never later than kickoff − 2h (the losing challengers still need the evening
-- to find someone else). A quorum landing inside that last stretch — only
-- possible on a short-notice offer — gets half an hour, capped at kickoff.
CREATE OR REPLACE FUNCTION public.fn_home_decide_by(p_kickoff timestamptz)
RETURNS timestamptz LANGUAGE plpgsql STABLE SET search_path TO '' AS $$
DECLARE v timestamptz;
BEGIN
    v := LEAST(GREATEST(p_kickoff - interval '24 hours', now() + interval '1 hour'),
               p_kickoff - interval '2 hours');
    IF v <= now() THEN
        v := LEAST(now() + interval '30 minutes', p_kickoff);
    END IF;
    RETURN v;
END;
$$;

-- "HH:MI DD/MM" in Vietnam time, for push copy. Feed fields stay timestamp-free
-- (see fn_friendly_challenge_quorum); a push body is read once, right away.
CREATE OR REPLACE FUNCTION public.fn_vn_time_label(p_at timestamptz)
RETURNS text LANGUAGE sql IMMUTABLE SET search_path TO '' AS $$
    SELECT to_char(p_at AT TIME ZONE 'Asia/Ho_Chi_Minh', 'HH24:MI DD/MM');
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Lapsing an offer's challengers — optionally only those still gathering
-- ─────────────────────────────────────────────────────────────────────────────
-- Withdrawing, replacing or accepting an offer ends every outstanding
-- challenge on it. Expiry no longer does: a `pending_home` challenger already
-- did its part and waits on home_decide_by instead.
DROP FUNCTION IF EXISTS public.fn_lapse_offer_challenges(uuid, text);
CREATE OR REPLACE FUNCTION public.fn_lapse_offer_challenges(
    p_offer_id uuid, p_reason text, p_requested_only boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT id, initiator_lobby_id FROM public.lobby_challenge
         WHERE offer_id = p_offer_id
           AND status IN ('requested', 'pending_home')
           AND (NOT p_requested_only OR status = 'requested')
    LOOP
        UPDATE public.lobby_challenge
           SET status = 'lapsed', updated_at = now() WHERE id = r.id;
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.initiator_lobby_id),
            'Thách đấu không thành',
            p_reason,
            jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
    END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_lapse_offer_challenges(uuid, text, boolean)
    FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Publishing — the gathering phase now closes at kickoff − 36h by default
-- ─────────────────────────────────────────────────────────────────────────────
-- Same body as friendly_challenge.sql except the default expiry: 36h leaves the
-- 12 hours between gathering closing and home's own kickoff − 24h deadline.
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

    RETURN v_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Append-only amendments
-- ─────────────────────────────────────────────────────────────────────────────
-- Adds a line to the offer's note without re-publishing it. Challengers already
-- on the offer keep the terms they snapshotted — an amendment is information
-- for whoever looks next, never a way to change what someone already agreed
-- to. Not allowed on `custom` rulesets, where the note IS the format.
CREATE OR REPLACE FUNCTION public.amend_challenge_offer(p_offer_id uuid, p_append text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    c_max_append constant integer := 140;
    v_uid  uuid := auth.uid();
    o      record;
    v_add  text := btrim(coalesce(p_append, ''));
    v_note text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO o FROM public.lobby_challenge_offer
     WHERE id = p_offer_id AND status = 'open' FOR UPDATE;
    IF o.id IS NULL THEN RAISE EXCEPTION 'no open offer'; END IF;
    IF NOT public.lobby_can_manage(o.lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;
    IF o.ruleset = 'custom' THEN
        RAISE EXCEPTION 'a custom ruleset cannot be amended';
    END IF;
    IF v_add = '' THEN RAISE EXCEPTION 'nothing to add'; END IF;
    IF char_length(v_add) > c_max_append THEN
        RAISE EXCEPTION 'the amendment is too long';
    END IF;

    v_note := CASE WHEN btrim(coalesce(o.terms_note, '')) = '' THEN v_add
                   ELSE o.terms_note || E'\n' || v_add END;
    -- lobby_challenge_offer_note_length caps the whole note at 280.
    IF char_length(v_note) > 280 THEN
        RAISE EXCEPTION 'the note is full';
    END IF;

    UPDATE public.lobby_challenge_offer SET terms_note = v_note WHERE id = p_offer_id;
END;
$$;
REVOKE ALL ON FUNCTION public.amend_challenge_offer(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.amend_challenge_offer(uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Sending — and actually asking your own people
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.send_friendly_challenge(
    p_initiator_lobby uuid,
    p_offer_id        uuid,
    p_threshold       integer,
    p_note            text DEFAULT NULL
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    c_match_minutes constant integer := 90;
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
            o.kickoff, o.kickoff + make_interval(mins => c_match_minutes),
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Quorum stamps home's deadline
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_friendly_challenge_quorum()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    a record; c record; v_going integer; v_name text; v_by timestamptz;
BEGIN
    SELECT id, challenge_id, lobby_id, confirmation_threshold
      INTO a FROM public.activity WHERE id = NEW.activity_id;
    IF a.challenge_id IS NULL OR a.confirmation_threshold IS NULL THEN RETURN NEW; END IF;

    SELECT * INTO c FROM public.lobby_challenge WHERE id = a.challenge_id;
    IF c.mode <> 'friendly' OR c.status <> 'requested' THEN RETURN NEW; END IF;
    IF c.initiator_lobby_id <> a.lobby_id THEN RETURN NEW; END IF;

    SELECT count(*) INTO v_going FROM public.activity_confirmation
     WHERE activity_id = a.id AND attendance = 'going';
    IF v_going < a.confirmation_threshold THEN RETURN NEW; END IF;

    v_by := public.fn_home_decide_by(c.proposed_time);

    UPDATE public.lobby_challenge
       SET status = 'pending_home', ready_at = now(), home_decide_by = v_by,
           updated_at = now()
     WHERE id = c.id AND status = 'requested';

    SELECT name INTO v_name FROM public.lobby WHERE id = c.initiator_lobby_id;
    PERFORM public.fn_enqueue_notification(
        'challenge_ready_for_home',
        ARRAY(SELECT uid FROM (
            SELECT captain_id AS uid FROM public.lobby WHERE id = c.target_lobby_id
            UNION
            SELECT user_id FROM public.lobby_member
             WHERE lobby_id = c.target_lobby_id AND role = 'coordinator') s),
        'Có đội sẵn sàng thách đấu',
        COALESCE(v_name, 'Một đội') || ' đã đủ quân — trả lời trước '
            || public.fn_vn_time_label(v_by),
        jsonb_build_object('lobby_id', c.target_lobby_id, 'challenge_id', c.id));

    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
    SELECT l.id, l.captain_id, 'update',
           jsonb_build_object(
               'title', 'Chờ duyệt thách đấu',
               'kind',  'challenge_ready',
               'tone',  'amber',
               'challenge_id', c.id,
               'fields', jsonb_build_array(
                   jsonb_build_array('Đội thách đấu', COALESCE(v_name, '—')),
                   jsonb_build_array('Sân', COALESCE(
                       (SELECT loc.name FROM public.location loc
                         WHERE loc.id = c.proposed_location), '—')),
                   jsonb_build_array('Đã đủ quân',
                       v_going::text || ' người')))
      FROM public.lobby l
     WHERE l.id = c.target_lobby_id;

    INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
    SELECT l.id, l.captain_id, 'update',
           jsonb_build_object(
               'title', 'Đã đủ quân',
               'kind',  'challenge_awaiting_home',
               'tone',  'blue',
               'fields', jsonb_build_array(
                   jsonb_build_array('Đối thủ', COALESCE(
                       (SELECT name FROM public.lobby
                         WHERE id = c.target_lobby_id), '—')),
                   jsonb_build_array('Sân', COALESCE(
                       (SELECT loc.name FROM public.location loc
                         WHERE loc.id = c.proposed_location), '—')),
                   jsonb_build_array('Trạng thái', 'Chờ đội chủ nhà trả lời')))
      FROM public.lobby l
     WHERE l.id = c.initiator_lobby_id;

    RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_friendly_challenge_quorum()
    FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Home picks — inside its window, never against itself, and RSVP'd
-- ─────────────────────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.pending_home_challengers(uuid);
CREATE FUNCTION public.pending_home_challengers(p_lobby_id uuid)
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
REVOKE ALL ON FUNCTION public.pending_home_challengers(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.pending_home_challengers(uuid) TO authenticated;

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

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. No-show: a claim is a report, answered within the ordinary 24h
-- ─────────────────────────────────────────────────────────────────────────────
-- The claimant's "they never showed" is filed as its blind report on the spot,
-- so every way this ends reuses the report machinery: the accused's own report
-- agrees (forfeit / ordinary result) or conflicts (dispute), a counter is a
-- dispute, a concession settles the walkover now, and silence is a one-sided
-- forfeit at end_time + 24h in sweep pass (d).
CREATE OR REPLACE FUNCTION public.claim_no_show(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid uuid := auth.uid(); c record; v_mine uuid; v_other uuid;
    v_end timestamptz; v_name text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.mode <> 'friendly' THEN RAISE EXCEPTION 'challenge not found'; END IF;

    v_mine := CASE
        WHEN public.lobby_can_manage(c.target_lobby_id, v_uid)    THEN c.target_lobby_id
        WHEN public.lobby_can_manage(c.initiator_lobby_id, v_uid) THEN c.initiator_lobby_id
    END;
    IF v_mine IS NULL THEN RAISE EXCEPTION 'not a manager of either lobby'; END IF;
    v_other := CASE WHEN v_mine = c.target_lobby_id
                    THEN c.initiator_lobby_id ELSE c.target_lobby_id END;

    SELECT max(a.end_time) INTO v_end FROM public.activity a WHERE a.challenge_id = p_challenge_id;
    IF now() < c.proposed_time + interval '30 minutes' THEN
        RAISE EXCEPTION 'too early — give them 30 minutes';
    END IF;
    IF v_end IS NOT NULL AND now() > v_end THEN
        RAISE EXCEPTION 'the match has ended — report the result instead';
    END IF;

    IF c.status = 'no_show_claimed' THEN
        IF c.no_show_claimed_by IS DISTINCT FROM v_mine THEN
            PERFORM public.fn_settle_friendly_challenge(
                p_challenge_id, 'disputed', 'disputed', NULL, NULL,
                'Hai đội cùng báo đối phương không đến');
            RETURN;
        END IF;
        RAISE EXCEPTION 'you have already made this claim';
    END IF;

    IF c.status <> 'scheduled' THEN RAISE EXCEPTION 'this match is not live'; END IF;

    UPDATE public.lobby_challenge
       SET status = 'no_show_claimed', no_show_claimed_by = v_mine,
           no_show_claimed_at = now(), updated_at = now()
     WHERE id = p_challenge_id;

    -- The claim IS the claimant's report, in the home frame: the claimant wins.
    INSERT INTO public.lobby_challenge_report
        (challenge_id, lobby_id, reported_by, result, is_forfeit)
    VALUES (p_challenge_id, v_mine, v_uid,
            CASE WHEN v_mine = c.target_lobby_id
                 THEN 'win'::public.lobby_match_result
                 ELSE 'loss'::public.lobby_match_result END,
            true)
    ON CONFLICT (challenge_id, lobby_id) DO UPDATE
        SET result = EXCLUDED.result, is_forfeit = true, sets = NULL,
            reported_by = EXCLUDED.reported_by, created_at = now();

    SELECT name INTO v_name FROM public.lobby WHERE id = v_mine;
    PERFORM public.fn_enqueue_notification(
        'no_show_claimed',
        ARRAY(SELECT uid FROM (
            SELECT captain_id AS uid FROM public.lobby WHERE id = v_other
            UNION
            SELECT user_id FROM public.lobby_member
             WHERE lobby_id = v_other AND role = 'coordinator') s),
        'Bị báo không đến',
        COALESCE(v_name, 'Đối thủ') || ' báo đội bạn không có mặt. Phản hồi trước '
            || public.fn_vn_time_label(COALESCE(v_end, c.proposed_time) + interval '24 hours'),
        jsonb_build_object('lobby_id', v_other, 'challenge_id', p_challenge_id));
END;
$$;

-- "We were there." Disagreement about whether the match happened is a dispute.
-- No longer limited to 10 minutes — it answers a claim at any point before the
-- claim settles at the reporting deadline.
CREATE OR REPLACE FUNCTION public.counter_no_show(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); c record; v_accused uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.status <> 'no_show_claimed' THEN
        RAISE EXCEPTION 'there is no claim to answer';
    END IF;
    v_accused := CASE WHEN c.no_show_claimed_by = c.target_lobby_id
                      THEN c.initiator_lobby_id ELSE c.target_lobby_id END;
    IF NOT public.lobby_can_manage(v_accused, v_uid) THEN
        RAISE EXCEPTION 'this claim is not against your lobby';
    END IF;

    PERFORM public.fn_settle_friendly_challenge(
        p_challenge_id, 'disputed', 'disputed', NULL, NULL,
        'Đội bị báo vắng mặt đã phản hồi');
END;
$$;

-- "Right, we didn't make it." Settles the walkover now instead of at the
-- deadline, so the team that turned up gets its answer the same evening.
CREATE OR REPLACE FUNCTION public.concede_no_show(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); c record; v_accused uuid; v_result public.lobby_match_result;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.status <> 'no_show_claimed' THEN
        RAISE EXCEPTION 'there is no claim to answer';
    END IF;
    v_accused := CASE WHEN c.no_show_claimed_by = c.target_lobby_id
                      THEN c.initiator_lobby_id ELSE c.target_lobby_id END;
    IF NOT public.lobby_can_manage(v_accused, v_uid) THEN
        RAISE EXCEPTION 'this claim is not against your lobby';
    END IF;

    -- Home frame: the claimant wins.
    v_result := CASE WHEN c.no_show_claimed_by = c.target_lobby_id
                     THEN 'win'::public.lobby_match_result
                     ELSE 'loss'::public.lobby_match_result END;

    INSERT INTO public.lobby_challenge_report
        (challenge_id, lobby_id, reported_by, result, is_forfeit)
    VALUES (p_challenge_id, v_accused, v_uid, v_result, true)
    ON CONFLICT (challenge_id, lobby_id) DO UPDATE
        SET result = EXCLUDED.result, is_forfeit = true, sets = NULL,
            reported_by = EXCLUDED.reported_by, created_at = now();

    PERFORM public.fn_settle_friendly_challenge(
        p_challenge_id, v_result, 'forfeit', NULL, NULL, 'Đối phương không có mặt');
END;
$$;
REVOKE ALL ON FUNCTION public.concede_no_show(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.concede_no_show(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. Reporting also answers an open claim
-- ─────────────────────────────────────────────────────────────────────────────
-- Same body as friendly_challenge.sql, except `no_show_claimed` is reportable:
-- the claimant's report is already on file, so the accused's report completes
-- the pair and resolves exactly like any other two reports.
CREATE OR REPLACE FUNCTION public.report_match_result(
    p_challenge_id uuid,
    p_result       text,
    p_sets         jsonb DEFAULT NULL,
    p_mvp_user_id  uuid  DEFAULT NULL,
    p_note         text  DEFAULT NULL
) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    c record; rh record; ra record;
    v_mine uuid; v_is_home boolean; v_end timestamptz;
    v_norm public.lobby_match_result; v_forfeit boolean := false;
    v_sets jsonb;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.mode <> 'friendly' THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF c.status NOT IN ('scheduled', 'awaiting_reports', 'no_show_claimed') THEN
        RAISE EXCEPTION 'this match is not open for reporting';
    END IF;

    v_mine := CASE
        WHEN public.lobby_can_manage(c.target_lobby_id, v_uid)    THEN c.target_lobby_id
        WHEN public.lobby_can_manage(c.initiator_lobby_id, v_uid) THEN c.initiator_lobby_id
    END;
    IF v_mine IS NULL THEN RAISE EXCEPTION 'not a manager of either lobby'; END IF;
    v_is_home := (v_mine = c.target_lobby_id);

    SELECT max(a.end_time) INTO v_end FROM public.activity a WHERE a.challenge_id = p_challenge_id;
    IF v_end IS NOT NULL AND now() < v_end THEN
        RAISE EXCEPTION 'the match has not finished yet';
    END IF;

    v_norm := CASE p_result
        WHEN 'draw'         THEN 'draw'::public.lobby_match_result
        WHEN 'win'          THEN CASE WHEN v_is_home THEN 'win'  ELSE 'loss' END
        WHEN 'loss'         THEN CASE WHEN v_is_home THEN 'loss' ELSE 'win'  END
        WHEN 'no_show_them' THEN CASE WHEN v_is_home THEN 'win'  ELSE 'loss' END
        WHEN 'no_show_us'   THEN CASE WHEN v_is_home THEN 'loss' ELSE 'win'  END
        ELSE NULL END;
    IF v_norm IS NULL THEN RAISE EXCEPTION 'invalid result %', p_result; END IF;
    v_forfeit := p_result IN ('no_show_them', 'no_show_us');

    IF c.ruleset <> 'best_of_sets' OR v_forfeit THEN p_sets := NULL; END IF;

    IF NOT v_is_home AND p_sets IS NOT NULL AND jsonb_typeof(p_sets) = 'array' THEN
        SELECT jsonb_agg(jsonb_build_array(s->1, s->0))
          INTO p_sets FROM jsonb_array_elements(p_sets) s;
    END IF;

    INSERT INTO public.lobby_challenge_report
        (challenge_id, lobby_id, reported_by, result, is_forfeit, sets, mvp_user_id, note)
    VALUES (p_challenge_id, v_mine, v_uid, v_norm, v_forfeit, p_sets, p_mvp_user_id,
            nullif(btrim(coalesce(p_note, '')), ''))
    ON CONFLICT (challenge_id, lobby_id) DO UPDATE
        SET result = EXCLUDED.result, is_forfeit = EXCLUDED.is_forfeit,
            sets = EXCLUDED.sets, mvp_user_id = EXCLUDED.mvp_user_id,
            note = EXCLUDED.note, reported_by = EXCLUDED.reported_by,
            created_at = now();

    -- An open no-show claim keeps its status until it resolves, so its card
    -- keeps explaining itself; only a plain scheduled match moves on.
    UPDATE public.lobby_challenge
       SET status = 'awaiting_reports', updated_at = now()
     WHERE id = p_challenge_id AND status = 'scheduled';

    SELECT * INTO rh FROM public.lobby_challenge_report
     WHERE challenge_id = p_challenge_id AND lobby_id = c.target_lobby_id;
    SELECT * INTO ra FROM public.lobby_challenge_report
     WHERE challenge_id = p_challenge_id AND lobby_id = c.initiator_lobby_id;

    IF rh.lobby_id IS NULL OR ra.lobby_id IS NULL THEN RETURN 'awaiting_opponent'; END IF;

    IF rh.result = ra.result THEN
        v_sets := CASE WHEN rh.sets IS NOT DISTINCT FROM ra.sets THEN rh.sets ELSE NULL END;
        PERFORM public.fn_settle_friendly_challenge(
            p_challenge_id, rh.result,
            CASE WHEN rh.is_forfeit AND ra.is_forfeit
                 THEN 'forfeit'::public.match_result_source
                 ELSE 'agreed'::public.match_result_source END,
            v_sets, COALESCE(rh.mvp_user_id, ra.mvp_user_id), COALESCE(rh.note, ra.note));
        RETURN 'agreed';
    END IF;

    IF rh.result = 'loss' AND ra.result = 'win' THEN
        IF rh.is_forfeit AND ra.is_forfeit THEN
            PERFORM public.fn_settle_friendly_challenge(
                p_challenge_id, 'practice', 'mutual_concession', NULL, NULL,
                'Cả hai đội đều báo không có mặt');
            RETURN 'no_match';
        END IF;
        PERFORM public.fn_settle_friendly_challenge(
            p_challenge_id, 'draw', 'mutual_concession', NULL,
            COALESCE(rh.mvp_user_id, ra.mvp_user_id),
            'Cả hai đội đều nhận thua — tính hòa');
        RETURN 'mutual_concession';
    END IF;

    PERFORM public.fn_settle_friendly_challenge(
        p_challenge_id, 'disputed', 'disputed', NULL, NULL,
        'Hai đội khai kết quả khác nhau');
    RETURN 'disputed';
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. The sweep
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_sweep_friendly_challenges()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    r record;
BEGIN
    -- ── (a) Offers whose gathering phase closed ─────────────────────────────
    -- Only `requested` challengers lapse here: they didn't round up their
    -- players in time. A `pending_home` one did, and now waits on
    -- home_decide_by (pass b). The "nobody bit" push goes out only when that
    -- is actually true — if someone is waiting, home already has their push.
    FOR r IN
        SELECT o.id, o.lobby_id
          FROM public.lobby_challenge_offer o
         WHERE o.status = 'open' AND o.expires_at <= now()
         FOR UPDATE OF o
    LOOP
        UPDATE public.lobby_challenge_offer SET status = 'expired' WHERE id = r.id;
        PERFORM public.fn_lapse_offer_challenges(
            r.id, 'Đội bạn chưa đủ quân trước hạn nên lời thách đấu đã hết hiệu lực', true);

        IF NOT EXISTS (SELECT 1 FROM public.lobby_challenge
                        WHERE offer_id = r.id AND status = 'pending_home') THEN
            PERFORM public.fn_enqueue_notification(
                'challenge_offer_expired',
                ARRAY(SELECT uid FROM (
                    SELECT captain_id AS uid FROM public.lobby WHERE id = r.lobby_id
                    UNION
                    SELECT user_id FROM public.lobby_member
                     WHERE lobby_id = r.lobby_id AND role = 'coordinator') s),
                'Lời mời hết hạn',
                'Chưa có đội nào đủ quân. Đăng lại cho tuần sau?',
                jsonb_build_object('lobby_id', r.lobby_id, 'offer_id', r.id));
        END IF;
    END LOOP;

    -- ── (b) Home didn't answer in time ──────────────────────────────────────
    FOR r IN
        SELECT c.id, c.initiator_lobby_id, l.name AS home_name
          FROM public.lobby_challenge c
          JOIN public.lobby l ON l.id = c.target_lobby_id
         WHERE c.mode = 'friendly'
           AND c.status = 'pending_home'
           AND c.home_decide_by IS NOT NULL
           AND c.home_decide_by <= now()
         FOR UPDATE OF c
    LOOP
        UPDATE public.lobby_challenge
           SET status = 'lapsed', updated_at = now() WHERE id = r.id;
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.initiator_lobby_id),
            'Thách đấu không thành',
            COALESCE(r.home_name, 'Đội chủ nhà') || ' không trả lời kịp',
            jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
    END LOOP;

    -- ── (b2) An hour left to answer ─────────────────────────────────────────
    -- Skipped when quorum itself was under two hours before the deadline: the
    -- ready push is recent enough to still be the reminder.
    FOR r IN
        SELECT c.id, c.target_lobby_id, c.ready_at, c.home_decide_by,
               li.name AS init_name
          FROM public.lobby_challenge c
          JOIN public.lobby li ON li.id = c.initiator_lobby_id
         WHERE c.mode = 'friendly'
           AND c.status = 'pending_home'
           AND c.home_reminded_at IS NULL
           AND c.home_decide_by IS NOT NULL
           AND c.home_decide_by - interval '1 hour' <= now()
           AND c.home_decide_by > now()
         FOR UPDATE OF c
    LOOP
        UPDATE public.lobby_challenge SET home_reminded_at = now() WHERE id = r.id;
        CONTINUE WHEN r.ready_at > r.home_decide_by - interval '2 hours';
        PERFORM public.fn_enqueue_notification(
            'challenge_ready_for_home',
            ARRAY(SELECT uid FROM (
                SELECT captain_id AS uid FROM public.lobby WHERE id = r.target_lobby_id
                UNION
                SELECT user_id FROM public.lobby_member
                 WHERE lobby_id = r.target_lobby_id AND role = 'coordinator') s),
            'Còn 1 tiếng để trả lời',
            COALESCE(r.init_name, 'Một đội') || ' vẫn đang chờ bạn nhận lời',
            jsonb_build_object('lobby_id', r.target_lobby_id, 'challenge_id', r.id));
    END LOOP;

    -- ── (c) Halfway reminder ────────────────────────────────────────────────
    -- An open no-show claim is reminded too: the accused is exactly who it's for.
    FOR r IN
        SELECT c.id, c.initiator_lobby_id, c.target_lobby_id
          FROM public.lobby_challenge c
          JOIN public.activity a ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.mode = 'friendly'
           AND c.status IN ('awaiting_reports', 'no_show_claimed')
           AND c.report_reminded_at IS NULL
           AND a.end_time + interval '12 hours' <= now()
         FOR UPDATE OF c
    LOOP
        UPDATE public.lobby_challenge SET report_reminded_at = now() WHERE id = r.id;

        IF NOT EXISTS (SELECT 1 FROM public.lobby_challenge_report
                        WHERE challenge_id = r.id AND lobby_id = r.target_lobby_id) THEN
            PERFORM public.fn_enqueue_notification(
                'match_result_pending',
                ARRAY(SELECT uid FROM (
                    SELECT captain_id AS uid FROM public.lobby WHERE id = r.target_lobby_id
                    UNION
                    SELECT user_id FROM public.lobby_member
                     WHERE lobby_id = r.target_lobby_id AND role = 'coordinator') s),
                'Chưa khai kết quả',
                'Còn 12 tiếng. Nếu chỉ một đội khai, kết quả của đội đó được ghi nhận.',
                jsonb_build_object('lobby_id', r.target_lobby_id, 'challenge_id', r.id));
        END IF;
        IF NOT EXISTS (SELECT 1 FROM public.lobby_challenge_report
                        WHERE challenge_id = r.id AND lobby_id = r.initiator_lobby_id) THEN
            PERFORM public.fn_enqueue_notification(
                'match_result_pending',
                ARRAY(SELECT uid FROM (
                    SELECT captain_id AS uid FROM public.lobby WHERE id = r.initiator_lobby_id
                    UNION
                    SELECT user_id FROM public.lobby_member
                     WHERE lobby_id = r.initiator_lobby_id AND role = 'coordinator') s),
                'Chưa khai kết quả',
                'Còn 12 tiếng. Nếu chỉ một đội khai, kết quả của đội đó được ghi nhận.',
                jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
        END IF;
    END LOOP;

    -- ── (d) The 24h window closes ───────────────────────────────────────────
    -- Unchanged, except an unanswered no-show claim lands here too: its one
    -- report is the claimant's forfeit, so it settles as a walkover.
    FOR r IN
        SELECT c.id,
               (SELECT count(*) FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id) AS n,
               (SELECT rr.result FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_result,
               (SELECT rr.is_forfeit FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_forfeit,
               (SELECT rr.sets FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_sets,
               (SELECT rr.mvp_user_id FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_mvp,
               (SELECT rr.note FROM public.lobby_challenge_report rr
                 WHERE rr.challenge_id = c.id LIMIT 1) AS only_note
          FROM public.lobby_challenge c
          JOIN public.activity a ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.mode = 'friendly'
           AND c.status IN ('awaiting_reports', 'scheduled', 'no_show_claimed')
           AND a.end_time + interval '24 hours' <= now()
         FOR UPDATE OF c
    LOOP
        IF r.n = 1 THEN
            PERFORM public.fn_settle_friendly_challenge(
                r.id, r.only_result,
                CASE WHEN r.only_forfeit THEN 'forfeit'::public.match_result_source
                     ELSE 'one_sided'::public.match_result_source END,
                r.only_sets, r.only_mvp, r.only_note);
        ELSE
            PERFORM public.fn_settle_friendly_challenge(
                r.id, 'practice', 'one_sided', NULL, NULL,
                'Không đội nào khai kết quả');
        END IF;
    END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_sweep_friendly_challenges() FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. Renew once
-- ─────────────────────────────────────────────────────────────────────────────
-- The expired-offer notification now carries a "Đăng lại tuần sau" button.
-- Renewing re-runs publish into the same slot, so a second tap on the same
-- notification would replace the first renewal — lapsing anyone who had
-- already answered it. A renewal that is still live answers the second tap.
CREATE OR REPLACE FUNCTION public.renew_challenge_offer(p_offer_id uuid)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
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
        o.handicap_side::text, o.handicap_amount, o.terms_note, o.mode::text);

    UPDATE public.lobby_challenge_offer SET renewed_from = p_offer_id WHERE id = v_id;
    RETURN v_id;
END;
$$;
