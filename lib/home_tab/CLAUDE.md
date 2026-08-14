# Home Tab — Discover

Read the root [`CLAUDE.md`](../../CLAUDE.md) first for project-wide conventions (build_runner,
navigation, the `selectedSportStateProvider` context sport, forui/theme, identity rules). This file
covers what's specific to the home screen.

## Purpose

Home is the **Discover** surface: five implemented subtabs sharing one filter, all scoped to the
context sport (`selectedSportStateProvider`). Challenger is client-gated off by default, so normal
builds show four. Each feed returns `[]` when no sport is selected.

The social surface (**Feed**) is a separate, first-positioned main tab — see
[`lib/feed_tab/CLAUDE.md`](../feed_tab/CLAUDE.md). It used to live here behind a header pill toggle;
it moved out to its own tab (a TikTok-style vertical feed doesn't compose well as a sub-segment of
another screen), so `HomeTab` is back to being single-purpose.

## Layout

- `main.dart` — `HomeTab`: `FScaffold` + `_DiscoverView` (four tabs by default).
  - Default indices are `0` freeplay, `1` teammate, `2` professional, `3` location. When Challenger
    is explicitly enabled it is inserted at `2`, shifting professional/location to `3`/`4`.
    `HomeTab`'s named index getters keep the `Home*Route` classes independent of that shift.
- Appbar suffixes: `NotificationIconButton`, `SportSelector`. (`DaAppbarButton` — the đá-balance
  pill — is hidden app-wide; the currency system is deferred/unbuilt, see root CLAUDE.md ▸ Activity
  & Currency System. The widget still exists in `lib/currency/` for when that ships.)
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

`filterStateProvider` (`FilterState` → `FilterData`: `search`, `city`, `districts` ≤6,
`schedule` ≤3 `Timeslot`s) is the single filter for all subtabs. It's **seeded from the signed-in
user's `details.location` and `details.playtime`** on build, defaulting to `City.hochiminh`.
Changing the city clears districts. Feeds `ref.watch(filterStateProvider)` so they refetch on any
filter change. `FilterState.onCommit()` (persisting the filter server-side) is a TODO.

**`search` (`p_search`) is wired into all four RPCs** (`schema/home_feed_search.sql`, applied to
prod): teammate/challenger match `lobby.name` OR
`lobby.searchable_id`; professional matches `professional.display_name`; location matches
name/address via the existing `search_locations` fuzzy match. All four are diacritic-insensitive
(`extensions.unaccent`). **Location is the one exception to "search narrows the result set"**: its
district filter is OR'd with the search term (broadens results), not AND'd — see the Location
subtab section below for why.

## Subtab data sources

Quick map, then the full contract for each:

| Subtab | Source | Model | Action |
|---|---|---|---|
| Teammate | `home_teammate_lobby_data` RPC | `LobbyFeedItem` | "Xin vào" → insert `lobby_befriend_record` (`request`) |
| Challenger | `home_challenger_lobby_data` RPC | `LobbyFeedItem` (`memberCount` + offer terms set) | "Thách đấu" → confirm-terms sheet → `send_challenge` RPC from the "challenging as" context lobby (see root CLAUDE.md ▸ Challenger System) |
| Professional | `home_professional_data` RPC (sport + soft city/district/schedule + role toggle; ranked verified/rating/reviews; `price_from` from `professional_service`) | `ProfessionalFeedItem` | tap → `ProfessionalDetailRoute`; book = "coming soon" toast |
| Location | `location` table, or `search_locations` RPC when `search` is set | `Location` (freezed) | list/map toggle; tap → detail sheet; "Chỉ đường" launches external maps |

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

- **Disabled by default in the client.** `ClientFeatureFlags.challengerFlow` gates the Discover
  subtab and the related lobby/activity/pro/notification continuation UI. Enable an explicit test
  build with `--dart-define=ENABLE_CHALLENGER_FLOW=true`; do not put it in a default ship command.
- Shows lobbies that have **published a challenge offer** (team vs team, with stated terms — see
  root CLAUDE.md ▸ Challenger System for the full flow).
- Requires `open_to_challengers boolean DEFAULT false NOT NULL` **plus** `challenge_offer_time` /
  `_location` / `_cost` on the `lobby` table, enforced together by a CHECK. Migration:
  `schema/challenger_support.sql` (the flag + MMR cache) +
  `schema/challenge_flow.sql` (the offer columns).
- Data: `home_challenger_lobby_data` function (`schema/challenge_flow.sql`).
  Params: `p_sport_id`, `p_city`, `p_districts`, `p_search`, `p_page_size`, `p_page_number` (no
  timeslot filter). Same return shape as teammate plus `member_count`, `offer_time`,
  `offer_location_name`, `offer_cost`, `rated_match_count`; excludes the user's own lobbies and
  offers whose kickoff has already passed.
- **Challenge interaction uses a SEPARATE table** — do NOT reuse `lobby_befriend_record` (that is
  user↔lobby / user↔user pairing only). The "Thách đấu" CTA opens a confirm-these-terms sheet (the
  home lobby already set time/venue/cost — the challenger accepts, doesn't propose) and calls
  `send_challenge` from the user's effective "challenging as" context lobby
  (`_ChallengeButton` / `_ConfirmChallengeSheet` in `challenger_section/main.dart`, backed by
  `send_challenge_controller.dart`). See root CLAUDE.md "Challenger System" for everything past send
  — accept, activity materialisation, referee, result, Elo.
- Model: reuses `LobbyFeedItem` (with `memberCount`, `offerTime`/`offerLocationName`/`offerCost`,
  and `ratedMatchCount` populated — `hasProvisionalMmr` qualifies the MMR display below
  `LobbyFeedItem.provisionalMatchThreshold` rated matches).

### Professional (Neutral) subtab

- Shows coaches and referees offering services for the selected sport, in two horizontal carousels
  (one per role), each with its own header (`_Section` in `professional_section/main.dart`) styled
  like the teammate/challenger/location subtabs' single `PSectionHeader` — title + chevron as one
  tappable unit (opens the "see all" sheet), with the shared `FilterWidget(showRoleFilter: true)`
  icon as the row's suffix. There's no single umbrella title here the way siblings have one: each
  role header *is* this screen's equivalent of that title, so the filter icon rides as the suffix on
  every currently-visible role section (not just one), so it stays reachable no matter which roles
  are checked.
- **Role visibility** is `FilterData.visibleRoles` (`Set<ProfessionalRole>`, both checked by
  default) — two independent `FCheckbox`es inside the filter sheet, one per role
  (`FilterState.setRoleVisible` refuses to uncheck the last remaining role). Unchecking a role hides
  its carousel entirely. This is applied client-side, and the feed `.select`s the query-affecting
  filter fields *excluding* `visibleRoles` so toggling it doesn't refetch.
- Data: `home_professional_data` RPC (`schema/professional_location_filter.sql`). Params mirror
  teammate — `p_sport_id`, `p_timeslots` (`Timeslot.listToJson`), `p_city` (`City.dbIndex`),
  `p_districts` (district ids), `p_page_size/number`. Returns the `professional` columns +
  `professional_role` + `price_from` / `price_from_kind` (cheapest active
  `professional_service.price_amount` for the sport, labelled hourly or per-session) +
  `timeslot_compat_score`. Ranked
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
  note, then inserts a `professional_booking` row (`status` defaults `requested`). **The professional
  does accept/reject in-app** — `lib/professional/pro_mode/` is a real mode switch
  (`core/state/pro_mode_state.dart`) that replaces the Manage tab with the pro's own schedule
  (`pro_schedule_main.dart`), pending requests (`pending_requests_main.dart`, `accept_professional_booking`
  / `reject_professional_booking`), and booking history. Payment is out-of-band (`agreed_rate` is
  informational, not an đá charge). See Manage ▸ Coaching for where a client's bookings surface
  afterward. A referee's confirmed booking that's attached to a lobby-vs-lobby challenge activity
  additionally offers "Ghi Kết Quả" once the match ends (`record_result_sheet.dart`) — see root
  CLAUDE.md ▸ Challenger System. **Messaging has no backing flow** (no message/conversation table at
  all) — "Nhắn tin" still shows a "sẽ sớm có mặt" toast.
- States: loading = skeleton list; empty = `PEmptySectionPlaceholder`; error = `showFToast`
  (destructive) + empty sections (matches the schedule feed). Avatars are initials-on-`primary`;
  real photos should follow the `user_avatar` Storage convention once a pro photo bucket exists.
- Model: `ProfessionalFeedItem` — `id, displayName, role (ProfessionalRole), bio, sports
  (List<int>), experienceYears, averageRating (double), reviewCount (int), isVerified (bool),
  priceFrom (double?)`. `ProfessionalRole` (`coach`/`referee`) lives in `core/model/enum.dart`.

### Location subtab

- Shows venues/courts from the `location` table, filtered by `city_cluster`, `district`, and the
  context sport (see below).
- **List/Map toggle** (`PPillToggle`, local `_VenueView` state — not persisted) in the header
  suffix next to the filter icon. List = interactive `FCard`s; Map = embedded `flutter_map`
  (OpenStreetMap tiles, no API key). Tapping a card **or** a map marker opens the venue detail sheet
  (`showPSheet`, `maxHeightRatio: 1.0`) with a static mini-map, address, sport/amenity chips, and a
  directions CTA.
- **Directions** use the shared `core/map_directions.dart` handoff. iOS presents a Passe sheet with
  Google Maps first and Apple Maps second (Google falls back to its directions website when the app
  is missing); Android uses the native `geo:` chooser with the same web fallback. Disabled when the
  venue has neither coordinates nor usable address/name text; otherwise an unmapped venue routes by
  its URL-encoded address or name. Google Maps SDK was deliberately *not* used (poor VN coverage + cost).
- **OSM tile usage policy compliance**: identifying `User-Agent` (`_tileUserAgent`) and visible
  attribution (`_OsmAttribution`) are set in `main.dart` of this folder; the 7-day-minimum tile
  cache the policy requires is flutter_map's built-in `NetworkTileProvider` disk cache (on by
  default, no extra package needed — BSD-3-Clause, not `flutter_map_tile_caching`/FMTC which is
  GPL-3.0), with its freshness floor forced to 7 days via `BuiltInMapCachingProvider
  .getOrCreateInstance(overrideFreshAge: ...)` in `lib/main.dart` (must run before any `TileLayer`
  builds). This does **not** cover aggregate-traffic risk as the user base grows — OSM enforces
  against the app as an identifiable operator (by `User-Agent`), not per-device, so a real
  user-growth push should trigger migrating off `tile.openstreetmap.org` to a self-hosted or
  commercial OSM-derived tile provider rather than relying on caching alone.
- **Coordinates & tags**: the `Location` freezed model carries `lat`, `lon`, `tags`, `cityCluster`,
  plus `coord` (→ `LatLng?`) and `displayAddress` helpers.
- **Sport-scoped** (`Location.matchesSport`/`.sports`/`hasDeclaredSport` in `core/model/location.dart`):
  the feed watches `selectedSportStateProvider` and drops venues whose OSM `sport:[...]` tag names
  sports Passe doesn't support (billiards, shooting, …) but *keeps* untagged venues (ambiguous —
  could still be a general facility). `Sport.others` (nothing chosen) skips the filter. Filtering is
  client-side, after fetch — the raw tag format ("key:[v1, v2]" strings) isn't something SQL can
  cleanly filter without a normalization migration; same precedent as the professional subtab's
  `visibleRoles` filter.
- **Sport/amenity chips** (`_SportChip`/`_TagChip` in `location_section/main.dart`) parse that same
  tag format instead of showing it raw: a chip per recognized Passe sport (icon + localized name,
  matching the professional subtab's `_SportChip` styling) plus a chip per recognized `leisure:[...]`
  facility value (`homeTab.location.amenity.<value>` translation keys — `pitch`, `sports_centre`,
  `stadium`, `swimming_pool`). Everything else in the tag set (opening_hours, building:levels,
  website, wikidata, …) is dropped rather than shown as raw OSM junk.
- **District filter** matches `location.district` against each selected ward's `legacyDistrict`
  (plus `id`, for the few rows already using it) — **not** `District.id`. `location.district` is
  free text from a 3rd-party scrape; verified against prod that HCMC's 16 old urban quận store the
  exact old-district label ("Quận 7", "Quận Bình Thạnh"), which is exactly what `legacyDistrict`
  holds (~43% of HCMC rows match this way). Rows using a pre-2021 sub-ward name (predating even the
  old Quận 2/Thủ Đức merger, e.g. "Phường Thảo Điền") or no district at all won't match any filter
  selection — an accepted gap given the data's quality, not a bug to chase further without a
  normalization pass on the source data (which is a 3rd-party API re-fetch, not something to migrate
  by hand — see root CLAUDE.md district-model note).
- If `FilterData.search` **or** `filter.districts` is non-empty, route through the
  `search_locations(search_term, p_districts, p_city_cluster)` RPC instead of the direct city-only
  query — search and district are **OR'd**, not AND'd (picking a district broadens results rather
  than narrowing a name search; `p_districts` uses the same `legacyDistrict` + `id` label set as the
  direct-query path above), while `p_city_cluster` is a hard **AND** on top of that OR (added by
  `schema/location_search_city_filter.sql` — the RPC originally ignored city on this path, so a
  district pick could leak the other supported city's venues whenever a district label coincided).
- **Migration**: `schema/home_feed_search.sql` widens `search_locations` to also return
  `lat/lon/tags/city_cluster` (so searched venues are pinnable) and adds the `p_districts` OR-match;
  also adds `p_search` to the other 3 RPCs (see "Shared filter" above), applied to prod. Supersedes
  the retired `location_map_support.sql`. `schema/location_search_city_filter.sql` (also applied)
  layers the `p_city_cluster` AND on top.
- **Unnamed venues**: ~20% of scraped rows have `name = ''` (not null — every one still has an
  address). `Location.hasName` gates the fallback; both the card and the detail sheet show
  `'homeTab.location.unnamed'.tr()` instead of a blank title.
- Roadmap: we don't own venue data yet; booking arrives with local-business integration. The detail
  sheet states this (`homeTab.location.roadmapNote`).
- Model: the `Location` freezed model in `core/model/location.dart`.

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
