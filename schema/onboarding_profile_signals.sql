-- Lets the onboarding gate recognize a pre-existing account signing in on a
-- fresh install (no local SharedPreferences flags at all — not even a
-- bridged guest one, see onboarding_prefs.dart) as already set up, instead
-- of showing them the new-user tour again. `gender`/`avatar` are already on
-- the `user` row the client loads on every auth resolve, so only the
-- cross-table "does this account have a seeded sport profile, and which
-- sport" lookup needs a function — mirrors freeplay_user_skill()'s per-sport
-- elo_seed lookup, just scanning all five sport tables instead of switching
-- on one.
--
-- Returns the DB sport_id (1=soccer .. 5=pickleball, matching Sport.index —
-- see freeplay_user_skill's p_sport_id convention) of any one sport profile
-- with a seeded elo, or NULL if none. The client needs the sport id, not
-- just a boolean: marking onboarding done without also restoring
-- `selectedSportStateProvider` (which defaults to `Sport.others` on a fresh
-- install same as everything else) would leave the app's context sport
-- unset — every sport-scoped feed bails out empty on `Sport.others`, and
-- with onboarding now marked done there'd be no route back to the picker.
CREATE FUNCTION public.seeded_sport_id(p_user_id uuid) RETURNS bigint
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
  SELECT sport_id FROM (
    SELECT 1 AS sport_id FROM public.soccer_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 2 FROM public.basketball_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 3 FROM public.badminton_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 4 FROM public.tennis_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
    UNION ALL
    SELECT 5 FROM public.pickleball_profile WHERE user_id = p_user_id AND elo_seed IS NOT NULL
  ) seeded
  LIMIT 1;
$$;

ALTER FUNCTION public.seeded_sport_id(p_user_id uuid) OWNER TO postgres;

REVOKE EXECUTE ON FUNCTION public.seeded_sport_id(p_user_id uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.seeded_sport_id(p_user_id uuid) TO authenticated;
