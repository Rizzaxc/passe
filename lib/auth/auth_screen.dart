import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, PostgrestException;

import '../ui/main.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulHookConsumerWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreen();
}

class _AuthScreen extends ConsumerState<AuthScreen> {
  final _key = GlobalKey<FormState>(debugLabel: 'auth_screen_form');


  @override
  Widget build(BuildContext context) {
    String email = '';
    String pass = '';

    Future<void> onLogin() async {
      final state = _key.currentState;
      if (state == null || !state.validate()) return;

      state.save();
      try {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithPassword(email: email, password: pass);
      } catch (e) {
        if (!context.mounted) return;
        String message = 'error_generic'.tr();
        if (e is AuthException && e.message.contains('Invalid login credentials')) {
          message = e.message;
        }
        showFToast(
          context: context,
          title: Text('auth.loginFailed'.tr()),
          description: Text(message),
          alignment: .bottomCenter,
        );
      }
    }

    Future<void> onRegister() async {
      final state = _key.currentState;
      if (state == null || !state.validate()) return;
      state.save();

      try {
        await ref
            .read(authControllerProvider.notifier)
            .signUpWithPassword(email: email, password: pass);
      } catch (e) {
        if (!context.mounted) return;
        String message = 'error_generic'.tr();
        if (e is AuthException && e.message.contains('User already registered')) {
          message = e.message;
        }
        showFToast(
          context: context,
          title: Text('auth.signUpFailed'.tr()),
          description: Text(message),
          alignment: .bottomCenter,
        );
      }
    }

    return FScaffold(
      header: FHeader(title: Text('auth.welcome'.tr())),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                onSaved: (value) => email = value ?? '',
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
              const SizedBox(height: 12),
              FTextFormField.password(
                label: Text('auth.passwordLabel'.tr()),
                clearable: (value) => value.text.isNotEmpty,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                autofillHints: const [AutofillHints.password],
                onSaved: (value) => pass = value ?? '',
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
                onFirstPressed: onLogin,
                onSecondPressed: onRegister,
                secondStyle: context.theme.buttonStyles.destructive,
                flex: 60,
              ),
              const SizedBox(height: 16),
              const SocialAuthSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialAuthSection extends ConsumerWidget {
  const SocialAuthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleAuthAction(Future<void> Function() action, String errorTitle) async {
      try {
        await action();
      } catch (e) {
        if (!context.mounted) return;
        showFToast(
          context: context,
          title: Text(errorTitle),
          description: Text('error_generic'.tr()),
          alignment: .bottomCenter,
        );
      }
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        FButton(
          style: FButtonStyle.outline(),
          onPress: () => handleAuthAction(
            () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
            'auth.googleLoginFailed'.tr(),
          ),
          prefix: const Icon(FontAwesomeIcons.google),
          child: Text('auth.googleContinue'.tr()),
        ),
        const SizedBox(height: 12),
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => handleAuthAction(
            () => ref.read(authControllerProvider.notifier).signInWithApple(),
            'auth.appleLoginFailed'.tr(),
          ),
          prefix: const Icon(FontAwesomeIcons.apple),
          child: Text('auth.appleContinue'.tr()),
        ),
        const SizedBox(height: 12),
        FButton(
          style: FButtonStyle.secondary(),
          onPress: () => handleAuthAction(
            () => ref.read(authControllerProvider.notifier).continueAsGuest(),
            'auth.guestLoginFailed'.tr(),
          ),
          prefix: const Icon(FIcons.forward),
          child: Text('auth.guestContinue'.tr()),
        ),
      ],
    );
  }
}
