import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'model/enum.dart';
import 'state/selected_sport_state.dart';

class SportSelector extends ConsumerWidget {
  const SportSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSportAsync = ref.watch(selectedSportStateProvider);

    return selectedSportAsync.when(
      data: (selectedSport) => FButton(
        style: FButtonStyle.ghost(),
        suffix: const Icon(FIcons.chevronDown),
        onPress: () => _showSportPicker(context, ref, selectedSport),
        child: Text(selectedSport.getLocalizedName(context)),
      ),
      loading: () => FButton.icon(
        style: FButtonStyle.ghost(),
        onPress: null,
        child: Icon(FIcons.loader),
      ),
      error: (err, stack) => FButton.icon(
        style: FButtonStyle.ghost(),
        onPress: null,
        child: Icon(FIcons.triangleAlert),
      ),
    );
  }

  void _showSportPicker(
    BuildContext context,
    WidgetRef ref,
    Sport selectedSport,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => FPicker(
        // control: FPickerControl.lifted(
        //   indexes: [selectedSport.index],
        //   onChange: (index) =>
        //       ref.read(selectedSportStateProvider.notifier).change(index),
        // ),
        children: [
          FPickerWheel(
            children: Sport.values
                .map((sport) => Text(sport.getLocalizedName(context)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
