import '../core/user_preferences.dart';

/// Persisted onboarding flags, namespaced per user (or the shared `'guest'`
/// namespace on this device) via [UserPreferences]. Read/written from
/// [onboarding_controller.dart]'s `OnboardingState` — this class has no
/// Riverpod/Flutter dependency so it can also be called from plain async
/// contexts without a `ref`.
typedef OnboardingStatus = ({
  bool coreDone,
  bool storyDone,
  bool profileDone,
  bool coachMarksDone,
  bool guestDeclined,
});

class OnboardingPrefs {
  OnboardingPrefs._();

  static const completedKey = 'ONBOARDING_COMPLETED';
  static const storyKey = 'ONBOARDING_STORY_DONE';
  static const profileKey = 'ONBOARDING_PROFILE_DONE';
  static const coachMarksKey = 'ONBOARDING_COACHMARKS_DONE';
  static const guestDeclinedKey = 'ONBOARDING_GUEST_DECLINED';

  // Mirrors SelectedSportState's own pref key
  // (lib/core/state/selected_sport_state.dart) so a guest's picked sport can
  // be adopted alongside onboarding completion on sign-up.
  static const _sportKey = 'SELECTED_SPORT';

  static UserPreferences get _prefs => UserPreferences.instance;

  static Future<OnboardingStatus> read() async {
    final coreDone = await _prefs.getBool(completedKey) ?? false;
    final storyDone = await _prefs.getBool(storyKey) ?? false;
    final profileDone = await _prefs.getBool(profileKey) ?? false;
    final coachMarksDone = await _prefs.getBool(coachMarksKey) ?? false;
    final guestDeclined = await _prefs.getBool(guestDeclinedKey) ?? false;
    return (
      coreDone: coreDone,
      storyDone: storyDone,
      profileDone: profileDone,
      coachMarksDone: coachMarksDone,
      guestDeclined: guestDeclined,
    );
  }

  static Future<void> markCoreDone() => _prefs.setBool(completedKey, true);

  static Future<void> markStoryDone() => _prefs.setBool(storyKey, true);

  static Future<void> markProfileDone() => _prefs.setBool(profileKey, true);

  static Future<void> markCoachMarksDone() =>
      _prefs.setBool(coachMarksKey, true);

  static Future<void> markGuestDeclined() =>
      _prefs.setBool(guestDeclinedKey, true);

  /// Idempotent, no-op for guests. Carries onboarding progress and the
  /// picked `SELECTED_SPORT` over from this device's guest namespace into
  /// the just-signed-up real user's namespace, so a guest who already saw
  /// the guide (and already picked a sport) isn't re-onboarded after
  /// registering. A guest who *declined* never wrote these flags, so
  /// nothing is adopted for them — they get the full guide as a new user.
  /// `profileKey` is never written under the guest namespace at all — the
  /// profile sheet is signed-in only (see `follow_up.dart`) — so this is a
  /// no-op for it either way, and every newly-signed-up account correctly
  /// gets the real, editable profile sheet regardless of guest history.
  static Future<void> bridgeGuestFlagsToCurrentUser() async {
    await _prefs.adoptGuestValue(completedKey);
    await _prefs.adoptGuestValue(storyKey);
    await _prefs.adoptGuestValue(profileKey);
    await _prefs.adoptGuestValue(coachMarksKey);
    await _prefs.adoptGuestValue(_sportKey);
  }
}
