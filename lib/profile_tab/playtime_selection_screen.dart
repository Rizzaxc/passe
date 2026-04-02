import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/timeslot_picker.dart';
import '../ui/dual_button.dart';
import 'profile_controller.dart';

class PlaytimeSelectionScreen extends ConsumerWidget {
  const PlaytimeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final timeslots = profileState.details.playtime ?? [];

    return FScaffold(
      header: FHeader(
        title: Text('profile.playtimeShort'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // List of selected timeslots
            if (timeslots.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'profile.playtimeExplanation'.tr(),
                    style: context.theme.typography.md.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
              )
            else
              FTileGroup(
                label: const Icon(FIcons.calendarDays),
                children: timeslots
                    .map(
                      (timeslot) => FTile(
                        title: Text(
                          '${timeslot.dayChunk.getShortName(context)} ${timeslot.dayOfWeek.getFullName(context)}',
                        ),
                        suffix: FButton.icon(
                          variant: .ghost,
                          child: Icon(
                            FIcons.trash,
                            color: context.theme.colors.destructive,
                          ),
                          onPress: () {
                            final updatedTimeslots = [...timeslots];
                            updatedTimeslots.remove(timeslot);
                            ref
                                .read(profileControllerProvider.notifier)
                                .updateDraft(
                                  details: profileState.details.copyWith(
                                    playtime: updatedTimeslots,
                                  ),
                                );
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 24),
            PDualButton(
              firstVariant: .outline,
              secondVariant: .outline,
              flex: 85,
              onFirstPressed: () async {
                final timeslot = await showTimeslotPicker(context: context);
                if (timeslot != null) {
                  final updatedTimeslots = [...timeslots];
                  // Check if timeslot already exists
                  if (!updatedTimeslots.contains(timeslot)) {
                    updatedTimeslots.add(timeslot);
                    ref
                        .read(profileControllerProvider.notifier)
                        .updateDraft(
                      details: profileState.details.copyWith(
                        playtime: updatedTimeslots,
                      ),
                    );
                  }
                }
              },
              onSecondPressed: () {
                ref.read(profileControllerProvider.notifier).resetPlaytime();
              },
              firstChild: const Icon(FIcons.plus),
              secondChild: const Icon(FIcons.rotateCcw),
            ),
          ],
        ),
      ),
    );
  }
}
