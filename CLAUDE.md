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

## Coding Guidelines

- Database schema dumped in ./schema/
- Organize code by their screen
- If a feature involves multiple screens, make a folder in each screen
- Generic, omni-present features or models go into /core
- Avoid nesting, prefer a flat folder structure
- UI is built with forui package. Custom widgets are in /ui and prefix named with P. ALWAYS check this package before. Documentation starting point is at ./forui_llms.txt
  building UI to avoid reinventing the wheel
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
  about the client identity source of truth.)
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

All 4 subtabs share the same `FilterData` (city, districts, schedule timeslots, search term).

#### Teammate subtab

- Shows **lobbies** looking for more players, matched to the current user.
- Data comes from the `home_teammate_lobby_data` Postgres function (already exists).
  Params: `p_sport_id`, `p_timeslots` (user's schedule as jsonb dict), `p_city` (city cluster id),
  `p_districts` (array of district ids), `p_page_size`, `p_page_number`.
- Returns: `id, name, homeground_name, playtime, details, visibility, timeslot_compat_score, profile_compat_score`.
- `profile_compat_score` (0–5) is computed by `calculate_profile_compat_score` — shared networks,
  industries, skill level proximity etc.
- **Action**: "Xin vào" — creates a row in `lobby_befriend_record` with `interaction_type = 'request'`,
  `target_lobby_id = lobby.id`. On accepted, the trigger adds the user as a lobby member.
- Dart model: `LobbyFeedItem` — plain class (not freezed), manual `fromJson`. Fields:
  `id, name, homegroundName, playtime (List<Timeslot>), details (LobbyDetails?), visibility,
  timeslotCompatScore (int), profileCompatScore (double), memberCount (int?)`.

#### Challenger subtab

- Shows lobbies that are **open to being challenged** (team vs team).
- Requires `open_to_challengers boolean DEFAULT false NOT NULL` column on the `lobby` table.
  Migration: `schema/challenger_support.sql`.
- Data comes from `home_challenger_lobby_data` Postgres function (in same migration file).
  Params: `p_sport_id`, `p_city`, `p_districts`, `p_page_size`, `p_page_number` (no timeslot filter).
  Returns same shape as teammate feed plus `member_count`; excludes the user's own lobbies.
- **Challenge interaction uses a SEPARATE table** — do NOT use `lobby_befriend_record`, which is
  for user↔lobby and user↔user pairing only. A `lobby_challenge` table needs to be designed
  (initiator_lobby_id, target_lobby_id, status, proposed details etc.). Handshake flow is TBD.
- Until the challenge table is designed, the "Thách đấu" action button is a disabled placeholder.
- Dart model: reuses `LobbyFeedItem` (the `memberCount` field is populated here).

#### Professional (Neutral) subtab

- Shows coaches and referees offering services for the selected sport.
- Queried directly from `professional` table (no location filter — professionals are not
  geographically bound in the current schema). Filter: `sports` array contains the sport id.
- Order by `average_rating DESC`.
- Booking flow is TBD (either app currency "đá" or out-of-band + session scheduling only).
- Dart model: `ProfessionalFeedItem` — plain class, manual `fromJson`. Fields:
  `id, displayName, role (ProfessionalRole), bio, sports (List<int>), experienceYears,
  averageRating (double), reviewCount (int), isVerified (bool)`.
- `ProfessionalRole` enum (`coach`, `referee`) lives in `core/model/enum.dart`.

#### Location subtab

- Shows venues/courts from the `location` table, filtered by `city_cluster` and `district`.
- Informational only for now — no booking or map integration yet.
- If `FilterData.search` is non-empty, use `search_locations(search_term)` RPC.
  Otherwise query `location` directly with city_cluster + district filters.
- Dart model: reuses the existing `Location` freezed model in `core/model/location.dart`.

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
