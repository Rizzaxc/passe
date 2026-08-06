import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'health_controller.dart';

class HealthNotLinkedView extends ConsumerWidget {
  const HealthNotLinkedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;

    ref.listen(healthControllerProvider, (previous, next) {
      if (Platform.isAndroid &&
          next.error != null &&
          previous?.error == null) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('health.notLinked.notAvailableAndroid'.tr()),
          alignment: .bottomCenter,
        );
      }
    });

    final healthState = ref.watch(healthControllerProvider);
    final isLinking = healthState.isLoading;
    final error = healthState.error;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FLucideIcons.heartPulse,
            size: 64,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(height: 24),
          Text(
            'health.notLinked.title'.tr(),
            style: theme.typography.body.xl2.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'health.notLinked.description'.tr(),
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colors.destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                Platform.isIOS
                    ? 'health.notLinked.notAvailableIOS'.tr()
                    : 'health.notLinked.notAvailableAndroid'.tr(),
                style: theme.typography.body.sm.copyWith(
                  color: theme.colors.destructive,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FButton(
            onPress: isLinking
                ? null
                : () => ref
                      .read(healthControllerProvider.notifier)
                      .linkHealthService(),
            child: isLinking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('health.notLinked.linkButton'.tr()),
          ),
        ],
      ),
    );
  }
}
