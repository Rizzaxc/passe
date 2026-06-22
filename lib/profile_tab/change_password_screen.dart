import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(_passwordController.text);

      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleCheck),
        title: Text('profile.passwordChanged'.tr()),
        alignment: .bottomCenter,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showFToast(
        context: context,
        icon: const Icon(FLucideIcons.circleX),
        variant: .destructive,
        title: Text('error'.tr()),
        description: Text('errorGeneric'.tr()),
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
        title: Text('profile.changePassword'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FTextFormField.password(
                label: Text('profile.newPassword'.tr()),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                control: FTextFieldControl.managed(
                  controller: _passwordController,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.passwordEmpty'.tr();
                  }
                  if (value.length < 8) {
                    return 'profile.passwordTooShort'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FTextFormField.password(
                label: Text('profile.confirmPassword'.tr()),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.passwordEmpty'.tr();
                  }
                  if (value != _passwordController.text) {
                    return 'profile.passwordMismatch'.tr();
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
                    : Text('profile.changePassword'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
