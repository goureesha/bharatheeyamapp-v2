import 'package:flutter/foundation.dart';

/// Google Sheets sync — DISABLED (sensitive scope removed).
/// All methods are no-ops that return success.
class SheetsService {
  static Future<bool> syncProfile(Map<String, dynamic> profile, {bool isNew = false}) async {
    debugPrint('SheetsService: sync disabled (no Google API scopes)');
    return true;
  }
}
