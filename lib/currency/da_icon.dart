import 'package:flutter/material.dart';

/// Faceted ruby gem — the brand-aspirational Đá glyph.
///
/// Hand-painted to match `Da Currency.html`'s SVG: hexagonal pavilion
/// + table, with a couple of brighter crown facets for a faceted look.
class DaIcon extends StatelessWidget {
  final double size;

  const DaIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _DaGemPainter(),
    );
  }
}

class _DaGemPainter extends CustomPainter {
  const _DaGemPainter();

  static const _darkRed = Color(0xFF7A0820);
  static const _midRed = Color(0xFFA30E2C);
  static const _red = Color(0xFFDC143C);
  static const _lightPink = Color(0xFFFF6B83);
  static const _palePink = Color(0xFFFF95A7);
  static const _topRed = Color(0xFFFF4D6E);
  static const _highlight = Color(0xFFFFC9D3);
  static const _girdle = Color(0xFF5B0617);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset((x / 24.0) * s, (y / 24.0) * s);

    final fill = Paint()..style = PaintingStyle.fill;

    void poly(List<Offset> pts, Color color) {
      fill.color = color;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
      canvas.drawPath(path, fill);
    }

    // pavilion (bottom point)
    poly([p(3, 9), p(21, 9), p(12, 22)], _midRed);
    // pavilion side facets
    poly([p(3, 9), p(12, 22), p(8, 9)], _red);
    poly([p(21, 9), p(16, 9), p(12, 22)], _darkRed);
    // table (top)
    poly([p(3, 9), p(7, 3), p(17, 3), p(21, 9)], _topRed);
    // crown facets
    poly([p(3, 9), p(7, 3), p(8, 9)], _palePink);
    poly([p(21, 9), p(17, 3), p(16, 9)], const Color(0xFFC71338));
    poly([p(7, 3), p(17, 3), p(16, 9), p(8, 9)], _lightPink);
    poly([p(7, 3), p(12, 5.5), p(17, 3)], _highlight);
    // girdle
    final girdle = Paint()
      ..color = _girdle
      ..strokeWidth = (0.4 / 24.0) * s;
    canvas.drawLine(p(3, 9), p(21, 9), girdle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
