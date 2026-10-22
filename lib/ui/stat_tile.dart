import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

import 'level_slider.dart';

/// One headline number with its meaning: a small caps label, a large Bitter
/// numeral, the word that interprets it, an optional segmented meter, and a
/// footnote. Light card surface — a stat is information, not a banner, so it
/// doesn't borrow the navy `PMatchBoard`.
class PStatTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String value;
  final String? caption;

  /// Filled / total segments, e.g. tier 3 of 5. Null hides the meter.
  final (int, int)? meter;
  final Widget? footer;

  const PStatTile({
    super.key,
    required this.label,
    this.icon,
    required this.value,
    this.caption,
    this.meter,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 6,
            children: [
              if (icon != null)
                Icon(icon, size: 14, color: colors.mutedForeground),
              Text(
                label.toUpperCase(),
                style: typography.body.xs.copyWith(
                  color: colors.mutedForeground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  height: 1.0,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 10,
            children: [
              Text(
                value,
                style: typography.body.xl3.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              if (caption != null)
                Flexible(
                  child: Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.lg.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ),
          if (meter case (final filled, final total))
            PLevelSlider(count: total, value: filled - 1),
          ?footer,
        ],
      ),
    );
  }
}
