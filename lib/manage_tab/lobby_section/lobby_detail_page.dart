import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'activity/main.dart';
import 'activity/planner_tab.dart';
import 'history/view.dart';
import 'lobby_avatar.dart';
import 'lobby_detail_controller.dart';
import 'lobby_info_sheet.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);

class LobbyDetailPage extends ConsumerStatefulWidget {
  final String lobbyId;
  final String? lobbyName;

  /// Which of the 3 tabs (0 = Feed, 1 = Planner, 2 = History) to land on.
  final int initialIndex;

  /// Threaded through to the Planner tab — see `LobbyPlannerTab`.
  final String? highlightActivityId;
  final String? highlightChallengeId;

  const LobbyDetailPage({
    super.key,
    required this.lobbyId,
    this.lobbyName,
    this.initialIndex = 0,
    this.highlightActivityId,
    this.highlightChallengeId,
  }) : assert(initialIndex >= 0 && initialIndex <= 2);

  /// Deep-links a specific tab (and, for Planner, a specific activity or
  /// challenge to scroll to and highlight) — used by notification routing.
  factory LobbyDetailPage.withInitialTab(
    String lobbyId,
    int initialIndex, {
    String? lobbyName,
    String? highlightActivityId,
    String? highlightChallengeId,
  }) {
    return LobbyDetailPage(
      lobbyId: lobbyId,
      lobbyName: lobbyName,
      initialIndex: initialIndex,
      highlightActivityId: highlightActivityId,
      highlightChallengeId: highlightChallengeId,
    );
  }

  @override
  ConsumerState<LobbyDetailPage> createState() => _LobbyDetailPageState();
}

class _LobbyDetailPageState extends ConsumerState<LobbyDetailPage> {
  late int _currentIndex;

  // Which tabs are actually inflated right now. FTabs' content viewport has
  // a ~250px cache extent on either side of the active page, so the
  // neighboring tab would otherwise get fully built — and fire its own
  // RPCs (Feed/Planner both hit Supabase on build) — even though it's not
  // on screen. Rendering everything but the active + just-left index as a
  // cheap SizedBox defeats that, matching lib/home_tab/main.dart's
  // `_DiscoverViewState`.
  late final Set<int> _builtIndices;
  Timer? _settleTimer;

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

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(lobbyDetailControllerProvider(widget.lobbyId));
    final colors = context.theme.colors;

    final lobbyName = infoAsync.value?.lobby.name ?? widget.lobbyName ?? '';
    // The Feed/Planner tabs' actions (schedule/reschedule/cancel, poll,
    // invite-to-challenge) are all coordinator-eligible — none of them
    // are kicking or editing lobby info — so this passes "can manage",
    // not strictly "is captain".
    final canManage =
        ref.watch(myLobbyPermissionProvider(widget.lobbyId)).value?.canManage ??
        false;

    final sections = <FTabEntry>[
      FTabEntry(
        label: const Icon(FLucideIcons.messageCircle),
        child: _builtIndices.contains(0)
            ? LobbyFeedTab(
                lobbyId: widget.lobbyId,
                isLeader: canManage,
                captainId: infoAsync.value?.lobby.captainId,
              )
            : const SizedBox.shrink(),
      ),
      FTabEntry(
        label: const Icon(FLucideIcons.activity),
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
        label: const Icon(FLucideIcons.clock),
        child: _builtIndices.contains(2)
            ? HistoryView(lobbyId: widget.lobbyId, lobbyName: lobbyName)
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
            // Custom header — avatar + name only, with overflow access
            // to the info sheet. Back nav is handled by system gesture.
            _LobbyHeader(
              lobbyId: widget.lobbyId,
              lobbyName: lobbyName,
              hasAvatar: infoAsync.value?.lobby.details?.hasAvatar ?? false,
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

/// Slim lobby-detail header: oversize letter avatar + name, with a
/// single overflow trigger for the info sheet. No back button —
/// system back gesture handles navigation — and no captain / sport /
/// member-count signage; those live in the info sheet now.
class _LobbyHeader extends StatelessWidget {
  static const _avatarSize = 56.0;

  final String lobbyId;
  final String lobbyName;
  final bool hasAvatar;
  final VoidCallback onInfoTap;

  const _LobbyHeader({
    required this.lobbyId,
    required this.lobbyName,
    required this.hasAvatar,
    required this.onInfoTap,
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
