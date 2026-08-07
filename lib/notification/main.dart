import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../manage_tab/lobby_section/lobby_invite_response_controller.dart';
import '../notifications/notification_kind.dart';
import '../notifications/notification_router.dart';
import '../router.dart';
import '../ui/main.dart';
import 'notification_center_controller.dart';
import 'notification_item.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  void _confirmClearRead(BuildContext context, WidgetRef ref) {
    showFDialog(
      context: context,
      builder: (dialogCtx, style, animation) => PConfirmDialog(
        animation: animation,
        title: Text('notification.clearRead.title'.tr()),
        body: Text('notification.clearRead.message'.tr()),
        actions: [
          FButton(
            variant: .outline,
            onPress: () => Navigator.of(dialogCtx).pop(),
            child: Text('notification.clearRead.cancel'.tr()),
          ),
          FButton(
            variant: .destructive,
            onPress: () {
              Navigator.of(dialogCtx).pop();
              ref
                  .read(notificationCenterControllerProvider.notifier)
                  .clearRead();
            },
            child: Text('notification.clearRead.confirm'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(notificationCenterControllerProvider);
    final items = itemsAsync.value ?? const <NotificationItem>[];
    final hasUnread = items.any((i) => i.isUnread);
    final hasRead = items.any((i) => !i.isUnread);

    return FScaffold(
      header: FHeader(
        title: Text('notification.title'.tr()),
        suffixes: [
          if (hasRead)
            FHeaderAction(
              icon: const Icon(FLucideIcons.trash2),
              onPress: () => _confirmClearRead(context, ref),
            ),
          if (hasUnread)
            FHeaderAction(
              icon: const Icon(FLucideIcons.checkCheck),
              onPress: () => ref
                  .read(notificationCenterControllerProvider.notifier)
                  .markAllRead(),
            ),
          FHeaderAction(
            icon: const Icon(FLucideIcons.x),
            onPress: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
      ),
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            PEmptySectionPlaceholder(
              hero: Icon(
                FLucideIcons.bellOff,
                size: 64,
                color: context.theme.colors.mutedForeground,
              ),
              subtitle: 'errorGeneric'.tr(),
            ),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                PEmptySectionPlaceholder(
                  hero: Icon(
                    FLucideIcons.bellOff,
                    size: 64,
                    color: context.theme.colors.mutedForeground,
                  ),
                  title: 'notification.empty.title'.tr(),
                  subtitle: 'notification.empty.subtitle'.tr(),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationCenterControllerProvider);
              await ref.read(notificationCenterControllerProvider.future);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _NotificationRow(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(NotificationKind? kind) => switch (kind) {
  NotificationKind.activityScheduled => FLucideIcons.calendarPlus,
  NotificationKind.activityConfirmed => FLucideIcons.calendarCheck,
  NotificationKind.proSessionReminder => FLucideIcons.clock,
  NotificationKind.challengerConfirmed ||
  NotificationKind.challengeReceived ||
  NotificationKind.challengeDeclined ||
  NotificationKind.challengeScheduled => FLucideIcons.swords,
  NotificationKind.challengeLapsed => FLucideIcons.calendarX,
  NotificationKind.matchResultRecorded => FLucideIcons.trophy,
  NotificationKind.lobbyInvite => FLucideIcons.users,
  NotificationKind.memberKicked => FLucideIcons.userMinus,
  NotificationKind.professionalBookingRequested ||
  NotificationKind.professionalBookingConfirmed ||
  NotificationKind.professionalBookingRejected => FLucideIcons.briefcase,
  NotificationKind.friendRequest ||
  NotificationKind.friendAccepted => FLucideIcons.userPlus,
  NotificationKind.paymentRequested ||
  NotificationKind.debtCollected => FLucideIcons.wallet,
  null => FLucideIcons.bell,
};

/// Coarse, hand-rolled relative time — not worth pulling in a full date/time
/// i18n dependency for one string.
String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${dt.day}/${dt.month}/${dt.year}';
}

class _NotificationRow extends ConsumerWidget {
  final NotificationItem item;

  const _NotificationRow({required this.item});

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref, {
    String? lobbyInviteStatus,
  }) async {
    if (item.isUnread) {
      await ref
          .read(notificationCenterControllerProvider.notifier)
          .markRead(item.id);
    }

    // The in-app list already watches this invite's status for its inline
    // Accept/Reject — reuse it to shortcut straight to the lobby (or do
    // nothing on decline) instead of round-tripping through the preview
    // page, which is the generic fallback for OS push taps that can't do
    // this cheap a check before routing.
    if (item.kind == NotificationKind.lobbyInvite) {
      if (lobbyInviteStatus == 'declined') return;
      if (lobbyInviteStatus == 'accepted') {
        final lobbyId = item.data['lobby_id'] as String?;
        if (lobbyId != null && context.mounted) {
          context.go(LobbyDetailRoute(id: lobbyId).location);
        }
        return;
      }
    }

    final location = resolveNotificationLocation({
      ...item.data,
      'kind': item.kind?.value,
    });
    // go(), not push(): most kinds resolve to a page nested under the bottom-
    // tab shell (e.g. LobbyDetailRoute under /manage/lobby/:id). Pushing a
    // full nested shell path on top of a root-level screen like this one
    // collides with the shell's own preserved branch state (go_router throws
    // a duplicate-GlobalKey assertion) — go() replaces the stack instead of
    // appending to it, so it can't collide.
    if (location != null && context.mounted) context.go(location);
  }

  Future<void> _onDelete(WidgetRef ref) => ref
      .read(notificationCenterControllerProvider.notifier)
      .delete(item.id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    final recordId = item.kind == NotificationKind.lobbyInvite
        ? item.data['record_id'] as String?
        : null;
    final lobbyInviteStatus = recordId == null
        ? null
        : ref.watch(lobbyInviteStatusProvider(recordId)).value;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _onDelete(ref),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colors.destructive,
        child: Icon(FLucideIcons.trash2, color: colors.destructiveForeground),
      ),
      child: FTappable(
        onPress: () =>
            _onTap(context, ref, lobbyInviteStatus: lobbyInviteStatus),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.isUnread ? colors.secondary : colors.muted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _iconFor(item.kind),
                  size: 18,
                  color: item.isUnread
                      ? colors.secondaryForeground
                      : colors.mutedForeground,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.sm.copyWith(
                        fontWeight: item.isUnread
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                    Text(
                      _relativeTime(item.createdAt),
                      style: typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (recordId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _LobbyInviteActions(recordId: recordId),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline Accept/Reject for a `lobby_invite` notification, or (once
/// resolved) a small hint of what tapping the card now does. This is the
/// primary accept surface — the old Manage▸Lobby mail-icon sheet is retired.
class _LobbyInviteActions extends ConsumerWidget {
  final String recordId;

  const _LobbyInviteActions({required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(lobbyInviteStatusProvider(recordId));
    final colors = context.theme.colors;

    return statusAsync.when(
      loading: () => const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (status) => switch (status) {
        'accepted' => Icon(
          FLucideIcons.chevronRight,
          size: 18,
          color: colors.primary,
        ),
        'declined' => Text(
          'lobby.invites.declined'.tr(),
          style: context.theme.typography.body.xs.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        _ => _LobbyInvitePendingButtons(recordId: recordId),
      },
    );
  }
}

class _LobbyInvitePendingButtons extends ConsumerStatefulWidget {
  final String recordId;

  const _LobbyInvitePendingButtons({required this.recordId});

  @override
  ConsumerState<_LobbyInvitePendingButtons> createState() =>
      _LobbyInvitePendingButtonsState();
}

class _LobbyInvitePendingButtonsState
    extends ConsumerState<_LobbyInvitePendingButtons> {
  bool _loading = false;

  Future<void> _respond(bool accept) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(lobbyInviteResponseControllerProvider.notifier)
          .respond(widget.recordId, accept: accept);
    } catch (e, st) {
      Talker().handle(e, st, 'lobby invite response failed');
      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        FButton.icon(
          variant: .ghost,
          size: .xs,
          onPress: () => _respond(false),
          child: const Icon(FLucideIcons.x, size: 14, color: pbBlue),
        ),
        FButton.icon(
          variant: .primary,
          size: .xs,
          onPress: () => _respond(true),
          child: const Icon(FLucideIcons.check, size: 14),
        ),
      ],
    );
  }
}
