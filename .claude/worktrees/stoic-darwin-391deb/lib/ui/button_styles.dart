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
      [.ghost]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: (radius) => .from(
          BoxDecoration(borderRadius: radius),
          variants: {
            [.disabled]: const .boxDelta(),
            [.hovered, .pressed]: .boxDelta(color: colors.secondary),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
        touch: true,
      ),
    },
  ),
);
