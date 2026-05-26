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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            // height: 1.0 collapses the title's line-box to the glyph
            // height so it visually centers with the suffix button
            // (and matches the professional subtab's title alignment).
            style: context.theme.typography.xl2.copyWith(
              fontWeight: .bold,
              height: 1.0,
            ),
          ),
        ),
        ?suffix,
      ],
    );
  }
}
