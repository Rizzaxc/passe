import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'history/main.dart';
import 'feed/lobby_form_sheet.dart';
import 'members/controller.dart';
import 'members/main.dart';
import 'upcoming/main.dart';

class LobbyDetailPage extends ConsumerWidget {
  final String lobbyId;
  final String? lobbyName;

  const LobbyDetailPage({
    super.key,
    required this.lobbyId,
    this.lobbyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberCount = ref
        .watch(lobbyMembersControllerProvider(lobbyId))
        .value
        ?.length;

    return FScaffold(
      header: FHeader(
        title: Text(lobbyName ?? lobbyId),
        suffixes: [
          FHeaderAction(
            icon: const Icon(FIcons.pencil),
            onPress: () => showLobbyFormSheet(
              context: context,
              ref: ref,
              lobbyId: lobbyId,
            ),
          ),
          FHeaderAction.back(onPress: () => context.pop()),
        ],
      ),
      child: CustomScrollView(
        slivers: [
          // ── Members ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'lobby.detail.members'.tr(),
              count: memberCount,
            ),
          ),
          SliverToBoxAdapter(child: MembersSection(lobbyId: lobbyId)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Upcoming ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'lobby.detail.upcoming'.tr()),
          ),
          SliverToBoxAdapter(child: UpcomingSection(lobbyId: lobbyId)),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── History ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'lobby.detail.history'.tr()),
          ),
          SliverToBoxAdapter(child: HistorySection(lobbyId: lobbyId)),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        spacing: 8,
        children: [
          Text(
            title,
            style: context.theme.typography.lg
                .copyWith(fontWeight: FontWeight.w600),
          ),
          if (count != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.theme.colors.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Text(
                  '$count',
                  style: context.theme.typography.sm.copyWith(
                    color: context.theme.colors.secondaryForeground,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
