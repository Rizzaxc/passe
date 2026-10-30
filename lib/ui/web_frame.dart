import 'dart:math' as math;

import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';

import '../core/app_platform.dart';
import 'theme.dart';

/// On web, caps the app at tablet width and centres it on a muted backdrop.
/// The layouts are phone/iPad-portrait only (the iOS build ships on iPad), so
/// [maxWidth] stays inside the range they're already exercised at. A no-op on
/// iOS/Android.
///
/// Wraps everything under `MaterialApp.builder`, *outside* [FTheme] and
/// [FToaster]: forui hosts its own overlay there, and anything above the frame
/// (coach marks, toasts) would otherwise lay out against the whole browser
/// window. Narrows [MediaQueryData.size] to match — screens that size off `MediaQuery.sizeOf(context).width` see the
/// frame, not the browser window.
class PWebFrame extends StatelessWidget {
  const PWebFrame({super.key, required this.child, this.maxWidth = 1024});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isWeb) return child;

    final media = MediaQuery.of(context);
    final width = math.min(media.size.width, maxWidth);
    if (width == media.size.width) return child;

    // Above FTheme, so read the app theme directly.
    final colors = pbThemeLight.colors;
    return ColoredBox(
      color: colors.muted,
      child: Center(
        child: SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: colors.border),
              ),
            ),
            child: MediaQuery(
              data: media.copyWith(size: Size(width, media.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
