import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../auth/auth_controller.dart';
import '../ui/main.dart';

void showDeleteAccountSheet(BuildContext context) {
  showPSheet(context: context, builder: (_) => const _DeleteAccountSheet());
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _confirmController = TextEditingController();
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _confirm(String username) async {
    setState(() => _deleting = true);

    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      // signOut() (called by deleteAccount()) drives the router back to
      // Welcome — no explicit navigation needed here, matching every other
      // sign-out path in the app.
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AccountDeletionBlockedException catch (e) {
      if (!mounted) return;
      final key = switch (e.reason) {
        AccountDeletionBlockReason.captain =>
          'profile.deleteAccountBlockedCaptain',
        AccountDeletionBlockReason.host => 'profile.deleteAccountBlockedHost',
      };
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleAlert),
        variant: .destructive,
        title: Text(key.tr()),
        alignment: .bottomCenter,
      );
    } catch (e, st) {
      Talker().handle(e, st, 'Account deletion failed');
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('profile.deleteAccountFailed'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authControllerProvider).value?.username ?? '';
    final colors = context.theme.colors;
    final canConfirm = _confirmController.text == username && !_deleting;

    return SingleChildScrollView(
      primary: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          PSheetTitle(
            label: 'profile.deleteAccountTitle'.tr(),
            trailing: FButton.icon(
              variant: .ghost,
              onPress: () => Navigator.of(context).pop(),
              child: const Icon(FLucideIcons.x),
            ),
          ),
          Text(
            'profile.deleteAccountWarning'.tr(),
            style: TextStyle(color: colors.mutedForeground),
          ),
          Text(
            'profile.deleteAccountConfirmHint'.tr(args: [username]),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          FTextField(
            hint: username,
            control: FTextFieldControl.managed(controller: _confirmController),
          ),
          FButton(
            variant: .destructive,
            onPress: canConfirm ? () => _confirm(username) : null,
            child: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('profile.deleteAccountConfirmButton'.tr()),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
