-- Lets a user opt their Zalo contact into public visibility (off by default), so someone
-- willing to be reachable by strangers isn't limited to the friends-only baseline set by
-- schema/user_contact.sql.
alter table public.user_contact
    add column if not exists zalo_public boolean not null default false;

-- RLS policies run with the QUERYING role's own privileges, not elevated ones — `freeplay_host`
-- is locked down to `postgres`/`service_role` only (reachable by regular users solely through
-- SECURITY DEFINER RPCs), so a policy that references it directly throws "permission denied for
-- table freeplay_host" for any `authenticated` caller, instead of just filtering rows. Route the
-- check through a SECURITY DEFINER function (same pattern as get_my_friend_ids()) so it runs as
-- the function owner. This function is what actually broke `user_contact` upserts: PostgREST's
-- upsert reads the row back afterwards (RETURNING), which re-evaluates this SELECT policy inside
-- the same transaction, so the permission error rolled back the write too.
create or replace function public.fn_is_active_freeplay_host(p_user_id uuid)
    returns boolean
    language sql stable security definer set search_path to 'public'
as $$
    select exists (
        select 1 from public.freeplay_host h
        where h.user_id = p_user_id and h.status = 'active'
    );
$$;

revoke all on function public.fn_is_active_freeplay_host(uuid) from public, anon;
grant execute on function public.fn_is_active_freeplay_host(uuid) to authenticated;

drop policy if exists "Friends and freeplay hosts contacts are readable" on public.user_contact;
drop policy if exists "Friends, public, and freeplay hosts contacts are readable" on public.user_contact;
create policy "Friends, public, and freeplay hosts contacts are readable"
    on public.user_contact for select to authenticated
    using (
        zalo_public
        or user_id in (select public.get_my_friend_ids())
        or public.fn_is_active_freeplay_host(user_contact.user_id)
    );
