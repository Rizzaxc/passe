import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/enum.dart';
import 'profile_controller.dart';

class IndustrySelectionScreen extends ConsumerWidget {
  const IndustrySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final selectedIndustries = profileState.industries;

    return FScaffold(
      header: FHeader(
        title: Text('profile.industryLabel'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FSelectTileGroup<Industry>(
          description: Text('profile.industryFeatureExplanation'.tr()),
          control: FMultiValueControl.managed(
            initial: selectedIndustries.toSet(),
            onChange: (selected) {
              while (selected.length > 2) {
                selected.remove(selected.first);
              }
              ref
                  .read(industryControllerProvider.notifier)
                  .updateAll(selected.toList());
            },
          ),
          children:
              (Industry.values.toList()..sort(
                    (a, b) => a
                        .getLocalizedName(context, withoutDiacritics: true)
                        .compareTo(b.getLocalizedName(context, withoutDiacritics: true)),
                  ))
                  .map(
                    (industry) => FSelectTile.suffix(
                      title: Text(industry.getLocalizedName(context)),
                      value: industry,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}
