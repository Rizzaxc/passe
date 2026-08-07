# passe

Next gen casual sport portal

## Stack

DB: Postgres/ Supabase
Frontend: Flutter
Complex operations are done at SQL functions and called using Supabase

## Flow

User will choose a "context sport" (frontend variable). The app will help them
find teammates, parties ("lobby"), organize play, hire coaches/ referees etc

5 Main Tabs (in bottom-nav order):

- Feed: a TikTok-style, one-post-per-screen vertical feed of ephemeral photo posts from you, your
  friends and your lobby mates (cross-sport). First tab — the social/discovery entry point.
- Home (Discover): 4 subtabs sharing one filter, all scoped to the context sport
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

`lib/social/` (friendship + `/user/:id`) also ships one:
[`lib/social/CLAUDE.md`](lib/social/CLAUDE.md).

Each tab folder ships its own `CLAUDE.md` with the file map, providers, and screen-specific
gotchas — read it before touching that screen:
[`lib/feed_tab/CLAUDE.md`](lib/feed_tab/CLAUDE.md),
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
- **Coordinator** — a member the captain has promoted (`lobby_member.role = 'coordinator'`, see
  `schema/lobby_coordinator_role.sql`). Can do the "manage" tier — schedule/reschedule/cancel
  activities, manage join requests, send/answer challenges — but **not** the captain-only tier
  (kick members, edit lobby info, transfer/delete). Gate manage-tier UI on `lobby_can_manage()` /
  `LobbyPermission.canManage`; captain-only UI on `isCaptain`.
- **Homeground** — a lobby's default venue; `lobby.home_ground` FK → `location`.
- **Searchable id** — a short human-shareable lobby code (`lobby.searchable_id`, a `nanoid(8)`),
  distinct from the UUID `lobby.id`.
- **Befriend** — the lobby join handshake (`lobby_befriend_record`): *request* (user → lobby) and
  *invite* (lobby → user). A third type, *pair* (user ↔ user, created a new lobby on accept),
  is **retired** — see *Friend* below. Distinct from **Friend**, which is user ↔ user.
- **Friend** — a mutual user↔user relationship (`friendship`, request → accept). The supported way
  to connect two people; it replaced the never-used `pair` befriend interaction. Blocking
  (`user_block`) severs it and hides both parties from each other.
- **Wall** — a user's own ephemeral posts, shown on `/user/:id` alongside a *tagged* segment.
- **Post** — a `wall_post`: 1–4 photos + an optional ≤140-char caption, hooked to a lobby activity
  or coach lesson from the last 7 days, living 1/3/7 days before being swept.
- **Tag** — up to 5 people named on a post (`wall_post_tag`), drawn from that session's attendees
  and lobby members. Tagging is also what widens a post's audience to the tagged person's friends.
- **Challenge / Challenger** — team-vs-team matchmaking (one lobby challenges another). Distinct from
  befriend; has its own `lobby_challenge` table + `send_challenge`/`respond_challenge`/`cancel_challenge`
  RPCs (`schema/lobby_challenge.sql`). A lobby opts in via `open_to_challengers`. See "Challenger
  System (built)" below.
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
  mapped by `City.dbIndex`) groups *districts* (hard-coded in `core/model/enum.dart`). "District"
  (`District`, `WardType`) means a post-2025-reform **ward/commune** (phường/xã) — Vietnam abolished
  the old quận/huyện tier nationwide on 2025-07-01. The class kept its old name for continuity with
  the `location.district` DB column and the `district.*` translation namespace; each entry also
  carries `legacyDistrict` (the pre-reform quận/huyện name) purely as a display/grouping label, not a
  functional key. Data is scoped to the *old* HCMC/Hanoi footprints (102 + 126 units) — HCMC's 2025
  merger with Bình Dương and Bà Rịa–Vũng Tàu is **not** modeled; expanding city coverage to the new
  provincial boundary is a separate product decision. Saved district preferences from before this
  conversion (old ids like `hcm_q1`) silently fail to resolve — every call site already treats a miss
  as "unknown" rather than crashing.
- **Compat score** — matchmaking output on a lobby feed row: `timeslot_compat_score` (schedule
  overlap) and `profile_compat_score` (networks/industries/skill proximity, 0–5).
- **ELO / elo seed** — skill rating. `elo_seed` (beginner/casual/tryhard) is the self-declared
  starting point per sport profile; `user_rating` holds the live ELO per sport/format, updated by
  `fn_apply_match_rating` on a scored, refereed challenge match (see "Challenger System").
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
- `friendship` — mutual user↔user edges (`schema/friendship.sql`); `user_block` sits alongside it.
- `wall_post` (+ `wall_post_tag`, `wall_post_reaction`, `wall_post_report`, `wall_post_gc`) — the
  ephemeral photo feed (`schema/wall_post.sql`). See *Friends & Feed* below.
- `lobby_member` — user↔lobby join.
- `lobby_befriend_record` — request/invite/pair handshake; CHECK constraints enforce the shape of
  each interaction type; triggers auto-accept reciprocals and add members on accept.
- `lobby_feed_item` (+ `lobby_feed_poll_vote`) — a lobby's action-stream; `payload` jsonb shape varies
  by `kind` (update/personal/system/poll/photo) per a CHECK. Canonical shapes:
  `lib/manage_tab/lobby_section/activity/feed.dart`.
- `activity` — a play session. `professional_booking_id` marks a *standalone* client pro-session
  (the coach branch of `my_schedule_data`) and is mutually exclusive with `lobby_id`
  (`activity_source_exclusivity` CHECK). Separately, a lobby activity may **attach** a hired
  `coach_booking_id` and/or `referee_booking_id` (FK → `professional_booking`, *coexist* with
  `lobby_id`, role-guarded by a trigger) — these surface on the activity hero card. See
  `schema/activity_professional_attachment.sql`.
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
- **Guard every `Row` that mixes an icon/label with dynamic-length text** (a user's name, a formatted price, a review
  count, anything not a short fixed string you control) **against horizontal overflow.** A `Row` with unguarded
  `Text` children only "works" until content is long enough or the device is narrow enough (this exact bug shipped
  on iPhone 13 in the professional discovery card's rating/price row). Concretely: wrap the dynamic text in
  `Flexible` or `Expanded` and set `maxLines: 1, overflow: TextOverflow.ellipsis` (or combine multiple dynamic spans
  into one `Text.rich` inside a single `Flexible` so the whole group ellipsizes together, not each piece
  independently). `Spacer()` between two unguarded children does **not** prevent overflow — it only absorbs slack,
  it doesn't shrink its siblings. When several elements in a row can't all be protected, let the least important one
  (e.g. a restated price) be the one that shrinks/ellipsizes first, not the primary action. Mentally (or actually)
  check new layouts against a narrow reference width (iPhone SE / 13 mini, ~375px) in addition to whatever device
  you're testing on, since a layout that fits on a larger phone can still overflow on a smaller one.
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
- **This is strictly an iOS + Android app.** Never attempt to build or run for web, Windows, macOS,
  or Linux (`flutter run -d chrome/windows/macos/linux`) — those targets aren't supported and
  aren't a meaningful way to verify a change here, even as a smoke test. Verify changes on an
  iOS/Android device or simulator/emulator, or by reasoning through the code/`flutter analyze`
  when a device isn't available.
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

These three types aren't the only way into a lobby: a **lobby invite link** (`lobby_invite_link`,
Discord-style, `lib/manage_tab/lobby_section/invite_link/`) lets a captain/coordinator generate a
  shareable `https://passe.vn/invite/CODE` that anyone can redeem for instant membership — it bypasses
`lobby_befriend_record` entirely (no request/invite row, no approval step) via a `SECURITY DEFINER`
RPC that inserts straight into `lobby_member`. It replaced the retired email-invite flow (formerly
`lobby_email_invite` + a Resend-backed edge function).

### Challenger System (built, full flow)

Separate from `lobby_befriend_record`. The flow: a lobby **publishes an offer** (opts in with terms)
→ it surfaces on Discover ▸ Challenger → another lobby's manager sends a challenge, accepting those
terms → accepting materialises a linked activity for each side → both confirm → the home side hires a
referee → the referee records the result → both lobbies' history and Elo update. Schema:
[`schema/lobby_challenge.sql`](schema/lobby_challenge.sql) +
[`schema/challenge_flow.sql`](schema/challenge_flow.sql) (+ its enum prelude
[`schema/challenge_flow_enums.sql`](schema/challenge_flow_enums.sql)).

- **Opting in is publishing an offer, not flipping a boolean.** `lobby.open_to_challengers` alone
  can't say when/where/how much, so `lobby.challenge_offer_time` / `_location` / `_cost` (per team,
  **excluding** the referee fee) travel with it, enforced as a set by the
  `lobby_challenge_offer_complete` CHECK — an open lobby always has all three, so no feed card can
  ever render a blank offer. Write path: `set_lobby_challenge_offer` (manage-tier gated). Client: the
  "Nhận Thách Đấu" checkbox-that's-a-button (`ChallengeOfferControl` /
  `challenge_offer_sheet.dart`), rendered on **both** the lobby activity hero's empty state and the
  lobby info sheet (the hero's empty state stops rendering once there's an upcoming session — the
  info sheet is the always-reachable copy). A stale unaccepted offer past its own kickoff is cleared
  by the cron sweep (see below), not left advertising a match in the past.
- **`lobby_challenge`** (`id, initiator_lobby_id, target_lobby_id, sport_id, status, proposed_time,
  proposed_location, agreed_cost, note, created_at, updated_at`; status enum now
  `requested/accepted/scheduled/played/lapsed/declined/cancelled`). `send_challenge` **snapshots**
  the target's current offer onto the challenge row rather than taking a client-supplied proposal —
  the challenger accepts stated terms, they don't negotiate (**counter-propose is intentionally not
  implemented**, v1 is accept/decline only), and the snapshot means a manager editing the lobby's
  offer afterwards can't rewrite the terms an in-flight challenge was sent under.
- **Accepting materialises the match.** `respond_challenge('accept')` inserts one `activity` row per
  lobby (same `challenge_id`, snapshotted time/venue, the agreed cost as `prepayment_amount`), clears
  the target's offer, and auto-declines its other pending challenges (a lobby can't accept two matches
  for one evening). The activity becomes official on RSVP quorum **and** an explicit manager
  confirmation (`confirm_challenge_activity`, `activity.manager_confirmed_at`) — quorum alone isn't
  enough for a challenge. Once **both** sides confirm, the challenge flips to `scheduled` — the real
  "it's locked in" moment, announced by a `challenge_scheduled` push to both lobbies (sent as two
  calls, one per lobby, each carrying that lobby's own id) and a `lobby_feed_item` on each side. RSVP
  quorum alone does **not** fire the generic `activity_confirmed` push for a challenge activity
  (`fn_emit_activity_confirmed` is guarded off `challenge_id IS NOT NULL`) — that would be premature,
  since a manager still has to confirm on both sides.
- **The referee is home-hired, optional, and is what makes a match rated.** The home (accepting)
  lobby's activity hero prompts "Đặt Trọng Tài", reusing the existing `PendingActivityBookingState`
  hand-off into `activity.referee_booking_id`. A match with no referee still gets logged for **both**
  sides — as a scoreless `practice`-result encounter, inserted automatically by the cron sweep once
  the match's `end_time` passes with no recorded result — but moves no rating. The CHECK
  `lobby_match_referee_required_for_scored_challenge` encodes this: a *scored* (win/loss/draw) match
  against an opponent lobby requires a referee booking; a scoreless one doesn't.
- **The referee records the result**, not the captain — from pro mode's schedule tab
  (`professional/pro_mode/pro_schedule_main.dart` + `record_result_sheet.dart`), gated on the
  activity's `end_time`, via `record_challenge_match`. Entry is **final** — no dispute window, no
  edit path. This closes the referee booking (existing `lobby_match_complete_referee_booking`
  trigger) and fires the Elo engine.
- **Both-sided history + Elo, live at last.** `lobby_match_history_data` now `UNION ALL`s the
  opponent-side rows and flips the perspective on read (win↔loss, sets inverted) — one row, two
  readings, no mirror row to drift. `fn_apply_match_rating` (an `AFTER INSERT` trigger on
  `lobby_match`, firing only on a scored+refereed challenge match) applies an equal, margin-scaled Elo
  delta to every member who RSVP'd `going` on their side's linked activity — the only "who played"
  signal that exists (`activity_confirmation.attendance` is RSVP intent, there's no check-in). This
  is the write side `challenger_support.sql`'s header deferred; the existing
  `trg_user_rating_recompute` → lobby `mmr` cache trigger fires off it unchanged. A lobby with too few
  rated matches shows its MMR with a "tạm tính" (provisional) qualifier client-side
  (`LobbyFeedItem.hasProvisionalMmr`, `rated_match_count` from the feed RPC) rather than presenting a
  seed-derived number as earned.
- **Sweeps**: an accepted challenge whose confirmation deadline passes with either side short of
  quorum is auto-voided (both activities deleted, challenge → `lapsed`, both lobbies pushed +
  fed); a `scheduled` match past `end_time` with no result becomes the scoreless encounter above,
  which also pushes `match_result_recorded` to both lobbies (previously silent). Both run off the
  existing 1-minute `fn_cron_tick`/`fn_sweep_challenges` — no new cron job.
- Client: `challenger_section/send_challenge_controller.dart` (send — moved here from
  `manage_tab/lobby_section/`, its only consumer now that the in-lobby "Mời Thách Đấu" SearchID-invite
  is **retired**: challenges start from Discover, against a lobby that actually opted in, not by
  paste-a-code from inside your own lobby), `challenges_controller.dart` + `challenges_sheet.dart`
  (incoming/outgoing list, agreed terms, referee state, surfaced from the lobby info sheet with an
  incoming badge), `challenge_offer_controller.dart` / `challenge_offer_sheet.dart` (the offer),
  `activity/hero.dart`'s `_ChallengeBlock` (opponent context, confirm, book-referee), and the Home
  "Thách đấu" CTA (`challenger_section/main.dart`, now a confirm-these-terms sheet, not a bare
  fire-and-forget button). Notifications: `challenge_received`, `challenger_confirmed`,
  `challenge_declined`, `challenge_scheduled`, `challenge_lapsed`, `match_result_recorded` — see
  root CLAUDE.md ▸ Notifications for the per-lobby-routing rule these all follow. Client-side kind
  mirror: `notifications/notification_kind.dart`; tap routing:
  `notifications/notification_router.dart`; center icon: `notification/main.dart`'s `_iconFor`.

### Activity & Currency System

- **As actually built**, scheduling is captain/coordinator-only end to end (the "member proposes →
  captain vetoes" flow was never implemented — see `lib/manage_tab/CLAUDE.md`). Members RSVP
  (going/maybe/out); the activity becomes official once enough **going** confirmations reach the
  threshold, which also fires the `activity_confirmed` push.
- **Match recording**: the free-text "Ghi kết quả" manual-entry path (`RecordMatchController` /
  `record_match_sheet.dart`) is **removed** — captains/coordinators can no longer log an ad-hoc
  practice/opponent result from the History tab. A **challenge** match's result is still recorded by
  the referee (`record_challenge_match`) — see "Challenger System" above — and that's now the only
  way a `lobby_match` row gets written. History reads via `lobby_match_history_data`.
- **đá currency is deferred, not built.** There is still no server-side ledger — `DaBalance`
  (`lib/currency/`) is a local SharedPreferences int and confirming an activity does **not** actually
  debit đá. The wallet's purchase/spending history is intentionally **empty** (not fabricated) and the
  top-up screen is labelled test-only. Bill-splitting with đá is likewise unbuilt. When a real ledger +
  payment provider land, wire debit-on-confirm / refund / split and replace the local int.
  `activity.prepayment_amount` is a captain-set informational deposit label, not a charge.
  `DaAppbarButton` (`lib/currency/da_appbar_button.dart`) — the đá-balance pill — is hidden from
  every tab's appbar for the same reason; the widget and wallet routes still exist, just unlinked
  from the main nav until the ledger is real.

### Friends & Feed

Friendship is a mutual `friendship` edge; the `pair` befriend interaction is **retired**
(`schema/friendship.sql` rejects new ones). `/user/:id` is the only page showing another user.

Wall posts (`schema/wall_post.sql`) are ephemeral photo posts hooked to a lobby activity you
RSVP'd `going` to, or a coach lesson you booked, in the last 7 days. Three rules matter most:

1. **The hook is a label, not integrity.** Display fields are snapshotted onto the post and both
   FKs are `ON DELETE SET NULL`, so `expire_past_activities()` deleting the activity doesn't
   break the card. Never re-resolve the activity when rendering.
2. **Tagging widens the audience.** A post reaches the author's friends and lobby mates, anyone
   tagged, and the friends of anyone tagged. Lobby proximity to the author alone grants nothing.
   `fn_can_see_wall_post` is the single predicate behind RLS, the feed RPC and the wall RPC.
3. **The public bucket is not privacy.** Public + UUID paths are a load-time decision; row
   visibility is enforced on the post, and the TTL sweep really deletes the object, so maximum
   exposure is one TTL.

Full client contract: [`lib/feed_tab/CLAUDE.md`](lib/feed_tab/CLAUDE.md) and
[`lib/social/CLAUDE.md`](lib/social/CLAUDE.md).

### Notifications

Push (raw FCM HTTP v1, iOS + Android) is **built**. Design + remaining provisioning steps:
[`docs/push_notifications_runbook.md`](docs/push_notifications_runbook.md).

- **Pipeline (outbox pattern):** a domain event calls `fn_enqueue_notification(kind, recipients,
  …)` → one row per recipient in `notification_outbox` → an AFTER-INSERT trigger pokes the
  `send-push` Edge Function via `pg_net` (fast path); a `pg_cron` job (`fn_cron_tick`, 1 min)
  scans due reminders and re-pokes stragglers (safety net). The function claims rows atomically
  (`fn_claim_outbox`), expands recipient → `user_device_token`, calls FCM, prunes dead tokens,
  marks `sent`/`failed` (retry cap 3). Schema: `schema/push_notifications.sql`.
- **Flag system = data-driven allowlist** `enabled_notification_kind`. Each `notification_kind`
  is dark-launched / kill-switched by toggling its `enabled` flag (no redeploy). Live kinds:
  `activity_scheduled` (a captain/coordinator puts up a new activity — creation only, not
  reschedule/cancel, which stay feed-only; see `schema/activity_scheduled_notify.sql`),
  `activity_confirmed`, `pro_session_reminder`, `lobby_invite`, `professional_booking_*`, (with
  the challenge handshake) `challenger_confirmed`, `challenge_received`, `challenge_declined`,
  `challenge_scheduled`, `challenge_lapsed`, `match_result_recorded`, (with friendship)
  `friend_request`, `friend_accepted`, and `member_kicked` (a captain removes a member —
  `schema/lobby_member_kicked_notify.sql`; kicking is a direct client-side `DELETE` on
  `lobby_member`, same as a voluntary leave, so the emitter tells the two apart by comparing
  `auth.uid()` to the deleted row's `user_id`). There is deliberately **no** "a friend posted" or
  "someone reacted" kind — the first is the highest-volume, most mutable-worthy push in any social
  app and neither is worth the noise in v1.
  Note: `fn_emit_activity_confirmed` counts **going-only** confirmations and fires on INSERT *or*
  UPDATE of `activity_confirmation` (an out→going switch can cross quorum) — see
  `schema/push_notifications.sql`. **It skips challenge activities entirely** (redefined
  challenge-aware in `schema/challenge_flow.sql`) — RSVP quorum is only half of "official" for a
  challenge (a manager still has to confirm, on both sides), so firing the generic "Hoạt động đã
  được chốt" off quorum alone would be premature and misleading. `challenge_scheduled`
  (`confirm_challenge_activity`, once both sides have confirmed) is the real "it's locked in" signal
  for a challenge match.
  **A recipient's push always carries their OWN lobby's id.** Any event that touches both lobbies
  of a challenge (accept, both-confirmed, lapse, result) sends **two** separate
  `fn_enqueue_notification` calls, one per lobby — a single shared `lobby_id` across a combined
  recipient list would route the other side's tap into the wrong lobby (this shipped broken for the
  lapse and match-result pushes in the initial pass and was fixed once the notification-center
  integration was audited).
- **Client (`lib/notifications/`):** `notification_service.dart` (FCM init, token register/refresh
  tied to `authControllerProvider`, foreground display via `flutter_local_notifications`, the
  permission **soft-ask**), `notification_router.dart` (`kind` → typed `go_router` route),
  `notification_kind.dart` (mirrors the DB enum by value). Init in `main.dart`.
- **Soft-ask, not cold prompt:** `maybePromptAndRegister(context, ref)` shows an in-app `PSheet`
  rationale before the OS dialog, fired at the first meaningful action (currently the teammate
  "Xin vào" CTA), no-op for guests / already-decided, never re-prompts after denial. Add the same
  one-liner at other first-action sites (lobby create, befriend accept, booking confirm) as they ship.
- **Device tokens:** `user_device_token` (fcm_token PK); registering via the `register_device_token`
  RPC moves the token to the current user (handles account-switch on a shared device); deleted on
  logout and server-side on FCM `UNREGISTERED`.
- **Notification centre (built):** `/notifications` (`lib/notification/`) is a passive, cross-kind
  chronological log of `notification_outbox` rows — unread badge on the bell (`NotificationIconButton`,
  live-updated on a foreground push), tap-to-navigate via the same `resolveNotificationLocation`
  routing table `notification_router.dart` uses for push taps, mark-read (`fn_mark_notification_read`)
  / mark-all-read (`fn_mark_all_notifications_read`, `schema/notification_center.sql`). Read state
  also clears on an OS push-banner tap, not just an in-center tap — the `send-push` Edge Function
  forwards the outbox row's own id as `data.notification_id` for this. This is **history, not the
  primary way to act** on a pending item: the existing per-surface actionable queues — the
  Manage▸Lobby invites button, a lobby's challenges/join-requests rows, the Profile Friends badge —
  are unchanged and still where accept/decline actually happens.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (`gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. Domain language currently lives in `CLAUDE.md`; `CONTEXT.md` + `docs/adr/` are where it moves when separated. See `docs/agents/domain.md`.
