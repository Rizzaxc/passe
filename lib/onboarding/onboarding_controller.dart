import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../core/model/enum.dart';
import '../core/model/user_avatar.dart';
import '../core/state/selected_sport_state.dart';
import 'onboarding_prefs.dart';

part 'onboarding_controller.g.dart';

/// DEBUG-ONLY: forces the onboarding guide to run on every app launch,
/// ignoring persisted completion, so it can be clicked through repeatedly
/// while testing without reinstalling or clearing app storage. Guarded by
/// `kDebugMode` so it can never affect a release build even if left on, and
/// off by default so a plain `flutter run` sees real persisted state — opt
/// in with `flutter run --dart-define=FORCE_ONBOARDING=true`.
const _forceShowOnboarding = bool.fromEnvironment('FORCE_ONBOARDING');

/// Tracks whether the force-override above has already fired once in this
/// process. `build()` re-runs every time `authControllerProvider` changes —
/// including the auth refresh a profile-sheet save triggers mid-flow — and
/// without this latch *every* one of those rebuilds would re-report "not
/// done", bouncing the user back to `/onboarding` after every save instead
/// of just once on cold start. Resets on relaunch/hot restart (a fresh
/// process), which is exactly when "show every launch" should re-apply.
bool _debugForceConsumed = false;

/// Persisted onboarding status — the single source of truth `router.dart`'s
/// `redirect` gates on (`coreDone`) and the shell's coach-mark pass consumes
/// (`coachMarksDone`). See `onboarding_prefs.dart` for the underlying keys.
@riverpod
class OnboardingState extends _$OnboardingState {
  @override
  FutureOr<OnboardingStatus> build() async {
    // Re-read under the right namespace whenever identity changes (guest ->
    // signed-up, sign-out, account switch).
    ref.watch(authControllerProvider);

    if (kDebugMode && _forceShowOnboarding && !_debugForceConsumed) {
      _debugForceConsumed = true;
      return (
        coreDone: false,
        storyDone: false,
        profileDone: false,
        coachMarksDone: false,
        getStartedDone: false,
        guestDeclined: false,
      );
    }

    await OnboardingPrefs.bridgeGuestFlagsToCurrentUser();
    var status = await OnboardingPrefs.read();

    // Self-heal: `coreDone` can be `true` with no real sport ever actually
    // persisted for this namespace — e.g. a stale `true` bridged in from
    // the shared 'guest' bucket above, from before `readStoredSportId`
    // existed (see its doc comment) or from any other source of the same
    // shape of corruption. Don't trust it: fall through to the lazy
    // migration below, which will either restore a real sport (and only
    // then re-mark done) or correctly send the user through the one-screen
    // sport pick instead of leaving them stuck on `Sport.others` forever
    // with no route back into onboarding to fix it.
    if (status.coreDone &&
        await OnboardingPrefs.readStoredSportId() == Sport.others.index) {
      status = (
        coreDone: false,
        storyDone: status.storyDone,
        profileDone: status.profileDone,
        coachMarksDone: status.coachMarksDone,
        getStartedDone: status.getStartedDone,
        guestDeclined: status.guestDeclined,
      );
    }

    // Lazy migration: pre-existing installs (from before this flow existed)
    // have no ONBOARDING_COMPLETED flag but already have a real context
    // sport — treat them as done rather than showing the new flow. Reads
    // the pref straight off disk (`OnboardingPrefs.readStoredSportId`)
    // rather than through `selectedSportStateProvider` — that provider's
    // Riverpod cache isn't tied to auth identity and can go stale across a
    // sign-out (see the doc comment on `readStoredSportId`), which used to
    // let this block write a false "already onboarded" flag into the wrong
    // namespace during the sign-out transition itself.
    //
    // `authControllerProvider` can re-emit (and thus restart this build())
    // several times in quick succession during app startup, so this
    // in-flight execution may resume each `await` after the provider itself
    // has already been superseded/disposed — guard with `ref.mounted`
    // before touching `ref` again, matching the convention in
    // sport_profile_controller.dart's `commit()`.
    if (!status.coreDone && ref.mounted) {
      final storedSportId = await OnboardingPrefs.readStoredSportId();
      var alreadySetUp = storedSportId != Sport.others.index;

      // A returning (non-guest) account signing in on a fresh install/new
      // phone has no local flags at all — not even a bridged guest one (see
      // onboarding_prefs.dart) — and `selectedSportStateProvider` defaults
      // to `Sport.others` on a fresh install same as every other local pref,
      // so the check above alone would wrongly send an already-onboarded
      // user through the whole tour again. Fall back to server-side
      // evidence this account already completed setup elsewhere: a stated
      // gender, a custom (non-generated) avatar, or a seeded sport profile.
      //
      // Only the seeded-sport-profile signal can also say *which* sport to
      // restore, and the sport pick is mandatory — every feed bails out on
      // `Sport.others` — so it's queried unconditionally here (not only
      // when gender/avatar are unset): finding a seeded sport is what makes
      // it safe to skip the picker screen too, not just the guide around
      // it. Marking `coreDone` without a real sport to put back would
      // strand the user on a permanently empty app with no route back to
      // the picker (onboarding would no longer be reachable to fix it).
      if (!alreadySetUp && ref.mounted) {
        final user = ref.read(authControllerProvider).value;
        final userId = user?.id;
        if (user != null && !user.isGuest && userId != null) {
          final hasGender = user.details?.gender != null;
          final hasCustomAvatar = user.details?.avatar is PhotoAvatar;
          final seededSportId =
              (await Supabase.instance.client
                          .rpc('seeded_sport_id', params: {'p_user_id': userId})
                          .timeout(const Duration(seconds: 5))
                      as num?)
                  ?.toInt();

          if (seededSportId != null && ref.mounted) {
            ref
                .read(selectedSportStateProvider.notifier)
                .change(Sport.values[seededSportId]);
            alreadySetUp = true;
          } else if ((hasGender || hasCustomAvatar) && ref.mounted) {
            // Old-account evidence, but no sport to restore — skip the rest
            // of the guide (story/profile-nudge/coach-marks/get-started)
            // while still routing through the one-screen sport pick itself,
            // rather than leaving the context sport unset.
            await OnboardingPrefs.markStoryDone();
            await OnboardingPrefs.markProfileDone();
            await OnboardingPrefs.markCoachMarksDone();
            await OnboardingPrefs.markGetStartedDone();
            if (ref.mounted) {
              status = (
                coreDone: status.coreDone,
                storyDone: true,
                profileDone: true,
                coachMarksDone: true,
                getStartedDone: true,
                guestDeclined: status.guestDeclined,
              );
            }
          }
        }
      }

      if (ref.mounted && alreadySetUp) {
        await OnboardingPrefs.markCoreDone();
        // A pre-existing install also never had a story sheet/profile
        // nudge/coach-mark pass, but showing those retroactively to an
        // established user would be intrusive, not helpful — treat the
        // whole thing as done, not just the sport gate.
        await OnboardingPrefs.markStoryDone();
        await OnboardingPrefs.markProfileDone();
        await OnboardingPrefs.markCoachMarksDone();
        await OnboardingPrefs.markGetStartedDone();
        status = (
          coreDone: true,
          storyDone: true,
          profileDone: true,
          coachMarksDone: true,
          getStartedDone: true,
          guestDeclined: status.guestDeclined,
        );
      }
    }

    return status;
  }

  Future<void> completeCore() async {
    await OnboardingPrefs.markCoreDone();
    if (!ref.mounted) return;
    final current = state.value;
    state = AsyncData((
      coreDone: true,
      storyDone: current?.storyDone ?? false,
      profileDone: current?.profileDone ?? false,
      coachMarksDone: current?.coachMarksDone ?? false,
      getStartedDone: current?.getStartedDone ?? false,
      guestDeclined: current?.guestDeclined ?? false,
    ));
  }

  Future<void> completeStory() async {
    await OnboardingPrefs.markStoryDone();
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData((
      coreDone: current.coreDone,
      storyDone: true,
      profileDone: current.profileDone,
      coachMarksDone: current.coachMarksDone,
      getStartedDone: current.getStartedDone,
      guestDeclined: current.guestDeclined,
    ));
  }

  Future<void> completeProfile() async {
    await OnboardingPrefs.markProfileDone();
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData((
      coreDone: current.coreDone,
      storyDone: current.storyDone,
      profileDone: true,
      coachMarksDone: current.coachMarksDone,
      getStartedDone: current.getStartedDone,
      guestDeclined: current.guestDeclined,
    ));
  }

  Future<void> completeCoachMarks() async {
    await OnboardingPrefs.markCoachMarksDone();
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData((
      coreDone: current.coreDone,
      storyDone: current.storyDone,
      profileDone: current.profileDone,
      coachMarksDone: true,
      getStartedDone: current.getStartedDone,
      guestDeclined: current.guestDeclined,
    ));
  }

  Future<void> completeGetStarted() async {
    await OnboardingPrefs.markGetStartedDone();
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData((
      coreDone: current.coreDone,
      storyDone: current.storyDone,
      profileDone: current.profileDone,
      coachMarksDone: current.coachMarksDone,
      getStartedDone: true,
      guestDeclined: current.guestDeclined,
    ));
  }

  Future<void> declineAsGuest() async {
    await OnboardingPrefs.markGuestDeclined();
    if (!ref.mounted) return;
    final current = state.value;
    state = AsyncData((
      coreDone: current?.coreDone ?? false,
      storyDone: current?.storyDone ?? false,
      profileDone: current?.profileDone ?? false,
      coachMarksDone: current?.coachMarksDone ?? false,
      getStartedDone: current?.getStartedDone ?? false,
      guestDeclined: true,
    ));
  }
}

/// In-flight step cursor for [OnboardingScreen] — the two screens that must
/// block entry to the app (a guest's opt-in question, and the mandatory
/// sport pick every feed depends on). Not persisted — a killed app just
/// restarts at the beginning (the router redirects back to `/onboarding`
/// since [OnboardingState]'s `coreDone` is still false). The rest of the
/// guide (story, profile, feature intro, get-started choices) runs *after*
/// this, as sheets/coach-marks layered over the real shell — see
/// `follow_up.dart`.
enum OnboardingStep { guestOptIn, sport }

@riverpod
class OnboardingFlowController extends _$OnboardingFlowController {
  @override
  OnboardingStep build() {
    final isGuest = ref.watch(authControllerProvider).value?.isGuest ?? true;
    final guestDeclined =
        ref.watch(onboardingStateProvider).value?.guestDeclined ?? false;
    // A guest who already declined shouldn't normally reach this route again
    // (the router stops gating them), but fall through to `sport` rather
    // than re-showing the opt-in prompt if they somehow do.
    return (isGuest && !guestDeclined)
        ? OnboardingStep.guestOptIn
        : OnboardingStep.sport;
  }

  void goTo(OnboardingStep step) => state = step;
}
