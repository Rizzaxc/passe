-- get_lobby_public_preview: add who's in the lobby (captain + up to 6 members).
--
-- Why: the Discover preview sheet showed only aggregates (gender/age bars,
-- top networks), so a player deciding whether to "Xin vào" couldn't see a
-- single face — or who runs the lobby. The sheet now shows a captain row and
-- an avatar strip that tap through to /user/:id.
--
-- Exposure rules (the RPC stays anon-granted, so these matter):
--   * Identities (captain / members_preview) are returned only to a SIGNED-IN
--     caller. Guests keep the aggregate-only view they had before.
--   * Anyone in a block relationship with the caller (either direction,
--     fn_is_blocked) is left out of members_preview, and the captain is
--     returned as null rather than leaking through.
--   * Only username, tag_number and the generatedAvatar marker are returned
--     — the same fields every other user chip in the app already shows.
--   * Private lobbies are still refused outright (unchanged), and MMR is
--     additionally nulled for private visibility in case that refusal is
--     ever loosened: MMR visibility follows lobby visibility, not the caller.
--
-- Everything else is identical to the live definition in schema/passe.sql.

CREATE OR REPLACE FUNCTION public.get_lobby_public_preview(p_lobby_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
DECLARE
    v_lobby       record;
    v_viewer      uuid := auth.uid();
    v_members     integer;
    v_gender      jsonb;
    v_age         jsonb;
    v_networks    jsonb;
    v_industries  jsonb;
    v_homegrounds jsonb;
    v_captain     jsonb;
    v_preview     jsonb;
BEGIN
    SELECT l.id, l.name, l.sport_id, l.description, l.playtime, l.visibility,
           l.mmr, l.rated_match_count, l.captain_id,
           loc.name AS homeground_name, loc.district AS homeground_district,
           loc.lat, loc.lon
      INTO v_lobby
      FROM public.lobby l
      LEFT JOIN public.lobby_homeground plhg ON plhg.lobby_id = l.id AND plhg.is_primary
      LEFT JOIN public.location loc ON loc.id = plhg.location_id
     WHERE l.id = p_lobby_id
       AND l.visibility <> 'private';

    IF v_lobby IS NULL THEN
        RETURN jsonb_build_object('valid', false, 'reason', 'not_found');
    END IF;

    SELECT count(*) INTO v_members
      FROM public.lobby_member
     WHERE lobby_id = p_lobby_id;

    SELECT jsonb_build_object(
        'male',    count(*) FILTER (WHERE u.details->>'gender' = 'male'),
        'female',  count(*) FILTER (WHERE u.details->>'gender' = 'female'),
        'unknown', count(*) FILTER (WHERE u.details->>'gender' IS NULL)
    ) INTO v_gender
      FROM public.lobby_member lm
      JOIN public."user" u ON u.id = lm.user_id
     WHERE lm.lobby_id = p_lobby_id;

    SELECT coalesce(jsonb_object_agg(age_group, cnt), '{}'::jsonb) INTO v_age
      FROM (
          SELECT coalesce(u.details->>'ageGroup', 'unknown') AS age_group, count(*) AS cnt
            FROM public.lobby_member lm
            JOIN public."user" u ON u.id = lm.user_id
           WHERE lm.lobby_id = p_lobby_id
           GROUP BY 1
      ) t;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
               'id', network_id, 'name', name, 'category', category, 'count', cnt
           ) ORDER BY cnt DESC), '[]'::jsonb) INTO v_networks
      FROM (
          SELECT n.id AS network_id, n.name, n.category, count(*) AS cnt
            FROM public.lobby_member lm
            JOIN public.user_network un ON un.user_id = lm.user_id
            JOIN public.network n ON n.id = un.network_id
           WHERE lm.lobby_id = p_lobby_id
           GROUP BY n.id, n.name, n.category
           ORDER BY cnt DESC
           LIMIT 5
      ) t;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
               'industry_id', industry_id, 'count', cnt
           ) ORDER BY cnt DESC), '[]'::jsonb) INTO v_industries
      FROM (
          SELECT ui.industry_id, count(*) AS cnt
            FROM public.lobby_member lm
            JOIN public.user_industry ui ON ui.user_id = lm.user_id
           WHERE lm.lobby_id = p_lobby_id
           GROUP BY ui.industry_id
           ORDER BY cnt DESC
           LIMIT 5
      ) t;

    SELECT coalesce(jsonb_agg(jsonb_build_object(
               'id', gloc.id, 'name', gloc.name, 'district', gloc.district,
               'lat', gloc.lat, 'lon', gloc.lon
           ) ORDER BY gh.is_primary DESC, gh.created_at), '[]'::jsonb) INTO v_homegrounds
      FROM public.lobby_homeground gh
      JOIN public.location gloc ON gloc.id = gh.location_id
     WHERE gh.lobby_id = p_lobby_id;

    IF v_viewer IS NOT NULL THEN
        SELECT jsonb_build_object(
                   'id', u.id,
                   'username', u.username,
                   'tag_number', u.tag_number,
                   'generated_avatar', u.details->>'generatedAvatar'
               )
          INTO v_captain
          FROM public."user" u
         WHERE u.id = v_lobby.captain_id
           AND NOT public.fn_is_blocked(v_viewer, u.id);

        -- Captain first, then coordinators, then members; capped at 6 — the
        -- strip shows "+N" off member_count for the rest.
        SELECT coalesce(jsonb_agg(jsonb_build_object(
                   'id', id,
                   'username', username,
                   'tag_number', tag_number,
                   'generated_avatar', generated_avatar
               ) ORDER BY rank, username), '[]'::jsonb)
          INTO v_preview
          FROM (
              SELECT u.id, u.username, u.tag_number,
                     u.details->>'generatedAvatar' AS generated_avatar,
                     CASE
                         WHEN u.id = v_lobby.captain_id THEN 0
                         WHEN lm.role = 'coordinator' THEN 1
                         ELSE 2
                     END AS rank
                FROM public.lobby_member lm
                JOIN public."user" u ON u.id = lm.user_id
               WHERE lm.lobby_id = p_lobby_id
                 AND NOT public.fn_is_blocked(v_viewer, u.id)
               ORDER BY rank, u.username
               LIMIT 6
          ) t;
    END IF;

    RETURN jsonb_build_object(
        'valid', true,
        'id', v_lobby.id,
        'name', v_lobby.name,
        'sport_id', v_lobby.sport_id,
        'description', v_lobby.description,
        'member_count', v_members,
        'playtime', v_lobby.playtime,
        'homeground_name', v_lobby.homeground_name,
        'homeground_district', v_lobby.homeground_district,
        'homeground_lat', v_lobby.lat,
        'homeground_lon', v_lobby.lon,
        'homegrounds', v_homegrounds,
        'mmr', CASE WHEN v_lobby.visibility <> 'private' THEN v_lobby.mmr END,
        'rated_match_count', v_lobby.rated_match_count,
        'gender_breakdown', v_gender,
        'age_group_breakdown', v_age,
        'top_networks', v_networks,
        'top_industries', v_industries,
        'captain', v_captain,
        'members_preview', coalesce(v_preview, '[]'::jsonb)
    );
END;
$$;
