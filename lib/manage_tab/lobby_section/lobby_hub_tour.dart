import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/user_preferences.dart';
import '../../onboarding/coach_marks.dart';
import '../../onboarding/onboarding_step_badge.dart';

/// Keys owned by one lobby-detail page. Keeping these per page avoids a
/// duplicate-GlobalKey collision while a route transition briefly retains
/// both the outgoing and incoming lobby hubs.
class LobbyHubTourTargets {
  final info = GlobalKey(debugLabel: 'lobbyTour.info');
  final feed = GlobalKey(debugLabel: 'lobbyTour.feed');
  final planner = GlobalKey(debugLabel: 'lobbyTour.planner');
  final history = GlobalKey(debugLabel: 'lobbyTour.history');

  List<GlobalKey> get all => [info, feed, planner, history];
}

/// Device-level completion ledger. This cannot use a normal user-namespaced
/// preference: logout intentionally clears that entire namespace, while the
/// product requirement is to remember that the same user already saw the
/// tour when they sign in again on this device.
class LobbyHubTourPrefs {
  LobbyHubTourPrefs._();

  // V2 replaces the first implementation, whose live tab-label targets could
  // disappear during an async lobby rebuild and end the tour after step 1.
  // The version bump gives anyone affected by that bug one corrected pass.
  static const _shownUserIdsKey = 'LOBBY_HUB_TOUR_V2_SHOWN_USER_IDS';

  static UserPreferences get _prefs => UserPreferences.instance;

  static Future<bool> hasSeen(String userId) async {
    final ids = await _prefs.getDeviceStringList(_shownUserIdsKey) ?? const [];
    return ids.contains(userId);
  }

  static Future<void> markSeen(String userId) async {
    final ids = <String>{
      ...?await _prefs.getDeviceStringList(_shownUserIdsKey),
      userId,
    };
    await _prefs.setDeviceStringList(_shownUserIdsKey, ids.toList()..sort());
  }
}

// Protects against two lobby routes racing before either tour has completed.
// Persistence remains the durable source of truth across app launches.
final Set<String> _showingForUserIds = {};

/// Shows the lobby-hub tour once for [userId] on this device.
///
/// Returning users are deduplicated by their stable id even after logout.
/// Finishing or explicitly skipping counts as seen; killing the app halfway
/// through does not, so the user gets another chance on the next visit.
Future<void> maybeShowLobbyHubTour({
  required BuildContext context,
  required String userId,
  required LobbyHubTourTargets targets,
}) async {
  if (_showingForUserIds.contains(userId)) return;

  final keys = [...targets.all, NavCoachKeys.health];
  if (keys.any((key) => key.currentContext == null)) {
    return;
  }

  // Capture every target up front. The lobby detail providers can resolve
  // and rebuild while the overlay is animating; using the live GlobalKeys on
  // every step gave the coach-mark package a chance to observe a transiently
  // unmounted Forui tab label, which it treats as "tour finished". These
  // controls are stationary for the lifetime of the overlay, so stable root-
  // overlay rectangles are the appropriate target representation here.
  final rootOverlay = Overlay.of(context, rootOverlay: true);
  final overlayBox = rootOverlay.context.findRenderObject();
  if (overlayBox is! RenderBox || !overlayBox.hasSize) return;

  final positions = <TargetPosition>[];
  for (final key in keys) {
    final targetBox = key.currentContext?.findRenderObject();
    if (targetBox is! RenderBox || !targetBox.hasSize) return;
    positions.add(
      TargetPosition(
        targetBox.size,
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox),
      ),
    );
  }

  if (await LobbyHubTourPrefs.hasSeen(userId) || !rootOverlay.mounted) return;

  _showingForUserIds.add(userId);
  var completionStarted = false;

  Future<void> complete() async {
    if (completionStarted) return;
    completionStarted = true;
    try {
      await LobbyHubTourPrefs.markSeen(userId);
    } finally {
      _showingForUserIds.remove(userId);
    }
  }

  const steps = [
    ('info', 'lobbyHub.tour.infoTitle', 'lobbyHub.tour.infoBody'),
    ('feed', 'lobbyHub.tour.feedTitle', 'lobbyHub.tour.feedBody'),
    ('planner', 'lobbyHub.tour.plannerTitle', 'lobbyHub.tour.plannerBody'),
    ('history', 'lobbyHub.tour.historyTitle', 'lobbyHub.tour.historyBody'),
    ('health', 'lobbyHub.tour.healthTitle', 'lobbyHub.tour.healthBody'),
  ];

  final tourTargets = <TargetFocus>[
    for (var i = 0; i < steps.length; i++)
      TargetFocus(
        identify: steps[i].$1,
        targetPosition: positions[i],
        shape: ShapeLightFocus.RRect,
        radius: 14,
        paddingFocus: 5,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: i == steps.length - 1
                ? ContentAlign.top
                : ContentAlign.bottom,
            builder: (context, controller) => _TourCopy(
              step: i + 1,
              total: steps.length,
              title: steps[i].$2.tr(),
              body: steps[i].$3.tr(),
              onNext: controller.next,
            ),
          ),
        ],
      ),
  ];

  TutorialCoachMark(
    targets: tourTargets,
    textSkip: 'lobbyHub.tour.skip'.tr(),
    disableBackButton: true,
    onFinish: () => unawaited(complete()),
    onSkip: () {
      unawaited(complete());
      return true;
    },
  ).showWithOverlayState(overlay: rootOverlay, rootOverlay: true);
}

class _TourCopy extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String body;
  final VoidCallback onNext;

  const _TourCopy({
    required this.step,
    required this.total,
    required this.title,
    required this.body,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepBadge(step: step, total: total, light: true),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FButton(
              onPress: onNext,
              child: Text(
                step == total ? 'onboarding.done'.tr() : 'onboarding.next'.tr(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
