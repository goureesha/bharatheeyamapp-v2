/// Stub SubscriptionService — all features unlocked, no paywall.
class SubscriptionService {
  static bool hasSubscription = true;
  static bool needsInternetVerification = false;
  static bool isGracePeriodActive = false;
  static int gracePeriodsUsedThisYear = 0;
  static int get subscriptionDaysRemaining => 365;
  static int get gracePeriodRemainingHours => 0;

  static bool get hasAccess => true;
  static bool get isTrialActive => false;
  static String get statusText => 'Premium (Unlocked)';
  static String get graceStatusText => '';
  static bool get hasAdFree => true;

  static Future<void> initialize() async {}
  static void dispose() {}
  static Future<void> checkOnReconnect() async {}
  static Future<bool> buySubscription() async => false;
  static Future<bool> buyAdFreeSubscription() async => false;
  static Future<void> restorePurchases() async {}
  static Future<void> reVerify() async {}
}
