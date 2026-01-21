import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'network_selection_screen.dart';

class NetworkEmptyPlaceholder extends StatelessWidget {
  const NetworkEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        FLabel(axis: .horizontal, child: Text('profile.networkLabel'.tr())),
        FTappable(child: FCard(subtitle: Text('profile.empty_network'.tr()))),
      ],
    );
  }
}
