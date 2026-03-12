-- Make lat, lon, full_address, city_cluster optional so user-entered locations
-- (without geocoding data) can be inserted.
ALTER TABLE public.location ALTER COLUMN lat DROP NOT NULL;
ALTER TABLE public.location ALTER COLUMN lon DROP NOT NULL;
ALTER TABLE public.location ALTER COLUMN full_address DROP NOT NULL;
ALTER TABLE public.location ALTER COLUMN city_cluster DROP NOT NULL;

-- RPC: atomically create location (if needed) + lobby + add the host as the first member.
-- Pass p_home_ground_id for an existing (geocoded) location, or omit it and supply
-- p_location_name / address fields to create a new free-text location on the fly.
-- Returns the created lobby row as JSON.
CREATE OR REPLACE FUNCTION public.create_lobby_with_location(
  p_name            text,
  p_sport_id        int,
  p_visibility      text    DEFAULT 'discoverable',
  p_playtime        jsonb   DEFAULT NULL,
  p_details         jsonb   DEFAULT NULL,
  p_home_ground_id  uuid    DEFAULT NULL,
  p_location_name   text    DEFAULT NULL,
  p_street_number   text    DEFAULT NULL,
  p_street_name     text    DEFAULT NULL,
  p_district        text    DEFAULT NULL,
  p_city            text    DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, extensions
AS $$
DECLARE
  v_user_id    uuid;
  v_loc_id     uuid;
  v_lobby_id   text;
  v_result     jsonb;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_home_ground_id IS NOT NULL THEN
    -- use the existing geocoded location directly
    v_loc_id := p_home_ground_id;
  ELSE
    -- insert a new free-text location
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

  -- add captain as first member
  INSERT INTO public.lobby_member (user_id, lobby_id)
  VALUES (v_user_id, v_lobby_id::uuid)
  ON CONFLICT DO NOTHING;

  SELECT row_to_json(l)::jsonb INTO v_result
  FROM public.lobby l
  WHERE l.id = v_lobby_id;

  RETURN v_result;
END;
$$;

ALTER FUNCTION public.create_lobby_with_location OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.create_lobby_with_location(text,int,text,jsonb,jsonb,uuid,text,text,text,text,text)
  TO authenticated, service_role;
