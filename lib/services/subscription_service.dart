import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../core/secrets.dart';

class SubscriptionService {
  static bool isProUser = false;
  static const String entitlementId = 'Bharatiyam Pro';

  static Future<void> initialize() async {
    if (kIsWeb) return; 

    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration = PurchasesConfiguration(Secrets.revenueCatApiKey);
      await Purchases.configure(configuration);
      
      final customerInfo = await Purchases.getCustomerInfo();
      isProUser = customerInfo.entitlements.all[entitlementId]?.isActive == true;
    } on PlatformException catch (e) {
      debugPrint("RevenueCat Init Error: ${e.message}");
    }
  }

  static Future<bool> presentPaywall() async {
    if (kIsWeb) return false;
    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
      if (paywallResult == PaywallResult.purchased || paywallResult == PaywallResult.restored) {
        return await checkProStatus();
      }
    } catch (e) {
      debugPrint("Paywall presenting error: $e");
    }
    return false;
  }

  static Future<bool> checkProStatus() async {
    if (kIsWeb) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      isProUser = customerInfo.entitlements.all[entitlementId]?.isActive == true;
      return isProUser;
    } catch (_) {
      return false;
    }
  }
}
