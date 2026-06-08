-- ============================================================================
-- activity_attendance.sql — three-way RSVP on activity_confirmation.
--
-- Previously a confirmation row was binary (present = "going"). Add an
-- `attendance` enum (going / maybe / out) so members can RSVP tentatively or
-- decline while still being on record. **Only `going` counts toward the
-- confirmation threshold** (an activity becomes official on enough `going`s).
--
-- Apply with execute_sql / apply_migration. Idempotent.
-- ============================================================================

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'activity_attendance') THEN
        CREATE TYPE public.activity_attendance AS ENUM ('going', 'maybe', 'out');
    END IF;
END $$;

ALTER TABLE public.activity_confirmation
    ADD COLUMN IF NOT EXISTS attendance public.activity_attendance NOT NULL DEFAULT 'going';

-- Changing attendance (going ⇄ maybe ⇄ out) is an UPDATE via upsert, which
-- needs its own policy (the table previously only had INSERT/SELECT/DELETE).
DROP POLICY IF EXISTS "Members can change their own attendance" ON public.activity_confirmation;
CREATE POLICY "Members can change their own attendance"
    ON public.activity_confirmation
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );

-- Status RPC now reports going + maybe counts and the caller's own attendance.
DROP FUNCTION IF EXISTS public.activity_confirmation_status(uuid);
CREATE FUNCTION public.activity_confirmation_status(p_activity_id uuid)
RETURNS TABLE(
    confirmed_count integer,   -- "going" only
    maybe_count integer,
    threshold integer,
    my_attendance text,        -- 'going' | 'maybe' | 'out' | NULL (no response)
    activity_confirmed boolean
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_threshold int;
    v_going     int;
    v_maybe     int;
    v_mine      text;
BEGIN
    SELECT a.confirmation_threshold INTO v_threshold
        FROM public.activity a WHERE a.id = p_activity_id;

    SELECT COUNT(*) FILTER (WHERE attendance = 'going')::int,
           COUNT(*) FILTER (WHERE attendance = 'maybe')::int
        INTO v_going, v_maybe
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id;

    SELECT attendance::text INTO v_mine
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND user_id = auth.uid();

    RETURN QUERY SELECT
        COALESCE(v_going, 0),
        COALESCE(v_maybe, 0),
        v_threshold,
        v_mine,
        (v_threshold IS NULL OR COALESCE(v_going, 0) >= v_threshold);
END;
$$;

-- Threshold check counts only "going".
CREATE OR REPLACE FUNCTION public.activity_is_confirmed(p_activity_id uuid)
RETURNS boolean
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_threshold int;
    v_count     int;
BEGIN
    SELECT a.confirmation_threshold INTO v_threshold
        FROM public.activity a WHERE a.id = p_activity_id;
    IF NOT FOUND THEN RETURN false; END IF;
    IF v_threshold IS NULL THEN RETURN true; END IF;

    SELECT COUNT(*) INTO v_count
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id AND attendance = 'going';

    RETURN v_count >= v_threshold;
END;
$$;

-- The recreated SECURITY DEFINER status fn defaults to PUBLIC execute; lock it.
REVOKE EXECUTE ON FUNCTION public.activity_confirmation_status(uuid) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.activity_confirmation_status(uuid) TO authenticated;
