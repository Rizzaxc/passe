import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../auth/auth_screen.dart';

class GuestProfileView extends StatelessWidget {
  const GuestProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            style: context.theme.typography.md.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthForm(),
                const SocialAuthSection(showGuestOption: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
