import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trusted_time_service.dart';
import 'google_auth_service.dart';
import 'subscription_service.dart';

/// Manages the offline access feature.
///
/// Rules:
/// - Users get N offline days TOTAL (lifetime, not consecutive).
/// - N is configured on the server (app_config/settings → max_offline_days).
/// - Each claim grants 24 hours of offline access.
/// - After 24 hours, the app locks until internet is restored.
/// - After all days are used, user must contact support.
/// - Usage is synced to Firestore using FieldValue.increment (no overwrites).
class OfflineAccessService {
  // ── Pref keys ──
  static const String _totalUsedKey = 'offline_days_used';
  static const String _claimStartKey = 'offline_claim_start';
  static const String _syncedToServerKey = 'offline_days_synced_count';
  static const String _maxDaysKey = 'offline_max_days';

  // ── Constants ──
  static const int _defaultMaxDays = 10; // fallback if server hasn't been read yet
  static const int claimDurationHours = 24;

  // ── State ──
  static int _totalDaysUsed = 0;
  static DateTime? _currentClaimStart;
  static int _syncedToServer = 0;
  static int _maxOfflineDays = _defaultMaxDays;

  // ── Computed ──

  /// Max offline days (server-configurable, cached locally)
  static int get maxOfflineDays => _maxOfflineDays;

  /// How many offline days have been used
  static int get daysUsed => _totalDaysUsed;

  /// How many offline days remain
  static int get daysRemaining => (_maxOfflineDays - _totalDaysUsed).clamp(0, _maxOfflineDays);

  /// Whether the user has any offline days left
  static bool get hasOfflineDaysLeft => daysRemaining > 0;

  /// Whether there's an active offline claim right now
  static bool get hasActiveClaim {
    if (_currentClaimStart == null) return false;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(_currentClaimStart!);
    return elapsed.inHours < claimDurationHours;
  }

  /// Hours remaining in current offline claim
  static int get claimHoursRemaining {
    if (_currentClaimStart == null) return 0;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(_currentClaimStart!);
    final remaining = claimDurationHours - elapsed.inHours;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether the current claim has expired (24h passed)
  static bool get isClaimExpired {
    if (_currentClaimStart == null) return false;
    final now = TrustedTimeService.now();
    final elapsed = now.difference(_currentClaimStart!);
    return elapsed.inHours >= claimDurationHours;
  }

  // ── Initialize ──

  /// Load offline access state from local storage
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _totalDaysUsed = prefs.getInt(_totalUsedKey) ?? 0;
    _syncedToServer = prefs.getInt(_syncedToServerKey) ?? 0;
    _maxOfflineDays = prefs.getInt(_maxDaysKey) ?? _defaultMaxDays;

    final claimTs = prefs.getInt(_claimStartKey);
    if (claimTs != null) {
      _currentClaimStart = DateTime.fromMillisecondsSinceEpoch(claimTs);
    }

    debugPrint('OfflineAccess: $daysRemaining/$_maxOfflineDays days remaining, claim active: $hasActiveClaim');
  }

  // ── Fetch max days from server ──

  /// Read max_offline_days from Firestore.
  /// Priority: user's device_bindings/{email} → global app_config/settings → default 10.
  /// Admin sets the field per-user in Firebase Console for specific users.
  static Future<void> fetchMaxDaysFromServer() async {
    try {
      // 1. Check per-user override first
      final email = GoogleAuthService.userEmail;
      if (email != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('device_bindings')
            .doc(email.toLowerCase())
            .get()
            .timeout(const Duration(seconds: 5));

        if (userDoc.exists && userDoc.data() != null) {
          final userMax = userDoc.data()!['max_offline_days'];
          if (userMax != null && userMax is int && userMax > 0) {
            _maxOfflineDays = userMax;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_maxDaysKey, _maxOfflineDays);
            debugPrint('OfflineAccess: Per-user max_offline_days = $_maxOfflineDays');
            return; // per-user value found, no need to check global
          }
        }
      }

      // 2. Fall back to global config
      final globalDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('settings')
          .get()
          .timeout(const Duration(seconds: 5));

      if (globalDoc.exists && globalDoc.data() != null) {
        final globalMax = globalDoc.data()!['max_offline_days'];
        if (globalMax != null && globalMax is int && globalMax > 0) {
          _maxOfflineDays = globalMax;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_maxDaysKey, _maxOfflineDays);
          debugPrint('OfflineAccess: Global max_offline_days = $_maxOfflineDays');
        }
      }
    } catch (e) {
      // Silently fail — use cached value
      debugPrint('OfflineAccess: Failed to fetch max days from server: $e');
    }
  }

  // ── Claim an offline day ──

  /// Claim one offline day (24 hours). Returns true if successful.
  static Future<bool> claimOfflineDay() async {
    // Only paid users can claim offline days
    if (!SubscriptionService.manualPremium && !SubscriptionService.hasSubscription) {
      debugPrint('OfflineAccess: Free/trial user — offline days not available');
      return false;
    }

    if (!hasOfflineDaysLeft) {
      debugPrint('OfflineAccess: No days remaining!');
      return false;
    }

    // If there's already an active claim, don't consume another day
    if (hasActiveClaim) {
      debugPrint('OfflineAccess: Already have active claim ($claimHoursRemaining hours left)');
      return true;
    }

    // Consume one day
    _totalDaysUsed++;
    _currentClaimStart = TrustedTimeService.now();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalUsedKey, _totalDaysUsed);
    await prefs.setInt(_claimStartKey, _currentClaimStart!.millisecondsSinceEpoch);

    debugPrint('OfflineAccess: Claimed day $_totalDaysUsed/$_maxOfflineDays');
    return true;
  }

  /// Clear the expired claim (called when user reconnects)
  static Future<void> clearExpiredClaim() async {
    if (_currentClaimStart != null && isClaimExpired) {
      _currentClaimStart = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claimStartKey);
      debugPrint('OfflineAccess: Expired claim cleared');
    }
  }

  /// Force-clear an active claim (called when server explicitly revokes access).
  /// Unlike clearExpiredClaim, this clears even if the claim hasn't expired yet.
  static Future<void> clearActiveClaim() async {
    _currentClaimStart = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claimStartKey);
    debugPrint('OfflineAccess: Active claim force-cleared (server revocation)');
  }

  // ── Server sync (incremental, no overwrites) ──

  /// Sync offline usage to Firestore using FieldValue.increment.
  /// Only syncs the DELTA (new days used since last sync) to avoid overwrites.
  /// Call this when the user comes back online.
  static Future<void> syncToServer() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return;

    // Also fetch latest max days while we're online
    await fetchMaxDaysFromServer();

    final delta = _totalDaysUsed - _syncedToServer;
    if (delta <= 0) {
      debugPrint('OfflineAccess: Nothing to sync (synced=$_syncedToServer, used=$_totalDaysUsed)');
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('device_bindings')
          .doc(email.toLowerCase());

      // Use FieldValue.increment to avoid overwriting other devices/sessions
      await docRef.set({
        'offlineDaysUsed': FieldValue.increment(delta),
        'lastOfflineSync': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update local synced count
      _syncedToServer = _totalDaysUsed;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_syncedToServerKey, _syncedToServer);

      debugPrint('OfflineAccess: Synced $delta days to server (total: $_totalDaysUsed)');
    } catch (e) {
      debugPrint('OfflineAccess: Server sync failed: $e');
    }
  }

  /// Restore offline day count from server (on fresh install / sign-in).
  /// Ensures reinstall doesn't reset offline days.
  static Future<void> restoreFromServer() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return;

    // Fetch max days config while we're at it
    await fetchMaxDaysFromServer();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('device_bindings')
          .doc(email.toLowerCase())
          .get()
          .timeout(const Duration(seconds: 8));

      if (doc.exists && doc.data() != null) {
        final serverDays = doc.data()!['offlineDaysUsed'] as int? ?? 0;
        if (serverDays > _totalDaysUsed) {
          // Server has higher count (e.g. used on another device or reinstall)
          _totalDaysUsed = serverDays;
          _syncedToServer = serverDays;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_totalUsedKey, _totalDaysUsed);
          await prefs.setInt(_syncedToServerKey, _syncedToServer);
          debugPrint('OfflineAccess: Restored from server: $serverDays days used');
        }
      }
    } catch (e) {
      debugPrint('OfflineAccess: Server restore failed: $e');
    }
  }
}
