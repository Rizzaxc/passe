-- ============================================================================
-- challenge_flow.sql — Part B of the challenger-flow build.
--
-- Apply `challenge_flow_enums.sql` (Part A) FIRST — this file uses the enum
-- values it adds, and Postgres cannot use an enum value in the transaction
-- that creates it.
--
-- What this closes (see the audit in the plan):
--   1. A lobby could never opt in — nothing wrote `open_to_challengers` and
--      `lobby` has no UPDATE policy at all. Opting in is now *publishing an
--      offer* (when / where / cost per team), not flipping a boolean.
--   2. Accepting a challenge was terminal — it flipped a status and pushed a
--      notification. It now materialises a linked, unconfirmed `activity` for
--      each side.
--   3. Recording a challenge match was impossible — the referee-required CHECK
--      demanded a booking the client never set. The referee now records the
--      result; the CHECK is narrowed to *scored* matches ("ref = rated").
--   4. Match history was one-sided and Elo had never moved for any user.
--
-- Every function pins `search_path` to '' and every SECURITY DEFINER one is
-- gated on `lobby_can_manage` / an explicit identity check.
--
-- Follow-up pass (notification-center audit): fn_sweep_challenges' lapse push
-- and record_challenge_match's result push each originally sent ONE shared
-- `lobby_id` to BOTH lobbies' recipients — every recipient's push routed to
-- whichever lobby happened to be named, not their own. Both are now two calls,
-- one per lobby. Also added: `challenge_scheduled` (the real "it's locked in"
-- signal — both sides confirmed), and a challenge-aware guard on
-- fn_emit_activity_confirmed so RSVP quorum alone no longer sends a
-- misleading "it's locked in" push for a challenge activity, whose real
-- "official" also requires a manager confirmation on both sides.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. The offer: opting in means stating when, where and how much
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.lobby
    ADD COLUMN IF NOT EXISTS challenge_offer_time     timestamptz,
    ADD COLUMN IF NOT EXISTS challenge_offer_location uuid REFERENCES public.location(id),
    ADD COLUMN IF NOT EXISTS challenge_offer_cost     numeric(10,2);

COMMENT ON COLUMN public.lobby.challenge_offer_cost IS
    'Cost per team for the offered match, EXCLUDING the referee fee (the referee is hired '
    'separately by the home team and settled out of band). Informational — there is no ledger.';

-- "Open with no terms" is unrepresentable, so no feed card can ever render a
-- blank offer regardless of what a client sends.
ALTER TABLE public.lobby DROP CONSTRAINT IF EXISTS lobby_challenge_offer_complete;
ALTER TABLE public.lobby ADD CONSTRAINT lobby_challenge_offer_complete CHECK (
    NOT open_to_challengers
    OR (challenge_offer_time     IS NOT NULL
        AND challenge_offer_location IS NOT NULL
        AND challenge_offer_cost     IS NOT NULL)
);

-- Kickoff-ordered scan for the stale-offer sweep.
CREATE INDEX IF NOT EXISTS lobby_challenge_offer_time_idx
    ON public.lobby (challenge_offer_time)
    WHERE open_to_challengers;

-- Publish / edit / withdraw the offer. Manage tier (captain OR coordinator) —
-- the same tier that answers challenges. Deliberately NOT folded into
-- `update_lobby`, which is captain-only and therefore the wrong gate.
CREATE OR REPLACE FUNCTION public.set_lobby_challenge_offer(
    p_lobby_id uuid,
    p_open     boolean,
    p_time     timestamptz DEFAULT NULL,
    p_location uuid        DEFAULT NULL,
    p_cost     numeric     DEFAULT NULL
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF NOT public.lobby_can_manage(p_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;

    IF p_open THEN
        IF p_time IS NULL OR p_location IS NULL OR p_cost IS NULL THEN
            RAISE EXCEPTION 'an open challenge offer needs a time, a location and a cost';
        END IF;
        IF p_time <= now() THEN
            RAISE EXCEPTION 'the offered kickoff is in the past';
        END IF;
        IF p_cost < 0 THEN
            RAISE EXCEPTION 'cost cannot be negative';
        END IF;

        UPDATE public.lobby
           SET open_to_challengers    = true,
               challenge_offer_time     = p_time,
               challenge_offer_location = p_location,
               challenge_offer_cost     = p_cost
         WHERE id = p_lobby_id;
    ELSE
        -- Withdrawing clears the terms too, so a stale offer can't linger
        -- behind an unchecked box and reappear on the next open.
        UPDATE public.lobby
           SET open_to_challengers    = false,
               challenge_offer_time     = NULL,
               challenge_offer_location = NULL,
               challenge_offer_cost     = NULL
         WHERE id = p_lobby_id;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_lobby_challenge_offer(uuid, boolean, timestamptz, uuid, numeric)
    TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Challenges snapshot the offer; activities link back to the challenge
-- ─────────────────────────────────────────────────────────────────────────────

-- The agreed price travels with the challenge, so a manager editing the lobby's
-- offer afterwards cannot silently rewrite the terms an in-flight challenge was
-- sent under. (`proposed_time` / `proposed_location` already exist and were
-- never populated — they become the rest of that snapshot.)
ALTER TABLE public.lobby_challenge
    ADD COLUMN IF NOT EXISTS agreed_cost numeric(10,2);

ALTER TABLE public.activity
    ADD COLUMN IF NOT EXISTS challenge_id uuid REFERENCES public.lobby_challenge(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS manager_confirmed_at timestamptz;

COMMENT ON COLUMN public.activity.manager_confirmed_at IS
    'A challenge activity becomes official on RSVP quorum AND an explicit manager confirmation; '
    'this is the second half. NULL on ordinary activities, whose "official" is derived from the '
    'going-count vs confirmation_threshold alone.';

CREATE INDEX IF NOT EXISTS activity_challenge_idx
    ON public.activity (challenge_id) WHERE challenge_id IS NOT NULL;

-- Both sides of a played match are read back by lobby; the opponent direction
-- had no index.
CREATE INDEX IF NOT EXISTS lobby_match_opponent_idx
    ON public.lobby_match (opponent_lobby_id, played_at DESC)
    WHERE opponent_lobby_id IS NOT NULL;

-- How many *rated* matches a lobby has played, cached on the row. The feed
-- needs it to mark an MMR as provisional, and the feed RPC is SECURITY INVOKER
-- by design — a live count there would be silently zeroed by lobby_match's RLS
-- for every lobby the caller isn't a member of. Same cache-and-trigger shape as
-- `mmr` / `member_count` in challenger_support.sql, for the same reason.
ALTER TABLE public.lobby
    ADD COLUMN IF NOT EXISTS rated_match_count integer NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION public.fn_lobby_recompute_rated_matches(p_lobby_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    IF p_lobby_id IS NULL THEN RETURN; END IF;
    UPDATE public.lobby l
       SET rated_match_count = (
            SELECT count(*) FROM public.lobby_match m
             WHERE m.result <> 'practice'
               AND (m.lobby_id = p_lobby_id OR m.opponent_lobby_id = p_lobby_id))
     WHERE l.id = p_lobby_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_lobby_match_rated_count()
    RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    IF TG_OP <> 'INSERT' THEN
        PERFORM public.fn_lobby_recompute_rated_matches(OLD.lobby_id);
        PERFORM public.fn_lobby_recompute_rated_matches(OLD.opponent_lobby_id);
    END IF;
    IF TG_OP <> 'DELETE' THEN
        PERFORM public.fn_lobby_recompute_rated_matches(NEW.lobby_id);
        PERFORM public.fn_lobby_recompute_rated_matches(NEW.opponent_lobby_id);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS lobby_match_rated_count ON public.lobby_match;
CREATE TRIGGER lobby_match_rated_count
    AFTER INSERT OR UPDATE OR DELETE ON public.lobby_match
    FOR EACH ROW EXECUTE FUNCTION public.trg_lobby_match_rated_count();

REVOKE ALL ON FUNCTION public.fn_lobby_recompute_rated_matches(uuid) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trg_lobby_match_rated_count()          FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. send_challenge — accept the home team's stated terms
-- ─────────────────────────────────────────────────────────────────────────────
-- The challenger no longer proposes a time: the target published an offer and
-- this is a taker. `p_proposed_time` is gone from the signature.
DROP FUNCTION IF EXISTS public.send_challenge(uuid, uuid, timestamptz, text);

CREATE OR REPLACE FUNCTION public.send_challenge(
    p_initiator_lobby uuid,
    p_target_lobby    uuid,
    p_note            text DEFAULT NULL
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid          uuid := auth.uid();
    v_sport        bigint;
    v_target_open  boolean;
    v_target_sport bigint;
    v_offer_time   timestamptz;
    v_offer_loc    uuid;
    v_offer_cost   numeric;
    v_id           uuid;
    v_recipients   uuid[];
    v_init_name    text;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_initiator_lobby = p_target_lobby THEN
        RAISE EXCEPTION 'cannot challenge your own lobby';
    END IF;
    IF NOT public.lobby_can_manage(p_initiator_lobby, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the initiating lobby';
    END IF;

    SELECT sport_id INTO v_sport FROM public.lobby WHERE id = p_initiator_lobby;
    SELECT open_to_challengers, sport_id,
           challenge_offer_time, challenge_offer_location, challenge_offer_cost
      INTO v_target_open, v_target_sport, v_offer_time, v_offer_loc, v_offer_cost
      FROM public.lobby WHERE id = p_target_lobby;

    IF v_target_sport IS NULL THEN RAISE EXCEPTION 'target lobby not found'; END IF;
    IF v_sport IS DISTINCT FROM v_target_sport THEN RAISE EXCEPTION 'sport mismatch'; END IF;
    IF NOT COALESCE(v_target_open, false) THEN
        RAISE EXCEPTION 'target lobby is not open to challengers';
    END IF;
    IF v_offer_time <= now() THEN
        RAISE EXCEPTION 'that offer has expired';
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.lobby_challenge
        WHERE initiator_lobby_id = p_initiator_lobby
          AND target_lobby_id = p_target_lobby
          AND status = 'requested'
    ) THEN
        RAISE EXCEPTION 'a challenge is already pending for this lobby';
    END IF;

    INSERT INTO public.lobby_challenge
        (initiator_lobby_id, target_lobby_id, sport_id,
         proposed_time, proposed_location, agreed_cost, note)
    VALUES (p_initiator_lobby, p_target_lobby, v_sport,
            v_offer_time, v_offer_loc, v_offer_cost, p_note)
    RETURNING id INTO v_id;

    SELECT array_agg(uid) INTO v_recipients FROM (
        SELECT captain_id AS uid FROM public.lobby WHERE id = p_target_lobby
        UNION
        SELECT user_id FROM public.lobby_member
            WHERE lobby_id = p_target_lobby AND role = 'coordinator'
    ) s;

    SELECT name INTO v_init_name FROM public.lobby WHERE id = p_initiator_lobby;

    PERFORM public.fn_enqueue_notification(
        'challenge_received',
        v_recipients,
        'Lời thách đấu mới',
        COALESCE(v_init_name, 'Một đội') || ' muốn thách đấu với bạn',
        jsonb_build_object('lobby_id', p_target_lobby, 'challenge_id', v_id)
    );

    RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_challenge(uuid, uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. respond_challenge — accepting materialises the match
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.respond_challenge(
    p_challenge_id uuid,
    p_action       text
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    -- The offer states a kickoff, not a duration; 90 minutes covers a soccer
    -- match and comfortably covers a racket session. It only drives end_time,
    -- which gates the referee's result entry and the post-match sweep — the
    -- referee's own booking carries the real billed window.
    c_match_minutes constant integer := 90;
    v_uid         uuid := auth.uid();
    v_init        uuid;
    v_target      uuid;
    v_status      public.lobby_challenge_status;
    v_sport       bigint;
    v_time        timestamptz;
    v_loc         uuid;
    v_cost        numeric;
    v_target_name text;
    v_init_name   text;
    v_recipients  uuid[];
    v_deadline    timestamptz;
    v_end         timestamptz;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT initiator_lobby_id, target_lobby_id, status, sport_id,
           proposed_time, proposed_location, agreed_cost
      INTO v_init, v_target, v_status, v_sport, v_time, v_loc, v_cost
      FROM public.lobby_challenge WHERE id = p_challenge_id;

    IF v_init IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF NOT public.lobby_can_manage(v_target, v_uid) THEN
        RAISE EXCEPTION 'not a manager of the target lobby';
    END IF;
    IF v_status <> 'requested' THEN RAISE EXCEPTION 'challenge is no longer open'; END IF;

    SELECT name INTO v_target_name FROM public.lobby WHERE id = v_target;
    SELECT name INTO v_init_name   FROM public.lobby WHERE id = v_init;

    IF p_action = 'accept' THEN
        IF v_time <= now() THEN RAISE EXCEPTION 'that kickoff has already passed'; END IF;

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
        INSERT INTO public.activity
            (user_id, sport_id, lobby_id, challenge_id, start_time, end_time, location_id,
             prepayment_required, payment_type, prepayment_amount,
             confirmation_threshold, confirmation_deadline)
        SELECT l.captain_id, v_sport, l.id, p_challenge_id, v_time, v_end, v_loc,
               (COALESCE(v_cost, 0) > 0),
               CASE WHEN COALESCE(v_cost, 0) > 0 THEN 'manual'::public.activity_payment_type END,
               CASE WHEN COALESCE(v_cost, 0) > 0 THEN v_cost END,
               GREATEST(2, ceil(l.member_count / 2.0)::integer),
               v_deadline
          FROM public.lobby l
         WHERE l.id IN (v_init, v_target);

        -- The offer is consumed: clear it and drop the target's other pending
        -- challenges, so one lobby can't accept five matches for one evening.
        UPDATE public.lobby
           SET open_to_challengers    = false,
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

        -- Surface it in both lobby feeds, same shape the scheduling flow posts.
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

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Manager confirmation — quorum alone doesn't make a challenge official
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.confirm_challenge_activity(p_activity_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid       uuid := auth.uid();
    v_lobby     uuid;
    v_challenge uuid;
    v_threshold integer;
    v_going     integer;
    v_pending   integer;
    v_init      uuid;
    v_target    uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT lobby_id, challenge_id, confirmation_threshold
      INTO v_lobby, v_challenge, v_threshold
      FROM public.activity WHERE id = p_activity_id;

    IF v_challenge IS NULL THEN RAISE EXCEPTION 'not a challenge activity'; END IF;
    IF NOT public.lobby_can_manage(v_lobby, v_uid) THEN
        RAISE EXCEPTION 'not a manager of this lobby';
    END IF;

    SELECT count(*) INTO v_going
      FROM public.activity_confirmation
     WHERE activity_id = p_activity_id AND attendance = 'going';

    IF v_threshold IS NOT NULL AND v_going < v_threshold THEN
        RAISE EXCEPTION 'not enough confirmations yet (% of %)', v_going, v_threshold;
    END IF;

    UPDATE public.activity
       SET manager_confirmed_at = now()
     WHERE id = p_activity_id AND manager_confirmed_at IS NULL;

    -- Locked in only once BOTH sides have confirmed.
    SELECT count(*) INTO v_pending
      FROM public.activity
     WHERE challenge_id = v_challenge AND manager_confirmed_at IS NULL;

    IF v_pending = 0 THEN
        UPDATE public.lobby_challenge
           SET status = 'scheduled', updated_at = now()
         WHERE id = v_challenge AND status = 'accepted'
        RETURNING initiator_lobby_id, target_lobby_id INTO v_init, v_target;

        -- This is the real "it's locked in" moment for a challenge — quorum
        -- alone (fn_emit_activity_confirmed, guarded off challenge activities
        -- below) isn't, since a manager still has to confirm and the other
        -- lobby might not have quorum yet. Two calls, one per lobby, each
        -- carrying that lobby's OWN id — a single shared lobby_id would route
        -- one side's push straight to their opponent's lobby.
        IF v_init IS NOT NULL THEN
            PERFORM public.fn_enqueue_notification(
                'challenge_scheduled',
                ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_init),
                'Trận đấu đã được chốt',
                'Cả hai đội đã xác nhận — trận thách đấu chính thức được lên lịch',
                jsonb_build_object('lobby_id', v_init, 'challenge_id', v_challenge));
            PERFORM public.fn_enqueue_notification(
                'challenge_scheduled',
                ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_target),
                'Trận đấu đã được chốt',
                'Cả hai đội đã xác nhận — trận thách đấu chính thức được lên lịch',
                jsonb_build_object('lobby_id', v_target, 'challenge_id', v_challenge));

            -- Mirrors the accept-time feed item in respond_challenge — the
            -- next entry in the same scheduling lifecycle (not a match
            -- outcome), so it belongs in the lobby feed the way schedule/
            -- reschedule/cancel already do.
            INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
            SELECT l.id, l.captain_id, 'update',
                   jsonb_build_object(
                       'title', 'Trận đấu đã được chốt',
                       'kind',  'match_confirmed',
                       'tone',  'green',
                       'fields', jsonb_build_array(
                           jsonb_build_array('Trạng thái', 'Cả hai đội đã xác nhận')))
              FROM public.lobby l
             WHERE l.id IN (v_init, v_target);
        END IF;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.confirm_challenge_activity(uuid) TO authenticated;

-- fn_emit_activity_confirmed (originally defined in push_notifications.sql)
-- fires on RSVP quorum for ANY activity — but for a challenge activity, quorum
-- is only half of "official" (the manager still has to confirm, per both
-- sides, above). Redefined here, challenge-aware: skip it entirely for a
-- challenge activity and let confirm_challenge_activity's `challenge_scheduled`
-- push be the one true "it's locked in" signal instead of a premature,
-- misleading "Hoạt động đã được chốt".
CREATE OR REPLACE FUNCTION public.fn_emit_activity_confirmed()
    RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_threshold  int;
    v_lobby_id   uuid;
    v_challenge  uuid;
    v_going      int;
    v_recipients uuid[];
    v_lobby_name text;
BEGIN
    SELECT a.confirmation_threshold, a.lobby_id, a.challenge_id
        INTO v_threshold, v_lobby_id, v_challenge
        FROM public.activity a
        WHERE a.id = NEW.activity_id;

    IF v_threshold IS NULL OR v_lobby_id IS NULL OR v_challenge IS NOT NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.attendance <> 'going' THEN
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' AND OLD.attendance = 'going' THEN
        RETURN NEW;
    END IF;

    SELECT count(*) FILTER (WHERE attendance = 'going') INTO v_going
        FROM public.activity_confirmation
        WHERE activity_id = NEW.activity_id;

    IF v_going <> v_threshold THEN
        RETURN NEW;
    END IF;

    SELECT array_agg(lm.user_id) INTO v_recipients
        FROM public.lobby_member lm
        WHERE lm.lobby_id = v_lobby_id;

    SELECT l.name INTO v_lobby_name FROM public.lobby l WHERE l.id = v_lobby_id;

    PERFORM public.fn_enqueue_notification(
        'activity_confirmed',
        v_recipients,
        'Hoạt động đã được chốt',
        COALESCE(v_lobby_name, 'Lobby') || ' đã đủ người tham gia',
        jsonb_build_object('lobby_id', v_lobby_id, 'activity_id', NEW.activity_id)
    );

    RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. "ref = rated" — narrow the CHECK that made challenge matches unrecordable
-- ─────────────────────────────────────────────────────────────────────────────
-- Old rule: any match naming an opponent lobby required a referee booking,
-- which no client code path could ever satisfy. New rule: only a *scored* one
-- does. An unrefereed challenge is still logged for both sides as a played
-- encounter with no score (result = 'practice', sets NULL) and moves no rating.
ALTER TABLE public.lobby_match
    DROP CONSTRAINT IF EXISTS lobby_match_referee_required_for_challenge;
ALTER TABLE public.lobby_match
    ADD CONSTRAINT lobby_match_referee_required_for_scored_challenge CHECK (
        opponent_lobby_id IS NULL
        OR result = 'practice'
        OR referee_booking_id IS NOT NULL
    );

-- `sets` stay meaningless on a scoreless encounter; a draw carries them.
ALTER TABLE public.lobby_match DROP CONSTRAINT IF EXISTS lobby_match_sets_only_when_decided;
ALTER TABLE public.lobby_match ADD CONSTRAINT lobby_match_sets_only_when_decided CHECK (
    (result = 'practice' AND sets IS NULL) OR result <> 'practice'
);

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. The referee records the result
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.record_challenge_match(
    p_challenge_id uuid,
    p_result       text,                 -- 'win' | 'loss' | 'draw', from the HOME side
    p_sets         jsonb DEFAULT NULL,   -- [[home, away], …]
    p_mvp_user_id  uuid  DEFAULT NULL,
    p_note         text  DEFAULT NULL
) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid        uuid := auth.uid();
    v_home       uuid;
    v_away       uuid;
    v_status     public.lobby_challenge_status;
    v_home_act   uuid;
    v_end        timestamptz;
    v_start      timestamptz;
    v_ref_book   uuid;
    v_venue      text;
    v_match      uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;
    IF p_result NOT IN ('win', 'loss', 'draw') THEN
        RAISE EXCEPTION 'invalid result %', p_result;
    END IF;

    SELECT target_lobby_id, initiator_lobby_id, status
      INTO v_home, v_away, v_status
      FROM public.lobby_challenge WHERE id = p_challenge_id;
    IF v_home IS NULL THEN RAISE EXCEPTION 'challenge not found'; END IF;
    IF v_status = 'played' THEN RAISE EXCEPTION 'this match already has a result'; END IF;
    IF v_status NOT IN ('accepted', 'scheduled') THEN
        RAISE EXCEPTION 'challenge is not in a playable state';
    END IF;

    SELECT a.id, a.start_time, a.end_time, a.referee_booking_id
      INTO v_home_act, v_start, v_end, v_ref_book
      FROM public.activity a
     WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_home;

    IF v_ref_book IS NULL THEN
        -- Fall back to the away side, in case the booking was attached there.
        SELECT a.referee_booking_id INTO v_ref_book
          FROM public.activity a
         WHERE a.challenge_id = p_challenge_id AND a.lobby_id = v_away
           AND a.referee_booking_id IS NOT NULL;
    END IF;
    IF v_ref_book IS NULL THEN
        RAISE EXCEPTION 'no referee is booked for this match';
    END IF;

    -- Only the booked referee writes the score.
    IF NOT EXISTS (
        SELECT 1
          FROM public.professional_booking pb
          JOIN public.professional pr ON pr.id = pb.professional_id
         WHERE pb.id = v_ref_book AND pr.linked_user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'only the booked referee can record this result';
    END IF;

    IF COALESCE(v_end, v_start) > now() THEN
        RAISE EXCEPTION 'the match has not finished yet';
    END IF;

    SELECT loc.name INTO v_venue
      FROM public.activity a
      LEFT JOIN public.location loc ON loc.id = a.location_id
     WHERE a.id = v_home_act;

    -- One row, read from both sides (see lobby_match_history_data).
    INSERT INTO public.lobby_match
        (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result, sets,
         mvp_user_id, note, venue_label, played_at, referee_booking_id)
    VALUES (v_home, v_home_act, v_away,
            COALESCE((SELECT name FROM public.lobby WHERE id = v_away), '—'),
            p_result::public.lobby_match_result, p_sets,
            p_mvp_user_id, p_note, COALESCE(v_venue, '—'),
            COALESCE(v_start, now()), v_ref_book)
    RETURNING id INTO v_match;

    UPDATE public.lobby_challenge
       SET status = 'played', updated_at = now() WHERE id = p_challenge_id;

    -- Two calls, one per lobby, each carrying its OWN lobby_id — a single
    -- shared lobby_id would route the away side's push into the home lobby.
    PERFORM public.fn_enqueue_notification(
        'match_result_recorded',
        ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_home),
        'Kết quả trận đấu',
        'Trọng tài đã ghi nhận kết quả trận thách đấu',
        jsonb_build_object('lobby_id', v_home, 'challenge_id', p_challenge_id));
    PERFORM public.fn_enqueue_notification(
        'match_result_recorded',
        ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = v_away),
        'Kết quả trận đấu',
        'Trọng tài đã ghi nhận kết quả trận thách đấu',
        jsonb_build_object('lobby_id', v_away, 'challenge_id', p_challenge_id));

    RETURN v_match;
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_challenge_match(uuid, text, jsonb, uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. Elo — the propagation `challenger_support.sql` deferred
-- ─────────────────────────────────────────────────────────────────────────────
-- Player Elo has never moved: `fn_seed_initial_elo` writes it once from the
-- self-declared elo_seed and nothing else ever touched it, so every lobby's MMR
-- (and the feed's whole favorability ranking) was a function of what members
-- claimed at signup. This is the write side.
--
-- Rated only when a referee scored it. Everyone who RSVP'd `going` on their
-- side's activity moves by the SAME delta — attendance is RSVP intent, there is
-- no check-in, so that is the only "who played" signal that exists.
CREATE OR REPLACE FUNCTION public.fn_apply_match_rating(p_match_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    -- Tunables. c_home_adv MUST match home_challenger_lobby_data's constant —
    -- the rating has to honour the favorability the card promised.
    c_home_adv    constant integer := 50;
    c_k_new       constant numeric := 32;   -- provisional (< c_provisional games)
    c_k_settled   constant numeric := 20;
    c_provisional constant integer := 10;
    c_margin_cap  constant numeric := 2.0;

    v_home     uuid;
    v_away     uuid;
    v_result   public.lobby_match_result;
    v_sets     jsonb;
    v_activity uuid;
    v_challenge uuid;
    v_sport    text;
    v_home_mmr integer;
    v_away_mmr integer;
    v_expected numeric;
    v_score    numeric;
    v_margin   numeric := 0;
    v_mult     numeric := 1;
    v_delta    numeric;
    r          record;
BEGIN
    SELECT m.lobby_id, m.opponent_lobby_id, m.result, m.sets, m.activity_id
      INTO v_home, v_away, v_result, v_sets, v_activity
      FROM public.lobby_match m WHERE m.id = p_match_id;

    IF v_away IS NULL OR v_result = 'practice' THEN RETURN; END IF;

    SELECT challenge_id INTO v_challenge FROM public.activity WHERE id = v_activity;
    IF v_challenge IS NULL THEN RETURN; END IF;

    -- Read both MMRs BEFORE any elo write, or the second lobby would be rated
    -- against a cache the first lobby's update already moved.
    SELECT public.fn_sport_name(sport_id), mmr INTO v_sport, v_home_mmr
      FROM public.lobby WHERE id = v_home;
    SELECT mmr INTO v_away_mmr FROM public.lobby WHERE id = v_away;
    IF v_sport IS NULL THEN RETURN; END IF;

    v_expected := 1.0 / (1.0 + power(10.0,
        ((v_away_mmr - (v_home_mmr + c_home_adv))::numeric / 400.0)));
    v_score := CASE v_result WHEN 'win' THEN 1.0 WHEN 'draw' THEN 0.5 ELSE 0.0 END;

    -- Blowout scaling off the aggregate scoreline.
    IF v_sets IS NOT NULL AND jsonb_typeof(v_sets) = 'array' THEN
        SELECT COALESCE(abs(sum((s->>0)::numeric - (s->>1)::numeric)), 0)
          INTO v_margin
          FROM jsonb_array_elements(v_sets) s;
    END IF;
    IF v_margin > 1 THEN
        v_mult := LEAST(c_margin_cap, 1 + 0.5 * ln(v_margin));
    END IF;

    FOR r IN
        SELECT a.lobby_id,
               ac.user_id,
               CASE WHEN a.lobby_id = v_home THEN v_score ELSE 1.0 - v_score END AS s,
               CASE WHEN a.lobby_id = v_home THEN v_expected ELSE 1.0 - v_expected END AS e
          FROM public.activity a
          JOIN public.activity_confirmation ac ON ac.activity_id = a.id
         WHERE a.challenge_id = v_challenge AND ac.attendance = 'going'
    LOOP
        -- Not ON CONFLICT: the unique key is (user_id, sport, format) and
        -- `format` is NULL here, and NULLs are distinct in a unique index — a
        -- conflict clause would never fire and would quietly duplicate the row.
        -- Same existence-check shape `fn_seed_initial_elo` uses.
        IF NOT EXISTS (
            SELECT 1 FROM public.user_rating
             WHERE user_id = r.user_id AND sport = v_sport AND format IS NULL
        ) THEN
            INSERT INTO public.user_rating (user_id, sport, elo, games_played)
            VALUES (r.user_id, v_sport, 1000, 0);
        END IF;

        UPDATE public.user_rating ur
           SET elo = GREATEST(100, ur.elo + round(
                   (CASE WHEN ur.games_played < c_provisional THEN c_k_new ELSE c_k_settled END)
                   * v_mult * (r.s - r.e))::integer),
               games_played = ur.games_played + 1,
               updated_at = now()
         WHERE ur.user_id = r.user_id AND ur.sport = v_sport AND ur.format IS NULL;
    END LOOP;
    -- Lobby MMR refreshes itself: trg_user_rating_recompute fires on the UPDATE.
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_lobby_match_rating()
    RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    PERFORM public.fn_apply_match_rating(NEW.id);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS lobby_match_apply_rating ON public.lobby_match;
CREATE TRIGGER lobby_match_apply_rating
    AFTER INSERT ON public.lobby_match
    FOR EACH ROW
    WHEN (NEW.opponent_lobby_id IS NOT NULL
          AND NEW.result <> 'practice'
          AND NEW.referee_booking_id IS NOT NULL)
    EXECUTE FUNCTION public.trg_lobby_match_rating();

REVOKE ALL ON FUNCTION public.fn_apply_match_rating(uuid)  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trg_lobby_match_rating()     FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. Both-sided history — one row, two readings
-- ─────────────────────────────────────────────────────────────────────────────
-- The RPC filtered `m.lobby_id = p_lobby_id`, so the opponent saw nothing even
-- though RLS already let them read the row. Rather than write a mirror row that
-- could drift (and that the captain-only UPDATE/DELETE policies would let each
-- side edit independently), the opponent's perspective is applied on read.
CREATE OR REPLACE FUNCTION public.lobby_match_history_data(
    p_lobby_id uuid,
    p_page_size integer DEFAULT 50,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid, activity_id uuid, opponent_lobby_id uuid, opponent_name text,
    opponent_tag text, result public.lobby_match_result, sets jsonb,
    mvp_username character varying, note text, venue_label text,
    played_at timestamp with time zone, duration_label text,
    member_usernames text[], referee_booking_id uuid, referee_name text
)
    LANGUAGE plpgsql SET search_path TO ''
AS $$
BEGIN
    RETURN QUERY
    WITH mine AS (
        -- Rows this lobby recorded: read as-is.
        SELECT m.*, false AS flipped, m.opponent_lobby_id AS other_id
          FROM public.lobby_match m
         WHERE m.lobby_id = p_lobby_id
        UNION ALL
        -- Rows the opponent recorded against us: read from our side.
        SELECT m.*, true AS flipped, m.lobby_id AS other_id
          FROM public.lobby_match m
         WHERE m.opponent_lobby_id = p_lobby_id
    )
    SELECT x.id,
           x.activity_id,
           x.other_id AS opponent_lobby_id,
           ol.name::text AS opponent_name,
           CASE WHEN x.flipped THEN COALESCE(ol.name, x.opponent_tag) ELSE x.opponent_tag END::text,
           CASE WHEN NOT x.flipped THEN x.result
                WHEN x.result = 'win'  THEN 'loss'::public.lobby_match_result
                WHEN x.result = 'loss' THEN 'win'::public.lobby_match_result
                ELSE x.result END AS result,
           CASE WHEN NOT x.flipped OR x.sets IS NULL THEN x.sets
                ELSE (SELECT jsonb_agg(jsonb_build_array(s->1, s->0))
                        FROM jsonb_array_elements(x.sets) s) END AS sets,
           u.username AS mvp_username,
           x.note,
           x.venue_label,
           x.played_at,
           x.duration_label,
           ARRAY(
               -- username is varchar(16); the declared return is text[], and
               -- Postgres will not widen the array element type for us.
               SELECT mu.username::text
                 FROM public.lobby_member lm
                 JOIN public."user" mu ON mu.id = lm.user_id
                WHERE lm.lobby_id = p_lobby_id
           ) AS member_usernames,
           x.referee_booking_id,
           ref.display_name AS referee_name
      FROM mine x
      LEFT JOIN public.lobby ol ON ol.id = x.other_id
      LEFT JOIN public."user" u ON u.id = x.mvp_user_id
      LEFT JOIN public.professional_booking rb ON rb.id = x.referee_booking_id
      LEFT JOIN public.professional ref ON ref.id = rb.professional_id
     ORDER BY x.played_at DESC
     LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 10. Challenge list — carry the agreed terms and the new statuses
-- ─────────────────────────────────────────────────────────────────────────────
DROP FUNCTION IF EXISTS public.lobby_challenge_data(uuid);

CREATE OR REPLACE FUNCTION public.lobby_challenge_data(p_lobby_id uuid)
    RETURNS TABLE(
        id uuid,
        direction text,          -- 'incoming' | 'outgoing'
        other_lobby_id uuid,
        other_lobby_name text,
        other_lobby_mmr integer,
        sport_id bigint,
        status public.lobby_challenge_status,
        proposed_time timestamptz,
        proposed_location_name text,
        agreed_cost numeric,
        note text,
        activity_id uuid,
        referee_booked boolean,
        created_at timestamptz
    )
    LANGUAGE sql STABLE SECURITY INVOKER SET search_path TO ''
AS $$
    SELECT c.id,
           CASE WHEN c.target_lobby_id = p_lobby_id THEN 'incoming' ELSE 'outgoing' END,
           CASE WHEN c.target_lobby_id = p_lobby_id THEN c.initiator_lobby_id ELSE c.target_lobby_id END,
           ol.name, ol.mmr, c.sport_id, c.status, c.proposed_time,
           loc.name::text, c.agreed_cost, c.note,
           mine.id,
           EXISTS (SELECT 1 FROM public.activity a2
                    WHERE a2.challenge_id = c.id AND a2.referee_booking_id IS NOT NULL),
           c.created_at
    FROM public.lobby_challenge c
    JOIN public.lobby ol
        ON ol.id = CASE WHEN c.target_lobby_id = p_lobby_id
                        THEN c.initiator_lobby_id ELSE c.target_lobby_id END
    LEFT JOIN public.location loc ON loc.id = c.proposed_location
    LEFT JOIN public.activity mine
        ON mine.challenge_id = c.id AND mine.lobby_id = p_lobby_id
    WHERE (c.initiator_lobby_id = p_lobby_id OR c.target_lobby_id = p_lobby_id)
      AND c.status IN ('requested', 'accepted', 'scheduled')
    ORDER BY c.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.lobby_challenge_data(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 11. Challenger feed — advertise the offer, stop requiring a homeground
-- ─────────────────────────────────────────────────────────────────────────────
-- Two fixes beyond the new columns: the candidate scan inner-joined `location`
-- on `home_ground`, so a lobby without one was invisible however open it was;
-- and geography keyed off the homeground rather than where the match is
-- actually played. The offer location is now the geographic anchor (the CHECK
-- guarantees it exists whenever a lobby is open), and the homeground is a
-- LEFT JOIN used only as a display label.
DROP FUNCTION IF EXISTS public.home_challenger_lobby_data(
    uuid, bigint, integer, character varying[], text, integer, integer, integer);

CREATE OR REPLACE FUNCTION public.home_challenger_lobby_data(
    p_context_lobby_id uuid,
    p_sport_id bigint,
    p_city integer,
    p_districts character varying[],
    p_search text DEFAULT NULL,
    p_mmr_window integer DEFAULT 200,
    p_page_size integer DEFAULT 10,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid, name text, homeground_name text, playtime jsonb, details jsonb,
    visibility public.lobby_visibility, member_count integer, lobby_mmr integer,
    favorability text, profile_compat_score numeric, match_factors text[],
    offer_time timestamptz, offer_location_name text, offer_cost numeric,
    rated_match_count integer
)
    LANGUAGE plpgsql SET search_path TO ''
AS $$
DECLARE
    c_home_adv  constant integer := 50;
    c_w_compat  constant numeric := 0.6;
    c_w_even    constant numeric := 0.4;
    v_mmr     integer;
    v_net     bigint[];
    v_active  bigint[];
    v_ind     integer[];
    v_pt      text[];
    v_lat     double precision;
    v_lon     double precision;
    v_window  integer := p_mmr_window;
    v_cnt     integer;
BEGIN
    SELECT l.mmr, l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
           loc.lat, loc.lon
      INTO v_mmr, v_net, v_active, v_ind, v_pt, v_lat, v_lon
      FROM public.lobby l
      LEFT JOIN public.location loc ON l.home_ground = loc.id
     WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    -- Tiered widening so a thin pool still returns the nearest opponents.
    SELECT count(*) INTO v_cnt
      FROM public.lobby l
      JOIN public.location oloc ON oloc.id = l.challenge_offer_location
     WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
       AND l.challenge_offer_time > now()
       AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
       AND l.id NOT IN (SELECT public.get_my_lobby_ids())
       AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
       AND (p_search IS NULL OR p_search = ''
            OR l.name ILIKE '%' || p_search || '%'
            OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
            OR l.searchable_id ILIKE '%' || p_search || '%');
    IF v_cnt < p_page_size THEN
        v_window := v_window * 2;
        SELECT count(*) INTO v_cnt
          FROM public.lobby l
          JOIN public.location oloc ON oloc.id = l.challenge_offer_location
         WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
           AND l.challenge_offer_time > now()
           AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
           AND l.id NOT IN (SELECT public.get_my_lobby_ids())
           AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
           AND (p_search IS NULL OR p_search = ''
                OR l.name ILIKE '%' || p_search || '%'
                OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
                OR l.searchable_id ILIKE '%' || p_search || '%');
        IF v_cnt < p_page_size THEN
            v_window := 1000000;
        END IF;
    END IF;

    RETURN QUERY
    WITH candidate AS (
        SELECT
            l.id, l.name, hloc.name AS homeground_name, l.playtime, l.details, l.visibility,
            l.member_count, l.mmr AS cand_mmr,
            l.network_ids, l.active_network_ids, l.industry_ids, l.playtime_keys,
            l.challenge_offer_time, l.challenge_offer_cost, l.rated_match_count,
            oloc.name AS offer_location_name,
            oloc.district, oloc.lat, oloc.lon
        FROM public.lobby l
        JOIN public.location oloc ON oloc.id = l.challenge_offer_location
        LEFT JOIN public.location hloc ON hloc.id = l.home_ground
        WHERE l.sport_id = p_sport_id AND l.open_to_challengers AND l.visibility <> 'private'
          AND l.challenge_offer_time > now()
          AND oloc.city_cluster = p_city AND l.id <> p_context_lobby_id
          AND l.id NOT IN (SELECT public.get_my_lobby_ids())
          AND l.mmr BETWEEN v_mmr - v_window AND v_mmr + v_window
          AND (p_search IS NULL OR p_search = ''
               OR l.name ILIKE '%' || p_search || '%'
               OR extensions.unaccent(l.name) ILIKE '%' || extensions.unaccent(p_search) || '%'
               OR l.searchable_id ILIKE '%' || p_search || '%')
    ),
    scored AS (
        SELECT
            c.*,
            1.0 / (1.0 + power(10.0, ((c.cand_mmr + c_home_adv - v_mmr)::numeric / 400.0))) AS away_expected,
            (c.network_ids && v_net) AS f_network,
            ((SELECT count(*) FROM (SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt)) x) > 0) AS f_playtime,
            ((c.district = ANY(p_districts))
                OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                    AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)) AS f_location,
            (c.industry_ids && v_ind) AS f_industry,
            (
                (CASE WHEN c.network_ids && v_net THEN 3 ELSE 0 END)
              + (CASE WHEN c.active_network_ids && v_active THEN 2 ELSE 0 END)
              + LEAST(2, cardinality(ARRAY(
                    SELECT unnest(c.playtime_keys) INTERSECT SELECT unnest(v_pt))))
              + (CASE WHEN (c.district = ANY(p_districts))
                        OR (v_lat IS NOT NULL AND c.lat IS NOT NULL
                            AND abs(c.lat - v_lat) + abs(c.lon - v_lon) < 0.1)
                      THEN 1 ELSE 0 END)
              + (CASE WHEN c.industry_ids && v_ind THEN 1 ELSE 0 END)
            )::numeric AS compat_raw
        FROM candidate c
    )
    SELECT
        s.id, s.name::text, s.homeground_name::text, s.playtime, s.details, s.visibility,
        s.member_count, s.cand_mmr AS lobby_mmr,
        CASE WHEN s.away_expected > 0.55 THEN 'favored'
             WHEN s.away_expected < 0.45 THEN 'underdog'
             ELSE 'even' END AS favorability,
        (2.5 + (s.compat_raw / 9.0) * 2.5) AS profile_compat_score,
        ARRAY_REMOVE(ARRAY[
            CASE WHEN s.f_network  THEN 'network'  END,
            CASE WHEN s.f_playtime THEN 'playtime' END,
            CASE WHEN s.f_location THEN 'location' END,
            CASE WHEN s.f_industry THEN 'industry' END
        ], NULL) AS match_factors,
        s.challenge_offer_time, s.offer_location_name::text, s.challenge_offer_cost,
        s.rated_match_count
    FROM scored s
    ORDER BY (
        c_w_compat * (s.compat_raw / 9.0)
      + c_w_even * (1.0 - 2.0 * abs(s.away_expected - 0.5))
    ) DESC
    LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;

GRANT EXECUTE ON FUNCTION public.home_challenger_lobby_data(
    uuid, bigint, integer, character varying[], text, integer, integer, integer) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 12. Sweeps — stale offers, lapsed challenges, unrefereed matches
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_sweep_challenges()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    r record;
BEGIN
    -- (a) An offer nobody took, past its own kickoff, would keep advertising a
    --     match in the past. Withdraw it.
    UPDATE public.lobby
       SET open_to_challengers    = false,
           challenge_offer_time     = NULL,
           challenge_offer_location = NULL,
           challenge_offer_cost     = NULL
     WHERE open_to_challengers AND challenge_offer_time <= now();

    -- (b) A challenge whose confirmation deadline passed with a side short of
    --     quorum (or a manager who never confirmed): void both activities.
    FOR r IN
        SELECT c.id, c.initiator_lobby_id, c.target_lobby_id
          FROM public.lobby_challenge c
         WHERE c.status = 'accepted'
           AND EXISTS (
               SELECT 1 FROM public.activity a
                WHERE a.challenge_id = c.id
                  AND a.confirmation_deadline IS NOT NULL
                  AND a.confirmation_deadline <= now()
                  AND a.manager_confirmed_at IS NULL)
    LOOP
        DELETE FROM public.activity WHERE challenge_id = r.id;
        UPDATE public.lobby_challenge
           SET status = 'lapsed', updated_at = now() WHERE id = r.id;

        -- One call per lobby, each carrying its OWN lobby_id — a single
        -- shared lobby_id (as this originally shipped) routed every
        -- initiator-side member's tap straight to the TARGET lobby.
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.initiator_lobby_id),
            'Trận thách đấu bị huỷ',
            'Không đủ xác nhận trước hạn chót nên trận đấu đã bị huỷ',
            jsonb_build_object('lobby_id', r.initiator_lobby_id, 'challenge_id', r.id));
        PERFORM public.fn_enqueue_notification(
            'challenge_lapsed',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.target_lobby_id),
            'Trận thách đấu bị huỷ',
            'Không đủ xác nhận trước hạn chót nên trận đấu đã bị huỷ',
            jsonb_build_object('lobby_id', r.target_lobby_id, 'challenge_id', r.id));

        INSERT INTO public.lobby_feed_item (lobby_id, author_id, kind, payload)
        SELECT l.id, l.captain_id, 'update',
               jsonb_build_object(
                   'title', 'Trận thách đấu bị huỷ',
                   'kind',  'cancelled',
                   'tone',  'crimson',
                   'fields', jsonb_build_array(
                       jsonb_build_array('Lý do', 'Không đủ xác nhận trước hạn chót')))
          FROM public.lobby l
         WHERE l.id IN (r.initiator_lobby_id, r.target_lobby_id);
    END LOOP;

    -- (c) A match that was played but never scored — no referee was booked, or
    --     one was and never recorded. It still happened, so it is logged for
    --     BOTH sides as an encounter with no score, and moves no rating. Doing
    --     this on a timer rather than as a captain action is what keeps one
    --     side from stamping a result into the other's record.
    FOR r IN
        SELECT c.id, c.target_lobby_id AS home, c.initiator_lobby_id AS away,
               a.id AS activity_id, a.start_time, a.location_id
          FROM public.lobby_challenge c
          JOIN public.activity a
            ON a.challenge_id = c.id AND a.lobby_id = c.target_lobby_id
         WHERE c.status IN ('accepted', 'scheduled')
           AND COALESCE(a.end_time, a.start_time) <= now()
           AND NOT EXISTS (SELECT 1 FROM public.lobby_match m WHERE m.activity_id = a.id)
    LOOP
        INSERT INTO public.lobby_match
            (lobby_id, activity_id, opponent_lobby_id, opponent_tag, result,
             venue_label, played_at)
        VALUES (r.home, r.activity_id, r.away,
                COALESCE((SELECT name FROM public.lobby WHERE id = r.away), '—'),
                'practice',
                COALESCE((SELECT name FROM public.location WHERE id = r.location_id), '—'),
                r.start_time);

        UPDATE public.lobby_challenge
           SET status = 'played', updated_at = now() WHERE id = r.id;

        -- Neither lobby was told anything when this shipped — a match that
        -- passed unrefereed just silently turned into a scoreless row. One
        -- call per lobby, its own lobby_id.
        PERFORM public.fn_enqueue_notification(
            'match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.home),
            'Trận đấu đã diễn ra',
            'Không có trọng tài nên trận đấu được ghi nhận nhưng không tính điểm',
            jsonb_build_object('lobby_id', r.home, 'challenge_id', r.id));
        PERFORM public.fn_enqueue_notification(
            'match_result_recorded',
            ARRAY(SELECT user_id FROM public.lobby_member WHERE lobby_id = r.away),
            'Trận đấu đã diễn ra',
            'Không có trọng tài nên trận đấu được ghi nhận nhưng không tính điểm',
            jsonb_build_object('lobby_id', r.away, 'challenge_id', r.id));
    END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.fn_sweep_challenges() FROM PUBLIC, anon, authenticated;

-- Hook into the existing 1-minute tick rather than adding a second cron job.
CREATE OR REPLACE FUNCTION public.fn_cron_tick()
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    PERFORM public.fn_sweep_challenges();
    PERFORM public.fn_process_reminders();
    IF EXISTS (SELECT 1 FROM public.notification_outbox
                WHERE status IN ('pending', 'sending')) THEN
        PERFORM public.fn_invoke_send_push();
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 13. RLS — a referee has to be able to see the match they are officiating
-- ─────────────────────────────────────────────────────────────────────────────
-- `activity` SELECT is owner-or-lobby-member scoped and a hired professional is
-- neither, so the pro-mode card's embed would silently return nothing — the
-- same failure mode that made the activity hero mock data for so long. This is
-- the mirror of the existing policy letting lobby members read the attached
-- booking.
DROP POLICY IF EXISTS "Linked professionals can view their attached activities" ON public.activity;
CREATE POLICY "Linked professionals can view their attached activities"
    ON public.activity FOR SELECT TO authenticated
    USING (
        (referee_booking_id IS NOT NULL OR coach_booking_id IS NOT NULL)
        AND EXISTS (
            SELECT 1
              FROM public.professional_booking pb
              JOIN public.professional pr ON pr.id = pb.professional_id
             WHERE pb.id IN (activity.referee_booking_id, activity.coach_booking_id)
               AND pr.linked_user_id = (SELECT auth.uid())
        )
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- 14. Enable the new notification kinds
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.enabled_notification_kind (kind, enabled) VALUES
    ('challenge_lapsed',      true),
    ('match_result_recorded', true),
    ('challenge_scheduled',   true)
ON CONFLICT (kind) DO UPDATE SET enabled = excluded.enabled, updated_at = now();

-- ─────────────────────────────────────────────────────────────────────────────
-- 15. Backfill the new cached column for existing lobbies
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT id FROM public.lobby LOOP
        PERFORM public.fn_lobby_recompute_rated_matches(r.id);
    END LOOP;
END $$;
