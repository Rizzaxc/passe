import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/state/selected_sport_state.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import '../freeplay_section/main.dart';
import '../invite_member_sheet.dart';
import '../schedule_activity_sheet.dart';
import 'lobby_controller.dart';
import 'lobby_form_sheet.dart';

class LobbySubtab extends ConsumerWidget {
  const LobbySubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobbiesAsync = ref.watch(userLobbiesControllerProvider);
    final currentUser = ref.watch(authControllerProvider).value;
    final isGuest = currentUser?.isGuest ?? true;
    final sport = ref.watch(selectedSportStateProvider).value;
    final sportName = sport?.getLocalizedName(context).toLowerCase() ?? '';

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
        if (!isGuest) const PlayerFreeplaySection(),
        PSectionHeader(
          title: 'manageTab.lobby.title'.tr(),
          suffix: FButton.icon(
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
                          title: 'manageTab.lobby.empty.title'.tr(
                            namedArgs: {'sport': sportName},
                          ),
                          subtitle: 'manageTab.lobby.empty.message'.tr(
                            namedArgs: {'sport': sportName},
                          ),
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
                            itemBuilder: (context, index) => ManageLobbyCard(
                              item: lobbies[index],
                              currentUserId: currentUser?.id,
                            ),
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

class ManageLobbyCard extends StatelessWidget {
  final LobbyListItem item;
  final String? currentUserId;

  const ManageLobbyCard({
    required this.item,
    required this.currentUserId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final lobby = item.lobby;
    final colors = context.theme.colors;
    final isLeader =
        currentUserId != null &&
        lobby.captainId != null &&
        lobby.captainId == currentUserId;
    // Scheduling is coordinator-eligible too (not kicking, not editing
    // lobby info) — the crown badge and sliver accent stay captain-only.
    final canManage = isLeader || item.isCoordinator;
    final frameColor = isLeader
        ? pbCoral
        : item.isCoordinator
        ? pbAmber
        : pbBlueDeep;
    final radius = BorderRadius.circular(16);

    return POffsetFrame(
      offsetColor: frameColor,
      borderRadius: radius,
      child: FTappable(
        onPress: lobby.id != null
            ? () => LobbyDetailRoute(
                id: lobby.id!,
                $extra: lobby.name,
              ).go(context)
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            border: Border.all(color: pbInk.withValues(alpha: 0.16)),
            borderRadius: radius,
            boxShadow: context.theme.style.shadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LobbyAvatar(
                      lobbyId: lobby.id,
                      name: lobby.name,
                      hasAvatar: lobby.details?.hasAvatar ?? false,
                      size: 58,
                      borderRadius: BorderRadius.circular(16),
                      backgroundColor: pbAmber,
                      foregroundColor: pbInk,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          if (isLeader || item.isCoordinator)
                            _LobbyRoleBadge(
                              isLeader: isLeader,
                              isCoordinator: item.isCoordinator,
                            ),
                          Text(
                            lobby.name,
                            style: context.theme.typography.body.lg.copyWith(
                              color: pbInk,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _LobbyMetaPill(
                      icon: FLucideIcons.users,
                      label: '${item.memberCount}',
                    ),
                    _LobbyMetaPill(
                      icon: FLucideIcons.swords,
                      label: item.isMmrCalibrated ? '${item.mmr}' : '? MMR',
                    ),
                  ],
                ),
                if (item.homeGroundName != null)
                  Row(
                    children: [
                      Icon(
                        FLucideIcons.mapPin,
                        size: 12,
                        color: colors.mutedForeground,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.homeGroundName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.xs.copyWith(
                            color: colors.mutedForeground,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                _NextActivityBoard(nextActivity: item.nextActivity),
                Row(
                  children: [
                    if (canManage && lobby.id != null)
                      Expanded(
                        child: FButton(
                          size: .sm,
                          style: FButtonStyleExtension.accentBlueStyle(
                            context.theme.buttonStyles.primary.base,
                          ),
                          prefix: const Icon(
                            FLucideIcons.calendarPlus,
                            size: 16,
                          ),
                          onPress: () =>
                              showScheduleActivitySheet(context, lobby.id!),
                          child: Text('lobby.scheduleActivity'.tr()),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 6),
                    FButton.icon(
                      size: .sm,
                      variant: .outline,
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
                      child: const Icon(FLucideIcons.copy, size: 16),
                    ),
                    if (lobby.id != null) ...[
                      const SizedBox(width: 6),
                      FButton.icon(
                        size: .sm,
                        variant: .outline,
                        onPress: () =>
                            showInviteMemberSheet(context, lobby.id!),
                        child: const Icon(FLucideIcons.userPlus, size: 16),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyRoleBadge extends StatelessWidget {
  final bool isLeader;
  final bool isCoordinator;

  const _LobbyRoleBadge({required this.isLeader, required this.isCoordinator});

  @override
  Widget build(BuildContext context) {
    final label = isLeader
        ? 'lobby.leader'.tr()
        : 'lobby.memberRole.coordinator'.tr();
    final color = isLeader ? pbCoral : pbAmber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(
            isLeader ? FLucideIcons.crown : FLucideIcons.shieldCheck,
            size: 10,
            color: pbInk,
          ),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.theme.typography.body.xs.copyWith(
                color: pbInk,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyMetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LobbyMetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: pbInk.withValues(alpha: 0.055),
      border: Border.all(color: pbInk.withValues(alpha: 0.12)),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 11, color: pbBlueDeep),
        Text(
          label,
          style: context.theme.typography.body.xs.copyWith(
            color: pbInk,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _NextActivityBoard extends StatelessWidget {
  final DateTime? nextActivity;

  const _NextActivityBoard({required this.nextActivity});

  @override
  Widget build(BuildContext context) {
    final activity = nextActivity;
    if (activity == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: pbInk.withValues(alpha: 0.055),
          border: Border.all(color: pbInk.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(FLucideIcons.calendarClock, size: 18, color: pbBlueDeep),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'lobby.noActivity'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.typography.body.sm.copyWith(
                  color: pbInk.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PMatchBoard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  'lobby.detail.upcoming'.tr().toUpperCase(),
                  style: context.theme.typography.body.xs.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.05,
                  ),
                ),
                Text(
                  DateFormat(
                    'EEE, d MMM',
                    context.locale.toLanguageTag(),
                  ).format(activity),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            DateFormat('HH:mm').format(activity),
            style: context.theme.typography.body.xl2.copyWith(
              color: pbAmber,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
