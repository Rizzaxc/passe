-- ============================================================================
-- Lobby challenge handshake (lobby-vs-lobby "Thách đấu").
--
-- Separate from lobby_befriend_record (that is user↔lobby / user↔user only).
-- A manager (captain or coordinator) of one lobby challenges another lobby that
-- is `open_to_challengers` in the same sport; the target lobby's managers
-- accept or decline. All writes go through SECURITY DEFINER RPCs — clients only
-- get SELECT via RLS.
--
-- Apply in TWO steps (enum ADD VALUE cannot be used in the same transaction it
-- is created in):
--   Part A: notification_kind enum additions  (own migration)
--   Part B: everything else                   (own migration)
-- ============================================================================

-- ─── Part A — notification kinds (apply as its own migration) ───────────────
-- ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'challenge_received';
-- ALTER TYPE public.notification_kind ADD VALUE IF NOT EXISTS 'challenge_declined';

-- ─── Part B ─────────────────────────────────────────────────────────────────

-- 1. Status enum
do $$
begin
    if not exists (select 1 from pg_type where typname = 'lobby_challenge_status') then
        create type public.lobby_challenge_status as enum (
            'requested', 'accepted', 'declined', 'cancelled'
        );
    end if;
end$$;

-- 2. Table
create table if not exists public.lobby_challenge (
    id                 uuid primary key default gen_random_uuid(),
    initiator_lobby_id uuid not null references public.lobby(id) on delete cascade,
    target_lobby_id    uuid not null references public.lobby(id) on delete cascade,
    sport_id           bigint not null,
    status             public.lobby_challenge_status not null default 'requested',
    proposed_time      timestamptz,
    proposed_location  uuid references public.location(id),
    note               text,
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),
    constraint lobby_challenge_distinct check (initiator_lobby_id <> target_lobby_id)
);

-- At most one open challenge per (initiator, target).
create unique index if not exists lobby_challenge_one_open
    on public.lobby_challenge (initiator_lobby_id, target_lobby_id)
    where status = 'requested';

-- Incoming-challenge lookups by target lobby.
create index if not exists lobby_challenge_target_idx
    on public.lobby_challenge (target_lobby_id, status);

-- 3. RLS — members of either lobby can read; no direct writes (RPCs only).
alter table public.lobby_challenge enable row level security;

drop policy if exists "Members of either lobby can read challenges" on public.lobby_challenge;
create policy "Members of either lobby can read challenges"
    on public.lobby_challenge for select to authenticated
    using (
        initiator_lobby_id in (select public.get_my_lobby_ids())
        or target_lobby_id in (select public.get_my_lobby_ids())
    );

-- 4. Send a challenge (initiator manager → target lobby)
create or replace function public.send_challenge(
    p_initiator_lobby uuid,
    p_target_lobby    uuid,
    p_proposed_time   timestamptz default null,
    p_note            text default null
) returns uuid
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid          uuid := auth.uid();
    v_sport        bigint;
    v_target_open  boolean;
    v_target_sport bigint;
    v_id           uuid;
    v_recipients   uuid[];
    v_init_name    text;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    if p_initiator_lobby = p_target_lobby then
        raise exception 'cannot challenge your own lobby';
    end if;
    if not public.lobby_can_manage(p_initiator_lobby, v_uid) then
        raise exception 'not a manager of the initiating lobby';
    end if;

    select sport_id into v_sport from public.lobby where id = p_initiator_lobby;
    select open_to_challengers, sport_id
        into v_target_open, v_target_sport
        from public.lobby where id = p_target_lobby;

    if v_target_sport is null then raise exception 'target lobby not found'; end if;
    if v_sport is distinct from v_target_sport then raise exception 'sport mismatch'; end if;
    if not coalesce(v_target_open, false) then
        raise exception 'target lobby is not open to challengers';
    end if;

    if exists (
        select 1 from public.lobby_challenge
        where initiator_lobby_id = p_initiator_lobby
          and target_lobby_id = p_target_lobby
          and status = 'requested'
    ) then
        raise exception 'a challenge is already pending for this lobby';
    end if;

    insert into public.lobby_challenge
        (initiator_lobby_id, target_lobby_id, sport_id, proposed_time, note)
    values (p_initiator_lobby, p_target_lobby, v_sport, p_proposed_time, p_note)
    returning id into v_id;

    select array_agg(uid) into v_recipients from (
        select captain_id as uid from public.lobby where id = p_target_lobby
        union
        select user_id from public.lobby_member
            where lobby_id = p_target_lobby and role = 'coordinator'
    ) s;

    select name into v_init_name from public.lobby where id = p_initiator_lobby;

    perform public.fn_enqueue_notification(
        'challenge_received',
        v_recipients,
        'Lời thách đấu mới',
        coalesce(v_init_name, 'Một đội') || ' muốn thách đấu với bạn',
        jsonb_build_object('lobby_id', p_target_lobby, 'challenge_id', v_id)
    );

    return v_id;
end;
$$;

-- 5. Respond to a challenge (target manager: accept / decline)
create or replace function public.respond_challenge(
    p_challenge_id uuid,
    p_action       text
) returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid         uuid := auth.uid();
    v_init        uuid;
    v_target      uuid;
    v_status      public.lobby_challenge_status;
    v_target_name text;
    v_recipients  uuid[];
begin
    if v_uid is null then raise exception 'not authenticated'; end if;

    select initiator_lobby_id, target_lobby_id, status
        into v_init, v_target, v_status
        from public.lobby_challenge where id = p_challenge_id;

    if v_init is null then raise exception 'challenge not found'; end if;
    if not public.lobby_can_manage(v_target, v_uid) then
        raise exception 'not a manager of the target lobby';
    end if;
    if v_status <> 'requested' then raise exception 'challenge is no longer open'; end if;

    select name into v_target_name from public.lobby where id = v_target;

    if p_action = 'accept' then
        update public.lobby_challenge
            set status = 'accepted', updated_at = now() where id = p_challenge_id;
        select array_agg(user_id) into v_recipients
            from public.lobby_member where lobby_id = v_init;
        perform public.fn_enqueue_notification(
            'challenger_confirmed', v_recipients,
            'Thách đấu được chấp nhận',
            coalesce(v_target_name, 'Đối thủ') || ' đã chấp nhận lời thách đấu',
            jsonb_build_object('lobby_id', v_init, 'challenge_id', p_challenge_id));
    elsif p_action = 'decline' then
        update public.lobby_challenge
            set status = 'declined', updated_at = now() where id = p_challenge_id;
        select array_agg(uid) into v_recipients from (
            select captain_id as uid from public.lobby where id = v_init
            union
            select user_id from public.lobby_member
                where lobby_id = v_init and role = 'coordinator'
        ) s;
        perform public.fn_enqueue_notification(
            'challenge_declined', v_recipients,
            'Thách đấu bị từ chối',
            coalesce(v_target_name, 'Đối thủ') || ' đã từ chối lời thách đấu',
            jsonb_build_object('lobby_id', v_init, 'challenge_id', p_challenge_id));
    else
        raise exception 'invalid action %', p_action;
    end if;
end;
$$;

-- 6. Cancel a pending challenge (initiator manager)
create or replace function public.cancel_challenge(p_challenge_id uuid)
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid  uuid := auth.uid();
    v_init uuid;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    select initiator_lobby_id into v_init
        from public.lobby_challenge
        where id = p_challenge_id and status = 'requested';
    if v_init is null then raise exception 'no open challenge to cancel'; end if;
    if not public.lobby_can_manage(v_init, v_uid) then
        raise exception 'not a manager of the initiating lobby';
    end if;
    update public.lobby_challenge
        set status = 'cancelled', updated_at = now() where id = p_challenge_id;
end;
$$;

grant execute on function public.send_challenge(uuid, uuid, timestamptz, text) to authenticated;
grant execute on function public.respond_challenge(uuid, text) to authenticated;
grant execute on function public.cancel_challenge(uuid) to authenticated;

-- 7. Incoming/outgoing challenge feed for a lobby (managers act on incoming).
create or replace function public.lobby_challenge_data(p_lobby_id uuid)
    returns table(
        id uuid,
        direction text,          -- 'incoming' | 'outgoing'
        other_lobby_id uuid,
        other_lobby_name text,
        other_lobby_mmr integer,
        sport_id bigint,
        status public.lobby_challenge_status,
        proposed_time timestamptz,
        note text,
        created_at timestamptz
    )
    language sql stable security invoker set search_path to ''
as $$
    select c.id,
           case when c.target_lobby_id = p_lobby_id then 'incoming' else 'outgoing' end,
           case when c.target_lobby_id = p_lobby_id then c.initiator_lobby_id else c.target_lobby_id end,
           ol.name, ol.mmr, c.sport_id, c.status, c.proposed_time, c.note, c.created_at
    from public.lobby_challenge c
    join public.lobby ol
        on ol.id = case when c.target_lobby_id = p_lobby_id
                        then c.initiator_lobby_id else c.target_lobby_id end
    where (c.initiator_lobby_id = p_lobby_id or c.target_lobby_id = p_lobby_id)
      and c.status in ('requested', 'accepted')
    order by c.created_at desc;
$$;

grant execute on function public.lobby_challenge_data(uuid) to authenticated;

-- 8. Enable the challenge notification kinds (challenger_confirmed was reserved).
insert into public.enabled_notification_kind (kind, enabled) values
    ('challenger_confirmed', true),
    ('challenge_received',   true),
    ('challenge_declined',   true)
on conflict (kind) do update set enabled = excluded.enabled, updated_at = now();
