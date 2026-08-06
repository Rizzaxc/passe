import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../ui/main.dart';
import 'change_password_screen.dart';

/// Step-up auth gate for sensitive actions (currently: adding/editing
/// payment info). Resolves `true` once the user has proven they know their
/// account password — either by confirming it now, or, if they've never set
/// one (Google/Apple-only accounts), by setting one up on the spot.
///
/// Resolves `false` if the user backs out at any point.
Future<bool> requirePasswordConfirmation(BuildContext context, WidgetRef ref) async {
  final authNotifier = ref.read(authControllerProvider.notifier);

  if (!authNotifier.hasPasswordCredential()) {
    final didSetUp = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(isInitialSetup: true),
      ),
    );
    // Just having proven the new password by typing it twice is enough
    // proof-of-knowledge — no need to make them confirm it again.
    return didSetUp ?? false;
  }

  if (!context.mounted) return false;
  final confirmed = await showPSheet<bool>(
    context: context,
    builder: (context) => const _ConfirmPasswordSheet(),
  );
  return confirmed ?? false;
}

class _ConfirmPasswordSheet extends ConsumerStatefulWidget {
  const _ConfirmPasswordSheet();

  @override
  ConsumerState<_ConfirmPasswordSheet> createState() => _ConfirmPasswordSheetState();
}

class _ConfirmPasswordSheetState extends ConsumerState<_ConfirmPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;

    final email = ref.read(authControllerProvider).value?.email;
    if (email == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPassword(email: email, password: _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        description: Text(e is AuthException ? 'payment.incorrectPassword'.tr() : 'errorGeneric'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: false,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            PSheetTitle(
              label: 'payment.confirmPasswordTitle'.tr(),
              trailing: FButton.icon(
                variant: .ghost,
                onPress: () => Navigator.of(context).pop(),
                child: const Icon(FLucideIcons.x),
              ),
            ),
            Text(
              'payment.confirmPasswordExplanation'.tr(),
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            FTextFormField.password(
              label: Text('auth.passwordLabel'.tr()),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              control: FTextFieldControl.managed(controller: _passwordController),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'auth.passwordEmpty'.tr();
                }
                return null;
              },
              onSubmit: (_) => _submit(),
            ),
            FButton(
              onPress: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('payment.confirmPasswordAction'.tr()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
