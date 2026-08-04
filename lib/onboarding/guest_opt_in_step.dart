import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/dual_button.dart';
import 'onboarding_controller.dart';

/// Guests-only first step: ask before spending their time on a guide they
/// may not want. Both answers lead straight to the mandatory sport pick;
/// the only difference is whether the story sheet / profile nudge / coach
/// marks run afterward, once inside the shell (accept) or not (decline —
/// and the full guide is offered again, for real, once they sign up).
class GuestOptInStep extends ConsumerWidget {
  const GuestOptInStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(FLucideIcons.compass, size: 44, color: colors.primary),
            ),
            const SizedBox(height: 32),
            Text(
              'onboarding.guest.title'.tr(),
              style: context.theme.typography.body.xl2.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'onboarding.guest.body'.tr(),
              style: context.theme.typography.body.md.copyWith(color: colors.mutedForeground, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PDualButton(
              axis: Axis.vertical,
              compact: true,
              secondVariant: .outline,
              onFirstPressed: () => ref
                  .read(onboardingFlowControllerProvider.notifier)
                  .goTo(OnboardingStep.sport),
              onSecondPressed: () async {
                await ref.read(onboardingStateProvider.notifier).declineAsGuest();
                ref
                    .read(onboardingFlowControllerProvider.notifier)
                    .goTo(OnboardingStep.sport);
              },
              firstChild: Text('onboarding.guest.accept'.tr()),
              secondChild: Text('onboarding.guest.decline'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
