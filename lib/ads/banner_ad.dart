import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'ad_config.dart';

/// A self-contained, anchored banner ad.
///
/// Drop it anywhere a fixed-height banner fits (e.g. above the bottom nav, or
/// pinned under a feed). It loads on first build, sizes itself to the loaded
/// creative, disposes on teardown, and renders nothing until an ad is ready —
/// so it never reserves blank space or shifts layout when a load fails.
class PBannerAd extends StatefulWidget {
  const PBannerAd({super.key, this.adSize = AdSize.banner});

  final AdSize adSize;

  @override
  State<PBannerAd> createState() => _PBannerAdState();
}

class _PBannerAdState extends State<PBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: AdConfig.bannerUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          Talker().handle(error, StackTrace.current, 'Banner load failed');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
