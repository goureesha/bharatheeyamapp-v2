import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_service.dart';
import 'appointment_service.dart';

/// Google Calendar 2-way sync service.
/// Syncs appointments to/from a dedicated "ಭಾರತೀಯಮ್ Appointments" calendar.
///
/// Strategy:
/// - App is source of truth on conflicts
/// - Uses extendedProperties to tag events with local appointment IDs
/// - Tracks sync via googleEventId on the Appointment model
class CalendarService {
  static gcal.CalendarApi? _calendarApi;
  static String? _calendarId;
  static bool _isSyncing = false;
  static String? _lastSyncTime;

  static bool get isSyncing => _isSyncing;
  static String? get lastSyncTime => _lastSyncTime;

  /// Calendar name used in Google Calendar
  static const _calendarName = 'ಭಾರತೀಯಮ್ Appointments';

  /// Key prefix for extendedProperties to identify our events
  static const _appIdKey = 'bharatheeyam_id';
  static const _appSourceKey = 'bharatheeyam_source';

  // ─── Initialization ───────────────────────────────────────

  /// Initialize the Calendar API client.
  /// Returns true if successful, false if auth fails.
  static String? lastInitError;
  static String? lastSyncDebug;

  static Future<bool> initialize() async {
    try {
      // Ensure calendar scopes are granted
      final scopeOk = await GoogleAuthService.ensureCalendarScope();
      if (!scopeOk) {
        lastInitError = 'Calendar permission not granted. Please sign out, sign in again and allow Calendar access.';
        debugPrint('CalendarService: $lastInitError');
        return false;
      }

      final client = await GoogleAuthService.getAuthenticatedClient();
      if (client == null) {
        lastInitError = 'Google auth client is null. Please sign out and sign in again.';
        debugPrint('CalendarService: $lastInitError');
        return false;
      }
      _calendarApi = gcal.CalendarApi(client);
      lastInitError = null;
      debugPrint('CalendarService: Initialized successfully');
      return true;
    } catch (e) {
      lastInitError = 'Init error: $e';
      debugPrint('CalendarService: $lastInitError');
      return false;
    }
  }

  /// Find or create the dedicated Bharatheeyam calendar.
  /// Returns the calendar ID, or null on failure.
  static Future<String?> getOrCreateCalendar() async {
    if (_calendarId != null) return _calendarId;
    if (_calendarApi == null) return null;

    try {
      // Check saved calendar ID first
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('gcal_calendar_id');
      if (savedId != null && savedId.isNotEmpty) {
        // Verify it still exists
        try {
          await _calendarApi!.calendars.get(savedId);
          _calendarId = savedId;
          debugPrint('CalendarService: Using saved calendar: $_calendarId');
          return _calendarId;
        } catch (_) {
          // Calendar was deleted, clear saved ID
          await prefs.remove('gcal_calendar_id');
        }
      }

      // Search existing calendars
      final calendarList = await _calendarApi!.calendarList.list();
      if (calendarList.items != null) {
        for (final cal in calendarList.items!) {
          if (cal.summary == _calendarName) {
            _calendarId = cal.id;
            await prefs.setString('gcal_calendar_id', _calendarId!);
            debugPrint('CalendarService: Found existing calendar: $_calendarId');
            return _calendarId;
          }
        }
      }

      // Create new calendar
      final newCal = gcal.Calendar()
        ..summary = _calendarName
        ..description = 'ಭಾರತೀಯಮ್ ಆಪ್ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್‌ಗಳು — Auto-synced from Bharatheeyam App'
        ..timeZone = 'Asia/Kolkata';

      final created = await _calendarApi!.calendars.insert(newCal);
      _calendarId = created.id;
      if (_calendarId != null) {
        await prefs.setString('gcal_calendar_id', _calendarId!);
      }
      debugPrint('CalendarService: Created new calendar: $_calendarId');
      return _calendarId;
    } catch (e) {
      debugPrint('CalendarService: getOrCreateCalendar error: $e');
      return null;
    }
  }

  // ─── Push (App → Google Calendar) ─────────────────────────

  /// Push a single appointment to Google Calendar.
  /// Creates a new event or updates an existing one.
  /// Returns the Google event ID, or null on failure.
  static Future<String?> pushAppointment(Appointment appt) async {
    if (_calendarApi == null || _calendarId == null) return null;
    if (appt.status == 'cancelled') {
      // If cancelled locally, delete from GCal
      if (appt.googleEventId.isNotEmpty) {
        await deleteEvent(appt.googleEventId);
      }
      return null;
    }

    try {
      final event = _toEvent(appt);

      if (appt.googleEventId.isNotEmpty) {
        // Update existing event
        try {
          final updated = await _calendarApi!.events.update(
            event, _calendarId!, appt.googleEventId,
          );
          debugPrint('CalendarService: Updated event ${updated.id}');
          return updated.id;
        } catch (e) {
          // Event might have been deleted from GCal, create new
          debugPrint('CalendarService: Update failed, creating new: $e');
        }
      }

      // Create new event
      final created = await _calendarApi!.events.insert(event, _calendarId!);
      debugPrint('CalendarService: Created event ${created.id}');
      return created.id;
    } catch (e) {
      debugPrint('CalendarService: pushAppointment error: $e');
      return null;
    }
  }

  /// Delete an event from Google Calendar.
  static Future<bool> deleteEvent(String eventId) async {
    if (_calendarApi == null || _calendarId == null) return false;
    try {
      await _calendarApi!.events.delete(_calendarId!, eventId);
      debugPrint('CalendarService: Deleted event $eventId');
      return true;
    } catch (e) {
      debugPrint('CalendarService: Delete error: $e');
      return false;
    }
  }

  // ─── Pull (Google Calendar → App) ─────────────────────────

  /// Pull events from Google Calendar for a date range.
  /// Returns list of Google Calendar events.
  static Future<List<gcal.Event>> pullEvents({
    DateTime? timeMin,
    DateTime? timeMax,
    String? calendarId,
  }) async {
    if (_calendarApi == null) return [];
    final cId = calendarId ?? _calendarId;
    if (cId == null) return [];

    final now = DateTime.now();
    timeMin ??= now.subtract(const Duration(days: 30));
    timeMax ??= now.add(const Duration(days: 90));

    try {
      final events = <gcal.Event>[];
      String? pageToken;

      do {
        final result = await _calendarApi!.events.list(
          cId,
          timeMin: timeMin!.toUtc(),
          timeMax: timeMax!.toUtc(),
          singleEvents: true,
          orderBy: 'startTime',
          pageToken: pageToken,
          maxResults: 250,
        );

        if (result.items != null) {
          events.addAll(result.items!);
        }
        pageToken = result.nextPageToken;
      } while (pageToken != null);

      debugPrint('CalendarService: Pulled ${events.length} events');
      return events;
    } catch (e) {
      debugPrint('CalendarService: pullEvents error: $e');
      return [];
    }
  }

  // ─── Full 2-Way Sync ──────────────────────────────────────

  /// Perform full bidirectional sync.
  /// Returns (pushed, pulled, deleted) counts.
  static Future<({int pushed, int pulled, int deleted})> fullSync() async {
    if (_isSyncing) return (pushed: 0, pulled: 0, deleted: 0);
    _isSyncing = true;

    int pushed = 0, pulled = 0, deleted = 0;

    try {
      // Step 0: Initialize if needed
      if (_calendarApi == null) {
        final ok = await initialize();
        if (!ok) {
          _isSyncing = false;
          throw Exception('Calendar API init failed. Sign out & sign in again, and allow Calendar permission.');
        }
      }

      final calId = await getOrCreateCalendar();
      if (calId == null) {
        _isSyncing = false;
        throw Exception('Could not find or create Bharatheeyam calendar in Google Calendar.');
      }

      final localAppts = AppointmentService.appointments;

      // Step 1: Push local appointments that don't have a googleEventId
      for (final appt in localAppts) {
        if (appt.googleEventId.isEmpty && appt.status != 'cancelled' && appt.clientName.trim().isNotEmpty) {
          final eventId = await pushAppointment(appt);
          if (eventId != null) {
            await AppointmentService.setGoogleEventId(appt, eventId);
            pushed++;
          }
        }
      }

      // Step 2: Push local appointments that have been updated
      // (Re-push all that have a googleEventId to ensure sync)
      for (final appt in localAppts) {
        if (appt.googleEventId.isNotEmpty) {
          if (appt.status == 'cancelled') {
            final ok = await deleteEvent(appt.googleEventId);
            if (ok) deleted++;
          } else {
            await pushAppointment(appt);
            // Don't count as pushed since it's an update
          }
        }
      }

      // Step 3: Pull events from GCal that we don't have locally
      // Check BOTH the dedicated calendar AND the primary calendar
      final gcalEvents = await pullEvents();
      final dedicatedCount = gcalEvents.length;

      // Also pull from primary calendar
      final primaryEvents = await pullEvents(calendarId: 'primary');
      final primaryCount = primaryEvents.length;
      gcalEvents.addAll(primaryEvents);

      int skippedTracked = 0, skippedOurs = 0, skippedNull = 0;

      final localEventIds = localAppts
          .where((a) => a.googleEventId.isNotEmpty)
          .map((a) => a.googleEventId)
          .toSet();

      for (final event in gcalEvents) {
        if (event.id == null) continue;

        // Skip events we already track
        if (localEventIds.contains(event.id)) { skippedTracked++; continue; }

        // Check if this is an event we created (has our marker)
        final isOurs = event.extendedProperties?.private?[_appSourceKey] == 'bharatheeyam';
        // If it's our event but not in local list, it was deleted locally — skip
        if (isOurs) { skippedOurs++; continue; }

        // This is a new event created directly in GCal — pull it in
        final appt = _toAppointment(event);
        if (appt != null) {
          await AppointmentService.addAppointmentDirect(appt);
          pulled++;
        } else {
          skippedNull++;
        }
      }

      lastSyncDebug = 'Dedicated cal: $dedicatedCount events\n'
          'Primary cal: $primaryCount events\n'
          'Already tracked: $skippedTracked\n'
          'Ours (skipped): $skippedOurs\n'
          'Convert failed: $skippedNull\n'
          'Calendar ID: $_calendarId';

      // Step 4: Check for events deleted from GCal
      // (Events we pushed but that no longer exist in GCal)
      final gcalEventIds = gcalEvents.map((e) => e.id).toSet();
      for (final appt in localAppts) {
        if (appt.googleEventId.isNotEmpty &&
            appt.status != 'cancelled' &&
            !gcalEventIds.contains(appt.googleEventId)) {
          // Event was deleted from GCal — mark as cancelled locally
          await AppointmentService.updateStatus(appt, 'cancelled');
          deleted++;
        }
      }

      _lastSyncTime = _formatSyncTime(DateTime.now());

      // Save last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gcal_last_sync', _lastSyncTime!);

      debugPrint('CalendarService: Sync complete — pushed=$pushed, pulled=$pulled, deleted=$deleted');
    } catch (e) {
      debugPrint('CalendarService: fullSync error: $e');
      _isSyncing = false;
      rethrow;
    } finally {
      _isSyncing = false;
    }

    return (pushed: pushed, pulled: pulled, deleted: deleted);
  }

  /// Load last sync time from prefs
  static Future<void> loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSyncTime = prefs.getString('gcal_last_sync');
  }

  // ─── Legacy API (backward compatible) ─────────────────────

  /// Legacy method — now actually creates a real Google Calendar event.
  /// Called from appointment_screen.dart after booking.
  static Future<bool> createAppointment({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    try {
      if (_calendarApi == null) {
        final ok = await initialize();
        if (!ok) return false;
      }
      final calId = await getOrCreateCalendar();
      if (calId == null) return false;

      final event = gcal.Event()
        ..summary = '🔮 $title'
        ..description = description
        ..start = (gcal.EventDateTime()
          ..dateTime = start
          ..timeZone = 'Asia/Kolkata')
        ..end = (gcal.EventDateTime()
          ..dateTime = end
          ..timeZone = 'Asia/Kolkata')
        ..extendedProperties = (gcal.EventExtendedProperties()
          ..private = {_appSourceKey: 'bharatheeyam'});

      if (location != null) event.location = location;

      await _calendarApi!.events.insert(event, calId);
      debugPrint('CalendarService: Legacy createAppointment succeeded');
      return true;
    } catch (e) {
      debugPrint('CalendarService: Legacy createAppointment error: $e');
      return false;
    }
  }

  // ─── Converters ───────────────────────────────────────────

  /// Convert Appointment → Google Calendar Event
  static gcal.Event _toEvent(Appointment appt) {
    // Parse start time
    final startParts = appt.startTime.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 9;
    final startMin = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;

    // Parse end time
    final endParts = appt.endTime.split(':');
    final endHour = int.tryParse(endParts[0]) ?? 10;
    final endMin = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0;

    final startDt = DateTime(appt.date.year, appt.date.month, appt.date.day, startHour, startMin);
    final endDt = DateTime(appt.date.year, appt.date.month, appt.date.day, endHour, endMin);

    // Build description
    final descParts = <String>[];
    if (appt.clientPhone.isNotEmpty) descParts.add('📞 ${appt.clientPhone}');
    if (appt.clientId.isNotEmpty) descParts.add('🆔 ${appt.clientId}');
    if (appt.notes.isNotEmpty) descParts.add('📝 ${appt.notes}');

    // Color based on status
    String? colorId;
    if (appt.status == 'completed') {
      colorId = '2'; // Sage/green
    } else if (appt.status == 'booked') {
      colorId = '7'; // Peacock/teal
    }

    return gcal.Event()
      ..summary = '🔮 ${appt.clientName}'
      ..description = descParts.join('\n')
      ..start = (gcal.EventDateTime()
        ..dateTime = startDt
        ..timeZone = 'Asia/Kolkata')
      ..end = (gcal.EventDateTime()
        ..dateTime = endDt
        ..timeZone = 'Asia/Kolkata')
      ..colorId = colorId
      ..extendedProperties = (gcal.EventExtendedProperties()
        ..private = {
          _appIdKey: '${appt.date.year}-${appt.date.month.toString().padLeft(2, '0')}-${appt.date.day.toString().padLeft(2, '0')}_${appt.startTime}_${appt.clientName}',
          _appSourceKey: 'bharatheeyam',
        });
  }

  /// Convert Google Calendar Event → Appointment
  /// Returns null if the event can't be converted.
  static Appointment? _toAppointment(gcal.Event event) {
    try {
      final start = event.start?.dateTime;
      final end = event.end?.dateTime;
      if (start == null || end == null) return null;

      // Convert to local time
      final localStart = start.toLocal();
      final localEnd = end.toLocal();

      // Extract client name from title (remove emoji prefix if present)
      String clientName = event.summary ?? 'Unknown';
      if (clientName.startsWith('🔮 ')) {
        clientName = clientName.substring(2).trim();
      }

      // Extract phone from description
      String phone = '';
      String notes = '';
      if (event.description != null) {
        for (final line in event.description!.split('\n')) {
          if (line.startsWith('📞 ')) {
            phone = line.substring(2).trim();
          } else if (line.startsWith('📝 ')) {
            notes = line.substring(2).trim();
          }
        }
        // If no structured format, use whole description as notes
        if (notes.isEmpty && phone.isEmpty) {
          notes = event.description ?? '';
        }
      }

      return Appointment(
        id: '${AppointmentService.appointments.length + 1}',
        date: DateTime(localStart.year, localStart.month, localStart.day),
        startTime: '${localStart.hour.toString().padLeft(2, '0')}:${localStart.minute.toString().padLeft(2, '0')}',
        endTime: '${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}',
        clientName: clientName,
        clientPhone: phone,
        status: 'booked',
        notes: notes,
        createdAt: DateTime.now().toIso8601String(),
        googleEventId: event.id ?? '',
      );
    } catch (e) {
      debugPrint('CalendarService: _toAppointment error: $e');
      return null;
    }
  }

  /// Format sync time for display
  static String _formatSyncTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month} $h:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Reset state (for sign-out)
  static void reset() {
    _calendarApi = null;
    _calendarId = null;
    _isSyncing = false;
    _lastSyncTime = null;
  }
}
