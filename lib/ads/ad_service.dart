import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'ad_config.dart';

part 'ad_service.g.dart';

final _talker = Talker();

/// One-shot SDK init. Called from `main()` before `runApp`.
///
/// On debug builds we don't need a `RequestConfiguration` with test device ids
/// because we ship Google's test unit ids (see [AdConfig]); when you swap in
/// real unit ids, register your physical test devices here to avoid serving —
/// and accidentally clicking — live ads during development.
Future<void> initMobileAds() async {
  await MobileAds.instance.initialize();
}

/// Preloads and serves interstitials.
///
/// Usage: `ref.read(interstitialControllerProvider.notifier).show()` at a
/// natural break point. The controller transparently reloads the next ad after
/// each show (or after a failed/expired impression), so callers never block on
/// network — if nothing is loaded yet, `show()` is a no-op and the user flow
/// continues uninterrupted.
@Riverpod(keepAlive: true)
class InterstitialController extends _$InterstitialController {
  InterstitialAd? _ad;
  bool _loading = false;

  @override
  void build() {
    _load();
    ref.onDispose(() {
      _ad?.dispose();
      _ad = null;
    });
  }

  void _load() {
    if (_loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              _load(); // queue the next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _talker.handle(error, StackTrace.current, 'Interstitial show failed');
              ad.dispose();
              _ad = null;
              _load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _ad = null;
          _talker.handle(error, StackTrace.current, 'Interstitial load failed');
        },
      ),
    );
  }

  /// Shows the preloaded interstitial if one is ready. Returns `true` if an ad
  /// was actually presented. Never throws.
  bool show() {
    final ad = _ad;
    if (ad == null) {
      _load(); // nothing ready — warm one up for next time
      return false;
    }
    _ad = null;
    ad.show();
    return true;
  }
}
