import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A confirmation-style [FDialog] with a title, optional body, and a row/column of actions.
///
/// forui 0.24 removed [FDialog]'s convenience `title`/`body`/`direction`/`actions` constructor in
/// favor of a bare `builder` — this widget restores that shape (per forui.dev's recommended
/// dialog snippet) so call sites don't each re-implement the layout.
class PConfirmDialog extends StatelessWidget {
  final FDialogStyleDelta style;
  final Animation<double>? animation;
  final Widget title;
  final Widget? body;
  final Axis direction;
  final List<Widget> actions;

  const PConfirmDialog({
    required this.title,
    required this.actions,
    this.body,
    this.direction = Axis.horizontal,
    this.style = const .context(),
    this.animation,
    super.key,
  });

  @override
  Widget build(BuildContext context) => FDialog(
    style: style,
    animation: animation,
    builder: (context, style) {
      final touch = context.platformVariant.touch;
      return Padding(
        padding: touch
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 18)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: touch
                  ? const EdgeInsets.only(left: 8, right: 8, bottom: 9)
                  : const EdgeInsets.only(left: 8, right: 8, bottom: 5),
              child: DefaultTextStyle.merge(style: style.titleTextStyle, child: title),
            ),
            if (body case final body?)
              Flexible(
                child: Padding(
                  padding: touch
                      ? const EdgeInsets.only(left: 8, right: 8, bottom: 20)
                      : const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                  child: DefaultTextStyle.merge(style: style.bodyTextStyle, child: body),
                ),
              ),
            switch (direction) {
              Axis.horizontal => Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: touch ? 10 : 8,
                children: touch ? [for (final action in actions) Expanded(child: action)] : actions,
              ),
              Axis.vertical => Column(mainAxisSize: MainAxisSize.min, spacing: touch ? 10 : 8, children: actions),
            },
          ],
        ),
      );
    },
  );
}
