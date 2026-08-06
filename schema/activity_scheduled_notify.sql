-- activity_scheduled: push lobby members the moment a captain/coordinator puts up
-- (creates) a new activity, so they know to RSVP. Deliberately creation-only —
-- reschedule()/cancel() stay feed-only (lobby_feed_item), same as today, to avoid
-- pushing on every minor time tweak.
--
-- Trigger-based, not RPC-based: activity creation is a direct client-side insert
-- into `activity` (see ScheduleActivityController.schedule() in
-- lib/manage_tab/lobby_section/schedule_activity_controller.dart), not a SECURITY
-- DEFINER RPC — same shape as fn_emit_activity_confirmed.
--
-- Requires schema/activity_scheduled_notify_enum.sql applied first (enum value must
-- commit before this file's DEFAULT/usage of it).

create or replace function public.fn_emit_activity_scheduled()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_recipients     uuid[];
    v_lobby_name     text;
    v_location_name  text;
begin
    -- Skip standalone pro-session activities (no lobby) and challenge-materialized
    -- activities (respond_challenge's accept branch is the only other INSERT into
    -- `activity` with challenge_id set — those already get challenge_received /
    -- challenge_scheduled, a second generic push here would be redundant).
    if new.lobby_id is null or new.challenge_id is not null then
        return new;
    end if;

    select array_agg(lm.user_id) into v_recipients
        from public.lobby_member lm
        where lm.lobby_id = new.lobby_id and lm.user_id <> new.user_id;

    if v_recipients is null or array_length(v_recipients, 1) = 0 then
        return new;
    end if;

    select l.name into v_lobby_name from public.lobby l where l.id = new.lobby_id;
    select loc.name into v_location_name from public.location loc where loc.id = new.location_id;

    perform public.fn_enqueue_notification(
        'activity_scheduled',
        v_recipients,
        coalesce(v_lobby_name, 'Lobby') || ' vừa lên lịch buổi chơi mới',
        'Lúc ' || to_char(new.start_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI DD/MM')
            || coalesce(' tại ' || v_location_name, '') || ' — xác nhận tham gia nhé',
        jsonb_build_object('lobby_id', new.lobby_id, 'activity_id', new.id)
    );

    return new;
end;
$$;

drop trigger if exists activity_scheduled_emit on public.activity;
create trigger activity_scheduled_emit
    after insert on public.activity
    for each row execute function public.fn_emit_activity_scheduled();

insert into public.enabled_notification_kind (kind, enabled) values
    ('activity_scheduled', true)
on conflict (kind) do nothing;
