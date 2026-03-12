import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/model/enum.dart';
import '../../core/state/selected_sport_state.dart';
import 'badminton.dart' show BadmintonProfileWidget;
import 'basketball.dart' show BasketballProfileWidget;
import 'pickleball.dart' show PickleballProfileWidget;
import 'soccer.dart' show SoccerProfileWidget;
import 'sport_profile_controller.dart';
import 'tennis.dart' show TennisProfileWidget;

class SportProfileScreen extends ConsumerWidget {
  const SportProfileScreen({super.key});

  Future<void> _commit(WidgetRef ref, Sport sport) => switch (sport) {
        Sport.soccer =>
          ref.read(soccerProfileControllerProvider.notifier).commit(),
        Sport.basketball =>
          ref.read(basketballProfileControllerProvider.notifier).commit(),
        Sport.badminton =>
          ref.read(badmintonProfileControllerProvider.notifier).commit(),
        Sport.tennis =>
          ref.read(tennisProfileControllerProvider.notifier).commit(),
        Sport.pickleball =>
          ref.read(pickleballProfileControllerProvider.notifier).commit(),
        Sport.others => Future.value(),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportAsync = ref.watch(selectedSportStateProvider);

    return FScaffold(
      header: FHeader(
        title: Text('profile.sportProfile'.tr(args: [
          sportAsync.maybeWhen(
            data: (s) => s.getLocalizedName(context),
            orElse: () => '',
          ),
        ])),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sportAsync.when(
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
            const SizedBox(height: 24),
            FButton(
              onPress: () async {
                final sport = sportAsync.asData?.value;
                if (sport == null) return;
                try {
                  await _commit(ref, sport);
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (!context.mounted) return;
                  showFToast(
                    context: context,
                    title: Text('error'.tr()),
                    description: Text('errorGeneric'.tr()),
                    alignment: .bottomCenter,
                  );
                }
              },
              child: Text('profile.commit'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
