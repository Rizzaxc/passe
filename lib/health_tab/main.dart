import 'package:easy_localization/easy_localization.dart';
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
        title: Text('health.title'.tr()),
        suffixes: [
          const NotificationIconButton(),
          const SportSelector(),
        ],
      ),
      child: Center(
        child: Text('health.content'.tr()),
      ),
    );
  }
}
