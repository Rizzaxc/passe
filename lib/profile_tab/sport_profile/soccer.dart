import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/model/sport_profile.dart' show SoccerProfile;
import 'elo_seed_field.dart';
import 'sport_profile_controller.dart';

class SoccerProfileWidget extends ConsumerWidget {
  const SoccerProfileWidget({super.key});

  void _update(WidgetRef ref, SoccerProfile updated) {
    ref.read(soccerProfileControllerProvider.notifier).updateDraft(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(soccerProfileControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        FMultiSelect<SoccerPosition>.rich(
          key: ValueKey(profile.position),
          label: Text('soccer.position.label'.tr()),
          hint: Text('notSet'.tr()),
          format: (p) => Text(p.getLocalizedName(context)),
          keepHint: false,
          control: FMultiValueControl.managed(
            initial: profile.position?.toSet() ?? {},
            onChange: (selected) =>
                _update(ref, profile.copyWith(position: selected.toList())),
          ),
          children: [
            for (final pos in SoccerPosition.values)
              FSelectItem(
                title: Text(pos.getLocalizedName(context)),
                value: pos,
              ),
          ],
        ),
        FMultiSelect<SoccerPitch>.rich(
          key: ValueKey(profile.pitch),
          label: Text('soccer.pitch.label'.tr()),
          hint: Text('notSet'.tr()),
          format: (p) => Text(p.getLocalizedName(context)),
          keepHint: false,
          control: FMultiValueControl.managed(
            initial: profile.pitch?.toSet() ?? {},
            onChange: (selected) =>
                _update(ref, profile.copyWith(pitch: selected.toList())),
          ),
          children: [
            for (final pitch in SoccerPitch.values)
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
