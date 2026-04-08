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
  static const String _graceCountKey = 'grace_period_count';
  static const String _graceYearKey = 'grace_period_year';
  static const String _graceStartKey = 'grace_start_timestamp';
  static const String _graceActiveKey = 'grace_active';

  // ── Constants ──
  static const int _trialDays = 3;
  static const int _offlineGraceDays = 2;
  static const int _maxGracePeriodsPerYear = 10;
  static const int _subscriptionDurationDays = 365;

  static InAppPurchase get _iap => InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // ── State ──
  static bool hasSubscription = false;
  static DateTime? trialStartDate;
  static DateTime? lastVerifiedDate;
  static DateTime? purchaseDate;

  // ── Grace period state ──
  static bool isGracePeriodActive = false;
  static DateTime? graceStartDate;
  static int gracePeriodsUsedThisYear = 0;
  static int _graceYear = 0;

  /// Whether the app must show the "connect to internet" screen
  static bool needsInternetVerification = false;

  // ════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR UI
  // ════════════════════════════════════════════════

  /// True if the user has access (subscribed + verified recently, OR trial active)
  static bool get hasAccess {
    if (kIsWeb) return true;
    if (needsInternetVerification) return false;
    return hasSubscription || isTrialActive;
  }

  /// True if the free trial is still active
  static bool get isTrialActive {
    if (trialStartDate == null) return false;
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

  /// Days remaining in subscription (0 if expired or not subscribed)
  static int get subscriptionDaysRemaining {
    if (!hasSubscription || purchaseDate == null) return 0;
    final expiryDate = purchaseDate!.add(const Duration(days: _subscriptionDurationDays));
    final remaining = expiryDate.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Hours remaining in current grace period (0 if not active)
  static int get gracePeriodRemainingHours {
    if (!isGracePeriodActive || graceStartDate == null) return 0;
    final elapsed = DateTime.now().difference(graceStartDate!);
    final remainingHours = (_offlineGraceDays * 24) - elapsed.inHours;
    return remainingHours > 0 ? remainingHours : 0;
  }

  /// Grace periods remaining this year
  static int get gracePeriodsRemainingThisYear {
    final remaining = _maxGracePeriodsPerYear - gracePeriodsUsedThisYear;
    return remaining > 0 ? remaining : 0;
  }

  /// Subscription status text for UI display
  static String get statusText {
    if (!hasSubscription && !isTrialActive) {
      return 'ಚಂದಾದಾರಿಕೆ ಇಲ್ಲ (No subscription)';
    }
    if (isTrialActive) {
      return 'ಟ್ರಯಲ್ ಸಕ್ರಿಯ - $trialDaysRemaining ದಿನ ಬಾಕಿ';
    }
    if (hasSubscription) {
      final days = subscriptionDaysRemaining;
      if (days > 0) {
        return 'ಪ್ರೀಮಿಯಂ ಸಕ್ರಿಯ - $days ದಿನ ಬಾಕಿ';
      } else {
        return 'ಚಂದಾದಾರಿಕೆ ಮುಗಿದಿದೆ';
      }
    }
    return '';
  }

  /// Grace period status text for UI display
  static String get graceStatusText {
    if (isGracePeriodActive) {
      final hrs = gracePeriodRemainingHours;
      return 'ಗ್ರೇಸ್ ಸಕ್ರಿಯ - ${hrs}h ಬಾಕಿ ($gracePeriodsUsedThisYear/$_maxGracePeriodsPerYear ಬಳಸಲಾಗಿದೆ)';
    }
    return 'ಗ್ರೇಸ್ ನಿಷ್ಕ್ರಿಯ ($gracePeriodsUsedThisYear/$_maxGracePeriodsPerYear ಬಳಸಲಾಗಿದೆ)';
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

    // Load grace period state
    _graceYear = prefs.getInt(_graceYearKey) ?? DateTime.now().year;
    gracePeriodsUsedThisYear = prefs.getInt(_graceCountKey) ?? 0;
    isGracePeriodActive = prefs.getBool(_graceActiveKey) ?? false;
    final graceStartTs = prefs.getInt(_graceStartKey);
    if (graceStartTs != null) {
      graceStartDate = DateTime.fromMillisecondsSinceEpoch(graceStartTs);
    }

    // Reset grace count if new year
    if (_graceYear != DateTime.now().year) {
      _graceYear = DateTime.now().year;
      gracePeriodsUsedThisYear = 0;
      await prefs.setInt(_graceYearKey, _graceYear);
      await prefs.setInt(_graceCountKey, 0);
    }

    // Check if existing grace period has expired
    if (isGracePeriodActive && graceStartDate != null) {
      final elapsed = DateTime.now().difference(graceStartDate!);
      if (elapsed.inDays >= _offlineGraceDays) {
        // Grace period expired
        isGracePeriodActive = false;
        await prefs.setBool(_graceActiveKey, false);
        debugPrint('⏰ Grace period expired on startup');
      }
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
  // PLAY STORE VERIFICATION
  // ════════════════════════════════════════════════

  /// Checks subscription status with Google Play.
  /// Strategy: ASSUME REVOKED, then GRANT only if Play Store confirms active purchase.
  static Future<void> _verifyWithPlayStore() async {
    bool storeReachable = false;
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('🔌 Play Store not available — activating grace period');
        await _activateGracePeriod();
        return;
      }
      storeReachable = true;

      // Reset: assume no active purchase until stream confirms one
      _foundActiveDuringRestore = false;

      // This triggers the purchase stream with current purchase state
      await _iap.restorePurchases();

      // Wait for the stream to process any restored purchases.
      // If subscription expired, the stream may not fire at all.
      await Future.delayed(const Duration(milliseconds: 2500));

      // Record that we successfully talked to Play Store
      await _updateLastVerified();
      needsInternetVerification = false;

      // Deactivate grace period since we successfully verified
      await _deactivateGracePeriod();

      // KEY FIX: If we had a subscription but Play Store didn't confirm it,
      // it means the subscription has expired → REVOKE
      if (!_foundActiveDuringRestore && hasSubscription) {
        debugPrint('⚠️ Play Store did NOT confirm active subscription → REVOKING');
        await _revokeAccess();
      }
    } catch (e) {
      debugPrint('Play Store verification error: $e');

      if (storeReachable) {
        // Store WAS reachable but restorePurchases() threw an error
        // (e.g. rate-limited, Play Store glitch).
        // Activate grace period — don't revoke on rate limit.
        debugPrint('⚠️ Store reachable but restore threw — activating grace period');
        await _activateGracePeriod();
      } else {
        // Store truly not reachable — genuine offline scenario
        await _activateGracePeriod();
      }
    }
  }

  // ════════════════════════════════════════════════
  // GRACE PERIOD MANAGEMENT
  // ════════════════════════════════════════════════

  /// Activate a grace period (offline or rate-limited)
  static Future<void> _activateGracePeriod() async {
    if (!hasSubscription) {
      // Not subscribed, nothing to grace-period
      needsInternetVerification = false;
      return;
    }

    // If already in an active grace period, check if it's still valid
    if (isGracePeriodActive && graceStartDate != null) {
      final elapsed = DateTime.now().difference(graceStartDate!);
      if (elapsed.inDays < _offlineGraceDays) {
        // Still within active grace period — allow access, don't count again
        needsInternetVerification = false;
        debugPrint('📟 Still within grace period (${elapsed.inHours}h elapsed). Access allowed.');
        return;
      } else {
        // This grace period expired — fall through to start a new one (if allowed)
        isGracePeriodActive = false;
      }
    }

    // Reset year counter if needed
    final currentYear = DateTime.now().year;
    if (_graceYear != currentYear) {
      _graceYear = currentYear;
      gracePeriodsUsedThisYear = 0;
    }

    // Check if grace periods are exhausted for this year
    if (gracePeriodsUsedThisYear >= _maxGracePeriodsPerYear) {
      // No more grace periods — LOCK until internet
      needsInternetVerification = true;
      isGracePeriodActive = false;
      debugPrint('🚫 All $gracePeriodsUsedThisYear grace periods used this year. LOCKED.');
      await _saveGraceState();
      return;
    }

    // Activate a NEW grace period
    isGracePeriodActive = true;
    graceStartDate = DateTime.now();
    gracePeriodsUsedThisYear++;
    needsInternetVerification = false;
    debugPrint('🛡️ Grace period #$gracePeriodsUsedThisYear activated (${_offlineGraceDays} days). Access allowed.');

    await _saveGraceState();
  }

  /// Deactivate grace period (after successful verification)
  static Future<void> _deactivateGracePeriod() async {
    if (isGracePeriodActive) {
      isGracePeriodActive = false;
      graceStartDate = null;
      debugPrint('✅ Grace period deactivated — verified online.');
      await _saveGraceState();
    }
  }

  /// Save grace period state to SharedPreferences
  static Future<void> _saveGraceState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_graceActiveKey, isGracePeriodActive);
    await prefs.setInt(_graceCountKey, gracePeriodsUsedThisYear);
    await prefs.setInt(_graceYearKey, _graceYear);
    if (graceStartDate != null) {
      await prefs.setInt(_graceStartKey, graceStartDate!.millisecondsSinceEpoch);
    }
  }

  /// Record the timestamp of successful Play Store communication
  static Future<void> _updateLastVerified() async {
    lastVerifiedDate = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastVerifiedKey, lastVerifiedDate!.millisecondsSinceEpoch);
  }

  // ════════════════════════════════════════════════
  // CONNECTIVITY RE-CHECK (call from app lifecycle)
  // ════════════════════════════════════════════════

  /// Call this when the app detects internet connectivity during a grace period.
  /// Also call on app resume to re-check.
  static Future<void> checkOnReconnect() async {
    if (kIsWeb) return;

    // Only re-verify if we are in grace period or need verification
    if (isGracePeriodActive || needsInternetVerification) {
      debugPrint('🔄 Internet detected during grace/lock — re-verifying with Play Store');
      await _verifyWithPlayStore();
    }
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
      _foundActiveDuringRestore = false;
      await _iap.restorePurchases();
      await Future.delayed(const Duration(milliseconds: 2500));
      await _updateLastVerified();
      needsInternetVerification = false;

      // Deactivate grace if we successfully verified
      await _deactivateGracePeriod();

      // If no active purchase was found during restore, revoke
      if (!_foundActiveDuringRestore && hasSubscription) {
        await _revokeAccess();
      }
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

  static bool _foundActiveDuringRestore = false;

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
          _foundActiveDuringRestore = true;

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
    isGracePeriodActive = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subStatusKey, false);
    await prefs.setBool(_graceActiveKey, false);
    debugPrint('🔒 Subscription REVOKED — no active purchase found');
  }

  // ── Legacy compatibility ──
  static bool get hasAdFree => hasSubscription;
  static Future<bool> buyAdFreeSubscription() => buySubscription();
}
