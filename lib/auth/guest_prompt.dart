import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../router.dart';
import '../ui/sheet.dart';
import 'auth_controller.dart';

/// Returns true if the user is signed in. If they're a guest, shows a sign-in
/// rationale sheet and returns false — call this at the top of any action a
/// guest can't complete (join a lobby, RSVP, vote, schedule) so the tap gets a
/// prompt instead of a silent no-op / RLS failure.
bool ensureSignedIn(BuildContext context, WidgetRef ref) {
  final userId = ref.read(currentUserIdProvider);
  if (userId != null) return true;
  showPSheet(context: context, builder: (_) => const _GuestPromptSheet());
  return false;
}

class _GuestPromptSheet extends StatelessWidget {
  const _GuestPromptSheet();

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
            label: 'auth.guestPrompt.title'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Icon(FLucideIcons.logIn, size: 22, color: colors.primary),
              Expanded(
                child: Text(
                  'auth.guestPrompt.body'.tr(),
                  style: context.theme.typography.body.sm
                      .copyWith(color: colors.mutedForeground, height: 1.5),
                ),
              ),
            ],
          ),
          FButton(
            onPress: () {
              Navigator.of(context).pop();
              const WelcomeRoute().go(context);
            },
            child: Text('auth.guestPrompt.cta'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
