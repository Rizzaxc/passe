-- ============================================================================
-- "Has unread wall post" existence check — feeds the app's initial-route pick
-- (see lib/router.dart: guest -> Discover, unread Feed -> Feed, else -> Manage).
--
-- Mirrors wall_feed_data's visibility CTE exactly (friends ∪ lobbymates ∪
-- tagged-audience, hidden_at is null, expires_at > now(), blocked check —
-- schema/wall_feed_pagination_bounds.sql) but as a LIMIT-1 existence check
-- instead of a paginated fetch, and excludes the caller's own posts (you
-- already know about those).
--
-- Depends on: schema/wall_post.sql, schema/friendship.sql. Idempotent /
-- re-runnable.
-- ============================================================================

create or replace function public.wall_feed_has_unread(
    p_since timestamptz default null   -- null = never checked before
) returns boolean
    language sql stable security definer set search_path to 'public'
as $$
    with me as (select auth.uid() as uid),
    friends as (select uid from public.get_my_friend_ids() as uid),
    lobbymates as (select uid from public.get_my_lobbymate_ids() as uid)
    select exists (
        select 1
        from public.wall_post p, me
        where p.hidden_at is null
          and p.expires_at > now()
          and p.author_id <> me.uid
          and p.created_at > coalesce(p_since, 'epoch'::timestamptz)
          and not public.fn_is_blocked(me.uid, p.author_id)
          and (
            p.author_id in (select uid from friends)
            or p.author_id in (select uid from lobbymates)
            or exists (
                select 1 from public.wall_post_tag t
                where t.post_id = p.id
                  and (t.user_id = me.uid or t.user_id in (select uid from friends))
            )
          )
    );
$$;

revoke all on function public.wall_feed_has_unread(timestamptz) from public, anon;
grant execute on function public.wall_feed_has_unread(timestamptz) to authenticated;
