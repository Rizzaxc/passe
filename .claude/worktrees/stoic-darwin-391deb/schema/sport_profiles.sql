-- Sport-specific profile tables.
-- Each sport gets its own table so fields are typed, indexed, and can FK to user_rating.
-- New sports get a new table when their fields are defined.

-- ─── Soccer ──────────────────────────────────────────────────────────────────

create table if not exists soccer_profile (
  user_id    uuid primary key references auth.users on delete cascade,
  position   text[] not null default '{}',   -- SoccerPosition values: 'outfield', 'keeper'
  pitch      text[] not null default '{}',   -- SoccerPitch values:    'futsal', '5v5', '7v7'
  elo_seed   text,                           -- EloSeed: 'beginner', 'casual', 'tryhard'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists soccer_profile_position_idx on soccer_profile using gin(position);
create index if not exists soccer_profile_pitch_idx    on soccer_profile using gin(pitch);

-- ─── Basketball ──────────────────────────────────────────────────────────────

create table if not exists basketball_profile (
  user_id    uuid primary key references auth.users on delete cascade,
  position   text[] not null default '{}',   -- BasketballPosition: 'guard', 'forward', 'center'
  pitch      text[] not null default '{}',   -- BasketballPitch:     'indoor', 'outdoor'
  elo_seed   text,                           -- EloSeed: 'beginner', 'casual', 'tryhard'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists basketball_profile_position_idx on basketball_profile using gin(position);
create index if not exists basketball_profile_pitch_idx    on basketball_profile using gin(pitch);

alter table basketball_profile enable row level security;

create policy "basketball profiles are publicly readable"
  on basketball_profile for select using (true);

create policy "users manage own basketball profile"
  on basketball_profile for all using (auth.uid() = user_id);

-- ─── Badminton ───────────────────────────────────────────────────────────────

create table if not exists badminton_profile (
  user_id       uuid primary key references auth.users on delete cascade,
  dominant_hand text,                         -- DominantHand: 'left', 'right'
  discipline    text[] not null default '{}', -- RacketDiscipline: 'singles', 'doubles'
  elo_seed      text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table badminton_profile enable row level security;
create policy "badminton profiles are publicly readable"
  on badminton_profile for select using (true);
create policy "users manage own badminton profile"
  on badminton_profile for all using (auth.uid() = user_id);

-- ─── Tennis ──────────────────────────────────────────────────────────────────

create table if not exists tennis_profile (
  user_id       uuid primary key references auth.users on delete cascade,
  dominant_hand text,
  discipline    text[] not null default '{}',
  elo_seed      text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table tennis_profile enable row level security;
create policy "tennis profiles are publicly readable"
  on tennis_profile for select using (true);
create policy "users manage own tennis profile"
  on tennis_profile for all using (auth.uid() = user_id);

-- ─── Pickleball ──────────────────────────────────────────────────────────────

create table if not exists pickleball_profile (
  user_id       uuid primary key references auth.users on delete cascade,
  dominant_hand text,
  discipline    text[] not null default '{}',
  elo_seed      text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table pickleball_profile enable row level security;
create policy "pickleball profiles are publicly readable"
  on pickleball_profile for select using (true);
create policy "users manage own pickleball profile"
  on pickleball_profile for all using (auth.uid() = user_id);

-- ─── Elo / User ratings (sport-agnostic) ─────────────────────────────────────
-- Populated by match result functions, not user input.

create table if not exists user_rating (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users on delete cascade,
  sport        text not null,      -- matches Sport enum json value
  format       text,               -- 'singles' | 'doubles' | null (team/default)
  elo          int  not null,
  games_played int  not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (user_id, sport, format)
);

create index if not exists user_rating_user_sport_idx on user_rating (user_id, sport);

-- ─── RLS ─────────────────────────────────────────────────────────────────────

alter table soccer_profile enable row level security;
alter table user_rating     enable row level security;

-- Users can read any sport profile (needed for matchmaking display)
create policy "sport profiles are publicly readable"
  on soccer_profile for select using (true);

-- Users can only write their own sport profile
create policy "users manage own soccer profile"
  on soccer_profile for all using (auth.uid() = user_id);

-- Elo is read-only for users; written by server functions only
create policy "user ratings are publicly readable"
  on user_rating for select using (true);
