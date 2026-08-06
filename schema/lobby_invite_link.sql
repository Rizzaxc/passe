-- Discord-style lobby invite links. Replaces the retired email-invite flow
-- (schema/lobby_email_invite.sql, schema/invite_email_sender.sql — removed).
--
-- A captain/coordinator generates a shareable code for their lobby; anyone
-- who redeems a valid code joins the lobby immediately (no approval step —
-- the link itself is the authorization, same trust model as a captain-issued
-- 'invite' befriend record, just without picking a specific target user
-- up front). Membership is inserted directly into lobby_member, bypassing
-- lobby_befriend_record entirely.

CREATE TABLE public.lobby_invite_link (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    lobby_id uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    -- No DEFAULT here (unlike lobby.searchable_id) — the code is always
    -- supplied explicitly by generate_lobby_invite_link, schema-qualified
    -- as extensions.nanoid(10). A column default would silently 42883 under
    -- this function's SET search_path TO '' (empty), since extensions.nanoid()
    -- internally calls the unqualified gen_random_bytes(), which only
    -- resolves when 'extensions' is on the active search_path.
    code text NOT NULL UNIQUE,
    created_by uuid NOT NULL REFERENCES public."user"(id),
    created_at timestamptz DEFAULT now() NOT NULL,
    expires_at timestamptz,
    revoked_at timestamptz,
    use_count integer DEFAULT 0 NOT NULL
);

CREATE INDEX idx_lobby_invite_link_lobby_id ON public.lobby_invite_link (lobby_id);

ALTER TABLE public.lobby_invite_link ENABLE ROW LEVEL SECURITY;

-- Any lobby member can view their lobby's invite link rows (same visibility
-- as searchable_id today) — writes only ever happen through the
-- SECURITY DEFINER RPCs below, so no INSERT/UPDATE/DELETE policy is needed.
CREATE POLICY "Members can view their lobby's invite links"
ON public.lobby_invite_link FOR SELECT TO authenticated
USING (EXISTS (
    SELECT 1 FROM public.lobby_member lm
    WHERE lm.lobby_id = lobby_invite_link.lobby_id AND lm.user_id = auth.uid()
));

-- ─────────────────────────────────────────────────────────────────
-- Generate / regenerate — manage-tier only. Revokes any currently-active
-- link for the lobby and creates a new one; there is exactly one active
-- link per lobby at a time.
-- ─────────────────────────────────────────────────────────────────

-- search_path includes 'extensions' (not the usual empty '') — needed for
-- extensions.nanoid(), whose own body calls the unqualified
-- gen_random_bytes() and has no SET search_path of its own, so it inherits
-- whatever this function's is. Same non-empty search_path
-- create_lobby_with_location already uses for the same reason
-- (lobby.searchable_id's nanoid default).
CREATE OR REPLACE FUNCTION public.generate_lobby_invite_link(
    p_lobby_id uuid,
    p_expires_in interval DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO 'public', 'extensions' AS $$
DECLARE
    v_uid  uuid := auth.uid();
    v_code text;
    v_exp  timestamptz;
BEGIN
    IF NOT public.lobby_can_manage(p_lobby_id, v_uid) THEN
        RAISE EXCEPTION 'Not authorized to manage this lobby';
    END IF;

    UPDATE public.lobby_invite_link
       SET revoked_at = now()
     WHERE lobby_id = p_lobby_id AND revoked_at IS NULL;

    v_exp := CASE WHEN p_expires_in IS NULL THEN NULL ELSE now() + p_expires_in END;
    v_code := extensions.nanoid(10);

    INSERT INTO public.lobby_invite_link (lobby_id, code, created_by, expires_at)
    VALUES (p_lobby_id, v_code, v_uid, v_exp)
    RETURNING code, expires_at INTO v_code, v_exp;

    RETURN jsonb_build_object('code', v_code, 'expires_at', v_exp);
END;
$$;

GRANT EXECUTE ON FUNCTION public.generate_lobby_invite_link(uuid, interval) TO authenticated;

-- ─────────────────────────────────────────────────────────────────
-- Revoke — manage-tier only. Removes the active link without replacing it.
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.revoke_lobby_invite_link(
    p_lobby_id uuid
) RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
BEGIN
    IF NOT public.lobby_can_manage(p_lobby_id, auth.uid()) THEN
        RAISE EXCEPTION 'Not authorized to manage this lobby';
    END IF;

    UPDATE public.lobby_invite_link
       SET revoked_at = now()
     WHERE lobby_id = p_lobby_id AND revoked_at IS NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.revoke_lobby_invite_link(uuid) TO authenticated;

-- ─────────────────────────────────────────────────────────────────
-- Preview — no auth required. Guests have no Supabase session at all
-- (auth.uid() is genuinely NULL, not just app-side), so the deep-link
-- landing screen needs an anon-callable lookup to show "you're invited to
-- join X" before asking anyone to sign in.
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_lobby_invite_preview(
    p_code text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_link record;
BEGIN
    SELECT lil.*, l.name AS lobby_name, l.sport_id, l.member_count, u.username AS captain_username
      INTO v_link
      FROM public.lobby_invite_link lil
      JOIN public.lobby l ON l.id = lil.lobby_id
      JOIN public."user" u ON u.id = l.captain_id
     WHERE lil.code = p_code;

    IF v_link IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    ELSIF v_link.revoked_at IS NOT NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'revoked');
    ELSIF v_link.expires_at IS NOT NULL AND v_link.expires_at <= now() THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'expired');
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'lobby_id', v_link.lobby_id,
        'lobby_name', v_link.lobby_name,
        'sport_id', v_link.sport_id,
        'member_count', v_link.member_count,
        'captain_username', v_link.captain_username
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_lobby_invite_preview(text) TO anon, authenticated;

-- ─────────────────────────────────────────────────────────────────
-- Redeem — authenticated only. Instant auto-join, no approval step.
-- Bypasses lobby_befriend_record entirely (and, deliberately, the
-- visibility='private' block that RLS puts on ordinary join *requests* —
-- a captain sharing an invite link is explicit consent).
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.redeem_lobby_invite_link(
    p_code text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
    v_uid  uuid := auth.uid();
    v_link record;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT lil.*, l.name AS lobby_name
      INTO v_link
      FROM public.lobby_invite_link lil
      JOIN public.lobby l ON l.id = lil.lobby_id
     WHERE lil.code = p_code;

    IF v_link IS NULL THEN
        RETURN jsonb_build_object('status', 'invalid', 'reason', 'not_found');
    ELSIF v_link.revoked_at IS NOT NULL THEN
        RETURN jsonb_build_object('status', 'invalid', 'reason', 'revoked');
    ELSIF v_link.expires_at IS NOT NULL AND v_link.expires_at <= now() THEN
        RETURN jsonb_build_object('status', 'invalid', 'reason', 'expired');
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.lobby_member lm
        WHERE lm.lobby_id = v_link.lobby_id AND lm.user_id = v_uid
    ) THEN
        RETURN jsonb_build_object(
            'status', 'already_member',
            'lobby_id', v_link.lobby_id,
            'lobby_name', v_link.lobby_name
        );
    END IF;

    INSERT INTO public.lobby_member (user_id, lobby_id) VALUES (v_uid, v_link.lobby_id);

    UPDATE public.lobby_invite_link
       SET use_count = use_count + 1
     WHERE id = v_link.id;

    RETURN jsonb_build_object(
        'status', 'joined',
        'lobby_id', v_link.lobby_id,
        'lobby_name', v_link.lobby_name
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.redeem_lobby_invite_link(text) TO authenticated;
