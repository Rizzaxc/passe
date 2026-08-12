-- Expand elo_seed from 3 tiers (beginner/casual/tryhard) to 5 tiers
-- (beginner/casual/fair/good/advanced), each 200 Elo apart.
--
--   beginner  700
--   casual    900
--   fair     1100
--   good     1300
--   advanced 1500
--
-- 'tryhard' is retired; existing rows carrying it are remapped to 'advanced'
-- (its closest surviving tier and the same relative rank it held before).

-- 1. Migrate existing data off the retired 'tryhard' value.
UPDATE public.soccer_profile     SET elo_seed = 'advanced' WHERE elo_seed = 'tryhard';
UPDATE public.basketball_profile SET elo_seed = 'advanced' WHERE elo_seed = 'tryhard';
UPDATE public.badminton_profile  SET elo_seed = 'advanced' WHERE elo_seed = 'tryhard';
UPDATE public.tennis_profile     SET elo_seed = 'advanced' WHERE elo_seed = 'tryhard';
UPDATE public.pickleball_profile SET elo_seed = 'advanced' WHERE elo_seed = 'tryhard';

UPDATE public.freeplay_request
  SET skill = 'advanced'
  WHERE skill = 'tryhard';

UPDATE public.freeplay_activity
  SET recommended_skills = array_replace(recommended_skills, 'tryhard', 'advanced')
  WHERE 'tryhard' = ANY (recommended_skills);

-- 2. Widen the freeplay CHECK constraints to the 5-tier vocabulary.
ALTER TABLE public.freeplay_activity
  DROP CONSTRAINT freeplay_activity_recommended_skills_check;
ALTER TABLE public.freeplay_activity
  ADD CONSTRAINT freeplay_activity_recommended_skills_check CHECK (
    cardinality(recommended_skills) > 0
    AND recommended_skills <@ ARRAY['beginner','casual','fair','good','advanced']::text[]
  );

ALTER TABLE public.freeplay_request
  DROP CONSTRAINT freeplay_request_skill_check;
ALTER TABLE public.freeplay_request
  ADD CONSTRAINT freeplay_request_skill_check CHECK (
    skill IS NULL OR skill = ANY (ARRAY['beginner','casual','fair','good','advanced']::text[])
  );

-- 3. Redefine the seed → starting-Elo mapping for 5 tiers, +200 per tier.
CREATE OR REPLACE FUNCTION public.fn_seed_initial_elo() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
  v_sport     text;
  v_elo       int;
begin
  -- Only act on first-time elo_seed set (null → value)
  if NEW.elo_seed is null then
    return NEW;
  end if;
  if OLD is not null and OLD.elo_seed is not null then
    return NEW;  -- already seeded, don't touch Elo
  end if;

  -- Derive sport from table name: 'soccer_profile' → 'soccer'
  v_sport := replace(TG_TABLE_NAME, '_profile', '');

  -- Map seed to starting Elo (200 apart per tier)
  v_elo := case NEW.elo_seed
    when 'beginner' then  700
    when 'casual'   then  900
    when 'fair'     then 1100
    when 'good'     then 1300
    when 'advanced' then 1500
    else                 900
  end;

  -- Insert only if no rating exists yet for this user+sport
  if not exists (
    select 1 from public.user_rating
    where user_id = NEW.user_id
      and sport   = v_sport
  ) then
    insert into public.user_rating (user_id, sport, elo, games_played)
    values (NEW.user_id, v_sport, v_elo, 0);
  end if;

  return NEW;
end;
$$;
