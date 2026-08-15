-- Push notifications for the lobby join-request lifecycle.
--
-- Requires schema/lobby_join_request_notify_enum.sql to be applied and
-- committed first.
--
-- A request INSERT notifies the lobby captain. A real manager decision on a
-- pending request notifies the original requester. The response trigger also
-- covers the existing reciprocal-invite path, which accepts the pending
-- request in the BEFORE INSERT trigger and cancels the new invite row.

create or replace function public.fn_emit_lobby_join_request()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_captain_id     uuid;
    v_lobby_name     text;
    v_requester_name text;
begin
    if new.interaction_type <> 'request'
       or new.status <> 'pending'
       or new.target_lobby_id is null then
        return new;
    end if;

    select l.captain_id, l.name
      into v_captain_id, v_lobby_name
      from public.lobby l
     where l.id = new.target_lobby_id;

    if v_captain_id is null then
        return new;
    end if;

    select concat(u.username, '#', u.tag_number)
      into v_requester_name
      from public."user" u
     where u.id = new.initiator_user_id;

    perform public.fn_enqueue_notification(
        'lobby_join_request',
        array[v_captain_id],
        'Yêu cầu tham gia lobby',
        coalesce(v_requester_name, 'Một người chơi') ||
            ' muốn tham gia ' || coalesce(v_lobby_name, 'lobby của bạn'),
        jsonb_build_object(
            'lobby_id', new.target_lobby_id::text,
            'record_id', new.id::text,
            'user_id', new.initiator_user_id::text
        )
    );

    return new;
end;
$$;

drop trigger if exists lobby_join_request_notify
    on public.lobby_befriend_record;
create trigger lobby_join_request_notify
    after insert on public.lobby_befriend_record
    for each row
    when (
        new.interaction_type = 'request'
        and new.status = 'pending'
    )
    execute function public.fn_emit_lobby_join_request();

create or replace function public.fn_emit_lobby_join_request_response()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_lobby_name text;
begin
    if new.interaction_type <> 'request'
       or old.status <> 'pending'
       or new.status not in ('accepted', 'declined')
       or new.target_lobby_id is null then
        return new;
    end if;

    -- The table's broad legacy UPDATE policy also lets an initiator cancel
    -- their own request. Only a captain/coordinator decision is an approval or
    -- denial worthy of a push; this also prevents a forged self-response push.
    if not public.lobby_can_manage(new.target_lobby_id, auth.uid()) then
        return new;
    end if;

    select l.name
      into v_lobby_name
      from public.lobby l
     where l.id = new.target_lobby_id;

    if new.status = 'accepted' then
        perform public.fn_enqueue_notification(
            'lobby_join_request_approved',
            array[new.initiator_user_id],
            'Yêu cầu tham gia được duyệt',
            'Bạn đã trở thành thành viên của ' ||
                coalesce(v_lobby_name, 'lobby'),
            jsonb_build_object(
                'lobby_id', new.target_lobby_id::text,
                'record_id', new.id::text
            )
        );
    else
        perform public.fn_enqueue_notification(
            'lobby_join_request_denied',
            array[new.initiator_user_id],
            'Yêu cầu tham gia bị từ chối',
            coalesce(v_lobby_name, 'Lobby') ||
                ' đã từ chối yêu cầu tham gia của bạn',
            jsonb_build_object(
                'lobby_id', new.target_lobby_id::text,
                'record_id', new.id::text
            )
        );
    end if;

    return new;
end;
$$;

drop trigger if exists lobby_join_request_response_notify
    on public.lobby_befriend_record;
create trigger lobby_join_request_response_notify
    after update of status on public.lobby_befriend_record
    for each row
    when (
        new.interaction_type = 'request'
        and old.status = 'pending'
        and new.status in ('accepted', 'declined')
    )
    execute function public.fn_emit_lobby_join_request_response();

insert into public.enabled_notification_kind (kind, enabled) values
    ('lobby_join_request', true),
    ('lobby_join_request_approved', true),
    ('lobby_join_request_denied', true)
on conflict (kind) do nothing;
