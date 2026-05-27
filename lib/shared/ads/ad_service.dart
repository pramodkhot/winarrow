import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Google's official test IDs — safe to use on any device during development.
  // TODO: Replace with your real ad unit IDs from https://admob.google.com
  static final _rewardedAdUnitId = defaultTargetPlatform == TargetPlatform.iOS
      ? (kDebugMode
            ? 'ca-app-pub-3940256099942544/1712485313'
            : 'YOUR_IOS_REWARDED_AD_UNIT_ID')
      : (kDebugMode
            ? 'ca-app-pub-3940256099942544/5224354917'
            : 'YOUR_ANDROID_REWARDED_AD_UNIT_ID');

  RewardedAd? _rewardedAd;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    _preload();
  }

  void _preload() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Shows a rewarded ad and calls [onRewarded] when the user earns the reward.
  /// Falls back to immediately granting the reward if no ad is ready.
  void showRewarded({required VoidCallback onRewarded}) {
    final ad = _rewardedAd;
    if (ad == null) {
      onRewarded();
      _preload();
      return;
    }

    _rewardedAd = null; // consume before showing

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _preload();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        onRewarded(); // graceful fallback
        _preload();
      },
    );

    ad.show(onUserEarnedReward: (_, __) => onRewarded());
  }
}
