# Health Tab — wearables & gamification

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This file covers the health screen specifics.

## Purpose

Integrates the user's wearables (Apple Health / Health Connect) to capture data during activities
and gamify engagement (goals/achievements). The whole tab is **gated on a link status**: until the
user grants health permissions, every subtab is replaced by the "not linked" CTA.

## Layout

- `main.dart` — `HealthTab`: watches `healthControllerProvider` (`AsyncValue<HealthLinkStatus>`).
  When `notLinked`, renders `HealthNotLinkedView` instead of the tabs. Otherwise an `FTabs` over 3
  subtabs. `HealthTab.withInitialTab(0|1|2)` (user_health / activity_data / achievements).
- `health_controller.dart` — `HealthController`: the link-status state machine (`loading`, `linked`,
  `notLinked`, `error`). `linkHealthService()` / `unlinkHealthService()` request/clear permissions.
- `health_data_service.dart` — wraps the `health` package for actually reading samples.
- `not_linked_view.dart` — the permission-request CTA.
- `user_health_section/`, `activity_data_section/`, `achievements_section/` — the 3 subtabs.
- `model/` — freezed models: `user_health_link`, `daily_health_summary`, `activity_health_metrics`,
  `hr_sample` (all generated; edit source + build_runner).

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
  that re-verification.
- `_health.configure()` throws on the iOS simulator (no HealthKit) — handle/expect failure there;
  test on a real device.
- The tab's own `RefreshIndicator` invalidates `healthControllerProvider` to re-run the link check.
  The three subtabs (`user_health`, `activity_data`, `achievements`) currently render placeholder
  content and intentionally have no per-subtab pull-to-refresh — add it when they load real data.
- Identity via `currentUserIdProvider`; bail when null (guest/signed-out has no health link).
- `user_health_link.platform` is a `@JsonEnum`-style value (`HealthPlatform.dbValue`) — follow the
  DB-id-as-enum-value rule when extending it.
- Health data types requested are the `_healthDataTypes` const list in `health_controller.dart` —
  add to that list (and the OS entitlements/Info.plist) when you need a new metric.
- Backend writes keep the `.timeout(const Duration(seconds: 5))`.
