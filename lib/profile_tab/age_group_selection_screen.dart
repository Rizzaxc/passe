import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/model/enum.dart';
import 'profile_controller.dart';

class AgeGroupSelectionScreen extends ConsumerWidget {
  const AgeGroupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final details = profileState.details;

    return FScaffold(
      header: FHeader.nested(
        title: Text('nav.profile'.tr()),
        prefixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FSelectTileGroup<AgeGroup>(
          label: Text('profile.ageGroup'.tr()),
          control: FMultiValueControl.managedRadio(
            initial: details.ageGroup,
            onChange: (selectedAgeGroup) {
              final updatedDetails = details.copyWith(
                ageGroup: selectedAgeGroup.firstOrNull,
              );
              ref
                  .read(profileControllerProvider.notifier)
                  .updateDraft(details: updatedDetails);
            },
          ),
          children: <FSelectTile<AgeGroup>>[
            FSelectTile.suffix(
              prefix: FaIcon(FontAwesomeIcons.graduationCap),
              title: Text(AgeGroup.student.getLocalizedName(context)),
              value: AgeGroup.student,
            ),
            FSelectTile.suffix(
              prefix: FaIcon(FontAwesomeIcons.briefcase),

              title: Text(AgeGroup.mature.getLocalizedName(context)),
              value: AgeGroup.mature,
            ),
            FSelectTile.suffix(
              prefix: FaIcon(FontAwesomeIcons.wineGlass),

              title: Text(AgeGroup.middleAge.getLocalizedName(context)),
              value: AgeGroup.middleAge,
            ),
          ],
        ),
      ),
    );
  }
}
