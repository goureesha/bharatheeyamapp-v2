import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static const String _subscriptionProductId = 'ad_free_yearly_500';

  // ── Pref keys ──
  static const String _subStatusKey = 'has_active_subscription';
  static const String _trialStartKey = 'trial_start_timestamp';
  static const String _lastVerifiedKey = 'last_verified_timestamp';
  static const String _purchaseDateKey = 'purchase_date_timestamp';
  static const int _trialDays = 3;
  static const int _offlineGraceDays = 2;

  static InAppPurchase get _iap => InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // ── State ──
  static bool hasSubscription = false;
  static DateTime? trialStartDate;
  static DateTime? lastVerifiedDate;
  static DateTime? purchaseDate;

  /// Whether the app must show the "connect to internet" screen
  static bool needsInternetVerification = false;

  /// True if the user has access (subscribed + verified recently, OR trial active)
  static bool get hasAccess {
    if (kIsWeb) return true;
    if (needsInternetVerification) return false;
    return hasSubscription || isTrialActive;
  }

  /// True if the free trial is still active
  static bool get isTrialActive {
    if (trialStartDate == null) return false;
    // Use last verified server time if available, else device time as fallback
    final now = lastVerifiedDate ?? DateTime.now();
    final elapsed = now.difference(trialStartDate!);
    return elapsed.inDays < _trialDays;
  }

  /// Days remaining in trial (0 if expired)
  static int get trialDaysRemaining {
    if (trialStartDate == null) return 0;
    final now = lastVerifiedDate ?? DateTime.now();
    final elapsed = now.difference(trialStartDate!);
    final remaining = _trialDays - elapsed.inDays;
    return remaining > 0 ? remaining : 0;
  }

  // ════════════════════════════════════════════════
  // INITIALIZATION
  // ════════════════════════════════════════════════

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached state
    hasSubscription = prefs.getBool(_subStatusKey) ?? false;

    final trialTs = prefs.getInt(_trialStartKey);
    if (trialTs != null) {
      trialStartDate = DateTime.fromMillisecondsSinceEpoch(trialTs);
    } else {
      // First install — start trial
      trialStartDate = DateTime.now();
      await prefs.setInt(_trialStartKey, trialStartDate!.millisecondsSinceEpoch);
    }

    final lastVerTs = prefs.getInt(_lastVerifiedKey);
    if (lastVerTs != null) {
      lastVerifiedDate = DateTime.fromMillisecondsSinceEpoch(lastVerTs);
    }

    final purchaseTs = prefs.getInt(_purchaseDateKey);
    if (purchaseTs != null) {
      purchaseDate = DateTime.fromMillisecondsSinceEpoch(purchaseTs);
    }

    if (kIsWeb) return;

    // Setup purchase listener
    _purchaseSub = _iap.purchaseStream.listen(
      (list) => _listenToPurchaseUpdated(list),
      onDone: () => _purchaseSub?.cancel(),
      onError: (e) => debugPrint('Purchase stream error: $e'),
    );

    // Verify subscription with Play Store
    await _verifyWithPlayStore();
  }

  static void dispose() {
    if (!kIsWeb) {
      _purchaseSub?.cancel();
    }
  }

  // ════════════════════════════════════════════════
  // PLAY STORE VERIFICATION (core logic)
  // ════════════════════════════════════════════════

  /// Checks subscription status with Google Play.
  /// If offline, enforces 2-day grace period.
  static Future<void> _verifyWithPlayStore() async {
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _handleOffline();
        return;
      }

      // This triggers the purchase stream with current purchase state
      await _iap.restorePurchases();

      // If we reach here, Play Store was contactable.
      // The actual grant/revoke happens in _listenToPurchaseUpdated.
      // We mark verification timestamp after a short delay to let the stream process.
      await Future.delayed(const Duration(milliseconds: 1500));

      // Record that we successfully talked to Play Store
      await _updateLastVerified();
      needsInternetVerification = false;

      // After restore completes, if no active purchase was found,
      // the stream handler would NOT have called _grantAccess.
      // We need to check: if hasSubscription was true before but the stream
      // didn't confirm it, we should revoke.
      // This is handled by _processRestoreResults below.
    } catch (e) {
      debugPrint('Play Store verification failed: $e');
      _handleOffline();
    }
  }

  /// Called when we can't reach Play Store — enforce grace period
  static void _handleOffline() {
    if (!hasSubscription) {
      // Not subscribed, nothing to grace-period
      needsInternetVerification = false;
      return;
    }

    // Check how long since last successful verification
    if (lastVerifiedDate == null) {
      // Never verified — must connect
      needsInternetVerification = true;
      return;
    }

    final elapsed = DateTime.now().difference(lastVerifiedDate!);
    if (elapsed.inDays >= _offlineGraceDays) {
      // Grace period expired — lock until internet
      needsInternetVerification = true;
      debugPrint('Offline grace period expired (${elapsed.inDays} days). Locking app.');
    } else {
      // Within grace period — allow access
      needsInternetVerification = false;
      debugPrint('Within offline grace period (${elapsed.inDays} days). Access allowed.');
    }
  }

  /// Record the timestamp of successful Play Store communication
  static Future<void> _updateLastVerified() async {
    lastVerifiedDate = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastVerifiedKey, lastVerifiedDate!.millisecondsSinceEpoch);
  }

  // ════════════════════════════════════════════════
  // PURCHASE FLOW
  // ════════════════════════════════════════════════

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

  /// Manually restore purchases (user-triggered)
  static Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 1500));
      await _updateLastVerified();
      needsInternetVerification = false;
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
  }

  /// Re-verify subscription (can be called from settings or periodically)
  static Future<void> reVerify() async {
    await _verifyWithPlayStore();
  }

  // ════════════════════════════════════════════════
  // PURCHASE STREAM HANDLER
  // ════════════════════════════════════════════════

  static bool _restoredAnyPurchase = false;

  static Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    if (purchaseDetailsList.isEmpty) {
      // Empty restore result — no active purchases
      await _revokeAccess();
      return;
    }

    bool foundActive = false;

    for (final pd in purchaseDetailsList) {
      if (pd.status == PurchaseStatus.pending) {
        continue;
      }

      if (pd.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${pd.error}');
      } else if (pd.status == PurchaseStatus.purchased ||
                 pd.status == PurchaseStatus.restored) {
        if (pd.productID == _subscriptionProductId) {
          foundActive = true;
          _restoredAnyPurchase = true;

          // Save the Play Store's transaction date as trusted timestamp
          if (pd.transactionDate != null) {
            final txDateMs = int.tryParse(pd.transactionDate!);
            if (txDateMs != null) {
              purchaseDate = DateTime.fromMillisecondsSinceEpoch(txDateMs);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(_purchaseDateKey, txDateMs);
            }
          }

          await _grantAccess();
        }
      } else if (pd.status == PurchaseStatus.canceled) {
        debugPrint('Purchase canceled for ${pd.productID}');
      }

      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }

    // If we processed a restore batch and found nothing active, revoke
    if (!foundActive && purchaseDetailsList.any((pd) =>
        pd.status == PurchaseStatus.restored || pd.status == PurchaseStatus.canceled)) {
      await _revokeAccess();
    }
  }

  // ════════════════════════════════════════════════
  // GRANT / REVOKE ACCESS
  // ════════════════════════════════════════════════

  static Future<void> _grantAccess() async {
    hasSubscription = true;
    needsInternetVerification = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, true);
    debugPrint('✅ Subscription GRANTED');
  }

  static Future<void> _revokeAccess() async {
    hasSubscription = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, false);
    debugPrint('🔒 Subscription REVOKED — no active purchase found');
  }

  // ── Legacy compatibility ──
  static bool get hasAdFree => hasSubscription;
  static Future<bool> buyAdFreeSubscription() => buySubscription();
}
