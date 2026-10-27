import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../auth/auth_controller.dart';
import '../../../core/model/enum.dart';
import '../../../discover_tab/lobby_public_preview_sheet.dart';
import '../../../discover_tab/teammate_section/feed_controller.dart';
import '../../../logger/talker.dart';
import '../../../router.dart';
import '../../../ui/main.dart';
import '../invite_member_sheet.dart';
import 'lobby_add_sheet.dart';
import 'lobby_controller.dart';
import 'lobby_form_sheet.dart';
import 'my_pending_requests_controller.dart';

class LobbySubtab extends ConsumerWidget {
  const LobbySubtab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lobbiesAsync = ref.watch(userLobbiesControllerProvider);
    final currentUser = ref.watch(authControllerProvider).value;
    final isGuest = currentUser?.isGuest ?? true;

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
              showLobbyAddSheet(context, ref);
            },
            child: const Icon(FLucideIcons.plus),
          ),
        ),
        // Requests waiting on a captain belong to the Lobby section — they're
        // lobbies you're about to be in — so they sit under its header.
        if (!isGuest) const _PendingRequestsSection(),
        Expanded(
          child: isGuest
              ? const _GuestLobbyState()
              : lobbiesAsync.when(
                  loading: () => const Center(child: FCircularProgress()),
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
                          actions: [
                            FButton(
                              size: .sm,
                              prefix: const Icon(FLucideIcons.search),
                              onPress: () =>
                                  const DiscoverTeammateRoute().go(context),
                              child: Text(
                                'manageTab.lobby.empty.findLobby'.tr(),
                              ),
                            ),
                            FButton(
                              size: .sm,
                              variant: .outline,
                              prefix: const Icon(FLucideIcons.plus),
                              onPress: () => createLobbyAndOpen(context, ref),
                              child: Text('manageTab.lobby.createFirst'.tr()),
                            ),
                          ],
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
                          // Eyebrow: the sport (the list mixes every sport
                          // now) and, when it applies, your role.
                          Row(
                            spacing: 8,
                            children: [
                              Flexible(
                                child: _SportEyebrow(sport: lobby.sport),
                              ),
                              if (isLeader || item.isCoordinator)
                                _LobbyRoleBadge(
                                  isLeader: isLeader,
                                  isCoordinator: item.isCoordinator,
                                ),
                            ],
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
                    Expanded(
                      child: FButton(
                        size: .sm,
                        style: FButtonStyleExtension.accentBlueStyle(
                          context.theme.buttonStyles.primary.base,
                        ),
                        onPress: lobby.id != null
                            ? () => LobbyDetailRoute(
                                id: lobby.id!,
                                $extra: lobby.name,
                              ).go(context)
                            : null,
                        child: Text(
                          'lobby.enterHub'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    FButton.icon(
                      size: .sm,
                      variant: .outline,
                      onPress: lobby.id != null
                          ? () => LobbyDetailRoute(
                              id: lobby.id!,
                              $extra: lobby.name,
                              tab: 1,
                              openActivityPlanner: canManage ? true : null,
                            ).go(context)
                          : null,
                      child: const Icon(FLucideIcons.calendarPlus, size: 16),
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

/// The lobby's sport as a small caps eyebrow over its name — the same
/// typographic tier as the role badge beside it, so the two read as one
/// label line rather than a sticker on the avatar.
class _SportEyebrow extends StatelessWidget {
  final Sport sport;

  const _SportEyebrow({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 5,
      children: [
        sport.getIcon(size: 7),
        Flexible(
          child: Text(
            sport.getLocalizedName(context).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.theme.typography.body.xs.copyWith(
              color: pbInk.withValues(alpha: 0.62),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1.0,
            ),
          ),
        ),
      ],
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

/// "Đang chờ duyệt" — the join requests the user has sent and nobody has
/// answered yet, in every sport, as one full-width horizontal slide (one
/// request per page, dots when there's more than one). Renders nothing while
/// loading, on error, or when there are none: it's a status strip, not a
/// section that needs an empty state of its own.
class _PendingRequestsSection extends ConsumerStatefulWidget {
  const _PendingRequestsSection();

  @override
  ConsumerState<_PendingRequestsSection> createState() =>
      _PendingRequestsSectionState();
}

class _PendingRequestsSectionState
    extends ConsumerState<_PendingRequestsSection> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cancel(MyPendingRequest r) async {
    try {
      await ref.read(joinRequestStateProvider.notifier).unrequest(r.lobbyId);
    } catch (e, st) {
      talker.handle(e, st, 'cancel join request failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myPendingRequestsProvider).value ?? const [];
    if (requests.isEmpty) return const SizedBox.shrink();
    final colors = context.theme.colors;
    final page = _page.clamp(0, requests.length - 1);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          PSheetSectionLabel(
            label: 'manageTab.lobby.pending.title'.tr(
              namedArgs: {'count': '${requests.length}'},
            ),
          ),
          SizedBox(
            height: 64,
            child: PageView.builder(
              controller: _controller,
              itemCount: requests.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final r = requests[i];
                return FTappable(
                  onPress: () =>
                      showLobbyPublicPreviewSheet(context, r.lobbyId),
                  child: Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 4, 0),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      spacing: 10,
                      children: [
                        r.sport.getIcon(size: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                r.lobbyName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.theme.typography.body.sm
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'manageTab.lobby.pending.waiting'.tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.theme.typography.body.xs
                                    .copyWith(color: colors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        FButton(
                          size: .sm,
                          variant: .ghost,
                          onPress: () => _cancel(r),
                          child: Text('manageTab.lobby.pending.cancel'.tr()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (requests.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                for (var i = 0; i < requests.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: i == page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == page ? colors.primary : colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
