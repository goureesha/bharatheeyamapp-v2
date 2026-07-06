import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trusted_time_service.dart';
import 'google_auth_service.dart';
import 'offline_access_service.dart';
import '../widgets/common.dart';

class SubscriptionService {
  // ── Pref keys ──
  static const String _subStatusKey = 'has_active_subscription';
  static const String _trialStartKey = 'trial_start_timestamp';
  static const String _lastOnlineCheckKey = 'last_online_check_timestamp';
  static const String _blockedKey = 'user_blocked';
  static const String _blockedReasonKey = 'user_blocked_reason';

  // ── Constants ──
  static const int _trialMinutes = 30;
  static const int _maxOfflineHours = 24;       // Must connect every 24h
  static const int _offlineGraceDays = 10;      // Max offline grace: 10 days

  // ── State ──
  static bool hasSubscription = false;
  static bool manualPremium = false;
  static DateTime? manualPremiumExpiry;
  static DateTime? trialStartDate;
  static DateTime? lastOnlineCheck;
  static bool isBlocked = false;
  static String blockedReason = '';

  // ════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR UI
  // ════════════════════════════════════════════════

  /// True if the user has access (manual premium OR trial active OR active offline claim)
  static bool get hasAccess {
    if (isBlocked) return false;
    if (kIsWeb) return true;
    if (OfflineAccessService.hasActiveClaim) return true;
    if (manualPremium) {
      if (manualPremiumExpiry != null &&
          manualPremiumExpiry!.isBefore(TrustedTimeService.now())) {
        manualPremium = false;
        hasSubscription = false;
        return false;
      }
      return true;
    }
    return hasSubscription || isTrialActive;
  }

  /// True if the user hasn't connected to the internet within the allowed window.
  /// - Trial users: NO grace period — must always have internet.
  /// - Premium users: 10-day offline grace, but must connect every 24 hours.
  static bool get needsInternetVerification {
    if (kIsWeb) return false;
    if (lastOnlineCheck == null) return true; // Never verified

    final now = TrustedTimeService.now();
    final hoursSinceCheck = now.difference(lastOnlineCheck!).inHours;

    // Trial users get NO offline grace — must always have internet
    if (!manualPremium && !hasSubscription) {
      if (hoursSinceCheck >= 1) {
        debugPrint('🔒 Trial user offline > 1 hour. No grace period. Must connect.');
        return true;
      }
      return false;
    }

    // Premium users: 10-day hard grace limit
    final daysSinceCheck = now.difference(lastOnlineCheck!).inDays;
    if (daysSinceCheck >= _offlineGraceDays) {
      debugPrint('🔒 Offline grace period expired ($daysSinceCheck days). Must connect.');
      return true;
    }

    // Premium users: must connect at least once every 24 hours
    if (hoursSinceCheck >= _maxOfflineHours) {
      debugPrint('🔒 Offline > $_maxOfflineHours hours ($hoursSinceCheck h). Must connect.');
      return true;
    }

    return false;
  }

  /// Record a successful online verification
  static Future<void> recordOnlineCheck() async {
    lastOnlineCheck = TrustedTimeService.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastOnlineCheckKey, lastOnlineCheck!.millisecondsSinceEpoch);
    debugPrint('🌐 Online check recorded: $lastOnlineCheck');
  }

  /// True if the free trial is still active (30 minutes)
  static bool get isTrialActive {
    if (trialStartDate == null) return false;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(trialStartDate!);
    return elapsed.inMinutes < _trialMinutes;
  }

  /// Minutes remaining in trial (0 if expired)
  static int get trialMinutesRemaining {
    if (trialStartDate == null) return 0;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(trialStartDate!);
    final remaining = _trialMinutes - elapsed.inMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// App status text for UI display
  static String get statusText {
    if (manualPremium && manualPremiumExpiry != null) {
      final days = manualPremiumExpiry!.difference(TrustedTimeService.now()).inDays;
      return 'Beta Access ✅ ($days ${AppLocale.l('daysRemaining')})';
    }
    if (hasSubscription) {
      return '${AppLocale.l('premiumActive')}';
    }
    if (isTrialActive) {
      final m = trialMinutesRemaining;
      return '${AppLocale.l('trialActive').replaceAll('{h}', '$m')} ($m min left)';
    }
    return '${AppLocale.l('trialExpired')}';
  }

  // ════════════════════════════════════════════════
  // INITIALIZATION — runs on EVERY app open
  // ════════════════════════════════════════════════

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load trial start (for trial-only logic)
    final trialTs = prefs.getInt(_trialStartKey);
    if (trialTs != null) {
      trialStartDate = DateTime.fromMillisecondsSinceEpoch(trialTs);
    } else {
      // First install — start trial
      trialStartDate = TrustedTimeService.now();
      await prefs.setInt(_trialStartKey, trialStartDate!.millisecondsSinceEpoch);
    }

    // Load last online check timestamp
    final lastCheckTs = prefs.getInt(_lastOnlineCheckKey);
    if (lastCheckTs != null) {
      lastOnlineCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTs);
    }

    if (kIsWeb) return;

    // Load cached blocked status (fail-open default: not blocked)
    isBlocked = prefs.getBool(_blockedKey) ?? false;
    blockedReason = prefs.getString(_blockedReasonKey) ?? '';

    // ── CRITICAL: Check Firestore on EVERY app open ──
    // Do NOT load cached subscription status first — always check server.
    // This ensures admin revocations take effect immediately on next app open.
    // If Firestore check succeeds → use server value (authoritative).
    // If Firestore check fails → fall back to cached value (10-day offline grace).
    final firestoreChecked = await checkManualPremium();
    if (!firestoreChecked) {
      // Firestore unreachable — use cached value as offline fallback.
      // The 10-day grace period is enforced by needsInternetVerification.
      // After 10 days without successful Firestore check, app locks.
      hasSubscription = prefs.getBool(_subStatusKey) ?? false;
      manualPremium = hasSubscription;
      debugPrint('⚠️ Firestore unreachable — using cached subscription: $hasSubscription');
      debugPrint('⚠️ Last online check: $lastOnlineCheck');
      if (lastOnlineCheck != null) {
        final daysSince = TrustedTimeService.now().difference(lastOnlineCheck!).inDays;
        final hoursSince = TrustedTimeService.now().difference(lastOnlineCheck!).inHours;
        debugPrint('⚠️ Offline for $daysSince days ($hoursSince hours). Grace: $_offlineGraceDays days.');
      }
    }
  }

  static void dispose() {}

  // ════════════════════════════════════════════════
  // FIRESTORE TRIAL SYNC (prevents trial reset on reinstall)
  // ════════════════════════════════════════════════

  /// Call AFTER sign-in + device binding. Syncs trial start with Firestore
  /// so uninstall/reinstall with same Gmail does NOT reset the trial.
  static Future<void> syncTrialWithFirestore() async {
    if (kIsWeb) return;
    final email = GoogleAuthService.userEmail;
    if (email == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('device_bindings')
          .doc(email.toLowerCase());

      final doc = await docRef.get().timeout(const Duration(seconds: 8));
      if (!doc.exists || doc.data() == null) return;

      final data = doc.data()!;
      final firestoreTrialTs = data['trialStartedAt'];

      if (firestoreTrialTs != null && firestoreTrialTs is Timestamp) {
        // Firestore has a trial start → restore it (prevents trial reset)
        final firestoreTrialDate = firestoreTrialTs.toDate();
        final prefs = await SharedPreferences.getInstance();
        final localTs = prefs.getInt(_trialStartKey);

        if (localTs == null || firestoreTrialDate.isBefore(DateTime.fromMillisecondsSinceEpoch(localTs))) {
          // Firestore date is earlier (original) → use it
          trialStartDate = firestoreTrialDate;
          await prefs.setInt(_trialStartKey, firestoreTrialDate.millisecondsSinceEpoch);
          debugPrint('🔄 Trial restored from Firestore: $firestoreTrialDate (no free trial on reinstall)');
        }
      } else {
        // No trial in Firestore yet → write current trial start
        if (trialStartDate != null) {
          await docRef.update({
            'trialStartedAt': Timestamp.fromDate(trialStartDate!),
          }).catchError((_) {});
          debugPrint('📝 Trial start written to Firestore: $trialStartDate');
        }
      }
    } catch (e) {
      debugPrint('Trial Firestore sync error: $e');
    }
  }

  // ════════════════════════════════════════════════
  // MANUAL PREMIUM (admin-set via Firestore)
  // ════════════════════════════════════════════════

  /// Check if the admin has manually granted premium for this user.
  /// Reads `manualPremium` flag from Firestore `device_bindings/{email}`.
  /// Returns true if Firestore was successfully reached, false on error.
  static Future<bool> checkManualPremium() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('device_bindings')
          .doc(email.toLowerCase())
          .get()
          .timeout(const Duration(seconds: 8));

      if (!doc.exists || doc.data() == null) {
        // Successfully reached Firestore — record online check
        // No document = no premium
        await recordOnlineCheck();
        manualPremium = false;
        hasSubscription = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_subStatusKey, false);
        return true;
      }

      // Successfully reached Firestore — record online check
      await recordOnlineCheck();

      final data = doc.data()!;

      // ── Block check (same document, no extra network call) ──
      final blockedFlag = data['blocked'] == true;
      final reason = data['blockedReason'] as String? ?? '';
      isBlocked = blockedFlag;
      blockedReason = reason;
      final prefs2 = await SharedPreferences.getInstance();
      await prefs2.setBool(_blockedKey, blockedFlag);
      await prefs2.setString(_blockedReasonKey, reason);
      if (blockedFlag) {
        debugPrint('🚫 User BLOCKED: $reason');
      }

      final isPremium = data['manualPremium'] == true;

      if (isPremium) {
        // manualPremiumExpiry is REQUIRED — no lifetime access
        final expiryTs = data['manualPremiumExpiry'];
        if (expiryTs != null && expiryTs is Timestamp) {
          final expiryDate = expiryTs.toDate();
          if (expiryDate.isBefore(TrustedTimeService.now())) {
            // Expired — update local state
            manualPremium = false;
            manualPremiumExpiry = null;
            hasSubscription = false;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_subStatusKey, false);
            debugPrint('🔒 Manual premium EXPIRED on $expiryDate');

            // Write back to Firestore so admin dashboard reflects it
            try {
              await FirebaseFirestore.instance
                  .collection('device_bindings')
                  .doc(email!.toLowerCase())
                  .update({'manualPremium': false});
              debugPrint('🔄 Firestore updated: manualPremium → false');
            } catch (_) {}
            return true;
          }
          manualPremiumExpiry = expiryDate;
          manualPremium = true;
          hasSubscription = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_subStatusKey, true);
          debugPrint('✅ Manual premium ACTIVE for $email (expires: $expiryDate)');
        } else {
          // manualPremium=true but NO expiry set → deny access
          manualPremium = false;
          manualPremiumExpiry = null;
          hasSubscription = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_subStatusKey, false);
          debugPrint('🔒 manualPremium=true but NO expiry set — access denied');
        }
      } else {
        manualPremium = false;
        manualPremiumExpiry = null;
        hasSubscription = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_subStatusKey, false);
        debugPrint('🔒 Manual premium REVOKED/OFF for $email');
      }
      return true;
    } catch (e) {
      debugPrint('Manual premium check error: $e');
      // Firestore unreachable — return false so caller knows to use cache
      return false;
    }
  }

  // ── Legacy compatibility ──
  static bool get hasAdFree => hasSubscription;
}
