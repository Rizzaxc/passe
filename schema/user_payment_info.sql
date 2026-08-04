-- ============================================================================
-- Payment info: a user's bank/e-wallet transfer targets (MoMo, bank accounts),
-- shown on their profile for friends/lobby mates to pay them *outside* the
-- app (đá/bill-splitting are unbuilt — see root CLAUDE.md). Visible to the
-- owner, friends, and lobby mates — same audience as fn_can_see_wall_post.
--
-- The account/phone number is never stored as plaintext: it's held in
-- Supabase Vault (`vault.create_secret`), referenced from this table by
-- UUID, and only ever decrypted inside the SECURITY DEFINER functions below.
-- The table itself has RLS enabled with NO policies — `authenticated`/`anon`
-- get nothing from a raw select/insert/delete; the functions are the only
-- way in, and that's also where the friend/lobbymate authorization check
-- lives (same predicate style as get_my_friend_ids/get_my_lobbymate_ids/
-- fn_is_blocked in schema/friendship.sql).
--
-- Idempotent / re-runnable.
-- ============================================================================

create table if not exists public.user_payment_info (
    id                       uuid primary key default gen_random_uuid(),
    user_id                  uuid not null references public."user"(id) on delete cascade,
    bank_id                  text not null,   -- VietQR bin (e.g. '970436' VCB, '971025' MoMo)
    bank_display_name        text not null,   -- shortName snapshotted at add-time
    value_secret_id          uuid not null references vault.secrets(id),   -- account/phone number
    account_name_secret_id   uuid references vault.secrets(id),            -- optional
    created_at               timestamptz not null default now()
);

create index if not exists user_payment_info_user_idx on public.user_payment_info (user_id);

alter table public.user_payment_info enable row level security;
-- Deliberately no policies — every access goes through the functions below.

-- Read: self, or friend/lobbymate not blocked (same predicate as fn_can_see_wall_post's).
create or replace function public.get_payment_info(p_user_id uuid)
    returns table (
        id uuid, bank_id text, bank_display_name text,
        value text, account_name text, created_at timestamptz
    )
    language plpgsql security definer set search_path to 'public'
as $$
begin
    if p_user_id <> auth.uid() and (
        public.fn_is_blocked(auth.uid(), p_user_id)
        or (
            p_user_id not in (select public.get_my_friend_ids())
            and p_user_id not in (select public.get_my_lobbymate_ids())
        )
    ) then
        return;   -- not authorized: empty result, not an error
    end if;

    return query
    select i.id, i.bank_id, i.bank_display_name,
           v_value.decrypted_secret, v_name.decrypted_secret, i.created_at
    from public.user_payment_info i
    join vault.decrypted_secrets v_value on v_value.id = i.value_secret_id
    left join vault.decrypted_secrets v_name on v_name.id = i.account_name_secret_id
    where i.user_id = p_user_id
    order by i.created_at;
end;
$$;

grant execute on function public.get_payment_info(uuid) to authenticated;

-- Write: always inserts for the caller, never a client-supplied user_id.
create or replace function public.add_payment_info(
    p_bank_id text, p_bank_display_name text, p_value text, p_account_name text default null
) returns uuid
    language plpgsql security definer set search_path to 'public'
as $$
declare
    v_value_secret_id uuid := vault.create_secret(p_value);
    v_name_secret_id uuid;
    v_id uuid;
begin
    if p_account_name is not null then
        v_name_secret_id := vault.create_secret(p_account_name);
    end if;

    insert into public.user_payment_info
        (user_id, bank_id, bank_display_name, value_secret_id, account_name_secret_id)
    values (auth.uid(), p_bank_id, p_bank_display_name, v_value_secret_id, v_name_secret_id)
    returning id into v_id;

    return v_id;
end;
$$;

grant execute on function public.add_payment_info(text, text, text, text) to authenticated;

-- Delete: ownership-checked; best-effort cleanup of the underlying vault secrets.
create or replace function public.delete_payment_info(p_id uuid) returns void
    language plpgsql security definer set search_path to 'public'
as $$
declare
    v_value_secret_id uuid;
    v_name_secret_id uuid;
begin
    delete from public.user_payment_info
    where id = p_id and user_id = auth.uid()
    returning value_secret_id, account_name_secret_id
    into v_value_secret_id, v_name_secret_id;

    delete from vault.secrets where id in (v_value_secret_id, v_name_secret_id);
end;
$$;

grant execute on function public.delete_payment_info(uuid) to authenticated;
