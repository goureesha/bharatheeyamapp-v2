import 'package:flutter/foundation.dart';

/// Google Docs sync — DISABLED (sensitive scope removed).
/// All methods are no-ops that return success.
class DocsService {
  static Future<bool> syncNotes(String name, String notes) async {
    debugPrint('DocsService: sync disabled (no Google API scopes)');
    return true;
  }

  static Future<bool> openDoc(String name) async {
    debugPrint('DocsService: open disabled (no Google API scopes)');
    return true;
  }
}
