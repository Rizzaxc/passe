-- ============================================================================
-- feeds_rls_fix.sql — let signed-in users read professional profiles.
--
-- public.professional only had a SELECT policy for the `anon` role
-- (is_verified = true). The authenticated role had no SELECT policy, so the
-- Home → Neutrals feed (`from('professional')...` run as authenticated)
-- returned nothing. Professionals are public discovery content, so allow
-- authenticated users to read all profiles.
--
-- Apply with execute_sql / apply_migration. Idempotent.
-- ============================================================================

DROP POLICY IF EXISTS "Authenticated users can read professional profiles" ON public.professional;

CREATE POLICY "Authenticated users can read professional profiles"
    ON public.professional
    FOR SELECT
    TO authenticated
    USING (true);
