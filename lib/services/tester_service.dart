import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'google_auth_service.dart';

class TesterService {
  static const String _testerCacheKey = 'is_beta_tester';
  static final ValueNotifier<bool> isTesterNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> statusMessage = ValueNotifier<String>('Waiting to check...');

  /// Returns true if the user is a verified tester.
  static bool get isTester => isTesterNotifier.value;

  /// Initializes the service by loading the cached tester status.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isTesterNotifier.value = prefs.getBool(_testerCacheKey) ?? false;
  }

  /// Verifies with Firestore if the given [email] belongs to a tester.
  /// It updates the local cache and the [_isTester] flag.
  static Future<void> checkTesterStatus(String? email) async {
    if (email == null || email.isEmpty) {
      statusMessage.value = 'Not logged in.';
      await _clearStatus();
      return;
    }
    
    statusMessage.value = 'Checking $email...';

    try {
      // Ensure Firebase Auth is active before Firestore query
      final authOk = await GoogleAuthService.ensureFirebaseAuth();
      if (!authOk) {
        statusMessage.value = 'Firebase Auth not active — sign in again';
        debugPrint('TesterService: Firebase Auth not active, skipping Firestore');
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('testers')
          .doc(email.toLowerCase())
          .get();

      final bool isTesterNow = doc.exists;
      
      if (isTesterNow) {
        statusMessage.value = 'Verified. Granthaalaya unlocked!';
      } else {
        statusMessage.value = 'Email $email not found in testers collection.';
      }

      if (isTesterNotifier.value != isTesterNow) {
        isTesterNotifier.value = isTesterNow;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_testerCacheKey, isTesterNow);
        debugPrint('TesterService: Status updated -> isTester: $isTesterNow');
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('permission-denied')) {
        statusMessage.value = 'Firestore rules need update — see firestore.rules';
      } else if (errStr.contains('unavailable') || errStr.contains('timeout')) {
        statusMessage.value = 'Offline — using cached status';
      } else {
        statusMessage.value = 'Check failed — using cached status';
      }
      debugPrint('TesterService: Failed to check tester status: $e');
      // On failure, we retain the cached status so users don't lose access if offline
    }
  }

  /// Clears the tester status (used on logout).
  static Future<void> _clearStatus() async {
    isTesterNotifier.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testerCacheKey);
  }

  /// Explicitly reset the tester status, useful when logging out.
  static Future<void> onSignOut() async {
    await _clearStatus();
  }
}
