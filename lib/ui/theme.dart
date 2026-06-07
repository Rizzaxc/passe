import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:passe/ui/button_styles.dart';

import 'select_menu_tile_style.dart';
import 'select_style.dart';
import 'tabs_style.dart';

// ignore_for_file: avoid_redundant_argument_values
// const pbRed = Color(0xFFDC143C);
const pbBlue = Color(0xFF3090F2);
const pbGreen = Color(0xFF959D54);

FThemeData get pbThemeLight {
  const colors = FColors(
    brightness: .light,
    systemOverlayStyle: .dark,
    barrier: Color(0x33000000),
    background: Color(0xFFF4F5EE),
    // background: Color(0xFFFFFFFF),

    foreground: Color(0xFF09090B),
    primary: Color(0xFFDC143C),
    primaryForeground: Color(0xFFFFF1F2),
    // Bumped from zinc-100 (#F4F4F5) — at that value secondary was
    // visually identical to both the warm bg (#F4F5EE) and to white,
    // so chips / pills / spend-row kind tints disappeared. Zinc-200
    // is one step up: readable on white without going chunky.
    secondary: Color(0xFFE4E4E7),
    secondaryForeground: Color(0xFF18181B),
    muted: Color(0xFFE5E7EB),
    mutedForeground: Color(0xFF71717A),

    destructive: Color(0xFFF97316),
    destructiveForeground: Color(0xFFFAFAFA),

    error: Color(0xFFf95c16),
    errorForeground: Color(0xFFFAFAFA),
    card: Color(0xFFFFFFFF),

    border: Color(0xFFDCDCD9),
  );

  final typography = _typography(colors: colors);
  final style = _style(colors: colors, typography: typography);

  return FThemeData(
    colors: colors,
    touch: true,
    typography: typography,
    style: style,
    buttonStyles: buttonStyles(
      colors: colors,
      typography: typography,
      style: style,
    ),
    tabsStyle: tabsStyle(colors: colors, typography: typography, style: style),
    selectMenuTileStyle: CustomFSelectMenuTileStyle.selectMenuTileStyle(colors: colors, typography: typography, style: style),
    selectStyle: selectStyle(colors: colors, typography: typography, style: style),
    extensions: [PasseColors(green: pbGreen, blue: pbBlue)],
  );
}

extension PasseColorExtension on FThemeData {
  PasseColors get brand => extension<PasseColors>();
}

FThemeData get pbThemeDark {
  const colors = FColors(
    brightness: .dark,
    systemOverlayStyle: .light,
    barrier: Color(0x7A000000),
    background: Color(0xFF0C0A09),
    foreground: Color(0xFFF2F2F2),
    primary: Color(0xFFE11D48),
    primaryForeground: Color(0xFFFFF1F2),
    secondary: Color(0xFF27272A),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF262626),
    mutedForeground: Color(0xFFA1A1AA),
    destructive: Color(0xFF7F1D1D),
    destructiveForeground: Color(0xFFFEF2F2),
    error: Color(0xFF7F1D1D),
    errorForeground: Color(0xFFFEF2F2),
    card: Color(0xFF1C1917),
    border: Color(0xFF27272A),
  );

  final typography = _typography(colors: colors);
  final style = _style(colors: colors, typography: typography);

  return FThemeData(
    colors: colors,
    touch: true,
    typography: typography,
    style: style,
    selectStyle: selectStyle(colors: colors, typography: typography, style: style),
    extensions: [PasseColors(green: pbGreen, blue: pbBlue)],
  );
}

class PasseColors extends ThemeExtension<PasseColors> {
  final Color green;
  final Color blue;

  const PasseColors({required this.green, required this.blue});

  @override
  PasseColors copyWith({Color? green, Color? blue}) =>
      PasseColors(green: green ?? this.green, blue: blue ?? this.blue);

  @override
  PasseColors lerp(PasseColors? other, double t) {
    if (other is! PasseColors) {
      return this;
    }

    return PasseColors(
      green: Color.lerp(green, other.green, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
    );
  }
}

FTypography _typography({
  required FColors colors,
  String defaultFontFamily = 'Bitter',
}) => FTypography(
  fontFamily: defaultFontFamily,
  xs: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 12,
    height: 1,
  ),
  sm: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 14,
    height: 1.25,
  ),
  md: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 16,
    height: 1.5,
  ),
  lg: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 18,
    height: 1.75,
  ),
  xl: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 20,
    height: 1.75,
  ),
  xl2: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 22,
    height: 2,
  ),
  xl3: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 30,
    height: 2.25,
  ),
  xl4: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 36,
    height: 2.5,
  ),
  xl5: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 48,
    height: 1,
  ),
  xl6: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 60,
    height: 1,
  ),
  xl7: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 72,
    height: 1,
  ),
  xl8: TextStyle(
    color: colors.foreground,
    fontFamily: defaultFontFamily,
    fontSize: 96,
    height: 1,
  ),
);

FStyle _style({required FColors colors, required FTypography typography}) =>
    FStyle(
      sizes: FSizes.inherit(touch: true),
      formFieldStyle: FFormFieldStyle.inherit(
        colors: colors,
        typography: typography,
        touch: true,
      ),
      focusedOutlineStyle: FFocusedOutlineStyle(
        color: colors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      iconStyle: IconThemeData(color: colors.primary, size: 24),
      tappableStyle: FTappableStyle(),
      borderRadius: const FBorderRadius(md: BorderRadius.all(Radius.circular(12))),
      borderWidth: 1,
      pagePadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shadow: const [
        BoxShadow(
          color: Color(0x0d000000),
          offset: Offset(0, 1),
          blurRadius: 2.5,
        ),
      ],
    );

// FThemeData get roseLight {
//   const colors = FColors(
//     brightness: .light,
//     systemOverlayStyle: .dark,
//     barrier: Color(0x33000000),
//     background: Color(0xFFFFFFFF),
//     foreground: Color(0xFF09090B),
//     primary: Color(0xFFE11D48),
//     primaryForeground: Color(0xFFFFF1F2),
//     secondary: Color(0xFFF4F4F5),
//     secondaryForeground: Color(0xFF18181B),
//     muted: Color(0xFFF4F4F5),
//     mutedForeground: Color(0xFF71717A),
//     destructive: Color(0xFFEF4444),
//     destructiveForeground: Color(0xFFFAFAFA),
//     error: Color(0xFFEF4444),
//     errorForeground: Color(0xFFFAFAFA),
//     border: Color(0xFFE4E4E7),
//   );
//
//   final typography = _typography(colors: colors);
//   final style = _style(colors: colors, typography: typography);
//
//   return FThemeData(colors: colors, typography: typography, style: style);
// }
//
// FThemeData get roseDark {
//   const colors = FColors(
//     brightness: .dark,
//     systemOverlayStyle: .light,
//     barrier: Color(0x7A000000),
//     background: Color(0xFF0C0A09),
//     foreground: Color(0xFFF2F2F2),
//     primary: Color(0xFFE11D48),
//     primaryForeground: Color(0xFFFFF1F2),
//     secondary: Color(0xFF27272A),
//     secondaryForeground: Color(0xFFFAFAFA),
//     muted: Color(0xFF262626),
//     mutedForeground: Color(0xFFA1A1AA),
//     destructive: Color(0xFF7F1D1D),
//     destructiveForeground: Color(0xFFFEF2F2),
//     error: Color(0xFF7F1D1D),
//     errorForeground: Color(0xFFFEF2F2),
//     border: Color(0xFF27272A),
//   );
//
//   final typography = _typography(colors: colors);
//   final style = _style(colors: colors, typography: typography);
//
//   return FThemeData(colors: colors, typography: typography, style: style);
// }
