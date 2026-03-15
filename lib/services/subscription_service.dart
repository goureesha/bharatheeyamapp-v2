import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _subscriptionProductId = 'ad_free_yearly_500';
  static const String _subStatusKey = 'has_active_subscription';
  static const String _trialStartKey = 'trial_start_timestamp';
  static const int _trialDays = 3;

  static InAppPurchase get _iap => InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // Subscription status
  static bool hasSubscription = false;

  // Trial tracking
  static DateTime? trialStartDate;

  /// True if the user has access to the app (either subscribed or within trial)
  static bool get hasAccess => hasSubscription || isTrialActive;

  /// True if the free trial is still active
  static bool get isTrialActive {
    if (trialStartDate == null) return false;
    final elapsed = DateTime.now().difference(trialStartDate!);
    return elapsed.inDays < _trialDays;
  }

  /// Days remaining in trial (0 if expired)
  static int get trialDaysRemaining {
    if (trialStartDate == null) return 0;
    final elapsed = DateTime.now().difference(trialStartDate!);
    final remaining = _trialDays - elapsed.inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Call this when the app starts
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load subscription status
    hasSubscription = prefs.getBool(_subStatusKey) ?? false;

    // Load or set trial start date
    final trialTs = prefs.getInt(_trialStartKey);
    if (trialTs != null) {
      trialStartDate = DateTime.fromMillisecondsSinceEpoch(trialTs);
    } else {
      // First install — start trial now
      trialStartDate = DateTime.now();
      await prefs.setInt(_trialStartKey, trialStartDate!.millisecondsSinceEpoch);
    }

    if (kIsWeb) return;

    // Setup the purchase listener stream
    final purchaseUpdated = _iap.purchaseStream;
    _purchaseSub = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSub?.cancel();
      },
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );

    if (!kIsWeb) {
       await _restorePurchasesSilently();
    }
  }

  static void dispose() {
    if (!kIsWeb) {
      _purchaseSub?.cancel();
    }
  }

  /// Trigger the purchase flow
  static Future<bool> buySubscription() async {
    if (kIsWeb) return false;

    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint('Store not available');
      return false;
    }

    final ProductDetailsResponse detailResponse = 
        await _iap.queryProductDetails({_subscriptionProductId});

    if (detailResponse.notFoundIDs.isNotEmpty) {
      debugPrint('Product $_subscriptionProductId not found on the Store.');
      return false;
    }

    if (detailResponse.productDetails.isEmpty) {
       return false;
    }

    final ProductDetails productDetails = detailResponse.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restores previous purchases
  static Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  static Future<void> _restorePurchasesSilently() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
       debugPrint('Silent restore failed: $e');
    }
  }

  static Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // pending
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.productID == _subscriptionProductId) {
             await _grantAccess();
          }
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  static Future<void> _grantAccess() async {
    hasSubscription = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, true);
    debugPrint('Subscription Granted!');
  }

  // Legacy compatibility
  static bool get hasAdFree => hasSubscription;
  static Future<bool> buyAdFreeSubscription() => buySubscription();
}
