class SubscriptionService {
  static bool isProUser = false;
  static const String entitlementId = 'Bharatiyam Pro';

  static Future<void> initialize() async {}

  static Future<bool> presentPaywall() async {
    return false;
  }

  static Future<bool> checkProStatus() async {
    return false;
  }
}
