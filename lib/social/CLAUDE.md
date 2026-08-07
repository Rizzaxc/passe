# Social — friendship graph & user pages

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This folder is the cross-screen half of the
Friends & Feed feature; the Feed UI itself lives in
[`lib/feed_tab/`](../feed_tab/) and is documented in
[`lib/feed_tab/CLAUDE.md`](../feed_tab/CLAUDE.md).

## Purpose

Person-to-person relationships, and the only page in the app that shows **another** user.
Before this existed there was no `/user/:id` route at all and no way to connect two people —
`lobby_befriend_record`'s `pair` interaction was written in SQL but never sent by any client.

## Files

- `friendship_controller.dart` — `FriendshipController` (`friend_data` RPC → `List<FriendUser>`),
  plus derived `friendsProvider` / `incomingFriendRequestsProvider`. Mutations go through the
  `send_friend_request` / `respond_friend_request` / `unfriend` / `block_user` / `unblock_user`
  RPCs, never direct table writes.
- `user_page.dart` + `user_page_controller.dart` — the `/user/:id` page (`UserRoute`): identity,
  the relationship CTA, and their read-only profile overview.
- `profile_overview_tab.dart` + `user_profile_detail_controller.dart` — the read-only overview
  section on `/user/:id`: general info (from `user_page_controller.dart`'s `UserProfile.details`,
  already carried by `user_profile_data`), plus networks/industries/the current context sport's
  profile (`userProfileDetailProvider`, three queries mirroring what `lib/profile_tab/`'s own
  self-editing controllers already run, just parameterized by the viewed `userId` instead of
  `auth.uid()` — all three tables are `USING (true)` readable, no new RPC needed). No wall/post
  browsing here — that was tried and dropped as not useful for a first pass.
- `friends_screen.dart` — `FriendsScreen`, the friends hub (open requests + friend list +
  username#tag search). Pushed as a full page (`Navigator.push(MaterialPageRoute(...))`) from the
  Profile tab (below Industry & Network) and from the Feed tab's empty-state "Tìm bạn bè" CTA —
  **not** a `showPSheet` bottom sheet, styled after `profile_tab/network_selection_screen.dart`
  (`FScaffold` + `FHeader` with `FHeaderAction.back` in `suffixes`). The search query is the same
  shape as `invite_member_sheet.dart:66`. Search is a plain `PSearchField` (no submit button) —
  `_onQueryChanged` debounces via its own 1s `Timer`, distinct from `PSearchField`'s own internal
  300ms debounce (which only applies in its typeahead/`suggestionsBuilder` mode; unused here since
  results render inline as `FTileGroup` rows, not an overlay dropdown).
- `block_report_sheet.dart` — unfriend / block / unblock actions on a person.

## Domain

- **Friendship is mutual** (`friendship` table, `pending → accepted`). A canonical
  `least/greatest` unique index means there is at most one live edge per unordered pair;
  `send_friend_request` turns a reciprocal request into an immediate accept rather than a second
  edge, mirroring the `lobby_befriend_record` auto-accept trigger.
- **`pair` is retired.** `schema/friendship.sql` installs a BEFORE INSERT trigger on
  `lobby_befriend_record` that rejects `interaction_type = 'pair'` and cancels pending ones. The
  enum value stays (accepted rows already produced real lobbies). `lobby_invite_response_controller.dart`
  reads `invite` only.
- **Blocking is symmetric in effect**: `block_user` severs any live friendship in the same call,
  and `fn_is_blocked` hides each party from the other everywhere the wall-post visibility
  predicate is used.

## Gotchas

- `user.tag_number` is **`varchar(4)`, not an integer** — every RPC returning it casts to `text`,
  and the Dart models hold a `String`. Getting this wrong fails at runtime, not compile time.
- Identity comes from `currentUserIdProvider` / `authControllerProvider`; guests get a disabled
  friend CTA rather than a button that throws (`send_friend_request` requires an authenticated uid).
- The friend CTA fires the notification **soft-ask** (`maybePromptAndRegister`) after the first
  successful request — never a cold OS prompt.
- `PUserAvatar` (`lib/ui/user_avatar.dart`) is the shared avatar. It is deliberately **not**
  cache-busted, unlike the profile tab's own avatar: a `?t=<millis>` changes the URL every build,
  which would defeat the disk and CDN cache for every avatar in a feed.
- All RPCs carry `.timeout(const Duration(seconds: 5))`.
- The Profile tab's Friends badge (`incomingFriendRequestsProvider`) is still the only place to
  *act* on a pending request. The notification centre (`/notifications`) also lists `friend_request`
  / `friend_accepted` events, but only as passive history — it doesn't replace this badge.
