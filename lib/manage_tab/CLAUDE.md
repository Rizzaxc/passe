# Manage Tab — schedule, lobbies, coaching

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This file covers the manage screen specifics.

## Purpose

Where users run the things they belong to: their calendar, their **lobbies** (parties), and their
coaching courses. Unlike Home (discovery), this is about entities the user is already a member of.

## Layout

- `main.dart` — `ManageTab`: `FScaffold` + `FTabs` over 3 player subtabs (`lobby`, `schedule`,
  `course`). `ManageTab.withInitialTab(0|1|2)` deep-links lobby/schedule/course (see `Manage*Route`
  in `router.dart`).
- `schedule_section/main.dart` — calendar view of the user's activities. Uses `lib/ui/calendar.dart`.
- Index 2 is **courses**, and it lives in [`lib/course/`](../course/), not here — the same code
  serves both sides of the relationship (`CourseHubSection` for a student, `ProCoursesSection` for a
  coach in pro mode), so it isn't manage-tab-specific. `coaching_section/` is **deleted**: it read
  `professional_booking` rows and grouped them by coach to look like courses.
- **Pro mode branches by role.** A coach gets `[courses, schedule, history]`; a referee gets
  `[requests, schedule, history]` over `referee_booking`, and every referee entry point is gated
  behind `ClientFeatureFlags.refereeFlow`. `ManageCourseRoute` is the mode-aware deep-link target for
  course notifications: it selects player index 2 or coach index 0 and exits host/referee mode when
  the destination must be the player's course hub.
- **Host mode follows the same primary-first contract:** `[open listings, schedule]`. Its schedule
  reuses the player calendar's timeline/card views and routes each card to the freeplay detail page.
  Hosted activities are bucketed independently, so simultaneous sessions render side by side rather
  than one hiding another.
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
  - `history/` — past matches (`lobby_match_history_data` RPC, now both-sided — see root CLAUDE.md ▸
    Challenger System), `match.dart` / `view.dart`.
  - `challenge_offer_sheet.dart` / `challenge_offer_controller.dart` — the "Nhận Thách Đấu" opt-in
    offer (when/where/cost), `schedule_activity_sheet.dart`, `lobby_info_sheet.dart`,
    `lobby_banner.dart` — sheets/widgets pushed from the detail page. (`invite_challenge_sheet.dart`
    is **retired** — challenging by SearchID from inside your own lobby bypassed the offer/matching
    system; see root CLAUDE.md ▸ Challenger System.)
  - `invite_link/` — the Discord-style lobby invite link (replaced the retired email-invite flow,
    `invite_member_sheet.dart`'s email mode). `invite_link_controller.dart` +
    `invite_link_card.dart` are the captain/coordinator-only generate/copy/share/regenerate/remove
    card embedded in `lobby_info_sheet.dart`, next to the SearchID row. `invite_landing_controller.dart`
    + `invite_landing_page.dart` back the `/invite/:code` route (`InviteRoute` in `router.dart`) that
    verified `https://passe.vn/invite/CODE` link opens. Android App Links are registered in
    `android/app/src/main/AndroidManifest.xml`; iOS Universal Links use the Runner entitlements.
    The association documents and browser fallback live in the root `website/` Astro project. No
    extra deep-link package is needed: Flutter's native Router integration passes the HTTPS path to
    the existing `InviteRoute`, so normal auth/onboarding gating still applies. Redemption is
    instant auto-join (`redeem_lobby_invite_link`, `SECURITY DEFINER`) — no approval step, unlike a
    `lobby_befriend_record` join request. Guests hit the existing `ensureSignedIn` prompt
    (`lib/auth/guest_prompt.dart`); the router's own `pendingDestination` bookkeeping already bounces
    them back to `/invite/CODE` after sign-in, so there's no separate pending-state provider. Schema:
    `schema/lobby_invite_link.sql`.

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
- **RSVP lock-in**: once an activity is `activity_confirmed` (enough `going` RSVPs to clear
  `confirmation_threshold`, or no threshold at all), a member whose row is already `going` can no
  longer change or retract it — enforced at the DB via RLS
  (`schema/activity_confirmation_lock_after_confirmed.sql`, tightening both the UPDATE and DELETE
  policies on `activity_confirmation`) so it holds regardless of client. `activity_card.dart`'s
  `_RsvpControl` mirrors this client-side (`locked` prop, padlock icon on the active pill) to avoid a
  round-trip just to show a rejection. Members who are `maybe`/`out`/unresponsive are unaffected and
  can still RSVP (including flipping to `going`) after confirmation.
- **`LobbyFeedController` mutations called from outside the Feed subtab need `ref.keepAlive()`.**
  The Feed tab (`LobbyFeedTab` in `activity/main.dart`) and the Planner tab (activity cards) are
  separate subtabs now — only one is mounted at a time — but Planner-side actions
  (`activity_card.dart`'s "Đến Muộn"/late and "Đòi Tiền"/payment-request quick actions,
  `planner_empty_state.dart`'s "remind captain") call mutations on `lobbyFeedControllerProvider` via
  a bare `ref.read(...).notifier`, same as `ScheduleActivityController.cancel()`'s documented hazard.
  Without `ref.keepAlive()`, the autoDispose provider can get disposed the instant the mutation
  yields (at `ref.invalidateSelf()`), so the trailing `await future` throws on a disposed Ref *after*
  the write already landed — surfacing as a spurious error toast on top of a feed item that did post
  successfully. `postPersonalAction` and `createAncillaryPaymentRequest` both wrap their body in
  `ref.keepAlive()` for this reason; `vote`/`markPaymentRequestPaid` don't need it because their only
  callers live inside `feed.dart`'s list items, which only exist while `LobbyFeedTab` itself is
  watching the provider.
- **Confirmation deadline wasn't rendered anywhere** — `schedule_activity_sheet.dart` writes
  `activity.confirmation_deadline`, but no card ever displayed it back. `activity_card.dart` now
  shows a "Hạn xác nhận …" tag (next to the cost tag, same `_Tag` row) whenever
  `upcoming.confirmationDeadline` is set. Purely informational — nothing currently freezes RSVP once
  the deadline itself passes (that's separate from the threshold-based lock-in above).

## Gotchas

- Read identity via `currentUserIdProvider` / `authControllerProvider.value?.id` — the `_LobbyCard`
  uses the latter to compute `isLeader`.
- The lobby list surfaces errors through a `ref.listen(... AsyncError ...)` → `showFToast`, not an
  inline error widget. The empty state uses `PEmptySectionPlaceholder`.
- `lobby.searchableId` (a `nanoid`) is the human-shareable lobby code, copied to clipboard from the
  lobby info sheet — distinct from the UUID `lobby.id` used in routes. The list card uses that former
  copy shortcut for scheduling instead: every member lands on Planner, while captains/coordinators
  also open the activity planner sheet after `LobbyPermission.canManage` resolves true.
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
  `UpcomingActivity` (extended with a `location(name, district)` join + the cost/confirmation
  columns that used to be fetched then thrown away by `_stripExtras`). The old mock also showed a
  pitch/court-number and match-format tag ("Sân 3", "Đôi nam nữ") — there's no such column on
  `activity`, so those are just gone rather than faked; only a cost tag shows now, and only when
  `cost_type`/`cost_amount` are set. **(2026-08 pass)** the old pre-session `prepayment_required`/
  `payment_type`/`prepayment_amount` deposit model (and its dead `'da'` branch — đá was never wired)
  is gone; `cost_type` (`per_pax`/`total`) + `cost_amount` are purely informational at scheduling
  time, and money actually changes hands post-session via the payment-request feature (chia tiền /
  đòi tiền trà đá — see root CLAUDE.md).
- **RSVP avatar strip** (`_RsvpAvatarRow`) now queries a small sample of `activity_confirmation` rows
  (new `activityAttendeesProvider` in `confirmation_controller.dart`) instead of 5 hardcoded
  letter/color pairs. It's capped at 6 rows and not paginated — fine for a decorative strip, not meant
  to enumerate everyone.
- **"Chỉ Đường" (directions)** copies the address to the clipboard instead of opening an external maps
  app — there's no `url_launcher` (or similar) dependency in `pubspec.yaml` yet, and adding one felt
  like a bigger call than this pass should make unilaterally. Swap in a real maps deep-link once that
  dependency lands.
- **"Thay Đổi" / reschedule**: `schedule_activity_sheet.dart` now takes an optional `existing:
  UpcomingActivity` and calls a new `ScheduleActivityController.reschedule()` (UPDATE + a
  `rescheduled` feed item) instead of `schedule()` (INSERT). **(2026-08 update)** the confirmation
  deadline is no longer a fixed "2 days before start" toggle — the organizer picks the lead time
  (2–72h before kickoff) with a slider (`_DeadlineLeadSlider`), clamped so it can never land in the
  past (the slider's usable max shrinks to however many hours actually remain until start once
  that's under 72h). Editing an activity re-derives the current lead from
  `start - existing.confirmationDeadline` so the slider seeds where the captain last left it, not a
  hardcoded default. **(2026-08 pass)** the quick-action row's separate "Đổi Giờ" (change time) and
  "Thêm Địa Điểm" (add location, shown only when the activity had no location yet) buttons opened the
  exact same sheet — collapsed into a single leader-only "Thay Đổi" action that covers time,
  location, recurrence, cost, and confirmation together.
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
- **Photo** action was removed from the picker rather than wired — posting `kind: 'photo'` needed a
  storage bucket + policies that didn't exist. **Now restored**, but not as a lobby-only photo: the
  `photo` kind is retired as a *writable* kind, and `lobby_feed_data` instead unions in the
  `wall_post` rows attached to that lobby's activities (`schema/lobby_feed_wall_posts.sql`), which
  the feed renders with the shared `PostCard`. The picker's photo tile opens the wall composer
  scoped to this lobby. One source of truth — a post deleted or TTL-swept vanishes from the lobby
  feed at the same moment it vanishes everywhere else. The old `_PhotoCard` (which drew a *painted
  fake* court photo via `_CourtPhotoPainter`) is gone.
- **"Đặt HLV / Trọng tài" (bookCoach)** navigates to the general Neutrals/professional discovery tab
  (`HomeProfessionalRoute`) after stashing the upcoming activity id in `PendingActivityBookingState`.
  The next booking submitted attaches back to that activity — into `coach_booking_id` **or**
  `referee_booking_id` depending on the booked pro's **role** (never `professional_booking_id`, which
  `activity_source_exclusivity` forbids on a lobby activity). The attached pro then surfaces on the
  hero card (`_AttachedProRow`), name + booking status, tap → `ProfessionalDetailRoute`. Members other
  than the captain can read the attached booking via the "Lobby members can view attached bookings"
  RLS policy (`schema/activity_professional_attachment.sql` — this migration was applied to prod
  ad-hoc and had never been committed to the repo until the challenger-flow pass below; it's now
  checked in verbatim from the live schema). **Now wired end to end**: a challenge activity's hero
  prompts the home side to book a referee (`_ChallengeBlock` in `activity/hero.dart`); the referee
  records the result from pro mode via `record_challenge_match`, which inserts the `lobby_match` row
  with `opponent_lobby_id` **and** `referee_booking_id` set together (the CHECK requires exactly
  that pairing for a scored match) and fires the Elo trigger. The free-text manual "Ghi kết quả"
  entry point (formerly `history/record_match_controller.dart` / `record_match_sheet.dart`,
  captain/coordinator-only on the History tab) is **removed** — `record_challenge_match` via the
  referee is now the only write path into `lobby_match`; see root CLAUDE.md ▸ Challenger System.
  **(2026-08 pass)** that same "Lobby members can view attached bookings" policy on
  `professional_booking` and `activity`'s own "Linked professionals can view their attached
  activities" policy referenced each other's table directly — a mutual RLS recursion that made
  **every** `select` against `activity` or `professional_booking` throw `infinite recursion detected
  in policy for relation "activity"` (Postgres error `42P17`) for any authenticated user, silently
  500ing the Manage▸Lobby list/detail's `activity` lookups (surfacing client-side as an endless
  loading spinner — Riverpod auto-retrying a `build()` that fails every time) along with anything
  else touching those two tables (RSVP confirmations, referee/coach attachment reads). Fixed live and
  checked in as `schema/fix_activity_professional_booking_rls_recursion.sql`: the
  `professional_booking` policy's `activity` lookup now goes through a `SECURITY DEFINER` `plpgsql`
  function (`is_booking_attached_to_my_lobby_activity`) instead of an inline subquery, breaking the
  cycle the same way `get_my_lobby_ids()` already did for every *other* lobby-membership check
  (also converted from `language sql` to `plpgsql` in the same pass, matching Supabase's documented
  recursion-avoidance pattern, though that alone didn't fix this specific cycle).
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
