import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'model/enum.dart';
import 'state/selected_sport_state.dart';

enum Notification { all, direct, nothing }

class SportSelector extends ConsumerWidget {
  const SportSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSportAsync = ref.watch(selectedSportStateProvider);

    return selectedSportAsync.when(
      data: (selectedSport) {
        FPopoverController? popoverController;
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
                  prefix: sport.getIcon(),
                  title: Text(sport.getLocalizedName(context)),
                  details: isSelected ? const Icon(FLucideIcons.check) : null,
                  selected: isSelected,
                  onPress: () {
                    ref.read(selectedSportStateProvider.notifier).change(sport);
                    popoverController?.hide();
                  },
                );
              }).toList(),
            ),
          ],
          builder: (context, controller, child) {
            popoverController = controller;
            return FHeaderAction(
              icon: selectedSport.getIcon(),
              onPress: controller.toggle,
            );
          },
        );
      },
      loading: () => FButton.icon(
        variant: .ghost,
        onPress: null,
        child: const Icon(Icons.question_mark, size: 24),
      ),
      error: (err, stack) => FButton.icon(
        variant: .ghost,
        onPress: null,
        child: const Icon(FLucideIcons.triangleAlert),
      ),
    );
  }
}
