-- ============================================================================
-- Rework activity cost: drop the never-built pre-payment/Đá deposit model,
-- replace with a plain informational cost (per-person or total) that's
-- settled *after* the session via the payment-request feature
-- (schema/lobby_payment_requests.sql), not collected up front.
--
-- No data-preservation path for existing prepayment_* rows — dropped as-is.
-- ============================================================================

ALTER TABLE public.activity
    DROP CONSTRAINT IF EXISTS activity_prepayment_terms_validity;

ALTER TABLE public.activity
    DROP COLUMN IF EXISTS prepayment_required,
    DROP COLUMN IF EXISTS payment_type,
    DROP COLUMN IF EXISTS prepayment_amount;

DROP TYPE IF EXISTS public.activity_payment_type;


-- ─── Enum for cost shape ────────────────────────────────────────

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_cost_type') THEN
        CREATE TYPE public.activity_cost_type AS ENUM ('per_pax', 'total');
    END IF;
END
$$;

COMMENT ON TYPE public.activity_cost_type IS
  'per_pax: cost_amount is what each attendee owes. total: cost_amount is split equally (rounded up to the nearest 1000 VND) across confirmed (going) attendees, including the organizer.';


-- ─── activity column additions ─────────────────────────────────

ALTER TABLE public.activity
    ADD COLUMN IF NOT EXISTS cost_type public.activity_cost_type,
    ADD COLUMN IF NOT EXISTS cost_amount numeric(10, 2);

COMMENT ON COLUMN public.activity.cost_amount IS
  'Informational cost, settled post-session by the payment-request feature — not a deposit or a charge at scheduling time.';


-- ─── Constraints ───────────────────────────────────────────────

-- Cost terms are all-or-nothing: type and amount are set together or not at all.
ALTER TABLE public.activity
    DROP CONSTRAINT IF EXISTS activity_cost_validity;
ALTER TABLE public.activity
    ADD CONSTRAINT activity_cost_validity CHECK (
        (cost_type IS NULL) = (cost_amount IS NULL)
        AND (cost_amount IS NULL OR cost_amount > 0)
    );
