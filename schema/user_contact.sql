-- A user's optional external-app contact info (currently just Zalo), kept out of the
-- broadly-readable `user.details` jsonb (that table's SELECT policy is USING(true)) so
-- visibility can be enforced at the RLS layer instead of trusted to client code:
--   - the owner can always read/write their own row
--   - friends can read it
--   - a freeplay host's contact is public — a host acts as an "alternative pro" (like a
--     hireable coach/referee, whose contact_details are already not friend-gated), not a
--     normal peer, so their info should be discoverable by anyone they might host
create table if not exists public.user_contact (
    user_id uuid primary key references public."user"(id) on delete cascade,
    zalo text,
    updated_at timestamptz not null default now(),
    constraint user_contact_zalo_length check (zalo is null or char_length(btrim(zalo)) between 1 and 32)
);

alter table public.user_contact enable row level security;

drop policy if exists "Owner can manage their contact info" on public.user_contact;
create policy "Owner can manage their contact info"
    on public.user_contact for all to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

drop policy if exists "Friends and freeplay hosts contacts are readable" on public.user_contact;
create policy "Friends and freeplay hosts contacts are readable"
    on public.user_contact for select to authenticated
    using (
        user_id in (select public.get_my_friend_ids())
        or exists (
            select 1 from public.freeplay_host h
            where h.user_id = user_contact.user_id and h.status = 'active'
        )
    );

create or replace function public.fn_touch_user_contact()
    returns trigger language plpgsql security invoker set search_path to 'public' as $$
begin
    new.updated_at := now();
    return new;
end
$$;

drop trigger if exists trg_user_contact_touch on public.user_contact;
create trigger trg_user_contact_touch
    before update on public.user_contact
    for each row execute function public.fn_touch_user_contact();
