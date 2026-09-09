-- ============================================================================
-- friendly_challenge_offer.sql — Part B of the friendly-challenge build.
-- Apply AFTER friendly_challenge_enums.sql.
--
-- Gives the challenge offer its own identity. It used to be three nullable
-- columns bolted onto `lobby` (challenge_offer_time/_location/_cost) held
-- together by the `lobby_challenge_offer_complete` CHECK, which meant:
--   * one offer per lobby, so a lobby could advertise Saturday OR Sunday,
--     never both;
--   * no id to snapshot, so an in-flight challenge could only reference "the
--     lobby's current terms", which move;
--   * nowhere to put the terms friendly mode actually needs — expiry, format,
--     handicap, who pays for the pitch;
--   * a re-post mutated the row in place, so last week's offer was unknowable.
--
-- This file CREATES and BACKFILLS only. The three `lobby` columns are dropped
-- at the end of Part C, once every reader of them (home_challenger_lobby_data,
-- set_lobby_challenge_offer, send_challenge, respond_challenge) has been
-- rewritten — dropping them here would leave the database broken between two
-- migrations.
--
-- Re-dump schema/passe.sql after applying (do not hand-edit the dump).
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.lobby_challenge_offer (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lobby_id        uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    mode            public.lobby_challenge_mode NOT NULL DEFAULT 'friendly',

    -- 1..3. A lobby may advertise at most three fixtures at once; the slot is
    -- what makes that cap an index rather than a counting trigger (which loses
    -- to a concurrent insert).
    slot            smallint NOT NULL,
    status          public.lobby_challenge_offer_status NOT NULL DEFAULT 'open',

    kickoff         timestamptz NOT NULL,
    location_id     uuid NOT NULL REFERENCES public.location(id),

    -- When the advert stops accepting challengers. Distinct from kickoff on
    -- purpose: a lobby wants to know whether it has a match BEFORE the day
    -- arrives, so it can go find one somewhere else if not.
    expires_at      timestamptz NOT NULL,

    -- Stated terms. The app never moves money (CLAUDE.md ▸ đá currency is
    -- deferred); modelling these buys a card that renders the same way every
    -- time, and a challenger's members seeing what they are committing to pay
    -- before they RSVP rather than after.
    venue_cost      numeric(10,2),
    cost_split      public.challenge_cost_split NOT NULL DEFAULT 'none',
    bounty_kind     public.challenge_bounty_kind NOT NULL DEFAULT 'none',
    bounty_amount   numeric(10,2),

    ruleset         public.challenge_ruleset NOT NULL DEFAULT 'standard',
    ruleset_param   smallint,

    handicap_side   public.challenge_handicap_side NOT NULL DEFAULT 'none',
    handicap_amount smallint,

    terms_note      text,

    created_by      uuid REFERENCES public."user"(id) ON DELETE SET NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),

    -- The +7-day re-post chain. Nothing renews itself: an expired offer pushes
    -- its managers a one-tap "đăng lại tuần sau", and this records what it came
    -- from so the chain is inspectable.
    renewed_from    uuid REFERENCES public.lobby_challenge_offer(id) ON DELETE SET NULL,

    CONSTRAINT lobby_challenge_offer_slot_range
        CHECK (slot BETWEEN 1 AND 3),
    CONSTRAINT lobby_challenge_offer_expiry_before_kickoff
        CHECK (expires_at < kickoff),
    CONSTRAINT lobby_challenge_offer_costs_nonneg
        CHECK ((venue_cost IS NULL OR venue_cost >= 0)
           AND (bounty_amount IS NULL OR bounty_amount >= 0)),

    -- A bounty amount is meaningful only when there is a bounty, and vice
    -- versa: "50k per goal" with kind 'none' would render as nothing.
    CONSTRAINT lobby_challenge_offer_bounty_shape
        CHECK ((bounty_kind = 'none') = (bounty_amount IS NULL)),

    -- Handicap is orthogonal to format and composes with any ruleset, so it
    -- gets its own pair rather than an enum value of its own.
    CONSTRAINT lobby_challenge_offer_handicap_shape
        CHECK ((handicap_side = 'none') = (handicap_amount IS NULL)
               AND (handicap_amount IS NULL OR handicap_amount > 0)),

    -- best_of_sets carries N, team_tie carries the rubber count; the other
    -- three take no number. Enforcing it here means the client can render the
    -- label ("Best of 5 ván") without ever hitting a NULL it has to guess at.
    CONSTRAINT lobby_challenge_offer_ruleset_param_shape
        CHECK (
            CASE ruleset
                WHEN 'best_of_sets' THEN ruleset_param IS NOT NULL AND ruleset_param > 0
                WHEN 'team_tie'     THEN ruleset_param IS NOT NULL AND ruleset_param > 0
                ELSE ruleset_param IS NULL
            END
        ),

    -- A custom format that says nothing is not a format.
    CONSTRAINT lobby_challenge_offer_custom_needs_note
        CHECK (ruleset <> 'custom' OR btrim(coalesce(terms_note, '')) <> ''),

    CONSTRAINT lobby_challenge_offer_note_length
        CHECK (terms_note IS NULL OR char_length(terms_note) <= 280)
);

-- THE 3-slot cap. Partial unique index, so two concurrent publishes into the
-- same slot cannot both win.
CREATE UNIQUE INDEX IF NOT EXISTS lobby_challenge_offer_one_per_slot_idx
    ON public.lobby_challenge_offer (lobby_id, slot)
    WHERE status = 'open';

-- The Discover feed reads open, unexpired offers for a sport; the sweep reads
-- open offers past their expiry.
CREATE INDEX IF NOT EXISTS lobby_challenge_offer_open_idx
    ON public.lobby_challenge_offer (expires_at)
    WHERE status = 'open';
CREATE INDEX IF NOT EXISTS lobby_challenge_offer_lobby_idx
    ON public.lobby_challenge_offer (lobby_id, status);

ALTER TABLE public.lobby_challenge_offer ENABLE ROW LEVEL SECURITY;

-- An offer is a public advert — the same posture `lobby.open_to_challengers`
-- already had, and guests browse Discover.
CREATE POLICY "Enable read access for all users"
    ON public.lobby_challenge_offer FOR SELECT USING (true);

-- Deliberately NO write policies: every mutation goes through a SECURITY
-- DEFINER RPC, matching `lobby_challenge`. The slot cap, the expiry rule and
-- the manage-tier gate are all things a direct client INSERT would bypass.

GRANT SELECT ON TABLE public.lobby_challenge_offer TO anon;
GRANT SELECT ON TABLE public.lobby_challenge_offer TO authenticated;
GRANT ALL    ON TABLE public.lobby_challenge_offer TO service_role;

-- ── Backfill: live refereed offers become slot-1 rows ───────────────────────
-- The old columns are dropped in Part C, not here. `expires_at` has no old
-- equivalent — the previous flow just let a stale offer advertise a match in
-- the past until the sweep withdrew it — so it is derived as kickoff − 24h,
-- clamped to stay in the future for an offer whose kickoff is already close.
INSERT INTO public.lobby_challenge_offer
    (lobby_id, mode, slot, status, kickoff, location_id, expires_at, venue_cost, cost_split)
SELECT l.id,
       'refereed',
       1,
       'open',
       l.challenge_offer_time,
       l.challenge_offer_location,
       GREATEST(l.challenge_offer_time - interval '24 hours',
                LEAST(now() + interval '1 hour', l.challenge_offer_time - interval '1 minute')),
       l.challenge_offer_cost,
       'split_even'
  FROM public.lobby l
 WHERE l.open_to_challengers
   AND l.challenge_offer_time IS NOT NULL
   AND l.challenge_offer_location IS NOT NULL
ON CONFLICT DO NOTHING;

COMMENT ON TABLE public.lobby_challenge_offer IS
'A lobby''s advertised fixture. Up to 3 open at once per lobby (slot 1..3, '
'index-enforced). Replaces lobby.challenge_offer_time/_location/_cost, which '
'could hold exactly one offer with no identity to snapshot and nowhere to put '
'expiry, format or handicap. Public-readable (guests browse Discover); all '
'writes go through SECURITY DEFINER RPCs so the slot cap and the manage-tier '
'gate cannot be bypassed.';
