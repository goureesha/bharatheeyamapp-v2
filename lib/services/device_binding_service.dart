import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'google_auth_service.dart';

/// Manages one-Gmail-one-device binding using LOCAL SharedPreferences.
/// No Google Sheets / sensitive scopes required.
class DeviceBindingService {
  static const _deviceIdKey = 'bharatheeyam_device_id';
  static const _boundEmailKey = 'bharatheeyam_bound_email';

  static String? _deviceId;
  static bool _isDeviceBound = true;

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

  /// Check if current device is bound to the signed-in email.
  /// Returns true if bound (or no binding exists yet → auto-registers).
  static Future<bool> checkBinding() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) { _isDeviceBound = true; return true; }

    try {
      final devId = await getDeviceId();
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString(_boundEmailKey);

      if (storedEmail == null || storedEmail.isEmpty) {
        // No binding exists → register this device
        await prefs.setString(_boundEmailKey, email.toLowerCase());
        _isDeviceBound = true;
        debugPrint('DeviceBinding: first bind email=$email devId=$devId');
        return true;
      }

      // Check if current email matches the bound email
      _isDeviceBound = (storedEmail.toLowerCase() == email.toLowerCase());
      debugPrint('DeviceBinding: check email=$email stored=$storedEmail bound=$_isDeviceBound');
      return _isDeviceBound;
    } catch (e) {
      debugPrint('DeviceBinding check error: $e');
      _isDeviceBound = true; // fail-open
      return true;
    }
  }

  /// Migrate: bind current device to the signed-in email (overwrite old binding)
  static Future<bool> migrateDevice() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_boundEmailKey, email.toLowerCase());
      _isDeviceBound = true;
      debugPrint('DeviceBinding: migrated to $email');
      return true;
    } catch (e) {
      debugPrint('DeviceBinding migrate error: $e');
      return false;
    }
  }
}
