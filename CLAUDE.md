# passe

Next gen casual sport portal

## Stack

DB: Postgres/ Supabase
Frontend: Flutter
Complex operations are done at SQL functions and called using Supabase

## Flow

User will choose a "context sport" (frontend variable). The app will help them
find teammates, parties ("lobby"), organize play, hire coaches/ referees etc

4 Main Tabs:

- Home: split into 4 subtabs. they share a filter
    - Teammates: find people/ lobbies to play with
    - Challengers: put up your lobby for challengers or look for them
    - Neutrals: hire coaches, referees, etc for your sport
    - Locations: find available venues according to criteria
- Manage:
    - the user's schedule as a calendar view (links to activities)
    - ongoing courses with a coach
    - their lobbies' activities: view, accept/ reject play invite, split bill, inspect history etc
- Health: integrate with user's wearables
    - capture data during activities
    - gamify and encourage further interactions (goals/ achievements etc)
- Profile:
    - general account bookkeeping
    - misc info/ preference on any particular sport: skill level, fitness level, play position
    - their consistent schedule for matchmaking
    - network and industry: allow user to choose from preset choices and improve matchmaking

Each tab folder ships its own `CLAUDE.md` with the file map, providers, and screen-specific
gotchas — read it before touching that screen:
[`lib/home_tab/CLAUDE.md`](lib/home_tab/CLAUDE.md),
[`lib/manage_tab/CLAUDE.md`](lib/manage_tab/CLAUDE.md),
[`lib/health_tab/CLAUDE.md`](lib/health_tab/CLAUDE.md),
[`lib/profile_tab/CLAUDE.md`](lib/profile_tab/CLAUDE.md).

## Glossary

Domain vocabulary — use these terms (not synonyms) in code, issues, and docs. This is the project's
primary glossary until a `CONTEXT.md` exists (see `docs/agents/domain.md`).

- **Context sport** (a.k.a. *selected sport*) — the single sport the whole app is scoped to at any
  moment, held in `selectedSportStateProvider` and changed via the appbar `SportSelector`. `Sport`
  enum: `others` (sentinel/“not chosen”), `soccer`, `basketball`, `badminton`, `tennis`, `pickleball`.
- **Lobby** — a party/group of players (the core social unit). Has a name, a sport, an optional
  *homeground*, a `visibility`, and members. Table: `lobby`.
- **Captain** — the lobby owner (`lobby.captain_id`). Captain-only actions: schedule activities,
  edit the lobby, manage members. A captain cannot leave their own lobby.
- **Member** — a user belonging to a lobby (`lobby_member` join table).
- **Homeground** — a lobby's default venue; `lobby.home_ground` FK → `location`.
- **Searchable id** — a short human-shareable lobby code (`lobby.searchable_id`, a `nanoid(8)`),
  distinct from the UUID `lobby.id`.
- **Befriend** — the join/pairing handshake (`lobby_befriend_record`). Three `interaction_type`s:
  *request* (user → lobby), *invite* (lobby → user), *pair* (user ↔ user, creates a new lobby).
- **Challenge / Challenger** — team-vs-team matchmaking (one lobby challenges another). Distinct from
  befriend; its own (still-to-be-built) `lobby_challenge` table. A lobby opts in via
  `open_to_challengers`.
- **Activity** — a scheduled play session (`activity`), linked to *either* a lobby *or* a
  professional booking. Members propose; the captain vetoes/edits; members confirm.
- **Match** — a recorded result of a played activity (`lobby_match`): result, sets, MVP, venue.
- **đá** ("rocks") — the app's internal currency, spent to confirm activities and to split bills.
  Not yet in the DB; currently a local int in `lib/currency/`.
- **Professional** / **Neutral** — a hireable coach or referee (`professional`, `professional_role`).
  The Home "Neutrals" subtab surfaces them; engagements are *bookings* (`professional_booking`).
- **Network** — a shared affiliation a user can claim (high school, gifted high school, university,
  company) used for matchmaking; *alumni* flag marks past membership. Tables: `network`,
  `user_network`.
- **Industry** — the user's professional industry (preset list) used for matchmaking. Tables:
  `industry`, `user_industry`.
- **Timeslot** — a `(dayOfWeek, dayChunk)` pair; *playtime* is a user's/lobby's list of timeslots
  used for schedule matching. `dayChunk` ∈ early/midday/noon/night.
- **City cluster** / **district** — geographic scoping. A *city cluster* (`supported_city_cluster`,
  mapped by `City.dbIndex`) groups *districts* (hard-coded in `core/model/enum.dart`).
- **Compat score** — matchmaking output on a lobby feed row: `timeslot_compat_score` (schedule
  overlap) and `profile_compat_score` (networks/industries/skill proximity, 0–5).
- **ELO / elo seed** — skill rating. `elo_seed` (beginner/casual/tryhard) is the self-declared
  starting point per sport profile; `user_rating` holds the live ELO per sport/format.
- **Guest** — an unauthenticated session (`PasseUser.isGuest`); read-only across most of the app.
- **Tag number** — the 4-digit discriminator appended to a username (`username#tag_number`);
  uniqueness is on the *pair*.

## Database Schema Overview

Postgres on Supabase. Full live dump: [`schema/passe.sql`](schema/passe.sql) (do not edit — re-dump).
Tables are `snake_case`, singular. Client identity is `auth.uid()`; RLS enforces per-user access.

**Identity & profile**
- `user` — id = `auth.uid()`; `username` + `tag_number`; `details` jsonb (gender, ageGroup, playtime,
  generatedAvatar, location{city,districts}) guarded by a json-schema CHECK. Editing that json shape
  needs a migration.
- `sport` — canonical sport list; ids mirror the `Sport` enum index.
- `industry` / `user_industry`, `network` / `user_network` — matchmaking affiliations (join tables).
  `industry.id` mirrors the 0-based `Industry` enum index. `network` has a Vietnamese FTS column.
- `<sport>_profile` (`soccer`, `basketball`, `badminton`, `tennis`, `pickleball`) — 1:1 with `user`
  (keyed `user_id`); store position/pitch or dominant_hand/discipline `text[]` + `elo_seed`.
- `user_rating` — live ELO per (user, sport, format).
- `supported_city_cluster`, `location` — geography; `location.city_cluster` FK → cluster id.

**Lobby & social**
- `lobby` — the party (captain_id, searchable_id, sport_id, playtime/details jsonb, home_ground FK,
  visibility).
- `lobby_member` — user↔lobby join.
- `lobby_befriend_record` — request/invite/pair handshake; CHECK constraints enforce the shape of
  each interaction type; triggers auto-accept reciprocals and add members on accept.
- `lobby_feed_item` (+ `lobby_feed_poll_vote`) — a lobby's action-stream; `payload` jsonb shape varies
  by `kind` (update/personal/system/poll/photo) per a CHECK. Canonical shapes:
  `lib/manage_tab/lobby_section/activity/feed.dart`.
- `activity` — a play session; CHECK forbids linking to both a lobby and a booking at once.
- `lobby_match` — recorded results; `sets` is a JSON array of `[us, them]`; challenge matches require
  a `referee_booking_id`.

**Professionals (coaches / referees)**
- `professional` — the hireable profile (role, `sports bigint[]`, `average_rating`, `review_count`,
  `is_verified`).
- `professional_service` — offered services (type, hourly_rate, duration, participants).
- `professional_booking` (+ `booking_additional_users`) — an engagement; status enum
  (`requested` → … never directly `completed`). `professional_booking_review` holds the rating that
  rolls up into `professional.average_rating`.

**Health & gamification**
- `user_health_link` — which platform (Apple Health / Health Connect) the user linked + sync times.
- `daily_health_summary` — per-day rollups for trends (resting HR, HRV, steps, sleep, weight…).
- `activity_health_metrics` — per-activity aggregates (HR zones, training load, effort, calories…).
- `activity_hr_sample` — raw per-second HR samples for curve reconstruction.
- `achievement` — XP-rewarding goals (sport-scoped, repeatable flag).

**Enums (Postgres types)**: `country`, `gender`, `health_platform`, `lobby_befriend_interaction`,
`lobby_befriend_status`, `lobby_feed_item_kind`, `lobby_match_result`, `lobby_visibility`,
`professional_booking_status`, `professional_role`. App-side enums mirror these by DB value (see the
enum-id rule in Coding Guidelines).

**Gotchas**: `numeric` columns (e.g. `average_rating`, `agreed_rate`) come back as `String` in Dart
JSON — parse with `double.tryParse`. Complex reads go through Postgres functions called via
`supabase.rpc(...)` (e.g. `home_teammate_lobby_data`, `lobby_feed_data`, `search_locations`).

## Coding Guidelines

- Database schema dumped in ./schema/
- Organize code by their screen
- If a feature involves multiple screens, make a folder in each screen
- Generic, omni-present features or models go into /core
- Avoid nesting, prefer a flat folder structure
- UI is built with forui package. Custom widgets are in /ui and prefix named with P. ALWAYS check this package before building UI to avoid reinventing the wheel. 
- Forui documentation starting point is at ./forui_llms.txt
- Do not use Material components already present in forui
- Bottom sheets MUST use `showPSheet` / `PSheet` from `lib/ui/sheet.dart` — never call `showFSheet` or hand-roll the
  `FSheets` + `Container` chrome directly. The wrapper enforces the project's standard silhouette (32-px radius, side
  borders only, keyboard-aware bottom padding). Pass `maxHeightRatio: 1.0` for info-style sheets that may grow to the
  full screen; the default `0.9` covers everything else. Sheet content should be just the inner widgets (e.g. a
  `SingleChildScrollView` + `Column`) — no outer `FSheets` or padded container
- Use Riverpod for state management. Avoid using Provider
- For the signed-in user's identity, read `currentUserIdProvider` (or `authControllerProvider` for the full
  `PasseUser`) — NEVER `Supabase.instance.client.auth.currentUser` directly. The raw getter bypasses the guest model
  and offline cache and won't rebuild dependents on auth change. `currentUserIdProvider` returns `null` for guests /
  signed-out, so `if (userId == null) return;` guards keep working. (Server-side RLS still uses `auth.uid()`; this is
  about the client identity source of truth.) The only sanctioned exceptions are `lib/auth/auth_controller.dart` and
  `lib/core/user_preferences.dart` (a synchronous singleton the auth layer itself depends on) — both carry an in-file
  comment explaining why they read the raw getter.
- Interactive auth flows (native Google/Apple sign-in) are the one exception to the 5s-timeout rule below — they're
  gated on the user, not a background RPC, so they must NOT be wrapped in `.timeout`.
- Every feed-like screen implements scroll to refresh. Scroll to refresh is recommended in general. Prefer to ask not to include instead of ignoring it
- App-level model is created with freezed. persisted in json form. app state persistence key is _stateKey (mostly for
  riverpod providers)
- If an entity has db id and its app model is enum, use the db value as the enum value
- Use JsonEnum whenever possible
- Use SharedPreferences to persist important app states
- Use Vietnamese for UI/ messages but do not translate jargon
- Every Supabase RPC call and async data-load function must have a `.timeout(const Duration(seconds: 5))` — no exceptions

- Whenever editing table user->details json schema, provide the migration script
- Use snake_case and singular form for table names and columns

## Build & Tooling

- **Code generation is load-bearing.** The project uses `riverpod_annotation`, `freezed`,
  `json_serializable`, and `go_router_builder`. Any file with a `part 'x.g.dart'` or
  `part 'x.freezed.dart'` directive (controllers annotated `@riverpod`, models annotated
  `@freezed`/`@JsonSerializable`, and `lib/router.dart`) is regenerated, not hand-edited. After
  editing any annotated file you MUST run:
  `dart run build_runner build --delete-conflicting-outputs`
  (use `watch` instead of `build` during active dev). Never edit `*.g.dart` / `*.freezed.dart` by hand.
- `flutter analyze` is the lint gate (`flutter_lints`). Suppress a single line with
  `// ignore: rule_name` only when genuinely warranted.
- Run the app with `flutter run`; tests with `flutter test`.
- **Environment**: config is loaded from `.env` via `flutter_dotenv` (`dotenv.load()` in `main`).
  `ENV` is one of `local | test | live`. `.env.example` documents the keys
  (`SUPABASE_URL`, `SUPABASE_PUBLIC_KEY`, `SENTRY_DSN`, `GOOGLE_IOS_CLIENT_ID`,
  `GOOGLE_WEB_CLIENT_ID`). Sentry no-ops on `local`; secrets live in `secrets/` (git-ignored).

## Architecture & Conventions

- **Navigation**: typed routes via `go_router` + `go_router_builder` in `lib/router.dart`. The four
  tabs live under a single `@TypedStatefulShellRoute<MainRoute>` (4 branches), rendered inside
  `ScaffoldWithNavBar` (the bottom nav). Tab widgets accept `.withInitialTab(i)` so a sub-route can
  deep-link to a specific subtab. To add a route: declare a `@TypedGoRoute<XRoute>` class, then run
  build_runner. Navigate with the generated `const XRoute().go(context)` / `.push(context)`. Pass
  heavy objects via the route's `$extra` field to skip a refetch (see `ProfessionalDetailRoute`,
  `LobbyDetailRoute`). `redirect` in `routerProvider` gates auth/guest/password-recovery flows.
- **Identity & auth**: `authControllerProvider` (`AsyncValue<PasseUser?>`) is the source of truth;
  read the id via `currentUserIdProvider`. `PasseUser.isGuest` distinguishes guests; the auth
  controller caches the user to SharedPreferences with a 24h offline TTL. See the identity rule in
  Coding Guidelines above.
- **Context sport**: the app-wide "selected sport" is `selectedSportStateProvider`
  (`AsyncValue<Sport>`, persisted to SharedPreferences). Almost every feed `.watch`es it and bails
  (returns `[]`) when it's null/`Sport.others`. The appbar `SportSelector` widget changes it.
- **State persistence**: wrap SharedPreferences through the `UserPreferences` singleton
  (`UserPreferences.instance`), never `SharedPreferences` directly. Persisted providers use a
  `static const _prefKey` / `_stateKey` convention.
- **Enum ⇆ DB id**: several enums encode their DB id positionally — `Sport.index` is sent as
  `p_sport_id` (`others=0, soccer=1, …`), `Industry.index` is the `industry_id`, and `City.dbIndex`
  is the city cluster id. Reordering these enums silently corrupts existing data — don't.
- **UI / theme**: forui (`FScaffold`, `FHeader`, `FTabs`, `FTile…`, `FButton`, `showFToast`). Theme
  is `pbThemeLight`; read colors/typography via `context.theme.colors` / `context.theme.typography`,
  brand accent is `pbBlue`. Custom `P`-prefixed widgets are re-exported from
  [`lib/ui/main.dart`](lib/ui/main.dart) (`PSheet`, `PSectionHeader`, `PEmptySectionPlaceholder`,
  `PillToggle`, `PSearchField`, …) — check there before building anything new.
- **Errors**: surface failures with `showFToast(... variant: .destructive ...)`; log via
  `Talker()` (`talker.handle(e, st)`), which also feeds Sentry off-`local`. Async data providers use
  `AsyncValue.guard` / `.when(loading/error/data:)`.
- **Mock-data fallback**: the home feeds (teammate, challenger, professional) and the Manage
  schedule read real data from the DB — loading shows a spinner, empty/error shows
  `PEmptySectionPlaceholder` (schedule surfaces errors via a toast). Synthetic integration data
  (`mocked_` lobbies/locations/pros, `mockeduser%` users) is seeded by `schema/mocked_seed.sql`.
  The Manage **coaching** section is the one remaining hard-coded prototype — it has no backing
  tables yet (`coaching_section/main.dart`).

## Internationalization

The app supports English and Vietnamese. Translations are stored in JSON files in the `assets/translations` directory

Make sure to keep the English industry names as keys exactly as they appear in the database and provide the Vietnamese
translations as values.

---

## Feature Design Notes

### Schema

- `schema/passe.sql` is a live dump of the current DB. Do not edit it — re-dump to update.
- Migration scripts (new tables/columns/functions) go in separate files under `schema/`.
- Supabase returns `numeric` columns as `String` in Dart JSON — parse carefully with `double.tryParse`.
- Playtime is stored in DB as a JSON array of `{dayOfWeek: "mon", dayChunk: "night"}` objects,
  matching `Timeslot.toJson()`. The `Timeslot.listFromJson/listToJson` static helpers are for the
  dict format `{"mon": ["night"]}` used by filter RPC functions.

### Home Tab

The home (discovery) screen's structure and the full per-subtab data contracts (RPC params, return
shapes, Dart models, actions) live in [`lib/home_tab/CLAUDE.md`](lib/home_tab/CLAUDE.md). The
cross-cutting systems those subtabs feed into — befriend, challenger, currency — are documented below.

### Lobby Befriend System (`lobby_befriend_record`)

Three interaction types:
- `request`: a user asks to join an existing lobby → on accept, trigger adds user as member.
- `invite`: a lobby captain invites a user → on accept, trigger adds user as member.
- `pair`: two individual users agree to play together → on accept, trigger creates a new lobby with
  both as members and the initiator as captain.

A before-insert trigger auto-accepts reciprocal request/invite pairs and enforces uniqueness.

### Challenger System (to be designed)

Separate from `lobby_befriend_record`. Needs a new `lobby_challenge` table with at minimum:
`id, initiator_lobby_id, target_lobby_id, sport_id, status (enum), proposed_time?, created_at, updated_at`.
The handshake (accept/decline/counter-propose) is TBD.

### Activity & Currency System

- Anyone in a lobby can propose a play session (activity). The lobby captain can veto or edit.
- Once enough members confirm, the activity becomes official.
- Confirming an activity costs "đá" (rocks) — the app's internal currency.
- "đá" also handles bill splitting after sessions.
- Currency system is not yet in the DB schema; needs to be designed.

### Notifications

- Push notifications (FCM/APNs) for important events: challenger confirmation, activity
  confirmation, pro session reminders.
- Use a **flag system**: each feature that wants push notifs opts in explicitly (not automatic).
  This allows incremental rollout as features are implemented.
- Infrastructure (FCM setup, device token storage) is not yet configured.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. Domain language currently lives in `CLAUDE.md`; `CONTEXT.md` + `docs/adr/` are where it moves when separated. See `docs/agents/domain.md`.
