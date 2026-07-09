-- Lobby avatar/profile picture support.
--
-- Storage: `lobby_avatar` bucket, public read, one object per lobby at
-- `<lobby.id>.jpg` (fixed filename = trivial upsert/cache-bust via a `?t=`
-- query param on the client, same convention as the `user_avatar` bucket).
-- The client tracks whether a custom photo exists via `lobby.details ->>
-- 'hasAvatar'` (see `LobbyDetails.hasAvatar` in lib/core/model/lobby.dart) —
-- `lobby.details` has no CHECK constraint so this needed no column migration.
--
-- Only the lobby's captain may write; anyone may read (public bucket, so
-- reads via the public URL route bypass RLS entirely — the SELECT policy
-- below only matters for authenticated API access, e.g. `list`/`getMetadata`).

insert into storage.buckets (id, name, public)
values ('lobby_avatar', 'lobby_avatar', true)
on conflict (id) do nothing;

create policy "lobby_avatar: public read"
on storage.objects
for select
to public
using (bucket_id = 'lobby_avatar');

create policy "lobby_avatar: captain can upload"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'lobby_avatar'
    and exists (
        select 1 from public.lobby l
        where l.id = (split_part(name, '.', 1))::uuid
          and l.captain_id = auth.uid()
    )
);

create policy "lobby_avatar: captain can replace"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'lobby_avatar'
    and exists (
        select 1 from public.lobby l
        where l.id = (split_part(name, '.', 1))::uuid
          and l.captain_id = auth.uid()
    )
)
with check (
    bucket_id = 'lobby_avatar'
    and exists (
        select 1 from public.lobby l
        where l.id = (split_part(name, '.', 1))::uuid
          and l.captain_id = auth.uid()
    )
);

create policy "lobby_avatar: captain can delete"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'lobby_avatar'
    and exists (
        select 1 from public.lobby l
        where l.id = (split_part(name, '.', 1))::uuid
          and l.captain_id = auth.uid()
    )
);
