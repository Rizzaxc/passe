-- Notification centre: mark-read RPCs for notification_outbox.
--
-- notification_outbox already has read_at + a self-SELECT RLS policy
-- ("forward-compat: notification centre" — see schema/push_notifications.sql).
-- Writes to the table are otherwise server-only by design (enqueue helper /
-- Edge Function run as definer / service role) — rather than add a broad
-- client UPDATE policy, these two narrow SECURITY DEFINER RPCs are the only
-- way a client can flip read_at, and only ever on their own rows.

create or replace function public.fn_mark_notification_read(p_id bigint)
returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    update public.notification_outbox
        set read_at = now()
        where id = p_id and recipient_user_id = auth.uid() and read_at is null;
end;
$$;

create or replace function public.fn_mark_all_notifications_read()
returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    update public.notification_outbox
        set read_at = now()
        where recipient_user_id = auth.uid() and read_at is null;
end;
$$;

revoke all on function public.fn_mark_notification_read(bigint) from public;
revoke all on function public.fn_mark_all_notifications_read() from public;
grant execute on function public.fn_mark_notification_read(bigint) to authenticated;
grant execute on function public.fn_mark_all_notifications_read() to authenticated;

-- Same rationale as above: no client DELETE policy on notification_outbox, just
-- these two narrow SECURITY DEFINER RPCs, scoped to the caller's own rows.
create or replace function public.fn_delete_notification(p_id bigint)
returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    delete from public.notification_outbox
        where id = p_id and recipient_user_id = auth.uid();
end;
$$;

create or replace function public.fn_clear_read_notifications()
returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    delete from public.notification_outbox
        where recipient_user_id = auth.uid() and read_at is not null;
end;
$$;

revoke all on function public.fn_delete_notification(bigint) from public;
revoke all on function public.fn_clear_read_notifications() from public;
grant execute on function public.fn_delete_notification(bigint) to authenticated;
grant execute on function public.fn_clear_read_notifications() to authenticated;
