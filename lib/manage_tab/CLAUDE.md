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
  - `activity/` — captain schedules, members confirm/react; `feed`, `upcoming_controller`, `hero`,
    `trigger_bar`, `confirmation_controller`, `poll_sheet`. The activity feed is the `lobby_feed_data`
    RPC (keyed `p_lobby_id`); confirmation state comes from `activity` / `activity_confirmation` tables
    and the `activity_confirmation_status` RPC.
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
- **Activity lifecycle, as actually built** (the "member proposes → captain vetoes/edits" flow described
  at the root `CLAUDE.md` was never implemented): scheduling is **captain-only** end to end —
  `schedule_activity_controller.dart`'s `schedule`/`reschedule`/`cancel` all insert/update/delete the
  `activity` row as the captain. Confirming costs **đá** (see the `lib/currency/` controller); the đá
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
- All RPCs/queries keep the `.timeout(const Duration(seconds: 5))`.
- **`activity` RLS is owner-scoped, not member-scoped** — `schema/activity_member_visibility.sql` adds
  a lobby-member SELECT policy on top of the pre-existing owner-only SELECT/UPDATE/DELETE. If you add
  a new direct `.from('activity')` read, make sure it's a lobby member doing the reading, not just the
  captain, or you'll silently get zero rows for everyone else (this was the likely root cause of the
  hero card being hardcoded in the first place — see "Known assumptions" below).

## Known assumptions (2026-07, activity screen pass)

A pass removed the hardcoded/mock UI in the activity tab (fake dates, fake location, fake RSVP
avatars, decoy buttons that did nothing) and wired the real functionality it was standing in for.
Judgment calls made along the way, in case they need revisiting:

- **RLS fix**: `schema/activity_member_visibility.sql` adds "lobby members can SELECT their lobby's
  activities". Before this, only the captain (the row's `user_id`) could see it at all — every other
  member's hero card / upcoming-activity query silently returned nothing. **This migration needs to be
  applied to the live Supabase project** (schema files here are dumped for review, not auto-applied).
- **Countdown/date/time/location** on the hero card now come from `upcoming_controller.dart`'s
  `UpcomingActivity` (extended with a `location(name, district)` join + the prepayment/confirmation
  columns that used to be fetched then thrown away by `_stripExtras`). The old mock also showed a
  pitch/court-number and match-format tag ("Sân 3", "Đôi nam nữ") — there's no such column on
  `activity`, so those are just gone rather than faked; only a prepayment tag shows now, and only when
  `prepayment_required` is true.
- **RSVP avatar strip** (`_RsvpAvatarRow`) now queries a small sample of `activity_confirmation` rows
  (new `activityAttendeesProvider` in `confirmation_controller.dart`) instead of 5 hardcoded
  letter/color pairs. It's capped at 6 rows and not paginated — fine for a decorative strip, not meant
  to enumerate everyone.
- **"Chỉ Đường" (directions)** copies the address to the clipboard instead of opening an external maps
  app — there's no `url_launcher` (or similar) dependency in `pubspec.yaml` yet, and adding one felt
  like a bigger call than this pass should make unilaterally. Swap in a real maps deep-link once that
  dependency lands.
- **"Đổi Giờ" / reschedule**: `schedule_activity_sheet.dart` now takes an optional `existing:
  UpcomingActivity` and calls a new `ScheduleActivityController.reschedule()` (UPDATE + a
  `rescheduled` feed item) instead of `schedule()` (INSERT). The confirmation-deadline toggle still
  only supports the fixed "2 days before start" default (same as a fresh schedule) — editing an
  activity whose deadline was ever set to something else would normalise it back to that default on
  save. There's no arbitrary custom-deadline picker in this sheet at all, so this isn't a regression,
  just a pre-existing limitation now also reachable via edit.
- **Cancel** (the hero's "…" overflow, captain-only) deletes the `activity` row and posts an `update`
  feed item with a new `UpdateKind.cancelled`. There's no soft-cancel / undo.
- **Poll**: moved from the "any member" picker section to "captain-only" — RLS
  (`"Captain can post updates and polls"`) already only allowed the captain to insert `kind = 'poll'`
  items; the picker's old grouping just didn't match that. `poll_sheet.dart` is a new minimal
  create-poll form (question + 2–4 options); `total_members` is the current roster count and
  `deadline` is a fixed "Trong 24 giờ" label — there's no real poll-deadline scheduling. Voting
  (`_PollCardState` in `activity/feed.dart`) now upserts into `lobby_feed_poll_vote` and re-derives
  tallies from `lobby_feed_data` (extended with a `my_vote` column — see
  `schema/lobby_feed_poll_my_vote.sql`) instead of faking the count with local `setState`.
- **Photo** action was removed from the picker rather than wired — posting `kind: 'photo'` needs an
  actual uploaded file (a storage bucket + storage RLS policies that don't currently exist), which is
  a bigger unit of infra than this pass covers. Left as a gap rather than a decoy tile.
- **"Book coach" (bookCoach)** navigates to the general Neutrals/professional discovery tab
  (`HomeProfessionalRoute`) — there's no lobby-scoped "book a coach for this session, auto-linked to
  the activity" flow built yet.
- **System feed items removed, not wired**: `SystemItem.hasApprove` (in-feed "Đồng Ý"/"Từ Chối" on a
  join-request card) had no producer anywhere — RLS doesn't even allow a client `INSERT` of
  `kind = 'system'`, and no trigger creates one either — so it was unreachable dead UI, not a stub
  worth wiring. If an in-feed approve/reject affordance is wanted later, it needs a new
  `SECURITY DEFINER` trigger on `lobby_befriend_record` inserting the system item (with the record id
  embedded in the payload so the buttons know what to act on) — the working equivalent today is the
  "Manage Requests" flow in `lobby_info_sheet.dart` / `join_requests_sheet.dart`.
- **`UpdateItem.ctaLabel`** was removed the same way — nothing ever set `cta_label` in any payload, so
  the button was permanently inert.
- **Personal quick-actions** (8 of them, plus the empty-state "remind captain") now post real
  `lobby_feed_item(kind: 'personal')` rows via `LobbyFeedController.postPersonalAction` — one-tap, no
  optional "detail" text capture (the DB payload does support a free-text `detail` field; the picker
  just doesn't collect it yet).
- **Dead code removed**: `lobby_section/upcoming/` (an unreferenced, superseded duplicate of
  `activity/upcoming_controller.dart` + the hero) and
  `feed/lobby_card_activity_slot.dart` (also unreferenced anywhere) were deleted rather than fixed.
- **Manage▸Lobby list card's "no activity" text** was previously always shown regardless of truth —
  `LobbyListItem.nextActivity` was declared but never populated. `lobby_controller.dart` now batches a
  soonest-`start_time`-per-lobby query, but deliberately does **not** resolve recurring series to their
  next virtual occurrence (that math lives in `upcoming_controller.dart`'s `_nextOccurrence` and felt
  like too much for a list card) — a lobby with only a recurring series and no upcoming one-off row
  still shows "no activity" on the list, even though its detail page's hero would show the recurring
  session correctly.
