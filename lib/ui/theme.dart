import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pubox/ui/button_styles.dart';

// ignore_for_file: avoid_redundant_argument_values

const pbRed = Color(0xFFFF2010);
const pbBlue = Color(0xFF3090F2);
const pbGreen = Color(0xFF959D54);

FThemeData get pbThemeLight {
  const colors = FColors(
    brightness: .light,
    systemOverlayStyle: .dark,
    barrier: Color(0x33000000),
    // background: Color(0xFFFFFFFF),
    background: Color(0xFFF4F5EE),

    foreground: Color(0xFF09090B),
    primary: pbRed,
    primaryForeground: Color(0xFFFFF1F2),
    secondary: Color(0xFFE6E8DD),
    secondaryForeground: Color(0xFF18181B),
    muted: Color(0xFFE4E4E0),
    mutedForeground: Color(0xFF71717A),
    destructive: pbBlue,
    destructiveForeground: Color(0xFFFAFAFA),
    error: Color(0xFFEF4444),
    errorForeground: Color(0xFFFAFAFA),
    border: Color(0xFFDCDCD9),
  );

  final typography = _typography(colors: colors);
  final style = _style(colors: colors, typography: typography);

  return FThemeData(
    colors: colors,
    typography: typography,
    style: style,
    buttonStyles: buttonStyles(colors: colors, typography: typography, style: style),
    extensions: [
      PuboxColor(color: pbRed),
      PuboxColor(color: pbBlue),
      PuboxColor(color: pbGreen),
    ],
  );
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
    border: Color(0xFF27272A),
  );

  final typography = _typography(colors: colors);
  final style = _style(colors: colors, typography: typography);

  return FThemeData(colors: colors, typography: typography, style: style);
}

class PuboxColor extends ThemeExtension<PuboxColor> {
  final Color color;

  const PuboxColor({required this.color});

  @override
  PuboxColor copyWith({Color? color}) => PuboxColor(color: color ?? this.color);

  @override
  PuboxColor lerp(PuboxColor? other, double t) {
    if (other is! PuboxColor) {
      return this;
    }

    return PuboxColor(color: Color.lerp(color, other.color, t)!);
  }
}

FTypography _typography({
  required FColors colors,
  String defaultFontFamily = 'Bitter',
}) => FTypography(
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
  base: TextStyle(
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
      formFieldStyle: FFormFieldStyle.inherit(
        colors: colors,
        typography: typography,
      ),
      focusedOutlineStyle: FFocusedOutlineStyle(
        color: colors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      iconStyle: IconThemeData(color: colors.primary, size: 24),
      tappableStyle: FTappableStyle(),
      borderRadius: const FLerpBorderRadius.all(Radius.circular(12), min: 24),
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