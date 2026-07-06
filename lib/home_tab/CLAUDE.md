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
  **Design rule: the teammate and challenger cards must stay visually identical** — same name,
  member-count badge, homeground, playtime/vibe chips, FitScore. The *only* permitted differences
  are (a) the **MMR block** (`lobbyMmr` + favorability, challenger-only) and (b) the **CTA** passed
  via `action`. Keep both feeds returning the same columns (incl. `member_count`) so the card
  renders consistently. Teammate CTA: "Xin vào" → once requested, shows a "Đã gửi" indicator + an
  **undo** button (`RequestedLobbyIds.unrequest`). Challenger CTA: "Thách đấu" (disabled placeholder).
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
| Professional | `home_professional_data` RPC (sport + soft city/district/schedule + role toggle; ranked verified/rating/reviews; `price_from` from `professional_service`) | `ProfessionalFeedItem` | tap → `ProfessionalDetailRoute`; book = "coming soon" toast |
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
- Returns: `id, name, homeground_name, playtime, details, visibility, member_count,
  timeslot_compat_score, profile_compat_score, match_factors, already_requested` (`match_factors` is a `text[]` of the
  real contributing factor codes — `network/industry/skill/age/gender/playtime/location` — that the
  card's FitScore "vibe" chips render directly instead of guessing from the score). `member_count`
  was added so teammate cards show the same top-right member badge as challenger.
- `profile_compat_score` is computed by `calculate_profile_compat_score` and lives in the band
  **[2.5, 5]**: 2.5 is the neutral "ok fit" floor (no shared signal — *not* a poor match), 5 is a
  fully-aligned match. Signals: shared/active networks, shared industry (fallback), skill-level
  proximity, **age-group match**, and a **gender-comfort** bump (a female user matched with a female
  target / a lobby that has ≥1 female member). Latest redesign: `schema/fitscore_redesign.sql`.
- **Action**: "Xin vào" → inserts a `lobby_befriend_record` with `interaction_type = 'request'`,
  `target_lobby_id = lobby.id`. On accept, a trigger adds the user as a lobby member.
- **Request state** (`schema/teammate_request_state.sql`): the feed **hides lobbies the user was
  `declined` from**, and returns `already_requested` (a `pending` request exists), which is the
  **baseline** for the "sent" CTA so it persists across restarts with no client seeding. The
  `JoinRequestState` notifier (`Map<String,bool>`, `keepAlive`) holds per-lobby *session overrides*
  that take precedence over the baseline (`true`=just requested, `false`=just undone) — the button
  reads `override[id] ?? item.alreadyRequested`. Once requested the CTA shows "Đã gửi" + an **Undo**
  button; undo flips the record to `status='cancelled'` (no DELETE policy exists — the initiator
  UPDATEs it; the insert trigger's dup-check ignores `cancelled`, so the lobby becomes joinable
  again). `accepted` requests drop out via membership (`get_my_lobby_ids()`).
- Model: `LobbyFeedItem` — `id, name, homegroundName, playtime (List<Timeslot>),
  details (LobbyDetails?), visibility, timeslotCompatScore (int), profileCompatScore (double),
  matchFactors (List<String>), alreadyRequested (bool), memberCount (int?)`.

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

- Shows coaches and referees offering services for the selected sport, in two horizontal carousels
  (one per role). The subtab keeps the shared `FilterWidget` icon (top-right); opened here it shows
  an extra **role toggle** (`FilterWidget(showRoleFilter: true)` → a deselectable `PSegmentedButton`
  inside the filter sheet, bound to `FilterData.role`). Deselected = both roles (default); selecting
  Coach/Referee hides the other section. `role` is applied client-side, and the feed `.select`s the
  query-affecting filter fields *excluding* `role` so toggling it doesn't refetch.
- Data: `home_professional_data` RPC (`schema/professional_location_filter.sql`). Params mirror
  teammate — `p_sport_id`, `p_timeslots` (`Timeslot.listToJson`), `p_city` (`City.dbIndex`),
  `p_districts` (district ids), `p_page_size/number`. Returns the `professional` columns +
  `professional_role` + `price_from` (cheapest active `professional_service.hourly_rate` for the
  sport, numeric → `double.tryParse`, shown "từ {rate}₫/giờ") + `timeslot_compat_score`. Ranked
  `is_verified DESC, average_rating DESC, review_count DESC`. (RLS exposes services only for
  *verified* pros, so unverified pros list without a price.)
- **Geo/schedule filter IS wired** (and soft). `professional` gained `preferred_city_cluster`
  (FK → `supported_city_cluster`) + `preferred_districts text[]`; `schedule jsonb` holds the same
  array shape as lobby playtime. The RPC treats all three as **soft**: a pro with *no* stated
  preference always shows; one *with* a preference must match (city equality, district `&&` overlap,
  schedule `calculate_timeslot_compat_score ≥ 4`). The feed `.select`s `(city, districts, schedule)`
  to refetch on those, and excludes `role` (applied client-side) and `search` (pros aren't
  text-searched).
- Tap a card (or a "see all" sheet row) → `ProfessionalDetailRoute` (`/professional/:id`) via
  `.push`, passing the `ProfessionalFeedItem` as `$extra` to skip a refetch. The "Xem hồ sơ" CTA does
  the same. A visible "Xem tất cả" header action opens the full-list sheet (no longer reliant on the
  hidden overscroll-drag, which remains as a bonus).
- **Booking is real** (`professional_booking` / `professional_service`, `lib/professional/booking_sheet.dart` +
  `booking_controller.dart`): "Đặt lịch" opens a sheet to pick an active service + date/time + optional
  note, then inserts a `professional_booking` row (`status` defaults `requested`; the professional
  accepts/rejects out of band — no in-app professional-side flow yet). Payment is out-of-band
  (`agreed_rate` is informational, not an đá charge). See Manage ▸ Coaching for where a client's
  bookings surface afterward. **Messaging has no backing flow** (no message/conversation table at
  all) — "Nhắn tin" still shows a "sẽ sớm có mặt" toast.
- States: loading = skeleton list; empty = `PEmptySectionPlaceholder`; error = `showFToast`
  (destructive) + empty sections (matches the schedule feed). Avatars are initials-on-`primary`;
  real photos should follow the `user_avatar` Storage convention once a pro photo bucket exists.
- Model: `ProfessionalFeedItem` — `id, displayName, role (ProfessionalRole), bio, sports
  (List<int>), experienceYears, averageRating (double), reviewCount (int), isVerified (bool),
  priceFrom (double?)`. `ProfessionalRole` (`coach`/`referee`) lives in `core/model/enum.dart`.

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
