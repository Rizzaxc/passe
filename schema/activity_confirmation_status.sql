-- ============================================================================
-- Two-level confirmation model
--
-- * Member confirmation = a `activity_confirmation` row exists for
--   (activity_id, user_id). That's the member saying "I'll be there".
-- * Activity confirmation = the session itself counts as "official":
--     - If `activity.confirmation_threshold IS NULL`, the activity is
--       confirmed the moment it's scheduled. Groups with a fixed weekly
--       slot use this — no quorum required.
--     - Otherwise the activity becomes confirmed once
--       count(activity_confirmation) >= confirmation_threshold.
--
-- The derivation lives in SQL so every caller (RPCs, RLS predicates,
-- views) gets the same answer. The companion RPC bundles the four
-- numbers the client needs to render the hero / RSVP control without
-- chasing extra round-trips.
-- ============================================================================


-- ─── Pure derivation: is the activity confirmed? ───────────────

CREATE OR REPLACE FUNCTION public.activity_is_confirmed(p_activity_id uuid)
RETURNS boolean
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
AS $$
DECLARE
    v_threshold int;
    v_count     int;
BEGIN
    SELECT a.confirmation_threshold INTO v_threshold
        FROM public.activity a
        WHERE a.id = p_activity_id;

    -- Activity doesn't exist — treat as not confirmed rather than NULL
    -- so callers don't have to handle three-valued logic.
    IF NOT FOUND THEN
        RETURN false;
    END IF;

    -- No threshold = always confirmed once scheduled.
    IF v_threshold IS NULL THEN
        RETURN true;
    END IF;

    SELECT COUNT(*) INTO v_count
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id;

    RETURN v_count >= v_threshold;
END;
$$;


-- ─── Read helper for the hero RSVP control ─────────────────────
--
-- One round-trip, the four numbers the hero needs:
--   confirmed_count   — total member confirmations
--   threshold         — null when the activity always-confirms
--   me_confirmed      — is the calling user in the confirmation list
--   activity_confirmed — derived status (see activity_is_confirmed)

CREATE OR REPLACE FUNCTION public.activity_confirmation_status(
    p_activity_id uuid
) RETURNS TABLE (
    confirmed_count int,
    threshold int,
    me_confirmed boolean,
    activity_confirmed boolean
)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
AS $$
DECLARE
    v_threshold int;
    v_count     int;
    v_me        boolean;
BEGIN
    SELECT a.confirmation_threshold INTO v_threshold
        FROM public.activity a
        WHERE a.id = p_activity_id;

    SELECT COUNT(*)::int INTO v_count
        FROM public.activity_confirmation
        WHERE activity_id = p_activity_id;

    SELECT EXISTS(
        SELECT 1
            FROM public.activity_confirmation
            WHERE activity_id = p_activity_id
              AND user_id = auth.uid()
    ) INTO v_me;

    RETURN QUERY SELECT
        v_count,
        v_threshold,
        v_me,
        (v_threshold IS NULL OR v_count >= v_threshold);
END;
$$;
