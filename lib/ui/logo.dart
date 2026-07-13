import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:vector_graphics/vector_graphics.dart';

import 'theme.dart';

enum PLogoVariant {
  /// Just the glass arrow mark.
  mark,

  /// Mark + "Passe" wordmark + slogan, side by side.
  horizontal,

  /// Mark on top, wordmark + slogan centered beneath.
  stacked,
}

/// The Passe brand lockup: the glass arrow mark (SVG) paired with the "Passe"
/// wordmark in Bitter and the "Play Together · Win Together" slogan.
///
/// The wordmark and slogan use the real Bitter font natively; the slogan runs
/// crimson → brand-blue. Colours come from the active [FThemeData] so the logo
/// adapts to light/dark automatically (override [wordmarkColor] on tinted
/// backgrounds — e.g. white on a crimson hero).
class PLogo extends StatelessWidget {
  final PLogoVariant variant;

  /// Height of the mark in logical pixels. Everything else scales from this.
  final double size;

  final bool showSlogan;

  /// Wordmark colour. Defaults to the theme's primary (crimson).
  final Color? wordmarkColor;

  const PLogo({
    super.key,
    this.variant = PLogoVariant.horizontal,
    this.size = 44,
    this.showSlogan = true,
    this.wordmarkColor,
  });

  static const _slogan = 'PLAY TOGETHER · WIN TOGETHER';

  @override
  Widget build(BuildContext context) {
    final mark = SvgPicture(
      const AssetBytesLoader('./assets/icons/logo.svg.vec'),
      height: size,
      width: size,
    );
    if (variant == PLogoVariant.mark) return mark;

    final colors = context.theme.colors;
    final wm = wordmarkColor ?? colors.primary;

    final wordmark = Text(
      'Passe',
      style: TextStyle(
        fontFamily: 'Bitter',
        fontWeight: FontWeight.w900,
        fontSize: size * 0.82,
        height: 1.0,
        letterSpacing: -size * 0.022,
        color: wm,
      ),
    );

    final slogan = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => LinearGradient(
        colors: [colors.primary, context.theme.brand.blue],
      ).createShader(rect),
      child: Text(
        _slogan,
        style: TextStyle(
          fontFamily: 'Bitter',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.19,
          letterSpacing: size * 0.05,
          height: 1.3,
          color: Colors.white,
        ),
      ),
    );

    if (variant == PLogoVariant.stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(height: size * 0.16),
          wordmark,
          if (showSlogan) ...[SizedBox(height: size * 0.12), slogan],
        ],
      );
    }

    // horizontal
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wordmark,
            if (showSlogan) ...[SizedBox(height: size * 0.07), slogan],
          ],
        ),
      ],
    );
  }
}
