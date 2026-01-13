import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NeutralSubtab extends StatelessWidget {
  const NeutralSubtab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('home.neutral'.tr()));
  }
}
