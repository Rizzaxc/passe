import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'icon/main.dart';
import 'model/enum.dart';
import 'state/selected_sport_state.dart';

enum Notification { all, direct, nothing }

class SportSelector extends ConsumerWidget {
  const SportSelector({super.key});

  static Widget _getSportIcon(Sport sport, {double size = 12}) {
    switch (sport) {
      case Sport.soccer:
        return SportIcons.soccer(size: size);
      case Sport.basketball:
        return SportIcons.basketball(size: size);
      case Sport.badminton:
        return SportIcons.badminton(size: size);
      case Sport.tennis:
        return SportIcons.tennis(size: size);
      case Sport.pickleball:
        return SportIcons.pickleball(size: size);
      case Sport.others:
        return const Icon(Icons.question_mark, size: 24);
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSportAsync = ref.watch(selectedSportStateProvider);
    final alertShown = ref.watch(othersAlertShownProvider);

    if (selectedSportAsync.value == Sport.others && !alertShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ref.read(othersAlertShownProvider)) {
          showFToast(
            context: context,
            title: Text(tr('sport.sportNotSelected')),
            description: Text(tr('sport.othersAlertDescription')),
            duration: null,
            icon: const Icon(FIcons.triangleAlert),
          );
          ref.read(othersAlertShownProvider.notifier).setShown();
        }
      });
    }

    return selectedSportAsync.when(
      data: (selectedSport) {
        return FPopoverMenu(
          menuAnchor: Alignment.topRight,
          childAnchor: Alignment.bottomRight,
          menu: [
            FItemGroup(
              children: Sport.values
                  .where((s) => s != Sport.others)
                  .map((sport) {
                final isSelected = sport == selectedSport;
                return FItem(
                  prefix: _getSportIcon(sport),
                  title: Text(sport.getLocalizedName(context)),
                  details: isSelected ? const Icon(FIcons.check) : null,
                  selected: isSelected,
                  onPress: () {
                    ref.read(selectedSportStateProvider.notifier).change(sport);
                  },
                );
              }).toList(),
            ),
          ],
          builder: (context, controller, child) {
            return FHeaderAction(
              icon: _getSportIcon(selectedSport),
              onPress: controller.toggle,
            );
          },
        );
      },
      loading: () => FButton.icon(
        style: FButtonStyle.ghost(),
        onPress: null,
        child: const Icon(Icons.question_mark, size: 24),
      ),
      error: (err, stack) => FButton.icon(
        style: FButtonStyle.ghost(),
        onPress: null,
        child: const Icon(FIcons.triangleAlert),
      ),
    );
  }
}
