import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TesterService {
  static const String _testerCacheKey = 'is_beta_tester';
  static bool _isTester = false;

  /// Returns true if the user is a verified tester.
  /// This checks the local cache instantly, and does not block the UI.
  static bool get isTester => _isTester;

  /// Initializes the service by loading the cached tester status.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isTester = prefs.getBool(_testerCacheKey) ?? false;
  }

  /// Verifies with Firestore if the given [email] belongs to a tester.
  /// It updates the local cache and the [_isTester] flag.
  static Future<void> checkTesterStatus(String? email) async {
    if (email == null || email.isEmpty) {
      await _clearStatus();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('testers')
          .doc(email.toLowerCase())
          .get();

      final bool isTesterNow = doc.exists;
      
      if (_isTester != isTesterNow) {
        _isTester = isTesterNow;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_testerCacheKey, _isTester);
        debugPrint('TesterService: Status updated -> isTester: $_isTester');
      }
    } catch (e) {
      debugPrint('TesterService: Failed to check tester status: $e');
      // On failure, we retain the cached status so users don't lose access if offline
    }
  }

  /// Clears the tester status (used on logout).
  static Future<void> _clearStatus() async {
    _isTester = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testerCacheKey);
  }

  /// Explicitly reset the tester status, useful when logging out.
  static Future<void> onSignOut() async {
    await _clearStatus();
  }
}
