-- ============================================================================
-- friendly_challenge.sql — Part C of the friendly-challenge build.
-- Apply AFTER friendly_challenge_offer.sql, lobby_trust.sql and
-- friendly_challenge_rating.sql — this file reads lobby.trust_score and writes
-- lobby_match.result_source, both of which those two add.
--
-- The friendly state machine, end to end:
--
--   home publishes an offer (Part B)
--        │
--   requested ── a challenger sends against that offer, and its OWN activity is
--        │       materialised immediately with a threshold IT chose. Any number
--        │       of lobbies may deliberate on one offer in parallel; nothing is
--        │       locked, so nobody can squat a slot by challenging and sitting.
--        │
--   pending_home ── that challenger's members reached their threshold. Home now
--        │          sees every ready challenger with a full public profile and
--        │          PICKS one; this is a chooser, not a yes/no.
--        │
--   scheduled ── home accepted. Home's activity is created (no threshold — they
--        │        posted the fixture), the offer slot closes, and every sibling
--        │        challenge on that offer auto-declines.
--        │
--   awaiting_reports ── played. Both sides file a result BLIND. Matching reports
--        │               rate the match; conflicting reports make it `disputed`
--        │               and cost BOTH lobbies a loss.
--        │
--   played / disputed / declined / lapsed / cancelled
--
-- Why disputing costs both sides a loss (see Part D for the arithmetic): if a
-- dispute were a free void, the losing side would simply file a false report
-- every time to escape the rating hit. Pricing a dispute at "at least as bad as
-- losing" makes that strictly unprofitable — a true loser gains nothing, and a
-- liar drags themselves down alongside their victim. The same reasoning makes an
-- uncountered no-show a RATED forfeit rather than an unrated void: not turning
-- up must not be cheaper than turning up and losing.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Notification kinds go live
-- ─────────────────────────────────────────────────────────────────────────────
-- Data-driven allowlist: a kind that isn't here is silently dropped by
-- fn_enqueue_notification, which is how kinds are dark-launched and killed.
INSERT INTO public.enabled_notification_kind (kind, enabled) VALUES
    ('challenge_ready_for_home', true),
    ('challenge_offer_expired',  true),
    ('match_result_pending',     true),
    ('no_show_claimed',          true),
    ('match_disputed',           true)
ON CONFLICT (kind) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. lobby_challenge gains its mode and its term snapshot
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.lobby_challenge
    ADD COLUMN IF NOT EXISTS mode public.lobby_challenge_mode NOT NULL DEFAULT 'friendly',
    ADD COLUMN IF NOT EXISTS offer_id uuid REFERENCES public.lobby_challenge_offer(id) ON DELETE SET NULL,
    -- Snapshot of the offer's terms, for exactly the reason proposed_time /
    -- proposed_location / agreed_cost are already snapshotted: a manager editing
    -- the offer afterwards must not be able to rewrite the terms an in-flight
    -- challenge was sent under.
    ADD COLUMN IF NOT EXISTS venue_cost      numeric(10,2),
    ADD COLUMN IF NOT EXISTS cost_split      public.challenge_cost_split NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS bounty_kind     public.challenge_bounty_kind NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS bounty_amount   numeric(10,2),
    ADD COLUMN IF NOT EXISTS ruleset         public.challenge_ruleset NOT NULL DEFAULT 'standard',
    ADD COLUMN IF NOT EXISTS ruleset_param   smallint,
    ADD COLUMN IF NOT EXISTS handicap_side   public.challenge_handicap_side NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS handicap_amount smallint,
    ADD COLUMN IF NOT EXISTS terms_note      text,
    -- No-show claim bookkeeping. Nullable: most challenges never see one.
    ADD COLUMN IF NOT EXISTS no_show_claimed_by uuid REFERENCES public.lobby(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS no_show_claimed_at timestamptz,
    -- Stamped once by the 12h sweep so the reminder cannot repeat every minute.
    ADD COLUMN IF NOT EXISTS report_reminded_at timestamptz;

-- Existing rows predate friendly mode entirely.
UPDATE public.lobby_challenge SET mode = 'refereed' WHERE mode = 'friendly' AND offer_id IS NULL;

-- The old index allowed exactly one open challenge between a given pair, which
-- would block challenging the same lobby's OTHER slot. Uniqueness now belongs
-- against the offer, not the opponent.
DROP INDEX IF EXISTS public.lobby_challenge_one_open;
CREATE UNIQUE INDEX IF NOT EXISTS lobby_challenge_one_open_per_offer
    ON public.lobby_challenge (initiator_lobby_id, offer_id)
    WHERE status IN ('requested', 'pending_home');

CREATE INDEX IF NOT EXISTS lobby_challenge_offer_idx
    ON public.lobby_challenge (offer_id, status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. The blind ballot box
-- ─────────────────────────────────────────────────────────────────────────────
-- Each lobby files its own result without seeing the other's. Blindness is
-- enforced HERE, in RLS — hiding the opponent's report client-side would leave
-- it readable over the wire, which is not a guarantee at all.
--
-- `result` is stored NORMALISED TO THE HOME FRAME so the two rows are directly
-- comparable: the client reports from its own perspective ("we won") and
-- report_match_result flips it for the away side before storing.
CREATE TABLE IF NOT EXISTS public.lobby_challenge_report (
    challenge_id uuid NOT NULL REFERENCES public.lobby_challenge(id) ON DELETE CASCADE,
    lobby_id     uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    reported_by  uuid REFERENCES public."user"(id) ON DELETE SET NULL,
    result       public.lobby_match_result NOT NULL,
    -- Set when the reporter says a side never turned up. Carried separately
    -- from `result` because a forfeit IS a win/loss — it just rates at half for
    -- the side that showed up (see fn_apply_match_rating in Part D).
    is_forfeit   boolean NOT NULL DEFAULT false,
    sets         jsonb,
    mvp_user_id  uuid REFERENCES public."user"(id) ON DELETE SET NULL,
    note         text,
    created_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (challenge_id, lobby_id),
    CONSTRAINT lobby_challenge_report_note_length
        CHECK (note IS NULL OR char_length(note) <= 280),
    -- A report is a verdict, never "disputed" — disputed is what the SERVER
    -- concludes when two verdicts disagree.
    CONSTRAINT lobby_challenge_report_result_shape
        CHECK (result <> 'disputed')
);

ALTER TABLE public.lobby_challenge_report ENABLE ROW LEVEL SECURITY;

-- You may read your own lobby's report at any time; you may read the opponent's
-- only once the challenge has left `awaiting_reports` — i.e. once the match has
-- resolved and there is nothing left to copy.
CREATE POLICY "Members read their own report, and both once resolved"
    ON public.lobby_challenge_report FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM public.lobby_member lm
                 WHERE lm.lobby_id = lobby_challenge_report.lobby_id
                   AND lm.user_id = (select auth.uid()))
        OR EXISTS (
            SELECT 1 FROM public.lobby_challenge c
             WHERE c.id = lobby_challenge_report.challenge_id
               AND c.status <> 'awaiting_reports'
               AND EXISTS (SELECT 1 FROM public.lobby_member lm2
                            WHERE lm2.user_id = (select auth.uid())
                              AND lm2.lobby_id IN (c.initiator_lobby_id, c.target_lobby_id)))
    );

-- No write policies: report_match_result is the only writer.
GRANT SELECT ON TABLE public.lobby_challenge_report TO authenticated;
GRANT ALL    ON TABLE public.lobby_challenge_report TO service_role;

COMMENT ON TABLE public.lobby_challenge_report IS
'One blind result report per lobby per friendly challenge. `result` is stored '
'normalised to the HOME frame so the two rows compare directly. RLS is what '
'makes reporting blind: the opponent''s row is unreadable until the challenge '
'leaves `awaiting_reports`. Matching reports rate the match; conflicting ones '
'make it `disputed` and cost both lobbies a loss.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Offer lifecycle
-- ─────────────────────────────────────────────────────────────────────────────

-- Kill an offer's outstanding challenges and the activities they materialised.
-- A lapsed challenge is NOT deleted: the challenger's members RSVP'd to it, so
-- it stays in the record as something that happened and fell through, and every
-- activity reader derives "dead" from this status rather than from a column of
-- its own (single source of truth — `activity` gains no status).
CREATE OR REPLACE FUNCTION public.fn_lapse_offer_challenges(p_offer_id uuid, p_reason text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT id, initiator_lobby_id FROM public.lobby_challenge
         WHERE offer_id = p_offer_id AND status IN ('requested', 'pending_home')
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
REVOKE ALL ON FUNCTION public.fn_lapse_offer_challenges(uuid, text)
    FROM PUBLIC, anon, authenticated;

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

    -- Default the advert to close a day before kickoff, so the lobby knows
    -- whether it has a match while there is still time to find another. Clamped
    -- for an offer posted less than a day out.
    v_expires := COALESCE(p_expires_at,
                          GREATEST(p_kickoff - interval '24 hours',
                                   LEAST(now() + interval '1 hour',
                                         p_kickoff - interval '1 minute')));
    IF v_expires >= p_kickoff THEN
        RAISE EXCEPTION 'the offer must close before kickoff';
    END IF;
    IF v_expires <= now() THEN
        RAISE EXCEPTION 'the offer would close in the past';
    END IF;

    -- Re-publishing into an occupied slot replaces it. The old offer's
    -- challengers are told, rather than silently finding their fixture gone.
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
GRANT EXECUTE ON FUNCTION public.publish_challenge_offer(
    uuid, smallint, timestamptz, uuid, timestamptz, numeric, text, text, numeric,
    text, smallint, text, smallint, text, text) TO authenticated;

CREATE OR REPLACE FUNCTION public.withdraw_challenge_offer(p_offer_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); v_lobby uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT lobby_id INTO v_lobby FROM public.lobby_challenge_offer
     WHERE id = p_offer_id AND status = 'open' FOR UPDATE;
    IF v_lobby IS NULL THEN RAISE EXCEPTION 'no open offer'; END IF;
    IF NOT public.lobby_can_manage(v_lobby, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;

    UPDATE public.lobby_challenge_offer SET status = 'withdrawn' WHERE id = p_offer_id;
    PERFORM public.fn_lapse_offer_challenges(p_offer_id, 'Đội chủ nhà đã rút lời mời');
END;
$$;
GRANT EXECUTE ON FUNCTION public.withdraw_challenge_offer(uuid) TO authenticated;

-- The one-tap "đăng lại tuần sau" behind the expiry push. Deliberately NOT an
-- auto_renew flag: an abandoned lobby would otherwise advertise a fixture it
-- will never honour forever, and every live offer here was affirmed by a human.
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

    -- Shift a week and re-run the publish path, so the slot-replacement and
    -- validation rules are the same ones a hand-published offer goes through.
    v_id := public.publish_challenge_offer(
        o.lobby_id, o.slot, o.kickoff + interval '7 days', o.location_id,
        o.expires_at + interval '7 days', o.venue_cost, o.cost_split::text,
        o.bounty_kind::text, o.bounty_amount, o.ruleset::text, o.ruleset_param,
        o.handicap_side::text, o.handicap_amount, o.terms_note, o.mode::text);

    UPDATE public.lobby_challenge_offer SET renewed_from = p_offer_id WHERE id = v_id;
    RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.renew_challenge_offer(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Sending a challenge — and committing your own people first
-- ─────────────────────────────────────────────────────────────────────────────
-- The step that makes friendly mode different: the challenger's activity is
-- materialised HERE, before home has ever seen the challenge, so the challenger
-- has to get its own members to show up on paper before it can ask for a match.
-- The threshold is chosen by the challenger, not dictated by home — it is their
-- roster, and only they know how many of them a Saturday actually produces.
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
    v_id      uuid;
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

    SELECT sport_id, captain_id, member_count
      INTO v_sport, v_captain, v_members
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

    -- Snapshot every term. From here the challenge is answerable on its own
    -- terms even if home edits or withdraws the advert.
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

    -- The challenger's own fixture, live immediately so members can RSVP. Its
    -- deadline IS the offer's expiry: deliberate slowness must not be a way to
    -- hold a slot past the point where home can still find someone else.
    INSERT INTO public.activity
        (user_id, sport_id, lobby_id, challenge_id, start_time, end_time,
         location_id, cost_type, cost_amount,
         confirmation_threshold, confirmation_deadline)
    VALUES (v_captain, v_sport, p_initiator_lobby, v_id,
            o.kickoff, o.kickoff + make_interval(mins => c_match_minutes),
            o.location_id,
            CASE WHEN COALESCE(o.venue_cost, 0) > 0 THEN 'total'::public.activity_cost_type END,
            CASE WHEN COALESCE(o.venue_cost, 0) > 0 THEN o.venue_cost END,
            p_threshold, o.expires_at);

    RETURN v_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.send_friendly_challenge(uuid, uuid, integer, text) TO authenticated;

-- Quorum on the challenger's side hands the ball to home. Automatic, because
-- making a manager press "now tell them" adds a step that can only ever be
-- forgotten — the members already said yes, which is the whole signal.
CREATE OR REPLACE FUNCTION public.fn_friendly_challenge_quorum()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    a record; c record; v_going integer; v_name text;
BEGIN
    SELECT id, challenge_id, lobby_id, confirmation_threshold
      INTO a FROM public.activity WHERE id = NEW.activity_id;
    IF a.challenge_id IS NULL OR a.confirmation_threshold IS NULL THEN RETURN NEW; END IF;

    SELECT * INTO c FROM public.lobby_challenge WHERE id = a.challenge_id;
    IF c.mode <> 'friendly' OR c.status <> 'requested' THEN RETURN NEW; END IF;
    -- Only the CHALLENGER's activity carries a threshold; home's has none.
    IF c.initiator_lobby_id <> a.lobby_id THEN RETURN NEW; END IF;

    SELECT count(*) INTO v_going FROM public.activity_confirmation
     WHERE activity_id = a.id AND attendance = 'going';
    IF v_going < a.confirmation_threshold THEN RETURN NEW; END IF;

    UPDATE public.lobby_challenge
       SET status = 'pending_home', updated_at = now()
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
        COALESCE(v_name, 'Một đội') || ' đã đủ quân và đang chờ bạn duyệt',
        -- The recipient's OWN lobby id: a shared one would route home's tap
        -- into the challenger's lobby.
        jsonb_build_object('lobby_id', c.target_lobby_id, 'challenge_id', c.id));

    -- Second surface. The push is the only *timely* signal, but it is also the
    -- easiest thing in the world to miss or dismiss — and this one is asking a
    -- manager to make a decision that expires with the offer. The feed item is
    -- the durable record: a manager who never saw the notification still finds
    -- "someone is waiting on us" the next time they open the lobby, and the
    -- badged "Lời thách đấu" row is right there in the info sheet.
    --
    -- Deliberately NO timestamp in the fields: `proposed_time` is timestamptz
    -- and formatting it here would render in the database's timezone, not the
    -- reader's. Everything shown is timezone-free.
    -- `challenge_id` is what makes this card ACTIONABLE rather than a notice:
    -- the feed renderer opens the challenger chooser straight from it, so a
    -- manager answers in one tap instead of going hunting through the info
    -- sheet. Every other update card is a read-only log entry; this one is a
    -- pending decision, and it should not cost three taps to act on.
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

    -- The challenger's own feed. Their members just voted the fixture over its
    -- threshold, so the state change is theirs too — without this the RSVP
    -- simply goes quiet and nobody knows whether it worked. Informational
    -- only: there is nothing for them to do but wait, and no challenge_id, so
    -- the card is deliberately not tappable.
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

DROP TRIGGER IF EXISTS trg_friendly_challenge_quorum ON public.activity_confirmation;
CREATE TRIGGER trg_friendly_challenge_quorum
    AFTER INSERT OR UPDATE ON public.activity_confirmation
    FOR EACH ROW EXECUTE FUNCTION public.fn_friendly_challenge_quorum();

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Home picks
-- ─────────────────────────────────────────────────────────────────────────────
-- Nothing was ever locked, so home can be looking at several ready challengers
-- at once. That is the point: home is choosing WHO to meet, not merely saying
-- yes to whoever asked first. Each row carries the challenger's full public
-- preview so the choice is made on something.
CREATE OR REPLACE FUNCTION public.pending_home_challengers(p_lobby_id uuid)
RETURNS TABLE(
    challenge_id uuid, offer_id uuid, offer_slot smallint,
    initiator_lobby_id uuid, initiator_name text, initiator_mmr integer,
    trust_score integer, rated_match_count integer, member_count integer,
    going_count integer, confirmation_threshold integer,
    kickoff timestamptz, location_name text, note text,
    created_at timestamptz, description text, homeground_name text,
    recommendation_counts jsonb)
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
           public.lobby_recommendation_counts(l.id)
      FROM public.lobby_challenge c
      JOIN public.lobby l ON l.id = c.initiator_lobby_id
      LEFT JOIN public.lobby_challenge_offer o ON o.id = c.offer_id
     WHERE c.target_lobby_id = p_lobby_id
       AND c.mode = 'friendly'
       AND c.status = 'pending_home'
       AND public.lobby_can_manage(p_lobby_id, auth.uid())
     ORDER BY c.created_at;
$$;
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

    SELECT name INTO v_init_name FROM public.lobby WHERE id = c.initiator_lobby_id;
    SELECT name, captain_id INTO v_home_name, v_home_captain
      FROM public.lobby WHERE id = c.target_lobby_id;

    IF p_action = 'accept' THEN
        UPDATE public.lobby_challenge
           SET status = 'scheduled', updated_at = now() WHERE id = p_challenge_id;

        -- Home's fixture carries NO threshold: they posted the offer, so the
        -- single manager yes IS their commitment. Requiring their members to
        -- re-vote for a match their own lobby advertised would be theatre.
        INSERT INTO public.activity
            (user_id, sport_id, lobby_id, challenge_id, start_time, end_time,
             location_id, cost_type, cost_amount)
        VALUES (v_home_captain, c.sport_id, c.target_lobby_id, p_challenge_id,
                c.proposed_time, c.proposed_time + make_interval(mins => c_match_minutes),
                c.proposed_location,
                CASE WHEN COALESCE(c.venue_cost, 0) > 0 THEN 'total'::public.activity_cost_type END,
                CASE WHEN COALESCE(c.venue_cost, 0) > 0 THEN c.venue_cost END);

        -- The slot is spent. Its other challengers are declined rather than
        -- left hanging — they committed their own members to this date and are
        -- owed a straight answer so they can go find another match.
        UPDATE public.lobby_challenge_offer
           SET status = 'taken' WHERE id = c.offer_id;

        PERFORM public.fn_lapse_offer_challenges(c.offer_id,
            COALESCE(v_home_name, 'Đội chủ nhà') || ' đã nhận lời thách đấu của đội khác');

        PERFORM public.fn_enqueue_notification(
            'challenger_confirmed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = c.initiator_lobby_id),
            'Thách đấu được chấp nhận',
            COALESCE(v_home_name, 'Đối thủ') || ' đã nhận lời thách đấu',
            jsonb_build_object('lobby_id', c.initiator_lobby_id, 'challenge_id', p_challenge_id));
        PERFORM public.fn_enqueue_notification(
            'challenge_scheduled',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = c.target_lobby_id),
            'Trận đấu đã chốt',
            'Trận gặp ' || COALESCE(v_init_name, 'đối thủ') || ' đã được xác nhận',
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

        -- The challenger's activity is NOT deleted. Its members RSVP'd; it
        -- stays as a thing that happened and fell through. Every activity
        -- reader derives "dead" from this status.
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
GRANT EXECUTE ON FUNCTION public.respond_friendly_challenge(uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Resolution — writing the one match row
-- ─────────────────────────────────────────────────────────────────────────────
-- Every terminal path funnels through here so the match row, the challenge
-- status, the trust bookkeeping and the pushes can never drift apart.
-- `p_result` is already in the HOME frame.
CREATE OR REPLACE FUNCTION public.fn_settle_friendly_challenge(
    p_challenge_id uuid,
    p_result       public.lobby_match_result,
    p_source       public.match_result_source,
    p_sets         jsonb DEFAULT NULL,
    p_mvp_user_id  uuid  DEFAULT NULL,
    p_note         text  DEFAULT NULL
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    c        record;
    v_home   uuid; v_away uuid;
    v_act    uuid; v_start timestamptz; v_venue text;
    v_match  uuid;
    v_home_name text; v_away_name text;
    v_title  text; v_body text;
BEGIN
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF c.status IN ('played', 'disputed') THEN RETURN NULL; END IF;

    -- Home is the lobby that posted the offer.
    v_home := c.target_lobby_id;
    v_away := c.initiator_lobby_id;

    SELECT a.id, a.start_time INTO v_act, v_start
      FROM public.activity a
     WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_home
     LIMIT 1;
    SELECT loc.name INTO v_venue FROM public.location loc WHERE loc.id = c.proposed_location;
    SELECT name INTO v_home_name FROM public.lobby WHERE id = v_home;
    SELECT name INTO v_away_name FROM public.lobby WHERE id = v_away;

    -- One physical row, read from both directions by lobby_match_history_data.
    INSERT INTO public.lobby_match
        (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result, sets,
         mvp_user_id, note, venue_label, played_at, result_source)
    VALUES (v_home, v_act, v_away, COALESCE(v_away_name, '—'),
            p_result,
            -- 'practice' and 'disputed' carry no agreed scoreline. The former
            -- is also a CHECK (lobby_match_sets_only_when_decided).
            CASE WHEN p_result IN ('practice', 'disputed') THEN NULL ELSE p_sets END,
            p_mvp_user_id, p_note, COALESCE(v_venue, '—'),
            COALESCE(v_start, c.proposed_time, now()), p_source)
    RETURNING id INTO v_match;

    -- The CASE yields `text`; Postgres will not implicitly assign that to an
    -- enum column, so the cast is load-bearing rather than decorative.
    UPDATE public.lobby_challenge
       SET status = (CASE WHEN p_result = 'disputed' THEN 'disputed' ELSE 'played' END)
                    ::public.lobby_challenge_status,
           updated_at = now()
     WHERE id = p_challenge_id;

    IF p_result = 'disputed' THEN
        -- Both sides pay, and both counters ramp. Nobody is knowably guilty
        -- from one row: a liar and their victim look identical here. What
        -- separates them is the doubling — a serial false-reporter draws
        -- disputes from many opponents and ramps 10 → 20 → 40, while each
        -- victim disputes once and resets on their next clean match.
        PERFORM public.fn_lobby_dispute_penalty(v_home);
        PERFORM public.fn_lobby_dispute_penalty(v_away);
        v_title := 'Tranh chấp kết quả';
        v_body  := 'Hai đội khai kết quả khác nhau — trận đấu bị tính thua cho cả hai bên';
        PERFORM public.fn_enqueue_notification('match_disputed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_home),
            v_title, v_body, jsonb_build_object('lobby_id', v_home, 'challenge_id', p_challenge_id));
        PERFORM public.fn_enqueue_notification('match_disputed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_away),
            v_title, v_body, jsonb_build_object('lobby_id', v_away, 'challenge_id', p_challenge_id));
    ELSE
        -- A clean result is what clears a lobby's dispute ramp: the way back is
        -- to play a match that ends in agreement, which a serial offender never
        -- manages and an unlucky honest lobby manages next week.
        IF p_source IN ('agreed', 'one_sided') THEN
            PERFORM public.fn_lobby_dispute_streak_reset(v_home);
            PERFORM public.fn_lobby_dispute_streak_reset(v_away);
        END IF;
        IF p_source = 'forfeit' THEN
            -- The absent side also wears the trust hit; showing up is the
            -- minimum, and the opponent's denouncements will follow anyway.
            PERFORM public.fn_lobby_dispute_penalty(
                CASE WHEN p_result = 'win' THEN v_away ELSE v_home END);
        END IF;
        v_title := 'Kết quả trận đấu';
        v_body  := 'Kết quả trận giao hữu đã được ghi nhận';
        PERFORM public.fn_enqueue_notification('match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_home),
            v_title, v_body, jsonb_build_object('lobby_id', v_home, 'challenge_id', p_challenge_id));
        PERFORM public.fn_enqueue_notification('match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_away),
            v_title, v_body, jsonb_build_object('lobby_id', v_away, 'challenge_id', p_challenge_id));
    END IF;

    RETURN v_match;
END;
$$;
-- Internal machinery: SECURITY DEFINER with NO caller authorization, because
-- the RPCs that call it do the checking. Supabase grants EXECUTE to anon and
-- authenticated by default at CREATE time and `FROM PUBLIC` does NOT remove
-- those, so both roles must be named explicitly -- otherwise any signed-in user
-- can stamp an arbitrary result onto any challenge.
REVOKE ALL ON FUNCTION public.fn_settle_friendly_challenge(
    uuid, public.lobby_match_result, public.match_result_source, jsonb, uuid, text)
    FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. The in-match no-show claim
-- ─────────────────────────────────────────────────────────────────────────────
-- Deliberately live rather than post-match: the team standing on an empty pitch
-- should be able to go home knowing where it stands, not wait a day. The window
-- opens 30 minutes after kickoff (late is not absent) and the accused gets 10
-- minutes to counter. Uncountered, the sweep settles it as a forfeit; countered,
-- the two sides disagree about what happened, which is exactly a dispute.
CREATE OR REPLACE FUNCTION public.claim_no_show(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid uuid := auth.uid(); c record; v_mine uuid; v_end timestamptz; v_name text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.mode <> 'friendly' THEN RAISE EXCEPTION 'challenge not found'; END IF;

    v_mine := CASE
        WHEN public.lobby_can_manage(c.target_lobby_id, v_uid)    THEN c.target_lobby_id
        WHEN public.lobby_can_manage(c.initiator_lobby_id, v_uid) THEN c.initiator_lobby_id
    END;
    IF v_mine IS NULL THEN RAISE EXCEPTION 'not a manager of either lobby'; END IF;

    SELECT max(a.end_time) INTO v_end FROM public.activity a WHERE a.challenge_id = p_challenge_id;
    IF now() < c.proposed_time + interval '30 minutes' THEN
        RAISE EXCEPTION 'too early — give them 30 minutes';
    END IF;
    IF v_end IS NOT NULL AND now() > v_end THEN
        RAISE EXCEPTION 'the match has ended — report the result instead';
    END IF;

    IF c.status = 'no_show_claimed' THEN
        -- Both sides claiming the other never showed is a disagreement about
        -- the match itself, settled the same way any other one is.
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

    SELECT name INTO v_name FROM public.lobby WHERE id = v_mine;
    PERFORM public.fn_enqueue_notification(
        'no_show_claimed',
        ARRAY(SELECT uid FROM (
            SELECT captain_id AS uid FROM public.lobby
             WHERE id = CASE WHEN v_mine = c.target_lobby_id
                             THEN c.initiator_lobby_id ELSE c.target_lobby_id END
            UNION
            SELECT user_id FROM public.lobby_member
             WHERE lobby_id = CASE WHEN v_mine = c.target_lobby_id
                                   THEN c.initiator_lobby_id ELSE c.target_lobby_id END
               AND role = 'coordinator') s),
        'Bị báo không đến',
        COALESCE(v_name, 'Đối thủ') || ' báo đội bạn không có mặt. Bạn có 10 phút để phản hồi.',
        jsonb_build_object(
            'lobby_id', CASE WHEN v_mine = c.target_lobby_id
                             THEN c.initiator_lobby_id ELSE c.target_lobby_id END,
            'challenge_id', p_challenge_id));
END;
$$;
GRANT EXECUTE ON FUNCTION public.claim_no_show(uuid) TO authenticated;

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
    IF now() > c.no_show_claimed_at + interval '10 minutes' THEN
        RAISE EXCEPTION 'the window to answer has closed';
    END IF;

    PERFORM public.fn_settle_friendly_challenge(
        p_challenge_id, 'disputed', 'disputed', NULL, NULL,
        'Đội bị báo vắng mặt đã phản hồi');
END;
$$;
GRANT EXECUTE ON FUNCTION public.counter_no_show(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. The blind report
-- ─────────────────────────────────────────────────────────────────────────────
-- `p_result` is from the REPORTER's own perspective — 'win', 'loss', 'draw',
-- 'no_show_them', 'no_show_us' — and is normalised to the home frame before
-- storage so the two rows compare directly.
--
-- Blind is a server guarantee, not social advice: the app will not show you the
-- opponent's answer, but the client actively tells you to go and agree the
-- result with them on the pitch first. Most of these formats need on-site
-- bookkeeping that gets fuzzy — nobody counted the king-of-the-hill holds
-- exactly — and two teams agreeing to call it a draw is a legitimate outcome.
-- What blindness prevents is one side copying the other, not the conversation
-- that produces an honest answer.
--
-- Two reports resolve one of three ways:
--   they match                 → rated as reported.
--   both conceded (each said
--   "we lost")                 → a DRAW, not a dispute. Nobody is lying when
--                                both sides are being generous, and these
--                                formats produce scrappy afternoons where
--                                neither side is sure. The draw already lands
--                                where it should: the home-advantage constant
--                                makes it favour the away and lower-rated side.
--   anything else, including
--   both claiming the win      → disputed, and both take a loss.
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
    c record; rh record; ra record;   -- rh = home's report, ra = away's
    v_mine uuid; v_is_home boolean; v_end timestamptz;
    v_norm public.lobby_match_result; v_forfeit boolean := false;
    v_sets jsonb;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.mode <> 'friendly' THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF c.status NOT IN ('scheduled', 'awaiting_reports') THEN
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

    -- Normalise to the home frame.
    v_norm := CASE p_result
        WHEN 'draw'         THEN 'draw'::public.lobby_match_result
        WHEN 'win'          THEN CASE WHEN v_is_home THEN 'win'  ELSE 'loss' END
        WHEN 'loss'         THEN CASE WHEN v_is_home THEN 'loss' ELSE 'win'  END
        WHEN 'no_show_them' THEN CASE WHEN v_is_home THEN 'win'  ELSE 'loss' END
        WHEN 'no_show_us'   THEN CASE WHEN v_is_home THEN 'loss' ELSE 'win'  END
        ELSE NULL END;
    IF v_norm IS NULL THEN RAISE EXCEPTION 'invalid result %', p_result; END IF;
    v_forfeit := p_result IN ('no_show_them', 'no_show_us');

    -- Only best_of_sets produces a scoreline anyone can agree on; the other
    -- formats have no set-by-set record to compare, so they rate on the flat
    -- delta (fn_apply_match_rating's margin multiplier simply does not fire).
    IF c.ruleset <> 'best_of_sets' OR v_forfeit THEN p_sets := NULL; END IF;

    -- Sets live on disk HOME-FIRST — `[home, away]` per set — because
    -- lobby_match_history_data reverses each pair for the away reader. But a
    -- manager types their OWN score first, so an away report arrives
    -- `[us, them]` and has to be flipped here. Without this the two sides'
    -- scorelines would never compare equal, and every best-of-sets match would
    -- quietly lose its scoreline (and its Elo margin multiplier) to the
    -- "reports disagree on sets" rule.
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

    UPDATE public.lobby_challenge
       SET status = 'awaiting_reports', updated_at = now()
     WHERE id = p_challenge_id AND status = 'scheduled';

    -- Both rows are read explicitly by SIDE, not as "mine and theirs". Two
    -- conflicting reports collapse to the same unordered {win, loss} pair in the
    -- home frame whichever way round they are, so an order-blind comparison
    -- cannot tell "we both lost" from "we both won" — and those two are
    -- opposites. Which lobby said which is the entire signal.
    SELECT * INTO rh FROM public.lobby_challenge_report
     WHERE challenge_id = p_challenge_id AND lobby_id = c.target_lobby_id;
    SELECT * INTO ra FROM public.lobby_challenge_report
     WHERE challenge_id = p_challenge_id AND lobby_id = c.initiator_lobby_id;

    -- Still waiting on them. The 24h sweep decides what silence means.
    IF rh.lobby_id IS NULL OR ra.lobby_id IS NULL THEN RETURN 'awaiting_opponent'; END IF;

    -- Agreement is judged on the RESULT ALONE. Every lesser disagreement is
    -- dropped rather than escalated, because two teams who agree on who won
    -- have not had a dispute:
    --   * mismatched sets      → rated, scoreline discarded. A mistyped set
    --                            score must not cost both teams their rating.
    --   * mismatched forfeit   → rated as an ordinary result. "They never
    --                            showed" vs "we played and lost" still agree on
    --                            the winner; the only thing riding on it is the
    --                            walkover half-delta, which is not worth a
    --                            double loss. A forfeit is only honoured when
    --                            BOTH sides say the match wasn't played.
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

    -- ── Both sides said they lost ───────────────────────────────────────────
    -- home reported 'loss' AND away reported 'win' means each lobby, writing
    -- blind, conceded to the other. That is not a conflict about the facts — it
    -- is two teams being gracious about a scrappy afternoon nobody kept score
    -- of properly, which these formats produce constantly. Recording it as a
    -- draw rather than a dispute is the difference between rewarding modesty
    -- and punishing it.
    --
    -- The mirror image — home 'win' AND away 'loss', both CLAIMING the victory
    -- — falls through to the dispute branch below, which is where it belongs.
    IF rh.result = 'loss' AND ra.result = 'win' THEN
        IF rh.is_forfeit AND ra.is_forfeit THEN
            -- Both reported that their OWN side never turned up, so there was
            -- no match. Logged for both lobbies, unrated: there is no rating
            -- information in a game nobody played.
            PERFORM public.fn_settle_friendly_challenge(
                p_challenge_id, 'practice', 'mutual_concession', NULL, NULL,
                'Cả hai đội đều báo không có mặt');
            RETURN 'no_match';
        END IF;

        -- A plain draw, deliberately: it already favours the away side and the
        -- lower-rated side, and it does so through the SAME home-advantage
        -- constant the Discover card's favorability was computed from. At equal
        -- MMR home's expected score is 0.571 and away's 0.429, so a draw moves
        -- home down and away up without a single line of special-case rating
        -- code. Sets are dropped: two reports that disagree on who won have no
        -- scoreline anyone agreed to.
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
GRANT EXECUTE ON FUNCTION public.report_match_result(uuid, text, jsonb, uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. Read model
-- ─────────────────────────────────────────────────────────────────────────────
-- `my_report` is the caller's own row only while the match is unresolved; the
-- opponent's is withheld by the same rule RLS enforces on the table, so a
-- client that forgot to hide it still cannot leak it.
--
-- CRITICAL: every result in this schema is stored in the HOME frame, because
-- one physical row has to read correctly from both ends (see
-- lobby_match_history_data). `my_report` is therefore FLIPPED back into the
-- caller's own frame before it leaves here — an away manager who reported "we
-- lost" stored 'win' (home won), and handing them that value would render their
-- own report as a victory. Nothing outside this function should ever have to
-- know which frame a result is in; if a new field carries a result, flip it
-- here too.
CREATE OR REPLACE FUNCTION public.friendly_challenge_data(p_lobby_id uuid)
RETURNS TABLE(
    id uuid, direction text, other_lobby_id uuid, other_lobby_name text,
    other_lobby_mmr integer, other_lobby_trust integer,
    sport_id bigint, status public.lobby_challenge_status, we_are_home boolean,
    proposed_time timestamptz, proposed_location_name text,
    venue_cost numeric, cost_split public.challenge_cost_split,
    bounty_kind public.challenge_bounty_kind, bounty_amount numeric,
    ruleset public.challenge_ruleset, ruleset_param smallint,
    handicap_side public.challenge_handicap_side, handicap_amount smallint,
    terms_note text, note text, activity_id uuid,
    going_count integer, confirmation_threshold integer,
    my_report public.lobby_match_result, my_report_forfeit boolean,
    opponent_reported boolean,
    no_show_claimed_by uuid, no_show_claimed_at timestamptz,
    created_at timestamptz)
    LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $$
    SELECT c.id,
           CASE WHEN c.initiator_lobby_id = p_lobby_id THEN 'outgoing' ELSE 'incoming' END,
           CASE WHEN c.initiator_lobby_id = p_lobby_id THEN c.target_lobby_id
                ELSE c.initiator_lobby_id END,
           ol.name, ol.mmr, ol.trust_score,
           c.sport_id, c.status, (c.target_lobby_id = p_lobby_id),
           c.proposed_time,
           (SELECT loc.name FROM public.location loc WHERE loc.id = c.proposed_location),
           c.venue_cost, c.cost_split, c.bounty_kind, c.bounty_amount,
           c.ruleset, c.ruleset_param, c.handicap_side, c.handicap_amount,
           c.terms_note, c.note,
           (SELECT a.id FROM public.activity a
             WHERE a.challenge_id = c.id AND a.lobby_id = p_lobby_id LIMIT 1),
           (SELECT count(*)::integer FROM public.activity_confirmation ac
             JOIN public.activity a ON a.id = ac.activity_id
            WHERE a.challenge_id = c.id AND a.lobby_id = c.initiator_lobby_id
              AND ac.attendance = 'going'),
           (SELECT a.confirmation_threshold FROM public.activity a
             WHERE a.challenge_id = c.id AND a.lobby_id = c.initiator_lobby_id),
           -- Flipped into the caller's frame: 'win' always means "we won".
           (SELECT CASE
                     WHEN c.target_lobby_id = p_lobby_id THEN r.result
                     WHEN r.result = 'win'  THEN 'loss'::public.lobby_match_result
                     WHEN r.result = 'loss' THEN 'win'::public.lobby_match_result
                     ELSE r.result
                   END
              FROM public.lobby_challenge_report r
             WHERE r.challenge_id = c.id AND r.lobby_id = p_lobby_id),
           (SELECT r.is_forfeit FROM public.lobby_challenge_report r
             WHERE r.challenge_id = c.id AND r.lobby_id = p_lobby_id),
           EXISTS (SELECT 1 FROM public.lobby_challenge_report r
                    WHERE r.challenge_id = c.id AND r.lobby_id <> p_lobby_id),
           c.no_show_claimed_by, c.no_show_claimed_at,
           c.created_at
      FROM public.lobby_challenge c
      JOIN public.lobby ol
        ON ol.id = CASE WHEN c.initiator_lobby_id = p_lobby_id
                        THEN c.target_lobby_id ELSE c.initiator_lobby_id END
     WHERE c.mode = 'friendly'
       AND p_lobby_id IN (c.initiator_lobby_id, c.target_lobby_id)
       AND c.status IN ('requested','pending_home','scheduled','no_show_claimed','awaiting_reports')
       -- A 'requested' challenge is a lobby still rounding up its OWN players;
       -- the handshake has not reached home yet and there is nothing for them
       -- to do. Showing it would put a row in home's list that they cannot act
       -- on, and would leak who is merely considering them.
       AND NOT (c.target_lobby_id = p_lobby_id AND c.status = 'requested')
       AND EXISTS (SELECT 1 FROM public.lobby_member lm
                    WHERE lm.lobby_id = p_lobby_id AND lm.user_id = auth.uid())
     ORDER BY c.proposed_time NULLS LAST, c.created_at;
$$;
GRANT EXECUTE ON FUNCTION public.friendly_challenge_data(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. Withdrawing a challenge
-- ─────────────────────────────────────────────────────────────────────────────
-- A challenger commits its own players the moment it sends, so it needs a way
-- back out before the handshake completes — otherwise a lobby that changes its
-- mind is stuck advertising a fixture to its own members until the offer
-- expires. `cancel_challenge` only covers the refereed flow's `requested`
-- state, so friendly gets its own.
--
-- The activity is NOT deleted: its members RSVP'd, and every activity reader
-- derives "dead" from the challenge status.
CREATE OR REPLACE FUNCTION public.cancel_friendly_challenge(p_challenge_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_uid uuid := auth.uid(); c record; v_name text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT * INTO c FROM public.lobby_challenge WHERE id = p_challenge_id FOR UPDATE;
    IF c.id IS NULL OR c.mode <> 'friendly' THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF c.status NOT IN ('requested', 'pending_home') THEN
        RAISE EXCEPTION 'this challenge can no longer be withdrawn';
    END IF;
    IF NOT public.lobby_can_manage(c.initiator_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the challenging lobby';
    END IF;

    UPDATE public.lobby_challenge
       SET status = 'cancelled', updated_at = now() WHERE id = p_challenge_id;

    -- Only tell the home lobby if they had actually been asked. A challenge
    -- withdrawn while still gathering players never reached them, so a push
    -- about it would be the first they ever heard of it.
    IF c.status = 'pending_home' THEN
        SELECT name INTO v_name FROM public.lobby WHERE id = c.initiator_lobby_id;
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT uid FROM (
                SELECT captain_id AS uid FROM public.lobby WHERE id = c.target_lobby_id
                UNION
                SELECT user_id FROM public.lobby_member
                 WHERE lobby_id = c.target_lobby_id AND role = 'coordinator') s),
            'Thách đấu đã rút',
            COALESCE(v_name, 'Đội thách đấu') || ' đã rút lời thách đấu',
            jsonb_build_object('lobby_id', c.target_lobby_id, 'challenge_id', p_challenge_id));
    END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.cancel_friendly_challenge(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.cancel_friendly_challenge(uuid) FROM PUBLIC, anon;
