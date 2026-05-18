import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'theme.dart';

class PSectionHeader extends StatelessWidget {
  final String title;
  final Widget? suffix;

  const PSectionHeader({super.key, required this.title, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.theme.typography.xl2.copyWith(fontWeight: .bold),
          ),
        ),
        if (suffix != null) suffix!,
      ],
    );
  }
}
