import 'dart:async';

import 'package:flutter/widgets.dart';

Future<bool> initMobileAds() async => true;

Future<bool> showRewardedAd(String id) async => false;

Future<void> showInterstitialAd(String id) async {}

Widget buildAdsBanner(String adUnitId) => const SizedBox.shrink();
