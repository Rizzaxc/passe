import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';

class SportEmptyPlaceholder extends StatelessWidget {
  final String sportName;

  const SportEmptyPlaceholder({
    super.key,
    required this.sportName,
  });

  @override
  Widget build(BuildContext context) {
    return FCard(
      subtitle: Text('profile.sport_feature_explanation'.tr()),
    );
  }
}
