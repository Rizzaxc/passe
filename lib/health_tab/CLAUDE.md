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
  evidence re-check), and `hrThresholds` (shared threshold resolver).
- `not_linked_view.dart` — the permission-request CTA.
- `user_health_section/` — body-trends dashboard (`main.dart`) + `health_metric.dart`
  (`HealthMetric` enum + `DashboardMetrics`, a locally-persisted customizable visible set).
- `activity_data_section/` — recap list + detected-workouts inbox (`main.dart`), `recap_sheet.dart`
  (per-activity HR-curve detail), `zone_bar.dart` (3-zone stacked bar).
- `achievements_section/` — still a hard-coded placeholder (gamification deferred).
- `model/` — freezed models: `user_health_link` (+ `maxHeartRate`/`lt1Bpm`/`lt2Bpm`),
  `daily_health_summary`, `activity_health_metrics` (3 zone fields + `dismissed` tombstone),
  `activity_health_row` (recap view model), `hr_sample` (all generated; edit source + build_runner).

## Data flow

UI reads the Supabase rollup tables; a sync step fills them from the device. Two passes in
`syncNow()`: (1) **daily summaries** — first run backfills 90 days, then today + the gap since
`user_health_link.last_sync_at`; (2) **activity capture** — `health_capture_candidates` returns the
user's confirmed/proposed activities + coach bookings (past `end_time`, no existing metrics row);
confirmed ones with wearable **evidence** (a `WORKOUT` record = high, or ≥10 min sustained HR in
zone = medium) are auto-captured. Unconfirmed-but-detected candidates surface in the
`activity_data` **"Detected workouts"** section: *attach* (health-only — writes metrics, never
touches attendance/đá) or *dismiss* (writes a `dismissed=true` tombstone so it isn't re-prompted).
Capture is sport-agnostic; only the recap-list display filters by the context sport.

## Link-status flow

`HealthController.build()`:
1. Checks the local SharedPreferences cache (`health_linked` / `health_platform`).
2. If cached linked, **re-verifies** platform permissions are still granted (they can be revoked in
   OS settings) — clears cache + backend if not.
3. Otherwise checks the `user_health_link` table for a prior link.

`linkHealthService()` calls `_health.configure()` + `requestAuthorization()`, then upserts
`user_health_link` (`platform`, `linked_at`) and caches locally. Platform is `appleHealth` on iOS,
`healthConnect` elsewhere.

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
- Health data types requested are the `_healthDataTypes` const list in `health_controller.dart` —
  add to that list (and the OS entitlements/Info.plist) when you need a new metric.
- **HR zones are a 3-zone LT model** (easy/moderate/hard by `lt1_bpm`/`lt2_bpm`). Defaults estimate
  LT1≈80% / LT2≈88% of an age-bucket max HR; `HrThresholds.estimated` drives the "estimated" tag in
  the recap sheet until the user declares real thresholds on `user_health_link`.
- `saveActivityMetrics` strips null keys before upsert so the DB keeps its `id`/`recorded_at`
  defaults; the dismissal tombstone reuses the same `(user_id, activity_id)` unique constraint.
- Backend writes keep the `.timeout(const Duration(seconds: 5))`.
- `schema/health_3zone.sql` is the migration (applied). It was hand-patched into `schema/passe.sql`
  (CLI couldn't `pg_dump` here) — re-dump properly when you next can.
