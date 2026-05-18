import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'theme.dart';

class PEmptySectionPlaceholder extends StatelessWidget {
  final Widget? hero;
  final String? title;
  final String subtitle;

  const PEmptySectionPlaceholder({
    super.key,
    this.hero,
    this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hero != null) ...[
            hero!,
            const SizedBox(height: 16),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: context.theme.typography.xl2.copyWith(fontWeight: .bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            subtitle,
            style: context.theme.typography.sm.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
