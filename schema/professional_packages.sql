-- Variable lessons/packages: a `professional_service` can now represent a multi-session package
-- (session_count > 1) priced either per-session or as a flat wholesale total. Packages are
-- *rolling*, not booked all-upfront: buying one creates a `professional_booking_package` container
-- row plus exactly one `professional_booking` row (session 1). Once that session completes, the
-- client is prompted to schedule the next one against the same package (see the booking sheet /
-- coaching-section changes) — there is no commitment to future session dates until each is
-- individually scheduled. A package is cancelable at any point; unused sessions just never get
-- created (no refund logic — payment stays informational, same as a plain booking's `agreed_rate`).
--
-- Needs to be applied to the live Supabase project — schema files here are dumped for review, not
-- auto-applied.

-- ── 1. Service-level package fields ─────────────────────────────────────────
ALTER TABLE public.professional_service
    ADD COLUMN IF NOT EXISTS session_count integer NOT NULL DEFAULT 1
        CHECK (session_count >= 1),
    ADD COLUMN IF NOT EXISTS pricing_mode text NOT NULL DEFAULT 'per_session'
        CHECK (pricing_mode IN ('per_session', 'wholesale'));

COMMENT ON COLUMN public.professional_service.session_count IS
    'Number of sessions in this offering. 1 = a plain single booking; >1 = a rolling package.';
COMMENT ON COLUMN public.professional_service.pricing_mode IS
    'per_session: hourly_rate applies per session (x session_count x participants if group).
     wholesale: hourly_rate is treated as one flat total price for the whole package/session.';

-- ── 2. Package container table ──────────────────────────────────────────────
CREATE TABLE public.professional_booking_package (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    client_user_id uuid NOT NULL,
    professional_id uuid NOT NULL,
    service_id uuid NOT NULL,
    sessions_total integer NOT NULL CHECK (sessions_total >= 1),
    sessions_used integer NOT NULL DEFAULT 0 CHECK (sessions_used >= 0),
    total_price numeric(10, 2) CHECK (total_price >= 0),
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled')),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT professional_booking_package_pkey PRIMARY KEY (id),
    CONSTRAINT professional_booking_package_used_le_total_check
        CHECK (sessions_used <= sessions_total),
    CONSTRAINT professional_booking_package_client_user_id_fkey
        FOREIGN KEY (client_user_id) REFERENCES public."user"(id) ON DELETE CASCADE,
    CONSTRAINT professional_booking_package_professional_id_fkey
        FOREIGN KEY (professional_id) REFERENCES public.professional(id) ON DELETE CASCADE,
    CONSTRAINT professional_booking_package_service_id_fkey
        FOREIGN KEY (service_id) REFERENCES public.professional_service(id) ON DELETE RESTRICT
);

COMMENT ON TABLE public.professional_booking_package IS
    'Container for a rolling multi-session package purchase. sessions_used increments as each
     professional_booking row against this package completes; the client is prompted to schedule
     the next session (a new professional_booking with this package_id) until sessions_used reaches
     sessions_total. Cancelable any time (status=cancelled) — no refund logic, no payment tie-in.';

CREATE INDEX idx_professional_booking_package_client
    ON public.professional_booking_package USING btree (client_user_id);
CREATE INDEX idx_professional_booking_package_professional
    ON public.professional_booking_package USING btree (professional_id);
CREATE INDEX idx_professional_booking_package_service
    ON public.professional_booking_package USING btree (service_id);

ALTER TABLE public.professional_booking_package ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Clients can manage their own booking packages" ON public.professional_booking_package
    TO authenticated
    USING ((SELECT auth.uid()) = client_user_id)
    WITH CHECK ((SELECT auth.uid()) = client_user_id);

CREATE POLICY "Linked professionals can view their booking packages" ON public.professional_booking_package
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.professional p
            WHERE p.id = professional_booking_package.professional_id
              AND p.linked_user_id = (SELECT auth.uid())
        )
    );

-- ── 3. Link individual bookings back to their package ───────────────────────
ALTER TABLE public.professional_booking
    ADD COLUMN IF NOT EXISTS package_id uuid,
    ADD CONSTRAINT professional_booking_package_id_fkey
        FOREIGN KEY (package_id) REFERENCES public.professional_booking_package(id) ON DELETE SET NULL;

CREATE INDEX idx_professional_booking_package_id
    ON public.professional_booking USING btree (package_id);
