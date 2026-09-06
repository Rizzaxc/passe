# Health Tab — wearables & gamification

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This file covers the health screen specifics.

## Purpose

Integrates the user's wearables (Apple Health / Health Connect) to capture data during activities
and gamify engagement (goals/achievements). The whole tab is **gated on a link status**: until the
user grants health permissions, every subtab is replaced by the "not linked" CTA.

## Layout

- `main.dart` — `HealthTab`: watches `healthControllerProvider` (`AsyncValue<HealthLinkStatus>`).
  When `notLinked`, renders `HealthNotLinkedView` instead of the tabs. Otherwise an `FTabs` over 3
  subtabs. `HealthTab.withInitialTab(0|1|2)` (user_health / activity_data / achievements). Header
  carries a **Sync button** (`_SyncButton`, only when linked) that runs the device→Supabase sync.
- `health_controller.dart` — `HealthController`: the link-status state machine (`loading`, `linked`,
  `notLinked`, `error`). `linkHealthService()` / `unlinkHealthService()` request/clear permissions.
- `health_data_service.dart` — wraps the `health` package: reads/aggregates a day or an activity
  window, computes the **3-zone LT** time-in-zone + evidence + downsampled HR curve, and does the
  direct Supabase upserts. `HrThresholds` (max/LT1/LT2 + `estimated`), `HealthEvidence`
  (none/medium/high), `ActivityCaptureResult` live here.
- `health_sync_service.dart` — `HealthSyncController`: the device→Supabase **sync engine**.
  `syncNow()` (daily-summary backfill + confirmed-activity capture), `attach()` / `dismiss()` for
  detected workouts. Fired once at app launch from `ScaffoldWithNavBar.initState` (non-blocking,
  self-guards guests/unlinked) and by the Sync button. **Pull-to-refresh never calls this** — it
  only re-reads Supabase.
- `health_data_controller.dart` — read providers (UI reads Supabase, not the device):
  `dailyHealthTrend` (direct select, sport-agnostic), `activityHealthList` (`activity_health_data`
  RPC, sport-scoped), `detectedWorkouts` (`health_capture_candidates` RPC + per-candidate device
  evidence re-check), and `hrThresholds` (shared threshold resolver). Also the one write path:
  `HrThresholdController.save()` (a `bool`-state notifier) directly `UPDATE`s
  `max_heart_rate`/`lt1_bpm`/`lt2_bpm` on the caller's `user_health_link` row (RLS-scoped, no RPC
  needed) and invalidates `hrThresholdsProvider`.
- `not_linked_view.dart` — the permission-request CTA.
- `user_health_section/` — body-trends dashboard (`main.dart`) + `health_metric.dart`
  (`HealthMetric` enum + `DashboardMetrics`, a locally-persisted customizable visible set).
  `main.dart` also has the **HR Zone** card (`_HrZoneSection`) — shows resolved max
  HR/LT1/LT2 (with an "(estimated)" tag when `lt1`/`lt2` aren't user-declared) and a pencil button
  opening `_HrZoneEditSheet` to declare real values. LT1/LT2 are required on save (int, LT1 < LT2 ≤
  250); Max HR is optional — leave it blank to keep the age-bucket estimate.
- `activity_data_section/` — recap list + detected-workouts inbox (`main.dart`), `recap_sheet.dart`
  (per-activity HR-curve detail), `zone_bar.dart` (3-zone stacked bar).
- `achievements_section/` — the gamification screen (see **Gamification** below):
  `main.dart` (level header + badges grouped by progress state), `badge_card.dart`
  (tier-icon card), `celebration_sheet.dart` (post-sync unlock/level-up sheet),
  `achievements_controller.dart` (read providers + celebration/unseen state), and
  `model/` (`achievement_progress`, `level_summary`, `achievement_celebration`).
- `model/` — freezed models: `user_health_link` (+ `maxHeartRate`/`lt1Bpm`/`lt2Bpm`),
  `daily_health_summary`, `activity_health_metrics` (3 zone fields + `dismissed` tombstone),
  `activity_health_row` (recap view model), `hr_sample` (all generated; edit source + build_runner).

## Data flow

UI reads the Supabase rollup tables; a sync step fills them from the device. Two passes in
`syncNow()`: (1) **daily summaries** — first run backfills 90 days, then today + the gap since
`user_health_link.last_sync_at`; (2) **activity capture** — `health_capture_candidates` returns the
user's confirmed/proposed activities + coach bookings (past `end_time`, no existing metrics row).
Every **confirmed** candidate is captured unconditionally — a committed activity always gets a
best-effort report once the device can be queried, whatever the numbers turn out to be;
`HealthEvidence` is not consulted for these. Unconfirmed-but-detected candidates (the user has some
relationship to the activity — e.g. a lobby/freeplay membership — but never RSVP'd) are different:
there's no commitment to anchor "did something happen" on, so those still need wearable **evidence**
(a `WORKOUT` record = high, or ≥10 min of measured HR-zone time at any intensity = medium) before
they're worth surfacing at all, in the `activity_data` **"Detected workouts"** section: *attach*
(health-only — writes metrics, never touches attendance/đá) or *dismiss* (writes a `dismissed=true`
tombstone so it isn't re-prompted). Capture is sport-agnostic; only the recap-list display filters by
the context sport.

## Link-status flow

`HealthController.build()`:
1. Checks the local SharedPreferences cache (`health_linked` / `health_platform`).
2. If cached linked, **re-verifies** platform permissions are still granted (they can be revoked in
   OS settings) — clears cache + backend if not.
3. Otherwise checks the `user_health_link` table for a prior link.

`linkHealthService()` calls `_health.configure()` + `requestAuthorization()`, then upserts
`user_health_link` (`platform`, `linked_at`) and caches locally. Platform is `appleHealth` on iOS,
`healthConnect` elsewhere.

## Gamification (achievements + XP/level)

One **global** fitness+social level (cap 50), no longer health-only — a `social` criteria
source (Feed engagement) was added alongside `daily`/`activity`/`special`. Schema/RPCs in
`schema/achievement_gamification.sql` + `schema/social_achievements.sql`; catalog in
`schema/achievement_seed.sql` (all applied via MCP — **re-dump `passe.sql`**, which is
currently stale beyond just this: it predates the whole `wall_post`/friendship system too).

- **Criteria are data, not code.** Each `achievement.criteria` jsonb is a constrained
  rule `{source, agg, metric, window, threshold, comparator?, row_min?, session_min?}`
  interpreted by one SQL function. Add/tune a badge = `INSERT`/`UPDATE` a row in the
  seed (keyed by the stable `code` slug) — no Dart change. CHECK-constrained vocabulary:
  `source ∈ daily|activity|special|social`, `agg ∈ sum|count|max|session_streak|special`,
  `window ∈ day|week|month|all_time` (calendar only — no rolling). `repeatable ⇒
  window ∈ {week,month}`.
- **`session_load`** is a *virtual* metric = 3-zone TRIMP `(easy + 2·mod + 3·hard)/60`,
  computed inline from `activity_health_metrics` zone seconds — the intensity-fair
  spine for hard/streak badges. No column.
- **`source=social`** reads `social_event` (`schema/social_achievements.sql`), an
  append-only log populated by triggers on `wall_post`/`wall_post_reaction` insert —
  **not** those tables directly, since posts/reactions are TTL-swept and would
  undercount a lifetime/monthly badge. `metric ∈ post_created|reaction_received|
  reaction_given`; self-reactions are excluded from `reaction_received`/`reaction_given`
  so an author can't farm their own badges. See [`lib/feed_tab/CLAUDE.md`](../feed_tab/CLAUDE.md).
- **Evaluator is the sole mutator, called from every surface that can move a criteria
  forward** — `HealthSyncController.syncNow()` for health/vitality badges, and the
  Feed compose/react controllers for social badges (via the shared
  `evaluateAchievements()` helper in `lib/core/achievement_evaluator.dart`). Health data
  only changes on sync, so that call site is unchanged; social data changes on
  post/react, so those call it right after their write instead. `evaluate_achievements(uid)`
  (SECURITY DEFINER) itself doesn't care who called it — it scores every criteria row
  for that user regardless. It persists unlocks to `user_achievement` (`ON CONFLICT DO
  NOTHING`, keyed by `period_key`), banks `xp_granted` (a **snapshot** of `xp_reward`,
  so retuning the catalog never rewrites history), recomputes `user.xp`/`user.level`,
  and returns the newly-unlocked payload. RLS gives clients **no** write path anywhere.
- **Curve lives only in SQL**: `C(L)=25·L·(L−1)`, cap 50. `user_level_summary` returns
  `{level, xp_total, current_floor, next_floor}`; the client renders the bar, never the
  formula. **Only ratchet the constant (25) *down*** — raising it de-levels users.
- **Read path is cheap**: `achievement_progress(uid)` computes per-badge state
  (`in_progress`/`earned_period`/`done`/`not_started`) for display; pull-to-refresh
  invalidates the read providers, **never** `syncNow()`.
- **Backfill floor**: achievements only count data since `greatest(user.created_at,
  now()−90d)`, so a new user can't farm pre-app watch history; repeatable badges only
  ever evaluate the current calendar period. Applies uniformly to `social_event` too,
  though it's moot in practice — that log only ever grows forward from signup.
- **Surfacing**: an evaluation that unlocks something → trophy-tab dot
  (`unseenAchievementsProvider`, persisted) + a pending `AchievementCelebrationController`
  payload the subtab shows as a `PSheet` on entry — from *any* call site, not just a
  health sync. Only the explicit Sync button additionally shows a toast.
  **TODO(notifications)**: replace that launch-sync toast with a push notification once
  that system exists (the dot→sheet flow stays).
- Only the health/vitality half is sport-scoped data; achievements themselves are
  **sport-agnostic** (`sport=NULL`) across the board, social included (Feed is
  cross-sport by design — see [`lib/feed_tab/CLAUDE.md`](../feed_tab/CLAUDE.md)). The
  back half of the level cap (25→50) is the reserved runway for a future competitive
  achievement track.

## Vitality Score

A second health subsystem alongside achievements (separate from XP/level). Backed by
`schema/vitality_score.sql` (tables `vitality_daily_load` + `vitality_score`, RPCs
`evaluate_vitality_score` / `vitality_score_summary`), invoked at the end of `syncNow()`
(`health_sync_service.dart`). Client: `vitality_score_controller.dart`,
`user_health_section/vitality_score_card.dart`, `model/vitality_score.dart`. Like achievements, the
evaluator is the sole mutator and runs only on sync; the read path is a cheap summary the card
renders. (Previously undocumented — added in the 2026-07 audit pass.)

## Gotchas

- **Permissions are READ-only and can be revoked out of band** — never assume a cached `linked`
  status means access still works; the controller re-checks `hasPermissions` every build. Preserve
  that re-verification. `syncNow()` guards on `healthControllerProvider` so it inherits this check.
- `_health.configure()` throws on the iOS simulator (no HealthKit) — handle/expect failure there;
  **test on a real device** (the launch sync + capture are untestable on the simulator).
- **Two refresh directions, don't conflate them**: the Sync button → `syncNow()` pulls the device
  into Supabase (heavy); pull-to-refresh (per data subtab) only invalidates the read providers. The
  tab-level scaffold has no `RefreshIndicator` over the linked tabs — each data subtab owns its own.
- Identity via `currentUserIdProvider`; bail when null (guest/signed-out has no health link).
- `user_health_link.platform` is a `@JsonEnum`-style value (`HealthPlatform.dbValue`) — follow the
  DB-id-as-enum-value rule when extending it.
- Health data types requested are the `_healthDataTypes` getter in `health_controller.dart` — add
  to that list (and the OS entitlements/Info.plist) when you need a new metric.
- **Sleep is not tracked.** Health Connect (Android) has no `SLEEP_IN_BED` mapping and no reliable
  in-bed/asleep distinction at all (`Datatype SLEEP_IN_BED not found in HC`), so sleep collection was
  dropped app-wide rather than special-cased per platform like HRV was: `_healthDataTypes` no longer
  requests `SLEEP_ASLEEP`/`SLEEP_IN_BED`, `readDailyHealthSummary` doesn't query it, and `HealthMetric`
  has no `sleep` entry. `daily_health_summary.sleep_minutes`/`sleep_quality_score` DB columns and the
  matching (now write-only-historically) Dart fields were left in place — old data isn't wiped, just no
  longer collected. Re-enabling sleep would need a real per-platform strategy, not a naive re-add.
- **HRV is platform-split, not one metric.** Health Connect (Android) has no SDNN record type —
  only `HeartRateVariabilityRmssdRecord` — so requesting `HEART_RATE_VARIABILITY_SDNN` there is a
  silent no-op (the `health` plugin logs `Datatype HEART_RATE_VARIABILITY_SDNN not found in HC` and
  returns nothing). `health_controller.dart`'s `hrvDataType` getter resolves to SDNN on iOS / RMSSD
  on Android; `health_data_service.dart` reads that type and writes the value to the matching
  `hrvSdnnMs`/`hrvRmssdMs` field (only one is ever populated per platform) on
  `ActivityHealthMetrics`/`DailyHealthSummary`/`ActivityHealthRow`. UI reads that want a
  platform-agnostic value should coalesce both (see `HealthMetric.hrv.value()`).
- **Distance and total energy are platform-split too.** Health Connect exposes
  `DISTANCE_DELTA` and `TOTAL_CALORIES_BURNED`; HealthKit exposes distance as walking/running,
  cycling, and swimming records, and whole-day energy is derived by adding active + basal energy.
  Keep permission requests and reads routed through `healthDistanceDataTypes()` /
  `healthAdditionalEnergyDataType()`. Requesting Android's `DISTANCE_DELTA` on iOS makes the
  `health` package throw and causes the whole activity capture to return no metrics.
- **HR zones are a 3-zone LT model** (easy/moderate/hard by `lt1_bpm`/`lt2_bpm`). Defaults estimate
  LT1≈80% / LT2≈88% of an age-bucket max HR; `HrThresholds.estimated` drives the "estimated" tag in
  the recap sheet until the user declares real thresholds on `user_health_link`.
- **Zone time excludes long *stationary* pauses, not just low HR.** `_calculateHrZones`
  (`health_data_service.dart`) cross-checks every below-LT1 stretch against step data from the same
  window before treating it as a break — duration alone can't tell "sitting on the bench" apart
  from "still playing, just very fit / a genuinely light session" (both look like sustained low HR).
  If there's corroborating movement (`_movementStepsPerMinuteFloor`), the whole stretch counts as
  easy no matter how long; if the player is stationary, only the first `_pauseGraceSeconds` (90s)
  count and the rest is excluded from every zone entirely. Social sports (badminton, basketball,
  soccer…) aren't endurance sports — a water break or side-change shouldn't read as several minutes
  of low-intensity play and drag `effort_score` (and the zone seconds that feed `session_load`/
  Vitality's load component) down the way it would for continuous steady-state cardio.
- `saveActivityMetrics` strips null keys before upsert so the DB keeps its `id`/`recorded_at`
  defaults; the dismissal tombstone reuses the same `(user_id, activity_id)` unique constraint.
- Device metrics are read independently through `_readHealthData`: one denied, unavailable, or
  slow optional datatype must not discard valid workout/HR data. A completely failed daily read
  aborts the pass before `last_sync_at` advances, and failures are logged through Talker/Sentry.
- Medium evidence is ten minutes of measured HR-zone time at any intensity (easy included); high
  evidence is an overlapping Workout record. Workout reads include a 15-minute start lead-in to
  accommodate someone starting their Watch before the scheduled activity, then filter to overlap.
  **This threshold only gates the unconfirmed "Detected workouts" surfacing**
  (`health_data_controller.dart`'s `detectedWorkouts` provider) — a confirmed/committed activity is
  captured by `_captureActivities` (`health_sync_service.dart`) regardless of `HealthEvidence`, since
  the user already told the app something happened there; evidence only answers "did something
  happen" for activities that were never explicitly confirmed.
- Backend writes keep the `.timeout(const Duration(seconds: 5))`.
- `schema/health_3zone.sql` is the migration (applied). It was hand-patched into `schema/passe.sql`
  (CLI couldn't `pg_dump` here) — re-dump properly when you next can.
