import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../router.dart';
import '../../ui/lobby_avatar.dart';
import 'activity/main.dart';
import 'activity/planner_tab.dart';
import 'history/view.dart';
import 'lobby_detail_controller.dart';
import 'lobby_hub_tour.dart';
import 'lobby_info_sheet.dart';
import 'schedule_activity_sheet.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);

class LobbyDetailPage extends ConsumerStatefulWidget {
  final String lobbyId;
  final String? lobbyName;

  /// Which of the 3 tabs (0 = Feed, 1 = Planner, 2 = History) to land on.
  final int initialIndex;

  /// Threaded through to the Planner tab (`LobbyPlannerTab`) and, for
  /// [highlightActivityId] alone, also to History (`HistoryView`) — a
  /// past-session notification (payment request, match result) targets an
  /// activity that only History can still show.
  final String? highlightActivityId;
  final String? highlightChallengeId;

  /// Opens the scheduling sheet after landing on Planner, provided the
  /// signed-in member's permission resolves to captain/coordinator.
  final bool openActivityPlanner;

  const LobbyDetailPage({
    super.key,
    required this.lobbyId,
    this.lobbyName,
    this.initialIndex = 0,
    this.highlightActivityId,
    this.highlightChallengeId,
    this.openActivityPlanner = false,
  }) : assert(initialIndex >= 0 && initialIndex <= 2);

  /// Deep-links a specific tab (and, for Planner, a specific activity or
  /// challenge to scroll to and highlight) — used by notification routing.
  factory LobbyDetailPage.withInitialTab(
    String lobbyId,
    int initialIndex, {
    String? lobbyName,
    String? highlightActivityId,
    String? highlightChallengeId,
    bool openActivityPlanner = false,
  }) {
    return LobbyDetailPage(
      lobbyId: lobbyId,
      lobbyName: lobbyName,
      initialIndex: initialIndex,
      highlightActivityId: highlightActivityId,
      highlightChallengeId: highlightChallengeId,
      openActivityPlanner: openActivityPlanner,
    );
  }

  @override
  ConsumerState<LobbyDetailPage> createState() => _LobbyDetailPageState();
}

class _LobbyDetailPageState extends ConsumerState<LobbyDetailPage> {
  late int _currentIndex;
  final _tourTargets = LobbyHubTourTargets();

  // Which tabs are actually inflated right now. FTabs' content viewport has
  // a ~250px cache extent on either side of the active page, so the
  // neighboring tab would otherwise get fully built — and fire its own
  // RPCs (Feed/Planner both hit Supabase on build) — even though it's not
  // on screen. Rendering everything but the active + just-left index as a
  // cheap SizedBox defeats that, matching lib/home_tab/main.dart's
  // `_DiscoverViewState`.
  late final Set<int> _builtIndices;
  Timer? _settleTimer;
  bool _didOpenActivityPlanner = false;
  bool _activityPlannerSheetOpen = false;
  bool _didAttemptTour = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _builtIndices = {_currentIndex};
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged(int index) {
    _settleTimer?.cancel();
    setState(() {
      _currentIndex = index;
      _builtIndices.add(index);
    });
    _settleTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _builtIndices
          ..clear()
          ..add(_currentIndex);
      });
    });
  }

  void _maybeOpenActivityPlanner(bool canManage) {
    if (!widget.openActivityPlanner || !canManage || _didOpenActivityPlanner) {
      return;
    }
    _didOpenActivityPlanner = true;
    _activityPlannerSheetOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _activityPlannerSheetOpen = false;
        return;
      }
      unawaited(() async {
        await showScheduleActivitySheet(context, widget.lobbyId);
        if (!mounted) return;
        _activityPlannerSheetOpen = false;
        _maybeScheduleTour(
          ref.read(currentUserIdProvider),
          ref.read(onboardingStateProvider).value?.getStartedDone ?? false,
        );
      }());
    });
  }

  void _maybeScheduleTour(String? userId, bool onboardingDone) {
    if (_didAttemptTour ||
        _activityPlannerSheetOpen ||
        userId == null ||
        !onboardingDone) {
      return;
    }
    _didAttemptTour = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Let the root shell finish any route transition before measuring both
      // the lobby tabs and its Health bottom-nav item in the root overlay.
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        unawaited(
          maybeShowLobbyHubTour(
            context: context,
            userId: userId,
            targets: _tourTargets,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(lobbyDetailControllerProvider(widget.lobbyId));
    final colors = context.theme.colors;
    final userId = ref.watch(currentUserIdProvider);
    final onboardingDone =
        ref.watch(onboardingStateProvider).value?.getStartedDone ?? false;

    final lobbyName = infoAsync.value?.lobby.name ?? widget.lobbyName ?? '';
    // The Feed/Planner tabs' actions (schedule/reschedule/cancel, poll,
    // invite-to-challenge) are all coordinator-eligible — none of them
    // are kicking or editing lobby info — so this passes "can manage",
    // not strictly "is captain".
    final canManage =
        ref.watch(myLobbyPermissionProvider(widget.lobbyId)).value?.canManage ??
        false;
    _maybeOpenActivityPlanner(canManage);
    _maybeScheduleTour(userId, onboardingDone);

    final sections = <FTabEntry>[
      FTabEntry(
        label: SizedBox(
          key: _tourTargets.feed,
          width: 44,
          height: 32,
          child: const Icon(FLucideIcons.messageCircle),
        ),
        child: _builtIndices.contains(0)
            ? LobbyFeedTab(
                lobbyId: widget.lobbyId,
                isLeader: canManage,
                captainId: infoAsync.value?.lobby.captainId,
              )
            : const SizedBox.shrink(),
      ),
      FTabEntry(
        label: SizedBox(
          key: _tourTargets.planner,
          width: 44,
          height: 32,
          child: const Icon(FLucideIcons.activity),
        ),
        child: _builtIndices.contains(1)
            ? LobbyPlannerTab(
                lobbyId: widget.lobbyId,
                isLeader: canManage,
                highlightActivityId: widget.highlightActivityId,
                highlightChallengeId: widget.highlightChallengeId,
              )
            : const SizedBox.shrink(),
      ),
      FTabEntry(
        label: SizedBox(
          key: _tourTargets.history,
          width: 44,
          height: 32,
          child: const Icon(FLucideIcons.clock),
        ),
        child: _builtIndices.contains(2)
            ? HistoryView(
                lobbyId: widget.lobbyId,
                lobbyName: lobbyName,
                highlightActivityId: widget.highlightActivityId,
              )
            : const SizedBox.shrink(),
      ),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom header — avatar + name, with an explicit back button
            // next to the overflow trigger for the info sheet.
            _LobbyHeader(
              infoKey: _tourTargets.info,
              lobbyId: widget.lobbyId,
              lobbyName: lobbyName,
              hasAvatar: infoAsync.value?.lobby.details?.hasAvatar ?? false,
              onBackTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  const ManageLobbyRoute().go(context);
                }
              },
              onInfoTap: () {
                if (infoAsync.value != null) {
                  showLobbyInfoSheet(context, infoAsync.value!, widget.lobbyId);
                }
              },
            ),

            // Tabs — horizontal padding matches the 14-px inset the
            // card content uses, so the tab indicator's edges line up
            // with the content underneath.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: FTabs(
                  expands: true,
                  contentPhysics: const NeverScrollableScrollPhysics(),
                  control: FTabControl.lifted(
                    index: _currentIndex,
                    onChange: _onTabChanged,
                  ),
                  children: sections,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────

/// Slim lobby-detail header: oversize letter avatar + name, with a back
/// button and the overflow trigger for the info sheet side by side. No
/// captain / sport / member-count signage; those live in the info sheet.
class _LobbyHeader extends StatelessWidget {
  static const _avatarSize = 56.0;

  final String lobbyId;
  final String lobbyName;
  final bool hasAvatar;
  final VoidCallback onBackTap;
  final VoidCallback onInfoTap;
  final Key? infoKey;

  const _LobbyHeader({
    required this.lobbyId,
    required this.lobbyName,
    required this.hasAvatar,
    required this.onBackTap,
    required this.onInfoTap,
    this.infoKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          // Avatar — enlarged so the lobby reads as the page's identity at
          // a glance. Falls back to a letter square when no photo is set.
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: LobbyAvatar(
              lobbyId: lobbyId,
              name: lobbyName,
              hasAvatar: hasAvatar,
              size: _avatarSize,
              borderRadius: BorderRadius.circular(14),
              backgroundColor: _crimsonTint,
              foregroundColor: _crimson,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              lobbyName,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: colors.foreground,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),

          IconButton(
            onPressed: onBackTap,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(7),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          IconButton(
            key: infoKey,
            onPressed: onInfoTap,
            icon: Icon(
              Icons.more_horiz_rounded,
              size: 22,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(7),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }
}
