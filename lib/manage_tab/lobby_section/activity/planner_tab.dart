// Planner tab — every current/future activity for a lobby, chronological,
// soonest-first, with an always-reachable "+" to schedule another one.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../ui/main.dart';
import '../schedule_activity_controller.dart';
import '../schedule_activity_sheet.dart';
import 'activity_card.dart';
import 'planner_empty_state.dart';
import 'upcoming_controller.dart';

class LobbyPlannerTab extends ConsumerStatefulWidget {
  final String lobbyId;
  final bool isLeader;

  /// Set when reached via a notification tap for a specific activity or
  /// challenge — the matching card scrolls into view and pulses once.
  final String? highlightActivityId;
  final String? highlightChallengeId;

  const LobbyPlannerTab({
    super.key,
    required this.lobbyId,
    required this.isLeader,
    this.highlightActivityId,
    this.highlightChallengeId,
  });

  @override
  ConsumerState<LobbyPlannerTab> createState() => _LobbyPlannerTabState();
}

class _LobbyPlannerTabState extends ConsumerState<LobbyPlannerTab> {
  final _cardKeys = <String, GlobalKey>{};
  bool _scrolledToHighlight = false;

  bool _isTarget(UpcomingActivity a) =>
      (widget.highlightActivityId != null &&
          a.activity.id == widget.highlightActivityId) ||
      (widget.highlightChallengeId != null &&
          a.challenge?.challengeId == widget.highlightChallengeId);

  void _maybeScrollToHighlight(List<UpcomingActivity> activities) {
    if (widget.highlightActivityId == null &&
        widget.highlightChallengeId == null) {
      return;
    }
    if (_scrolledToHighlight) return;

    UpcomingActivity? target;
    for (final a in activities) {
      if (_isTarget(a)) {
        target = a;
        break;
      }
    }
    if (target == null) return;

    _scrolledToHighlight = true;
    final id = target.activity.id!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _cardKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(
      lobbyUpcomingActivitiesControllerProvider(widget.lobbyId),
    );
    final atCap =
        (activitiesAsync.value?.length ?? 0) >=
        ScheduleActivityController.maxConcurrentActivities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: PSectionHeader(
            title: 'lobbyHub.planner.activityTitle'.tr(),
            suffix: widget.isLeader
                ? FButton.icon(
                    variant: .ghost,
                    onPress: atCap
                        ? null
                        : () => showScheduleActivitySheet(
                            context,
                            widget.lobbyId,
                          ),
                    child: const Icon(FLucideIcons.plus),
                  )
                : null,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                lobbyUpcomingActivitiesControllerProvider(widget.lobbyId),
              );
              await ref.read(
                lobbyUpcomingActivitiesControllerProvider(
                  widget.lobbyId,
                ).future,
              );
            },
            child: activitiesAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (_, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  PEmptySectionPlaceholder(
                    subtitle: 'lobbyHub.planner.loadFailed'.tr(),
                  ),
                ],
              ),
              data: (activities) {
                if (activities.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      PlannerEmptyState(
                        lobbyId: widget.lobbyId,
                        isLeader: widget.isLeader,
                      ),
                    ],
                  );
                }
                _maybeScrollToHighlight(activities);
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: activities.length,
                  itemBuilder: (context, i) {
                    final a = activities[i];
                    final id = a.activity.id!;
                    final key = _cardKeys.putIfAbsent(id, () => GlobalKey());
                    return ActivityCard(
                      key: key,
                      lobbyId: widget.lobbyId,
                      upcoming: a,
                      isLeader: widget.isLeader,
                      highlighted: _isTarget(a),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
