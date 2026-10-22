import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/model/enum.dart';
import '../../ui/main.dart';

/// Shared eloSeed field used by all sport profile widgets and the onboarding
/// profile step. Self-declared and freely editable at any time — the DB only
/// uses the first value it ever sees to seed the user's starting Elo, so a
/// later change here doesn't disturb an already-seeded rating.
///
/// Drawn as the same 5-step bar as a lobby's MMR meter (`PLevelSlider`).
/// The level word only appears here (the guided tour and Profile), written
/// into the line that explains it: "**Khá** — Chơi thường xuyên…".
class EloSeedField extends StatelessWidget {
  final EloSeed? value;
  final ValueChanged<EloSeed?> onChanged;

  const EloSeedField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final seed = value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          'eloSeed.label'.tr(),
          style: typography.body.sm.copyWith(fontWeight: FontWeight.w600),
        ),
        PLevelSlider(
          count: EloSeed.values.length,
          value: seed?.index,
          onChanged: (i) => onChanged(EloSeed.values[i]),
        ),
        if (seed == null)
          Text(
            'eloSeed.pickHint'.tr(),
            style: typography.body.sm.copyWith(
              color: colors.mutedForeground,
              height: 1.4,
            ),
          )
        else
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: seed.getLocalizedName(context),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      ' — ${'onboarding.profile.skillLevels.${seed.name}'.tr()}',
                ),
              ],
            ),
            style: typography.body.sm.copyWith(height: 1.4),
          ),
        Text(
          'eloSeed.description'.tr(),
          style: typography.body.xs.copyWith(
            color: colors.mutedForeground,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
