-- Trigger: seed initial Elo into user_rating when elo_seed is first committed
-- on any sport profile table.
--
-- Rules:
--   1. Only fires when elo_seed transitions from NULL → non-null (first commit).
--   2. Does nothing if a user_rating row already exists for that sport
--      (protects real Elo earned from matches).
--   3. Sport name is derived from the table name by stripping '_profile'.

create or replace function public.fn_seed_initial_elo()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
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

  -- Map seed to starting Elo
  v_elo := case NEW.elo_seed
    when 'beginner' then  700
    when 'casual'   then 1000
    when 'tryhard'  then 1300
    else                 1000
  end;

  -- Insert only if no rating exists yet for this user+sport (format null = default/team)
  if not exists (
    select 1 from public.user_rating
    where user_id = NEW.user_id
      and sport   = v_sport
      and format is null
  ) then
    insert into public.user_rating (user_id, sport, elo, games_played)
    values (NEW.user_id, v_sport, v_elo, 0);
  end if;

  return NEW;
end;
$$;

-- Attach to every sport profile table

create trigger soccer_elo_seed
  after insert or update of elo_seed on public.soccer_profile
  for each row execute function public.fn_seed_initial_elo();

create trigger basketball_elo_seed
  after insert or update of elo_seed on public.basketball_profile
  for each row execute function public.fn_seed_initial_elo();

create trigger badminton_elo_seed
  after insert or update of elo_seed on public.badminton_profile
  for each row execute function public.fn_seed_initial_elo();

create trigger tennis_elo_seed
  after insert or update of elo_seed on public.tennis_profile
  for each row execute function public.fn_seed_initial_elo();

create trigger pickleball_elo_seed
  after insert or update of elo_seed on public.pickleball_profile
  for each row execute function public.fn_seed_initial_elo();
