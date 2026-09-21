-- Let a lobby name a venue the map doesn't name — without touching the venue.
--
-- 406 of 2,050 `location` rows (20%) have a blank `name`: real, correctly
-- geocoded places that OSM never labelled. They render as "Địa điểm chưa đặt
-- tên" plus a generic pin, which is a dead end — the person scheduling there
-- usually knows exactly what the place is called and has no way to say so.
--
-- Two things this deliberately is NOT:
--
-- * NOT a server-side rename. `location.name` stays exactly as the map source
--   left it. A nickname is one lobby's local knowledge, not a global claim,
--   and letting it propagate would mean any user could relabel a shared row
--   every other lobby also reads.
-- * NOT available on a named venue. If the map already gave the place a name,
--   that name wins — nicknaming a verified venue is how "Nhà Thi Đấu Phú Thọ"
--   becomes "sân ông Tư" for everyone who looks it up afterwards. Enforced in
--   `set_lobby_location_alias`, because a CHECK cannot span two tables.

CREATE TABLE public.lobby_location_alias (
    lobby_id    uuid NOT NULL REFERENCES public.lobby(id) ON DELETE CASCADE,
    location_id uuid NOT NULL REFERENCES public.location(id) ON DELETE CASCADE,
    name        text NOT NULL
                CHECK (btrim(name) <> '' AND char_length(name) <= 80),
    created_by  uuid NOT NULL REFERENCES public."user"(id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (lobby_id, location_id)
);

CREATE INDEX idx_lobby_location_alias_location
    ON public.lobby_location_alias (location_id);

ALTER TABLE public.lobby_location_alias ENABLE ROW LEVEL SECURITY;

-- Read is members-only: the whole point is that the name does not leave the
-- lobby. No INSERT/UPDATE/DELETE policy — writes go through the RPC below,
-- which is where the "venue must be unnamed" guard lives.
CREATE POLICY "Members read their lobby's venue aliases"
    ON public.lobby_location_alias FOR SELECT
    USING (lobby_id IN (SELECT public.get_my_lobby_ids()));

GRANT SELECT ON TABLE public.lobby_location_alias TO authenticated;

-- Set (or clear, with a null/blank name) one lobby's nickname for a venue.
-- Any member may do this, not just a manager: it is a label, it is reversible,
-- and it is confined to people who already share the lobby.
CREATE FUNCTION public.set_lobby_location_alias(
    p_lobby_id uuid,
    p_location_id uuid,
    p_name text
) RETURNS void
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
    v_uid uuid := auth.uid();
    v_venue_name text;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'not authenticated' USING ERRCODE = '42501';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.lobby_member
         WHERE lobby_id = p_lobby_id AND user_id = v_uid
    ) THEN
        RAISE EXCEPTION 'not a member of this lobby' USING ERRCODE = '42501';
    END IF;

    SELECT name INTO v_venue_name
      FROM public.location WHERE id = p_location_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'no such location' USING ERRCODE = '23503';
    END IF;

    -- The guard. A venue the map already named is not nicknameable — see the
    -- header. Blank-named rows are the entire addressable set.
    IF btrim(coalesce(v_venue_name, '')) <> '' THEN
        RAISE EXCEPTION 'this venue already has a name'
            USING ERRCODE = '22023';
    END IF;

    IF btrim(coalesce(p_name, '')) = '' THEN
        DELETE FROM public.lobby_location_alias
         WHERE lobby_id = p_lobby_id AND location_id = p_location_id;
        RETURN;
    END IF;

    INSERT INTO public.lobby_location_alias
        (lobby_id, location_id, name, created_by)
    VALUES (p_lobby_id, p_location_id, btrim(p_name), v_uid)
    ON CONFLICT (lobby_id, location_id) DO UPDATE
        SET name = EXCLUDED.name, created_by = EXCLUDED.created_by;
END;
$$;

REVOKE ALL ON FUNCTION public.set_lobby_location_alias(uuid, uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.set_lobby_location_alias(uuid, uuid, text) TO authenticated;

-- Every alias the caller can see, as {location_id: name}. One round trip for
-- a lobby screen that renders many venues.
CREATE FUNCTION public.lobby_location_aliases(p_lobby_id uuid)
RETURNS TABLE(location_id uuid, name text)
    LANGUAGE sql STABLE
    SET search_path TO 'public'
    AS $$
    SELECT a.location_id, a.name
      FROM public.lobby_location_alias a
     WHERE a.lobby_id = p_lobby_id
       AND a.lobby_id IN (SELECT public.get_my_lobby_ids());
$$;

REVOKE ALL ON FUNCTION public.lobby_location_aliases(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lobby_location_aliases(uuid) TO authenticated;
