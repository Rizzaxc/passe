import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../ui/main.dart';

class SportEmptyPlaceholder extends StatelessWidget {
  const SportEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return PCard(subtitle: Text('profile.sportFeatureExplanation'.tr()));
  }
}
