import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../core/sport_selector.dart';
import '../router.dart';
import '../ui/main.dart';

class HealthTab extends StatelessWidget {
  const HealthTab({super.key});

  static final instance = HealthTab();

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: FHeader(
        title: const Text('Health'),
        suffixes: [
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: const Center(
        child: Text('Health Content'),
      ),
    );
  }
}
