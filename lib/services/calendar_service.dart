import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:flutter/foundation.dart';
import 'google_auth_service.dart';

class CalendarService {
  /// Create an appointment in the user's Google Calendar.
  static Future<bool> createAppointment({
    required String clientName,
    required DateTime startTime,
    required Duration duration,
    String? description,
  }) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return false;

      final api = cal.CalendarApi(client);
      final endTime = startTime.add(duration);

      final event = cal.Event(
        summary: 'ಜಾತಕ - $clientName',
        description: description ?? 'ಭಾರತೀಯಮ್ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್',
        start: cal.EventDateTime(
          dateTime: startTime,
          timeZone: 'Asia/Kolkata',
        ),
        end: cal.EventDateTime(
          dateTime: endTime,
          timeZone: 'Asia/Kolkata',
        ),
        reminders: cal.EventReminders(
          useDefault: false,
          overrides: [
            cal.EventReminder(method: 'popup', minutes: 30),
          ],
        ),
      );

      await api.events.insert(event, 'primary');
      return true;
    } catch (e) {
      debugPrint('Calendar event error: $e');
      return false;
    }
  }
}
