# Profile Tab — account & matchmaking preferences

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This file covers the profile screen specifics.

## Purpose

Account bookkeeping plus all the matchmaking inputs: general info (gender, age group, location,
playtime), network & industry, and per-sport profiles (skill/position/etc.). Most of this feeds the
compatibility scores used by the Home feeds.

## Layout

- `main.dart` — `ProfileTab`: a `SingleChildScrollView` of `FTileGroup` sections (avatar, account,
  general info, network/industry, sport) plus a single "commit" `FButton`. Guests get
  `GuestProfileView` instead.
- `profile_controller.dart` — three `@riverpod` controllers (draft/commit pattern):
  - `ProfileController` (`ProfileState`: username, `UserDetails`, networks, industries, pickedAvatar)
    — the editable draft; `commit()` writes `user.username` + `user.details` json, syncs networks &
    industries, handles avatar upload/removal, then refreshes `authControllerProvider`.
  - `NetworkController` / `IndustryController` — selected networks (≤5) / industries (≤2), each with
    its own `commit()` against `user_network` / `user_industry`.
  - `NetworkSearchController` — typeahead search via `search_networks_unaccent` RPC.
- Per-field push screens: `age_group_selection_screen`, `location_selection_screen`,
  `playtime_selection_screen`, `industry_selection_screen`, `network_selection_screen`,
  `change_username_screen`, `change_password_screen`.
- `sport_profile/` — the per-sport profile editor (`sport_profile_screen.dart` switches on the
  context sport to `SoccerProfileWidget` / `Basketball…` / `Badminton…` / `Tennis…` /
  `Pickleball…`, each with its own `*ProfileController`, backed by a `<sport>_profile` table). ELO is
  seeded via `elo_seed_field.dart` (`EloSeed` enum → `fn_seed_initial_elo`).

## Draft / commit pattern

The profile is edited as an in-memory **draft** and only persisted on the explicit commit button.
`ProfileController.updateDraft(...)` mutates fields; the commit button in `main.dart` runs
`ProfileController.commit()` **and** the relevant sport profile's `commit()` together via
`Future.wait`, then auth state refreshes so the rest of the app sees the new `UserDetails`.

## Data model

- `UserDetails` (freezed, `core/model/user_details.dart`): `gender`, `ageGroup`, `playtime`
  (`List<Timeslot>`), `location` (`UserLocation`), `avatar` (`UserAvatar?`). Persisted as the
  `details` jsonb column on the `user` table. **Editing this json schema requires a migration
  script** (see root guideline) — `avatar` is the one exception: its `@JsonKey(fromJson:
  toJson:)` wire-encodes to/from the same `generatedAvatar` string key the column already used
  (see Avatar handling below), so introducing it needed no migration.
- Enums (`core/model/enum.dart`) are `@JsonEnum`; `Industry.index` and `City.dbIndex` are DB ids —
  don't reorder.

## Avatar handling

`UserDetails.avatar` is a `UserAvatar?` sealed type (`core/model/user_avatar.dart`):
`GeneratedAvatar(seed)` → an `AvatarPlus` seed (procedural avatar); `PhotoAvatar()` → the user has
a **custom uploaded photo** in the `user_avatar` storage bucket at `<userId>.jpg` (loaded as a
cache-busted `NetworkImage`); `null` → unset, falls back to seeding off the username.
`UserAvatar.decode`/`.encode` wire-convert to/from the underlying `details ->> 'generatedAvatar'`
string (non-empty = seed, `''` = photo, absent = unset) — this is the *only* place that
string-sentinel convention should be handled; every typed consumer (`ProfileController`,
`profile_tab/main.dart`) works with `UserAvatar`, not the raw string. Read-only surfaces elsewhere
in the app (lobby member lists, feed authors, payment payees, etc.) still read the raw wire string
directly out of Supabase JSON — they never touch `UserDetails`, so they didn't need to change.
`pickedAvatar` (an `XFile` on `ProfileState`) is a not-yet-committed pick; `commit()` uploads it and
removes a stale custom photo, falling back to a generated seed if upload fails.

## Gotchas

- **Guests can't edit** — `ProfileTab` shows `GuestProfileView` (which also embeds the password-reset
  entry point). Guard new features on `user == null || user.isGuest`.
- Network is capped at **5 selections**, industry at **2 selections** — the toggle logic in each
  controller enforces its own cap; respect it.
- Username identity is `username#tagNumber`; uniqueness is on the *(username, tag_number)* pair.
  `changeUsername` races against a DB unique constraint and throws `UsernameTakenException`.
- Sport profiles only exist for the 5 real sports; `Sport.others` renders nothing and commits a
  no-op `Future.value()`.
- All Supabase calls keep the `.timeout(const Duration(seconds: 5))`; password change is an
  `auth.updateUser` (not a table write).
