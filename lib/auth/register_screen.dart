import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pubox/auth/services/auth_service.dart';
import 'package:pubox/auth/widgets/auth_button.dart';
import 'package:pubox/auth/widgets/auth_input.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AuthInput(
              controller: _emailController,
              labelText: 'Email',
            ),
            const SizedBox(height: 16),
            AuthInput(
              controller: _passwordController,
              labelText: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AuthButton(
              onPressed: () async {
                // await ref.read(authServiceProvider).signUp(
                //       _emailController.text,
                //       _passwordController.text,
                //     );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              text: 'Register',
            ),
          ],
        ),
      ),
    );
  }
}
