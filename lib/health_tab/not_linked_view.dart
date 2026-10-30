import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_platform.dart';
import '../ui/main.dart';
import 'health_controller.dart';

/// Full-screen link CTA. Only a guest sees this now — a signed-in user who
/// hasn't linked a wearable gets [HealthLinkPromptCard] above their
/// achievements instead (social badges don't need a device).
class HealthNotLinkedView extends ConsumerWidget {
  const HealthNotLinkedView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    _listenForAndroidUnavailable(context, ref);
    final error = ref.watch(healthControllerProvider).error;

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
            const _UnavailableNotice(),
          ],
          const SizedBox(height: 32),
          const _LinkButton(),
        ],
      ),
    );
  }
}

/// Compact link CTA that sits above the achievements subtab while no
/// wearable is linked — the device-only subtabs (trends, activity data) stay
/// hidden, but achievements don't, since social badges progress from posts
/// and reactions alone.
class HealthLinkPromptCard extends ConsumerWidget {
  const HealthLinkPromptCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    _listenForAndroidUnavailable(context, ref);
    final error = ref.watch(healthControllerProvider).error;

    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(FLucideIcons.heartPulse, color: theme.colors.primary),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      'health.notLinked.promptTitle'.tr(),
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'health.notLinked.promptBody'.tr(),
                      style: theme.typography.body.sm.copyWith(
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (error != null) const _UnavailableNotice(),
          const _LinkButton(),
        ],
      ),
    );
  }
}

void _listenForAndroidUnavailable(BuildContext context, WidgetRef ref) {
  ref.listen(healthControllerProvider, (previous, next) {
    if (AppPlatform.isAndroid && next.error != null && previous?.error == null) {
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('health.notLinked.notAvailableAndroid'.tr()),
        alignment: .bottomCenter,
      );
    }
  });
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colors.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppPlatform.isIOS
            ? 'health.notLinked.notAvailableIOS'.tr()
            : 'health.notLinked.notAvailableAndroid'.tr(),
        style: theme.typography.body.sm.copyWith(
          color: theme.colors.destructive,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _LinkButton extends ConsumerWidget {
  const _LinkButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLinking = ref.watch(healthControllerProvider).isLoading;
    return FButton(
      onPress: isLinking
          ? null
          : () => ref.read(healthControllerProvider.notifier).linkHealthService(),
      child: isLinking
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text('health.notLinked.linkButton'.tr()),
    );
  }
}
