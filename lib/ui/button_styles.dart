import 'package:flutter/material.dart';

import 'package:forui/forui.dart';
import 'theme.dart';

// ignore_for_file: unnecessary_ignore
// ignore_for_file: avoid_redundant_argument_values

/// Extension on FButtonStyle to add Pubox accent color styles
extension FButtonStyleExtension on FButtonStyle {
  /// Accent blue button style using pbBlue color
  static FButtonStyle Function(FButtonStyle) accentBlue() {
    return (style) {
      final baseBorderRadius = style.decoration.resolve({}).borderRadius;
      final baseTextStyle = style.contentStyle.textStyle.resolve({});

      return FButtonStyle(
        decoration: FWidgetStateMap({
          WidgetState.disabled: BoxDecoration(
            borderRadius: baseBorderRadius,
            color: pbBlue.withValues(alpha: 0.5),
          ),
          WidgetState.hovered | WidgetState.pressed: BoxDecoration(
            borderRadius: baseBorderRadius,
            color: Color.lerp(pbBlue, Colors.black, 0.1),
          ),
          WidgetState.any: BoxDecoration(
            borderRadius: baseBorderRadius,
            color: pbBlue,
          ),
        }),
        focusedOutlineStyle: style.focusedOutlineStyle,
        contentStyle: FButtonContentStyle(
          textStyle: FWidgetStateMap({
            WidgetState.disabled: baseTextStyle.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            WidgetState.any: baseTextStyle.copyWith(
              color: Colors.white,
            ),
          }),
          iconStyle: FWidgetStateMap({
            WidgetState.disabled: IconThemeData(
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            WidgetState.any: IconThemeData(color: Colors.white, size: 20),
          }),
          circularProgressStyle: FWidgetStateMap({
            WidgetState.disabled: FCircularProgressStyle(
              iconStyle: IconThemeData(color: Colors.white.withValues(alpha: 0.5), size: 20),
            ),
            WidgetState.any: FCircularProgressStyle(
              iconStyle: IconThemeData(color: Colors.white, size: 20),
            ),
          }),
          padding: style.contentStyle.padding,
          spacing: style.contentStyle.spacing,
        ),
        iconContentStyle: FButtonIconContentStyle(
          iconStyle: FWidgetStateMap({
            WidgetState.disabled: IconThemeData(
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            WidgetState.any: IconThemeData(color: Colors.white, size: 20),
          }),
        ),
        tappableStyle: style.tappableStyle,
      );
    };
  }

  /// Accent green button style using pbGreen color
  static FButtonStyle Function(FButtonStyle) accentGreen() {
    return (style) {
      final baseBorderRadius = style.decoration.resolve({}).borderRadius;
      final baseTextStyle = style.contentStyle.textStyle.resolve({});

      return FButtonStyle(
        decoration: FWidgetStateMap({
          WidgetState.disabled: BoxDecoration(
            borderRadius: baseBorderRadius,
            color: pbGreen.withValues(alpha: 0.5),
          ),
          WidgetState.hovered | WidgetState.pressed: BoxDecoration(
            borderRadius: baseBorderRadius,
            color: Color.lerp(pbGreen, Colors.black, 0.1),
          ),
          WidgetState.any: BoxDecoration(
            borderRadius: baseBorderRadius,
            color: pbGreen,
          ),
        }),
        focusedOutlineStyle: style.focusedOutlineStyle,
        contentStyle: FButtonContentStyle(
          textStyle: FWidgetStateMap({
            WidgetState.disabled: baseTextStyle.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            WidgetState.any: baseTextStyle.copyWith(
              color: Colors.white,
            ),
          }),
          iconStyle: FWidgetStateMap({
            WidgetState.disabled: IconThemeData(
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            WidgetState.any: IconThemeData(color: Colors.white, size: 20),
          }),
          circularProgressStyle: FWidgetStateMap({
            WidgetState.disabled: FCircularProgressStyle(
              iconStyle: IconThemeData(color: Colors.white.withValues(alpha: 0.5), size: 20),
            ),
            WidgetState.any: FCircularProgressStyle(
              iconStyle: IconThemeData(color: Colors.white, size: 20),
            ),
          }),
          padding: style.contentStyle.padding,
          spacing: style.contentStyle.spacing,
        ),
        iconContentStyle: FButtonIconContentStyle(
          iconStyle: FWidgetStateMap({
            WidgetState.disabled: IconThemeData(
              color: Colors.white.withValues(alpha: 0.5),
              size: 20,
            ),
            WidgetState.any: IconThemeData(color: Colors.white, size: 20),
          }),
        ),
        tappableStyle: style.tappableStyle,
      );
    };
  }
}

FButtonStyles buttonStyles({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FButtonStyles(
  primary: .inherit(
    colors: colors,
    style: style,
    typography: typography,
    color: colors.primary,
    foregroundColor: colors.primaryForeground,
  ),
  secondary: .inherit(
    colors: colors,
    style: style,
    typography: typography,
    color: colors.secondary,
    foregroundColor: colors.secondaryForeground,
  ),
  destructive: .inherit(
    colors: colors,
    style: style,
    typography: typography,
    color: colors.destructive,
    foregroundColor: colors.destructiveForeground,
  ),
  outline: FButtonStyle(
    decoration: FWidgetStateMap({
      WidgetState.disabled: BoxDecoration(
        border: .all(color: colors.disable(colors.border)),
        borderRadius: style.borderRadius,
      ),
      WidgetState.hovered | WidgetState.pressed: BoxDecoration(
        border: .all(color: colors.border),
        borderRadius: style.borderRadius,
        color: colors.secondary,
      ),
      WidgetState.any: BoxDecoration(
        border: .all(color: colors.border),
        borderRadius: style.borderRadius,
      ),
    }),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: .inherit(
      typography: typography,
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    iconContentStyle: .inherit(
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    tappableStyle: style.tappableStyle,
  ),
  ghost: FButtonStyle(
    decoration: FWidgetStateMap({
      WidgetState.disabled: BoxDecoration(borderRadius: style.borderRadius),
      WidgetState.hovered | WidgetState.pressed: BoxDecoration(
        borderRadius: style.borderRadius,
        color: colors.secondary,
      ),
      WidgetState.any: BoxDecoration(borderRadius: style.borderRadius),
    }),
    focusedOutlineStyle: style.focusedOutlineStyle,
    contentStyle: .inherit(
      typography: typography,
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    iconContentStyle: .inherit(
      enabled: colors.secondaryForeground,
      disabled: colors.disable(colors.secondaryForeground),
    ),
    tappableStyle: style.tappableStyle,
  ),
);
