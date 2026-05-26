-- ============================================================================
-- Lobby ↔ lobby_member integrity
--
-- Pushes three invariants into the schema so they hold no matter which
-- code path created / mutated the rows:
--
--   1. Every lobby's captain has a `lobby_member` row in their own lobby.
--   2. The captain cannot leave their own lobby while still its captain
--      — captaincy must be transferred first (or the lobby deleted).
--   3. A lobby can only be deleted when its captain is the sole member
--      remaining (everyone else has to leave first). A 1-member lobby
--      that the captain wants to abandon must be explicitly deleted.
--
-- Service-role / admin bypasses are not covered — they sidestep RLS and
-- can also sidestep these triggers if invoked with `session_replication_role`
-- set, which we don't try to defend against.
-- ============================================================================


-- ─── (1) Captain auto-joined on lobby INSERT ───────────────────

CREATE OR REPLACE FUNCTION public.lobby_add_captain_as_member()
RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
AS $$
BEGIN
    INSERT INTO public.lobby_member (user_id, lobby_id)
    VALUES (NEW.captain_id, NEW.id)
    ON CONFLICT (user_id, lobby_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS lobby_add_captain_as_member ON public.lobby;

CREATE TRIGGER lobby_add_captain_as_member
    AFTER INSERT ON public.lobby
    FOR EACH ROW
    EXECUTE FUNCTION public.lobby_add_captain_as_member();


-- One-shot backfill: any pre-trigger lobby whose captain isn't a member
-- gets fixed up here. Idempotent via the unique (user_id, lobby_id).
INSERT INTO public.lobby_member (user_id, lobby_id)
SELECT l.captain_id, l.id
FROM public.lobby l
ON CONFLICT (user_id, lobby_id) DO NOTHING;


-- ─── (2) Captain can't leave while still captain ───────────────
--
-- The check has to coexist with lobby deletion (which cascades to
-- lobby_member rows including the captain's). We pass a tx-local config
-- from the lobby BEFORE DELETE trigger to whitelist that specific
-- cascade — see lobby_before_delete() below.

CREATE OR REPLACE FUNCTION public.lobby_member_prevent_captain_leave()
RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
AS $$
DECLARE
    v_captain_id     uuid;
    v_being_deleted  text;
BEGIN
    SELECT captain_id
        INTO v_captain_id
        FROM public.lobby
        WHERE id = OLD.lobby_id;

    -- Lobby is already gone (e.g. a different cascade path) — let the
    -- delete through.
    IF v_captain_id IS NULL THEN
        RETURN OLD;
    END IF;

    -- Non-captain leaving: always OK.
    IF v_captain_id <> OLD.user_id THEN
        RETURN OLD;
    END IF;

    -- Captain leaving: only allowed when the lobby itself is being
    -- deleted in this same transaction (signal set by lobby_before_delete).
    v_being_deleted := current_setting('app.lobby_being_deleted', true);
    IF v_being_deleted = OLD.lobby_id::text THEN
        RETURN OLD;
    END IF;

    RAISE EXCEPTION
        'Captain cannot leave lobby % — transfer captaincy first', OLD.lobby_id;
END;
$$;

DROP TRIGGER IF EXISTS lobby_member_prevent_captain_leave ON public.lobby_member;

CREATE TRIGGER lobby_member_prevent_captain_leave
    BEFORE DELETE ON public.lobby_member
    FOR EACH ROW
    EXECUTE FUNCTION public.lobby_member_prevent_captain_leave();


-- ─── (3) Lobby delete only when captain is the sole remaining member ──
--
-- Members other than the captain block the delete — they must leave
-- first. The captain's own lobby_member row is removed via the cascade
-- on lobby_member.lobby_id (set up below). The captain-leave trigger
-- recognises the tx-local signal set here and lets that cascade through.

CREATE OR REPLACE FUNCTION public.lobby_before_delete()
RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
AS $$
DECLARE
    v_other_members int;
BEGIN
    SELECT COUNT(*)
        INTO v_other_members
        FROM public.lobby_member
        WHERE lobby_id = OLD.id
          AND user_id <> OLD.captain_id;

    IF v_other_members > 0 THEN
        RAISE EXCEPTION
            'Cannot delete lobby % while % other member(s) remain — they must leave first',
            OLD.id, v_other_members;
    END IF;

    -- Whitelist the captain-leave check for the cascade that's about
    -- to run on lobby_member. `true` makes the setting tx-local.
    PERFORM set_config('app.lobby_being_deleted', OLD.id::text, true);

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS lobby_before_delete ON public.lobby;

CREATE TRIGGER lobby_before_delete
    BEFORE DELETE ON public.lobby
    FOR EACH ROW
    EXECUTE FUNCTION public.lobby_before_delete();


-- Cascade the captain's lobby_member row when the lobby is deleted.
-- Previously the FK had no ON DELETE action, so deleting a lobby would
-- fail with an FK violation if any lobby_member row existed (which is
-- always, now that the captain auto-joins).
ALTER TABLE public.lobby_member
    DROP CONSTRAINT IF EXISTS lobby_member_lobby_id_fkey;

ALTER TABLE public.lobby_member
    ADD CONSTRAINT lobby_member_lobby_id_fkey
        FOREIGN KEY (lobby_id) REFERENCES public.lobby(id) ON DELETE CASCADE;


-- ─── De-duplicate captain-insert from existing RPCs ────────────
--
-- Both call sites previously inserted the captain into lobby_member
-- with ON CONFLICT DO NOTHING. The trigger above now owns that
-- responsibility — these functions just create the lobby (and, in the
-- befriend pair case, add the OTHER user).

CREATE OR REPLACE FUNCTION public.create_lobby_with_location(
    p_name text,
    p_sport_id integer,
    p_visibility text DEFAULT 'discoverable'::text,
    p_playtime jsonb DEFAULT NULL::jsonb,
    p_details jsonb DEFAULT NULL::jsonb,
    p_home_ground_id uuid DEFAULT NULL::uuid,
    p_location_name text DEFAULT NULL::text,
    p_street_number text DEFAULT NULL::text,
    p_street_name text DEFAULT NULL::text,
    p_district text DEFAULT NULL::text,
    p_city text DEFAULT NULL::text
) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'extensions'
AS $$
DECLARE
    v_user_id  uuid;
    v_loc_id   uuid;
    v_lobby_id uuid;
    v_result   jsonb;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_home_ground_id IS NOT NULL THEN
        v_loc_id := p_home_ground_id;
    ELSIF p_location_name IS NOT NULL OR p_street_name IS NOT NULL OR p_city IS NOT NULL THEN
        INSERT INTO public.location (name, street_number, street_name, district, city)
        VALUES (
            NULLIF(TRIM(COALESCE(p_location_name, '')), ''),
            NULLIF(p_street_number, '')::integer,
            NULLIF(p_street_name,   ''),
            NULLIF(p_district,      ''),
            NULLIF(p_city,          '')
        )
        RETURNING id INTO v_loc_id;
    END IF;

    INSERT INTO public.lobby (name, sport_id, visibility, playtime, details, home_ground, captain_id)
    VALUES (
        p_name,
        p_sport_id,
        p_visibility::public.lobby_visibility,
        p_playtime,
        p_details,
        v_loc_id,
        v_user_id
    )
    RETURNING id INTO v_lobby_id;

    -- Captain → lobby_member is handled by the lobby_add_captain_as_member
    -- AFTER INSERT trigger.

    SELECT row_to_json(l)::jsonb
        INTO v_result
        FROM public.lobby l
        WHERE l.id = v_lobby_id;

    RETURN v_result;
END;
$$;


CREATE OR REPLACE FUNCTION public.lobby_befriend_accepted_trigger_fn()
RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
AS $$
DECLARE
    new_lobby_id       uuid;
    initiator_username text;
    target_username    text;
    lobby_name         text;
    sport_id           bigint;
BEGIN
    IF NEW.status = 'accepted' AND (OLD.status IS NULL OR OLD.status != 'accepted') THEN

        -- 'request' / 'invite' add the relevant user to an existing lobby.
        IF NEW.interaction_type = 'request' AND NEW.target_lobby_id IS NOT NULL THEN
            INSERT INTO public.lobby_member (user_id, lobby_id)
            VALUES (NEW.initiator_user_id, NEW.target_lobby_id)
            ON CONFLICT DO NOTHING;

        ELSIF NEW.interaction_type = 'invite' AND NEW.target_user_id IS NOT NULL THEN
            INSERT INTO public.lobby_member (user_id, lobby_id)
            VALUES (NEW.target_user_id, NEW.target_lobby_id)
            ON CONFLICT DO NOTHING;

        -- 'pair' creates a brand-new lobby. The captain (initiator) is
        -- joined automatically by lobby_add_captain_as_member; we only
        -- need to add the OTHER user.
        ELSIF NEW.interaction_type = 'pair' AND NEW.target_user_id IS NOT NULL THEN
            IF NEW.details ? 'sport_id' THEN
                sport_id := (NEW.details ->> 'sport_id')::bigint;

                SELECT username INTO initiator_username
                    FROM public."user" WHERE id = NEW.initiator_user_id;
                SELECT username INTO target_username
                    FROM public."user" WHERE id = NEW.target_user_id;
                lobby_name := initiator_username || ' & ' || target_username;

                INSERT INTO public.lobby (captain_id, name, sport_id)
                VALUES (NEW.initiator_user_id, lobby_name, sport_id)
                RETURNING id INTO new_lobby_id;

                INSERT INTO public.lobby_member (user_id, lobby_id)
                VALUES (NEW.target_user_id, new_lobby_id)
                ON CONFLICT DO NOTHING;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;
