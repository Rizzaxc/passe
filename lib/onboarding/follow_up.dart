import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
import 'coach_marks.dart';
import 'get_started_sheet.dart';
import 'onboarding_controller.dart';
import 'profile_sheet.dart';
import 'story_sheet.dart';

/// Chains the rest of the onboarding journey once the user has landed in
/// the real shell with a sport picked: story sheet → profile sheet →
/// feature-intro coach-marks → get-started choices. The profile sheet is
/// signed-in only — guests can't persist profile edits, so there's little
/// for a non-interactive preview to accomplish; a declining guest skips all
/// four until they sign up. Safe to call from the shell's `initState` on
/// every launch — each step is individually gated on its own persisted
/// "done" flag, so a step that already ran is a no-op.
Future<void> runOnboardingFollowUps(BuildContext context, WidgetRef ref) async {
  final status = ref.read(onboardingStateProvider).value;
  if (status == null || !status.coreDone) return;

  final isGuest = ref.read(authControllerProvider).value?.isGuest ?? false;
  if (isGuest && status.guestDeclined) return;

  if (!status.storyDone) {
    await showStorySheet(context, ref);
  }
  if (!context.mounted) return;

  final afterStory = ref.read(onboardingStateProvider).value;
  if (!isGuest && afterStory != null && !afterStory.profileDone) {
    await showProfileSheet(context, ref);
  }
  if (!context.mounted) return;

  await maybeShowCoachMarks(context, ref);
  if (!context.mounted) return;

  final afterCoachMarks = ref.read(onboardingStateProvider).value;
  if (afterCoachMarks != null &&
      afterCoachMarks.coachMarksDone &&
      !afterCoachMarks.getStartedDone) {
    await showGetStartedSheet(context, ref);
  }
}
