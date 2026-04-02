import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../ui/empty_section_placeholder.dart';

class UserHealthSubtab extends StatelessWidget {
  const UserHealthSubtab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PEmptySectionPlaceholder(
          subtitle: 'health.userHealth.content'.tr(),
        ),
      ],
    );
  }
}
