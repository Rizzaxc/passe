import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/enum.dart';
import '../core/state/selected_sport_state.dart';
import 'onboarding_controller.dart';

/// Mandatory sport pick — every Home/Manage feed goes blank on
/// [Sport.others], so this is the one step that always runs, even for a
/// guest who declined the rest of the guide. The only "core" step left in
/// the blocking pre-shell route; picking a sport releases the user straight
/// into the real app. The story sheet, profile sheet and feature-intro
/// coach-marks run afterward, layered over the real (now sport-scoped)
/// shell — see `follow_up.dart`.
class SportStep extends ConsumerWidget {
  const SportStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final sports = Sport.values.where((s) => s != Sport.others).toList();

    Future<void> onPick(Sport sport) async {
      ref.read(selectedSportStateProvider.notifier).change(sport);
      await ref.read(onboardingStateProvider.notifier).completeCore();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'onboarding.sport.title'.tr(),
              style: context.theme.typography.body.xl2
                  .copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'onboarding.sport.body'.tr(),
              style: context.theme.typography.body.md
                  .copyWith(color: colors.mutedForeground, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final sport in sports)
                  FButton(
                    variant: .outline,
                    prefix: sport.getIcon(size: 18),
                    onPress: () => onPick(sport),
                    child: Text(sport.getLocalizedName(context)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'onboarding.sport.hint'.tr(),
              style: context.theme.typography.body.sm
                  .copyWith(color: colors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
