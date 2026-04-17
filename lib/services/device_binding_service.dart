import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'google_auth_service.dart';

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
        await docRef.set({
          'deviceId': devId,
          'email': email.toLowerCase(),
          'boundAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: FIRST BIND ✅ email=$email devId=$devId');
        return true;
      }

      final storedDeviceId = doc.data()!['deviceId'] as String?;

      if (storedDeviceId == null || storedDeviceId.isEmpty) {
        // Corrupted entry → re-register
        await docRef.set({
          'deviceId': devId,
          'email': email.toLowerCase(),
          'boundAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: RE-BIND (corrupted) ✅ email=$email devId=$devId');
        return true;
      }

      if (storedDeviceId == devId) {
        // SAME device → allowed
        await docRef.update({'lastSeen': FieldValue.serverTimestamp()}).catchError((_) {});
        await _cacheLocalBinding(email, devId);
        _isDeviceBound = true;
        _hasCheckedOnce = true;
        debugPrint('DeviceBinding: MATCH ✅ email=$email');
        return true;
      }

      // DIFFERENT device → BLOCKED
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
    if (email == null) return false;

    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) return false;

      final devId = await getDeviceId();
      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      await docRef.set({
        'deviceId': devId,
        'email': email.toLowerCase(),
        'boundAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'migratedAt': FieldValue.serverTimestamp(),
      });

      // Cache locally
      await _cacheLocalBinding(email, devId);

      _isDeviceBound = true;
      _hasCheckedOnce = true;
      debugPrint('DeviceBinding: MIGRATED ✅ email=$email devId=$devId');
      return true;
    } catch (e) {
      debugPrint('DeviceBinding migrate error: $e');
      return false;
    }
  }
}
