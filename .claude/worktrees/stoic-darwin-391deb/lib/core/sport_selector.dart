import 'package:easy_localization/easy_localization.dart';
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
    final alertShown = ref.watch(othersAlertShownProvider);

    if (selectedSportAsync.value == Sport.others && !alertShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!ref.read(othersAlertShownProvider)) {
          ref.read(othersAlertShownProvider.notifier).setShown();
          showFDialog(
            context: context,
            barrierDismissible: false,
            useRootNavigator: true,
            builder: (dialogContext, style, animation) => PopScope(
              canPop: false,
              child: FDialog(
                animation: animation,
                title: Text(tr('sport.sportNotSelected')),
                body: Text(tr('sport.othersAlertDescription')),
                direction: Axis.vertical,
                actions: [
                  for (final sport in Sport.values.where((s) => s != Sport.others))
                    FButton(
                      variant: .outline,
                      prefix: sport.getIcon(),
                      onPress: () {
                        ref.read(selectedSportStateProvider.notifier).change(sport);
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(sport.getLocalizedName(dialogContext)),
                    ),
                ],
              ),
            ),
          );
        }
      });
    }

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
                  details: isSelected ? const Icon(FIcons.check) : null,
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
        child: const Icon(FIcons.triangleAlert),
      ),
    );
  }
}
