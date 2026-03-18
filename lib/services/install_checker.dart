import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Checks if app was installed from the Google Play Store.
/// On web, always returns true (no sideloading concept).
class InstallChecker {
  static bool _checked = false;
  static bool _isFromStore = true;

  static bool get isFromPlayStore => _isFromStore;

  static Future<void> check() async {
    if (_checked) return;
    _checked = true;

    // Web apps can't be sideloaded
    if (kIsWeb) {
      _isFromStore = true;
      return;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final installer = info.installerStore ?? '';
      debugPrint('InstallChecker: installer = "$installer"');

      // Play Store installer package name
      _isFromStore = installer == 'com.android.vending' ||
                     installer == 'com.google.android.feedback' ||
                     installer.isEmpty; // debug builds have empty installer, allow during dev
    } catch (e) {
      debugPrint('InstallChecker error: $e');
      _isFromStore = true; // fail-open for safety during development
    }
  }
}
