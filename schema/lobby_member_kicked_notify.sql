-- member_kicked: push a member the moment a captain removes them from a lobby.
--
-- Kicking isn't its own RPC — it's a direct client-side DELETE on `lobby_member`
-- (LobbyMembersController.kick() in lib/manage_tab/lobby_section/members/controller.dart),
-- the same table/shape a member's own voluntary leave() uses. The two are told
-- apart the same way "Lobby membership deletion policy" RLS already does:
-- self-removal (OLD.user_id = auth.uid()) is a leave, not a kick, and is skipped
-- here. RLS also means only the captain can ever delete someone *else*'s row, so
-- reaching the "someone else" branch below already implies a captain-initiated kick.
--
-- Also skipped when the whole lobby is being deleted in this transaction
-- (app.lobby_being_deleted, set by lobby_before_delete) — that's a lobby teardown,
-- not a targeted removal, even though in practice lobby_before_delete only allows
-- that when no other members remain.
--
-- Requires schema/lobby_member_kicked_notify_enum.sql applied first (enum value
-- must commit before this file's usage of it).

create or replace function public.fn_emit_member_kicked()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_lobby_name    text;
    v_being_deleted text;
begin
    if old.user_id = (select auth.uid()) then
        return old;  -- self-leave, not a kick
    end if;

    v_being_deleted := current_setting('app.lobby_being_deleted', true);
    if v_being_deleted = old.lobby_id::text then
        return old;  -- lobby teardown, not a targeted removal
    end if;

    select name into v_lobby_name from public.lobby where id = old.lobby_id;
    if v_lobby_name is null then
        return old;  -- lobby already gone
    end if;

    perform public.fn_enqueue_notification(
        'member_kicked',
        ARRAY[old.user_id],
        'Bạn đã bị xoá khỏi lobby',
        'Bạn không còn là thành viên của ' || v_lobby_name,
        jsonb_build_object('lobby_id', old.lobby_id::text)
    );

    return old;
end;
$$;

drop trigger if exists lobby_member_kicked_emit on public.lobby_member;
create trigger lobby_member_kicked_emit
    after delete on public.lobby_member
    for each row execute function public.fn_emit_member_kicked();

insert into public.enabled_notification_kind (kind, enabled) values
    ('member_kicked', true)
on conflict (kind) do nothing;
