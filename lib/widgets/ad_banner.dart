import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/config.dart';

/// Sticky anchored adaptive banner. Collapses to nothing until an ad loads.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load(MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _load(int width) async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    BannerAd(
      adUnitId: Config.bannerAdUnit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _ad = ad as BannerAd);
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    ).load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
