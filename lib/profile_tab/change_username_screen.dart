import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';

class ChangeUsernameScreen extends ConsumerStatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  ConsumerState<ChangeUsernameScreen> createState() =>
      _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends ConsumerState<ChangeUsernameScreen> {
  static final _alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = _formKey.currentState;
    if (state == null || !state.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changeUsername(_usernameController.text.trim());

      if (!mounted) return;
      Navigator.of(context).pop();
    } on UsernameTakenException {
      if (!mounted) return;
      showFToast(
        context: context,
        title: Text('profile.usernameTaken'.tr()),
        alignment: .bottomCenter,
      );
    } catch (e) {
      if (!mounted) return;
      showFToast(
        context: context,
        title: Text('error'.tr()),
        description: Text('error_generic'.tr()),
        alignment: .bottomCenter,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag =
        ref.watch(authControllerProvider).value?.tagNumber ?? '0000';

    return FScaffold(
      header: FHeader(
        title: Text('profile.changeUsername'.tr()),
        suffixes: [
          FHeaderAction.back(onPress: () => Navigator.of(context).pop()),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FTextFormField(
                label: Text('profile.newUsername'.tr()),
                maxLength: 16,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                control: FTextFieldControl.managed(
                  controller: _usernameController,
                ),
                suffixBuilder: (context, _, __) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '#$tag',
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile.newUsername'.tr();
                  }
                  if (!_alphanumericRegex.hasMatch(value.trim())) {
                    return 'profile.usernameInvalidChars'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FTextFormField(
                label: Text('profile.confirmUsername'.tr()),
                maxLength: 16,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                suffixBuilder: (context, _, __) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '#$tag',
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'profile.confirmUsername'.tr();
                  }
                  if (value.trim() != _usernameController.text.trim()) {
                    return 'profile.usernameMismatch'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: _isLoading ? null : _submit,
                style: FButtonStyle.primary(),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('profile.changeUsername'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
