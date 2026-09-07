import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<bool> initMobileAds() async {
  try {
    await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> showRewardedAd(String id) async {
  final completer = Completer<bool>();
  try {
    await RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
            onAdFailedToShowFullScreenContent: (a, err) {
              a.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (a, r) {
            if (!completer.isCompleted) completer.complete(true);
          });
        },
        onAdFailedToLoad: (err) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
  } catch (_) {
    if (!completer.isCompleted) completer.complete(false);
  }
  return completer.future.timeout(const Duration(seconds: 12), onTimeout: () => false);
}

Future<void> showInterstitialAd(String id) async {
  final completer = Completer<void>();
  try {
    await InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (a) {
              a.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (a, err) {
              a.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (err) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
  } catch (_) {
    if (!completer.isCompleted) completer.complete();
  }
  return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {});
}
