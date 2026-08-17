import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/state/selected_sport_state.dart';
import '../../ui/main.dart';
import 'badminton.dart' show BadmintonProfileWidget;
import 'basketball.dart' show BasketballProfileWidget;
import 'pickleball.dart' show PickleballProfileWidget;
import 'soccer.dart' show SoccerProfileWidget;
import 'sport_profile_controller.dart';
import 'tennis.dart' show TennisProfileWidget;

class SportProfileScreen extends ConsumerWidget {
  const SportProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportAsync = ref.watch(selectedSportStateProvider);

    return PFlushOnPop(
      onFlush: () {
        final sport = sportAsync.asData?.value;
        if (sport != null) flushSportProfile(ref, sport);
      },
      child: FScaffold(
        header: FHeader.nested(
          title: Text(
            'profile.sportProfile'.tr(
              args: [
                sportAsync.maybeWhen(
                  data: (s) => s.getLocalizedName(context),
                  orElse: () => '',
                ),
              ],
            ),
          ),
          prefixes: [
            FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: sportAsync.when(
            data: (sport) => switch (sport) {
              Sport.soccer => const SoccerProfileWidget(),
              Sport.basketball => const BasketballProfileWidget(),
              Sport.badminton => const BadmintonProfileWidget(),
              Sport.tennis => const TennisProfileWidget(),
              Sport.pickleball => const PickleballProfileWidget(),
              Sport.others => const SizedBox.shrink(),
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}
