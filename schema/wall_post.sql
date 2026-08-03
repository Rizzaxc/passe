-- ============================================================================
-- Wall posts — ephemeral photo posts hooked to something the author did.
--
-- A post must reference either a lobby `activity` the author RSVP'd `going`
-- to, or a coach `professional_booking` they were the client on — in both
-- cases within the last 7 days. That reference is a **label, not integrity**:
-- the display fields are snapshotted onto the post at creation, both FKs are
-- ON DELETE SET NULL, and the card renders from the snapshot. This is why
-- `expire_past_activities()` (which hard-deletes past unconfirmed activities)
-- needs no carve-out — it can delete the activity and the post still reads
-- "Chủ nhật · Sân Tao Đàn".
--
-- Visibility (one predicate, used by both the wall and the feed):
--   self, the author's friends, the author's lobby mates, anyone tagged, and
--   **the friends of anyone tagged**. Tagging is the audience-widening
--   mechanism — sharing a lobby with a friend of the author grants nothing.
--
-- STORAGE IS NOT ACCESS CONTROL. The `wall_post` bucket is public with
-- unguessable UUID paths, chosen for load time: a public URL is a stable cache
-- key, so images survive in the CDN and on disk, where a signed URL's rotating
-- token would force a re-download every session. Row visibility is enforced on
-- the post, never on the bytes. Because the expiry sweep really deletes the
-- object (schema/wall_post_expiry.sql), maximum exposure is one TTL.
--
-- Depends on: schema/friendship.sql (get_my_friend_ids, get_my_lobbymate_ids,
-- fn_is_blocked). Idempotent / re-runnable.
-- ============================================================================

-- 1. Table
create table if not exists public.wall_post (
    id          uuid primary key default gen_random_uuid(),
    author_id   uuid not null default auth.uid()
                    references public."user"(id) on delete cascade,

    -- The hook. Exactly one, and only at insert time — either may later go
    -- null when the referenced row is deleted.
    activity_id             uuid references public.activity(id) on delete set null,
    professional_booking_id uuid references public.professional_booking(id) on delete set null,

    -- Snapshot of the hook, captured at insert. Survives the FKs nulling out.
    sport_id           bigint not null,
    lobby_id           uuid references public.lobby(id) on delete set null,
    source_label       text,          -- lobby name, or the coach's display name
    source_start_time  timestamptz not null,
    source_venue_name  text,

    caption     text constraint wall_post_caption_length
                    check (caption is null or char_length(caption) <= 140),
    image_paths text[] not null constraint wall_post_image_count
                    check (array_length(image_paths, 1) between 1 and 4),

    ttl_days    smallint not null default 7
                    constraint wall_post_ttl_choice check (ttl_days in (1, 3, 7)),
    created_at  timestamptz not null default now(),
    expires_at  timestamptz not null,
    hidden_at   timestamptz          -- set by the moderation auto-hide trigger
);

-- Enforced on insert only (see the note on the columns above): a post is born
-- attached to exactly one thing.
create or replace function public.fn_wall_post_source_exclusivity()
    returns trigger
    language plpgsql set search_path to ''
as $$
begin
    if num_nonnulls(new.activity_id, new.professional_booking_id) <> 1 then
        raise exception
            'a wall post must reference exactly one activity or booking';
    end if;
    return new;
end;
$$;

drop trigger if exists trg_wall_post_source_exclusivity on public.wall_post;
create trigger trg_wall_post_source_exclusivity
    before insert on public.wall_post
    for each row execute function public.fn_wall_post_source_exclusivity();

-- One post per author per thing. Partial (the columns are nullable), and they
-- free up if the post is deleted or swept — re-posting about the same session
-- after deleting is intentionally allowed.
create unique index if not exists wall_post_one_per_activity
    on public.wall_post (author_id, activity_id) where activity_id is not null;
create unique index if not exists wall_post_one_per_booking
    on public.wall_post (author_id, professional_booking_id)
    where professional_booking_id is not null;

-- Feed reads are "recent, unexpired, by these authors".
create index if not exists wall_post_author_created_idx
    on public.wall_post (author_id, created_at desc);
create index if not exists wall_post_expiry_idx on public.wall_post (expires_at);
create index if not exists wall_post_lobby_idx
    on public.wall_post (lobby_id) where lobby_id is not null;

create table if not exists public.wall_post_tag (
    post_id  uuid not null references public.wall_post(id) on delete cascade,
    user_id  uuid not null references public."user"(id) on delete cascade,
    primary key (post_id, user_id)
);

-- The 2nd-degree feed path resolves tagged-user → posts, so index that way.
create index if not exists wall_post_tag_user_idx on public.wall_post_tag (user_id);

-- Storage objects awaiting deletion. Rows land here from two places — the TTL
-- sweep (schema/wall_post_expiry.sql) and an author deleting their own post —
-- and a small Edge Function drains it via the Storage API. Deleting from
-- `storage.objects` in SQL does not reclaim the underlying file, so the queue
-- is the only correct way out.
create table if not exists public.wall_post_gc (
    path       text primary key,
    queued_at  timestamptz not null default now()
);

-- Service role only. RLS-with-no-policies denies every row; the revoke also
-- strips the blanket grants Supabase's default privileges hand to anon /
-- authenticated, which a `revoke ... from public` alone does not.
alter table public.wall_post_gc enable row level security;
revoke all on public.wall_post_gc from anon, authenticated, public;

create table if not exists public.wall_post_reaction (
    post_id    uuid not null references public.wall_post(id) on delete cascade,
    user_id    uuid not null references public."user"(id) on delete cascade,
    emoji      text not null constraint wall_post_reaction_emoji_length
                   check (char_length(emoji) between 1 and 8),
    created_at timestamptz not null default now(),
    primary key (post_id, user_id)   -- one reaction each; changing = upsert
);

-- 2. Tag rules: at most 5, and only people connected to the session.
--    "Attendees ∪ lobby members" deliberately — you can tag someone who didn't
--    RSVP, to humour the absentees.
create or replace function public.fn_wall_post_tag_guard()
    returns trigger
    language plpgsql security definer set search_path to ''
as $$
declare
    v_activity uuid;
    v_booking  uuid;
    v_lobby    uuid;
    v_count    int;
begin
    select activity_id, professional_booking_id, lobby_id
        into v_activity, v_booking, v_lobby
        from public.wall_post where id = new.post_id;

    select count(*) into v_count
        from public.wall_post_tag where post_id = new.post_id;
    if v_count >= 5 then
        raise exception 'a post can tag at most 5 people';
    end if;

    if v_activity is not null then
        if not exists (
            select 1 from public.activity_confirmation c
                where c.activity_id = v_activity and c.user_id = new.user_id
            union all
            select 1 from public.lobby_member m
                where m.lobby_id = v_lobby and m.user_id = new.user_id
        ) then
            raise exception 'can only tag attendees or lobby members';
        end if;
    elsif v_booking is not null then
        if not exists (
            select 1 from public.professional_booking b
                where b.id = v_booking and b.client_user_id = new.user_id
            union all
            select 1 from public.booking_additional_users a
                where a.booking_id = v_booking and a.user_id = new.user_id
            union all
            select 1 from public.professional p
                join public.professional_booking b2 on b2.professional_id = p.id
                where b2.id = v_booking and p.linked_user_id = new.user_id
        ) then
            raise exception 'can only tag people on this booking';
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_wall_post_tag_guard on public.wall_post_tag;
create trigger trg_wall_post_tag_guard
    before insert on public.wall_post_tag
    for each row execute function public.fn_wall_post_tag_guard();

-- 3. Visibility. Kept as one SECURITY DEFINER predicate so the RLS policy, the
--    feed RPC and the wall RPC can never drift apart.
create or replace function public.fn_can_see_wall_post(p_post_id uuid)
    returns boolean
    language sql stable security definer set search_path to 'public'
as $$
    select exists (
        select 1
        from public.wall_post p
        where p.id = p_post_id
          and (
            p.author_id = auth.uid()
            or (
                p.hidden_at is null
                and p.expires_at > now()
                and not public.fn_is_blocked(auth.uid(), p.author_id)
                and (
                    p.author_id in (select public.get_my_friend_ids())
                    or p.author_id in (select public.get_my_lobbymate_ids())
                    or exists (
                        select 1 from public.wall_post_tag t
                        where t.post_id = p.id
                          and (
                            t.user_id = auth.uid()
                            or t.user_id in (select public.get_my_friend_ids())
                          )
                    )
                )
            )
          )
    );
$$;

grant execute on function public.fn_can_see_wall_post(uuid) to authenticated;

-- 4. RLS
alter table public.wall_post enable row level security;
alter table public.wall_post_tag enable row level security;
alter table public.wall_post_reaction enable row level security;

drop policy if exists "Visible posts are readable" on public.wall_post;
create policy "Visible posts are readable"
    on public.wall_post for select to authenticated
    using (public.fn_can_see_wall_post(id));

-- Inserts go through create_wall_post() (which enforces eligibility), but the
-- policy still pins authorship so a stray direct insert can't forge one.
drop policy if exists "Authors can write their own posts" on public.wall_post;
create policy "Authors can write their own posts"
    on public.wall_post for insert to authenticated
    with check (author_id = (select auth.uid()));

drop policy if exists "Authors can delete their own posts" on public.wall_post;
create policy "Authors can delete their own posts"
    on public.wall_post for delete to authenticated
    using (author_id = (select auth.uid()));

drop policy if exists "Tags follow their post" on public.wall_post_tag;
create policy "Tags follow their post"
    on public.wall_post_tag for select to authenticated
    using (public.fn_can_see_wall_post(post_id));

drop policy if exists "Authors manage their post's tags" on public.wall_post_tag;
create policy "Authors manage their post's tags"
    on public.wall_post_tag for insert to authenticated
    with check (exists (
        select 1 from public.wall_post p
        where p.id = post_id and p.author_id = (select auth.uid())
    ));

drop policy if exists "Authors remove their post's tags" on public.wall_post_tag;
create policy "Authors remove their post's tags"
    on public.wall_post_tag for delete to authenticated
    using (exists (
        select 1 from public.wall_post p
        where p.id = post_id and p.author_id = (select auth.uid())
    ));

drop policy if exists "Reactions follow their post" on public.wall_post_reaction;
create policy "Reactions follow their post"
    on public.wall_post_reaction for select to authenticated
    using (public.fn_can_see_wall_post(post_id));

drop policy if exists "React to visible posts" on public.wall_post_reaction;
create policy "React to visible posts"
    on public.wall_post_reaction for insert to authenticated
    with check (
        user_id = (select auth.uid())
        and public.fn_can_see_wall_post(post_id)
    );

drop policy if exists "Change your own reaction" on public.wall_post_reaction;
create policy "Change your own reaction"
    on public.wall_post_reaction for update to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

drop policy if exists "Remove your own reaction" on public.wall_post_reaction;
create policy "Remove your own reaction"
    on public.wall_post_reaction for delete to authenticated
    using (user_id = (select auth.uid()));

-- 5. Storage bucket. Public + UUID paths — see the header note on why.
--    Path is `<auth.uid()>/<uuid>.jpg`: user-scoped rather than post-scoped
--    because the client uploads *before* the post row exists.
insert into storage.buckets (id, name, public)
values ('wall_post', 'wall_post', true)
on conflict (id) do nothing;

-- NOTE: deliberately **no** broad SELECT policy on storage.objects, unlike
-- `lobby_avatar`. A public bucket serves bytes over the /object/public/ route
-- without consulting RLS, so a SELECT policy adds nothing for image loading —
-- all it enables is `list`, which would let any client enumerate every object
-- path in the bucket. For avatars that's harmless (paths are `<id>.jpg`, i.e.
-- already guessable); here it would defeat the unguessable-UUID-path premise
-- the whole storage decision rests on. Caught by the `public_bucket_allows_listing`
-- advisor.
drop policy if exists "wall_post: public read" on storage.objects;

drop policy if exists "wall_post: owner can upload" on storage.objects;
create policy "wall_post: owner can upload"
    on storage.objects for insert to authenticated
    with check (
        bucket_id = 'wall_post'
        and split_part(name, '/', 1) = auth.uid()::text
    );

drop policy if exists "wall_post: owner can delete" on storage.objects;
create policy "wall_post: owner can delete"
    on storage.objects for delete to authenticated
    using (
        bucket_id = 'wall_post'
        and split_part(name, '/', 1) = auth.uid()::text
    );

-- 6. Create a post. SECURITY DEFINER so eligibility and the snapshot are
--    computed server-side from the source row rather than trusted from the
--    client.
create or replace function public.create_wall_post(
    p_activity_id  uuid,
    p_booking_id   uuid,
    p_image_paths  text[],
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
    if coalesce(array_length(p_image_paths, 1), 0) not between 1 and 4 then
        raise exception 'a post needs between 1 and 4 images';
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
        caption, image_paths, ttl_days, expires_at
    ) values (
        v_uid, p_activity_id, p_booking_id,
        coalesce(v_sport, 0), v_lobby, v_label, v_start, v_venue,
        nullif(btrim(p_caption), ''), p_image_paths, p_ttl_days,
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

create or replace function public.delete_wall_post(p_post_id uuid)
    returns void
    language plpgsql security definer set search_path to ''
as $$
declare
    v_paths text[];
begin
    select image_paths into v_paths
        from public.wall_post
        where id = p_post_id and author_id = auth.uid();
    if v_paths is null then raise exception 'not your post'; end if;

    -- Hand the objects to the same GC queue the TTL sweep uses, so there is
    -- exactly one path that reclaims storage.
    insert into public.wall_post_gc (path)
        select unnest(v_paths)
        on conflict do nothing;

    delete from public.wall_post where id = p_post_id;
end;
$$;

-- Set / change / clear a reaction in one call.
create or replace function public.react_to_wall_post(
    p_post_id uuid,
    p_emoji   text
) returns void
    language plpgsql security definer set search_path to ''
as $$
begin
    if auth.uid() is null then raise exception 'not authenticated'; end if;
    if not public.fn_can_see_wall_post(p_post_id) then
        raise exception 'post not visible';
    end if;

    if p_emoji is null then
        delete from public.wall_post_reaction
            where post_id = p_post_id and user_id = auth.uid();
    else
        insert into public.wall_post_reaction (post_id, user_id, emoji)
            values (p_post_id, auth.uid(), p_emoji)
            on conflict (post_id, user_id)
            do update set emoji = excluded.emoji, created_at = now();
    end if;
end;
$$;

grant execute on function
    public.create_wall_post(uuid, uuid, text[], text, smallint, uuid[])
    to authenticated;
grant execute on function public.delete_wall_post(uuid) to authenticated;
grant execute on function public.react_to_wall_post(uuid, text) to authenticated;
