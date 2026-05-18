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
  decoration: .from(
    BoxDecoration(
      borderRadius: style.borderRadius.md,
      color: color,
    ),
    variants: {
      [.disabled]: .boxDelta(color: colors.disable(color)),
      [.hovered, .pressed]: .boxDelta(color: colors.hover(color)),
    },
  ),
  focusedOutlineStyle: style.focusedOutlineStyle,
  contentStyle: _buttonContentStyle(
    typography: typography,
    enabled: foregroundColor,
    disabled: colors.disable(foregroundColor),
  ),
  iconContentStyle: FButtonIconContentStyle(
    iconStyle: .from(
      IconThemeData(color: foregroundColor, size: 20),
      variants: {
        [.disabled]: .delta(color: colors.disable(foregroundColor)),
      },
    ),
  ),
  tappableStyle: style.tappableStyle,
);

FButtonContentStyle _buttonContentStyle({
  required FTypography typography,
  required Color enabled,
  required Color disabled,
}) => FButtonContentStyle(
  textStyle: .from(
    typography.md.copyWith(
      color: enabled,
      fontWeight: FontWeight.w500,
      height: 1,
    ),
    variants: {
      [.disabled]: .delta(color: disabled),
    },
  ),
  iconStyle: .from(
    IconThemeData(color: enabled, size: 20),
    variants: {
      [.disabled]: .delta(color: disabled),
    },
  ),
  circularProgressStyle: .from(
    FCircularProgressStyle(
      iconStyle: IconThemeData(color: enabled, size: 20),
    ),
    variants: {
      [.disabled]: .delta(iconStyle: .delta(color: disabled)),
    },
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.5),
  spacing: 10,
);
