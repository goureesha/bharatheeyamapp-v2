import 'package:flutter/material.dart';

class AdService {
  static Future<void> initialize() async {}

  static String get bannerAdUnitId => '';
  static String get interstitialAdUnitId => '';

  static Future<void> showInterstitialAd(BuildContext context) async {}
}

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
