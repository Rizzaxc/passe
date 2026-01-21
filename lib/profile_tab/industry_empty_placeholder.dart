import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'industry_selection_screen.dart';

class IndustryEmptyPlaceholder extends StatelessWidget {
  const IndustryEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        FLabel(
          axis: .horizontal,
          child: const Text('Username'),
        ),
        FCard(
          subtitle: Text('profile.empty_industry'.tr()),
        ),
      ],
    );
  }
}
