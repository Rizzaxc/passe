-- ============================================================================
-- push_notifications.sql — FCM push-notification spine (outbox pattern)
--
-- Pipeline:  domain event  →  fn_enqueue_notification (per-recipient rows in
--            notification_outbox)  →  statement-trigger pokes the `send-push`
--            Edge Function via pg_net (fast path)  →  pg_cron `fn_cron_tick`
--            every minute (a) scans due bookings into the outbox and (b) re-pokes
--            for any stragglers (safety net).  The Edge Function claims pending
--            rows atomically, expands recipient → device tokens, calls FCM HTTP
--            v1, prunes dead tokens, and marks rows sent/failed.
--
-- The "flag system" is data-driven: enabled_notification_kind is an allowlist the
-- enqueue helper checks, so a kind can be dark-launched or kill-switched without a
-- redeploy. `challenger_confirmed` ships reserved-but-dormant (no lobby_challenge
-- table / accept handshake exists yet — see schema/challenger_support.sql).
--
-- Edge-function URL + service-role key are read from Supabase Vault at poke time
-- (secrets: 'edge_send_push_url', 'edge_service_role_key'). Until those exist the
-- poke is a no-op and rows simply wait — nothing errors. See RUNBOOK.
--
-- Idempotent / re-runnable. Apply with Supabase `apply_migration` (DDL).
-- ============================================================================

-- ── 0. Extensions ───────────────────────────────────────────────────────────
create extension if not exists pg_net;   -- async HTTP (net.*)
create extension if not exists pg_cron;  -- scheduler (cron.*)

-- ── 1. Notification kind enum (shared vocabulary, mirrored client-side) ──────
do $$
begin
    if not exists (select 1 from pg_type where typname = 'notification_kind') then
        create type public.notification_kind as enum (
            'activity_confirmed',
            'pro_session_reminder',
            'challenger_confirmed'   -- reserved; dormant until the challenge handshake exists
        );
    end if;
end$$;

-- ── 2. Rollout allowlist (the data-driven feature flag / kill-switch) ────────
create table if not exists public.enabled_notification_kind (
    kind       public.notification_kind primary key,
    enabled    boolean not null default true,
    updated_at timestamptz not null default now()
);

insert into public.enabled_notification_kind (kind, enabled) values
    ('activity_confirmed',   true),
    ('pro_session_reminder', true),
    ('challenger_confirmed', false)
on conflict (kind) do nothing;

-- Server-only table: RLS on, no policies → only SECURITY DEFINER fns / service role.
alter table public.enabled_notification_kind enable row level security;

-- ── 3. Device tokens ─────────────────────────────────────────────────────────
-- fcm_token is globally unique (PK). Registering upserts and MOVES the token to
-- the current user, so logging in account B on account A's phone reassigns it and
-- A stops receiving on that device. Stale tokens are also pruned server-side when
-- FCM returns 404/UNREGISTERED (see the Edge Function).
create table if not exists public.user_device_token (
    fcm_token  text primary key,
    user_id    uuid not null references public."user"(id) on delete cascade,
    platform   text not null check (platform in ('ios', 'android')),
    updated_at timestamptz not null default now()
);
create index if not exists user_device_token_user_idx
    on public.user_device_token (user_id);

alter table public.user_device_token enable row level security;

-- Owner may read / delete (delete-on-logout) their own device rows. Registration
-- goes through the SECURITY DEFINER RPC below (it has to overwrite a row that may
-- currently belong to another user, which an RLS UPDATE could not do).
drop policy if exists "device tokens: read own" on public.user_device_token;
create policy "device tokens: read own" on public.user_device_token
    for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "device tokens: delete own" on public.user_device_token;
create policy "device tokens: delete own" on public.user_device_token
    for delete to authenticated using (user_id = (select auth.uid()));

-- Register / refresh the calling user's device token (upsert moves user).
create or replace function public.register_device_token(
    p_fcm_token text,
    p_platform  text
) returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'register_device_token: not authenticated';
    end if;
    if p_platform not in ('ios', 'android') then
        raise exception 'register_device_token: bad platform %', p_platform;
    end if;

    insert into public.user_device_token (fcm_token, user_id, platform, updated_at)
    values (p_fcm_token, (select auth.uid()), p_platform, now())
    on conflict (fcm_token) do update
        set user_id    = excluded.user_id,
            platform   = excluded.platform,
            updated_at = now();
end;
$$;

revoke all on function public.register_device_token(text, text) from public;
grant execute on function public.register_device_token(text, text) to authenticated;

-- ── 4. Outbox (per-recipient rows; a little send-state machine) ──────────────
create table if not exists public.notification_outbox (
    id                bigint generated always as identity primary key,
    kind              public.notification_kind not null,
    recipient_user_id uuid not null references public."user"(id) on delete cascade,
    title             text not null,
    body              text not null,
    data              jsonb not null default '{}'::jsonb,  -- routing contract {kind,target_id,…}
    status            text not null default 'pending'
                          check (status in ('pending', 'sending', 'sent', 'failed')),
    attempt_count     int  not null default 0,
    last_error        text,
    read_at           timestamptz,                          -- forward-compat: notification centre
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now()
);

-- Hot path: the Edge Function claims unfinished rows; partial index keeps it tiny.
create index if not exists notification_outbox_pending_idx
    on public.notification_outbox (created_at)
    where status in ('pending', 'sending');
-- Future notification-centre read model.
create index if not exists notification_outbox_recipient_idx
    on public.notification_outbox (recipient_user_id, created_at desc);

alter table public.notification_outbox enable row level security;

-- Recipient may read their own notifications (notification-centre groundwork).
-- Writes are server-only (enqueue helper / Edge Function run as definer / service role).
drop policy if exists "outbox: read own" on public.notification_outbox;
create policy "outbox: read own" on public.notification_outbox
    for select to authenticated using (recipient_user_id = (select auth.uid()));

-- ── 5. Enqueue helper (the single write-path every emitter funnels through) ──
-- Honours the allowlist (dormant/killed kinds drop silently), stamps the shared
-- `kind` into data, fans out one row per recipient, then pokes the sender.
create or replace function public.fn_enqueue_notification(
    p_kind       public.notification_kind,
    p_recipients uuid[],
    p_title      text,
    p_body       text,
    p_data       jsonb default '{}'::jsonb
) returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_enabled boolean;
    v_inserted int;
begin
    select enabled into v_enabled
        from public.enabled_notification_kind
        where kind = p_kind;

    if not coalesce(v_enabled, false) then
        return;  -- kind dormant or kill-switched
    end if;

    insert into public.notification_outbox (kind, recipient_user_id, title, body, data)
    select p_kind, r, p_title, p_body,
           coalesce(p_data, '{}'::jsonb) || jsonb_build_object('kind', p_kind::text)
    from unnest(p_recipients) as r
    where r is not null;

    get diagnostics v_inserted = row_count;
    if v_inserted > 0 then
        perform public.fn_invoke_send_push();  -- fast-path poke
    end if;
end;
$$;

-- ── 6. Edge-function poke (pg_net → send-push), config read from Vault ────────
create or replace function public.fn_invoke_send_push()
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_url text;
    v_key text;
begin
    select decrypted_secret into v_url
        from vault.decrypted_secrets where name = 'edge_send_push_url';
    select decrypted_secret into v_key
        from vault.decrypted_secrets where name = 'edge_service_role_key';

    -- Not configured yet → leave rows for the cron sweeper; never error.
    if v_url is null or v_key is null then
        return;
    end if;

    perform net.http_post(
        url     := v_url,
        headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || v_key
        ),
        body    := '{}'::jsonb
    );
end;
$$;

-- ── 7. Statement-level webhook: poke once per enqueue insert ─────────────────
create or replace function public.fn_outbox_poke()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
begin
    perform public.fn_invoke_send_push();
    return null;
end;
$$;

drop trigger if exists notification_outbox_poke on public.notification_outbox;
create trigger notification_outbox_poke
    after insert on public.notification_outbox
    for each statement execute function public.fn_outbox_poke();

-- ── 8. Emitter: activity_confirmed (fires on the quorum-crossing RSVP) ───────
-- One push to every lobby member the moment count(activity_confirmation) first
-- reaches confirmation_threshold. Always-confirmed (NULL threshold) and non-lobby
-- (booking) activities have no quorum event and are skipped.
create or replace function public.fn_emit_activity_confirmed()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_threshold  int;
    v_lobby_id   uuid;
    v_count      int;
    v_recipients uuid[];
    v_lobby_name text;
begin
    select a.confirmation_threshold, a.lobby_id
        into v_threshold, v_lobby_id
        from public.activity a
        where a.id = new.activity_id;

    if v_threshold is null or v_lobby_id is null then
        return new;
    end if;

    select count(*) into v_count
        from public.activity_confirmation
        where activity_id = new.activity_id;

    if v_count <> v_threshold then
        return new;  -- below quorum, or already crossed on an earlier row
    end if;

    select array_agg(lm.user_id) into v_recipients
        from public.lobby_member lm
        where lm.lobby_id = v_lobby_id;

    select l.name into v_lobby_name from public.lobby l where l.id = v_lobby_id;

    perform public.fn_enqueue_notification(
        'activity_confirmed',
        v_recipients,
        'Hoạt động đã được chốt',
        coalesce(v_lobby_name, 'Lobby') || ' đã đủ người tham gia',
        jsonb_build_object('target_id', new.activity_id::text,
                           'lobby_id',  v_lobby_id::text)
    );
    return new;
end;
$$;

drop trigger if exists activity_confirmation_emit_confirmed on public.activity_confirmation;
create trigger activity_confirmation_emit_confirmed
    after insert on public.activity_confirmation
    for each row execute function public.fn_emit_activity_confirmed();

-- ── 9. Emitter: pro_session_reminder (T-1h, cron-driven, single-shot) ────────
alter table public.professional_booking
    add column if not exists reminder_sent_at timestamptz;

-- Scan confirmed bookings starting within the next hour; enqueue once, then stamp
-- reminder_sent_at so a later tick can't re-send. SKIP LOCKED keeps ticks disjoint.
create or replace function public.fn_process_reminders()
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    r record;
begin
    for r in
        select b.id, b.booking_time_start, b.client_user_id
            from public.professional_booking b
            where b.reminder_sent_at is null
              and b.status = 'confirmed'
              and b.booking_time_start >  now()
              and b.booking_time_start <= now() + interval '1 hour'
            for update skip locked
    loop
        perform public.fn_enqueue_notification(
            'pro_session_reminder',
            (select array_agg(uid) from (
                 select r.client_user_id as uid
                 union
                 select au.user_id
                     from public.booking_additional_users au
                     where au.booking_id = r.id
             ) s),
            'Sắp tới giờ tập với coach',
            'Buổi tập của bạn bắt đầu lúc '
                || to_char(r.booking_time_start at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI'),
            jsonb_build_object('target_id', r.id::text)
        );
        update public.professional_booking
            set reminder_sent_at = now()
            where id = r.id;
    end loop;
end;
$$;

-- ── 10. Cron tick: reminders + straggler re-poke, once a minute ──────────────
create or replace function public.fn_cron_tick()
    returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    perform public.fn_process_reminders();
    -- Re-poke if anything is still unfinished (webhook miss / FCM 5xx / cold start).
    if exists (select 1 from public.notification_outbox
                where status in ('pending', 'sending')) then
        perform public.fn_invoke_send_push();
    end if;
end;
$$;

-- (Re)register the schedule.
select cron.unschedule('push-cron-tick')
    where exists (select 1 from cron.job where jobname = 'push-cron-tick');
select cron.schedule('push-cron-tick', '* * * * *', $$select public.fn_cron_tick();$$);

-- ── 11. Atomic claim for the Edge Function ───────────────────────────────────
-- Flips a batch of unfinished rows to `sending` (attempt_count++) and returns
-- them. SKIP LOCKED keeps concurrent invocations (trigger poke vs cron sweep)
-- disjoint; rows wedged in `sending` past p_stale are reclaimable.
create or replace function public.fn_claim_outbox(
    p_limit        int  default 100,
    p_max_attempts int  default 3,
    p_stale        text default '2 minutes'
) returns setof public.notification_outbox
    language plpgsql security definer set search_path to ''
as $$
begin
    return query
    update public.notification_outbox o
       set status        = 'sending',
           attempt_count = o.attempt_count + 1,
           updated_at    = now()
     where o.id in (
        select id from public.notification_outbox
         where attempt_count < p_max_attempts
           and (status = 'pending'
                or (status = 'sending' and updated_at < now() - p_stale::interval))
         order by created_at
         limit p_limit
         for update skip locked
     )
    returning o.*;
end;
$$;

revoke all on function public.fn_claim_outbox(int, int, text) from public;
grant execute on function public.fn_claim_outbox(int, int, text) to service_role;
