import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forui/forui.dart';

import 'auth_controller.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final regEmailCtrl = TextEditingController();
    final regPassCtrl = TextEditingController();

    Future<void> onLogin() async {
      final email = emailCtrl.text.trim();
      final pass = passCtrl.text;
      if (email.isEmpty || pass.isEmpty) return;
      await ref
          .read(authControllerProvider.notifier)
          .signInWithPassword(email: email, password: pass);
    }

    Future<void> onRegister() async {
      final email = regEmailCtrl.text.trim();
      final pass = regPassCtrl.text;
      if (email.isEmpty || pass.isEmpty) return;
      await ref
          .read(authControllerProvider.notifier)
          .signUpWithPassword(email: email, password: pass);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Sign Up'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Login Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Forui text fields fallback to Material if unavailable
                  FTextField(
                    controller: emailCtrl,
                    label: const Text('Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  FTextField(
                    controller: passCtrl,
                    label: const Text('Password'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 16),
                  // Forui primary button
                  FButton(onPress: onLogin, child: const Text('Login')),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                          prefix: const Icon(Icons.g_mobiledata),
                          child: const Text('Continue with Google'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithApple(),
                          prefix: const Icon(Icons.apple),
                          child: const Text('Continue with Apple'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sign Up Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FTextField(
                    controller: regEmailCtrl,
                    label: const Text('Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  FTextField(
                    controller: regPassCtrl,
                    label: const Text('Password'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 16),
                  FButton(
                    onPress: onRegister,
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                          prefix: const Icon(Icons.g_mobiledata),
                          child: const Text('Continue with Google'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          style: FButtonStyle.outline(),
                          onPress: () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithApple(),
                          prefix: const Icon(Icons.apple),
                          child: const Text('Continue with Apple'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
