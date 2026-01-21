import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/model/enum.dart';
import '../../core/model/user_details.dart';
import 'sport_empty_placeholder.dart';

class PickleballProfile extends ConsumerWidget {
  final UserDetails details;

  const PickleballProfile({super.key, required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sport = Sport.pickleball;
    final sportId = sport.index;
    final sportName = sport.getLocalizedName(context);
    final sportProfile = details.sport?[sportId.toString()];
    final skillLevel = sportProfile?.skill;

    return sportProfile == null
        ? SportEmptyPlaceholder(sportName: sportName)
        : FTileGroup(
      label: Text('profile.sportProfile'.tr(args: [sportName])),
      description: Text('profile.sport_feature_explanation'.tr()),
      children: [
        FTile(
          title: Text(sportName),
          subtitle: Text('Skill Level: $skillLevel'),
          onPress: () {},
        ),
      ],
    );
  }
}
