import 'package:flutter/foundation.dart';

/// Web-safe platform checks. `dart:io`'s `Platform.isX` throws
/// `UnsupportedError` on web, so every platform branch in `lib/` goes through
/// here instead — never import `Platform` from `dart:io` directly.
///
/// Web is a showcase target (`app.passe.vn`): mobile-only surfaces are gated
/// via `guardWeb` (`lib/ui/get_app_sheet.dart`) rather than hidden.
class AppPlatform {
  const AppPlatform._();

  static const bool isWeb = kIsWeb;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Native Apple platforms — where `sign_in_with_apple`'s native credential
  /// flow works.
  static bool get isApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
