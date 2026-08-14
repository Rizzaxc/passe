-- A Host's public display name is separate from the linked user's username,
-- matching the professional profile contract. Let an authenticated Host edit
-- only that field on their own row; all other Host fields remain RPC/admin-only.

-- This restrictive blanket-deny policy predates the self-service field. Drop
-- it so the owner policy below can match; RLS default-deny and the existing
-- table privilege revokes continue to block every operation not granted here.
DROP POLICY IF EXISTS "Freeplay Host is RPC only"
    ON public.freeplay_host;

-- PostgREST UPDATEs need a matching SELECT policy and SELECT permission on
-- columns used to identify the row. Keep that read surface to the caller's own
-- Host id/owner/name rather than opening the rest of the table.
DROP POLICY IF EXISTS "Hosts can read their own display name"
    ON public.freeplay_host;

CREATE POLICY "Hosts can read their own display name"
    ON public.freeplay_host
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Hosts can update their own display name"
    ON public.freeplay_host;

CREATE POLICY "Hosts can update their own display name"
    ON public.freeplay_host
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);

GRANT SELECT (id, user_id, display_name)
    ON TABLE public.freeplay_host TO authenticated;

GRANT UPDATE (display_name)
    ON TABLE public.freeplay_host TO authenticated;

COMMENT ON COLUMN public.freeplay_host.display_name IS
    'Public Host name, independent from the linked user account username.';
