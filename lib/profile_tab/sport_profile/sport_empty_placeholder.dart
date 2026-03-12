import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';

class SportEmptyPlaceholder extends StatelessWidget {
  const SportEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return FCard(
      subtitle: Text('profile.sportFeatureExplanation'.tr()),
    );
  }
}
