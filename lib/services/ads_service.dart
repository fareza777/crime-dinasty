import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ads_impl.dart';

/// AdMob wiring. Uses official Google test IDs unless --dart-define overrides.
///
/// Ads never block cold start: [init] is fail-soft, timed out, and must be
/// called after the first Flutter frame (see [GameController.boot]).
class AdsConfig {
  static const testApp = 'ca-app-pub-3940256099942544~3347511713';
  static const testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  static const appId = String.fromEnvironment('ADMOB_APP_ID', defaultValue: testApp);
  static const rewardedId =
      String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: testRewarded);
  static const interstitialId =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: testInterstitial);
}

class AdsService {
  AdsService();

  bool initialized = false;
  bool available = false;
  bool adsRemoved = false;
  DateTime? lastInterstitial;

  /// Initialize AdMob. Never throws. No-ops on web / missing Play Services.
  Future<void> init() async {
    if (initialized) return;
    initialized = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      available = false;
      return;
    }
    try {
      available = await initMobileAds().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
    } catch (e, st) {
      debugPrint('Ads init skipped: $e\n$st');
      available = false;
    }
  }

  /// Rewarded: retry last decision OR bonus opportunity.
  Future<bool> showRewarded({required String reason}) async {
    if (adsRemoved) return true;
    if (!available || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      // Preview / no Play Services: grant so the loop stays playable.
      return true;
    }
    try {
      return await showRewardedAd(AdsConfig.rewardedId);
    } catch (e) {
      debugPrint('Rewarded skipped: $e');
      return kDebugMode;
    }
  }

  /// Interstitials only at natural pauses, throttled.
  Future<void> maybeInterstitial({required String reason, required int yearsSince}) async {
    if (adsRemoved || !available) return;
    if (reason != 'generation' && reason != 'prison') return;
    if (yearsSince < 4) return;
    final last = lastInterstitial;
    if (last != null && DateTime.now().difference(last).inMinutes < 8) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await showInterstitialAd(AdsConfig.interstitialId).timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      lastInterstitial = DateTime.now();
    } catch (e) {
      debugPrint('Interstitial skipped: $e');
    }
  }
}
