-- ============================================================================
-- account_deletion.sql — self-service account deletion (outbox pattern)
--
-- Deleting `auth.users` requires the Admin API (service-role only) — a normal
-- SECURITY DEFINER function can't do it directly. So this mirrors the existing
-- push-notification pipeline (schema/push_notifications.sql):
--
--   request_account_deletion()  →  cleans up public-schema data owned by the
--   caller, deletes their public.user row, then queues one row in
--   account_deletion_request  →  AFTER-INSERT trigger pokes the Edge Function
--   `delete-account` via pg_net (fast path)  →  pg_cron re-pokes any stragglers
--   once a minute (safety net)  →  the function claims the row and calls
--   `auth.admin.deleteUser(user_id)` with the service-role key.
--
-- Edge-function URL + shared invoke secret are read from Supabase Vault at
-- poke time (secrets: 'edge_delete_account_url', 'edge_service_role_key' —
-- the latter is already provisioned for send-push and is reused here). Until
-- 'edge_delete_account_url' exists the poke is a no-op and the row just waits
-- for the cron sweep once it's set. See docs/push_notifications_runbook.md
-- for the exact provisioning steps this mirrors (swap function name/secrets).
--
-- What request_account_deletion() does NOT do: silently resolve lobby
-- captaincy or an active freeplay-host profile on the caller's behalf. Both
-- block deletion with a clear error — the existing
-- lobby_member_prevent_captain_leave trigger (schema/lobby_membership_integrity.sql)
-- already enforces the captain case for free when we DELETE the caller's
-- lobby_member rows below; the freeplay-host case is checked explicitly.
--
-- Idempotent / re-runnable. Apply with Supabase `apply_migration` (DDL).
-- ============================================================================

-- ── 0. Preserve immutable/attributed content instead of blocking deletion ────
-- Both columns were NOT NULL + implicit RESTRICT, which would make deletion
-- fail outright for anyone who ever left a referee review or created a lobby
-- invite link. Match the existing pattern used everywhere else an author-ish
-- reference needs to survive its author's departure (wall_post.author_id,
-- message.sender_id, lobby_feed_item.author_id are all nullable + SET NULL).

alter table public.referee_booking_review
    alter column reviewer_user_id drop not null;

alter table public.referee_booking_review
    drop constraint if exists professional_booking_review_reviewer_user_id_fkey;
alter table public.referee_booking_review
    add constraint professional_booking_review_reviewer_user_id_fkey
        foreign key (reviewer_user_id) references public."user"(id) on delete set null;

alter table public.lobby_invite_link
    alter column created_by drop not null;

alter table public.lobby_invite_link
    drop constraint if exists lobby_invite_link_created_by_fkey;
alter table public.lobby_invite_link
    add constraint lobby_invite_link_created_by_fkey
        foreign key (created_by) references public."user"(id) on delete set null;

-- ── 1. Deletion outbox ────────────────────────────────────────────────────────
-- Deliberately NO foreign key on user_id: by the time this row is inserted the
-- public.user row is already gone (that's the point — this row is what tells
-- the Edge Function which auth.users id to remove next). Adding a FK here
-- would either block the insert or need careful ordering footguns; a plain
-- uuid sidesteps the whole class of problem.
create table if not exists public.account_deletion_request (
    id            bigint generated always as identity primary key,
    user_id       uuid not null,
    status        text not null default 'pending'
                      check (status in ('pending', 'processing', 'done', 'failed')),
    attempt_count int  not null default 0,
    last_error    text,
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

create index if not exists account_deletion_request_pending_idx
    on public.account_deletion_request (created_at)
    where status in ('pending', 'processing');

-- Server-only table: RLS on, no policies → only SECURITY DEFINER fns / service role.
alter table public.account_deletion_request enable row level security;

-- ── 2. Atomic claim for the Edge Function (mirrors fn_claim_outbox) ───────────
create or replace function public.fn_claim_account_deletion_requests(
    p_limit        int  default 20,
    p_max_attempts int  default 3,
    p_stale        text default '2 minutes'
) returns setof public.account_deletion_request
    language plpgsql security definer set search_path to ''
as $$
begin
    return query
    update public.account_deletion_request r
       set status        = 'processing',
           attempt_count = r.attempt_count + 1,
           updated_at    = now()
     where r.id in (
        select id from public.account_deletion_request
         where attempt_count < p_max_attempts
           and (status = 'pending'
                or (status = 'processing' and updated_at < now() - p_stale::interval))
         order by created_at
         limit p_limit
         for update skip locked
     )
    returning r.*;
end;
$$;

revoke all on function public.fn_claim_account_deletion_requests(int, int, text) from public;
grant execute on function public.fn_claim_account_deletion_requests(int, int, text) to service_role;

-- ── 3. Edge-function poke (pg_net → delete-account), config read from Vault ──
create or replace function public.fn_invoke_delete_account()
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_url text;
    v_key text;
begin
    select decrypted_secret into v_url
        from vault.decrypted_secrets where name = 'edge_delete_account_url';
    select decrypted_secret into v_key
        from vault.decrypted_secrets where name = 'edge_service_role_key';

    -- Not configured yet → leave the row for the cron sweeper; never error.
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

create or replace function public.fn_account_deletion_poke()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
begin
    perform public.fn_invoke_delete_account();
    return null;
end;
$$;

drop trigger if exists account_deletion_request_poke on public.account_deletion_request;
create trigger account_deletion_request_poke
    after insert on public.account_deletion_request
    for each statement execute function public.fn_account_deletion_poke();

-- ── 4. Cron safety net (own 1-minute schedule; independent of the push cron) ─
create or replace function public.fn_account_deletion_cron_tick()
    returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    if exists (select 1 from public.account_deletion_request
                where status in ('pending', 'processing')) then
        perform public.fn_invoke_delete_account();
    end if;
end;
$$;

select cron.unschedule('account-deletion-cron-tick')
    where exists (select 1 from cron.job where jobname = 'account-deletion-cron-tick');
select cron.schedule('account-deletion-cron-tick', '* * * * *',
    $$select public.fn_account_deletion_cron_tick();$$);

-- ── 5. The user-facing RPC ────────────────────────────────────────────────────
create or replace function public.request_account_deletion()
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_user_id uuid;
begin
    v_user_id := auth.uid();
    if v_user_id is null then
        raise exception 'Not authenticated';
    end if;

    -- Leave every lobby. Reuses the existing captain-leave guard trigger
    -- (lobby_member_prevent_captain_leave) — if this user still captains any
    -- lobby, this DELETE raises 'Captain cannot leave lobby % — transfer
    -- captaincy first' and the whole deletion aborts. No separate check needed.
    delete from public.lobby_member where user_id = v_user_id;

    -- An active freeplay-host profile isn't safe to tear down silently here —
    -- other users may have open seat requests / activities tied to it. Block
    -- with a distinct, parseable message instead of guessing what to do.
    if exists (select 1 from public.freeplay_host where user_id = v_user_id) then
        raise exception 'Cannot delete account: still an active freeplay host';
    end if;

    -- RESTRICT-guarded rows that are safe to just drop (no other user's data
    -- depends on their content surviving).
    delete from public.lobby_befriend_record
        where initiator_user_id = v_user_id or target_user_id = v_user_id;
    delete from public.user_industry where user_id = v_user_id;
    delete from public.user_network  where user_id = v_user_id;

    -- Everything else cascades or SETs NULL automatically via existing FKs —
    -- activity_confirmation, health data, ratings, wall posts, reactions,
    -- messages, friendships, device tokens, referee reviews, invite links
    -- (the last two per section 0 above). See schema/passe.sql for the full
    -- FK list on public.user(id).
    delete from public."user" where id = v_user_id;

    -- Queue the privileged auth.users deletion — see sections 1-4 above.
    insert into public.account_deletion_request (user_id) values (v_user_id);
end;
$$;

revoke all on function public.request_account_deletion() from public;
grant execute on function public.request_account_deletion() to authenticated;
