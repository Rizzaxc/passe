import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'guest_opt_in_step.dart';
import 'onboarding_controller.dart';
import 'sport_step.dart';

/// Host for the two screens that must block entry to the app: a guest's
/// opt-in question, and the mandatory sport pick every feed depends on.
/// The rest of the journey — app story, improve profile, feature intro —
/// runs *after* this, as sheets/coach-marks layered over the real shell
/// (see `follow_up.dart`), so the user sees the real app instead of being
/// walled off behind a multi-screen carousel.
///
/// Barrier-locked — there's always a valid next step (including the
/// mandatory sport pick for a declining guest), so there's nothing sensible
/// to back out to.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingFlowControllerProvider);

    return PopScope(
      canPop: false,
      child: FScaffold(
        child: switch (step) {
          OnboardingStep.guestOptIn => const GuestOptInStep(),
          OnboardingStep.sport => const SportStep(),
        },
      ),
    );
  }
}
