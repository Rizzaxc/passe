-- Fixes lobby deletion: lobby_befriend_record.target_lobby_id references lobby(id) with
-- ON UPDATE CASCADE but no ON DELETE action (defaults to NO ACTION). Every other table that
-- references lobby (lobby_challenge, lobby_feed_item, lobby_invite_link, lobby_match,
-- lobby_member) already cascades on delete; a lobby with any request/invite history silently
-- fails to delete with a foreign-key violation until this is fixed.
ALTER TABLE public.lobby_befriend_record
    DROP CONSTRAINT lobby_befriend_record_target_lobby_id_fkey,
    ADD CONSTRAINT lobby_befriend_record_target_lobby_id_fkey
        FOREIGN KEY (target_lobby_id) REFERENCES public.lobby(id)
        ON UPDATE CASCADE ON DELETE CASCADE;
