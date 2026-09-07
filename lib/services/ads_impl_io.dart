import 'dart:io' show Platform;

import 'ads_impl_stub.dart' as stub;
import 'ads_impl_mobile.dart' as mobile;

Future<bool> initMobileAds() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.initMobileAds();
  }
  return stub.initMobileAds();
}

Future<bool> showRewardedAd(String id) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.showRewardedAd(id);
  }
  return stub.showRewardedAd(id);
}

Future<void> showInterstitialAd(String id) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return mobile.showInterstitialAd(id);
  }
  return stub.showInterstitialAd(id);
}
