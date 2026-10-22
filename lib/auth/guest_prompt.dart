import 'package:easy_localization/easy_localization.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
            // Not WelcomeRoute: for a guest the router treats /welcome as an
            // auth-flow page and bounces straight back to `pendingDestination`
            // (where they already are), so the button did nothing. The Profile
            // tab embeds the sign-in form for guests — one place to sign in.
            //
            // Close every sheet, not just this one: the prompt is often
            // stacked on another sheet (the lobby preview's "Xin vào"), and
            // a navigation under a still-open sheet looks like nothing
            // happened.
            onPress: () {
              Navigator.of(
                context,
                rootNavigator: true,
              ).popUntil((route) => route is! PopupRoute);
              const ProfileRoute().go(context);
            },
            child: Text('auth.guestPrompt.cta'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
