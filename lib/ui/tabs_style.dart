import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:forui/forui.dart';

import 'theme.dart';

// ignore_for_file: unnecessary_ignore
// ignore_for_file: avoid_redundant_argument_values

FTabsStyle tabsStyle({
  required FColors colors,
  required FTypography typography,
  required FStyle style,
}) => FTabsStyle(
  decoration: BoxDecoration(
    border: .all(color: colors.muted),
    borderRadius: style.borderRadius.md,
    color: colors.muted,
  ),
  labelTextStyle: .from(
    typography.body.sm.copyWith(
      fontWeight: .w500,
      fontFamily: FTypeface.defaultFontFamily,
      color: pbBlue,
    ),
    variants: {
      [.selected]: .delta(color: colors.primary),
    },
  ),
  indicatorDecoration: BoxDecoration(
    color: colors.background,
    borderRadius: style.borderRadius.md,
  ),
  focusedOutlineStyle: style.focusedOutlineStyle,
  padding: const .all(4),
  indicatorSize: .tab,
  minHeight: 35,
  spacing: 10,
);
