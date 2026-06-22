import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class SportEmptyPlaceholder extends StatelessWidget {
  const SportEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return FCard(
      subtitle: Text('profile.sportFeatureExplanation'.tr()),
    );
  }
}
