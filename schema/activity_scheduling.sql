-- ============================================================================
-- Extend `activity` for the "schedule internal play session" flow
--
-- Adds the columns the create-activity form captures: location, prepayment
-- terms, confirmation threshold + deadline, and a weekly-recurrence
-- pattern. Also introduces `activity_confirmation` to track which
-- members have committed (and how much Đá they put down as deposit).
--
-- Recurrence model: one row per series. `recurrence_day_of_week` set
-- means "this is the template for every <weekday>" — occurrences aren't
-- materialised in advance; the app generates the next occurrence from
-- start_time + the day-of-week pattern. Editing a single occurrence in
-- the future will require breaking the link (out of scope here).
-- ============================================================================


-- ─── Enum for payment surface ──────────────────────────────────

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_payment_type') THEN
        CREATE TYPE public.activity_payment_type AS ENUM ('manual', 'da');
    END IF;
END
$$;

COMMENT ON TYPE public.activity_payment_type IS
  'How prepayment for a scheduled activity is collected: ''manual'' = out-of-band (cash / bank transfer organised by the captain); ''da'' = held by the app via the Đá ledger.';


-- ─── activity column additions ─────────────────────────────────

ALTER TABLE public.activity
    -- Where the session is held. Defaults to the lobby's home_ground in
    -- the app layer; nullable at the DB level so off-grid pickup games
    -- still validate.
    ADD COLUMN IF NOT EXISTS location_id uuid
        REFERENCES public.location(id) ON DELETE SET NULL,

    -- Whether members must put down a deposit to confirm attendance.
    ADD COLUMN IF NOT EXISTS prepayment_required boolean
        DEFAULT false NOT NULL,

    -- Only meaningful when prepayment_required = true.
    ADD COLUMN IF NOT EXISTS payment_type public.activity_payment_type,
    ADD COLUMN IF NOT EXISTS prepayment_amount numeric(10, 2),

    -- Minimum number of confirmed members for the activity to become
    -- "official". Captain-set; nullable means "no threshold" (always
    -- official once scheduled).
    ADD COLUMN IF NOT EXISTS confirmation_threshold int,

    -- Cutoff after which no more confirmations are accepted. NULL = no
    -- cutoff (members can confirm right up to start_time).
    ADD COLUMN IF NOT EXISTS confirmation_deadline timestamptz,

    -- Weekly recurrence: 0 = Monday … 6 = Sunday, matching ISO ordering
    -- (Postgres extract(isodow) - 1). NULL = one-off session.
    ADD COLUMN IF NOT EXISTS recurrence_day_of_week smallint;

COMMENT ON COLUMN public.activity.location_id IS
  'Where the session is held. App defaults this to the lobby''s home_ground when creating an activity.';
COMMENT ON COLUMN public.activity.confirmation_threshold IS
  'Minimum confirmed members for the activity to be "official". NULL = no threshold.';
COMMENT ON COLUMN public.activity.confirmation_deadline IS
  'Cutoff for accepting confirmations. NULL = no cutoff. Form defaults this to 2 days before start_time; auto-off when the session is less than 2 days out.';
COMMENT ON COLUMN public.activity.recurrence_day_of_week IS
  'Weekly recurrence anchor (0=Mon … 6=Sun, ISO ordering). NULL = one-off. Recurrence is virtual — occurrences aren''t materialised; the app derives next-occurrence from start_time + this day.';


-- ─── Constraints ───────────────────────────────────────────────

-- Threshold must be positive when set.
ALTER TABLE public.activity
    DROP CONSTRAINT IF EXISTS activity_confirmation_threshold_validity;
ALTER TABLE public.activity
    ADD CONSTRAINT activity_confirmation_threshold_validity CHECK (
        confirmation_threshold IS NULL OR confirmation_threshold > 0
    );

-- Day-of-week within ISO range.
ALTER TABLE public.activity
    DROP CONSTRAINT IF EXISTS activity_recurrence_day_validity;
ALTER TABLE public.activity
    ADD CONSTRAINT activity_recurrence_day_validity CHECK (
        recurrence_day_of_week IS NULL OR (recurrence_day_of_week BETWEEN 0 AND 6)
    );

-- Confirmation deadline must precede start_time (cutoffs after start
-- are nonsensical).
ALTER TABLE public.activity
    DROP CONSTRAINT IF EXISTS activity_confirmation_deadline_validity;
ALTER TABLE public.activity
    ADD CONSTRAINT activity_confirmation_deadline_validity CHECK (
        confirmation_deadline IS NULL OR confirmation_deadline < start_time
    );

-- Prepayment terms are all-or-nothing: if it's required, both the
-- payment surface and the amount must be set; if not, both must be NULL.
ALTER TABLE public.activity
    DROP CONSTRAINT IF EXISTS activity_prepayment_terms_validity;
ALTER TABLE public.activity
    ADD CONSTRAINT activity_prepayment_terms_validity CHECK (
        (prepayment_required = false
            AND payment_type IS NULL
            AND prepayment_amount IS NULL)
        OR
        (prepayment_required = true
            AND payment_type IS NOT NULL
            AND prepayment_amount IS NOT NULL
            AND prepayment_amount > 0)
    );


-- ─── activity_confirmation: who has committed ──────────────────

CREATE TABLE IF NOT EXISTS public.activity_confirmation (
    activity_id uuid NOT NULL
        REFERENCES public.activity(id) ON DELETE CASCADE,
    user_id uuid NOT NULL
        REFERENCES public."user"(id) ON DELETE CASCADE,
    confirmed_at timestamp with time zone DEFAULT now() NOT NULL,
    -- Đá actually held against this confirmation. Always 0 for
    -- 'manual' payment activities and for activities without
    -- prepayment_required.
    deposit_da int DEFAULT 0 NOT NULL CHECK (deposit_da >= 0),
    PRIMARY KEY (activity_id, user_id)
);

COMMENT ON TABLE public.activity_confirmation IS
  'Members who have committed to attending an activity. Row count is compared against activity.confirmation_threshold to determine whether the session is "official". deposit_da records the Đá held when activity.payment_type = ''da''.';

CREATE INDEX IF NOT EXISTS activity_confirmation_user_idx
    ON public.activity_confirmation (user_id);


-- ─── RLS on activity_confirmation ──────────────────────────────

ALTER TABLE public.activity_confirmation ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can read confirmations in their lobby"
    ON public.activity_confirmation;

CREATE POLICY "Members can read confirmations in their lobby"
    ON public.activity_confirmation
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1
            FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );

DROP POLICY IF EXISTS "Members can confirm their own attendance"
    ON public.activity_confirmation;

CREATE POLICY "Members can confirm their own attendance"
    ON public.activity_confirmation
    FOR INSERT
    TO authenticated
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1
            FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );

DROP POLICY IF EXISTS "Members can retract their own confirmation"
    ON public.activity_confirmation;

CREATE POLICY "Members can retract their own confirmation"
    ON public.activity_confirmation
    FOR DELETE
    TO authenticated
    USING (user_id = (SELECT auth.uid()));
