import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../ui/main.dart';
import '../challenge/friendly_offer_controller.dart';
import '../challenge/friendly_offer_sheet.dart';
import '../schedule_activity_sheet.dart';

/// The planner's "+": a private session for the lobby, or a challenge offer
/// for other teams. [atCap] disables the first (the activity limit) without
/// blocking the second.
Future<void> showPlannerAddSheet(
  BuildContext context,
  String lobbyId, {
  required bool atCap,
}) async {
  final challenge = await showPSheet<bool>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (_, ref, _) {
        final open =
            ref
                .watch(friendlyOfferControllerProvider(lobbyId))
                .value
                ?.open
                .length ??
            0;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              PSheetTitle(
                label: 'challenge.findOpponent.addTitle'.tr(),
                trailing: FButton.icon(
                  variant: .ghost,
                  onPress: () => Navigator.of(sheetContext).pop(),
                  child: const Icon(FLucideIcons.x),
                ),
              ),
              FTileGroup(
                children: [
                  FTile(
                    prefix: const Icon(FLucideIcons.calendarPlus),
                    title: Text('challenge.findOpponent.schedule'.tr()),
                    subtitle: Text('challenge.findOpponent.scheduleHint'.tr()),
                    suffix: const Icon(FLucideIcons.chevronRight),
                    onPress: atCap
                        ? null
                        : () => Navigator.of(sheetContext).pop(false),
                  ),
                  FTile(
                    prefix: const Icon(FLucideIcons.swords),
                    title: Text('challenge.findOpponent.challenge'.tr()),
                    subtitle: Text(
                      open == 0
                          ? 'challenge.findOpponent.challengeHint'.tr()
                          : 'challenge.findOpponent.openCount'.tr(
                              namedArgs: {
                                'count': '$open',
                                'max': '${ChallengeOfferBoard.maxSlots}',
                              },
                            ),
                    ),
                    suffix: const Icon(FLucideIcons.chevronRight),
                    onPress: () => Navigator.of(sheetContext).pop(true),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
  );
  if (challenge == null || !context.mounted) return;
  if (challenge) {
    await openChallengeComposer(context, lobbyId);
  } else {
    await showScheduleActivitySheet(context, lobbyId);
  }
}
