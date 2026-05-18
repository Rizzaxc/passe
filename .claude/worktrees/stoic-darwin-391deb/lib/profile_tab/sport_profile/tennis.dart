import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/model/sport_profile.dart' show TennisProfile;
import 'elo_seed_field.dart';
import 'sport_profile_controller.dart';

class TennisProfileWidget extends ConsumerWidget {
  const TennisProfileWidget({super.key});

  void _update(WidgetRef ref, TennisProfile updated) {
    ref.read(tennisProfileControllerProvider.notifier).updateDraft(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tennisProfileControllerProvider);
    final profile = state.profile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        FSelect<DominantHand>.rich(
          key: ValueKey(profile.dominantHand),
          label: Text('racketSport.dominantHand.label'.tr()),
          hint: 'notSet'.tr(),
          format: (h) => h.getLocalizedName(context),
          autoHide: true,
          control: FSelectControl.lifted(
            value: profile.dominantHand,
            onChange: (h) {
              if (h != null) _update(ref, profile.copyWith(dominantHand: h));
            },
          ),
          children: [
            for (final hand in DominantHand.values)
              FSelectItem(
                title: Text(hand.getLocalizedName(context)),
                value: hand,
              ),
          ],
        ),
        FMultiSelect<RacketDiscipline>.rich(
          key: ValueKey(profile.discipline),
          label: Text('racketSport.discipline.label'.tr()),
          hint: Text('notSet'.tr()),
          format: (d) => Text(d.getLocalizedName(context)),
          keepHint: false,
          control: FMultiValueControl.managed(
            initial: profile.discipline?.toSet() ?? {},
            onChange: (selected) =>
                _update(ref, profile.copyWith(discipline: selected.toList())),
          ),
          children: [
            for (final d in RacketDiscipline.values)
              FSelectItem(
                title: Text(d.getLocalizedName(context)),
                value: d,
              ),
          ],
        ),
        EloSeedField(
          value: profile.eloSeed,
          locked: state.eloSeedLocked,
          onChanged: (s) {
            if (s != null) _update(ref, profile.copyWith(eloSeed: s));
          },
        ),
      ],
    );
  }
}
