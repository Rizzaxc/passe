import 'package:flutter/material.dart';

import 'package:forui/forui.dart';
import 'theme.dart';

// ignore_for_file: unnecessary_ignore
// ignore_for_file: avoid_redundant_argument_values

/// Extension on FButtonStyle to add Pubox accent color styles
extension FButtonStyleExtension on FButtonStyle {
  /// Accent blue button style using pbBlue color
  static FButtonStyle accentBlueStyle(FButtonStyle base) {
    final baseBorderRadius = base.decoration.base.borderRadius;

    return FButtonStyle(
      decoration: .from(
        BoxDecoration(
          borderRadius: baseBorderRadius,
          color: pbBlue,
        ),
        variants: {
          [.disabled]: .delta(color: pbBlue.withValues(alpha: 0.5)),
          [.hovered, .pressed]: .delta(color: Color.lerp(pbBlue, Colors.black, 0.1)),
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
    final baseBorderRadius = base.decoration.base.borderRadius;

    return FButtonStyle(
      decoration: .from(
        BoxDecoration(
          borderRadius: baseBorderRadius,
          color: pbGreen,
        ),
        variants: {
          [.disabled]: .delta(color: pbGreen.withValues(alpha: 0.5)),
          [.hovered, .pressed]: .delta(color: Color.lerp(pbGreen, Colors.black, 0.1)),
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
      decoration: .from(
        BoxDecoration(borderRadius: style.borderRadius, color: colors.primary),
        variants: {
          [.hovered, .pressed]: .delta(color: colors.hover(colors.primary)),
          [.disabled]: .delta(color: colors.disable(colors.primary)),
        },
      ),
      foregroundColor: colors.primaryForeground,
      disabledForegroundColor: colors.disable(colors.primaryForeground),
    ),
    variants: {
      [.secondary]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(borderRadius: style.borderRadius, color: colors.secondary),
          variants: {
            [.hovered, .pressed]: .delta(color: colors.hover(colors.secondary)),
            [.disabled]: .delta(color: colors.disable(colors.secondary)),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
      ),
      [.destructive]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(borderRadius: style.borderRadius, color: colors.destructive),
          variants: {
            [.hovered, .pressed]: .delta(color: colors.hover(colors.destructive)),
            [.disabled]: .delta(color: colors.disable(colors.destructive)),
          },
        ),
        foregroundColor: colors.destructiveForeground,
        disabledForegroundColor: colors.disable(colors.destructiveForeground),
      ),
      [.outline]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(
            border: .all(color: colors.border),
            borderRadius: style.borderRadius,
          ),
          variants: {
            [.disabled]: .delta(color: colors.disable(colors.border)),
            [.hovered, .pressed]: .delta(color: colors.secondary),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
      ),
      [.ghost]: FButtonSizeStyles.inherit(
        typography: typography,
        style: style,
        decoration: .from(
          BoxDecoration(borderRadius: style.borderRadius),
          variants: {
            [.disabled]: const .delta(),
            [.hovered, .pressed]: .delta(color: colors.secondary),
          },
        ),
        foregroundColor: colors.secondaryForeground,
        disabledForegroundColor: colors.disable(colors.secondaryForeground),
      ),
    },
  ),
);
