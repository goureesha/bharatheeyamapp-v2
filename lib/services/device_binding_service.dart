import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'google_auth_service.dart';
import 'app_access_service.dart';

/// Manages one-Gmail-one-device binding using Firestore for cross-device enforcement.
///
/// SECURITY: Firestore is the SOLE source of truth.
/// If Firestore is unreachable, we BLOCK (fail-closed) to prevent bypass.
///
/// Flow:
///   1. Each device gets a unique UUID (persisted in SharedPreferences).
///   2. On sign-in, we check Firestore: `device_bindings/{email}` → stored deviceId.
///   3. If no binding exists → register this device.
///   4. If binding exists AND matches this device → OK.
///   5. If binding exists AND does NOT match → BLOCK (show mismatch screen).
///   6. "Migrate Device" updates Firestore to the new device.
class DeviceBindingService {
  static const _deviceIdKey = 'bharatheeyam_device_id';
  static const _firestoreCollection = 'device_bindings';
  static const _localBoundEmailKey = 'bharatheeyam_bound_email';
  static const _localBoundDeviceKey = 'bharatheeyam_bound_device_id';
  static const _lastFirestoreCheckKey = 'bharatheeyam_last_firestore_check';

  static String? _deviceId;
  static bool _isDeviceBound = false; // FAIL-CLOSED: default to blocked until verified
  static bool _hasCheckedOnce = false;
  static bool isDeviceBlocked = false;
  static String deviceBlockedReason = '';

  static bool get isDeviceBound => _isDeviceBound;
  static bool get hasCheckedOnce => _hasCheckedOnce;
  static String? get deviceId => _deviceId;

  /// Get or generate a unique device ID (persisted locally)
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
      debugPrint('DeviceBinding: new deviceId=$_deviceId');
    }
    return _deviceId!;
  }

  /// Collect rich device + access details for Firestore
  static Future<Map<String, dynamic>> _getDeviceDetails(String email, String devId) async {
    final data = <String, dynamic>{
      'deviceId': devId,
      'email': email.toLowerCase(),
      'lastSeen': FieldValue.serverTimestamp(),
    };

    // Device info
    try {
      if (!kIsWeb) {
        final deviceInfo = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final android = await deviceInfo.androidInfo;
          data['deviceName'] = '${android.brand} ${android.model}';
          data['deviceBrand'] = android.brand;
          data['deviceModel'] = android.model;
          data['androidVersion'] = android.version.release;
          data['sdkInt'] = android.version.sdkInt;
          data['manufacturer'] = android.manufacturer;
          data['product'] = android.product;
          data['fingerprint'] = android.fingerprint;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final ios = await deviceInfo.iosInfo;
          data['deviceName'] = ios.name;
          data['deviceModel'] = ios.model;
          data['iosVersion'] = ios.systemVersion;
        }
      }
    } catch (e) {
      debugPrint('DeviceBinding: device info error: $e');
    }

    // App version
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      data['appVersion'] = pkgInfo.version;
      data['buildNumber'] = pkgInfo.buildNumber;
    } catch (_) {}

    // Trial details
    data['isTrialActive'] = AppAccessService.isTrialActive;
    data['trialMinutesRemaining'] = AppAccessService.trialMinutesRemaining;
    if (AppAccessService.trialStartDate != null) {
      data['trialStartedAt'] = Timestamp.fromDate(AppAccessService.trialStartDate!);
    }

    // NOTE: Do NOT write accessActive or accessDaysRemaining from the app.
    // Only adminAccess (admin-set) controls access.
    // Writing these fields from the app was causing lockout failures.

    // Clean up all stale/app-written fields — admin uses adminAccess only
    data['premiumActive'] = FieldValue.delete();
    data['premiumDaysRemaining'] = FieldValue.delete();
    data['subscribedAt'] = FieldValue.delete();
    data['subscriptionDaysRemaining'] = FieldValue.delete();
    data['hasSubscription'] = FieldValue.delete();

    return data;
  }

  /// Ensure Firebase is initialized (reuse the centralized init)
  static Future<bool> _ensureFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAkG1hdauVlL9b8nHM5o2B25yPQ6IANci4',
            appId: '1:212430902387:web:149c933fd3d29aa5014606',
            messagingSenderId: '212430902387',
            projectId: 'bharatheeyam-app',
            authDomain: 'bharatheeyam-app.firebaseapp.com',
            storageBucket: 'bharatheeyam-app.firebasestorage.app',
            measurementId: 'G-BNTGY2WSLZ',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e) {
      debugPrint('DeviceBinding: Firebase init error: $e');
      return Firebase.apps.isNotEmpty; // still might be usable
    }
  }

  /// Check if current device is bound to the signed-in email using Firestore.
  /// Returns true if bound (or first time → auto-registers).
  ///
  /// SECURITY: If Firestore is unreachable, we use a LIMITED local fallback:
  ///   - Only allows if we've previously verified via Firestore AND device+email match
  ///   - New devices that never verified via Firestore are BLOCKED
  static Future<bool> checkBinding() async {
    // Skip device binding on web — no persistent device identity
    if (kIsWeb) {
      _isDeviceBound = true;
      _hasCheckedOnce = true;
      return true;
    }

    final email = GoogleAuthService.userEmail;
    if (email == null) {
      // Not signed in — no binding to check
      _isDeviceBound = true;
      _hasCheckedOnce = true;
      return true;
    }

    final devId = await getDeviceId();

    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) {
        debugPrint('DeviceBinding: Firebase NOT ready, using strict local fallback');
        return _strictLocalFallback(email, devId);
      }

      // Ensure Firebase Auth is active before any Firestore operations.
      // Without this, new devices fail to register due to permission-denied.
      final authOk = await GoogleAuthService.ensureFirebaseAuth();
      if (!authOk) {
        debugPrint('DeviceBinding: Firebase Auth NOT active — falling back to local');
        return _strictLocalFallback(email, devId);
      }

      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      final doc = await docRef.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firestore timeout');
        },
      );

      if (!doc.exists || doc.data() == null) {
        // No binding exists → register this device (FIRST TIME)
        final details = await _getDeviceDetails(email, devId);
        details['boundAt'] = FieldValue.serverTimestamp();
        details['bindEvent'] = 'first_bind';
        await docRef.set(details, SetOptions(merge: true));
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: FIRST BIND ✅ email=$email devId=$devId');
        return true;
      }

      final storedDeviceId = doc.data()!['deviceId'] as String?;

      if (storedDeviceId == null || storedDeviceId.isEmpty) {
        // Corrupted entry → re-register
        final details = await _getDeviceDetails(email, devId);
        details['boundAt'] = FieldValue.serverTimestamp();
        details['bindEvent'] = 'rebind_corrupted';
        await docRef.set(details, SetOptions(merge: true));
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: RE-BIND (corrupted) ✅ email=$email devId=$devId');
        return true;
      }

      if (storedDeviceId == devId) {
        // SAME device → allowed — update with full details
        try {
          final details = await _getDeviceDetails(email, devId);
          await docRef.update(details);
          debugPrint('DeviceBinding: MATCH ✅ full update OK email=$email');
        } catch (e) {
          debugPrint('DeviceBinding: full update failed=$e, trying lastSeen only');
          try {
            await docRef.update({'lastSeen': FieldValue.serverTimestamp()});
            debugPrint('DeviceBinding: lastSeen update OK');
          } catch (e2) {
            debugPrint('DeviceBinding: lastSeen update ALSO failed=$e2');
          }
        }
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: MATCH ✅ email=$email');
        return true;
      }

      // ── DEVICE MISMATCH ──
      // Different device detected → BLOCK for ALL users
      // User must tap "Migrate Device" button in settings to switch
      _isDeviceBound = false;
      _hasCheckedOnce = true;
      await _clearLocalBinding();
      debugPrint('DeviceBinding: MISMATCH ❌ email=$email thisDevice=$devId storedDevice=$storedDeviceId');
      return false;
    } catch (e) {
      debugPrint('DeviceBinding check error: $e');
      return _strictLocalFallback(email, devId);
    }
  }
  /// Cache a successful Firestore verification locally
  static Future<void> _cacheLocalBinding(String email, String devId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localBoundEmailKey, email.toLowerCase());
    await prefs.setString(_localBoundDeviceKey, devId);
    await prefs.setInt(_lastFirestoreCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear local binding cache (called on mismatch)
  static Future<void> _clearLocalBinding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localBoundEmailKey);
    await prefs.remove(_localBoundDeviceKey);
    await prefs.remove(_lastFirestoreCheckKey);
  }

  /// STRICT local fallback: only allows if we've previously verified via Firestore
  /// AND the cached email+device match the current ones.
  /// New devices that never verified via Firestore are BLOCKED.
  static Future<bool> _strictLocalFallback(String email, String devId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedEmail = prefs.getString(_localBoundEmailKey);
      final cachedDevice = prefs.getString(_localBoundDeviceKey);
      final lastCheck = prefs.getInt(_lastFirestoreCheckKey) ?? 0;

      // If never verified via Firestore → BLOCK
      if (cachedEmail == null || cachedDevice == null || lastCheck == 0) {
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ never verified via Firestore');
        return false;
      }

      // If cached email doesn't match → BLOCK
      if (cachedEmail.toLowerCase() != email.toLowerCase()) {
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ email mismatch cached=$cachedEmail current=$email');
        return false;
      }

      // If cached device doesn't match → BLOCK
      if (cachedDevice != devId) {
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ device mismatch');
        return false;
      }

      // Check if the last Firestore verification was within 7 days
      final daysSinceCheck = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lastCheck))
          .inDays;
      if (daysSinceCheck > 7) {
        // Stale cache → BLOCK (force online verification)
        _isDeviceBound = false;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: STRICT LOCAL ❌ cache stale ($daysSinceCheck days old)');
        return false;
      }

      // All checks passed → same email, same device, recent Firestore verification
      _isDeviceBound = true;
      _hasCheckedOnce = true;
      debugPrint('DeviceBinding: STRICT LOCAL ✅ cached verification valid ($daysSinceCheck days old)');
      return true;
    } catch (e) {
      debugPrint('DeviceBinding strict local error: $e');
      _isDeviceBound = false; // FAIL-CLOSED
      _hasCheckedOnce = true;
      return false;
    }
  }

  /// Migrate: bind current device to the signed-in email (overwrites old binding in Firestore)
  static Future<bool> migrateDevice() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) {
      debugPrint('DeviceBinding migrate: NO EMAIL — user not signed in');
      return false;
    }

    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) {
        debugPrint('DeviceBinding migrate: Firebase NOT ready');
        return false;
      }

      // Ensure Firebase Auth is active for Firestore rules
      final authOk = await GoogleAuthService.ensureFirebaseAuth();
      if (!authOk) {
        debugPrint('DeviceBinding migrate: Firebase Auth NOT active — cannot write to Firestore');
        return false;
      }
      debugPrint('DeviceBinding migrate: Firebase Auth confirmed ✅');

      final devId = await getDeviceId();
      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      // Try full details, fallback to minimal if _getDeviceDetails fails
      Map<String, dynamic> details;
      try {
        details = await _getDeviceDetails(email, devId);
      } catch (e) {
        debugPrint('DeviceBinding migrate: details error=$e, using minimal');
        details = {
          'deviceId': devId,
          'email': email.toLowerCase(),
          'lastSeen': FieldValue.serverTimestamp(),
        };
      }

      details['boundAt'] = FieldValue.serverTimestamp();
      details['migratedAt'] = FieldValue.serverTimestamp();
      details['bindEvent'] = 'manual_migrate';
      await docRef.set(details, SetOptions(merge: true));

      // Cache locally
      await _cacheLocalBinding(email, devId);

      _isDeviceBound = true;
      _hasCheckedOnce = true;
      debugPrint('DeviceBinding: MIGRATED ✅ email=$email devId=$devId');
      return true;
    } catch (e, stack) {
      final errStr = e.toString();
      if (errStr.contains('permission-denied')) {
        debugPrint('DeviceBinding migrate PERMISSION DENIED: Firestore rules must allow write to device_bindings/${email.toLowerCase()}');
        debugPrint('DeviceBinding: Ensure Firebase Auth is active and email matches doc ID');
      }
      debugPrint('DeviceBinding migrate error: $e');
      debugPrint('DeviceBinding migrate stack: $stack');
      return false;
    }
  }

  /// Track every device install/launch in Firestore (installs/{deviceId})
  /// This gives you visibility into ALL devices, not just per-email bindings.
  static Future<void> trackInstall() async {
    try {
      if (kIsWeb) return; // Skip web

      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) return;

      final devId = await getDeviceId();
      final email = GoogleAuthService.userEmail;

      final data = <String, dynamic>{
        'deviceId': devId,
        'email': email?.toLowerCase() ?? 'not_signed_in',
        'lastLaunch': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      };

      // Device info
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final android = await deviceInfo.androidInfo;
          data['deviceName'] = '${android.brand} ${android.model}';
          data['brand'] = android.brand;
          data['model'] = android.model;
          data['androidVersion'] = android.version.release;
          data['sdkInt'] = android.version.sdkInt;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final ios = await deviceInfo.iosInfo;
          data['deviceName'] = ios.name;
          data['model'] = ios.model;
          data['iosVersion'] = ios.systemVersion;
        }
      } catch (_) {}

      // App version
      try {
        final pkgInfo = await PackageInfo.fromPlatform();
        data['appVersion'] = pkgInfo.version;
        data['buildNumber'] = pkgInfo.buildNumber;
      } catch (_) {}

      // NOTE: Do not write access status — admin-controlled via device_bindings only

      final docRef = FirebaseFirestore.instance
          .collection('installs')
          .doc(devId);

      final doc = await docRef.get().timeout(const Duration(seconds: 5));
      if (!doc.exists) {
        data['firstInstall'] = FieldValue.serverTimestamp();
        data['launchCount'] = 1;
        await docRef.set(data);
        debugPrint('InstallTracker: NEW install ✅ devId=$devId');
      } else {
        final prevCount = (doc.data()?['launchCount'] as int?) ?? 0;
        data['launchCount'] = prevCount + 1;
        await docRef.update(data);
        debugPrint('InstallTracker: UPDATE ✅ devId=$devId launches=${prevCount + 1}');
      }

    } catch (e) {
      debugPrint('InstallTracker error: $e');
    }
  }

  /// Check if this device is blocked via installs/{deviceId}
  /// Called during deferred init. Has its own timeout. Fail-OPEN.
  static Future<void> checkDeviceBlock() async {
    try {
      if (kIsWeb) return;

      // Load cached value first
      final prefs = await SharedPreferences.getInstance();
      isDeviceBlocked = prefs.getBool('device_blocked') ?? false;
      deviceBlockedReason = prefs.getString('device_blocked_reason') ?? '';

      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) return; // use cached

      final devId = await getDeviceId();
      final doc = await FirebaseFirestore.instance
          .collection('installs')
          .doc(devId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final blocked = data['blocked'] == true;
        final reason = data['blockedReason'] as String? ?? '';
        isDeviceBlocked = blocked;
        deviceBlockedReason = reason;
        await prefs.setBool('device_blocked', blocked);
        await prefs.setString('device_blocked_reason', reason);
        if (blocked) {
          debugPrint('🚫 DEVICE BLOCKED: $devId reason=$reason');
        }
      }
    } catch (e) {
      debugPrint('DeviceBlock check error: $e');
      // Fail-open: use cached value
    }
  }


}
