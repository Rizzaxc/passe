import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../ui/main.dart';
import '../invite_link/redeem_code_sheet.dart';
import 'lobby_form_sheet.dart';

enum _LobbyAddChoice { create, redeem }

/// Manage ▸ Lobby's "+": start a new lobby, or join one from an invite code
/// someone sent you. The second path is the stand-in for a deferred deep
/// link — a store install loses the `passe.vn/invite/CODE` tap.
Future<void> showLobbyAddSheet(BuildContext context, WidgetRef ref) async {
  final choice = await showPSheet<_LobbyAddChoice>(
    context: context,
    builder: (sheetContext) => SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'manageTab.lobby.add.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(sheetContext).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTileGroup(
            children: [
              FTile(
                prefix: const Icon(FLucideIcons.shieldPlus),
                title: Text('manageTab.lobby.add.create'.tr()),
                subtitle: Text(
                  'manageTab.lobby.add.createSubtitle'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                suffix: const Icon(FLucideIcons.chevronRight),
                onPress: () =>
                    Navigator.of(sheetContext).pop(_LobbyAddChoice.create),
              ),
              FTile(
                prefix: const Icon(FLucideIcons.ticket),
                title: Text('lobby.inviteLink.redeemTitle'.tr()),
                subtitle: Text(
                  'manageTab.lobby.add.redeemSubtitle'.tr(),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                suffix: const Icon(FLucideIcons.chevronRight),
                onPress: () =>
                    Navigator.of(sheetContext).pop(_LobbyAddChoice.redeem),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case _LobbyAddChoice.create:
      await createLobbyAndOpen(context, ref);
    case _LobbyAddChoice.redeem:
      await showRedeemInviteCodeSheet(context);
  }
}
