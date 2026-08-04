import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import '../incoming_invites_controller.dart';
import '../incoming_invites_sheet.dart';
import '../invite_member_sheet.dart';
import '../lobby_avatar.dart';
import '../schedule_activity_sheet.dart';
import 'lobby_controller.dart';
import 'lobby_form_sheet.dart';

class LobbySubtab extends ConsumerWidget {
  const LobbySubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobbiesAsync = ref.watch(userLobbiesControllerProvider);
    final isGuest = ref.watch(authControllerProvider).value?.isGuest ?? true;

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

    // Pending incoming invites (invite/pair records targeting this user).
    final inviteCount =
        ref.watch(incomingInvitesControllerProvider).value?.length ?? 0;

    return Column(
      children: [
        PSectionHeader(
          title: 'manageTab.lobby.title'.tr(),
          suffix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InvitesButton(count: inviteCount),
              FButton.icon(
                variant: .ghost,
                onPress: () {
                  if (isGuest) {
                    showFToast(
                      context: context,
                      icon: const Icon(FLucideIcons.circleAlert),
                      variant: .destructive,
                      title: Text('lobby.signInRequired'.tr()),
                      alignment: .bottomCenter,
                    );
                    return;
                  }
                  showLobbyFormSheet(context: context, ref: ref, lobbyId: null);
                },
                child: const Icon(FLucideIcons.plus),
              ),
            ],
          ),
        ),
        Expanded(
          child: isGuest
              ? const _GuestLobbyState()
              : lobbiesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
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
                            await ref.read(
                              userLobbiesControllerProvider.future,
                            );
                          },
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: lobbies.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
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

/// A guest has no lobbies and can't create one, so the generic "create a
/// lobby to start playing" empty state (which implies a working CTA) would
/// be misleading — mirrors `feed_tab/main.dart`'s `_GuestState`: hero icon +
/// title + subtitle + a direct sign-in CTA, centered rather than pinned to
/// the top of a list since there's nothing else in this section for a guest.
class _GuestLobbyState extends StatelessWidget {
  const _GuestLobbyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PEmptySectionPlaceholder(
                  hero: Icon(
                    FLucideIcons.userX,
                    size: 64,
                    color: context.theme.colors.mutedForeground,
                  ),
                  title: 'manageTab.lobby.guest.title'.tr(),
                  subtitle: 'manageTab.lobby.guest.message'.tr(),
                ),
                const SizedBox(height: 16),
                FButton(
                  onPress: () => const ProfileRoute().go(context),
                  child: Text('auth.guestPrompt.cta'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inbox button in the lobby-list header — opens the pending-invites sheet,
/// with a count badge when the user has unresolved invites/pairs.
class _InvitesButton extends StatelessWidget {
  final int count;

  const _InvitesButton({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FButton.icon(
          variant: .ghost,
          onPress: () => showIncomingInvitesSheet(context),
          child: const Icon(FLucideIcons.mailPlus),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.background, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryForeground,
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
    // Scheduling is coordinator-eligible too (not kicking, not editing
    // lobby info) — the crown badge and sliver accent stay captain-only.
    final canManage = isLeader || item.isCoordinator;
    final sliverColor = isLeader ? colors.primary : colors.muted;

    return FTappable(
      onPress: lobby.id != null
          ? () =>
                LobbyDetailRoute(id: lobby.id!, $extra: lobby.name).go(context)
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
                      LobbyAvatar(
                        lobbyId: lobby.id,
                        name: lobby.name,
                        hasAvatar: lobby.details?.hasAvatar ?? false,
                        size: 48,
                        borderRadius: context.theme.style.borderRadius.md,
                        backgroundColor: colors.secondary,
                        foregroundColor: colors.primary,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            // Name + crown (full width, wraps up to 2 lines)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 4,
                              children: [
                                Expanded(
                                  child: Text(
                                    lobby.name,
                                    style: context.theme.typography.body.sm
                                        .copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colors.primary,
                                          fontSize: 15,
                                        ),
                                    maxLines: 2,
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
                            // Meta: mmr
                            Row(
                              spacing: 10,
                              children: [
                                if (item.isMmrCalibrated)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 4,
                                    children: [
                                      Icon(
                                        FLucideIcons.swords,
                                        size: 14,
                                        color: colors.primary,
                                      ),
                                      Text(
                                        '${item.mmr}',
                                        style: context.theme.typography.body.lg
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: colors.primary,
                                              height: 1,
                                            ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.muted,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '? MMR',
                                      style: TextStyle(
                                        fontFamily: context
                                            .theme
                                            .typography
                                            .body
                                            .xs
                                            .fontFamily,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: colors.mutedForeground,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Homeground — level with the avatar, spanning the full
                  // card width rather than indented under the name column.
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
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            DateFormat(
                              'EEE, d MMM · HH:mm',
                            ).format(item.nextActivity!),
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
                      if (canManage && lobby.id != null)
                        FButton.icon(
                          size: .xs,
                          variant: .ghost,
                          onPress: () =>
                              showScheduleActivitySheet(context, lobby.id!),
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
                          child: Icon(
                            FLucideIcons.userPlus,
                            size: 16,
                            color: pbBlue,
                          ),
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
