-- ============================================================================
-- Friendship graph (mutual, request/accept) + user blocking.
--
-- Replaces `lobby_befriend_record`'s `pair` interaction, which modelled a
-- user↔user handshake by creating a 2-person *lobby* on accept. `pair` was
-- never sent by any client (only read, in incoming_invites_controller.dart) —
-- this file retires it: new `pair` inserts are rejected and pending rows are
-- cancelled. Accepted pair rows are left alone; the lobbies they produced are
-- real and stay valid.
--
-- `user_block` lives here rather than with the post-moderation tables because
-- a block is a relationship between people, not a property of a post: the
-- friendship RPCs below have to honour it.
--
-- Apply in TWO steps (ALTER TYPE ... ADD VALUE cannot run in the same
-- transaction that later uses the new value):
--   Part A: notification_kind enum additions  (own migration)
--   Part B: everything else                   (own migration)
--
-- Idempotent / re-runnable.
-- ============================================================================

-- ─── Part A — notification kinds (apply as its own migration) ───────────────
-- ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'friend_request';
-- ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'friend_accepted';

-- ─── Part B ─────────────────────────────────────────────────────────────────

-- 1. Status enum
do $$
begin
    if not exists (select 1 from pg_type where typname = 'friendship_status') then
        create type public.friendship_status as enum (
            'pending', 'accepted', 'declined', 'cancelled'
        );
    end if;
end$$;

-- 2. Tables
create table if not exists public.friendship (
    id            uuid primary key default gen_random_uuid(),
    requester_id  uuid not null references public."user"(id) on delete cascade,
    addressee_id  uuid not null references public."user"(id) on delete cascade,
    status        public.friendship_status not null default 'pending',
    created_at    timestamptz not null default now(),
    responded_at  timestamptz,
    constraint friendship_distinct check (requester_id <> addressee_id)
);

-- One live relationship per unordered pair. Canonicalised with least/greatest
-- so an A→B request and a B→A request collide on the same index entry — the
-- send RPC turns that collision into a reciprocal auto-accept before it can
-- ever fire, but the index is the backstop.
create unique index if not exists friendship_one_live_per_pair
    on public.friendship (
        least(requester_id, addressee_id),
        greatest(requester_id, addressee_id)
    )
    where status in ('pending', 'accepted');

create index if not exists friendship_addressee_idx
    on public.friendship (addressee_id, status);
create index if not exists friendship_requester_idx
    on public.friendship (requester_id, status);

create table if not exists public.user_block (
    blocker_id  uuid not null references public."user"(id) on delete cascade,
    blocked_id  uuid not null references public."user"(id) on delete cascade,
    created_at  timestamptz not null default now(),
    primary key (blocker_id, blocked_id),
    constraint user_block_distinct check (blocker_id <> blocked_id)
);

create index if not exists user_block_blocked_idx on public.user_block (blocked_id);

-- 3. Helpers — mirror get_my_lobby_ids()'s shape (SETOF uuid, SECURITY DEFINER)
--    so they can be used inside RLS predicates without recursing into RLS.
create or replace function public.get_my_friend_ids()
    returns setof uuid
    language sql stable security definer set search_path to 'public'
as $$
    select case when requester_id = auth.uid() then addressee_id else requester_id end
    from public.friendship
    where status = 'accepted'
      and auth.uid() in (requester_id, addressee_id);
$$;

-- Every user sharing at least one lobby with the caller (excluding the caller).
create or replace function public.get_my_lobbymate_ids()
    returns setof uuid
    language sql stable security definer set search_path to 'public'
as $$
    select distinct m.user_id
    from public.lobby_member m
    where m.lobby_id in (select public.get_my_lobby_ids())
      and m.user_id <> auth.uid();
$$;

-- True if either party has blocked the other.
create or replace function public.fn_is_blocked(p_a uuid, p_b uuid)
    returns boolean
    language sql stable security definer set search_path to 'public'
as $$
    select exists (
        select 1 from public.user_block
        where (blocker_id = p_a and blocked_id = p_b)
           or (blocker_id = p_b and blocked_id = p_a)
    );
$$;

grant execute on function public.get_my_friend_ids() to authenticated;
grant execute on function public.get_my_lobbymate_ids() to authenticated;
grant execute on function public.fn_is_blocked(uuid, uuid) to authenticated;

-- 4. RLS — read your own edges; all writes go through the RPCs below.
alter table public.friendship enable row level security;
alter table public.user_block enable row level security;

drop policy if exists "Parties can read their friendship rows" on public.friendship;
create policy "Parties can read their friendship rows"
    on public.friendship for select to authenticated
    using (auth.uid() in (requester_id, addressee_id));

drop policy if exists "Blocker can read their blocks" on public.user_block;
create policy "Blocker can read their blocks"
    on public.user_block for select to authenticated
    using (blocker_id = (select auth.uid()));

-- 5. Send a friend request.
--    Idempotent: re-sending an already-pending request returns the same row.
--    Reciprocal: if the other party already has a pending request out to the
--    caller, this accepts it instead of creating a second edge (same behaviour
--    as the lobby_befriend_record auto-accept trigger).
create or replace function public.send_friend_request(p_user_id uuid)
    returns uuid
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid    uuid := auth.uid();
    v_id     uuid;
    v_status public.friendship_status;
    v_owner  uuid;
    v_label  text;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    if p_user_id is null then raise exception 'no target user'; end if;
    if p_user_id = v_uid then raise exception 'cannot befriend yourself'; end if;
    if not exists (select 1 from public."user" u where u.id = p_user_id) then
        raise exception 'user not found';
    end if;
    if public.fn_is_blocked(v_uid, p_user_id) then
        raise exception 'blocked';
    end if;

    select id, status, requester_id into v_id, v_status, v_owner
        from public.friendship
        where status in ('pending', 'accepted')
          and least(requester_id, addressee_id) = least(v_uid, p_user_id)
          and greatest(requester_id, addressee_id) = greatest(v_uid, p_user_id);

    if v_status = 'accepted' then
        return v_id;                       -- already friends, no-op
    elsif v_status = 'pending' and v_owner = v_uid then
        return v_id;                       -- already sent, no-op
    elsif v_status = 'pending' then
        -- They asked first: accept theirs rather than opening a second edge.
        update public.friendship
            set status = 'accepted', responded_at = now()
            where id = v_id;

        select u.username || '#' || u.tag_number into v_label
            from public."user" u where u.id = v_uid;

        perform public.fn_enqueue_notification(
            'friend_accepted',
            array[p_user_id],
            'Đã thành bạn bè',
            coalesce(v_label, 'Một người chơi') || ' đã chấp nhận lời mời kết bạn',
            jsonb_build_object('user_id', v_uid::text));
        return v_id;
    end if;

    insert into public.friendship (requester_id, addressee_id)
        values (v_uid, p_user_id)
        returning id into v_id;

    select u.username || '#' || u.tag_number into v_label
        from public."user" u where u.id = v_uid;

    perform public.fn_enqueue_notification(
        'friend_request',
        array[p_user_id],
        'Lời mời kết bạn',
        coalesce(v_label, 'Một người chơi') || ' muốn kết bạn với bạn',
        jsonb_build_object('user_id', v_uid::text));

    return v_id;
end;
$$;

-- 6. Respond to an incoming request (addressee only).
create or replace function public.respond_friend_request(
    p_friendship_id uuid,
    p_action        text
) returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid       uuid := auth.uid();
    v_requester uuid;
    v_addressee uuid;
    v_status    public.friendship_status;
    v_label     text;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;

    select requester_id, addressee_id, status
        into v_requester, v_addressee, v_status
        from public.friendship where id = p_friendship_id;

    if v_requester is null then raise exception 'request not found'; end if;
    if v_addressee <> v_uid then raise exception 'not yours to answer'; end if;
    if v_status <> 'pending' then raise exception 'request is no longer open'; end if;

    if p_action = 'accept' then
        update public.friendship
            set status = 'accepted', responded_at = now()
            where id = p_friendship_id;

        select u.username || '#' || u.tag_number into v_label
            from public."user" u where u.id = v_uid;

        perform public.fn_enqueue_notification(
            'friend_accepted',
            array[v_requester],
            'Đã thành bạn bè',
            coalesce(v_label, 'Một người chơi') || ' đã chấp nhận lời mời kết bạn',
            jsonb_build_object('user_id', v_uid::text));
    elsif p_action = 'decline' then
        -- No notification: a silent decline is the kinder default and avoids
        -- turning a rejection into a push.
        update public.friendship
            set status = 'declined', responded_at = now()
            where id = p_friendship_id;
    else
        raise exception 'invalid action %', p_action;
    end if;
end;
$$;

-- 7. Cancel an outgoing request / unfriend. Both directions, one entry point.
create or replace function public.unfriend(p_user_id uuid)
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then raise exception 'not authenticated'; end if;

    update public.friendship
        set status = 'cancelled', responded_at = now()
        where status in ('pending', 'accepted')
          and least(requester_id, addressee_id) = least(v_uid, p_user_id)
          and greatest(requester_id, addressee_id) = greatest(v_uid, p_user_id);
end;
$$;

-- 8. Block / unblock. Blocking severs any live friendship in the same call.
create or replace function public.block_user(p_user_id uuid)
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    if p_user_id = v_uid then raise exception 'cannot block yourself'; end if;

    insert into public.user_block (blocker_id, blocked_id)
        values (v_uid, p_user_id)
        on conflict do nothing;

    update public.friendship
        set status = 'cancelled', responded_at = now()
        where status in ('pending', 'accepted')
          and least(requester_id, addressee_id) = least(v_uid, p_user_id)
          and greatest(requester_id, addressee_id) = greatest(v_uid, p_user_id);
end;
$$;

create or replace function public.unblock_user(p_user_id uuid)
    returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    if auth.uid() is null then raise exception 'not authenticated'; end if;
    delete from public.user_block
        where blocker_id = auth.uid() and blocked_id = p_user_id;
end;
$$;

grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.respond_friend_request(uuid, text) to authenticated;
grant execute on function public.unfriend(uuid) to authenticated;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;

-- 9. The caller's friends + open requests, in one round trip.
create or replace function public.friend_data()
    returns table(
        friendship_id    uuid,
        user_id          uuid,
        username         text,
        tag_number       text,   -- varchar(4) on public."user", not an int
        details          jsonb,
        direction        text,   -- 'friend' | 'incoming' | 'outgoing'
        created_at       timestamptz
    )
    language sql stable security definer set search_path to 'public'
as $$
    select f.id,
           case when f.requester_id = auth.uid() then f.addressee_id else f.requester_id end,
           u.username::text,
           u.tag_number::text,
           u.details,
           case
               when f.status = 'accepted' then 'friend'
               when f.addressee_id = auth.uid() then 'incoming'
               else 'outgoing'
           end,
           f.created_at
    from public.friendship f
    join public."user" u
        on u.id = case when f.requester_id = auth.uid()
                       then f.addressee_id else f.requester_id end
    where auth.uid() in (f.requester_id, f.addressee_id)
      and f.status in ('pending', 'accepted')
      and not public.fn_is_blocked(auth.uid(), u.id)
    order by f.created_at desc;
$$;

-- 10. The /user/:id header: public-ish profile + this viewer's relationship.
create or replace function public.user_profile_data(p_user_id uuid)
    returns table(
        user_id           uuid,
        username          text,
        tag_number        text,  -- varchar(4) on public."user", not an int
        details           jsonb,
        friendship_id     uuid,
        friend_state      text,  -- 'none'|'friend'|'incoming'|'outgoing'|'blocked'
        friend_count      integer,
        shared_lobby_count integer
    )
    language sql stable security definer set search_path to 'public'
as $$
    select u.id,
           u.username::text,
           u.tag_number::text,
           u.details,
           f.id,
           case
               when public.fn_is_blocked(auth.uid(), u.id) then 'blocked'
               when f.status = 'accepted' then 'friend'
               when f.status = 'pending' and f.addressee_id = auth.uid() then 'incoming'
               when f.status = 'pending' then 'outgoing'
               else 'none'
           end,
           (select count(*)::int from public.friendship af
             where af.status = 'accepted'
               and u.id in (af.requester_id, af.addressee_id)),
           (select count(*)::int from public.lobby_member lm
             where lm.user_id = u.id
               and lm.lobby_id in (select public.get_my_lobby_ids()))
    from public."user" u
    left join public.friendship f
        on f.status in ('pending', 'accepted')
       and least(f.requester_id, f.addressee_id) = least(auth.uid(), u.id)
       and greatest(f.requester_id, f.addressee_id) = greatest(auth.uid(), u.id)
    where u.id = p_user_id;
$$;

grant execute on function public.friend_data() to authenticated;
grant execute on function public.user_profile_data(uuid) to authenticated;

-- 11. Retire `pair`.
--     The enum value stays (accepted rows produced real lobbies, and the
--     table's CHECK constraints reference it) — but nothing may create a new
--     one. Friendship is the supported user↔user relationship now.
create or replace function public.fn_reject_pair_befriend()
    returns trigger
    language plpgsql set search_path to ''
as $$
begin
    if new.interaction_type = 'pair' then
        raise exception
            'lobby_befriend_record.pair is retired — use send_friend_request()';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_reject_pair_befriend on public.lobby_befriend_record;
create trigger trg_reject_pair_befriend
    before insert on public.lobby_befriend_record
    for each row execute function public.fn_reject_pair_befriend();

update public.lobby_befriend_record
    set status = 'cancelled'
    where interaction_type = 'pair' and status = 'pending';

-- 12. Enable the new notification kinds.
insert into public.enabled_notification_kind (kind, enabled) values
    ('friend_request',  true),
    ('friend_accepted', true)
on conflict (kind) do update set enabled = excluded.enabled, updated_at = now();
