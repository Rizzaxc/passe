import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'model.dart';

/// Tint helpers used across the wallet screens.
///
/// These mirror the translucent variants in `colors_and_type.css`
/// (`--pb-crimson-tint` etc.) — the design uses them as soft chip /
/// glyph backgrounds.
extension WalletTints on FColors {
  Color get crimsonTint => primary.withValues(alpha: 0.10);
  Color get greenTint => Color(0xFF959D54).withValues(alpha: 0.14);
  Color get blueTint => Color(0xFF3090F2).withValues(alpha: 0.12);
}

/// Card-on-bg surface with the project's standard 12px radius, 1px
/// border, and the subtle FStyle drop shadow.
class WalletCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;

  const WalletCard({
    super.key,
    required this.child,
    this.padding,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: colors.background == const Color(0xFFF4F5EE) ? Colors.white : colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d000000),
            offset: Offset(0, 1),
            blurRadius: 2.5,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Tiny ALL-CAPS section label used above grouped lists in the design.
class WalletSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const WalletSectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Bitter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
          letterSpacing: 0.6,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

/// Coloured payment-method square badge (M / Z / QR / Apple / star).
class PayBadge extends StatelessWidget {
  final DaPayMethod method;
  final double size;

  const PayBadge({super.key, required this.method, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: method.badgeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: method == DaPayMethod.apple
          ? Icon(Icons.apple, color: Colors.white, size: size * 0.7)
          : Text(
              method.badge,
              style: TextStyle(
                fontFamily: 'Bitter',
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
    );
  }
}

/// Outline icon used for spend-kind glyphs in transaction rows.
class SpendKindGlyph extends StatelessWidget {
  final DaSpendKind kind;
  final Color color;
  final double size;

  const SpendKindGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      DaSpendKind.confirm => FLucideIcons.check,
      DaSpendKind.venue => FLucideIcons.mapPin,
      DaSpendKind.coach => FLucideIcons.userPlus,
      DaSpendKind.split => FLucideIcons.split,
      DaSpendKind.fee => FLucideIcons.flag,
      DaSpendKind.refund => FLucideIcons.arrowDown,
    };
    return Icon(icon, size: size, color: color);
  }
}

/// Standard back-button row used as the wallet's stack header.
class WalletStackHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const WalletStackHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    // FScaffold doesn't auto-wrap its `header` slot in a SafeArea — the
    // built-in FHeader does that itself. Since this is a custom header,
    // we have to apply the top inset here so the back button isn't
    // covered by the status bar / notch.
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 8, 14),
        child: Row(
          children: [
            FButton.icon(
              variant: .ghost,
              onPress: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
              child: Icon(FLucideIcons.chevronLeft, size: 22, color: colors.foreground),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Bitter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: colors.foreground,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Vertically stacked metric pair used in the summary card on the
/// purchase / spending history screens.
class WalletSummaryCard extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String leftSuffix;
  final Color leftColor;
  final String rightLabel;
  final String rightValue;
  final String rightSuffix;
  final Color rightColor;

  const WalletSummaryCard({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.leftSuffix,
    required this.leftColor,
    required this.rightLabel,
    required this.rightValue,
    required this.rightSuffix,
    required this.rightColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return WalletCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: leftLabel,
              value: leftValue,
              suffix: leftSuffix,
              color: leftColor,
            ),
          ),
          Container(width: 1, height: 36, color: colors.border),
          const SizedBox(width: 16),
          Expanded(
            child: _Metric(
              label: rightLabel,
              value: rightValue,
              suffix: rightSuffix,
              color: rightColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final Color color;

  const _Metric({
    required this.label,
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Bitter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: 0.6,
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -0.4,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              suffix,
              style: TextStyle(
                fontFamily: 'Bitter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1,
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Empty-state placeholder matching the design's plain centred copy.
class WalletEmpty extends StatelessWidget {
  final String message;

  const WalletEmpty({super.key, this.message = 'Chưa có hoạt động nào trong mục này'});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Bitter',
          fontSize: 13,
          height: 1.5,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

/// Small "DATE" header above each day's transaction group.
class WalletDateLabel extends StatelessWidget {
  final String date;

  const WalletDateLabel(this.date, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        date.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Bitter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1,
          letterSpacing: 0.6,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

/// Pill-shaped status badge (e.g. "Chờ xác nhận", "Thất bại").
class WalletStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const WalletStatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Bitter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
          color: color,
        ),
      ),
    );
  }
}

/// Groups a list of items by their `date` field, in reverse chrono order.
List<({String date, List<T> items})> groupByDate<T>(
  List<T> items,
  String Function(T) dateOf,
) {
  final map = <String, List<T>>{};
  for (final it in items) {
    map.putIfAbsent(dateOf(it), () => []).add(it);
  }
  final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
  return keys.map((d) => (date: d, items: map[d]!)).toList();
}
