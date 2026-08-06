import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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
