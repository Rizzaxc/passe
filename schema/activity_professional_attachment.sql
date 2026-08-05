-- ============================================================================
-- activity_professional_attachment.sql — reconstructed from the live schema.
--
-- This migration was applied to the Supabase project directly (via MCP) at
-- some point before this repo pass and never committed, even though root
-- CLAUDE.md and lib/manage_tab/CLAUDE.md both cite it by name. Re-created here
-- from `pg_get_functiondef` / `pg_get_constraintdef` against the live project
-- (qlezbnjfuabcxlsxxnrw) so the repo and prod stop disagreeing — apply is a
-- no-op there (`IF NOT EXISTS` / `CREATE OR REPLACE` throughout), so this is
-- safe to run again.
--
-- Lets a lobby activity have a hired coach and/or referee ATTACHED alongside
-- its `lobby_id` (distinct from `professional_booking_id`, which
-- `activity_source_exclusivity` reserves for a standalone client pro-session
-- and forbids together with `lobby_id`).
-- ============================================================================

ALTER TABLE public.activity
    ADD COLUMN IF NOT EXISTS coach_booking_id uuid
        REFERENCES public.professional_booking(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS referee_booking_id uuid
        REFERENCES public.professional_booking(id) ON DELETE SET NULL;

-- A booking attached here has to actually be that role — you can't attach a
-- referee's booking as `coach_booking_id` or vice versa.
CREATE OR REPLACE FUNCTION public.fn_activity_attachment_role_check()
    RETURNS trigger
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO ''
AS $$
BEGIN
  IF NEW.coach_booking_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.professional_booking pb
      JOIN public.professional p ON p.id = pb.professional_id
      WHERE pb.id = NEW.coach_booking_id
        AND p.professional_role = 'coach'
  ) THEN
    RAISE EXCEPTION 'coach_booking_id % must reference a coach booking', NEW.coach_booking_id;
  END IF;

  IF NEW.referee_booking_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.professional_booking pb
      JOIN public.professional p ON p.id = pb.professional_id
      WHERE pb.id = NEW.referee_booking_id
        AND p.professional_role = 'referee'
  ) THEN
    RAISE EXCEPTION 'referee_booking_id % must reference a referee booking', NEW.referee_booking_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activity_attachment_role_check ON public.activity;
CREATE TRIGGER activity_attachment_role_check
    BEFORE INSERT OR UPDATE OF coach_booking_id, referee_booking_id ON public.activity
    FOR EACH ROW EXECUTE FUNCTION public.fn_activity_attachment_role_check();

-- Lobby members (not just the captain) can read the attached booking, so the
-- hero card's `_AttachedProRow` doesn't silently render nothing for everyone
-- but the row's own `user_id` — the same RLS gap class documented in
-- lib/manage_tab/CLAUDE.md ("activity RLS is owner-scoped, not member-scoped").
DROP POLICY IF EXISTS "Lobby members can view attached bookings" ON public.professional_booking;
CREATE POLICY "Lobby members can view attached bookings"
    ON public.professional_booking FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.activity a
            WHERE (a.coach_booking_id = professional_booking.id
                   OR a.referee_booking_id = professional_booking.id)
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );
