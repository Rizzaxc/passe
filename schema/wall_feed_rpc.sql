-- ============================================================================
-- Wall / Feed read paths.
--
-- Three functions, one row shape between the first two so the client renders
-- both with the same card:
--   wall_feed_data       — the Home ▸ Feed aggregation
--   user_wall_data       — one person's wall, 'authored' or 'tagged'
--   postable_activities  — what the composer is allowed to hook a post to
--
-- The feed resolves visibility with CTEs rather than leaning on the RLS
-- predicate row-by-row (same approach as home_teammate_lobby_data), but the
-- *rules* are identical to fn_can_see_wall_post — if you change one, change
-- both. Depends on: schema/wall_post.sql, schema/friendship.sql.
--
-- Idempotent / re-runnable.
-- ============================================================================

-- 1. Feed — posts from the caller, their friends, their lobby mates, and any
--    post a friend of theirs is tagged in (the 2nd-degree path).
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
    image_paths        text[],
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
           v.image_paths,
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

-- 2. One person's wall. `p_mode`:
--      'authored' — posts they wrote
--      'tagged'   — posts they're tagged in
--    Both run through fn_can_see_wall_post, so a visitor's 'tagged' view is
--    automatically narrowed to what they were already entitled to see. There
--    is no separate rule for the tagged tab and therefore nothing to leak.
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
    image_paths        text[],
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
           p.image_paths,
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

-- 3. What the composer may hook a post to: lobby activities in the last 7 days
--    the caller RSVP'd `going` to, plus their coach lessons in the same window.
--    Mirrors the eligibility in create_wall_post() exactly — if these disagree
--    the picker offers rows the insert then rejects.
create or replace function public.postable_activities()
    returns table(
        activity_id     uuid,
        booking_id      uuid,
        sport_id        bigint,
        lobby_id        uuid,
        source_label    text,
        start_time      timestamptz,
        venue_name      text,
        already_posted  boolean
    )
    language sql stable security definer set search_path to 'public'
as $$
    select a.id,
           null::uuid,
           a.sport_id,
           a.lobby_id,
           l.name,
           a.start_time,
           loc.name,
           exists (select 1 from public.wall_post w
                    where w.activity_id = a.id and w.author_id = auth.uid())
    from public.activity a
    join public.activity_confirmation c
        on c.activity_id = a.id
       and c.user_id = auth.uid()
       and c.attendance = 'going'
    left join public.lobby l on l.id = a.lobby_id
    left join public.location loc on loc.id = a.location_id
    where a.start_time < now()
      and a.start_time > now() - interval '7 days'

    union all

    select null::uuid,
           b.id,
           s.sport_id,
           null::uuid,
           p.display_name,
           b.booking_time_start,
           loc.name,
           exists (select 1 from public.wall_post w
                    where w.professional_booking_id = b.id
                      and w.author_id = auth.uid())
    from public.professional_booking b
    join public.professional p on p.id = b.professional_id
    join public.professional_service s on s.id = b.service_id
    left join public.location loc on loc.id = b.location_id
    where b.client_user_id = auth.uid()
      and p.professional_role = 'coach'
      and b.status in ('confirmed', 'completed')
      and b.booking_time_end < now()
      and b.booking_time_end > now() - interval '7 days'

    order by start_time desc;
$$;

-- 4. Who the composer may tag: that activity's attendees ∪ the lobby's members
--    (or, for a lesson, the coach and anyone else on the booking). Mirrors
--    fn_wall_post_tag_guard.
create or replace function public.taggable_users(
    p_activity_id uuid default null,
    p_booking_id  uuid default null
) returns table(
    user_id    uuid,
    username   text,
    tag_number text,
    details    jsonb,
    attended   boolean
)
    language sql stable security definer set search_path to 'public'
as $$
    select u.id, u.username::text, u.tag_number::text, u.details,
           bool_or(x.attended)
    from (
        select c.user_id as uid, true as attended
            from public.activity_confirmation c
            where p_activity_id is not null
              and c.activity_id = p_activity_id
              and c.attendance = 'going'
        union all
        select m.user_id, false
            from public.lobby_member m
            join public.activity a on a.lobby_id = m.lobby_id
            where p_activity_id is not null and a.id = p_activity_id
        union all
        select b.client_user_id, true
            from public.professional_booking b
            where p_booking_id is not null and b.id = p_booking_id
        union all
        select au.user_id, true
            from public.booking_additional_users au
            where p_booking_id is not null and au.booking_id = p_booking_id
        union all
        select p.linked_user_id, true
            from public.professional p
            join public.professional_booking b on b.professional_id = p.id
            where p_booking_id is not null
              and b.id = p_booking_id
              and p.linked_user_id is not null
    ) x
    join public."user" u on u.id = x.uid
    where u.id <> auth.uid()
    group by u.id, u.username, u.tag_number, u.details
    order by bool_or(x.attended) desc, u.username;
$$;

grant execute on function public.wall_feed_data(bigint, int, int) to authenticated;
grant execute on function public.user_wall_data(uuid, text, int, int) to authenticated;
grant execute on function public.postable_activities() to authenticated;
grant execute on function public.taggable_users(uuid, uuid) to authenticated;
