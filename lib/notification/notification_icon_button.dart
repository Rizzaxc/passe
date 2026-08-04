import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../router.dart';
import 'notification_unread_count_controller.dart';

class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationUnreadCountProvider).value ?? 0;
    final colors = context.theme.colors;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FButton.icon(
          variant: .ghost,
          child: const Icon(FLucideIcons.bell, size: 20),
          onPress: () => const NotificationRoute().push(context),
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
