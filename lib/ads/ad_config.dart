import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central source of AdMob unit ids.
///
/// Unit ids are read from `.env` (see `.env.example`) so each environment can
/// point at different inventory. When a key is missing — e.g. local dev, or a
/// format you haven't provisioned yet — we fall back to Google's official
/// **test** ad unit ids, which always fill and never risk policy strikes.
///
/// The AdMob *App* id is NOT here: it must live in the native manifests
/// (`AndroidManifest.xml` / `Info.plist`), not in Dart.
class AdConfig {
  const AdConfig._();

  // Google's official sample unit ids — safe to ship in debug, never in prod.
  // https://developers.google.com/admob/flutter/test-ads#sample_ad_units
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  static String _envOrTest({
    required String androidKey,
    required String iosKey,
    required String androidTest,
    required String iosTest,
  }) {
    if (Platform.isAndroid) {
      final v = dotenv.maybeGet(androidKey);
      return (v == null || v.isEmpty) ? androidTest : v;
    }
    final v = dotenv.maybeGet(iosKey);
    return (v == null || v.isEmpty) ? iosTest : v;
  }

  static String get bannerUnitId => _envOrTest(
    androidKey: 'ADMOB_BANNER_UNIT_ANDROID',
    iosKey: 'ADMOB_BANNER_UNIT_IOS',
    androidTest: _testBannerAndroid,
    iosTest: _testBannerIos,
  );

  static String get interstitialUnitId => _envOrTest(
    androidKey: 'ADMOB_INTERSTITIAL_UNIT_ANDROID',
    iosKey: 'ADMOB_INTERSTITIAL_UNIT_IOS',
    androidTest: _testInterstitialAndroid,
    iosTest: _testInterstitialIos,
  );
}
