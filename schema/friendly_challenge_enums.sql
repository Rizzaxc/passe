-- ============================================================================
-- friendly_challenge_enums.sql — Part A of the friendly-challenge build.
--
-- The referee-gated challenger flow (lobby_challenge.sql + challenge_flow.sql)
-- cannot record a scored result without a hired referee: the CHECK
-- `lobby_match_referee_required_for_scored_challenge` makes it structurally
-- impossible, and `fn_apply_match_rating` only fires when a booking is present.
-- That couples lobby-vs-lobby play to a marketplace of paid officials that does
-- not exist yet, which is why the whole thing sits behind
-- `ClientFeatureFlags.challengerFlow`.
--
-- The FRIENDLY mode ships first and needs no third party: home posts a fixture,
-- a challenger's own members vote to commit, home picks from whoever is ready,
-- they play, and BOTH sides report the result independently and blind. Matching
-- reports rate the match; conflicting reports cost both lobbies a loss.
--
-- Postgres cannot use an enum value in the same transaction that adds it, so
-- every ADD VALUE lives here and Parts B..F consume them. Apply in order:
--   1. friendly_challenge_enums.sql      (this file)
--   2. friendly_challenge_offer.sql
--   3. lobby_trust.sql                    (trust columns; Part E reads them)
--   4. friendly_challenge_rating.sql      (lobby_match.result_source; ditto)
--   5. friendly_challenge.sql
--   6. friendly_challenge_sweep.sql
--   7. challenge_accept_cost_fix.sql
-- ============================================================================

-- ─── Which state machine a challenge follows ────────────────────────────────
-- 'refereed' is the existing flag-gated flow, untouched. 'friendly' is this
-- build. The two sweeps scope themselves by this column so they can never race
-- on the same row.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lobby_challenge_mode') THEN
    CREATE TYPE public.lobby_challenge_mode AS ENUM ('friendly', 'refereed');
  END IF;
END $$;

-- ─── Challenge lifecycle gains the friendly states ──────────────────────────
--   pending_home     — the challenger's OWN members hit their self-set RSVP
--                      threshold; the handshake is now home's to answer. This
--                      is the step that distinguishes friendly mode: a lobby
--                      commits its people before it ever reaches the opponent.
--   awaiting_reports — played; at least one side has filed a blind result.
--   no_show_claimed  — a manager claimed mid-match that the other side never
--                      turned up; the accused has 10 minutes to counter.
--   disputed         — the two blind reports disagreed, or a no-show claim was
--                      countered. Terminal, and costs BOTH lobbies a loss.
-- ('accepted' stays refereed-only — friendly goes requested → pending_home →
-- scheduled, because home's yes IS the acceptance and needs no second confirm.)
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'pending_home';
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'awaiting_reports';
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'no_show_claimed';
ALTER TYPE public.lobby_challenge_status ADD VALUE IF NOT EXISTS 'disputed';

-- ─── A match result that is nobody's win ────────────────────────────────────
-- `lobby_match_history_data` reads ONE physical row from two directions and
-- flips win↔loss. "Both sides lost" cannot be expressed by a flip, so it needs
-- its own value that reads as itself from either end.
ALTER TYPE public.lobby_match_result ADD VALUE IF NOT EXISTS 'disputed';

-- ─── Offer lifecycle ────────────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lobby_challenge_offer_status') THEN
    CREATE TYPE public.lobby_challenge_offer_status AS ENUM
      ('open', 'taken', 'expired', 'withdrawn');
  END IF;
END $$;

-- ─── Stated terms ───────────────────────────────────────────────────────────
-- The app never moves money (see CLAUDE.md ▸ đá currency is deferred). These
-- are terms the two lobbies agree to and settle off-app; the value of modelling
-- them is that a challenger's members can see what they are signing up to pay
-- BEFORE they RSVP, and that the card renders the same way every time.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'challenge_cost_split') THEN
    CREATE TYPE public.challenge_cost_split AS ENUM
      ('none', 'split_even', 'loser_pays', 'home_pays', 'away_pays');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'challenge_bounty_kind') THEN
    CREATE TYPE public.challenge_bounty_kind AS ENUM
      ('none', 'per_goal_diff', 'fixed_per_team');
  END IF;
END $$;

-- ─── Format ─────────────────────────────────────────────────────────────────
-- Only these five, because everything else collapses into one of them: a
-- rotation is best-of-X with shuffled lineups, and a timed aggregate is what
-- `standard` already means for soccer and basketball.
--   standard         — the sport's normal match
--   best_of_sets     — best of N (param = N). The ONLY format that yields a
--                      set-by-set score, so the only one where
--                      fn_apply_match_rating's margin multiplier stays live.
--   king_of_the_hill — đội thắng giữ sân; a stream of short games, whoever held
--                      the court longer takes it. No fixed count, no set score.
--   team_tie         — N separate singles/doubles rubbers, aggregate decides
--                      (param = rubbers). The club format, and the real answer
--                      to "how do 10-a-side racket lobbies play each other".
--   custom           — free text; requires terms_note.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'challenge_ruleset') THEN
    CREATE TYPE public.challenge_ruleset AS ENUM
      ('standard', 'best_of_sets', 'king_of_the_hill', 'team_tie', 'custom');
  END IF;
END $$;

-- ─── Handicap ───────────────────────────────────────────────────────────────
-- Deliberately NOT a ruleset: a handicap composes with any format. It is also
-- the mechanism that makes an MMR-mismatched fixture worth accepting, which is
-- squarely a matchmaking concern rather than a formatting one.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'challenge_handicap_side') THEN
    CREATE TYPE public.challenge_handicap_side AS ENUM ('none', 'home', 'away');
  END IF;
END $$;

-- ─── How a recorded result came to be ───────────────────────────────────────
-- This is what lets a scored friendly match exist without a referee booking:
-- the CHECK is relaxed for any source that isn't 'referee', while a row that
-- CLAIMS referee provenance still has to have the booking to back it.
--   referee    — the flag-gated flow: a hired official recorded it.
--   agreed     — both lobbies filed blind reports and they matched.
--   one_sided  — only one lobby filed by the 24h deadline; it stands.
--   forfeit    — an uncountered no-show claim.
--   mutual_concession — both lobbies reported losing. Recorded as a draw, not
--                a dispute: two teams each conceding is agreement about the
--                spirit of the thing, not a conflict about the facts. See
--                report_match_result for why this is distinguishable from both
--                sides CLAIMING the win, which is a dispute.
--   disputed   — the two blind reports conflicted.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'match_result_source') THEN
    CREATE TYPE public.match_result_source AS ENUM
      ('referee', 'agreed', 'one_sided', 'forfeit', 'mutual_concession', 'disputed');
  END IF;
END $$;

-- ─── Post-match verdicts ────────────────────────────────────────────────────
-- friendly/fairplay are worth +1 each, the other three −1; there is NO
-- functional difference within either group. The kind exists so the signal is
-- legible on a lobby's profile ("12 thân thiện · 2 smurf") instead of a bare
-- integer, and so `smurfing` is sayable at all — it is the only verdict that
-- accuses the LADDER rather than the conduct, and if it gets used a lot that is
-- the instrument telling you self-declared `elo_seed` is being abused.
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lobby_recommendation_kind') THEN
    CREATE TYPE public.lobby_recommendation_kind AS ENUM
      ('friendly', 'fairplay', 'unfriendly', 'dirty', 'smurfing');
  END IF;
END $$;

-- ─── Notification kinds ─────────────────────────────────────────────────────
-- `match_result_recorded` already exists (challenge_flow_enums.sql) and is
-- reused for the resolved match, so it is not re-added here.
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'challenge_ready_for_home';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'challenge_offer_expired';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'match_result_pending';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'no_show_claimed';
ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'match_disputed';
