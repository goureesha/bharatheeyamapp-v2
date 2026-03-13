import 'package:flutter/material.dart';

class AdService {
  static Future<void> initialize() async {}

  static String get bannerAdUnitId => '';
  static String get interstitialAdUnitId => '';
  static String get rewardedInterstitialAdUnitId => '';

  /// No-op on web — just calls onDismissed immediately.
  static Future<void> showInterstitialAd(BuildContext context,
      {VoidCallback? onDismissed}) async {
    onDismissed?.call();
  }

  /// No-op on web — calls onCompleted immediately so the save still works.
  static Future<void> showRewardedInterstitialAd(BuildContext context,
      {required VoidCallback onCompleted}) async {
    onCompleted();
  }
}

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
