import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class EmptySearch extends StatelessWidget {
  const EmptySearch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 64),
          Icon(
            FIcons.searchX,
            size: 64,
            color: theme.colors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'homeTab.empty.title'.tr(),
            style: theme.typography.xl2.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'homeTab.empty.message'.tr(),
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
