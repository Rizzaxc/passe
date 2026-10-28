-- ============================================================================
-- Discover ▸ Thách đấu: hide offers the context lobby can't challenge anyway
-- ============================================================================
-- send_friendly_challenge and respond_friendly_challenge both reject a pair of
-- lobbies that share a manager (captain or coordinator, fn_lobbies_share_manager),
-- which stops one person farming rating with two lobbies. The feed still listed
-- those offers, so someone running two lobbies saw their other lobby's offer,
-- filled in the confirm sheet, and only then got the error toast.
--
-- This filters them out of the feed instead. The feed runs as the caller, and
-- lobby_member RLS only shows members of lobbies you're in, so the overlap can't
-- be computed inline: a coordinator of the OFFERING lobby would be invisible.
-- fn_shared_manager_lobby_ids (SECURITY DEFINER) computes the excluded set once
-- per call, and returns nothing unless the caller belongs to the context lobby,
-- so it can't be used to map out other lobbies' managers. The RPC guards stay
-- the authority; this is only about not showing a dead card.
--
-- Apply after friendly_challenge_followups.sql (which defines the helper).
-- Return shape unchanged, so CREATE OR REPLACE is enough.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fn_shared_manager_lobby_ids(p_lobby_id uuid)
RETURNS uuid[]
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path TO ''
AS $$
    WITH me AS (
        SELECT 1 WHERE EXISTS (
            SELECT 1 FROM public.lobby_member
             WHERE lobby_id = p_lobby_id AND user_id = auth.uid())
    ), mine AS (
        SELECT l.captain_id AS uid FROM public.lobby l, me WHERE l.id = p_lobby_id
        UNION
        SELECT m.user_id FROM public.lobby_member m, me
         WHERE m.lobby_id = p_lobby_id AND m.role = 'coordinator'
    ), theirs AS (
        SELECT l.id FROM public.lobby l JOIN mine ON mine.uid = l.captain_id
        UNION
        SELECT m.lobby_id FROM public.lobby_member m
          JOIN mine ON mine.uid = m.user_id
         WHERE m.role = 'coordinator'
    )
    SELECT COALESCE(array_agg(id), '{}') FROM theirs WHERE id <> p_lobby_id;
$$;

REVOKE ALL ON FUNCTION public.fn_shared_manager_lobby_ids(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fn_shared_manager_lobby_ids(uuid)
    TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.friendly_offer_feed_data(p_context_lobby_id uuid, p_sport_id bigint, p_city integer DEFAULT NULL::integer, p_districts character varying[] DEFAULT NULL::character varying[], p_search text DEFAULT NULL::text, p_mmr_window integer DEFAULT 200, p_page_size integer DEFAULT 20, p_page_number integer DEFAULT 1) RETURNS TABLE(offer_id uuid, slot smallint, lobby_id uuid, lobby_name text, lobby_mmr integer, trust_score integer, rated_match_count integer, member_count integer, description text, homeground_name text, kickoff timestamp with time zone, expires_at timestamp with time zone, location_name text, venue_cost numeric, cost_split public.challenge_cost_split, bounty_kind public.challenge_bounty_kind, bounty_amount numeric, ruleset public.challenge_ruleset, ruleset_param smallint, handicap_side public.challenge_handicap_side, handicap_amount smallint, terms_note text, favorability text, recommendation_counts jsonb, already_challenged boolean)
    LANGUAGE plpgsql STABLE
    SET search_path TO ''
    AS $$
DECLARE
    c_home_adv constant integer := 50;
    v_mmr integer;
    v_excluded uuid[];
BEGIN
    SELECT l.mmr INTO v_mmr FROM public.lobby l WHERE l.id = p_context_lobby_id;
    v_mmr := COALESCE(v_mmr, 1000);

    -- Lobbies sharing a captain/coordinator with the context lobby: the
    -- send guard would reject them, so don't list them. Empty for guests.
    v_excluded := public.fn_shared_manager_lobby_ids(p_context_lobby_id);

    RETURN QUERY
    SELECT o.id, o.slot, l.id, l.name::text,
           l.mmr, l.trust_score, l.rated_match_count,
           l.member_count, l.description,
           (SELECT loc2.name FROM public.lobby_homeground hg
              JOIN public.location loc2 ON loc2.id = hg.location_id
             WHERE hg.lobby_id = l.id AND hg.is_primary LIMIT 1),
           o.kickoff, o.expires_at, loc.name::text,
           o.venue_cost, o.cost_split, o.bounty_kind, o.bounty_amount,
           o.ruleset, o.ruleset_param, o.handicap_side, o.handicap_amount,
           o.terms_note,
           -- Stated from the CHALLENGER's point of view, honouring the same
           -- home advantage the rating engine applies if this match happens.
           CASE
               WHEN (l.mmr + c_home_adv) - v_mmr >  p_mmr_window THEN 'harder'
               WHEN v_mmr - (l.mmr + c_home_adv) >  p_mmr_window THEN 'easier'
               ELSE 'even'
           END::text,
           public.lobby_recommendation_counts(l.id),
           EXISTS (SELECT 1 FROM public.lobby_challenge c
                    WHERE c.offer_id = o.id
                      AND c.initiator_lobby_id = p_context_lobby_id
                      AND c.status IN ('requested', 'pending_home'))
      FROM public.lobby_challenge_offer o
      JOIN public.lobby l ON l.id = o.lobby_id
      JOIN public.location loc ON loc.id = o.location_id
     WHERE o.status = 'open'
       AND o.mode = 'friendly'
       AND o.expires_at > now()
       AND l.sport_id = p_sport_id
       AND l.visibility <> 'private'
       AND l.id <> COALESCE(p_context_lobby_id, '00000000-0000-0000-0000-000000000000'::uuid)
       AND NOT (l.id = ANY(v_excluded))
       AND (p_city IS NULL OR loc.city_cluster = p_city)
       AND (p_districts IS NULL OR array_length(p_districts, 1) IS NULL
            OR loc.district = ANY(p_districts))
       AND (p_search IS NULL OR btrim(p_search) = ''
            OR l.name ILIKE '%' || btrim(p_search) || '%')
     ORDER BY abs((l.mmr + c_home_adv) - v_mmr), o.kickoff
     LIMIT p_page_size OFFSET (p_page_number - 1) * p_page_size;
END;
$$;
