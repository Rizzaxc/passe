# Manage Tab — schedule, lobbies, coaching

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This file covers the manage screen specifics.

## Purpose

Where users run the things they belong to: their calendar, their **lobbies** (parties), and their
coaching courses. Unlike Home (discovery), this is about entities the user is already a member of.

## Layout

- `main.dart` — `ManageTab`: `FScaffold` + `FTabs` over 3 subtabs (`schedule`, `lobby`, `coaching`).
  `ManageTab.withInitialTab(0|1)` deep-links schedule/lobby (see `Manage*Route` in `router.dart`).
- `schedule_section/main.dart` — calendar view of the user's activities. Uses `lib/ui/calendar.dart`.
- `coaching_section/main.dart` — ongoing courses with a coach.
- `lobby_section/` — the bulk of this tab:
  - `feed/main.dart` — `LobbySubtab`: the list of the user's lobbies (`userLobbiesControllerProvider`)
    — a direct `lobby` query filtered by the **context sport** (`sport_id == Sport.index`) and an
    inner join on `lobby_member` for the current user, plus a per-lobby member count. `+` opens
    `lobby_form_sheet.dart` to create a lobby (`create_lobby_with_location` RPC). Captain marked with
    a crown.
  - `lobby_detail_page.dart` + `lobby_detail_controller.dart` — the pushed `LobbyDetailRoute`
    (`/manage/lobby/:id`). Loads one `lobby` row joined to `location(name)`.
  - `members/` — roster management (`lobby_member` table).
  - `activity/` — propose / confirm play sessions; `feed`, `upcoming`, `hero`, `trigger_bar`,
    `confirmation_controller`. The activity feed is the `lobby_feed_data` RPC (keyed `p_lobby_id`);
    confirmation state comes from `activity` / `activity_confirmation` tables and the
    `activity_confirmation_status` RPC.
  - `history/` — past matches (`lobby_match_history_data` RPC), `match.dart` / `view.dart`.
  - `invite_challenge_sheet.dart`, `schedule_activity_sheet.dart`, `lobby_info_sheet.dart`,
    `lobby_banner.dart` — sheets/widgets pushed from the detail page.

## Domain model

- **Lobby** = a party of players. `Lobby` is a freezed model in `core/model/lobby.dart`
  (`captainId`, `searchableId`, `name`, `visibility`, …). `core/model/activity.dart` is the activity
  model. Both are generated — edit the source, run build_runner.
- **Captain** is the lobby owner: `lobby.captainId == currentUserId`. Captain-only actions
  (schedule activity, edit lobby, manage members) gate on `isLeader`. A captain cannot leave their
  own lobby (`lobby_member_prevent_captain_leave` trigger).
- **Activity lifecycle**: any member proposes a session → captain can veto/edit → once enough members
  confirm it becomes official. Confirming costs **đá** (see the `lib/currency/` controller). The đá
  ledger is not yet in the DB — currency is currently a local SharedPreferences int.

## Gotchas

- Read identity via `currentUserIdProvider` / `authControllerProvider.value?.id` — the `_LobbyCard`
  uses the latter to compute `isLeader`.
- The lobby list surfaces errors through a `ref.listen(... AsyncError ...)` → `showFToast`, not an
  inline error widget. The empty state uses `PEmptySectionPlaceholder`.
- `lobby.searchableId` (a `nanoid`) is the human-shareable lobby code, copied to clipboard from the
  card — distinct from the UUID `lobby.id` used in routes.
- Navigate to detail with `LobbyDetailRoute(id: lobby.id!, $extra: lobby.name).go(context)` — passing
  the name via `$extra` lets the page show a title before the row loads.
- Several action buttons are still placeholders (`onPress: null` or a `TODO` toast): add-member,
  the captain's schedule-activity shortcut on the card. Wire these, don't assume they work.
- All RPCs/queries keep the `.timeout(const Duration(seconds: 5))`.
