import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'google_auth_service.dart';

/// Manages one-Gmail-one-device binding using Firestore for cross-device enforcement.
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

  static String? _deviceId;
  static bool _isDeviceBound = true; // default true (fail-open until checked)

  static bool get isDeviceBound => _isDeviceBound;
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

  /// Check if current device is bound to the signed-in email using Firestore.
  /// Returns true if bound (or first time → auto-registers).
  static Future<bool> checkBinding() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) {
      _isDeviceBound = true;
      return true;
    }

    try {
      // Ensure Firebase is initialized
      try {
        await Firebase.initializeApp();
      } catch (_) {
        // Already initialized — that's fine
      }

      final devId = await getDeviceId();
      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      final doc = await docRef.get();

      if (!doc.exists || doc.data() == null) {
        // No binding exists → register this device
        await docRef.set({
          'deviceId': devId,
          'email': email.toLowerCase(),
          'boundAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        _isDeviceBound = true;
        debugPrint('DeviceBinding: FIRST BIND email=$email devId=$devId');
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
        _isDeviceBound = true;
        debugPrint('DeviceBinding: RE-BIND (empty) email=$email devId=$devId');
        return true;
      }

      if (storedDeviceId == devId) {
        // Same device → allowed
        // Update lastSeen timestamp
        await docRef.update({'lastSeen': FieldValue.serverTimestamp()});
        _isDeviceBound = true;
        debugPrint('DeviceBinding: MATCH ✅ email=$email');
        return true;
      }

      // Different device → BLOCKED
      _isDeviceBound = false;
      debugPrint('DeviceBinding: MISMATCH ❌ email=$email thisDevice=$devId storedDevice=$storedDeviceId');
      return false;
    } catch (e) {
      debugPrint('DeviceBinding check error: $e');
      // If Firestore is unreachable, fall back to local check
      // This prevents blocking users who are offline
      return _localFallbackCheck(email);
    }
  }

  /// Migrate: bind current device to the signed-in email (overwrites old binding in Firestore)
  static Future<bool> migrateDevice() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return false;

    try {
      try {
        await Firebase.initializeApp();
      } catch (_) {}

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

      // Also update local binding
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bharatheeyam_bound_email', email.toLowerCase());

      _isDeviceBound = true;
      debugPrint('DeviceBinding: MIGRATED ✅ email=$email devId=$devId');
      return true;
    } catch (e) {
      debugPrint('DeviceBinding migrate error: $e');
      return false;
    }
  }

  /// Local fallback when Firestore is unreachable (e.g., no internet)
  /// Checks SharedPreferences to at least enforce single-email-per-device
  static Future<bool> _localFallbackCheck(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('bharatheeyam_bound_email');

      if (storedEmail == null || storedEmail.isEmpty) {
        // First time locally → register
        await prefs.setString('bharatheeyam_bound_email', email.toLowerCase());
        _isDeviceBound = true;
        return true;
      }

      _isDeviceBound = (storedEmail.toLowerCase() == email.toLowerCase());
      debugPrint('DeviceBinding: LOCAL fallback email=$email stored=$storedEmail bound=$_isDeviceBound');
      return _isDeviceBound;
    } catch (e) {
      debugPrint('DeviceBinding local fallback error: $e');
      _isDeviceBound = true; // fail-open
      return true;
    }
  }
}
