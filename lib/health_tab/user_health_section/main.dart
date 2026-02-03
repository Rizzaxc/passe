import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UserHealthSubtab extends StatelessWidget {
  const UserHealthSubtab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('health.userHealth.content'.tr()),
    );
  }
}
