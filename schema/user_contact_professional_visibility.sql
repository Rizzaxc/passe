-- A linked professional's (coach/referee) Zalo was never readable by a
-- browsing client — user_contact's SELECT policy only special-cased an
-- active freeplay host (fn_is_active_freeplay_host), friends, and
-- zalo_public. `professional` rows are admin-linked, never self-registered
-- (see root CLAUDE.md), so the same trust level as an active freeplay host
-- applies without an extra is_verified gate.
CREATE FUNCTION public.fn_is_linked_professional(p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    select exists (
        select 1 from public.professional p
        where p.linked_user_id = p_user_id
    );
$$;

ALTER FUNCTION public.fn_is_linked_professional(p_user_id uuid) OWNER TO postgres;

DROP POLICY "Friends, public, and freeplay hosts contacts are readable" ON public.user_contact;

CREATE POLICY "Friends, public, freeplay hosts, and pros contacts are readable" ON public.user_contact
    FOR SELECT TO authenticated
    USING (
        zalo_public
        OR (user_id IN (SELECT public.get_my_friend_ids()))
        OR public.fn_is_active_freeplay_host(user_id)
        OR public.fn_is_linked_professional(user_id)
    );
