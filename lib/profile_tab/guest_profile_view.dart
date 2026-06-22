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
            FLucideIcons.userX,
            size: 80,
            color: context.theme.colors.mutedForeground,
          ),
          const SizedBox(height: 24),
          Text(
            'profile.guestTitle'.tr(),
            style: context.theme.typography.body.xl2.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'profile.guestMessage'.tr(),
            style: context.theme.typography.body.md.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mirror the welcome flow's hierarchy: social sign-in is the
                // default, expected path (shown big, up front), email/password
                // is the secondary fallback below an "or" divider.
                const SocialAuthSection(showGuestOption: false),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'auth.orDivider'.tr(),
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                const AuthForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
