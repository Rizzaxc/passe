import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../core/model/enum.dart';

/// Shared eloSeed field used by all sport profile widgets.
/// Shows a read-only tile once locked (committed to DB).
class EloSeedField extends StatelessWidget {
  final EloSeed? value;
  final bool locked;
  final ValueChanged<EloSeed?> onChanged;

  const EloSeedField({
    super.key,
    required this.value,
    required this.locked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (locked && value != null) {
      return FTileGroup(
        label: Text('eloSeed.label'.tr()),
        children: [
          FTile(
            prefix: const Icon(FIcons.lock),
            title: Text(value!.getLocalizedName(context)),
          ),
        ],
      );
    }

    return FSelect<EloSeed>.rich(
      label: Text('eloSeed.label'.tr()),
      description: Text('eloSeed.description'.tr()),
      hint: 'notSet'.tr(),
      format: (s) => s.getLocalizedName(context),
      autoHide: true,
      control: FSelectControl.lifted(
        value: value,
        onChange: onChanged,
      ),
      children: [
        for (final seed in EloSeed.values)
          FSelectItem(
            title: Text(seed.getLocalizedName(context)),
            value: seed,
          ),
      ],
    );
  }
}
