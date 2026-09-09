-- ============================================================================
-- friendly_challenge_rating.sql — Part D of the friendly-challenge build.
-- Apply AFTER lobby_trust.sql, BEFORE friendly_challenge.sql
-- (fn_settle_friendly_challenge writes lobby_match.result_source).
--
-- Unlocks rating for a match nobody was paid to officiate, and teaches the Elo
-- engine the two outcomes that only exist in friendly mode.
--
-- The constraint this file dismantles, `lobby_match_referee_required_for_scored
-- _challenge`, is what made the referee load-bearing: a win/loss/draw against
-- an opponent lobby was structurally impossible without a booking. It is
-- replaced rather than dropped, because the half of it that still matters is
-- that a row CLAIMING referee provenance must actually have the booking.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

ALTER TABLE public.lobby_match
    ADD COLUMN IF NOT EXISTS result_source public.match_result_source NOT NULL DEFAULT 'referee';

COMMENT ON COLUMN public.lobby_match.result_source IS
'How this result came to be. referee: a hired official recorded it (the '
'flag-gated flow). agreed: both lobbies filed blind reports that matched. '
'one_sided: only one lobby filed by the 24h deadline. forfeit: an uncountered '
'no-show claim. disputed: the two blind reports conflicted.';

ALTER TABLE public.lobby_match
    DROP CONSTRAINT IF EXISTS lobby_match_referee_required_for_scored_challenge;
ALTER TABLE public.lobby_match
    ADD CONSTRAINT lobby_match_referee_required_for_scored_challenge CHECK (
        opponent_lobby_id IS NULL
        OR result = 'practice'
        OR referee_booking_id IS NOT NULL
        OR result_source <> 'referee'
    );

-- A disputed match has no agreed scoreline, same as a practice one.
ALTER TABLE public.lobby_match
    DROP CONSTRAINT IF EXISTS lobby_match_sets_only_when_decided;
ALTER TABLE public.lobby_match
    ADD CONSTRAINT lobby_match_sets_only_when_decided CHECK (
        (result IN ('practice', 'disputed') AND sets IS NULL)
        OR result NOT IN ('practice', 'disputed')
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- Elo
-- ─────────────────────────────────────────────────────────────────────────────
-- Two new branches; everything else — the expected-score formula, the home
-- advantage, the K split, the margin multiplier, the going-RSVP membership
-- rule, the user_rating upsert, the trg_user_rating_recompute MMR cache — is
-- exactly as it was.
--
--   DISPUTED: both sides receive the delta they would have got for LOSING.
--   This deliberately breaks Elo's zero-sum property; a dispute drains rating
--   from the pool rather than moving it. That is the entire deterrent. If a
--   dispute merely voided the match, the losing side would file a false report
--   every single time to escape the hit, and nothing else here would matter.
--   Priced at "never cheaper than losing", it is unprofitable from every angle:
--   a true loser gains nothing, a liar drags themselves down alongside their
--   victim, and a colluding pair cannot farm a lose-lose.
--
--   MUTUAL CONCESSION needs no branch here at all, which is the point. Both
--   sides conceding is settled as a plain 'draw', and a draw already moves home
--   down and away up: v_expected folds in c_home_adv, so at equal MMR home
--   expects 0.571 and away 0.429. The lower-rated side gains more still, since
--   its expected score is lower. "Favours the away and/or lower-rated team"
--   falls out of the arithmetic that was already there.
--
--   FORFEIT: the absent side takes its FULL loss delta — not turning up must
--   not be cheaper than turning up and losing, or every team that expects to
--   lose simply stays home. The side that showed up takes HALF its win delta:
--   driving across town to an empty pitch is worth something, but it is not
--   worth a full win over a team that never played.
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
    c_forfeit_win constant numeric := 0.5;  -- the walkover discount

    v_home     uuid;
    v_away     uuid;
    v_result   public.lobby_match_result;
    v_sets     jsonb;
    v_activity uuid;
    v_source   public.match_result_source;
    v_challenge uuid;
    v_sport    text;
    v_home_mmr integer;
    v_away_mmr integer;
    v_expected numeric;
    v_score    numeric;
    v_margin   numeric := 0;
    v_mult     numeric := 1;
    v_disputed boolean;
    r          record;
BEGIN
    SELECT m.lobby_id, m.opponent_lobby_id, m.result, m.sets, m.activity_id, m.result_source
      INTO v_home, v_away, v_result, v_sets, v_activity, v_source
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

    v_disputed := (v_result = 'disputed');
    v_score := CASE v_result WHEN 'win' THEN 1.0 WHEN 'draw' THEN 0.5 ELSE 0.0 END;

    -- Blowout scaling off the aggregate scoreline. A disputed or forfeited
    -- match has no agreed scoreline to scale by, so it stays at 1.
    IF NOT v_disputed AND v_sets IS NOT NULL AND jsonb_typeof(v_sets) = 'array' THEN
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
               -- A dispute is a loss for BOTH sides: s = 0 either way, so each
               -- side's delta is K·(0 − its own expected score), which is
               -- precisely what it would have lost by.
               CASE WHEN v_disputed THEN 0.0
                    WHEN a.lobby_id = v_home THEN v_score
                    ELSE 1.0 - v_score END AS s,
               CASE WHEN a.lobby_id = v_home THEN v_expected
                    ELSE 1.0 - v_expected END AS e,
               -- Halve only the winner of a walkover. The absent side is
               -- untouched by this and takes the full hit.
               CASE WHEN v_source = 'forfeit'
                     AND ((a.lobby_id = v_home AND v_result = 'win')
                       OR (a.lobby_id = v_away AND v_result = 'loss'))
                    THEN c_forfeit_win ELSE 1.0 END AS forfeit_scale
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
                   * v_mult * r.forfeit_scale * (r.s - r.e))::integer),
               games_played = ur.games_played + 1,
               updated_at = now()
         WHERE ur.user_id = r.user_id AND ur.sport = v_sport AND ur.format IS NULL;
    END LOOP;
    -- Lobby MMR refreshes itself: trg_user_rating_recompute fires on the UPDATE.
END;
$$;

-- The referee is no longer what makes a match rateable. Any scored inter-lobby
-- match rates; `fn_apply_match_rating` still bails on anything without a
-- challenge behind it, so an ordinary lobby activity is unaffected.
DROP TRIGGER IF EXISTS lobby_match_apply_rating ON public.lobby_match;
CREATE TRIGGER lobby_match_apply_rating
    AFTER INSERT ON public.lobby_match
    FOR EACH ROW
    WHEN (NEW.opponent_lobby_id IS NOT NULL
          AND NEW.result <> 'practice')
    EXECUTE FUNCTION public.trg_lobby_match_rating();

REVOKE ALL ON FUNCTION public.fn_apply_match_rating(uuid) FROM PUBLIC, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- History carries the provenance
-- ─────────────────────────────────────────────────────────────────────────────
-- The result flip already handles `disputed` correctly — it falls through the
-- ELSE and reads as itself from both sides, which is exactly right for an
-- outcome that was nobody's win. What the client additionally needs is WHY a
-- rating moved: a disputed match must render as "tranh chấp kết quả — cả hai
-- đội bị tính thua" rather than appearing as an unexplained drop, and a
-- walkover must say so.
DROP FUNCTION IF EXISTS public.lobby_match_history_data(uuid, integer, integer);
CREATE OR REPLACE FUNCTION public.lobby_match_history_data(
    p_lobby_id uuid,
    p_page_size integer DEFAULT 50,
    p_page_number integer DEFAULT 1
) RETURNS TABLE(
    id uuid, activity_id uuid, opponent_lobby_id uuid, opponent_name text,
    opponent_tag text, result public.lobby_match_result, sets jsonb,
    mvp_username character varying, note text, venue_label text,
    played_at timestamp with time zone, duration_label text,
    member_usernames text[], referee_booking_id uuid, referee_name text,
    result_source public.match_result_source
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
           -- 'draw', 'practice' and 'disputed' all read as themselves from
           -- either end; only win/loss invert.
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
           ref.display_name AS referee_name,
           x.result_source
      FROM mine x
      LEFT JOIN public.lobby ol ON ol.id = x.other_id
      LEFT JOIN public."user" u ON u.id = x.mvp_user_id
      LEFT JOIN public.referee_booking rb ON rb.id = x.referee_booking_id
      LEFT JOIN public.professional ref ON ref.id = rb.professional_id
     ORDER BY x.played_at DESC
     LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
GRANT EXECUTE ON FUNCTION public.lobby_match_history_data(uuid, integer, integer) TO authenticated;
