import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../auth/auth_controller.dart';
import '../../core/model/lobby.dart';
import 'activity/main.dart';
import 'history/view.dart';
import 'lobby_detail_controller.dart';
import 'lobby_info_sheet.dart';
import 'members/controller.dart';

const _crimson = Color(0xFFDC143C);
const _crimsonTint = Color(0xFFFFEBED);

class LobbyDetailPage extends ConsumerStatefulWidget {
  final String lobbyId;
  final String? lobbyName;

  const LobbyDetailPage({
    super.key,
    required this.lobbyId,
    this.lobbyName,
  });

  @override
  ConsumerState<LobbyDetailPage> createState() => _LobbyDetailPageState();
}

class _LobbyDetailPageState extends ConsumerState<LobbyDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Activity state (mock)
  final bool _hasActivity = true;
  String _myRsvp = 'going';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(lobbyDetailControllerProvider(widget.lobbyId));
    final membersAsync =
        ref.watch(lobbyMembersControllerProvider(widget.lobbyId));
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final colors = context.theme.colors;

    final lobbyName =
        infoAsync.value?.lobby.name ?? widget.lobbyName ?? '';
    final memberCount = membersAsync.value?.length;
    final isLeader = currentUserId != null &&
        infoAsync.value?.lobby.captainId == currentUserId;
    final sport = infoAsync.value?.lobby.sport;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom header
            _LobbyHeader(
              lobbyName: lobbyName,
              memberCount: memberCount,
              isLeader: isLeader,
              lobby: infoAsync.value?.lobby,
              onBack: () => context.pop(),
              onInfoTap: () {
                if (infoAsync.value != null) {
                  showLobbyInfoSheet(context, infoAsync.value!,
                      widget.lobbyId);
                }
              },
            ),

            // Tabs
            _LobbyTabBar(controller: _tabController),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ActivityTab(
                    lobbyId: widget.lobbyId,
                    isLeader: isLeader,
                    sport: sport,
                    hasActivity: _hasActivity,
                    myRsvp: _myRsvp,
                    onRsvpChanged: (v) => setState(() => _myRsvp = v),
                  ),
                  const HistoryView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────

class _LobbyHeader extends StatelessWidget {
  final String lobbyName;
  final int? memberCount;
  final bool isLeader;
  final Lobby? lobby;
  final VoidCallback onBack;
  final VoidCallback onInfoTap;

  const _LobbyHeader({
    required this.lobbyName,
    required this.memberCount,
    required this.isLeader,
    required this.lobby,
    required this.onBack,
    required this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final initial =
        lobbyName.isNotEmpty ? lobbyName[0].toUpperCase() : '?';

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colors.secondaryForeground,
            ),
            padding: const EdgeInsets.all(6),
          ),

          // Letter avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _crimsonTint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _crimson,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        lobbyName,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF09090B),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 5),
                      Icon(
                        FIcons.crown,
                        size: 13,
                        color: colors.mutedForeground,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    if (lobby?.sport != null) ...[
                      lobby!.sport.getIcon(size: 11),
                      const SizedBox(width: 3),
                    ],
                    if (memberCount != null) ...[
                      Text(
                        '$memberCount TV',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Search
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search_rounded,
                size: 20, color: colors.secondaryForeground),
            padding: const EdgeInsets.all(7),
            constraints:
                const BoxConstraints(minWidth: 34, minHeight: 34),
          ),

          // Burger menu → info sheet
          IconButton(
            onPressed: onInfoTap,
            icon: Icon(Icons.more_horiz_rounded,
                size: 20, color: colors.secondaryForeground),
            padding: const EdgeInsets.all(7),
            constraints:
                const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }
}

// ─── Tab bar ────────────────────────────────────────────────────

class _LobbyTabBar extends StatelessWidget {
  final TabController controller;
  const _LobbyTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: colors.foreground,
        unselectedLabelColor: colors.mutedForeground,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: _crimson,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(height: 40, text: 'Hoạt động'),
          Tab(height: 40, text: 'Lịch sử'),
        ],
      ),
    );
  }
}
