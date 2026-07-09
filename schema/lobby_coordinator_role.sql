-- Coordinator role: captain can grant members a "coordinator" role that
-- carries every captain capability except kicking members and editing lobby
-- info (name/visibility/playtime/details/home_ground via update_lobby, and
-- lobby deletion). Captaincy transfer and promoting/demoting coordinators
-- also stay captain-only — those are lobby-administration actions, the same
-- tier as kicking, not day-to-day lobby operation.

-- 1. Role column on lobby_member (no role concept existed before this).
CREATE TYPE public.lobby_member_role AS ENUM ('member', 'coordinator');

ALTER TABLE public.lobby_member
    ADD COLUMN role public.lobby_member_role NOT NULL DEFAULT 'member';

-- 2. Helper: true if the caller is the lobby's captain OR a coordinator
-- member. SECURITY DEFINER so it can be used inside RLS policies on other
-- tables without each policy needing its own EXISTS-join boilerplate
-- (mirrors get_my_lobby_ids()).
CREATE FUNCTION public.lobby_can_manage(p_lobby_id uuid, p_user_id uuid DEFAULT auth.uid())
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.lobby l
        WHERE l.id = p_lobby_id AND l.captain_id = p_user_id
    ) OR EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = p_lobby_id AND lm.user_id = p_user_id AND lm.role = 'coordinator'
    );
$$;

GRANT EXECUTE ON FUNCTION public.lobby_can_manage(uuid, uuid) TO authenticated;

-- 3. Captain-only RPC to grant/revoke the coordinator role. Not exposed via
-- a plain UPDATE RLS policy on lobby_member — role changes are a
-- captain-tier action, same as kicking, so they go through a validated
-- function like transfer_lobby_captaincy.
CREATE FUNCTION public.set_lobby_member_role(
    p_lobby_id uuid, p_member_user_id uuid, p_role text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby WHERE id = p_lobby_id AND captain_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'set_lobby_member_role: caller is not the lobby captain';
    END IF;
    IF p_member_user_id = auth.uid() THEN
        RAISE EXCEPTION 'set_lobby_member_role: captain cannot change their own role';
    END IF;
    IF p_role NOT IN ('member', 'coordinator') THEN
        RAISE EXCEPTION 'set_lobby_member_role: invalid role %', p_role;
    END IF;

    UPDATE public.lobby_member
    SET role = p_role::public.lobby_member_role
    WHERE lobby_id = p_lobby_id AND user_id = p_member_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'set_lobby_member_role: % is not a member of this lobby', p_member_user_id;
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_lobby_member_role(uuid, uuid, text) TO authenticated;

-- 4. Extend existing captain-only RLS policies to also allow coordinators.
-- Kick (lobby_member DELETE), update_lobby, transfer_lobby_captaincy, and
-- "Captain can delete their lobby" are deliberately NOT touched here.

DROP POLICY "Captain can post updates and polls" ON public.lobby_feed_item;
CREATE POLICY "Captain or coordinator can post updates and polls" ON public.lobby_feed_item
    FOR INSERT TO authenticated
    WITH CHECK (
        author_id = auth.uid()
        AND kind = ANY (ARRAY['update'::public.lobby_feed_item_kind, 'poll'::public.lobby_feed_item_kind])
        AND public.lobby_can_manage(lobby_id)
    );

DROP POLICY "Author or captain can delete a feed item" ON public.lobby_feed_item;
CREATE POLICY "Author or captain or coordinator can delete a feed item" ON public.lobby_feed_item
    FOR DELETE TO authenticated
    USING (author_id = auth.uid() OR public.lobby_can_manage(lobby_id));

DROP POLICY "Captain can record matches for their lobby" ON public.lobby_match;
CREATE POLICY "Captain or coordinator can record matches for their lobby" ON public.lobby_match
    FOR INSERT TO authenticated
    WITH CHECK (public.lobby_can_manage(lobby_id));

DROP POLICY "Captain can edit their lobby's matches" ON public.lobby_match;
CREATE POLICY "Captain or coordinator can edit their lobby's matches" ON public.lobby_match
    FOR UPDATE TO authenticated
    USING (public.lobby_can_manage(lobby_id))
    WITH CHECK (public.lobby_can_manage(lobby_id));

DROP POLICY "Captain can delete their lobby's matches" ON public.lobby_match;
CREATE POLICY "Captain or coordinator can delete their lobby's matches" ON public.lobby_match
    FOR DELETE TO authenticated
    USING (public.lobby_can_manage(lobby_id));

DROP POLICY "Users involved can update befriend record status" ON public.lobby_befriend_record;
CREATE POLICY "Users involved can update befriend record status" ON public.lobby_befriend_record
    FOR UPDATE TO authenticated
    USING (
        auth.uid() = initiator_user_id
        OR auth.uid() = target_user_id
        OR (target_lobby_id IS NOT NULL AND public.lobby_can_manage(target_lobby_id))
    )
    WITH CHECK (true);

-- 5. Activity scheduling/editing/canceling: existing RLS is row-ownership
-- only (user_id = auth.uid()), so a coordinator editing/canceling an
-- activity the captain (or another coordinator) created was blocked. Add a
-- lobby-role clause alongside ownership so any captain/coordinator can
-- manage any of their lobby's activities, not just ones they personally
-- created. INSERT is left untouched (already permissive to any member
-- inserting as themselves, matching the app's own convention).
DROP POLICY "Users can update their own activities" ON public.activity;
CREATE POLICY "Owner or lobby manager can update activities" ON public.activity
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR (lobby_id IS NOT NULL AND public.lobby_can_manage(lobby_id)))
    WITH CHECK (user_id = auth.uid() OR (lobby_id IS NOT NULL AND public.lobby_can_manage(lobby_id)));

DROP POLICY "Users can delete their own activities" ON public.activity;
CREATE POLICY "Owner or lobby manager can delete activities" ON public.activity
    FOR DELETE TO authenticated
    USING (user_id = auth.uid() OR (lobby_id IS NOT NULL AND public.lobby_can_manage(lobby_id)));
