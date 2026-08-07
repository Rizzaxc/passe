import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Compact version of the landing page's hard offset-shadow treatment.
///
/// The child owns its foreground surface and border. This widget only draws
/// the colored backplate peeking out along the trailing and bottom edges.
class POffsetFrame extends StatelessWidget {
  final Widget child;
  final Color offsetColor;
  final BorderRadius borderRadius;
  final double offset;

  const POffsetFrame({
    required this.child,
    required this.offsetColor,
    required this.borderRadius,
    this.offset = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: offsetColor, borderRadius: borderRadius),
    child: Padding(
      padding: EdgeInsets.only(right: offset, bottom: offset),
      child: child,
    ),
  );
}

/// Deep-blue fixture surface with the landing page's faint court geometry.
class PMatchBoard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  const PMatchBoard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.backgroundColor = const Color(0xFF173B92),
    super.key,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: ColoredBox(
      color: backgroundColor,
      child: CustomPaint(
        painter: const _CourtLinePainter(),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

class _CourtLinePainter extends CustomPainter {
  const _CourtLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x24FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.68, size.height / 2);
    final radius = size.shortestSide * 0.34;

    canvas.drawCircle(center, radius, paint);
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A drop-in for [FCard]'s pre-0.24 title/subtitle/child convenience constructor, which forui
/// removed in favor of a bare `builder` (the new `FCard(child: ...)` no longer applies any
/// padding). Restores the old title/subtitle/child layout — using the current theme's
/// [FCardStyle.padding]/`titleTextStyle`/`subtitleTextStyle` — so call sites don't each
/// reimplement it.
class PCard extends StatelessWidget {
  final FCardStyleDelta style;
  final Clip clipBehavior;
  final Widget? title;
  final Widget? subtitle;
  final Widget? child;

  const PCard({
    this.title,
    this.subtitle,
    this.child,
    this.style = const .context(),
    this.clipBehavior = .none,
    super.key,
  }) : assert(title != null || subtitle != null || child != null, 'Provide at least one of title, subtitle, child.');

  @override
  Widget build(BuildContext context) => FCard(
    style: style,
    clipBehavior: clipBehavior,
    builder: (context, cardStyle, _) => Padding(
      padding: cardStyle.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title case final title?) DefaultTextStyle.merge(style: cardStyle.titleTextStyle, child: title),
          if (subtitle case final subtitle?)
            Padding(
              padding: EdgeInsets.only(top: title != null ? 2 : 0),
              child: DefaultTextStyle.merge(style: cardStyle.subtitleTextStyle, child: subtitle),
            ),
          if (child case final child?)
            Padding(padding: EdgeInsets.only(top: (title != null || subtitle != null) ? 6 : 0), child: child),
        ],
      ),
    ),
  );
}
