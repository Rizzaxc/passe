import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/model/sport_profile.dart' show BasketballProfile;
import 'elo_seed_field.dart';
import 'sport_profile_controller.dart';

class BasketballProfileWidget extends ConsumerWidget {
  const BasketballProfileWidget({super.key});

  void _update(WidgetRef ref, BasketballProfile updated) {
    ref.read(basketballProfileControllerProvider.notifier).updateDraft(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(basketballProfileControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        FMultiSelect<BasketballPosition>.rich(
          key: ValueKey(profile.position),
          label: Text('basketball.position.label'.tr()),
          hint: Text('notSet'.tr()),
          format: (p) => Text(p.getLocalizedName(context)),
          keepHint: false,
          control: FMultiValueControl.managed(
            initial: profile.position?.toSet() ?? {},
            onChange: (selected) =>
                _update(ref, profile.copyWith(position: selected.toList())),
          ),
          children: [
            for (final pos in BasketballPosition.values)
              FSelectItem(
                title: Text(pos.getLocalizedName(context)),
                value: pos,
              ),
          ],
        ),
        FMultiSelect<BasketballPitch>.rich(
          key: ValueKey(profile.pitch),
          label: Text('basketball.pitch.label'.tr()),
          hint: Text('notSet'.tr()),
          format: (p) => Text(p.getLocalizedName(context)),
          keepHint: false,
          control: FMultiValueControl.managed(
            initial: profile.pitch?.toSet() ?? {},
            onChange: (selected) =>
                _update(ref, profile.copyWith(pitch: selected.toList())),
          ),
          children: [
            for (final pitch in BasketballPitch.values)
              FSelectItem(
                title: Text(pitch.getLocalizedName(context)),
                value: pitch,
              ),
          ],
        ),
        EloSeedField(
          value: profile.eloSeed,
          onChanged: (s) {
            if (s != null) _update(ref, profile.copyWith(eloSeed: s));
          },
        ),
      ],
    );
  }
}
