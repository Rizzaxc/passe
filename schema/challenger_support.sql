-- Add challenger mode flag to lobby table
ALTER TABLE public.lobby
    ADD COLUMN IF NOT EXISTS open_to_challengers boolean DEFAULT false NOT NULL;

-- Query function for the challenger feed
-- Returns lobbies that are open to challengers, filtered by sport and location,
-- ordered by profile compatibility score (same scoring as teammate feed).
-- Excludes lobbies the current user is already a member of.
CREATE OR REPLACE FUNCTION public.home_challenger_lobby_data(
    p_sport_id bigint,
    p_city integer,
    p_districts character varying[],
    p_page_size integer DEFAULT 10,
    p_page_number integer DEFAULT 1
) RETURNS TABLE (
    id uuid,
    name character varying,
    homeground_name character varying,
    playtime jsonb,
    details jsonb,
    visibility public.lobby_visibility,
    member_count bigint,
    profile_compat_score numeric
)
    LANGUAGE plpgsql
    SET search_path TO ''
AS $$
BEGIN
    RETURN QUERY
        SELECT l.id,
               l.name,
               loc.name                                                          AS homeground_name,
               l.playtime,
               l.details,
               l.visibility,
               COUNT(lm.id)                                                      AS member_count,
               public.calculate_profile_compat_score(auth.uid(), l.id, l.sport_id) AS profile_compat_score
        FROM public.lobby l
                 JOIN public.location loc ON l.home_ground = loc.id
                 LEFT JOIN public.lobby_member lm ON lm.lobby_id = l.id
        WHERE l.sport_id = p_sport_id
          AND l.open_to_challengers = true
          AND l.visibility != 'private'
          AND loc.city_cluster = p_city
          AND loc.district = ANY (p_districts)
          AND l.captain_id != auth.uid()
          AND l.id NOT IN (SELECT lm2.lobby_id
                           FROM public.lobby_member lm2
                           WHERE lm2.user_id = auth.uid())
        GROUP BY l.id, loc.name
        ORDER BY profile_compat_score DESC
        LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
