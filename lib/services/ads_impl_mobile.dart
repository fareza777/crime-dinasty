import 'dart:async';

import 'package:flutter/material.dart';
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

Widget buildAdsBanner(String adUnitId) => _AdaptiveBanner(adUnitId: adUnitId);

class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({required this.adUnitId});
  final String adUnitId;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (_ad != null) return;
    final size = AdSize.banner;
    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (_ad == ad) _ad = null;
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } catch (_) {
      ad.dispose();
      _ad = null;
    }
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
    return ColoredBox(
      color: const Color(0xFF0B1220),
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

