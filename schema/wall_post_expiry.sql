-- ============================================================================
-- Wall post TTL sweep.
--
-- Belt and braces, deliberately:
--   1. Every read path already filters `expires_at > now()`, so an expired
--      post is invisible the instant it expires even if the sweep is late.
--   2. This hourly sweep deletes the rows and queues their storage objects,
--      so "ephemeral" is true on disk and not just in the UI.
--
-- Storage deletion has to go out through the Storage API — deleting a row from
-- `storage.objects` in SQL leaves the underlying file behind. So the sweep
-- queues paths into `wall_post_gc` (created in schema/wall_post.sql) and pokes
-- a `gc-wall-images` Edge Function, reusing the exact pg_net + Vault pattern
-- the `send-push` function uses. Until those Vault secrets exist the poke is a
-- no-op and paths simply accumulate in the queue — nothing errors, and no post
-- stays visible either way.
--
-- Depends on: schema/wall_post.sql. Idempotent / re-runnable.
-- ============================================================================

create extension if not exists pg_net;
create extension if not exists pg_cron;

-- 1. Delete expired posts, queueing their images for the GC pass.
create or replace function public.fn_sweep_expired_wall_posts()
    returns int
    language plpgsql security definer set search_path to ''
as $$
declare
    v_count int;
begin
    with expired as (
        delete from public.wall_post
        where expires_at <= now()
        returning image_paths
    ), queued as (
        insert into public.wall_post_gc (path)
        select distinct unnest(image_paths) from expired
        on conflict do nothing
        returning 1
    )
    select count(*) into v_count from queued;

    return v_count;
end;
$$;

-- 2. Hand the queue to the Storage API via the Edge Function.
--    Mirrors fn_poke_send_push in schema/push_notifications.sql: read the URL
--    and service-role key from Vault, fire and forget through pg_net. The
--    function is responsible for removing the rows it successfully deletes.
create or replace function public.fn_poke_wall_gc()
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_url text;
    v_key text;
begin
    if not exists (select 1 from public.wall_post_gc limit 1) then
        return;  -- nothing queued, don't spend a request
    end if;

    select decrypted_secret into v_url
        from vault.decrypted_secrets where name = 'edge_wall_gc_url';
    select decrypted_secret into v_key
        from vault.decrypted_secrets where name = 'edge_service_role_key';

    if v_url is null or v_key is null then
        return;  -- not provisioned yet; the queue waits
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || v_key
        ),
        body := '{}'::jsonb
    );
end;
$$;

-- 3. One tick does both.
create or replace function public.fn_wall_cron_tick()
    returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    perform public.fn_sweep_expired_wall_posts();
    perform public.fn_poke_wall_gc();
end;
$$;

-- 4. Schedule hourly. A post is invisible the moment it expires (read filter),
--    so the sweep is about reclaiming storage, not about correctness — hourly
--    is plenty and keeps the cron log quiet.
do $$
begin
    if exists (select 1 from cron.job where jobname = 'wall_post_sweep') then
        perform cron.unschedule('wall_post_sweep');
    end if;
    perform cron.schedule(
        'wall_post_sweep',
        '7 * * * *',
        $cron$select public.fn_wall_cron_tick();$cron$
    );
end$$;

revoke all on function public.fn_sweep_expired_wall_posts() from public, authenticated;
revoke all on function public.fn_poke_wall_gc() from public, authenticated;
revoke all on function public.fn_wall_cron_tick() from public, authenticated;
