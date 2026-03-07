import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _adFreeProductId = 'ad_free_yearly_500';
  static const String _subStatusKey = 'has_active_subscription';

  static final InAppPurchase _iap = InAppPurchase.instance;
  static late StreamSubscription<List<PurchaseDetails>> _purchaseSub;

  // Cache flag in memory for instant access
  static bool hasAdFree = false;

  /// Call this when the app starts
  static Future<void> initialize() async {
    // 1. Load cached status immediately
    final prefs = await SharedPreferences.getInstance();
    hasAdFree = prefs.getBool(_subStatusKey) ?? false;

    // 2. Setup the purchase listener stream
    final purchaseUpdated = _iap.purchaseStream;
    _purchaseSub = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSub.cancel();
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );

    // 3. (Optional) Check to restore previous purchases dynamically from the Play Store
    // Usually, you might do this behind a "Restore Purchases" button to avoid spamming the API,
    // but doing a quick check ensures the flag stays updated if they bought it on another device.
    if (!kIsWeb) {
       await _restorePurchasesSilently();
    }
  }

  static void dispose() {
    _purchaseSub.cancel();
  }

  /// Trigger the purchase flow for the 500 INR Yearly Ad-Free logic
  static Future<bool> buyAdFreeSubscription() async {
    if (kIsWeb) return false; // In-app billing is not supported on Web

    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('Store not available');
      return false;
    }

    // Query the exact product from Google Play
    final ProductDetailsResponse detailResponse = 
        await _iap.queryProductDetails({_adFreeProductId});

    if (detailResponse.notFoundIDs.isNotEmpty) {
      debugPrint('Product $_adFreeProductId not found on the Store. Ensure it is configured in Play Console.');
      return false;
    }

    if (detailResponse.productDetails.isEmpty) {
       return false;
    }

    final ProductDetails productDetails = detailResponse.productDetails.first;

    // Launch the billing flow
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // Using buyNonConsumable since a yearly subscription functions exactly like a non-consumable 
    // in terms of the initial purchase hook, though true Subscriptions have their own renewals.
    // The `in_app_purchase` package handles both under `buyNonConsumable`
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restores previous purchases
  static Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  static Future<void> _restorePurchasesSilently() async {
    // This silently requests Google Play to push past purchases down the purchaseStream
    try {
      await _iap.restorePurchases();
    } catch (e) {
       debugPrint('Silent restore failed: $e');
    }
  }

  /// Process the transactions streaming in from Google Play
  static Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          if (purchaseDetails.productID == _adFreeProductId) {
             await _grantAdFreeAccess();
          }
        }
        
        // Always complete the pending purchase, otherwise the user is refunded!
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  static Future<void> _grantAdFreeAccess() async {
    hasAdFree = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, true);
    debugPrint('Ad-Free Subscription Granted and Cached!');
  }
}
