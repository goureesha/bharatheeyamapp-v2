import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'google_auth_service.dart';

class UserSessionService {
  static bool _isBlocked = false;
  static int _deviceCount = 0;
  static String _deviceId = '';

  static bool get isBlocked => _isBlocked;
  static int get deviceCount => _deviceCount;
  static String get deviceId => _deviceId;

  /// Register this device in Firestore and check if user is blocked.
  /// Returns true if user is allowed, false if blocked.
  static Future<bool> registerAndCheck() async {
    final email = GoogleAuthService.userEmail;
    if (email == null || email.isEmpty) return false;

    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(email);

      // Get device info
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      String model = 'Unknown';
      String os = 'Unknown';

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final info = await deviceInfo.androidInfo;
          model = '${info.brand} ${info.model}';
          os = 'Android ${info.version.release}';
          _deviceId = info.id;
        } else if (Platform.isIOS) {
          final info = await deviceInfo.iosInfo;
          model = info.utsname.machine;
          os = 'iOS ${info.systemVersion}';
          _deviceId = info.identifierForVendor ?? 'unknown';
        }
      } else {
        final info = await deviceInfo.webBrowserInfo;
        model = info.browserName.name;
        os = 'Web';
        _deviceId = 'web_${info.userAgent?.hashCode ?? 0}';
      }

      // Check / create user document
      final userSnap = await userRef.get();
      if (userSnap.exists) {
        final data = userSnap.data() ?? {};
        final status = data['status'] ?? 'active';
        if (status == 'blocked') {
          _isBlocked = true;
          return false;
        }
        // Update last login
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'name': GoogleAuthService.userName ?? '',
          'photoUrl': GoogleAuthService.userPhoto ?? '',
        });
      } else {
        // First time user
        await userRef.set({
          'name': GoogleAuthService.userName ?? '',
          'email': email,
          'photoUrl': GoogleAuthService.userPhoto ?? '',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      // Register device
      final deviceRef = userRef.collection('devices').doc(_deviceId);
      await deviceRef.set({
        'model': model,
        'os': os,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'lastActive': FieldValue.serverTimestamp(),
        'firstLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update lastActive (not firstLogin on merge)
      await deviceRef.update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Count devices
      final devicesSnap = await userRef.collection('devices').get();
      _deviceCount = devicesSnap.docs.length;

      // Store device count on user doc for admin dashboard
      await userRef.update({'deviceCount': _deviceCount});

      _isBlocked = false;
      return true;
    } catch (e) {
      debugPrint('UserSessionService error: $e');
      // Allow usage if Firestore fails (graceful degradation)
      return true;
    }
  }

  /// Check block status only (lightweight, no device registration)
  static Future<bool> checkBlocked() async {
    final email = GoogleAuthService.userEmail;
    if (email == null || email.isEmpty) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .get();
      if (doc.exists) {
        final status = doc.data()?['status'] ?? 'active';
        _isBlocked = (status == 'blocked');
        return !_isBlocked;
      }
      return true;
    } catch (e) {
      return true;
    }
  }
}
