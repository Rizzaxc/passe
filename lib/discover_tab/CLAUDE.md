# Discover Tab

Read the root [`CLAUDE.md`](../../CLAUDE.md) first for project-wide conventions (build_runner,
navigation, the `selectedSportStateProvider` context sport, forui/theme, identity rules). This file
covers what's specific to the Discover screen.

## Purpose

Discover is a surface with five implemented subtabs sharing one filter, all scoped to the
context sport (`selectedSportStateProvider`). Challenger is client-gated off by default, so normal
builds show four. Each feed returns `[]` when no sport is selected.

The social surface (**Feed**) is a separate, first-positioned main tab — see
[`lib/feed_tab/CLAUDE.md`](../feed_tab/CLAUDE.md). It used to live here behind a header pill toggle;
it moved out to its own tab (a TikTok-style vertical feed doesn't compose well as a sub-segment of
another screen), so `DiscoverTab` is back to being single-purpose.

## Layout

- `main.dart` — `DiscoverTab`: `FScaffold` + `_DiscoverView` (four tabs by default).
  - Default indices are `0` freeplay, `1` teammate, `2` professional, `3` location. When Challenger
    is explicitly enabled it is inserted at `2`, shifting professional/location to `3`/`4`.
    `DiscoverTab`'s named index getters keep the `Discover*Route` classes independent of that shift.
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
- `freeplay_section/main.dart` is the thinnest of the five: the models, providers, card and detail
  page all live in [`lib/freeplay/`](../freeplay/) because the host/manager side of the same data
  is rendered from Manage (see [`lib/manage_tab/CLAUDE.md`](../manage_tab/CLAUDE.md)).
- `lobby_public_preview_sheet.dart` / `lobby_public_preview_controller.dart` — the read-only
  "who are these people" sheet for a lobby you don't belong to (`get_lobby_public_preview`,
  anon-granted, **refuses `private` lobbies**, collapsing not-found and private into one answer so a
  guessed uuid can't probe existence). Opened by tapping a `LobbyFeedCard`, and by the owner chip on
  a lobby-owned freeplay listing. It is *not* `LobbyDetailPage` — that one is for members.

## Shared filter

`filterStateProvider` (`FilterState` → `FilterData`: `search`, `city`, `districts` ≤6,
`schedule` ≤3 `Timeslot`s) is the single filter for all subtabs. It's **seeded from the signed-in
user's `details.location` and `details.playtime`** on build, defaulting to `City.hochiminh`.
Changing the city clears districts. Feeds `ref.watch(filterStateProvider)` so they refetch on any
filter change. `FilterState.onCommit()` (persisting the filter server-side) is a TODO.

**`search` (`p_search`) is wired into every subtab RPC** (`schema/home_feed_search.sql`, applied to
prod): teammate/challenger match `lobby.name` OR
`lobby.searchable_id`; professional matches `professional.display_name`; location matches
name/address via the existing `search_locations` fuzzy match; freeplay matches the listing owner's
name (Host display name *or* lobby name) plus venue and address. All are diacritic-insensitive
(`extensions.unaccent`). **Location is the one exception to "search narrows the result set"**: its
district filter is OR'd with the search term (broadens results), not AND'd — see the Location
subtab section below for why.

## Subtab data sources

Quick map, then the full contract for each:

| Subtab | Source | Model | Action |
|---|---|---|---|
| Freeplay | `home_freeplay_data` RPC (anon-granted) | `FreeplayActivity` (`lib/freeplay/model.dart`) | "Xin một chỗ" → `request_freeplay_seat` RPC |
| Teammate | `home_teammate_lobby_data` RPC | `LobbyFeedItem` | "Xin vào" → insert `lobby_befriend_record` (`request`) |
| Challenger | `home_challenger_lobby_data` RPC | `LobbyFeedItem` (`memberCount` + offer terms set) | "Thách đấu" → confirm-terms sheet → `send_challenge` RPC from the "challenging as" context lobby (see root CLAUDE.md ▸ Challenger System) |
| Professional | `home_professional_data` RPC (sport + soft city/district/schedule + role toggle; ranked verified/rating/reviews; `price_from` from `professional_service`) | `ProfessionalFeedItem` | tap → `ProfessionalDetailRoute`; book = "coming soon" toast |
| Location | `location` table, or `search_locations` RPC when `search` is set | `Location` (freezed) | list/map toggle; tap → detail sheet; "Chỉ đường" launches external maps |

Conventions across all four: `p_sport_id` is `Sport.index`; `p_city` is `City.dbIndex`; districts
are `district.id` strings; every RPC/query carries `.timeout(const Duration(seconds: 5))`.
`LobbyFeedItem` and `ProfessionalFeedItem` are **plain classes with manual `fromJson`** (not
freezed) — edit them by hand, no build_runner.

### Freeplay subtab

- Shows single **drop-in seats** in the next 7 days: one row per open session, cheapest path from
  "I'm free tonight" to actually playing. Index `0` — the first thing Discover shows.
- Data: `home_freeplay_data(p_sport_id, p_timeslots, p_city, p_districts, p_search, p_page_size,
  p_page_number)`. **Granted to `anon`** — a signed-out visitor sees the feed (the seat request
  itself is authenticated-only).
- **A listing has one of two owners, and the feed returns both in one ordered list.** `owner_kind`
  (`'host' | 'lobby'`) is the discriminator; it is *derived* server-side from
  `activity.freeplay_host_id`, never stored:
  - `'host'` — the original product: a curated `freeplay_host` row (provisioned out of band, there
    is no self-serve RPC) putting up a standalone session. `host_id` is a `freeplay_host.id`; the
    owner chip pushes `FreeplayHostRoute`.
  - `'lobby'` — a **non-private** lobby offering spare seats on an activity it already scheduled
    (`schema/lobby_freeplay_exposure.sql`). `host_id` is a `lobby.id`, `host_name` is the lobby
    name, `host_avatar_url` is null, and the owner chip opens `showLobbyPublicPreviewSheet` instead.
    `FreeplayActivity.isLobbyOwned` is the client-side switch — branch on it, never on whether
    `hostAvatarUrl` happens to be null.
- The feed excludes private lobbies at query time, so flipping a lobby to private would withdraw its
  listings — which is exactly why the server refuses that flip while one is live (see
  [`lib/manage_tab/CLAUDE.md`](../manage_tab/CLAUDE.md) ▸ Freeplay exposure).
- **Action**: "Xin một chỗ" → `request_freeplay_seat`, which opens a two-party (Host) or requester +
  every-manager (lobby) thread on the shared messaging layer. Rejections worth knowing: a lobby
  *member* can't request a seat in their own lobby's listing (they RSVP), and a `declined` request
  is terminal.
- Price is gendered (`male_price` / `female_price`) and snapshotted onto the request at request
  time, so it never drifts afterwards. `numeric` comes back as `String` — `_money()` in
  `lib/freeplay/model.dart` parses it.

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
- **Sport-scoped, now server-side.** `search_locations` takes `p_sport_id` and filters on the
  `location.sport_ids bigint[]` column (GIN-indexed, `schema/location_sport_tags.sql`), populated
  from the OSM tags by `tool/venue/normalize.py`. It used to be client-side, after a flat
  `LIMIT 60` — which is how a thin sport (HCMC badminton had 24 real venues) could render an empty
  list while matches sat past the limit, unfetched.
  **The "keep untagged venues" semantic is load-bearing and must survive any rewrite**: the
  predicate is `(NOT has_declared_sport OR sport_ids && ARRAY[p_sport_id])`, never a bare
  `sport_ids && …`, because ~433 rows declare no sport at all and "no sport info" is not "wrong
  sport". `has_declared_sport` records whether the source named *any* sport, including ones Passe
  doesn't support, which is what still hides a volleyball-only court. `Sport.others` sends `null`,
  not `0`. `Location.sports`/`hasDeclaredSport`/`amenityKeys` prefer the new columns and fall back
  to parsing raw `tags`, so unmigrated rows, `user_submitted` rows (`create_location` writes no
  tags) and stale cached JSON keep behaving as before.
- **Sport/amenity chips** (`_SportChip`/`_TagChip` in `location_section/main.dart`) parse that same
  tag format instead of showing it raw: a chip per recognized Passe sport (icon + localized name,
  matching the professional subtab's `_SportChip` styling) plus a chip per recognized `leisure:[...]`
  facility value (`homeTab.location.amenity.<value>` translation keys — `pitch`, `sports_centre`,
  `stadium`, `swimming_pool`). Everything else in the tag set (opening_hours, building:levels,
  website, wikidata, …) is dropped rather than shown as raw OSM junk.
- **District (ward) filter — the normalization pass has been done.** `location.district` now holds
  the canonical `District.id` (`hcm_ankhanh`) for every row whose coordinates fall inside one of the
  102 HCMC / 126 Hanoi wards, derived geometrically by `tool/venue/` from OSM `admin_level=6`
  boundary polygons rather than parsed out of the text. Before this, `district` was free text mixing
  legacy quận labels, pre-reform ward names and blanks, and **557 of 997 HCMC rows (56%) plus 376 of
  1,052 Hanoi rows could not be surfaced by any ward selection at all.** After: Hanoi 0
  unfilterable, HCMC 229 — and those 229 are exactly the out-of-footprint rows below.
  The client still sends four labels per selected ward (`id`, `legacyDistrict`, `name`, and the
  `"Phường X"`/`"Xã X"` form) because a handful of rows keep a legacy value, and `search_locations`
  compares with `=`. Diacritics are handled server-side (both sides are `unaccent`ed); spelling is
  not. `district_legacy` keeps the pre-normalization value, so the whole pass is reversible with one
  UPDATE.
- **Out-of-footprint rows.** 241 rows filed under `city_cluster = 1` are actually in Đồng Nai /
  Bình Dương (Biên Hòa, Dĩ An, Thủ Dầu Một) — the 2025 reform merged those into HCMC, but
  `VietnamLocationData` deliberately scopes to the *old* footprint. They're marked
  `is_verified = false` and hidden when **browsing**, but still returned when **searching** by name:
  if someone types a venue's name they asked for it specifically. Note `create_location` writes
  `is_verified = false` for every user submission too, so the predicate is
  `(is_verified OR source = 'user_submitted')` — a blanket verified-only filter breaks the
  manual-entry flow.
- **One code path.** Every case goes through
  `search_locations(search_term, p_districts, p_city_cluster, p_sport_id)`; the old direct
  `.from('location').select()` browse query is **gone**. It could only go once the RPC gained a
  match-all branch (empty term + no wards now returns the city's venues; previously that combination
  matched *nothing*, which is why the second path existed at all) — and it had to go, because it
  couldn't express the sport predicate without re-reading raw tag strings client-side.
  Search and district are **OR'd**, not AND'd (picking a ward broadens results rather than narrowing
  a name search); `p_city_cluster` and `p_sport_id` are hard **AND**s on top of that OR.
  Migration: `schema/search_locations_sport_scoped.sql`.
- **Migration**: `schema/home_feed_search.sql` widens `search_locations` to also return
  `lat/lon/tags/city_cluster` (so searched venues are pinnable) and adds the `p_districts` OR-match;
  also adds `p_search` to the other 3 RPCs (see "Shared filter" above), applied to prod. Supersedes
  the retired `location_map_support.sql`. `schema/location_search_city_filter.sql` (also applied)
  layers the `p_city_cluster` AND on top.
- **Unnamed venues** (406 rows, 20%): real, correctly geocoded places OSM never labelled. Three
  things happen, and **none of them renames the venue on the server** — `location.name` stays
  exactly as the map source left it:
  1. `Location.describe()` builds a client-side description from the row's own facility kind and
     street/ward ("Sân cầu lông — Đ. Nguyễn Hữu Cảnh") instead of one shared placeholder. Still
     rendered muted/italic: it is a description, not a claimed name.
  2. `_venueGlyph()` uses the venue's sport icon when its tags name exactly one, falling back to the
     map pin. A screen of identical grey pins is most of why a correctly-populated list read as
     broken. Map markers stay pins deliberately — a pin is the right metaphor on a map.
  3. A lobby member who knows the real name can set one via `set_lobby_location_alias`
     (`schema/lobby_location_alias.sql`). The alias is **scoped to that lobby**, and the RPC
     **refuses a venue that already has a name** — a nickname is local knowledge, not a global
     claim, and letting anyone relabel a shared row every other lobby reads is how
     "Nhà Thi Đấu Phú Thọ" becomes "sân ông Tư" for everybody. The guard lives in the function
     because a CHECK cannot span two tables.
- **Venue data is grown by `tool/venue/`** — see its README. Re-runnable and idempotent on
  `external_id`; it never deletes (six columns across five tables FK into `location`) and never
  touches a `user_submitted` row.
  **OSM is exhausted as a volume source**: an exhaustive Overpass pull over the HCMC footprint
  returns 1,836 elements of which only 303 are named, and all of OSM HCMC holds 47 badminton and 18
  pickleball venues. Real coverage has to come from `tool/venue/curated_seed.csv`.
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
- **A freeplay seat is not lobby membership.** Accepting an outsider onto a lobby-owned listing
  deliberately writes **no** `activity_confirmation` row: that row is the lobby's own commitment
  quorum and bill-split basis. Anything that wants to show guests has to union
  `freeplay_request` explicitly — don't "fix" it by inserting a confirmation.
- Challenger interactions must NOT reuse `lobby_befriend_record` (that table is user↔lobby /
  user↔user only) — the challenge handshake needs its own `lobby_challenge` table, still unbuilt.
