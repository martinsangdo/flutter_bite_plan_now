import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/config.dart';

/// Owns the interstitial: preloads one, shows it on every 4th swipe or deck reload.
class AdsService {
  InterstitialAd? _ready;
  bool _loading = false;
  int _swipes = 0;
  bool _due = false;

  static Future<void> init() => MobileAds.instance.initialize();

  void preload() {
    if (_ready != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: Config.interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ready = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  /// Counts a swipe; completes once any ad it triggered is dismissed.
  /// Never shows an ad when [cooking] (entering Cook Mode): a due ad waits for the next skip.
  Future<void> onSwipe({required bool cooking}) {
    if (++_swipes % kAdEverySwipes == 0) _due = true;
    if (!_due || cooking) return Future.value();
    _due = false;
    return _show();
  }

  Future<void> onDeckReload() => _show();

  Future<void> _show() {
    final ad = _ready;
    if (ad == null) {
      preload();
      return Future.value();
    }
    _ready = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        done.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        preload();
        done.complete();
      },
    );
    ad.show();
    return done.future;
  }
}
