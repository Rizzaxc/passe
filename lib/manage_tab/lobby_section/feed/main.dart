import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import '../invite_member_sheet.dart';
import 'lobby_controller.dart';
import 'lobby_form_sheet.dart';

class LobbySubtab extends ConsumerWidget {
  const LobbySubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobbiesAsync = ref.watch(userLobbiesControllerProvider);

    ref.listen(userLobbiesControllerProvider, (_, next) {
      if (next is AsyncError && context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('error'.tr()),
          description: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    });

    return Column(
      children: [
        PSectionHeader(
          title: 'manageTab.lobby.title'.tr(),
          suffix: FButton.icon(
            variant: .ghost,
            onPress: () =>
                showLobbyFormSheet(context: context, ref: ref, lobbyId: null),
            child: const Icon(FLucideIcons.plus),
          ),
        ),
        Expanded(
          child: lobbiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (lobbies) => lobbies.isEmpty
                ? PEmptySectionPlaceholder(
                    hero: Icon(
                      FLucideIcons.users,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    title: 'manageTab.lobby.empty.title'.tr(),
                    subtitle: 'manageTab.lobby.empty.message'.tr(),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(userLobbiesControllerProvider);
                      await ref.read(userLobbiesControllerProvider.future);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: lobbies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _LobbyCard(item: lobbies[index]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _LobbyCard extends ConsumerWidget {
  final LobbyListItem item;

  const _LobbyCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobby = item.lobby;
    final colors = context.theme.colors;
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final isLeader =
        currentUserId != null &&
        lobby.captainId != null &&
        lobby.captainId == currentUserId;
    final initial =
        lobby.name.isNotEmpty ? lobby.name[0].toUpperCase() : '?';
    final sliverColor = isLeader ? colors.primary : colors.muted;

    return FTappable(
      onPress: lobby.id != null
          ? () => LobbyDetailRoute(id: lobby.id!, $extra: lobby.name).go(context)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          border: Border.all(color: colors.border),
          borderRadius: context.theme.style.borderRadius.md,
          boxShadow: context.theme.style.shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  // Avatar + name column
                  Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          borderRadius: context.theme.style.borderRadius.md,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontFamily: context.theme.typography.body.xl2.fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                            height: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            // Name + crown | member count (top-right)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Row(
                                    spacing: 4,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          lobby.name,
                                          style: context.theme.typography.body.sm
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: colors.primary,
                                                fontSize: 15,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isLeader)
                                        Icon(
                                          FLucideIcons.crown,
                                          size: 13,
                                          color: colors.mutedForeground,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item.memberCount}',
                                      style: context.theme.typography.body.lg
                                          .copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: colors.primary,
                                            height: 1,
                                          ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'thành viên',
                                      style: TextStyle(
                                        fontFamily: context
                                            .theme.typography.body.xs.fontFamily,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: colors.mutedForeground,
                                        letterSpacing: 0.4,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Homeground
                            if (item.homeGroundName != null)
                              Row(
                                spacing: 4,
                                children: [
                                  Icon(
                                    FLucideIcons.mapPin,
                                    size: 12,
                                    color: colors.mutedForeground,
                                  ),
                                  Flexible(
                                    child: Text(
                                      item.homeGroundName!,
                                      style: context.theme.typography.body.xs
                                          .copyWith(
                                            color: colors.mutedForeground,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  FDivider(),

                  // Activity label (left) + small ghost action buttons (right)
                  Row(
                    children: [
                      // Activity state
                      if (item.nextActivity != null) ...[
                        Icon(
                          FLucideIcons.calendar,
                          size: 12,
                          color: colors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('EEE, d MMM · HH:mm').format(
                              item.nextActivity!,
                            ),
                            style: TextStyle(
                              fontFamily:
                                  context.theme.typography.body.xs.fontFamily,
                              fontSize: 11,
                              color: colors.mutedForeground,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        Expanded(
                          child: Text(
                            'lobby.noActivity'.tr(),
                            style: TextStyle(
                              fontFamily:
                                  context.theme.typography.body.xs.fontFamily,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: colors.mutedForeground,
                              height: 1.2,
                            ),
                          ),
                        ),
                      // Action buttons
                      if (isLeader)
                        FButton.icon(
                          size: .xs,
                          variant: .ghost,
                          onPress: () =>
                              showFToast(context: context, title: Text('TODO')),
                          child: Icon(
                            FLucideIcons.calendarPlus,
                            size: 16,
                            color: pbBlue,
                          ),
                        ),
                      FButton.icon(
                        size: .xs,
                        variant: .ghost,
                        onPress: lobby.searchableId != null
                            ? () async {
                                await Clipboard.setData(
                                  ClipboardData(text: lobby.searchableId!),
                                );
                                if (!context.mounted) return;
                                showFToast(
                                  context: context,
                                  icon: const Icon(FLucideIcons.info),
                                  title: Text('lobby.searchIDCopied'.tr()),
                                  description: Text(
                                    'lobby.searchIDExplanation'.tr(),
                                  ),
                                  alignment: .bottomCenter,
                                );
                              }
                            : null,
                        child: Icon(FLucideIcons.copy, size: 16, color: pbBlue),
                      ),
                      if (lobby.id != null)
                        FButton.icon(
                          size: .xs,
                          variant: .ghost,
                          onPress: () =>
                              showInviteMemberSheet(context, lobby.id!),
                          child: Icon(FLucideIcons.userPlus, size: 16, color: pbBlue),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom sliver
            SizedBox(height: 4, child: ColoredBox(color: sliverColor)),
          ],
        ),
      ),
    );
  }
}
