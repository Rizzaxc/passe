# Home Tab — discovery

Read the root [`CLAUDE.md`](../../CLAUDE.md) first for project-wide conventions (build_runner,
navigation, the `selectedSportStateProvider` context sport, forui/theme, identity rules). This file
covers what's specific to the home screen.

## Purpose

The discovery surface. Four subtabs, all driven by the same `selectedSportStateProvider` (context
sport) and the same shared `FilterData`. Each feed returns `[]` when no sport is selected.

## Layout

- `main.dart` — `HomeTab`: `FScaffold` + `FTabs` hosting the 4 subtabs. Appbar suffixes are shared
  app-wide (`DaAppbarButton`, `NotificationIconButton`, `SportSelector`). `HomeTab.withInitialTab(i)`
  deep-links a subtab (`0` teammate, `1` challenger, `2` professional, `3` location — see the
  `Home*Route` classes in `router.dart`).
- `filter.dart` / `filter_controller.dart` — the **shared filter** across all four subtabs.
- `lobby_feed_card.dart` — `LobbyFeedCard`, the shared card for the lobby-shaped subtabs.
- `teammate_section/`, `challenger_section/`, `professional_section/`, `location_section/` — one
  `main.dart` (UI) + `feed_controller.dart` (`@riverpod` data) each.

## Shared filter

`filterStateProvider` (`FilterState` → `FilterData`: `search`, `city`, `districts` ≤3,
`schedule` ≤3 `Timeslot`s) is the single filter for all subtabs. It's **seeded from the signed-in
user's `details.location` and `details.playtime`** on build, defaulting to `City.hochiminh`.
Changing the city clears districts. Feeds `ref.watch(filterStateProvider)` so they refetch on any
filter change. `FilterState.onCommit()` (persisting the filter server-side) is a TODO.

## Subtab data sources

Quick map, then the full contract for each:

| Subtab | Source | Model | Action |
|---|---|---|---|
| Teammate | `home_teammate_lobby_data` RPC | `LobbyFeedItem` | "Xin vào" → insert `lobby_befriend_record` (`request`) |
| Challenger | `home_challenger_lobby_data` RPC | `LobbyFeedItem` (`memberCount` set) | "Thách đấu" — **disabled placeholder** (no `lobby_challenge` table yet) |
| Professional | `professional` table (no geo filter, `average_rating DESC`) | `ProfessionalFeedItem` | tap → `ProfessionalDetailRoute` |
| Location | `location` table, or `search_locations` RPC when `search` is set | `Location` (freezed) | informational only |

Conventions across all four: `p_sport_id` is `Sport.index`; `p_city` is `City.dbIndex`; districts
are `district.id` strings; every RPC/query carries `.timeout(const Duration(seconds: 5))`.
`LobbyFeedItem` and `ProfessionalFeedItem` are **plain classes with manual `fromJson`** (not
freezed) — edit them by hand, no build_runner.

### Teammate subtab

- Shows **lobbies** looking for more players, matched to the current user.
- Data: `home_teammate_lobby_data` Postgres function (already exists).
  Params: `p_sport_id`, `p_timeslots` (user's schedule as jsonb dict — `Timeslot.listToJson`),
  `p_city` (city cluster id), `p_districts` (array of district ids), `p_page_size`, `p_page_number`.
- Returns: `id, name, homeground_name, playtime, details, visibility, timeslot_compat_score,
  profile_compat_score`.
- `profile_compat_score` (0–5) is computed by `calculate_profile_compat_score` — shared networks,
  industries, skill-level proximity etc.
- **Action**: "Xin vào" → inserts a `lobby_befriend_record` with `interaction_type = 'request'`,
  `target_lobby_id = lobby.id`. On accept, a trigger adds the user as a lobby member. Optimistic
  state lives in `RequestedLobbyIdsProvider` (a `Set<String>`), rolled back on failure.
- Model: `LobbyFeedItem` — `id, name, homegroundName, playtime (List<Timeslot>),
  details (LobbyDetails?), visibility, timeslotCompatScore (int), profileCompatScore (double),
  memberCount (int?)`.

### Challenger subtab

- Shows lobbies **open to being challenged** (team vs team).
- Requires `open_to_challengers boolean DEFAULT false NOT NULL` on the `lobby` table.
  Migration: `schema/challenger_support.sql`.
- Data: `home_challenger_lobby_data` function (same migration file).
  Params: `p_sport_id`, `p_city`, `p_districts`, `p_page_size`, `p_page_number` (no timeslot filter).
  Same return shape as teammate plus `member_count`; excludes the user's own lobbies.
- **Challenge interaction uses a SEPARATE table** — do NOT reuse `lobby_befriend_record` (that is
  user↔lobby / user↔user pairing only). A `lobby_challenge` table is still to be designed; until
  then the "Thách đấu" button is a disabled placeholder. See root CLAUDE.md "Challenger System".
- Model: reuses `LobbyFeedItem` (with `memberCount` populated).

### Professional (Neutral) subtab

- Shows coaches and referees offering services for the selected sport.
- Queried directly from the `professional` table — **no location filter** (professionals aren't
  geographically bound in the current schema). Filter: `sports` array contains the sport id.
  Order by `average_rating DESC`.
- Booking flow is TBD (either app currency "đá" or out-of-band + session scheduling).
- Tap a card → `ProfessionalDetailRoute` (`/professional/:id`); pass the `ProfessionalFeedItem` as
  `$extra` to skip a refetch.
- Model: `ProfessionalFeedItem` — `id, displayName, role (ProfessionalRole), bio, sports
  (List<int>), experienceYears, averageRating (double), reviewCount (int), isVerified (bool)`.
  `ProfessionalRole` (`coach`/`referee`) lives in `core/model/enum.dart`.

### Location subtab

- Shows venues/courts from the `location` table, filtered by `city_cluster` and `district`.
- Informational only for now — no booking or map integration yet.
- If `FilterData.search` is non-empty, use the `search_locations(search_term)` RPC; otherwise query
  `location` directly with city_cluster + district filters.
- **Known gap (deferred):** the direct query currently filters by `city_cluster` only —
  `filter.districts` is not yet applied. See `TODO(location-district-filter)` in
  `location_section/feed_controller.dart`.
- Model: reuses the `Location` freezed model in `core/model/location.dart`.

## Gotchas

- **No mock fallback**: teammate, challenger and professional subtabs read real DB data — loading
  shows a spinner, empty/error shows `PEmptySectionPlaceholder`. (Synthetic `mocked_` content is
  seeded in the DB via `schema/mocked_seed.sql`, not hard-coded in the widgets.)
- The "request to join" optimistic state lives in `RequestedLobbyIdsProvider` (a `Set<String>`),
  which rolls back on failure — it is **not** refetched from the server.
- Every feed implements scroll-to-refresh via `RefreshIndicator` + `ref.invalidate(feedProvider)`
  then `await ref.read(feedProvider.future)`. Keep this on any new feed.
- All feed RPCs/queries carry the mandatory `.timeout(const Duration(seconds: 5))`.
- Challenger interactions must NOT reuse `lobby_befriend_record` (that table is user↔lobby /
  user↔user only) — the challenge handshake needs its own `lobby_challenge` table, still unbuilt.
