-- ============================================================================
-- activity_confirmation_lock_after_confirmed.sql — once an activity is
-- confirmed (enough "going" RSVPs to hit activity.confirmation_threshold,
-- or no threshold at all — see activity_is_confirmed()), a member who is
-- already "going" can no longer change or retract their RSVP. Prevents a
-- committed member from bailing after the session is already locked in.
--
-- Members who are "maybe" / "out" / unresponsive are unaffected — they can
-- still RSVP normally (including flipping to "going") after confirmation;
-- only a currently-"going" row is frozen.
--
-- Apply with execute_sql / apply_migration. Idempotent.
-- ============================================================================

DROP POLICY IF EXISTS "Members can change their own attendance" ON public.activity_confirmation;
CREATE POLICY "Members can change their own attendance"
    ON public.activity_confirmation
    FOR UPDATE
    TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        AND NOT (
            attendance = 'going'
            AND public.activity_is_confirmed(activity_id)
        )
    )
    WITH CHECK (
        user_id = (SELECT auth.uid())
        AND EXISTS (
            SELECT 1 FROM public.activity a
            WHERE a.id = activity_confirmation.activity_id
              AND a.lobby_id IN (SELECT public.get_my_lobby_ids())
        )
    );

DROP POLICY IF EXISTS "Members can retract their own confirmation" ON public.activity_confirmation;
CREATE POLICY "Members can retract their own confirmation"
    ON public.activity_confirmation
    FOR DELETE
    TO authenticated
    USING (
        user_id = (SELECT auth.uid())
        AND NOT (
            attendance = 'going'
            AND public.activity_is_confirmed(activity_id)
        )
    );
