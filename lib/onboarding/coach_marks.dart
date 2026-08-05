import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../auth/auth_controller.dart';
import 'onboarding_controller.dart';
import 'onboarding_step_badge.dart';

/// GlobalKeys for the live bottom-nav icons the feature-intro tour points
/// at. Owned here (not in `main.dart`) so the target list below and the
/// widgets they key off can't drift apart. Attached to the icons in
/// `ScaffoldWithNavBar` (`lib/main.dart`).
class NavCoachKeys {
  NavCoachKeys._();

  static final feed = GlobalKey(debugLabel: 'coach.feed');
  static final discover = GlobalKey(debugLabel: 'coach.discover');
  static final manage = GlobalKey(debugLabel: 'coach.manage');
  static final health = GlobalKey(debugLabel: 'coach.health');
  static final profile = GlobalKey(debugLabel: 'coach.profile');
}

/// Runs the one-time feature-intro coach-mark pass over the real bottom nav.
/// No-op unless the story sheet (and, for signed-in users, the profile
/// sheet — guests never get one, see `follow_up.dart`) have already run,
/// the pass hasn't already run itself, and every target has actually laid
/// out (a `null` `currentContext` means the shell's first frame hasn't
/// happened yet — call again on a later frame).
///
/// The returned future only resolves once the tour is actually finished or
/// skipped (bridged from `TutorialCoachMark`'s callbacks via a [Completer],
/// since `.show()` itself returns `void`) — `follow_up.dart` awaits this so
/// the closing get-started sheet appears right after, not while the tour is
/// still on screen.
Future<void> maybeShowCoachMarks(BuildContext context, WidgetRef ref) async {
  final status = ref.read(onboardingStateProvider).value;
  if (status == null || !status.coreDone || !status.storyDone) return;
  final isGuest = ref.read(authControllerProvider).value?.isGuest ?? false;
  if (!isGuest && !status.profileDone) return;
  if (status.coachMarksDone) return;

  final keys = [
    NavCoachKeys.feed,
    NavCoachKeys.discover,
    NavCoachKeys.manage,
    NavCoachKeys.health,
    NavCoachKeys.profile,
  ];
  if (keys.any((k) => k.currentContext == null)) return;

  final labelKeys = [
    'onboarding.coach.feed',
    'onboarding.coach.discover',
    'onboarding.coach.manage',
    'onboarding.coach.health',
    'onboarding.coach.profile',
  ];

  final completer = Completer<void>();

  // Dismissing mid-tour (skip) counts the same as finishing it — either way
  // the user has seen it and it shouldn't run again.
  Future<void> complete() async {
    await ref.read(onboardingStateProvider.notifier).completeCoachMarks();
    if (!completer.isCompleted) completer.complete();
  }

  final targets = [
    for (var i = 0; i < keys.length; i++)
      TargetFocus(
        identify: 'nav_$i',
        keyTarget: keys[i],
        shape: ShapeLightFocus.RRect,
        radius: 16,
        // Nav items sit tightly packed side-by-side, so keep the highlight
        // padding tight too — the default (10) bled into neighboring items
        // and looked mismatched against the actual tap target.
        paddingFocus: 4,
        // Tapping the target itself already advances (enableTargetTab
        // defaults true); without this, tapping anywhere else on the
        // darkened overlay does nothing, which reads as "stuck" — users
        // shouldn't have to find the exact target to progress, only Skip
        // should be a distinct action.
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnboardingStepBadge(step: 3, total: 4, light: true),
                const SizedBox(height: 4),
                Text(
                  labelKeys[i].tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
  ];

  TutorialCoachMark(
    targets: targets,
    textSkip: 'onboarding.coach.skip'.tr(),
    onFinish: () => complete(),
    onSkip: () {
      complete();
      return true;
    },
  ).show(context: context);

  return completer.future;
}
