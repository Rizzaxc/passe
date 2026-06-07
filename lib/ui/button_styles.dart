import 'package:flutter/material.dart';

import 'package:forui/forui.dart';
import 'theme.dart';

// ignore_for_file: unnecessary_ignore
// ignore_for_file: avoid_redundant_argument_values

/// Extension on FButtonStyle to add Passe accent color styles
extension FButtonStyleExtension on FButtonStyle {
  /// Accent blue button style using pbBlue color
  static FButtonStyle accentBlueStyle(FButtonStyle base) {
    final baseBorderRadius = (base.decoration.base as BoxDecoration?)?.borderRadius;

    return FButtonStyle(
      decoration: .from(
        BoxDecoration(
          borderRadius: baseBorderRadius,
          color: pbBlue,
        ),
        variants: {
          [.disabled]: .boxDelta(color: pbBlue.withValues(alpha: 0.5)),
          [.hovered, .pressed]: .boxDelta(color: Color.lerp(pbBlue, Colors.black, 0.1)),
        },
      ),
      focusedOutlineStyle: base.focusedOutlineStyle,
      contentStyle: FButtonContentStyle(
        textStyle: .from(
          base.contentStyle.textStyle.base.copyWith(color: Colors.white),
          variants: {
            [.disabled]: .delta(color: Colors.white.withValues(alpha: 0.5)),
          },
        ),
        iconStyle: .from(
          IconThemeData(color: Colors.white, size: 20),
          variants: {
            [.disabled]: .delta(color: Colors.white.withValues(alpha: 0.5)),
          },
        ),
        circularProgressStyle: .from(
          FCircularProgressStyle(
            iconStyle: IconThemeData(color: Colors.white, size: 20),
          ),
          variants: {
            [.disabled]: .delta(iconStyle: .delta(color: Colors.white.withValues(alpha: 0.5))),
          },
        ),
        padding: base.contentStyle.padding,
        spacing: base.contentStyle.spacing,
      ),
      iconContentStyle: FButtonIconContentStyle(
        iconStyle: .from(
          IconThemeData(color: Colors.white, size: 20),
          variants: {
            [.disabled]: .delta(color: Colors.white.withValues(alpha: 0.5)),
          },
        ),
      ),
      tappableStyle: base.tappableStyle,
    );
  }

  /// Accent green button style using pbGreen color
  static FButtonStyle accentGreenStyle(FButtonStyle base) {
    final baseBorderRadius = (base.decoration.base as BoxDecoration?)?.borderRadius;

    return FButtonStyle(
      decoration: .from(
        BoxDecoration(
          borderRadius: baseBorderRadius,
          color: pbGreen,
        ),
        variants: {
          [.disabled]: .boxDelta(color: pbGreen.withValues(alpha: 0.5)),
          [.hovered, .pressed]: .boxDelta(color: Color.lerp(pbGreen, Colors.black, 0.1)),
        },
      ),
      focusedOutlineStyle: base.focusedOutlineStyle,
      contentStyle: FButtonContentStyle(
        textStyle: .from(
          base.contentStyle.textStyle.base.copyWith(color: Colors.white),
          variants: {
            [.disabled]: .delta(color: Colors.white.withValues(alpha: 0.5)),
          },
        ),
        iconStyle: .from(
          IconThemeData(color: Colors.white, size: 20),
          variants: {
            [.disabled]: .delta(color: Colors.white.withValues(alpha: 0.5)),
          },
        ),
        circularProgressStyle: .from(
          FCircularProgressStyle(
            iconStyle: IconThemeData(color: Colors.white, size: 20),
          ),
          variants: {
            [.disabled]: .delta(iconStyle: .delta(color: Colors.white.withValues(alpha: 0.5))),
          },
        ),
        padding: base.contentStyle.padding,
        spacing: base.contentStyle.spacing,
      ),
      iconContentStyle: FButtonIconContentStyle(
        iconStyle: .from(
          IconThemeData(color: Colors.white, size: 20),
          variants: {
            [.disabled]: .delta(color: Colors.white.withValues(alpha: 0.5)),
          },
        ),
      ),
      tappableStyle: base.tappableStyle,
    );
  }
}

/// Ghost-button sizing tweaked from forui's defaults:
///
/// - **Pill bg** — `borderRadius: 9999` so the pressed / hover state
///   renders as a circle/pill around the icon. Looks more like a
///   tap puck than a rounded rect, which matches how the design uses
///   ghost buttons (almost always icon-only affordances next to form
///   fields, headers, sheets etc.).
/// - **Tighter constraints** — icon-mode hit box shrinks from forui's
///   default 44×44 to 36×36 (and proportionally for `xs`/`sm`/`lg`).
///   The pressed background follows, so it no longer bleeds past
///   adjacent rows.
///
/// Text-mode (FButton with a text child) keeps the original wider
/// constraints — the size change only applies to the icon variant
/// via `iconConstraints` + `iconPadding`.
FButtonSizeStyles _ghostSizes({
  required FTypography typography,
  required FStyle style,
  required FColors colors,
}) {
  FVariants<FTappableVariantConstraint, FTappableVariant, Decoration, DecorationDelta> decoration() => .from(
    BoxDecoration(borderRadius: BorderRadius.circular(9999)),
    variants: {
      [.disabled]: const .boxDelta(),
      [.hovered, .pressed]: .boxDelta(color: colors.secondary),
    },
  );

  FButtonStyle make({
    required TextStyle textStyle,
    required BoxConstraints contentConstraints,
    required EdgeInsetsGeometry contentPadding,
    required double contentSpacing,
    required BoxConstraints iconConstraints,
    required double iconSize,
    required EdgeInsetsGeometry iconPadding,
  }) => FButtonStyle.inherit(
    style: style,
    foregroundColor: colors.secondaryForeground,
    disabledForegroundColor: colors.disable(colors.secondaryForeground),
    decoration: decoration(),
    textStyle: textStyle,
    contentConstraints: contentConstraints,
    contentPadding: contentPadding,
    contentSpacing: contentSpacing,
    iconConstraints: iconConstraints,
    iconSize: iconSize,
    iconPadding: iconPadding,
  );

  // md (default) — matches forui's text-mode min size, but icon hit-box
  // shrinks to 36 so the round pressed state stays compact.
  final md = make(
    textStyle: typography.sm,
    contentConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    contentSpacing: 6,
    iconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    iconSize: typography.md.fontSize ?? 18,
    iconPadding: const EdgeInsets.all(9),
  );

  return FButtonSizeStyles(FVariants(
    md,
    variants: {
      [.xs]: make(
        textStyle: typography.xs,
        contentConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        contentSpacing: 4,
        iconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        iconSize: typography.sm.fontSize ?? 16,
        iconPadding: const EdgeInsets.all(5),
      ),
      [.sm]: make(
        textStyle: typography.sm,
        contentConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        contentSpacing: 4,
        iconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        iconSize: typography.md.fontSize ?? 18,
        iconPadding: const EdgeInsets.all(7),
      ),
      [.md]: md,
      [.lg]: make(
        textStyle: typography.sm,
        contentConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        contentSpacing: 6,
        iconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        iconSize: typography.lg.fontSize ?? 20,
        iconPadding: const EdgeInsets.all(10),
      ),
    },
  ));
}

FButtonStyles buttonStyles({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FButtonStyles(
  FVariants(
    FButtonSizeStyles.inherit(
      typography: typography,
      style: style,
      decoration: (radius) => .from(
        BoxDecoration(borderRadius: radius, color: colors.primary),
        variants: {
          [.hovered, .pressed]: .boxDelta(color: colors.hover(colors.primary)),
          [.disabled]: .boxDelta(color: colors.disable(colors.primary)),
        },
      ),
      foregroundColor: colors.primaryForeground,
      disabledForegroundColor: colors.disable(colors.primaryForeground),
      touch: true,
    ),
    variants: {
      [.secondary]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: (radius) => .from(
          BoxDecoration(borderRadius: radius, color: colors.secondary),
          variants: {
            [.hovered, .pressed]: .boxDelta(color: colors.hover(colors.secondary)),
            [.disabled]: .boxDelta(color: colors.disable(colors.secondary)),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
        touch: true,
      ),
      [.destructive]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: (radius) => .from(
          BoxDecoration(borderRadius: radius, color: colors.destructive),
          variants: {
            [.hovered, .pressed]: .boxDelta(color: colors.hover(colors.destructive)),
            [.disabled]: .boxDelta(color: colors.disable(colors.destructive)),
          },
        ),
        foregroundColor: colors.destructiveForeground,
        disabledForegroundColor: colors.disable(colors.destructiveForeground),
        touch: true,
      ),
      [.outline]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: (radius) => .from(
          BoxDecoration(
            border: .all(color: colors.border),
            borderRadius: radius,
          ),
          variants: {
            [.disabled]: .boxDelta(color: colors.disable(colors.border)),
            [.hovered, .pressed]: .boxDelta(color: colors.secondary),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
        touch: true,
      ),
      [.ghost]: _ghostSizes(
        typography: typography,
        style: style,
        colors: colors,
      ),
    },
  ),
);
