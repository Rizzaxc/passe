-- Keep private professional workflow objects out of the anonymous API surface.
-- Authenticated reads remain protected by the row policies installed by
-- professional_security_hardening.sql.

REVOKE SELECT ON TABLE public.professional_booking FROM anon;
REVOKE SELECT ON TABLE public.professional_booking_package FROM anon;
REVOKE SELECT ON TABLE public.booking_additional_users FROM anon;

-- These functions are trigger-only implementation details. PostgreSQL rejects
-- direct trigger-function calls, but revoking EXECUTE also removes them from
-- the callable PostgREST RPC surface.
REVOKE ALL ON FUNCTION public.fn_complete_professional_booking_on_match()
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_notify_professional_booking_created()
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_notify_professional_booking_status_changed()
    FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.professional_booking_review_updated_trigger_fn()
    FROM PUBLIC, anon, authenticated;
