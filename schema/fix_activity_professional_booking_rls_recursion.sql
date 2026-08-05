-- Fixes "infinite recursion detected in policy for relation ..." thrown by
-- EVERY select against `activity` or `professional_booking` for an
-- authenticated user.
--
-- Root cause: two policies reference each other's table directly:
--   - activity's "Linked professionals can view their attached activities"
--     queries professional_booking (joined to professional).
--   - professional_booking's "Lobby members can view attached bookings"
--     queries activity back (schema/activity_professional_attachment.sql).
-- Evaluating either table's RLS therefore requires evaluating the other's,
-- which requires the first's again — Postgres detects this and aborts the
-- query rather than looping forever. (The earlier hypothesis — that
-- get_my_lobby_ids() recursed through lobby_member's own "Users can see
-- lobby members in shared lobbies" policy — was ruled out: calling
-- get_my_lobby_ids() directly, and querying lobby_member directly, both
-- work fine; only activity and professional_booking recurse, confirming
-- this is a two-table mutual reference, not that one.)
--
-- Fix: wrap professional_booking's `activity` lookup in a SECURITY DEFINER
-- function (language plpgsql — matches Supabase's own documented recursion
-- workaround, see "Use Security Definer Functions" in the RLS guide). This
-- breaks the cycle at this one edge: the function bypasses activity's RLS
-- for this single narrow "is this booking attached to one of my lobby's
-- activities" check, so activity's own policies never need to be
-- re-evaluated while professional_booking's policy runs.
--
-- Also converts get_my_lobby_ids() from `language sql` to `language
-- plpgsql`, for the same reason and matching the same official pattern —
-- kept even though it alone didn't resolve this specific recursion (the
-- real cycle turned out to be activity<->professional_booking, not
-- get_my_lobby_ids()<->lobby_member), since it's still the documented,
-- safer form for a SECURITY DEFINER RLS helper.
CREATE OR REPLACE FUNCTION public.get_my_lobby_ids()
 RETURNS SETOF uuid
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY SELECT lobby_id FROM public.lobby_member WHERE user_id = auth.uid();
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_booking_attached_to_my_lobby_activity(p_booking_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.activity a
    WHERE (a.coach_booking_id = p_booking_id OR a.referee_booking_id = p_booking_id)
      AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
  );
END;
$function$;

DROP POLICY IF EXISTS "Lobby members can view attached bookings" ON public.professional_booking;
CREATE POLICY "Lobby members can view attached bookings" ON public.professional_booking
FOR SELECT
USING ( public.is_booking_attached_to_my_lobby_activity(id) );
