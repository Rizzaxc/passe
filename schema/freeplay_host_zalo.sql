-- freeplay_host is RPC-only ("Freeplay Host is RPC only" RESTRICTIVE USING
-- (false)) — a direct client `.from('freeplay_host')` select always returns
-- zero rows, so the detail page's Zalo button (next to the main CTA) needs
-- a SECURITY DEFINER function to resolve host_id -> user_id -> zalo, the
-- same way fn_is_active_freeplay_host already bypasses that restriction to
-- back user_contact's own RLS policy.
CREATE FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT uc.zalo
    FROM public.freeplay_host h
    JOIN public.user_contact uc ON uc.user_id = h.user_id
    WHERE h.id = p_host_id AND h.status = 'active';
$$;

ALTER FUNCTION public.fn_freeplay_host_zalo(p_host_id uuid) OWNER TO postgres;
