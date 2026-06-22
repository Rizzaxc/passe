import 'package:forui/forui.dart';

// ignore_for_file: avoid_redundant_argument_values

extension CustomFSelectMenuTileStyle on Never {
  static FSelectMenuTileStyle selectMenuTileStyle({
    required FColors colors,
    required FTypography typography,
    required FStyle style,
  }) => FSelectMenuTileStyle.inherit(
    colors: colors,
    typography: typography,
    style: style,
    hapticFeedback: const FHapticFeedback(),
    touch: true,
  );
}
