import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/lobby.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import 'lobby_card_activity_slot.dart';
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
          icon: const Icon(FIcons.circleX),
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
            child: const Icon(FIcons.plus),
          ),
        ),
        Expanded(
          child: lobbiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (lobbies) => lobbies.isEmpty
                ? PEmptySectionPlaceholder(
                    hero: Icon(
                      FIcons.users,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    title: 'manageTab.lobby.empty.title'.tr(),
                    subtitle: 'manageTab.lobby.empty.message'.tr(),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    itemCount: lobbies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _LobbyCard(item: lobbies[index]),
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

    return FCard(
      child: FTappable(
        onPress: lobby.id != null
            ? () => LobbyDetailRoute(
                id: lobby.id!,
                $extra: lobby.name,
              ).go(context)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: info left, avatar right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Row(
                        spacing: 4,
                        children: [
                          Flexible(
                            child: Text(
                              lobby.name,
                              style: context.theme.typography.lg.copyWith(
                                fontWeight: .w600,
                                color: context.theme.colors.primary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLeader)
                            Icon(FIcons.crown, size: 14, color: colors.primary),
                        ],
                      ),

                      Row(
                        spacing: 4,
                        children: [
                          Icon(
                            FIcons.users,
                            size: 12,
                            color: colors.mutedForeground,
                          ),
                          Text(
                            '${item.memberCount}',
                            style: context.theme.typography.sm.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                          if (item.homeGroundName != null) ...[
                            Icon(
                              FIcons.mapPin,
                              size: 12,
                              color: colors.mutedForeground,
                            ),
                            Flexible(
                              child: Text(
                                item.homeGroundName!,
                                style: context.theme.typography.sm.copyWith(
                                  color: colors.mutedForeground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _LobbyAvatar(name: lobby.name),
              ],
            ),

            // Separator
            FDivider(),

            // Bottom: activity slot left, actions right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: .spaceBetween,
                children: [
                  LobbyCardActivitySlot(
                    nextActivity: item.nextActivity,
                    isLeader: isLeader,
                  ),
                  _ActionButtons(lobby: lobby),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Lobby lobby;

  const _ActionButtons({required this.lobby});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                    icon: Icon(FIcons.info),
                    title: Text('lobby.searchIDCopied'.tr()),
                    description: Text('lobby.searchIDExplanation'.tr()),
                    alignment: .bottomCenter,
                  );
                }
              : null,
          child: Icon(FIcons.copy, size: 16, color: pbBlue),
        ),
        FButton.icon(
          variant: .ghost,
          size: .xs,
          onPress: null, // TODO: invite API
          child: Icon(FIcons.userPlus, size: 16, color: pbBlue),
        ),
      ],
    );
  }
}

class _LobbyAvatar extends StatelessWidget {
  final String name;

  const _LobbyAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: context.theme.colors.secondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: context.theme.typography.xl.copyWith(
          fontWeight: .bold,
          color: context.theme.colors.secondaryForeground,
        ),
      ),
    );
  }
}
