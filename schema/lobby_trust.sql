-- ============================================================================
-- lobby_trust.sql — Part C of the friendly-challenge build.
-- Apply AFTER friendly_challenge_offer.sql, BEFORE friendly_challenge.sql
-- (pending_home_challengers and friendly_challenge_data read trust_score).
--
-- Friendly mode has no referee, so the only thing standing behind a result is
-- the two lobbies' word. TrustScore is what makes that word carry: a public,
-- earned number that says whether a lobby has been worth playing.
--
-- SOCIAL PRESSURE ONLY, this pass. It gates nothing — a low-trust lobby can
-- still post offers, send challenges and report results. It is rendered on the
-- Discover offer card, in the challenges sheet and in home's chooser, which is
-- where it does its work: you see who you are agreeing to meet before you
-- commit your own members to a Saturday.
--
-- Baseline 40. A recommendation is ±2, netted per match and clamped to ±14 so a
-- stacked roster cannot swing more than a well-attended one. A dispute costs 10
-- and DOUBLES on each consecutive one, which is what separates a serial
-- false-reporter from their victims: each victim disputes once and resets on
-- their next clean match, while the offender never gets a clean match and ramps
-- 10 → 20 → 40. Negative means low trust.
-- ============================================================================

ALTER TABLE public.lobby
    ADD COLUMN IF NOT EXISTS trust_score integer NOT NULL DEFAULT 40,
    -- Running total of dispute/no-show penalties. Kept separately from
    -- trust_score so the score can be RECOMPUTED from its two inputs rather
    -- than incrementally mutated — a recommendation being changed inside its
    -- window would otherwise have to guess what it previously contributed.
    ADD COLUMN IF NOT EXISTS dispute_penalty_total integer NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS dispute_streak integer NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.lobby.trust_score IS
'Derived: 40 + Σ(per-match recommendation net, clamped ±14) − dispute_penalty_total. '
'Never written directly — call fn_recompute_lobby_trust. Display only; gates nothing.';

CREATE TABLE IF NOT EXISTS public.lobby_recommendation (
    match_id         uuid NOT NULL REFERENCES public.lobby_match(id) ON DELETE CASCADE,
    voter_id         uuid NOT NULL REFERENCES public."user"(id) ON DELETE CASCADE,
    subject_lobby_id uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    kind             public.lobby_recommendation_kind NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    -- One verdict per person per match. Picking both 'friendly' and 'fairplay'
    -- would be worth +4 and would make the ±14 clamp mean something different
    -- per voter, so the choice is exclusive.
    PRIMARY KEY (match_id, voter_id)
);

CREATE INDEX IF NOT EXISTS lobby_recommendation_subject_idx
    ON public.lobby_recommendation (subject_lobby_id, kind);

ALTER TABLE public.lobby_recommendation ENABLE ROW LEVEL SECURITY;

-- The tallies are public (they are the point). Individual authorship is not
-- hidden either — you are vouching for or against a team you just played, and
-- an anonymous denouncement is a different, worse product.
CREATE POLICY "Enable read access for all users"
    ON public.lobby_recommendation FOR SELECT USING (true);

GRANT SELECT ON TABLE public.lobby_recommendation TO anon;
GRANT SELECT ON TABLE public.lobby_recommendation TO authenticated;
GRANT ALL    ON TABLE public.lobby_recommendation TO service_role;

-- The sign lives here and nowhere else, so a 'smurfing' row can never carry +1.
CREATE OR REPLACE FUNCTION public.fn_recommendation_sign(p_kind public.lobby_recommendation_kind)
RETURNS integer LANGUAGE sql IMMUTABLE SET search_path TO '' AS $$
    SELECT CASE p_kind WHEN 'friendly' THEN 1 WHEN 'fairplay' THEN 1 ELSE -1 END;
$$;

CREATE OR REPLACE FUNCTION public.fn_recompute_lobby_trust(p_lobby_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    UPDATE public.lobby l
       SET trust_score = 40
           + COALESCE((
               -- Net per match FIRST, then clamp, then sum. Clamping the grand
               -- total instead would let one enormous match drown out a season.
               SELECT sum(GREATEST(-14, LEAST(14, per_match)))
                 FROM (SELECT sum(public.fn_recommendation_sign(r.kind)) * 2 AS per_match
                         FROM public.lobby_recommendation r
                        WHERE r.subject_lobby_id = p_lobby_id
                        GROUP BY r.match_id) m
             ), 0)
           - l.dispute_penalty_total
     WHERE l.id = p_lobby_id;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_recompute_lobby_trust(uuid)
    FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.fn_lobby_dispute_penalty(p_lobby_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE v_streak integer;
BEGIN
    SELECT dispute_streak INTO v_streak FROM public.lobby WHERE id = p_lobby_id FOR UPDATE;
    IF v_streak IS NULL THEN RETURN; END IF;

    UPDATE public.lobby
       -- Streak capped at 10 doublings purely so the arithmetic stays in an
       -- integer; a lobby that has disputed ten consecutive matches has long
       -- since made the point.
       SET dispute_penalty_total = dispute_penalty_total + (10 * (2 ^ LEAST(v_streak, 10)))::integer,
           dispute_streak = LEAST(v_streak + 1, 10)
     WHERE id = p_lobby_id;

    PERFORM public.fn_recompute_lobby_trust(p_lobby_id);
END;
$$;
-- Named roles, not just PUBLIC: otherwise any signed-in user could tank an
-- arbitrary lobby's trust score by calling this directly.
REVOKE ALL ON FUNCTION public.fn_lobby_dispute_penalty(uuid)
    FROM PUBLIC, anon, authenticated;

-- The way back. A lobby that had one bad night resets on its next match that
-- ends in agreement; a lobby that keeps disagreeing with everyone never does.
CREATE OR REPLACE FUNCTION public.fn_lobby_dispute_streak_reset(p_lobby_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    UPDATE public.lobby SET dispute_streak = 0
     WHERE id = p_lobby_id AND dispute_streak <> 0;
END;
$$;
REVOKE ALL ON FUNCTION public.fn_lobby_dispute_streak_reset(uuid)
    FROM PUBLIC, anon, authenticated;

-- ─── Casting a verdict ──────────────────────────────────────────────────────
-- Eligibility is the same "who played" predicate fn_apply_match_rating uses:
-- an activity_confirmation of 'going' on YOUR side of this match. There is no
-- check-in in this app, so RSVP intent is the only presence signal that exists.
CREATE OR REPLACE FUNCTION public.recommend_lobby(
    p_match_id         uuid,
    p_subject_lobby_id uuid,
    p_kind             text
) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
DECLARE
    v_uid uuid := auth.uid();
    m record; v_challenge uuid; v_my_lobby uuid;
BEGIN
    IF v_uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

    SELECT lobby_id, opponent_lobby_id, activity_id, created_at
      INTO m FROM public.lobby_match WHERE id = p_match_id;
    IF m.lobby_id IS NULL THEN RAISE EXCEPTION 'match not found'; END IF;
    IF m.opponent_lobby_id IS NULL THEN
        RAISE EXCEPTION 'there is no opponent to vouch for';
    END IF;
    IF p_subject_lobby_id NOT IN (m.lobby_id, m.opponent_lobby_id) THEN
        RAISE EXCEPTION 'that lobby did not play this match';
    END IF;
    IF now() > m.created_at + interval '24 hours' THEN
        RAISE EXCEPTION 'the window to vouch has closed';
    END IF;

    SELECT challenge_id INTO v_challenge FROM public.activity WHERE id = m.activity_id;
    IF v_challenge IS NULL THEN RAISE EXCEPTION 'not a challenge match'; END IF;

    -- Which side was this voter on? Only a 'going' RSVP counts.
    SELECT a.lobby_id INTO v_my_lobby
      FROM public.activity a
      JOIN public.activity_confirmation ac
        ON ac.activity_id = a.id AND ac.user_id = v_uid AND ac.attendance = 'going'
     WHERE a.challenge_id = v_challenge
     LIMIT 1;
    IF v_my_lobby IS NULL THEN
        RAISE EXCEPTION 'only players who confirmed for this match can vouch';
    END IF;
    -- You vouch for the OPPONENT, never your own lobby.
    IF v_my_lobby = p_subject_lobby_id THEN
        RAISE EXCEPTION 'you cannot vouch for your own lobby';
    END IF;

    INSERT INTO public.lobby_recommendation (match_id, voter_id, subject_lobby_id, kind)
    VALUES (p_match_id, v_uid, p_subject_lobby_id, p_kind::public.lobby_recommendation_kind)
    ON CONFLICT (match_id, voter_id) DO UPDATE
        SET kind = EXCLUDED.kind, subject_lobby_id = EXCLUDED.subject_lobby_id,
            created_at = now();

    PERFORM public.fn_recompute_lobby_trust(p_subject_lobby_id);
END;
$$;
GRANT EXECUTE ON FUNCTION public.recommend_lobby(uuid, uuid, text) TO authenticated;

-- The breakdown is the reason the kinds exist at all: "uy tín 46 · 12 thân
-- thiện · 2 smurf" tells a challenger something a single integer cannot.
CREATE OR REPLACE FUNCTION public.lobby_recommendation_counts(p_lobby_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SET search_path TO '' AS $$
    SELECT COALESCE(jsonb_object_agg(kind, n), '{}'::jsonb)
      FROM (SELECT r.kind::text AS kind, count(*) AS n
              FROM public.lobby_recommendation r
             WHERE r.subject_lobby_id = p_lobby_id
             GROUP BY r.kind) s;
$$;
GRANT EXECUTE ON FUNCTION public.lobby_recommendation_counts(uuid) TO anon, authenticated;
