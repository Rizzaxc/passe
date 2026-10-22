import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/model/enum.dart';
import '../../ui/main.dart';
import 'badminton.dart' show BadmintonProfileWidget;
import 'basketball.dart' show BasketballProfileWidget;
import 'pickleball.dart' show PickleballProfileWidget;
import 'soccer.dart' show SoccerProfileWidget;
import 'sport_profile_controller.dart';
import 'tennis.dart' show TennisProfileWidget;

/// One sport's profile editor. Takes the sport explicitly: Profile lists a
/// tile per sport rather than editing whichever one was the context sport.
class SportProfileScreen extends ConsumerWidget {
  final Sport sport;

  const SportProfileScreen({super.key, required this.sport});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PFlushOnPop(
      onFlush: () => flushSportProfile(ref, sport),
      child: FScaffold(
        header: FHeader.nested(
          title: Text(
            'profile.sportProfile'.tr(args: [sport.getLocalizedName(context)]),
          ),
          prefixes: [
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: switch (sport) {
            Sport.soccer => const SoccerProfileWidget(),
            Sport.basketball => const BasketballProfileWidget(),
            Sport.badminton => const BadmintonProfileWidget(),
            Sport.tennis => const TennisProfileWidget(),
            Sport.pickleball => const PickleballProfileWidget(),
            Sport.others => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
