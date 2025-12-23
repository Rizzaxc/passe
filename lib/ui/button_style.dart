import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:forui/forui.dart';

// ignore_for_file: unnecessary_ignore
// ignore_for_file: avoid_redundant_argument_values
FButtonStyle buttonStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
  required Color color,
  required Color foregroundColor,
}) => FButtonStyle(
  decoration: FWidgetStateMap({
    WidgetState.disabled: BoxDecoration(
      borderRadius: style.borderRadius,
      color: colors.disable(color),
    ),
    WidgetState.hovered | WidgetState.pressed: BoxDecoration(
      borderRadius: style.borderRadius,
      color: colors.hover(color),
    ),
    WidgetState.any: BoxDecoration(
      borderRadius: style.borderRadius,
      color: color,
    ),
  }),
  focusedOutlineStyle: style.focusedOutlineStyle,
  contentStyle: _buttonContentStyle(
    typography: typography,
    enabled: foregroundColor,
    disabled: colors.disable(foregroundColor, colors.disable(color)),
  ),
  iconContentStyle: FButtonIconContentStyle(
    iconStyle: FWidgetStateMap({
      WidgetState.disabled: IconThemeData(
        color: colors.disable(foregroundColor, colors.disable(color)),
        size: 20,
      ),
      WidgetState.any: IconThemeData(color: foregroundColor, size: 20),
    }),
  ),
  tappableStyle: style.tappableStyle,
);

FButtonContentStyle _buttonContentStyle({
  required FTypography typography,
  required Color enabled,
  required Color disabled,
}) => FButtonContentStyle(
  textStyle: FWidgetStateMap({
    WidgetState.disabled: typography.base.copyWith(
      color: disabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
    WidgetState.any: typography.base.copyWith(
      color: enabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
  }),
  iconStyle: FWidgetStateMap({
    WidgetState.disabled: IconThemeData(color: disabled, size: 20),
    WidgetState.any: IconThemeData(color: enabled, size: 20),
  }),
  circularProgressStyle: FWidgetStateMap({
    WidgetState.disabled: FCircularProgressStyle(
      iconStyle: IconThemeData(color: disabled, size: 20),
    ),
    WidgetState.any: FCircularProgressStyle(
      iconStyle: IconThemeData(color: enabled, size: 20),
    ),
  }),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.5),
  spacing: 10,
);
