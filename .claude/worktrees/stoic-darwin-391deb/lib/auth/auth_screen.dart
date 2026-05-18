import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../ui/main.dart';
import 'auth_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(title: Text('auth.welcome'.tr())),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthForm(),
            const SizedBox(height: 16),
            const SocialAuthSection(),
          ],
        ),
      ),
    );
  }
}

class AuthForm extends ConsumerStatefulWidget {
  const AuthForm({super.key});

  @override
  ConsumerState<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<AuthForm> {
  final _key = GlobalKey<FormState>(debugLabel: 'auth_form');

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
        String message = 'errorGeneric';

        if (e is AuthException && e.statusCode == '400') {
          message = 'auth.credentialsInvalid';
        }
        showFToast(
          context: context,
          icon: const Icon(FIcons.circleX),
          variant: .destructive,
          title: Text('auth.loginFailed'.tr()),
          description: Text(message.tr()),
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
        String message = 'errorGeneric';
        if (e is AuthException && e.statusCode == '422') {
          message = 'auth.userAlreadyRegistered';
        }
        showFToast(
          context: context,
          icon: const Icon(FIcons.circleX),
          variant: .destructive,
          title: Text('auth.signUpFailed'.tr()),
          description: Text(message.tr()),
          alignment: .bottomCenter,
        );
      }
    }

    return Form(
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
          PDualButton(
            firstChild: Text(
              'auth.signIn'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            secondChild: Text('auth.signUp'.tr()),
            onFirstPressed: onLogin,
            onSecondPressed: onRegister,
            secondVariant: .destructive,
            flex: 60,
          ),
        ],
      ),
    );
  }
}

class SocialAuthSection extends ConsumerWidget {
  final bool showGuestOption;
  const SocialAuthSection({super.key, this.showGuestOption = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleAuthAction(Future<void> Function() action, String errorTitle) async {
      try {
        await action();
      } catch (e) {
        if (!context.mounted) return;
        showFToast(
          context: context,
          icon: const Icon(FIcons.circleX),
          variant: .destructive,
          title: Text(errorTitle),
          description: Text('errorGeneric'.tr()),
          alignment: .bottomCenter,
        );
      }
    }

    const iconBoxWidth = 24.0;
    const contentWidth = 200.0;

    Widget buildRow({
      required Widget icon,
      required String label,
      required VoidCallback onTap,
    }) {
      final buttonStyle = context.theme.buttonStyles.outline.base;

      return FTappable(
        style: buttonStyle.tappableStyle,
        builder: (context, variants, child) => DecoratedBox(
          decoration: buttonStyle.decoration.resolve(variants),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Center(child: child),
          ),
        ),
        onPress: onTap,
        child: SizedBox(
          width: contentWidth,
          child: Row(
            children: [
              SizedBox(
                width: iconBoxWidth,
                child: icon,
              ),
              const SizedBox(width: 16),
              Text(label, style: context.theme.typography.md,),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            buildRow(
              icon: FaIcon(FontAwesomeIcons.google, color: const Color(0xFF4285F4)),
              label: 'auth.googleContinue'.tr(),
              onTap: () => handleAuthAction(
                () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
                'auth.googleLoginFailed'.tr(),
              ),
            ),
            buildRow(
              icon: FaIcon(FontAwesomeIcons.apple, color: context.theme.colors.foreground),
              label: 'auth.appleContinue'.tr(),
              onTap: () => handleAuthAction(
                () => ref.read(authControllerProvider.notifier).signInWithApple(),
                'auth.appleLoginFailed'.tr(),
              ),
            ),
            if (showGuestOption)
              buildRow(
                icon: Icon(FIcons.forward),
                label: 'auth.guestContinue'.tr(),
                onTap: () => handleAuthAction(
                  () => ref.read(authControllerProvider.notifier).continueAsGuest(),
                  'auth.guestLoginFailed'.tr(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
