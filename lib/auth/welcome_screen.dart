import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../core/icon/main.dart';
import '../ui/main.dart';
import 'auth_screen.dart';

/// The pre-auth story. Each beat is a warm tinted plate carrying one of the
/// app's own illustrated sport icons, dressed with a soft blob, a halftone
/// field and scattered confetti — the same illustrations the rest of the app
/// uses, so the story looks like the product rather than a stock intro.
///
/// The three beats run crimson → amber → green (primary, pbStar, pbGreen), and
/// that accent drives the plate wash, the rule above the title and the active
/// page dot, so each screen reads as a distinct chapter of one system. pbBlue
/// stays in the mix as confetti on every plate rather than carrying a beat —
/// the story wanted warmth, and blue is the one cool note in the palette.
class WelcomeScreen extends HookConsumerWidget {
  const WelcomeScreen({super.key});

  static const _beats = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final colors = context.theme.colors;

    final illustrations = <Widget>[
      PasseIcons.lobby,
      PasseIcons.playtime,
      // An athlete mid-action rather than the `strength` fist: that one is
      // drawn on an opaque white disc, which flattened the plate wash behind it.
      PasseIcons.basketballDunk,
    ];
    final accents = [colors.primary, pbStar, context.theme.brand.green];

    final isAuthPage = currentPage.value == _beats;
    final accent = accents[currentPage.value.clamp(0, accents.length - 1)];

    return FScaffold(
      childPad: false,
      child: Column(
        children: [
          // Brand lockup rides above the story, and steps aside for the auth
          // page, which brings its own header.
          _FadeOnAuth(
            hidden: isAuthPage,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Row(
                  children: const [PLogo(variant: PLogoVariant.horizontal, size: 30)],
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              allowImplicitScrolling: true,
              controller: pageController,
              onPageChanged: (index) => currentPage.value = index,
              children: [
                for (var i = 0; i < _beats; i++)
                  _StoryPage(
                    controller: pageController,
                    index: i,
                    illustration: illustrations[i],
                    accent: accents[i],
                    cool: context.theme.brand.blue,
                    title: 'welcome.page${i + 1}.title'.tr(),
                    description: 'welcome.page${i + 1}.description'.tr(),
                  ),
                const AuthScreen(),
              ],
            ),
          ),
          _FadeOnAuth(
            hidden: isAuthPage,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SmoothPageIndicator(
                  controller: pageController,
                  count: _beats + 1,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: accent,
                    dotColor: colors.border,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapses chrome on the auth page. This must remove the *space*, not just
/// the paint — fading with [AnimatedOpacity] alone leaves an empty band where
/// the lockup was and pushes the auth screen's own header down below it.
class _FadeOnAuth extends StatelessWidget {
  final bool hidden;
  final Widget child;

  const _FadeOnAuth({required this.hidden, required this.child});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: hidden,
        child: AnimatedCrossFade(
          firstChild: child,
          secondChild: const SizedBox(width: double.infinity),
          crossFadeState: hidden ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOut,
        ),
      );
}

class _StoryPage extends StatelessWidget {
  final PageController controller;
  final int index;
  final Widget illustration;
  final Color accent;
  final Color cool;
  final String title;
  final String description;

  const _StoryPage({
    required this.controller,
    required this.index,
    required this.illustration,
    required this.accent,
    required this.cool,
    required this.title,
    required this.description,
  });

  /// Where the viewport actually sits, in pages. Falls back to this page's own
  /// index before the controller is attached, so the first frame is neutral.
  double _viewportPage() {
    if (controller.hasClients && controller.position.haveDimensions) {
      return controller.page ?? index.toDouble();
    }
    return index.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // -1 → this page is one swipe to the left, 0 → settled, 1 → to the right.
        final delta = (_viewportPage() - index).clamp(-1.0, 1.0);
        final settled = 1 - delta.abs();

        return Opacity(
          opacity: settled.clamp(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    // The plate lags the swipe, the copy leads it — the two
                    // separate as you drag and resolve as the page settles.
                    child: Transform.translate(
                      offset: Offset(delta * -52, 0),
                      child: Transform.scale(
                        scale: 1 - delta.abs() * 0.10,
                        child: _StoryPlate(
                          illustration: illustration,
                          accent: accent,
                          cool: cool,
                          beat: index,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Transform.translate(
                  offset: Offset(delta * 64, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Bitter',
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          height: 1.15,
                          letterSpacing: -0.6,
                          color: colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: context.theme.typography.body.md.copyWith(
                          color: colors.mutedForeground,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One illustration dressed with painted decoration — a soft glow, blurred
/// blobs, a halftone field, a broken ring and scattered confetti. Deliberately
/// *frameless*: nothing clips or encloses the art, so the decoration bleeds
/// into the page instead of sitting inside a card. Painted rather than shipped
/// as art so it re-tints per beat and costs no assets.
class _StoryPlate extends StatelessWidget {
  final Widget illustration;
  final Color accent;
  final Color cool;
  final int beat;

  const _StoryPlate({
    required this.illustration,
    required this.accent,
    required this.cool,
    required this.beat,
  });

  /// The wash is the accent pulled toward the brand's amber, so every plate
  /// lands warm. Without this pbGreen washes out to a drab khaki next to the
  /// crimson and amber beats; the accent itself stays untouched for the ring,
  /// the confetti, the title rule and the page dot.
  Color get _wash => Color.lerp(accent, pbStar, 0.28)!;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PlateDecorPainter(
                    accent: accent,
                    wash: _wash,
                    cool: cool,
                    spark: pbStar,
                    beat: beat,
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: w * 0.62,
                  height: w * 0.62,
                  child: illustration,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Everything on the plate that isn't the illustration. Positions are fixed
/// per [beat] rather than random, so a rebuild never reshuffles the confetti.
class _PlateDecorPainter extends CustomPainter {
  final Color accent;
  final Color wash;
  final Color cool;
  final Color spark;
  final int beat;

  const _PlateDecorPainter({
    required this.accent,
    required this.wash,
    required this.cool,
    required this.spark,
    required this.beat,
  });

  /// Organic blob through six points of varying radius, smoothed with quadratics.
  Path _blob(Offset c, double r, double phase) {
    final wobble = [1.0, 0.86, 1.08, 0.9, 1.12, 0.84];
    final points = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final a = phase + i * math.pi / 3;
      final rr = r * wobble[i];
      points.add(Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr));
    }
    final path = Path();
    final start = Offset.lerp(points[5], points[0], 0.5)!;
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < 6; i++) {
      final ctrl = points[i];
      final end = Offset.lerp(points[i], points[(i + 1) % 6], 0.5)!;
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final centre = Offset(w * 0.5, h * 0.5);

    // Warm glow instead of a card: fades to nothing, so the art has no edge.
    canvas.drawCircle(
      centre,
      w * 0.62,
      Paint()
        ..shader = RadialGradient(
          colors: [wash.withValues(alpha: 0.34), wash.withValues(alpha: 0.0)],
          stops: const [0.18, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: w * 0.62)),
    );

    // Blurred blobs give the glow some structure without drawing a boundary.
    final blur = MaskFilter.blur(BlurStyle.normal, w * 0.05);
    canvas.drawPath(
      _blob(centre, w * 0.36, beat * 0.7),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.60)
        ..maskFilter = blur,
    );
    canvas.drawPath(
      _blob(Offset(w * 0.60, h * 0.40), w * 0.30, 0.9 + beat * 0.5),
      Paint()
        ..color = accent.withValues(alpha: 0.12)
        ..maskFilter = blur,
    );

    // Deliberately no ring or frame around the art — nothing encloses it.

    // Halftone field in the lower-left, dots fading out as they rise.
    final dot = Paint()..color = accent.withValues(alpha: 0.22);
    final step = w * 0.052;
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < 6; col++) {
        final x = w * 0.06 + col * step;
        final y = h * 0.62 + row * step;
        if (x > w * 0.44 || y > h * 0.95) continue;
        final fade = 1 - (row / 7) - (col / 12);
        if (fade <= 0.08) continue;
        canvas.drawCircle(
          Offset(x, y),
          w * 0.011 * fade + w * 0.004,
          dot..color = accent.withValues(alpha: 0.26 * fade),
        );
      }
    }

    // Confetti: filled dots, open rings, and the mark's own chevron.
    final confetti = <_Bit>[
      _Bit(0.16, 0.14, _Kind.chevron, accent, 1.0),
      _Bit(0.84, 0.20, _Kind.dot, spark, 1.0),
      _Bit(0.90, 0.52, _Kind.ring, cool, 0.9),
      _Bit(0.24, 0.36, _Kind.dot, cool, 0.7),
      _Bit(0.72, 0.86, _Kind.chevron, spark, 0.8),
      _Bit(0.10, 0.52, _Kind.ring, accent, 0.75),
      _Bit(0.50, 0.09, _Kind.dot, accent, 0.8),
    ];

    for (var i = 0; i < confetti.length; i++) {
      // Rotate which bits appear per beat so the three plates aren't identical.
      if ((i + beat) % 7 == 3) continue;
      final b = confetti[i];
      final c = Offset(w * b.x, h * b.y);
      final s = w * 0.030 * b.scale;
      switch (b.kind) {
        case _Kind.dot:
          canvas.drawCircle(c, s * 0.55, Paint()..color = b.color.withValues(alpha: 0.85));
        case _Kind.ring:
          canvas.drawCircle(
            c,
            s * 0.72,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = w * 0.010
              ..color = b.color.withValues(alpha: 0.75),
          );
        case _Kind.chevron:
          final p = Path()
            ..moveTo(c.dx - s * 0.5, c.dy - s * 0.7)
            ..lineTo(c.dx + s * 0.5, c.dy)
            ..lineTo(c.dx - s * 0.5, c.dy + s * 0.7);
          canvas.drawPath(
            p,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = w * 0.013
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = b.color.withValues(alpha: 0.8),
          );
      }
    }
  }

  @override
  bool shouldRepaint(_PlateDecorPainter old) =>
      old.accent != accent ||
      old.wash != wash ||
      old.cool != cool ||
      old.spark != spark ||
      old.beat != beat;
}

enum _Kind { dot, ring, chevron }

class _Bit {
  final double x;
  final double y;
  final _Kind kind;
  final Color color;
  final double scale;

  const _Bit(this.x, this.y, this.kind, this.color, this.scale);
}
