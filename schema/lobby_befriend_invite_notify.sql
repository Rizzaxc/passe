-- Push notification on any lobby_befriend_record invite creation.
-- Extracted from lobby_email_invite.sql (now retired) — this fires for every
-- 'invite' interaction_type row, not just email-originated ones (user-search
-- invites, and the invite-link redemption path), so it must survive the
-- email-invite removal.
-- Requires: ALTER TYPE notification_kind ADD VALUE 'lobby_invite';
--           INSERT INTO enabled_notification_kind ... ;

CREATE OR REPLACE FUNCTION public.fn_notify_lobby_invite()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_inviter_name text;
    v_lobby_name   text;
BEGIN
    IF NEW.interaction_type != 'invite' OR NEW.target_user_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT u.username INTO v_inviter_name
    FROM public."user" u WHERE u.id = NEW.initiator_user_id;

    IF NEW.target_lobby_id IS NOT NULL THEN
        SELECT l.name INTO v_lobby_name
        FROM public.lobby l WHERE l.id = NEW.target_lobby_id;
    END IF;

    PERFORM public.fn_enqueue_notification(
        'lobby_invite',
        ARRAY[NEW.target_user_id],
        COALESCE(v_inviter_name, 'Ai đó') || ' mời bạn vào lobby',
        COALESCE(v_lobby_name, 'một lobby'),
        jsonb_build_object(
            'lobby_id', NEW.target_lobby_id,
            'record_id', NEW.id
        )
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS lobby_befriend_invite_notify ON public.lobby_befriend_record;
CREATE TRIGGER lobby_befriend_invite_notify
AFTER INSERT ON public.lobby_befriend_record
FOR EACH ROW
WHEN (NEW.interaction_type = 'invite')
EXECUTE FUNCTION public.fn_notify_lobby_invite();
