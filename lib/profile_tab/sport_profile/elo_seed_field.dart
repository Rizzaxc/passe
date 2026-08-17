import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../core/model/enum.dart';

/// Shared eloSeed field used by all sport profile widgets. Self-declared and
/// freely editable at any time — the DB only uses the first value it ever
/// sees to seed the user's starting Elo, so a later change here doesn't
/// disturb an already-seeded rating.
class EloSeedField extends StatelessWidget {
  final EloSeed? value;
  final ValueChanged<EloSeed?> onChanged;

  const EloSeedField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FSelect<EloSeed>.rich(
      label: Text('eloSeed.label'.tr()),
      description: Text('eloSeed.description'.tr()),
      hint: 'notSet'.tr(),
      format: (s) => s.getLocalizedName(context),
      autoHide: true,
      control: FSelectControl.lifted(value: value, onChange: onChanged),
      children: [
        for (final seed in EloSeed.values)
          FSelectItem(title: Text(seed.getLocalizedName(context)), value: seed),
      ],
    );
  }
}
