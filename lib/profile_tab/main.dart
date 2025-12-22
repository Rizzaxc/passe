import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../auth/auth_controller.dart';
import '../core/sport_selector.dart';
import '../ui/main.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  static final instance = ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FScaffold(
      header: FHeader(
        title: const Text('Profile'),
        suffixes: [
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Text('Profile Content'),
            ),
            FButton(
              style: FButtonStyle.destructive(),
              onPress: () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
