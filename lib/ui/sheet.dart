import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Passe's standard bottom-sheet chrome.
///
/// Wraps an [FSheets] in a [Container] with the project's signature
/// silhouette — 32-px radius on every corner, side borders only, app
/// background fill, and keyboard-aware bottom padding so form fields
/// stay visible when the IME opens.
///
/// Prefer [showPSheet] over reaching for this widget directly. Use the
/// raw widget only when you need to embed the chrome inside something
/// `showFSheet` doesn't accommodate (e.g. a stateful sheet host).
class PSheet extends StatelessWidget {
  final Widget child;

  /// Padding inside the chrome, before the bottom keyboard inset is
  /// added on. Defaults to a uniform 24 px on every side, matching the
  /// existing filter and lobby-form sheets.
  final EdgeInsetsGeometry padding;

  const PSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // Apply the dynamic keyboard inset on top of the configured bottom
    // padding so a tall sheet's CTA stays above the on-screen keyboard.
    final resolved = padding
        .resolve(Directionality.of(context))
        .copyWith(bottom: padding.resolve(Directionality.of(context)).bottom + bottomInset);

    return FSheets(
      child: Container(
        padding: resolved,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(32),
          border: Border.symmetric(
            horizontal: BorderSide(color: colors.border),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Show a bottom-sheet with Passe's standard chrome.
///
/// All app sheets should go through this helper so the silhouette
/// (radius, border, padding, keyboard handling) stays consistent. The
/// [builder] receives the sheet's `BuildContext` and should return the
/// sheet's content; [PSheet] wraps it.
///
/// [maxHeightRatio] caps the sheet's height against the available
/// vertical space. Default `0.9` matches the lobby-form sheet; pass
/// `1.0` for an info-style sheet that can grow to the full screen.
Future<T?> showPSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxHeightRatio = 0.9,
  EdgeInsetsGeometry padding = const EdgeInsets.all(24),
}) {
  return showFSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    side: .btt,
    mainAxisMaxRatio: maxHeightRatio,
    builder: (ctx) => PSheet(
      padding: padding,
      child: Builder(builder: builder),
    ),
  );
}

/// Top-of-sheet title shared by every [PSheet].
///
/// Renders as `typography.xl2` at bold weight — visually distinct from
/// the all-caps [PSheetSectionLabel] used for groups inside the sheet.
/// Pair the two: one title per sheet at the top, section labels for
/// each logical group beneath.
///
/// [trailing] sits at the far right of the row — typically a ghost X
/// close button.
class PSheetTitle extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const PSheetTitle({
    super.key,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.theme.typography.xl2
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Small all-caps section heading used inside [PSheet] content.
///
/// Matches the typographic vocabulary the lobby-info sheet established
/// for grouping its members / settings blocks: 11-px Bitter at w700,
/// 0.7-px letter-spacing, foreground muted.
///
/// Pass [trailing] to attach a right-aligned widget — a small action
/// button, count, or italic description. A [Spacer] is inserted between
/// the label and the trailing, so it pushes to the far right of the
/// row's available width.
class PSheetSectionLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const PSheetSectionLabel({
    super.key,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final text = Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colors.mutedForeground,
        letterSpacing: 0.7,
        height: 1.2,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          text,
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
