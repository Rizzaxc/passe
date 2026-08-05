import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../notifications/notification_kind.dart';
import '../notifications/notification_router.dart';
import '../ui/main.dart';
import 'notification_center_controller.dart';
import 'notification_item.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(notificationCenterControllerProvider);
    final hasUnread = itemsAsync.value?.any((i) => i.isUnread) ?? false;

    return FScaffold(
      header: FHeader(
        title: Text('notification.title'.tr()),
        suffixes: [
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
  NotificationKind.activityConfirmed => FLucideIcons.calendarCheck,
  NotificationKind.proSessionReminder => FLucideIcons.clock,
  NotificationKind.challengerConfirmed ||
  NotificationKind.challengeReceived ||
  NotificationKind.challengeDeclined ||
  NotificationKind.challengeScheduled => FLucideIcons.swords,
  NotificationKind.challengeLapsed => FLucideIcons.calendarX,
  NotificationKind.matchResultRecorded => FLucideIcons.trophy,
  NotificationKind.lobbyInvite => FLucideIcons.users,
  NotificationKind.professionalBookingRequested ||
  NotificationKind.professionalBookingConfirmed ||
  NotificationKind.professionalBookingRejected => FLucideIcons.briefcase,
  NotificationKind.friendRequest ||
  NotificationKind.friendAccepted => FLucideIcons.userPlus,
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

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    if (item.isUnread) {
      await ref
          .read(notificationCenterControllerProvider.notifier)
          .markRead(item.id);
    }
    final location = resolveNotificationLocation(item.data);
    if (location != null && context.mounted) context.push(location);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FTappable(
      onPress: () => _onTap(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Icon(_iconFor(item.kind), size: 20, color: colors.mutedForeground),
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
                      fontWeight: item.isUnread ? FontWeight.w700 : FontWeight.w500,
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
            if (item.isUnread)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
