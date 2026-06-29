-- Wire lobby_email_invite to the send-invite-email Edge Function via pg_net.
-- Pattern mirrors fn_invoke_send_push in push_notifications.sql.

-- Track whether the email was sent so retries/sweeps skip it.
ALTER TABLE public.lobby_email_invite
ADD COLUMN IF NOT EXISTS email_sent boolean DEFAULT false NOT NULL;

-- ── Poke helper ──────────────────────────────────────────────────
-- Reads the Edge Function URL + auth key from Vault, POSTs the
-- invite payload. Gracefully no-ops if secrets aren't set yet.
--
-- Vault secrets needed:
--   edge_invite_email_url   — full URL of the send-invite-email function
--   edge_invite_email_key   — shared bearer token (= INVITE_INVOKE_SECRET)

CREATE OR REPLACE FUNCTION public.fn_invoke_send_invite_email(
    p_invite_id  uuid,
    p_email      text,
    p_inviter_id uuid,
    p_lobby_id   uuid
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_url          text;
    v_key          text;
    v_inviter_name text;
    v_lobby_name   text;
    v_sport_name   text;
BEGIN
    SELECT decrypted_secret INTO v_url
        FROM vault.decrypted_secrets WHERE name = 'edge_invite_email_url';
    SELECT decrypted_secret INTO v_key
        FROM vault.decrypted_secrets WHERE name = 'edge_invite_email_key';

    IF v_url IS NULL OR v_key IS NULL THEN
        RETURN;
    END IF;

    SELECT u.username INTO v_inviter_name
        FROM public."user" u WHERE u.id = p_inviter_id;

    SELECT l.name, s.name INTO v_lobby_name, v_sport_name
        FROM public.lobby l
        LEFT JOIN public.sport s ON s.id = l.sport_id
        WHERE l.id = p_lobby_id;

    PERFORM net.http_post(
        url     := v_url,
        headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || v_key
        ),
        body    := jsonb_build_object(
            'invite_id',    p_invite_id,
            'email',        p_email,
            'inviter_name', COALESCE(v_inviter_name, 'Ai đó'),
            'lobby_name',   COALESCE(v_lobby_name, 'một lobby'),
            'sport_name',   COALESCE(v_sport_name, '')
        )
    );
END;
$$;

-- ── AFTER INSERT trigger ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.fn_lobby_email_invite_send()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    PERFORM public.fn_invoke_send_invite_email(
        NEW.id, NEW.email, NEW.inviter_user_id, NEW.lobby_id
    );
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS lobby_email_invite_send ON public.lobby_email_invite;
CREATE TRIGGER lobby_email_invite_send
AFTER INSERT ON public.lobby_email_invite
FOR EACH ROW
EXECUTE FUNCTION public.fn_lobby_email_invite_send();
