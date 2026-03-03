import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static bool isProUser = false;
  static const String _entitlementId = 'premium_access'; // Set this inside RevenueCat

  static Future<void> initialize() async {
    if (kIsWeb) return; // RevenueCat is mobile-only for Flutter

    // REPLACE WITH YOUR REVENUECAT PUBLIC API KEYS
    // Purchases.configure(PurchasesConfiguration("YOUR_REVENUECAT_PUBLIC_KEY"));
    
    // final customerInfo = await Purchases.getCustomerInfo();
    // isProUser = customerInfo.entitlements.all[_entitlementId]?.isActive == true;
  }

  static Future<bool> purchasePremium() async {
    /*
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        final package = offerings.current!.availablePackages[0];
        final customerInfo = await Purchases.purchasePackage(package);
        isProUser = customerInfo.entitlements.all[_entitlementId]?.isActive == true;
        return isProUser;
      }
    } catch (e) {
      debugPrint("Purchase failed: $e");
    }
    */
    return false;
  }
}
