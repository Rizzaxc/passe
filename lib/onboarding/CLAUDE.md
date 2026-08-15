# Onboarding — post-signup guide

Read the root [`CLAUDE.md`](../../CLAUDE.md) first. This file covers the onboarding flow specifics.

## Flow

Two phases:

1. **Blocking gate** (`onboarding_screen.dart`, route `/onboarding`) — `OnboardingFlowController`
   picks between two screens: a guest-only opt-in ask (`guest_opt_in_step.dart` — "want a quick
   look at how Passe works?") and the mandatory sport pick every feed depends on
   (`sport_step.dart`). A signed-up user always lands directly on the sport pick. Both of a guest's
   answers lead to the same sport pick next; the only thing the opt-in decides is whether the
   follow-up chain below runs later (accept) or is skipped entirely until they sign up (decline —
   `OnboardingStatus.guestDeclined`). `router.dart`'s `redirect` sends any user here until
   `OnboardingState.coreDone` (the sport pick, not the opt-in), then on to whichever tab
   `router.dart`'s `resolveInitialTabDestination` picks — Discover for a guest, otherwise Feed or
   Manage depending on unread state (see `router.dart`'s own comments).
2. **Follow-up chain** (`follow_up.dart`'s `runOnboardingFollowUps`, fired once from
   `ScaffoldWithNavBar.initState` in `lib/main.dart`) — runs as sheets/overlays over the *real*,
   already sport-scoped shell, in order:
   `story_sheet.dart` (what Passe is) → `profile_sheet.dart` (signed-in only; gender/age/playtime/
   skill) → `coach_marks.dart` (bottom-nav feature tour) → `get_started_sheet.dart` (closing choice:
   **create a lobby with people you already know** as the hero action, plus find teammates / add a
   friend / hire a coach / connect a wearable as secondary tiles — see the "why a hero action" note
   below). Each step is gated on its own
   persisted flag (`onboarding_prefs.dart`), so the chain is idempotent and safe to re-invoke.
   `onboarding_step_badge.dart` is the shared "X/4" pill each step's header shows so the sequence
   reads as bounded rather than sheets popping up unannounced.
3. `get_started_sheet.dart` is deliberately the *last* step, after the coach-mark tour rather than
   before it: the tour is passive orientation ("here's what's in each tab"), the get-started sheet
   is the one *actionable* close — a new user's Feed (first tab) has no posts until they have
   friends or lobby-mates (see `lib/feed_tab/CLAUDE.md`), so ending on a label tour alone would
   land them on an empty screen with nothing prompted.
4. `maybeShowCoachMarks` bridges `TutorialCoachMark`'s `onFinish`/`onSkip` callbacks through a
   `Completer` so its returned `Future` resolves only once the tour actually finishes/is skipped
   (`.show()` itself returns `void`) — `follow_up.dart` awaits it so the get-started sheet appears
   right after, not while the tour overlay is still on screen.
5. **Why "create a lobby" is the hero action, not a tile:** every other option on the get-started
   sheet depends on someone else already being there — Discover-based teammate matching needs a
   nearby lobby, hiring a coach needs a professional to have signed up, adding a friend needs them
   to already have an account. On a freshly-launched, thin-liquidity app those can easily return
   empty (this app hit exactly that empty state live while testing the Teammates subtab). Creating a
   lobby with people the user already knows succeeds unconditionally regardless of local density, so
   it's styled as the prominent `_HeroAction` card in `get_started_sheet.dart` rather than another
   `FTile` — it's the one path onboarding can always deliver on. `Thuê HLV / trọng tài` stays a
   normal-weight secondary tile rather than a liquidity risk, since Neutrals supply (coaches/
   referees) is expected to be seeded ahead of user launch.

`_forceShowOnboarding` in `onboarding_controller.dart` (debug-only, `kDebugMode`-gated) replays the
whole guide on every launch for manual testing; off by default, opt in with
`flutter run --dart-define=FORCE_ONBOARDING=true`.

6. **The progress badges track real sub-progress, not a fixed macro step number.** Story sheet's
   badge is `currentPage + 1 / 3` (live with the `PageView`); the coach-mark tour's badge is
   `i + 1 / keys.length` per target — a badge that doesn't move while the content underneath it
   visibly changes reads as broken. Profile and get-started sheets have no internal sub-progress, so
   they keep a plain step-in-the-4-stage-sequence number.
7. **`get_started_sheet.dart`'s "Tìm đồng đội" tile opens straight into the filter sheet**, not a
   bare list — `DiscoverTeammateRoute(openFilter: true)` → `DiscoverTab` → `TeammateSubtab.openFilter`
   (guarded by the module-level `_autoFilterConsumed` latch in `teammate_section/main.dart` so
   revisiting the tab later doesn't reopen it). The filter sheet itself (`discover_tab/filter.dart`)
   shows a **one-time** single-target `TutorialCoachMark` over its confirm button ("tinh chỉnh tiêu
   chí tìm kiếm...") the very first time anyone ever opens it (persisted `FILTER_FIELDS_COACH_SEEN`
   flag, `_FilterCoachMarkPrefs`) — not gated to the onboarding entry point, since the hint is useful
   however a user first reaches the sheet. A per-field tour was tried first and dropped: every field
   here is a live interactive control (text field / dropdown), so tapping the target itself got
   captured by the field instead of advancing the tour — `enableOverlayTab: true` on the remaining
   target works around the same issue for the confirm button too, but a single hint sidesteps the
   whole class of problem. `hideSkip: true` — a single-target tour has nothing to skip *to*, any tap
   already finishes it, so a separate Skip button was redundant chrome. `paddingFocus: 4` (not the
   package default of 10) keeps the highlight tight around the button instead of spilling past its
   edges. Steering a new user to actually set their filter (especially location/
   schedule) before browsing also directly improves their odds of a real match on a thin-liquidity
   launch — see the "why a hero action" note above.

## Analytics — documented, not implemented

There is currently **no product-analytics instrumentation** anywhere in this flow (or the app) —
the persisted flags in `onboarding_prefs.dart` are local `SharedPreferences` only, never emitted
anywhere observable. Sentry only captures crashes. This means activation rate, time-to-
activation, and per-step drop-off cannot currently be measured.

Intended plan for when this is prioritized:
- **Activation event candidate**: first `friendship` accepted, first `lobby_member` join, or first
  `wall_post` — something plausibly correlated with a return visit, not just onboarding completion
  itself. Needs real cohort data to pick between these once events exist.
- **Step-boundary events**: emit at `completeCore`/`completeStory`/`completeProfile`/
  `completeCoachMarks`/`completeGetStarted` in `onboarding_controller.dart` — these are already the
  single choke points every step's completion passes through, so instrumentation slots in there
  without touching the UI layer.
- **Minimum viable version**: even without a full analytics vendor, a Supabase table insert
  (`onboarding_event(user_id, step, created_at)`) at each of the above points plus one for the
  activation event would be enough to build a funnel query.
