import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../auth/auth_controller.dart';
import '../ui/main.dart';

class GuestProfileView extends ConsumerWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon and Message
          Icon(
            FIcons.userX,
            size: 80,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: 24),
          Text(
            'profile.guestTitle'.tr(),
            style: context.theme.typography.xl2.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'profile.guestMessage'.tr(),
            style: context.theme.typography.base.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Embedded auth form
          _GuestAuthForm(),
        ],
      ),
    );
  }
}

class _GuestAuthForm extends ConsumerStatefulWidget {
  const _GuestAuthForm();

  @override
  ConsumerState<_GuestAuthForm> createState() => _GuestAuthFormState();
}

class _GuestAuthFormState extends ConsumerState<_GuestAuthForm> {
  final _key = GlobalKey<FormState>(debugLabel: 'guest_profile_form');
  String _email = '';
  String _password = '';

  Future<void> _onLogin() async {
    final state = _key.currentState;
    if (state == null || !state.validate()) return;

    state.save();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPassword(email: _email, password: _password);
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      showFToast(
        context: context,
        title: Text('auth.loginFailed'.tr()),
        description: Text(e.toString()),
        alignment: .bottomCenter,
      );
    }
  }

  Future<void> _onRegister() async {
    final state = _key.currentState;
    if (state == null || !state.validate()) return;
    state.save();

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUpWithPassword(email: _email, password: _password);
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      showFToast(
        context: context,
        title: Text('auth.signUpFailed'.tr()),
        description: Text(e.toString()),
        alignment: .bottomCenter,
      );
    }
  }

  Future<void> _handleAuthAction(
      Future<void> Function() action, String errorTitle) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      showFToast(
        context: context,
        title: Text(errorTitle),
        description: Text(e.toString()),
        alignment: .bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FCard(
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FTextFormField.email(
              label: Text('auth.emailLabel'.tr()),
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              clearable: (value) => value.text.isNotEmpty,
              autofillHints: const [AutofillHints.email],
              onSaved: (value) => _email = value ?? '',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'auth.emailEmpty'.tr();
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'auth.emailInvalid'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            FTextFormField.password(
              label: Text('auth.passwordLabel'.tr()),
              clearable: (value) => value.text.isNotEmpty,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autofillHints: const [AutofillHints.password],
              onSaved: (value) => _password = value ?? '',
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
            FDualButton(
              firstChild: Text(
                'auth.signIn'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              secondChild: Text('auth.signUp'.tr()),
              onFirstPressed: _onLogin,
              onSecondPressed: _onRegister,
              secondStyle: (styles) => styles.destructive,
              flex: 60,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => _handleAuthAction(
                () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                'auth.googleLoginFailed'.tr(),
              ),
              prefix: Icon(FIcons.globe),
              child: Text('auth.googleContinue'.tr()),
            ),
            const SizedBox(height: 12),
            FButton(
              style: FButtonStyle.outline(),
              onPress: () => _handleAuthAction(
                () => ref.read(authControllerProvider.notifier).signInWithApple(),
                'auth.appleLoginFailed'.tr(),
              ),
              prefix: Icon(Icons.apple),
              child: Text('auth.appleContinue'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
