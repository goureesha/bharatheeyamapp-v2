import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_service.dart';

class AdService {
  // ── Ad Unit IDs (test IDs — replace with real ones from AdMob dashboard) ──
  static String get bannerAdUnitId =>
      'ca-app-pub-3940256099942544/6300978111';

  static String get interstitialAdUnitId =>
      'ca-app-pub-3940256099942544/1033173712';

  static String get rewardedInterstitialAdUnitId =>
      'ca-app-pub-3940256099942544/5354046379'; // test rewarded interstitial

  // ───────────────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (SubscriptionService.hasAdFree) return;
    if (kIsWeb) return; // AdMob not supported on web
    await MobileAds.instance.initialize();
  }

  /// Regular interstitial — 5-second skippable (AdMob controls the skip timer).
  /// Call before/after an action (generate, tab switch).
  static Future<void> showInterstitialAd(BuildContext context,
      {VoidCallback? onDismissed}) async {
    if (SubscriptionService.hasAdFree) return;
    if (kIsWeb) {
      onDismissed?.call();
      return;
    }
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onDismissed?.call();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onDismissed?.call();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          onDismissed?.call(); // Don't block the user if ad fails
        },
      ),
    );
  }

  /// Rewarded interstitial — NON-skippable, ~30 seconds.
  /// Used on the Save button. Calls [onCompleted] after the ad finishes.
  static Future<void> showRewardedInterstitialAd(BuildContext context,
      {required VoidCallback onCompleted}) async {
    if (SubscriptionService.hasAdFree) {
      onCompleted();
      return;
    }
    if (kIsWeb) {
      onCompleted();
      return;
    }
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onCompleted();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              onCompleted(); // Don't block save if ad fails
            },
          );
          ad.show(onUserEarnedReward: (_, reward) {
            debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedInterstitialAd failed to load: $error');
          onCompleted(); // Don't block save
        },
      ),
    );
  }
}

// ── Banner widget (unchanged) ─────────────────────────────────────────────────

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (SubscriptionService.hasAdFree || kIsWeb) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SubscriptionService.hasAdFree || kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Colors.transparent,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
