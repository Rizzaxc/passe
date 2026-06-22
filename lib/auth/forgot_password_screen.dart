import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../router.dart';
import 'auth_controller.dart';

/// Step 1 of password recovery: collect the email and trigger the reset code.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'forgot_password_form');
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendPasswordResetCode(email);

      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleCheck),
        title: Text('auth.resetCodeSent'.tr()),
        description: Text('auth.resetCodeSentDescription'.tr()),
        alignment: .bottomCenter,
      );
      // Proceed to the verify + new-password step.
      ResetPasswordRoute(email: email).push<void>(context);
    } catch (e) {
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('auth.resetFailed'.tr()),
        description: Text('auth.resetEmailFailed'.tr()),
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
        title: Text('auth.forgotPasswordTitle'.tr()),
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
                'auth.forgotPasswordInstruction'.tr(),
                style: context.theme.typography.body.sm.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              FTextFormField.email(
                label: Text('auth.emailLabel'.tr()),
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofillHints: const [AutofillHints.email],
                control: FTextFieldControl.managed(
                  controller: _emailController,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.emailEmpty'.tr();
                  }
                  final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'auth.emailInvalid'.tr();
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
                    : Text('auth.sendResetCode'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
