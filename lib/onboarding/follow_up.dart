import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../core/user_preferences.dart';
import '../manage_tab/lobby_section/lobby_hub_tour.dart';
import 'coach_marks.dart';
import 'get_started_sheet.dart';
import 'onboarding_controller.dart';
import 'profile_sheet.dart';

/// Chains the rest of the onboarding journey once the user has landed in
/// the real shell with a sport picked: profile sheet → feature-intro
/// coach-marks → get-started choices. There's deliberately no "what is
/// Passe" story here — the pre-auth welcome pages already tell it, and
/// telling it twice was noise. The profile sheet is signed-in only — guests
/// can't persist profile edits, so there's little for a non-interactive
/// preview to accomplish; a declining guest skips all three until they sign
/// up. Safe to call from the shell's `initState` on every launch — each step
/// is individually gated on its own persisted "done" flag, so a step that
/// already ran is a no-op.
Future<void> runOnboardingFollowUps(BuildContext context, WidgetRef ref) async {
  final status = ref.read(onboardingStateProvider).value;
  if (status == null || !status.coreDone) return;

  final isGuest = ref.read(authControllerProvider).value?.isGuest ?? false;
  if (isGuest && status.guestDeclined) return;

  if (!isGuest && !status.profileDone) {
    await showProfileSheet(context, ref);
  }
  if (!context.mounted) return;

  await _runTourAndGetStarted(context, ref);
}

/// Profile ▸ "Hướng dẫn": replays the nav tour and the get-started sheet on
/// demand, and re-arms the one-time in-context hints (the lobby-hub tour and
/// the Discover filter hint) so they show again on their next visit. Ignores
/// a guest's earlier decline — asking for the guide is an explicit opt-in.
Future<void> replayOnboardingGuide(BuildContext context, WidgetRef ref) async {
  await ref.read(onboardingStateProvider.notifier).resetGuide();
  final userId = ref.read(currentUserIdProvider);
  if (userId != null) await LobbyHubTourPrefs.forget(userId);
  // Owned by `discover_tab/filter.dart`'s private `_FilterCoachMarkPrefs`;
  // cleared by key so this file doesn't reach into that screen's internals.
  await UserPreferences.instance.remove('FILTER_FIELDS_COACH_SEEN');
  if (!context.mounted) return;
  await _runTourAndGetStarted(context, ref);
}

Future<void> _runTourAndGetStarted(BuildContext context, WidgetRef ref) async {
  await maybeShowCoachMarks(context, ref);
  if (!context.mounted) return;

  final afterCoachMarks = ref.read(onboardingStateProvider).value;
  if (afterCoachMarks != null &&
      afterCoachMarks.coachMarksDone &&
      !afterCoachMarks.getStartedDone) {
    await showGetStartedSheet(context, ref);
  }
}
