import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

  static const _shownUserIdsKey = 'LOBBY_HUB_TOUR_SHOWN_USER_IDS';

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
  if (_showingForUserIds.contains(userId) ||
      await LobbyHubTourPrefs.hasSeen(userId)) {
    return;
  }

  final keys = [...targets.all, NavCoachKeys.health];
  if (!context.mounted || keys.any((key) => key.currentContext == null)) {
    return;
  }

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
        keyTarget: keys[i],
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
  ).show(context: context, rootOverlay: true);
}

class _TourCopy extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String body;

  const _TourCopy({
    required this.step,
    required this.total,
    required this.title,
    required this.body,
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
        ],
      ),
    );
  }
}
