-- Pending email invites for users not yet on the platform.
-- When the invitee signs up, a trigger auto-joins them to the lobby.

CREATE TABLE public.lobby_email_invite (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    lobby_id uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    inviter_user_id uuid NOT NULL REFERENCES public."user"(id),
    email text NOT NULL,
    status text DEFAULT 'pending' NOT NULL
        CHECK (status IN ('pending', 'accepted', 'expired')),
    created_at timestamptz DEFAULT now() NOT NULL,
    expires_at timestamptz DEFAULT (now() + interval '7 days') NOT NULL,
    UNIQUE (lobby_id, email)
);

ALTER TABLE public.lobby_email_invite ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view email invites"
ON public.lobby_email_invite FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.lobby_member lm
    WHERE lm.lobby_id = lobby_email_invite.lobby_id AND lm.user_id = auth.uid()
));

CREATE POLICY "Members can create email invites"
ON public.lobby_email_invite FOR INSERT TO authenticated
WITH CHECK (
    inviter_user_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = lobby_email_invite.lobby_id AND lm.user_id = auth.uid()
    )
);

-- ─────────────────────────────────────────────────────────────────
-- RPC: invite by email — resolves existing vs new user
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.invite_to_lobby_by_email(
    p_lobby_id uuid,
    p_email text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid        uuid := auth.uid();
    v_target_uid uuid;
    v_email      text := lower(trim(p_email));
BEGIN
    -- Caller must be a lobby member
    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = p_lobby_id AND lm.user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'Not a member of this lobby';
    END IF;

    -- Look up existing user by email
    SELECT au.id INTO v_target_uid
    FROM auth.users au
    WHERE au.email = v_email
    LIMIT 1;

    IF v_target_uid IS NOT NULL THEN
        -- Already a member?
        IF EXISTS (
            SELECT 1 FROM public.lobby_member lm
            WHERE lm.lobby_id = p_lobby_id AND lm.user_id = v_target_uid
        ) THEN
            RETURN jsonb_build_object('status', 'already_member');
        END IF;

        -- Create a normal befriend invite (triggers handle reciprocal auto-accept)
        INSERT INTO public.lobby_befriend_record (
            initiator_user_id, target_user_id, target_lobby_id, interaction_type
        ) VALUES (v_uid, v_target_uid, p_lobby_id, 'invite');

        RETURN jsonb_build_object('status', 'invited_existing');
    ELSE
        -- New user: upsert email invite (re-invite resets an expired row)
        INSERT INTO public.lobby_email_invite (lobby_id, inviter_user_id, email)
        VALUES (p_lobby_id, v_uid, v_email)
        ON CONFLICT (lobby_id, email) DO UPDATE
        SET status = 'pending',
            inviter_user_id = v_uid,
            expires_at = now() + interval '7 days',
            created_at = now()
        WHERE public.lobby_email_invite.status != 'pending';

        RETURN jsonb_build_object('status', 'invited_new');
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.invite_to_lobby_by_email(uuid, text) TO authenticated;

-- ─────────────────────────────────────────────────────────────────
-- Auto-join trigger: when a new public.user row is created (via the
-- auth signup trigger), check for pending email invites and add the
-- user to those lobbies.
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.lobby_email_invite_auto_join_fn()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_email  text;
    v_invite record;
BEGIN
    SELECT au.email INTO v_email
    FROM auth.users au WHERE au.id = NEW.id;

    IF v_email IS NULL THEN RETURN NEW; END IF;

    FOR v_invite IN
        SELECT * FROM public.lobby_email_invite lei
        WHERE lei.email = v_email
          AND lei.status = 'pending'
          AND lei.expires_at > now()
    LOOP
        -- Create a pending befriend invite (user must accept manually)
        INSERT INTO public.lobby_befriend_record (
            initiator_user_id, target_user_id, target_lobby_id, interaction_type
        ) VALUES (v_invite.inviter_user_id, NEW.id, v_invite.lobby_id, 'invite')
        ON CONFLICT DO NOTHING;

        UPDATE public.lobby_email_invite
        SET status = 'accepted'
        WHERE id = v_invite.id;
    END LOOP;

    RETURN NEW;
END;
$$;

CREATE TRIGGER lobby_email_invite_auto_join
AFTER INSERT ON public."user"
FOR EACH ROW
EXECUTE FUNCTION public.lobby_email_invite_auto_join_fn();

-- ─────────────────────────────────────────────────────────────────
-- Push notification on befriend invite creation.
-- Requires: ALTER TYPE notification_kind ADD VALUE 'lobby_invite';
--           INSERT INTO enabled_notification_kind ... ;
-- ─────────────────────────────────────────────────────────────────

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

CREATE TRIGGER lobby_befriend_invite_notify
AFTER INSERT ON public.lobby_befriend_record
FOR EACH ROW
WHEN (NEW.interaction_type = 'invite')
EXECUTE FUNCTION public.fn_notify_lobby_invite();
