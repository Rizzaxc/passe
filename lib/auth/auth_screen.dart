import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forui/forui.dart';

import 'auth_controller.dart';

class AuthScreen extends StatefulHookConsumerWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreen();
}

class _AuthScreen extends ConsumerState<AuthScreen> {
  final _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    String email = '';
    String pass = '';

    Future<void> onLogin() async {
      final state = _key.currentState;
      if (state == null || !state.validate()) return;

      state.save();
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPassword(email: email, password: pass);
    }

    Future<void> onRegister() async {
      final state = _key.currentState;
      if (state == null || !state.validate()) return;
      state.save();

      await ref
          .read(authControllerProvider.notifier)
          .signUpWithPassword(email: email, password: pass);
    }

    return FScaffold(
      header: FHeader(title: const Text('Welcome')),
      child: FTabs(
        children: [
          FTabEntry(
            label: const Text('Login'),
            child: Form(
              key: _key,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Forui text fields fallback to Material if unavailable
                    FTextFormField.email(
                      label: const Text('Email'),
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: .onUserInteraction,
                      clearable: (value) => value.text.isNotEmpty,
                      autofillHints: const [AutofillHints.email],
                      onSaved: (value) => email = value ?? '',
                    ),
                    const SizedBox(height: 12),
                    FTextFormField.password(
                      label: const Text('Password'),
                      clearable: (value) => value.text.isNotEmpty,
                      autovalidateMode: .onUserInteraction,
                      autofillHints: const [AutofillHints.password],
                      onSaved: (value) => pass = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    FButton(onPress: onLogin, child: const Text('Login')),
                    const SocialAuthSection(),
                  ],
                ),
              ),
            ),
          ),
          FTabEntry(
            label: const Text('Sign Up'),
            child: Form(
              key: _key,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FTextFormField.email(
                      label: const Text('Email'),
                      keyboardType: TextInputType.emailAddress,
                      clearable: (value) => value.text.isNotEmpty,
                      autovalidateMode: .onUserInteraction,

                      autofillHints: const [AutofillHints.email],
                      onSaved: (value) => email = value ?? '',
                    ),
                    const SizedBox(height: 12),
                    FTextFormField.password(
                      label: const Text('Password'),
                      clearable: (value) => value.text.isNotEmpty,
                      autovalidateMode: .onUserInteraction,
                      autofillHints: const [AutofillHints.newPassword],
                      onSaved: (value) => pass = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    FButton(
                      onPress: onRegister,
                      child: const Text('Create account'),
                    ),
                    const SocialAuthSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SocialAuthSection extends ConsumerWidget {
  const SocialAuthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        FButton(
          style: FButtonStyle.outline(),
          onPress: () =>
              ref.read(authControllerProvider.notifier).signInWithGoogle(),
          prefix: const Icon(FontAwesomeIcons.google),
          child: const Text('Continue with Google'),
        ),
        const SizedBox(height: 12),
        FButton(
          style: FButtonStyle.outline(),
          onPress: () =>
              ref.read(authControllerProvider.notifier).signInWithApple(),
          prefix: const Icon(FontAwesomeIcons.apple),
          child: const Text('Continue with Apple'),
        ),
        const SizedBox(height: 12),
        FButton(
          style: FButtonStyle.secondary(),
          onPress: () =>
              ref.read(authControllerProvider.notifier).continueAsGuest(),
          prefix: const Icon(FIcons.forward),
          child: const Text('Continue as Guest'),
        ),
      ],
    );
  }
}
