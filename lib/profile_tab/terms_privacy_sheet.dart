import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../core/legal_links.dart';
import '../ui/main.dart';
import 'delete_account_sheet.dart';

/// [rootContext] is the caller's own context (e.g. `ProfileTab`'s), kept
/// around so the delete-account tile can pop this sheet and immediately open
/// the confirmation sheet on a context that's guaranteed to outlive this
/// one — reusing this sheet's own `context` after popping it races the
/// close animation.
void showTermsPrivacySheet(BuildContext rootContext) {
  showPSheet(
    context: rootContext,
    builder: (_) => _TermsPrivacySheet(rootContext: rootContext),
  );
}

class _TermsPrivacySheet extends StatelessWidget {
  final BuildContext rootContext;

  const _TermsPrivacySheet({required this.rootContext});

  void _openDeleteAccount(BuildContext context) {
    Navigator.of(context).pop();
    if (rootContext.mounted) showDeleteAccountSheet(rootContext);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          PSheetTitle(
            label: 'profile.termsPrivacyTitle'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          FTileGroup(
            children: [
              FTile(
                prefix: const Icon(FLucideIcons.fileText),
                title: Text('auth.termsOfService'.tr()),
                suffix: const Icon(FLucideIcons.externalLink),
                onPress: () => openTermsOfService(context),
              ),
              FTile(
                prefix: const Icon(FLucideIcons.shieldCheck),
                title: Text('auth.privacyNotice'.tr()),
                suffix: const Icon(FLucideIcons.externalLink),
                onPress: () => openPrivacyNotice(context),
              ),
            ],
          ),
          FTileGroup(
            children: [
              FTile(
                style: .delta(
                  backgroundColor: .delta([.all(colors.destructive)]),
                ),
                onPress: () {
                  showFToast(
                    context: context,
                    icon: const Icon(FLucideIcons.trash2),
                    title: Text('profile.confirmDeleteAccountHold'.tr()),
                    duration: const Duration(milliseconds: 1500),
                    alignment: .bottomCenter,
                  );
                },
                onLongPress: () => _openDeleteAccount(context),
                title: Text(
                  'profile.deleteAccount'.tr(),
                  style: TextStyle(color: colors.destructive),
                ),
                details: Icon(FLucideIcons.trash2, color: colors.destructive),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
