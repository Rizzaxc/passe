-- Storage RLS for the `user_avatar` bucket.
--
-- The bucket itself already exists (public read, one object per user at
-- `<user.id>.jpg`, see the `user_avatar` handling notes in profile_tab's
-- CLAUDE.md and the comment atop lobby_avatar.sql) but was missing any
-- storage.objects policies — RLS defaults to deny, so every upload/replace
-- from ProfileController.commit() (lib/profile_tab/profile_controller.dart)
-- was silently rejected with a 400, caught by the client and surfaced as
-- AvatarUploadFailedException while falling back to a generated avatar.

create policy "user_avatar: public read"
on storage.objects
for select
to public
using (bucket_id = 'user_avatar');

create policy "user_avatar: owner can upload"
on storage.objects
for insert
to authenticated
with check (
    bucket_id = 'user_avatar'
    and split_part(name, '.', 1) = (auth.uid())::text
);

create policy "user_avatar: owner can replace"
on storage.objects
for update
to authenticated
using (
    bucket_id = 'user_avatar'
    and split_part(name, '.', 1) = (auth.uid())::text
)
with check (
    bucket_id = 'user_avatar'
    and split_part(name, '.', 1) = (auth.uid())::text
);

create policy "user_avatar: owner can delete"
on storage.objects
for delete
to authenticated
using (
    bucket_id = 'user_avatar'
    and split_part(name, '.', 1) = (auth.uid())::text
);
