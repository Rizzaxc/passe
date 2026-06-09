import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Stacked 3-zone time bar (easy / moderate / hard) with a minute legend.
class ZoneBar extends StatelessWidget {
  final int easy;
  final int moderate;
  final int hard;
  final bool compact;

  const ZoneBar({
    super.key,
    required this.easy,
    required this.moderate,
    required this.hard,
    this.compact = false,
  });

  static const _easyColor = Color(0xFF4F94CD); // calm blue
  static const _moderateColor = Color(0xFFE0A800); // amber

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final hardColor = colors.primary;
    final total = easy + moderate + hard;
    if (total == 0) return const SizedBox.shrink();

    final segments = <(int, Color)>[
      (easy, _easyColor),
      (moderate, _moderateColor),
      (hard, hardColor),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              for (final (seconds, color) in segments)
                if (seconds > 0)
                  Expanded(
                    flex: seconds,
                    child: Container(height: compact ? 6 : 10, color: color),
                  ),
            ],
          ),
        ),
        if (!compact)
          Row(
            spacing: 12,
            children: [
              _Legend(color: _easyColor, label: 'health.zone.easy'.tr(), seconds: easy),
              _Legend(color: _moderateColor, label: 'health.zone.moderate'.tr(), seconds: moderate),
              _Legend(color: hardColor, label: 'health.zone.hard'.tr(), seconds: hard),
            ],
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int seconds;
  const _Legend({required this.color, required this.label, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds / 60).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        Text(
          '$label ${minutes}m',
          style: context.theme.typography.xs.copyWith(color: context.theme.colors.mutedForeground),
        ),
      ],
    );
  }
}
