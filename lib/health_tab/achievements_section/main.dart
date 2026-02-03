import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AchievementsSubtab extends StatelessWidget {
  const AchievementsSubtab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('health.achievements.content'.tr()),
    );
  }
}
