import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'auth_controller.dart';

/// Step 2 of password recovery: verify the emailed OTP and set a new password.
///
/// On success the controller's `updateUser` fires `userUpdated`, which the auth
/// listener turns into a signed-in state — the router then navigates to Home,
/// so this screen does not pop manually.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'reset_password_form');
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).resetPasswordWithOtp(
            email: widget.email,
            token: _otpController.text.trim(),
            newPassword: _passwordController.text,
          );

      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleCheck),
        title: Text('auth.passwordResetSuccess'.tr()),
        alignment: .bottomCenter,
      );
      // Auth state refresh drives navigation to Home; nothing to pop here.
    } catch (e) {
      if (!mounted) return;
      // A bad/expired code is the common, actionable failure.
      final description = e is AuthException
          ? 'auth.otpInvalidOrExpired'.tr()
          : 'errorGeneric'.tr();
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('auth.resetFailed'.tr()),
        description: Text(description),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      resizeToAvoidBottomInset: false,
      header: FHeader(
        title: Text('auth.resetPasswordTitle'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'auth.resetPasswordInstruction'.tr(args: [widget.email]),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              FTextFormField(
                label: Text('auth.otpLabel'.tr()),
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                control: FTextFieldControl.managed(controller: _otpController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.otpEmpty'.tr();
                  }
                  if (value.trim().length != 6) {
                    return 'auth.otpInvalid'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FTextFormField.password(
                label: Text('auth.newPasswordLabel'.tr()),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofillHints: const [AutofillHints.newPassword],
                control: FTextFieldControl.managed(
                  controller: _passwordController,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.passwordEmpty'.tr();
                  }
                  if (value.length < 8) {
                    return 'auth.passwordLength'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FTextFormField.password(
                label: Text('auth.confirmPasswordLabel'.tr()),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.passwordEmpty'.tr();
                  }
                  if (value != _passwordController.text) {
                    return 'auth.passwordMismatch'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('auth.resetPassword'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
