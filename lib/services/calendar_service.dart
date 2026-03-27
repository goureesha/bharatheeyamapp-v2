import 'package:flutter/foundation.dart';

/// Google Calendar sync — DISABLED (sensitive scope removed).
/// All methods are no-ops that return success.
class CalendarService {
  static Future<bool> createAppointment({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    debugPrint('CalendarService: create disabled (no Google API scopes)');
    return true;
  }
}
