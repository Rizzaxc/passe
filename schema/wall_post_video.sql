-- ============================================================================
-- Wall post video support.
--
-- wall_post.image_paths (text[], 1-4 image paths) becomes wall_post.media
-- (jsonb, an ordered array of 1-4 mixed image/video items):
--   {"type": "image", "path": "<uid>/<file>.jpg"}
--   {"type": "video", "path": "<uid>/<file>.mp4", "duration_ms": 42000,
--    "thumbnail_path": "<uid>/<file>.jpg"}
--
-- Images keep living in the `wall_post` bucket. Video is much larger (a
-- compressed 60s clip commonly runs 5-25MB vs ~250KB for a compressed photo)
-- so it gets its own `wall_post_video` bucket — keeps the image bucket's size
-- profile unchanged and makes storage/bandwidth for each media type
-- separately visible. Video thumbnails (poster frames, generated client-side
-- at compose time) are small JPEGs and live in the `wall_post` bucket
-- alongside the photos.
--
-- No backfill: existing rows lose their image_paths on deploy and render as
-- an empty card until they naturally expire (TTL is at most 7 days).
--
-- Depends on: schema/wall_post.sql, schema/wall_post_expiry.sql,
-- schema/wall_feed_rpc.sql, schema/lobby_feed_author_avatar.sql,
-- schema/wall_moderation.sql. Idempotent / re-runnable.
-- ============================================================================

-- 1. Validate a media array's shape. Used both as a table CHECK (so no write
--    path — including a raw insert that bypasses create_wall_post, same
--    caveat as the pre-existing image-count CHECK — can produce a malformed
--    row) and, for a cleaner error message, from create_wall_post itself
--    before it ever reaches the constraint.
--
--    duration_ms is self-reported by the client — nothing here actually
--    probes the video file — so this guarantees "no client bug/version ever
--    wrote a mislabeled row", not "no malicious client ever lied".
create or replace function public.fn_valid_wall_post_media(p_media jsonb)
    returns boolean
    language sql immutable
    set search_path to ''
as $$
    select
        jsonb_typeof(p_media) = 'array'
        and jsonb_array_length(p_media) between 1 and 4
        and not exists (
            select 1 from jsonb_array_elements(p_media) elem
            where (elem->>'type') not in ('image', 'video')
               or coalesce(elem->>'path', '') = ''
               or (
                    (elem->>'type') = 'video'
                    and coalesce((elem->>'duration_ms')::numeric, 0) > 60000
                  )
        );
$$;

-- 2. Table shape. The moderation view reads image_paths directly (not
--    through a function), so it has to be dropped before the column can be —
--    recreated in step 11 below, reading media instead.
drop view if exists public.wall_post_moderation_queue;

alter table public.wall_post drop column if exists image_paths;
alter table public.wall_post add column if not exists media jsonb
    not null default '[]'::jsonb;
alter table public.wall_post alter column media drop default;

alter table public.wall_post drop constraint if exists wall_post_media_shape;
-- NOT VALID: don't choke on rows already live at deploy time (see header) —
-- still fully enforced for every insert/update from here on.
alter table public.wall_post add constraint wall_post_media_shape
    check (public.fn_valid_wall_post_media(media)) not valid;

-- 3. Video bucket. Same public + unguessable-UUID-path pattern as
--    `wall_post` (see that file's header for why). 25MB matches the
--    client-side pre-upload check in compose_controller.dart; kept here too
--    as defense-in-depth against a bypassed client.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('wall_post_video', 'wall_post_video', true, 26214400,
        array['video/mp4', 'video/quicktime', 'video/x-m4v'])
on conflict (id) do update
    set file_size_limit = excluded.file_size_limit,
        allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "wall_post_video: owner can upload" on storage.objects;
create policy "wall_post_video: owner can upload"
    on storage.objects for insert to authenticated
    with check (
        bucket_id = 'wall_post_video'
        and split_part(name, '/', 1) = auth.uid()::text
    );

drop policy if exists "wall_post_video: owner can delete" on storage.objects;
create policy "wall_post_video: owner can delete"
    on storage.objects for delete to authenticated
    using (
        bucket_id = 'wall_post_video'
        and split_part(name, '/', 1) = auth.uid()::text
    );

-- No SELECT policy, same reasoning as `wall_post`'s bucket: a public bucket
-- serves bytes over /object/public/ without consulting RLS, so a SELECT
-- policy would only enable `list` — letting any client enumerate every
-- object path in the bucket, defeating the unguessable-path premise.

-- 4. wall_post_gc needs to know which bucket a queued path belongs to, now
--    that images/thumbnails (`wall_post`) and video (`wall_post_video`)
--    split across two buckets.
alter table public.wall_post_gc add column if not exists bucket_id text
    not null default 'wall_post';
alter table public.wall_post_gc alter column bucket_id drop default;
alter table public.wall_post_gc drop constraint if exists wall_post_gc_pkey;
alter table public.wall_post_gc add constraint wall_post_gc_pkey
    primary key (bucket_id, path);

-- 5. Shared helper: media jsonb -> the (bucket_id, path) pairs to reclaim on
--    delete/expiry. One place, reused by create/delete/sweep, so a new media
--    kind can't drift the bucket mapping between call sites.
create or replace function public.fn_wall_post_media_gc_paths(p_media jsonb)
    returns table(bucket_id text, path text)
    language sql immutable
    set search_path to ''
as $$
    select case when elem->>'type' = 'video' then 'wall_post_video'
                else 'wall_post' end,
           elem->>'path'
    from jsonb_array_elements(p_media) elem
    union all
    select 'wall_post', elem->>'thumbnail_path'
    from jsonb_array_elements(p_media) elem
    where elem->>'type' = 'video' and coalesce(elem->>'thumbnail_path', '') <> '';
$$;

revoke all on function public.fn_valid_wall_post_media(jsonb) from public, authenticated;
revoke all on function public.fn_wall_post_media_gc_paths(jsonb) from public, authenticated;

-- 6. create_wall_post: p_image_paths text[] -> p_media jsonb. The parameter
--    type changes, so this is a new overload as far as Postgres is
--    concerned — drop the old signature explicitly rather than leave it as
--    dead, still-callable code.
drop function if exists public.create_wall_post(uuid, uuid, text[], text, smallint, uuid[]);

create or replace function public.create_wall_post(
    p_activity_id  uuid,
    p_booking_id   uuid,
    p_media        jsonb,
    p_caption      text default null,
    p_ttl_days     smallint default 7,
    p_tagged_users uuid[] default '{}'
) returns uuid
    language plpgsql security definer set search_path to ''
as $$
declare
    v_uid    uuid := auth.uid();
    v_id     uuid;
    v_sport  bigint;
    v_lobby  uuid;
    v_label  text;
    v_start  timestamptz;
    v_venue  text;
    v_tag    uuid;
begin
    if v_uid is null then raise exception 'not authenticated'; end if;
    if num_nonnulls(p_activity_id, p_booking_id) <> 1 then
        raise exception 'reference exactly one activity or booking';
    end if;
    if not public.fn_valid_wall_post_media(p_media) then
        raise exception
            'a post needs 1-4 media items, each an image or a video under 1 minute';
    end if;
    if array_length(p_tagged_users, 1) > 5 then
        raise exception 'a post can tag at most 5 people';
    end if;

    if p_activity_id is not null then
        -- Eligible: it started in the last 7 days, and the author said they
        -- were going. `going` only — a `maybe`/`out` RSVP is not "I was there".
        select a.sport_id, a.lobby_id, l.name, a.start_time, loc.name
            into v_sport, v_lobby, v_label, v_start, v_venue
            from public.activity a
            left join public.lobby l on l.id = a.lobby_id
            left join public.location loc on loc.id = a.location_id
            where a.id = p_activity_id
              and a.start_time < now()
              and a.start_time > now() - interval '7 days'
              and exists (
                select 1 from public.activity_confirmation c
                where c.activity_id = a.id
                  and c.user_id = v_uid
                  and c.attendance = 'going'
              );

        if v_start is null then
            raise exception
                'activity is not postable (must be within 7 days and RSVP''d going)';
        end if;
    else
        -- A coach lesson the caller was the client on. Gated on `confirmed` OR
        -- `completed`, not `completed` alone: completion is a manual tap that
        -- most sessions never receive (see professional_booking_completion.sql),
        -- so requiring it would make almost every real lesson unpostable.
        select b.booking_time_start, p.display_name, loc.name,
               (select s.sport_id from public.professional_service s
                 where s.id = b.service_id)
            into v_start, v_label, v_venue, v_sport
            from public.professional_booking b
            join public.professional p on p.id = b.professional_id
            left join public.location loc on loc.id = b.location_id
            where b.id = p_booking_id
              and b.client_user_id = v_uid
              and p.professional_role = 'coach'
              and b.status in ('confirmed', 'completed')
              and b.booking_time_end < now()
              and b.booking_time_end > now() - interval '7 days';

        if v_start is null then
            raise exception 'lesson is not postable (must be yours and within 7 days)';
        end if;
    end if;

    insert into public.wall_post (
        author_id, activity_id, professional_booking_id,
        sport_id, lobby_id, source_label, source_start_time, source_venue_name,
        caption, media, ttl_days, expires_at
    ) values (
        v_uid, p_activity_id, p_booking_id,
        coalesce(v_sport, 0), v_lobby, v_label, v_start, v_venue,
        nullif(btrim(p_caption), ''), p_media, p_ttl_days,
        now() + (p_ttl_days || ' days')::interval
    ) returning id into v_id;

    foreach v_tag in array coalesce(p_tagged_users, '{}'::uuid[]) loop
        insert into public.wall_post_tag (post_id, user_id)
            values (v_id, v_tag)
            on conflict do nothing;
    end loop;

    return v_id;
end;
$$;

grant execute on function
    public.create_wall_post(uuid, uuid, jsonb, text, smallint, uuid[])
    to authenticated;

-- 7. delete_wall_post: route media (+ video thumbnails) into the GC queue
--    with the right bucket_id per path.
create or replace function public.delete_wall_post(p_post_id uuid)
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_media jsonb;
begin
    select media into v_media
        from public.wall_post
        where id = p_post_id and author_id = auth.uid();
    if v_media is null then raise exception 'not your post'; end if;

    -- Hand the objects to the same GC queue the TTL sweep uses, so there is
    -- exactly one path that reclaims storage.
    insert into public.wall_post_gc (bucket_id, path)
        select bucket_id, path from public.fn_wall_post_media_gc_paths(v_media)
        on conflict do nothing;

    delete from public.wall_post where id = p_post_id;
end;
$$;

-- 8. TTL sweep: same bucket-aware queueing as delete_wall_post.
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
        returning media
    ), queued as (
        insert into public.wall_post_gc (bucket_id, path)
        select distinct g.bucket_id, g.path
        from expired e, public.fn_wall_post_media_gc_paths(e.media) g
        on conflict do nothing
        returning 1
    )
    select count(*) into v_count from queued;

    return v_count;
end;
$$;

-- 9. Read paths: image_paths (text[]) -> media (jsonb) in the output shape.
--    An existing OUT column's type can't change via CREATE OR REPLACE, so
--    both need a DROP first. Both just pass the column through untouched to
--    the client, which parses it (see lib/core/model/wall_post.dart).
drop function if exists public.wall_feed_data(bigint, int, int);

create or replace function public.wall_feed_data(
    p_sport_id    bigint default null,   -- null = all sports
    p_page_size   int default 20,
    p_page_number int default 0
) returns table(
    id                 uuid,
    author_id          uuid,
    author_username    text,
    author_tag_number  text,
    author_details     jsonb,
    sport_id           bigint,
    lobby_id           uuid,
    source_label       text,
    source_start_time  timestamptz,
    source_venue_name  text,
    caption            text,
    media              jsonb,
    created_at         timestamptz,
    expires_at         timestamptz,
    tags               jsonb,   -- [{user_id, username, tag_number}]
    reactions          jsonb,   -- {"🔥": 3, "👏": 1}
    my_reaction        text
)
    language sql stable security definer set search_path to 'public'
as $$
    with me as (select auth.uid() as uid),
    -- Set-returning functions go in FROM, not the select list: in the select
    -- list they'd be evaluated per output row instead of expanded once.
    friends as (select uid from public.get_my_friend_ids() as uid),
    lobbymates as (select uid from public.get_my_lobbymate_ids() as uid),
    visible as (
        select p.*
        from public.wall_post p, me
        where p.hidden_at is null
          and p.expires_at > now()
          and not public.fn_is_blocked(me.uid, p.author_id)
          and (p_sport_id is null or p.sport_id = p_sport_id)
          and (
            p.author_id = me.uid
            or p.author_id in (select uid from friends)
            or p.author_id in (select uid from lobbymates)
            or exists (
                select 1 from public.wall_post_tag t
                where t.post_id = p.id
                  and (t.user_id = me.uid
                       or t.user_id in (select uid from friends))
            )
          )
    )
    select v.id,
           v.author_id,
           u.username::text,
           u.tag_number::text,
           u.details,
           v.sport_id,
           v.lobby_id,
           v.source_label,
           v.source_start_time,
           v.source_venue_name,
           v.caption,
           v.media,
           v.created_at,
           v.expires_at,
           coalesce((
               select jsonb_agg(jsonb_build_object(
                          'user_id', tu.id,
                          'username', tu.username,
                          'tag_number', tu.tag_number))
               from public.wall_post_tag t
               join public."user" tu on tu.id = t.user_id
               where t.post_id = v.id
           ), '[]'::jsonb),
           coalesce((
               select jsonb_object_agg(r.emoji, r.n)
               from (select emoji, count(*) as n
                       from public.wall_post_reaction
                      where post_id = v.id
                      group by emoji) r
           ), '{}'::jsonb),
           (select emoji from public.wall_post_reaction
             where post_id = v.id and user_id = (select uid from me))
    from visible v
    join public."user" u on u.id = v.author_id
    order by v.created_at desc
    limit greatest(p_page_size, 1)
    offset greatest(p_page_number, 0) * greatest(p_page_size, 1);
$$;

grant execute on function public.wall_feed_data(bigint, int, int) to authenticated;

drop function if exists public.user_wall_data(uuid, text, int, int);

create or replace function public.user_wall_data(
    p_user_id     uuid,
    p_mode        text default 'authored',
    p_page_size   int default 20,
    p_page_number int default 0
) returns table(
    id                 uuid,
    author_id          uuid,
    author_username    text,
    author_tag_number  text,
    author_details     jsonb,
    sport_id           bigint,
    lobby_id           uuid,
    source_label       text,
    source_start_time  timestamptz,
    source_venue_name  text,
    caption            text,
    media              jsonb,
    created_at         timestamptz,
    expires_at         timestamptz,
    tags               jsonb,
    reactions          jsonb,
    my_reaction        text
)
    language sql stable security definer set search_path to 'public'
as $$
    select p.id,
           p.author_id,
           u.username::text,
           u.tag_number::text,
           u.details,
           p.sport_id,
           p.lobby_id,
           p.source_label,
           p.source_start_time,
           p.source_venue_name,
           p.caption,
           p.media,
           p.created_at,
           p.expires_at,
           coalesce((
               select jsonb_agg(jsonb_build_object(
                          'user_id', tu.id,
                          'username', tu.username,
                          'tag_number', tu.tag_number))
               from public.wall_post_tag t
               join public."user" tu on tu.id = t.user_id
               where t.post_id = p.id
           ), '[]'::jsonb),
           coalesce((
               select jsonb_object_agg(r.emoji, r.n)
               from (select emoji, count(*) as n
                       from public.wall_post_reaction
                      where post_id = p.id
                      group by emoji) r
           ), '{}'::jsonb),
           (select emoji from public.wall_post_reaction
             where post_id = p.id and user_id = auth.uid())
    from public.wall_post p
    join public."user" u on u.id = p.author_id
    where public.fn_can_see_wall_post(p.id)
      and case
            when p_mode = 'tagged' then exists (
                select 1 from public.wall_post_tag t
                where t.post_id = p.id and t.user_id = p_user_id)
            else p.author_id = p_user_id
          end
    order by p.created_at desc
    limit greatest(p_page_size, 1)
    offset greatest(p_page_number, 0) * greatest(p_page_size, 1);
$$;

grant execute on function public.user_wall_data(uuid, text, int, int) to authenticated;

-- 10. lobby_feed_data: payload shape only (image_paths -> media inside the
--     jsonb payload) — the RETURNS TABLE signature itself is unchanged (the
--     payload column stays jsonb), so CREATE OR REPLACE is enough here,
--     unlike the two functions above. Full body carried forward from
--     schema/lobby_feed_author_avatar.sql (the latest link in this
--     function's redefinition chain — see that file's header) plus this one
--     change, so this file becomes the new latest link.
create or replace function public.lobby_feed_data(p_lobby_id uuid, p_page_size integer default 50, p_before timestamp with time zone default null::timestamp with time zone)
 returns table(id uuid, author_id uuid, author_username character varying, kind lobby_feed_item_kind, payload jsonb, created_at timestamp with time zone, poll_tallies jsonb, my_vote integer, payment_payees jsonb, author_generated_avatar text)
 language plpgsql
 set search_path to ''
as $function$
BEGIN
    RETURN QUERY
        SELECT * FROM (
            SELECT fi.id,
                   fi.author_id,
                   u.username                             AS author_username,
                   fi.kind,
                   fi.payload,
                   fi.created_at,
                   CASE WHEN fi.kind = 'poll' THEN
                       (SELECT jsonb_object_agg(option_index::text, c)
                        FROM (
                            SELECT option_index, COUNT(*) AS c
                            FROM public.lobby_feed_poll_vote v
                            WHERE v.feed_item_id = fi.id
                            GROUP BY option_index
                        ) t)
                   END                                    AS poll_tallies,
                   CASE WHEN fi.kind = 'poll' THEN
                       (SELECT v.option_index
                        FROM public.lobby_feed_poll_vote v
                        WHERE v.feed_item_id = fi.id AND v.user_id = auth.uid())
                   END                                    AS my_vote,
                   CASE WHEN fi.kind = 'payment_request' THEN
                       (SELECT jsonb_agg(jsonb_build_object(
                                  'user_id',          pr.user_id,
                                  'username',         pu.username,
                                  'generated_avatar', pu.details ->> 'generatedAvatar',
                                  'amount_owed',       pr.amount_owed,
                                  'paid',              (r.user_id IS NOT NULL)))
                          FROM public.lobby_payment_request_payee pr
                          JOIN public."user" pu ON pu.id = pr.user_id
                          LEFT JOIN public.lobby_feed_item_reaction r
                                 ON r.feed_item_id = fi.id AND r.user_id = pr.user_id
                         WHERE pr.feed_item_id = fi.id)
                   END                                    AS payment_payees,
                   (u.details ->> 'generatedAvatar')      AS author_generated_avatar
            FROM public.lobby_feed_item fi
                     LEFT JOIN public."user" u ON u.id = fi.author_id
            WHERE fi.lobby_id = p_lobby_id
              -- Legacy `photo` rows (there should be none — the kind was never
              -- writable) are dropped rather than rendered: the client's photo
              -- branch now expects a wall-post payload.
              AND fi.kind <> 'photo'
              AND (p_before IS NULL OR fi.created_at < p_before)

            UNION ALL

            -- ── Wall posts attached to this lobby ────────────────────────
            SELECT p.id,
                   p.author_id,
                   au.username                            AS author_username,
                   'photo'::public.lobby_feed_item_kind   AS kind,
                   jsonb_build_object(
                       'id',                p.id,
                       'author_id',         p.author_id,
                       'author_username',   au.username,
                       'author_tag_number', au.tag_number,
                       'author_details',    au.details,
                       'sport_id',          p.sport_id,
                       'lobby_id',          p.lobby_id,
                       'source_label',      p.source_label,
                       'source_start_time', p.source_start_time,
                       'source_venue_name', p.source_venue_name,
                       'caption',           p.caption,
                       'media',             p.media,
                       'created_at',        p.created_at,
                       'expires_at',        p.expires_at,
                       'tags', coalesce((
                           SELECT jsonb_agg(jsonb_build_object(
                                      'user_id', tu.id,
                                      'username', tu.username,
                                      'tag_number', tu.tag_number))
                           FROM public.wall_post_tag t
                           JOIN public."user" tu ON tu.id = t.user_id
                           WHERE t.post_id = p.id
                       ), '[]'::jsonb),
                       'reactions', coalesce((
                           SELECT jsonb_object_agg(r.emoji, r.n)
                           FROM (SELECT emoji, count(*) AS n
                                   FROM public.wall_post_reaction
                                  WHERE post_id = p.id
                                  GROUP BY emoji) r
                       ), '{}'::jsonb),
                       'my_reaction', (
                           SELECT emoji FROM public.wall_post_reaction
                            WHERE post_id = p.id AND user_id = auth.uid())
                   )                                      AS payload,
                   p.created_at,
                   NULL::jsonb                            AS poll_tallies,
                   NULL::integer                          AS my_vote,
                   NULL::jsonb                             AS payment_payees,
                   (au.details ->> 'generatedAvatar')     AS author_generated_avatar
            FROM public.wall_post p
                     JOIN public."user" au ON au.id = p.author_id
            WHERE p.lobby_id = p_lobby_id
              AND p.hidden_at IS NULL
              AND p.expires_at > now()
              AND (p_before IS NULL OR p.created_at < p_before)
        ) merged
        ORDER BY merged.created_at DESC
        LIMIT p_page_size;
END;
$function$
;

-- 11. Moderation queue: image_paths -> media. No client consumes this view
--     (operator SQL-console only), so a straight DROP + CREATE is simplest.
drop view if exists public.wall_post_moderation_queue;
create view public.wall_post_moderation_queue
    with (security_invoker = true) as
    select p.id,
           p.author_id,
           p.caption,
           p.media,
           p.created_at,
           p.expires_at,
           p.hidden_at,
           count(r.*) as report_count,
           array_agg(distinct r.reason) as reasons
    from public.wall_post p
    join public.wall_post_report r on r.post_id = p.id
    group by p.id
    order by count(r.*) desc, p.created_at desc;

revoke all on public.wall_post_moderation_queue from anon, authenticated, public;
