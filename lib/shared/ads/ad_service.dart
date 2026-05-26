import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:flutter/foundation.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Replace these with your real placement IDs from Meta Audience Network dashboard.
  // Test IDs below work on any device during development.
  static final _rewardedId = kDebugMode
      ? 'VID_HD_16_9_15S_LINK#2090571174322989_3194357793944319'
      : 'YOUR_REWARDED_VIDEO_PLACEMENT_ID';

  bool _loaded = false;
  VoidCallback? _onRewarded;

  Future<void> init() async {
    await FacebookAudienceNetwork.init();
    _preload();
  }

  void _preload() {
    _loaded = false;
    FacebookRewardedVideoAd.loadRewardedVideoAd(
      placementId: _rewardedId,
      listener: _onResult,
    );
  }

  void _onResult(RewardedVideoAdResult result, dynamic value) {
    switch (result) {
      case RewardedVideoAdResult.LOADED:
        _loaded = true;
      case RewardedVideoAdResult.VIDEO_COMPLETE:
        _loaded = false;
        final cb = _onRewarded;
        _onRewarded = null;
        cb?.call();
        _preload(); // queue next ad
      case RewardedVideoAdResult.VIDEO_CLOSED:
        // Closed without completing — don't reward.
        _loaded = false;
        _onRewarded = null;
        _preload();
      case RewardedVideoAdResult.ERROR:
        _loaded = false;
        // Graceful fallback: grant reward so UX never breaks.
        final cb = _onRewarded;
        _onRewarded = null;
        cb?.call();
        _preload();
      default:
        break;
    }
  }

  /// Shows a rewarded ad and calls [onRewarded] when the user completes it.
  /// If no ad is loaded yet, grants the reward immediately as a fallback.
  void showRewarded({required VoidCallback onRewarded}) {
    if (!_loaded) {
      onRewarded();
      _preload();
      return;
    }
    _onRewarded = onRewarded;
    FacebookRewardedVideoAd.showRewardedVideoAd();
  }
}
