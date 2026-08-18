import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trusted_time_service.dart';
import 'google_auth_service.dart';
import 'offline_access_service.dart';
import '../widgets/common.dart';

class AppAccessService {
  // ── Pref keys ──
  static const String _accessStatusKey = 'has_active_access';
  static const String _trialStartKey = 'trial_start_timestamp';
  static const String _lastOnlineCheckKey = 'last_online_check_timestamp';
  static const String _blockedKey = 'user_blocked';
  static const String _blockedReasonKey = 'user_blocked_reason';
  static const String _muhurtaUnlockedKey = 'muhurta_unlocked';
  static const String _isStudentKey = 'is_student';

  // ── Constants ──
  static const int _trialMinutes = 30;
  static const int _maxOfflineHours = 24;       // Must connect every 24h
  static int _offlineGraceDays = 10;      // Max offline grace: 10 days

  // ── State ──
  static bool isActivated = false;
  static bool adminAccess = false;
  static DateTime? adminAccessExpiry;
  static DateTime? trialStartDate;
  static DateTime? lastOnlineCheck;
  static bool isBlocked = false;
  static String blockedReason = '';
  static bool muhurtaUnlocked = false;
  static bool isStudent = false;

  // ════════════════════════════════════════════════
  // COMPUTED PROPERTIES FOR UI
  // ════════════════════════════════════════════════

  /// True if the user has access (admin access OR trial active OR active offline claim)
  static bool get hasAccess {
    if (isBlocked) return false;
    if (kIsWeb) return true;
    if (OfflineAccessService.hasActiveClaim) return true;
    if (adminAccess) {
      if (adminAccessExpiry != null &&
          adminAccessExpiry!.isBefore(TrustedTimeService.now())) {
        adminAccess = false;
        isActivated = false;
        return false;
      }
      return true;
    }
    return isActivated || isTrialActive;
  }

  /// True if the user hasn't connected to the internet within the allowed window.
  /// - Trial users: NO grace period — must always have internet.
  /// - Activated users: 10-day offline grace, but must connect every 24 hours.
  static bool get needsInternetVerification {
    if (kIsWeb) return false;
    if (lastOnlineCheck == null) return true; // Never verified

    final now = TrustedTimeService.now();
    final hoursSinceCheck = now.difference(lastOnlineCheck!).inHours;

    // Trial users get NO offline grace — must always have internet
    if (!adminAccess && !isActivated) {
      if (hoursSinceCheck >= 1) {
        debugPrint('🔒 Trial user offline > 1 hour. No grace period. Must connect.');
        return true;
      }
      return false;
    }

    // Activated users: 10-day hard grace limit
    final daysSinceCheck = now.difference(lastOnlineCheck!).inDays;
    if (daysSinceCheck >= _offlineGraceDays) {
      debugPrint('🔒 Offline grace period expired ($daysSinceCheck days). Must connect.');
      return true;
    }

    // Activated users: must connect at least once every 24 hours
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
    if (adminAccess && adminAccessExpiry != null) {
      final days = adminAccessExpiry!.difference(TrustedTimeService.now()).inDays;
      return 'Beta Access ✅ ($days ${AppLocale.l('daysRemaining')})';
    }
    if (isActivated) {
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
    // Do NOT load cached access status first — always check server.
    // This ensures admin revocations take effect immediately on next app open.
    // If Firestore check succeeds → use server value (authoritative).
    // If Firestore check fails → fall back to cached value (10-day offline grace).
    final firestoreChecked = await checkAdminAccess();
    if (!firestoreChecked) {
      // Firestore unreachable — use cached value as offline fallback.
      // The 10-day grace period is enforced by needsInternetVerification.
      // After 10 days without successful Firestore check, app locks.
      // Migration: also check old pref key for users updating from older versions
      isActivated = prefs.getBool(_accessStatusKey) ??
                    prefs.getBool('has_active_subscription') ?? false;
      adminAccess = isActivated;
      muhurtaUnlocked = prefs.getBool(_muhurtaUnlockedKey) ?? false;
      isStudent = prefs.getBool(_isStudentKey) ?? false;
      debugPrint('⚠️ Firestore unreachable — using cached access: $isActivated');
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

  /// Load max_offline_days from Firestore app_config/settings.
  /// Falls back to default 10 if not set or on error.
  static Future<void> loadOfflineGraceDays() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('settings')
          .get()
          .timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        final days = doc.data()!['max_offline_days'];
        if (days != null && days is int && days > 0) {
          _offlineGraceDays = days;
          debugPrint('AppConfig: max_offline_days = $_offlineGraceDays');
        }
      }
    } catch (e) {
      debugPrint('AppConfig: Failed to load offline grace days: $e');
    }
  }

  // ════════════════════════════════════════════════
  // ADMIN ACCESS (admin-set via Firestore)
  // ════════════════════════════════════════════════

  /// Check if the admin has granted access for this user.
  /// Reads `manualPremium` flag from Firestore `device_bindings/{email}`.
  /// Returns true if Firestore was successfully reached, false on error.
  static Future<bool> checkAdminAccess() async {
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
        // No document = no access
        await recordOnlineCheck();
        adminAccess = false;
        isActivated = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_accessStatusKey, false);
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

      // Firestore field names kept as-is for data compatibility
      final hasAdminGrant = data['manualPremium'] == true;

      // ── Muhurta unlock (separate premium feature) ──
      final muhurtaFlag = data['muhurtaUnlocked'] == true;
      muhurtaUnlocked = muhurtaFlag;
      final prefs3 = await SharedPreferences.getInstance();
      await prefs3.setBool(_muhurtaUnlockedKey, muhurtaFlag);
      debugPrint('🔮 Muhurta access: ${muhurtaFlag ? 'UNLOCKED' : 'LOCKED'}');

      // ── Student mode (locks taranukoola + vastu) ──
      final studentFlag = data['isStudent'] == true;
      isStudent = studentFlag;
      await prefs3.setBool(_isStudentKey, studentFlag);
      debugPrint('🎓 Student mode: ${studentFlag ? 'ON' : 'OFF'}');

      if (hasAdminGrant) {
        // Expiry is REQUIRED — no lifetime access
        final expiryTs = data['manualPremiumExpiry'];
        if (expiryTs != null && expiryTs is Timestamp) {
          final expiryDate = expiryTs.toDate();
          if (expiryDate.isBefore(TrustedTimeService.now())) {
            // Expired — update local state
            adminAccess = false;
            adminAccessExpiry = null;
            isActivated = false;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_accessStatusKey, false);
            debugPrint('🔒 Admin access EXPIRED on $expiryDate');

            // Write back to Firestore so admin dashboard reflects it
            try {
              await FirebaseFirestore.instance
                  .collection('device_bindings')
                  .doc(email!.toLowerCase())
                  .update({'manualPremium': false});
              debugPrint('🔄 Firestore updated: access revoked');
            } catch (_) {}
            return true;
          }
          adminAccessExpiry = expiryDate;
          adminAccess = true;
          isActivated = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_accessStatusKey, true);
          debugPrint('✅ Admin access ACTIVE for $email (expires: $expiryDate)');
        } else {
          // Flag set but NO expiry → deny access
          adminAccess = false;
          adminAccessExpiry = null;
          isActivated = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_accessStatusKey, false);
          debugPrint('🔒 Admin flag set but NO expiry — access denied');
        }
      } else {
        adminAccess = false;
        adminAccessExpiry = null;
        isActivated = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_accessStatusKey, false);
        debugPrint('🔒 Admin access REVOKED/OFF for $email');
      }
      return true;
    } catch (e) {
      debugPrint('Admin access check error: $e');
      // Firestore unreachable — return false so caller knows to use cache
      return false;
    }
  }

  // ── Legacy compatibility ──
  static bool get hasFullAccess => isActivated;
}
