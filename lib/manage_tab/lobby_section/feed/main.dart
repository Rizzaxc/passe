import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/lobby.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
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
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                  // Avatar + name + meta
                  Row(
                    spacing: 12,
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
                            fontFamily: context.theme.typography.xl2.fontFamily,
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
                            Row(
                              spacing: 4,
                              children: [
                                Expanded(
                                  child: Text(
                                    lobby.name,
                                    style: context.theme.typography.sm.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isLeader)
                                  Icon(FIcons.crown, size: 13, color: colors.mutedForeground),
                              ],
                            ),
                            Row(
                              spacing: 4,
                              children: [
                                Icon(FIcons.users, size: 12, color: colors.mutedForeground),
                                Text(
                                  '${item.memberCount}',
                                  style: context.theme.typography.xs.copyWith(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                if (item.homeGroundName != null) ...[
                                  Icon(FIcons.mapPin, size: 12, color: colors.mutedForeground),
                                  Flexible(
                                    child: Text(
                                      item.homeGroundName!,
                                      style: context.theme.typography.xs.copyWith(
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
                    ],
                  ),

                  FDivider(),

                  _CardActions(lobby: lobby, isLeader: isLeader, nextActivity: item.nextActivity),
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

class _CardActions extends StatelessWidget {
  final Lobby lobby;
  final bool isLeader;
  final DateTime? nextActivity;

  const _CardActions({required this.lobby, required this.isLeader, this.nextActivity});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    Widget? activityLabel;
    if (nextActivity != null) {
      final formatted = DateFormat('EEE, d MMM · HH:mm').format(nextActivity!);
      activityLabel = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FIcons.check, size: 13, color: colors.primary),
          Text(
            formatted,
            style: context.theme.typography.xs.copyWith(color: colors.mutedForeground),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (activityLabel != null) ...[
          activityLabel,
          const Spacer(),
        ] else
          const Spacer(),
        if (isLeader)
          FButton.icon(
            size: .xs,
            variant: .ghost,
            onPress: () => showFToast(context: context, title: Text('TODO')),
            child: Icon(FIcons.calendarPlus, size: 16, color: pbBlue),
          ),
        FButton.icon(
          size: .xs,
          variant: .ghost,
          onPress: lobby.searchableId != null
              ? () async {
                  await Clipboard.setData(ClipboardData(text: lobby.searchableId!));
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
          size: .xs,
          variant: .ghost,
          onPress: null,
          child: Icon(FIcons.userPlus, size: 16, color: pbBlue),
        ),
      ],
    );
  }
}


