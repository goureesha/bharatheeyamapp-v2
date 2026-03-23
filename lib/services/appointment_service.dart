import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/calendar/v3.dart' as cal;
import 'google_auth_service.dart';
import 'client_service.dart';

/// Appointment data model
class Appointment {
  final String id; // row index in sheet
  final DateTime date;
  final String startTime; // "HH:MM"
  final String endTime;   // "HH:MM"
  final String clientName;
  final String clientPhone;
  final String status; // booked, cancelled, completed
  final String notes;
  final String createdAt;
  final String clientId; // Links to Client.clientId (BH-2026-0001)

  Appointment({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.clientName,
    required this.clientPhone,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.clientId = '',
  });

  /// Parse from sheet row [date, startTime, endTime, clientName, phone, status, notes, createdAt, clientId]
  factory Appointment.fromRow(int rowIndex, List<Object?> row) {
    final dateStr = row.isNotEmpty ? row[0].toString() : '';
    final parts = dateStr.split('-');
    DateTime date;
    try {
      date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      date = DateTime.now();
    }
    return Appointment(
      id: '${rowIndex + 1}', // 1-indexed row
      date: date,
      startTime: row.length > 1 ? row[1].toString() : '',
      endTime: row.length > 2 ? row[2].toString() : '',
      clientName: row.length > 3 ? row[3].toString() : '',
      clientPhone: row.length > 4 ? row[4].toString() : '',
      status: row.length > 5 ? row[5].toString() : 'booked',
      notes: row.length > 6 ? row[6].toString() : '',
      createdAt: row.length > 7 ? row[7].toString() : '',
      clientId: row.length > 8 ? row[8].toString() : '',
    );
  }

  List<Object> toRow() => [
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    startTime, endTime, clientName, clientPhone, status, notes, createdAt, clientId,
  ];

  /// Human-readable time for WhatsApp
  String get timeRange => '$startTime - $endTime';
  String get dateStr => '${date.day}/${date.month}/${date.year}';
}

/// Available time slot configuration
class AvailableSlot {
  final int dayOfWeek; // 1=Monday, 7=Sunday
  final String startTime; // "HH:MM"
  final String endTime;
  final int slotMinutes;

  AvailableSlot({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.slotMinutes,
  });
}

/// Manages appointments in a Google Sheet
class AppointmentService {
  static const _sheetKey = 'bharatheeyam_appt_sheet_id';
  static const _apptTab = 'Appointments';
  static const _slotsTab = 'AvailableSlots';

  // In-memory cache
  static List<Appointment> _appointments = [];
  static List<AvailableSlot> _availableSlots = [];
  static bool _isLoaded = false;

  static List<Appointment> get appointments => _appointments;
  static List<AvailableSlot> get availableSlots => _availableSlots;
  static bool get isLoaded => _isLoaded;

  // ─── Sheet Setup ─────────────────────────────────────────

  static Future<sheets.SheetsApi?> _getApi() async {
    final client = await GoogleAuthService.getAuthClient();
    if (client == null) return null;
    return sheets.SheetsApi(client);
  }

  static Future<String?> _getOrCreateSheet(sheets.SheetsApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_sheetKey);
    if (existing != null) {
      try {
        await api.spreadsheets.get(existing);
        return existing;
      } catch (_) {
        // Sheet may have been deleted
      }
    }

    try {
      final created = await api.spreadsheets.create(sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: 'ಭಾರತೀಯಮ್ - Appointments'),
        sheets: [
          sheets.Sheet(properties: sheets.SheetProperties(title: _apptTab)),
          sheets.Sheet(properties: sheets.SheetProperties(title: _slotsTab, index: 1)),
        ],
      ));
      final id = created.spreadsheetId!;
      await prefs.setString(_sheetKey, id);

      // Write headers for Appointments tab
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [['Date', 'Start', 'End', 'Client', 'Phone', 'Status', 'Notes', 'CreatedAt', 'ClientId']]),
        id, '$_apptTab!A1:I1',
        valueInputOption: 'RAW',
      );

      // Write headers for AvailableSlots tab
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [['Day', 'Start', 'End', 'SlotMinutes']]),
        id, '$_slotsTab!A1:D1',
        valueInputOption: 'RAW',
      );

      // Default available slots: Mon-Sat, 9:00 - 17:00, 60 min slots
      final defaultSlots = <List<Object>>[];
      for (int d = 1; d <= 6; d++) {
        defaultSlots.add([d.toString(), '09:00', '17:00', '60']);
      }
      await api.spreadsheets.values.append(
        sheets.ValueRange(values: defaultSlots),
        id, '$_slotsTab!A:D',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );

      debugPrint('AppointmentService: Created sheet $id');
      return id;
    } catch (e) {
      debugPrint('AppointmentService: Sheet creation error: $e');
      return null;
    }
  }

   // ─── Load All Data ─────────────────────────────────────────

  static Future<void> loadAll() async {
    try {
      final api = await _getApi();
      if (api == null) return;
      final sid = await _getOrCreateSheet(api);
      if (sid == null) return;

      // Load appointments from Google Sheets
      final apptResp = await api.spreadsheets.values.get(sid, '$_apptTab!A:I');
      final apptRows = apptResp.values ?? [];
      _appointments = [];
      for (int i = 1; i < apptRows.length; i++) { // skip header row
        _appointments.add(Appointment.fromRow(i, apptRows[i]));
      }

      // Load available slots
      final slotsResp = await api.spreadsheets.values.get(sid, '$_slotsTab!A:D');
      final slotRows = slotsResp.values ?? [];
      _availableSlots = [];
      for (int i = 1; i < slotRows.length; i++) {
        final row = slotRows[i];
        if (row.isEmpty) continue;
        _availableSlots.add(AvailableSlot(
          dayOfWeek: int.tryParse(row[0].toString()) ?? 1,
          startTime: row.length > 1 ? row[1].toString() : '09:00',
          endTime: row.length > 2 ? row[2].toString() : '17:00',
          slotMinutes: row.length > 3 ? (int.tryParse(row[3].toString()) ?? 60) : 60,
        ));
      }

      // ─── Sync from Google Calendar ──────────────────────────
      await _syncFromGoogleCalendar(api, sid);

      _isLoaded = true;
      debugPrint('AppointmentService: Loaded ${_appointments.length} appointments, ${_availableSlots.length} slots');
    } catch (e) {
      debugPrint('AppointmentService: Load error: $e');
    }
  }

  /// Fetch events from Google Calendar and merge any that aren't in the sheet
  static Future<void> _syncFromGoogleCalendar(sheets.SheetsApi sheetsApi, String sheetId) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return;

      final calApi = cal.CalendarApi(client);
      final now = DateTime.now();
      final timeMin = now.subtract(const Duration(days: 90));
      final timeMax = now.add(const Duration(days: 90));

      final events = await calApi.events.list(
        'primary',
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 250,
      );

      if (events.items == null || events.items!.isEmpty) return;

      // Build a set of existing appointment keys for deduplication
      final existingKeys = <String>{};
      for (final a in _appointments) {
        final key = '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}_${a.startTime}_${a.clientName}';
        existingKeys.add(key);
      }

      int synced = 0;
      for (final event in events.items!) {
        if (event.start?.dateTime == null || event.end?.dateTime == null) continue;

        final start = event.start!.dateTime!.toLocal();
        final end = event.end!.dateTime!.toLocal();
        final summary = event.summary ?? '';
        final description = event.description ?? '';

        // Only sync events created by this app
        String clientName;
        if (summary.startsWith('ಜಾತಕ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ - ')) {
          clientName = summary.substring('ಜಾತಕ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ - '.length);
        } else if (summary.startsWith('ಜಾತಕ - ')) {
          clientName = summary.substring(7);
        } else {
          continue; // Skip non-app events
        }

        final dateStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
        final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
        final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

        final key = '${dateStr}_${startTime}_$clientName';

        // Skip if already exists
        if (existingKeys.contains(key)) continue;

        // Extract phone from description if present
        String phone = '';
        final phoneMatch = RegExp(r'Phone:\s*([+\d\s-]+)').firstMatch(description);
        if (phoneMatch != null) phone = phoneMatch.group(1)?.trim() ?? '';

        // Determine status from event
        String status = 'booked';
        if (event.status == 'cancelled') status = 'cancelled';

        final appt = Appointment(
          id: '0',
          date: DateTime(start.year, start.month, start.day),
          startTime: startTime,
          endTime: endTime,
          clientName: clientName,
          clientPhone: phone,
          status: status,
          notes: description.replaceAll(RegExp(r'Phone:\s*[+\d\s-]+'), '').trim(),
          createdAt: DateTime.now().toIso8601String(),
        );

        // Add to sheet so it persists
        try {
          await sheetsApi.spreadsheets.values.append(
            sheets.ValueRange(values: [appt.toRow()]),
            sheetId, '$_apptTab!A:I',
            valueInputOption: 'RAW',
            insertDataOption: 'INSERT_ROWS',
          );
        } catch (e) {
          debugPrint('AppointmentService: Sync write error: $e');
        }

        _appointments.add(appt);
        existingKeys.add(key);
        synced++;
      }

      if (synced > 0) {
        debugPrint('AppointmentService: Synced $synced events from Google Calendar');
      }
    } catch (e) {
      debugPrint('AppointmentService: Calendar sync error: $e');
    }
  }


  // ─── CRUD Operations ─────────────────────────────────────

  /// Add a new appointment
  static Future<bool> addAppointment({
    required DateTime date,
    required String startTime,
    required String endTime,
    required String clientName,
    required String clientPhone,
    String notes = '',
  }) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getOrCreateSheet(api);
      if (sid == null) return false;

      // Auto-create or link client
      String linkedClientId = '';
      if (clientPhone.isNotEmpty) {
        final client = await ClientService.getOrCreateClient(
          name: clientName,
          phone: clientPhone,
        );
        if (client != null) linkedClientId = client.clientId;
      }

      final now = DateTime.now();
      final appointment = Appointment(
        id: '0',
        date: date,
        startTime: startTime,
        endTime: endTime,
        clientName: clientName,
        clientPhone: clientPhone,
        status: 'booked',
        notes: notes,
        createdAt: now.toIso8601String(),
        clientId: linkedClientId,
      );

      await api.spreadsheets.values.append(
        sheets.ValueRange(values: [appointment.toRow()]),
        sid, '$_apptTab!A:I',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );

      _appointments.add(appointment);

      // Also create Google Calendar event
      await _createCalendarEvent(appointment);

      debugPrint('AppointmentService: Added appointment for ${appointment.clientName}');
      return true;
    } catch (e) {
      debugPrint('AppointmentService: Add error: $e');
      return false;
    }
  }

  /// Update appointment status (cancel/complete)
  static Future<bool> updateStatus(Appointment appt, String newStatus) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getOrCreateSheet(api);
      if (sid == null) return false;

      // Find the row in sheet
      final apptResp = await api.spreadsheets.values.get(sid, '$_apptTab!A:I');
      final rows = apptResp.values ?? [];
      
      int? rowIdx;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length > 3 &&
            row[0].toString() == '${appt.date.year}-${appt.date.month.toString().padLeft(2, '0')}-${appt.date.day.toString().padLeft(2, '0')}' &&
            row[1].toString() == appt.startTime &&
            row[3].toString() == appt.clientName) {
          rowIdx = i + 1; // 1-indexed
          break;
        }
      }

      if (rowIdx == null) return false;

      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [[newStatus]]),
        sid, '$_apptTab!F$rowIdx',
        valueInputOption: 'RAW',
      );

      // Update local cache
      final idx = _appointments.indexWhere((a) =>
          a.date == appt.date && a.startTime == appt.startTime && a.clientName == appt.clientName);
      if (idx >= 0) {
        _appointments[idx] = Appointment(
          id: appt.id, date: appt.date, startTime: appt.startTime,
          endTime: appt.endTime, clientName: appt.clientName,
          clientPhone: appt.clientPhone, status: newStatus,
          notes: appt.notes, createdAt: appt.createdAt,
        );
      }

      return true;
    } catch (e) {
      debugPrint('AppointmentService: Update error: $e');
      return false;
    }
  }

  /// Delete an appointment
  static Future<bool> deleteAppointment(Appointment appt) async {
    return updateStatus(appt, 'cancelled');
  }

  // ─── Queries ─────────────────────────────────────────────

  /// Get appointments for a specific date
  static List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments
        .where((a) => a.date.year == date.year && a.date.month == date.month && a.date.day == date.day && a.status != 'cancelled' && a.clientName.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get all dates that have appointments (for calendar dots)
  static Map<DateTime, List<Appointment>> getAppointmentsByDate() {
    final map = <DateTime, List<Appointment>>{};
    for (final a in _appointments) {
      if (a.status == 'cancelled' || a.clientName.trim().isEmpty) continue;
      final key = DateTime(a.date.year, a.date.month, a.date.day);
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  /// Get available time slots for a specific date
  static List<String> getAvailableSlotsForDate(DateTime date) {
    final dayOfWeek = date.weekday; // 1=Monday, 7=Sunday
    final slot = _availableSlots.firstWhere(
      (s) => s.dayOfWeek == dayOfWeek,
      orElse: () => AvailableSlot(dayOfWeek: dayOfWeek, startTime: '', endTime: '', slotMinutes: 60),
    );

    if (slot.startTime.isEmpty) return []; // Not available this day

    final slots = <String>[];
    final startParts = slot.startTime.split(':');
    final endParts = slot.endTime.split(':');
    int startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // Get already booked slots for this date
    final booked = getAppointmentsForDate(date);
    final bookedTimes = booked.map((a) => a.startTime).toSet();

    while (startMin + slot.slotMinutes <= endMin) {
      final h = (startMin ~/ 60).toString().padLeft(2, '0');
      final m = (startMin % 60).toString().padLeft(2, '0');
      final timeStr = '$h:$m';
      if (!bookedTimes.contains(timeStr)) {
        slots.add(timeStr);
      }
      startMin += slot.slotMinutes;
    }

    return slots;
  }

  // ─── Google Calendar Integration ──────────────────────────

  static Future<void> _createCalendarEvent(Appointment appt) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return;

      final calApi = cal.CalendarApi(client);
      final startParts = appt.startTime.split(':');
      final endParts = appt.endTime.split(':');

      final start = DateTime(appt.date.year, appt.date.month, appt.date.day,
          int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(appt.date.year, appt.date.month, appt.date.day,
          int.parse(endParts[0]), int.parse(endParts[1]));

      final event = cal.Event(
        summary: 'ಜಾತಕ - ${appt.clientName}',
        description: appt.notes.isNotEmpty ? appt.notes : 'ಭಾರತೀಯಮ್ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್\nPhone: ${appt.clientPhone}',
        start: cal.EventDateTime(dateTime: start, timeZone: 'Asia/Kolkata'),
        end: cal.EventDateTime(dateTime: end, timeZone: 'Asia/Kolkata'),
        reminders: cal.EventReminders(
          useDefault: false,
          overrides: [
            cal.EventReminder(method: 'popup', minutes: 30),
            cal.EventReminder(method: 'popup', minutes: 1440), // 24 hours before
          ],
        ),
      );

      await calApi.events.insert(event, 'primary');
      debugPrint('AppointmentService: Calendar event created');
    } catch (e) {
      debugPrint('AppointmentService: Calendar event error: $e');
    }
  }

  // ─── WhatsApp Message Templates ───────────────────────────

  /// Generate WhatsApp confirmation message
  static String confirmationMessage(Appointment appt) {
    return 'ನಮಸ್ಕಾರ ${appt.clientName},\n\n'
        'ನಿಮ್ಮ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ದೃಢಪಡಿಸಲಾಗಿದೆ ✅\n\n'
        '📅 ದಿನಾಂಕ: ${appt.dateStr}\n'
        '⏰ ಸಮಯ: ${appt.timeRange}\n\n'
        'ದಯವಿಟ್ಟು ಸಮಯಕ್ಕೆ ಸರಿಯಾಗಿ ಬನ್ನಿ.\n\n'
        '- ಭಾರತೀಯಮ್ ✨';
  }

  /// Generate WhatsApp reminder message
  static String reminderMessage(Appointment appt) {
    return 'ನಮಸ್ಕಾರ ${appt.clientName},\n\n'
        'ನಿಮ್ಮ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ನಾಳೆಯ ಜ್ಞಾಪನೆ 🔔\n\n'
        '📅 ದಿನಾಂಕ: ${appt.dateStr}\n'
        '⏰ ಸಮಯ: ${appt.timeRange}\n\n'
        'ದಯವಿಟ್ಟು ಸಮಯಕ್ಕೆ ಸರಿಯಾಗಿ ಬನ್ನಿ.\n\n'
        '- ಭಾರತೀಯಮ್ ✨';
  }

  /// Generate available slots message to share with clients
  static String availableSlotsMessage(DateTime date) {
    final slots = getAvailableSlotsForDate(date);
    if (slots.isEmpty) return 'ಈ ದಿನಾಂಕದಲ್ಲಿ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ.';

    final dateStr = '${date.day}/${date.month}/${date.year}';
    final slotStr = slots.map((s) {
      final parts = s.split(':');
      final h = int.parse(parts[0]);
      final amPm = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '  ⏰ $h12:${parts[1]} $amPm';
    }).join('\n');

    return 'ನಮಸ್ಕಾರ,\n\n'
        '📅 $dateStr ದಿನಾಂಕದಲ್ಲಿ ಲಭ್ಯವಿರುವ ಸ್ಲಾಟ್‌ಗಳು:\n\n'
        '$slotStr\n\n'
        'ಬುಕ್ ಮಾಡಲು ದಯವಿಟ್ಟು ಸಂಪರ್ಕಿಸಿ.\n\n'
        '- ಭಾರತೀಯಮ್ ✨';
  }

  /// Generate a full weekly/monthly calendar of available slots for sharing
  /// [days] = how many days ahead to include (7 for week, 30 for month)
  static String weeklyCalendarMessage({int days = 7}) {
    const dayNames = ['ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ', 'ರವಿವಾರ'];
    const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];

    final today = DateTime.now();
    final buf = StringBuffer();

    buf.writeln('🙏 *ಭಾರತೀಯಮ್ - ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಕ್ಯಾಲೆಂಡರ್*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('');
    buf.writeln('ಕೆಳಗಿನ ದಿನಾಂಕಗಳಲ್ಲಿ ಲಭ್ಯವಿರುವ ಸಮಯಗಳನ್ನು ನೋಡಿ.');
    buf.writeln('ನಿಮಗೆ ಬೇಕಾದ ದಿನಾಂಕ ಮತ್ತು ಸಮಯವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ ಉತ್ತರಿಸಿ.');
    buf.writeln('');

    bool anySlots = false;
    for (int i = 1; i <= days; i++) {
      final date = today.add(Duration(days: i));
      final slots = getAvailableSlotsForDate(date);
      if (slots.isEmpty) continue;

      anySlots = true;
      final dayName = dayNames[date.weekday - 1];
      final monthName = months[date.month - 1];

      buf.writeln('📅 *${date.day} $monthName ($dayName)*');
      for (final s in slots) {
        final parts = s.split(':');
        final h = int.parse(parts[0]);
        final amPm = h >= 12 ? 'PM' : 'AM';
        final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        buf.writeln('   ⏰ $h12:${parts[1]} $amPm');
      }
      buf.writeln('');
    }

    if (!anySlots) {
      buf.writeln('❌ ಮುಂದಿನ $days ದಿನಗಳಲ್ಲಿ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ.');
    }

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('ಬುಕ್ ಮಾಡಲು: ನಿಮ್ಮ ಹೆಸರು, ಫೋನ್ ಸಂಖ್ಯೆ, ಮತ್ತು ಬೇಕಾದ ದಿನಾಂಕ+ಸಮಯವನ್ನು ಕಳುಹಿಸಿ.');
    buf.writeln('');
    buf.writeln('- *ಭಾರತೀಯಮ್* ✨');

    return buf.toString();
  }

  /// Generate calendar message for a custom date+time range
  static String customCalendarMessage({
    required DateTime fromDate,
    required DateTime toDate,
    required int fromHour,
    required int fromMinute,
    required int toHour,
    required int toMinute,
  }) {
    const dayNames = ['ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', 'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ', 'ರವಿವಾರ'];
    const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];

    final customFromMin = fromHour * 60 + fromMinute;
    final customToMin = toHour * 60 + toMinute;

    final buf = StringBuffer();
    buf.writeln('🙏 *ಭಾರತೀಯಮ್ - ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಕ್ಯಾಲೆಂಡರ್*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('');

    // Format time range for header
    String _fmt(int h, int m) {
      final amPm = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$h12:${m.toString().padLeft(2, '0')} $amPm';
    }

    buf.writeln('⏰ ಸಮಯ: ${_fmt(fromHour, fromMinute)} - ${_fmt(toHour, toMinute)}');
    buf.writeln('ನಿಮಗೆ ಬೇಕಾದ ಸ್ಲಾಟ್ ಆಯ್ಕೆ ಮಾಡಿ ಉತ್ತರಿಸಿ.');
    buf.writeln('');

    bool anySlots = false;
    DateTime current = fromDate;
    while (!current.isAfter(toDate)) {
      final allSlots = getAvailableSlotsForDate(current);
      // Filter slots within the custom time window
      final filtered = allSlots.where((s) {
        final parts = s.split(':');
        final slotMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        return slotMin >= customFromMin && slotMin < customToMin;
      }).toList();

      if (filtered.isNotEmpty) {
        anySlots = true;
        final dayName = dayNames[current.weekday - 1];
        final monthName = months[current.month - 1];
        buf.writeln('📅 *${current.day} $monthName ($dayName)*');
        for (final s in filtered) {
          final parts = s.split(':');
          final h = int.parse(parts[0]);
          final amPm = h >= 12 ? 'PM' : 'AM';
          final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
          buf.writeln('   ⏰ $h12:${parts[1]} $amPm  ☐');
        }
        buf.writeln('');
      }
      current = current.add(const Duration(days: 1));
    }

    if (!anySlots) {
      buf.writeln('❌ ಈ ಅವಧಿಯಲ್ಲಿ ಯಾವುದೇ ಸ್ಲಾಟ್ ಲಭ್ಯವಿಲ್ಲ.');
    }

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*ಬುಕ್ ಮಾಡಲು:*');
    buf.writeln('✅ ನಿಮಗೆ ಬೇಕಾದ ಸ್ಲಾಟ್ ಆಯ್ಕೆ ಮಾಡಿ');
    buf.writeln('✅ ನಿಮ್ಮ ಹೆಸರು ಮತ್ತು ಫೋನ್ ಸಂಖ್ಯೆ ಕಳುಹಿಸಿ');
    buf.writeln('');
    buf.writeln('- *ಭಾರತೀಯಮ್* ✨');

    return buf.toString();
  }

  /// Generate a booking page URL with available slots encoded in the hash
  /// The URL points to the GitHub Pages booking page (docs/booking.html)
  static String generateBookingPageUrl({
    required DateTime fromDate,
    required DateTime toDate,
    required int fromHour,
    required int fromMinute,
    required int toHour,
    required int toMinute,
  }) {
    final customFromMin = fromHour * 60 + fromMinute;
    final customToMin = toHour * 60 + toMinute;

    // Build slots map: { "2026-03-24": ["09:00", "10:00", ...], ... }
    final slotsMap = <String, List<String>>{};
    int slotDuration = 60; // default
    DateTime current = fromDate;
    while (!current.isAfter(toDate)) {
      final allSlots = getAvailableSlotsForDate(current);
      final filtered = allSlots.where((s) {
        final parts = s.split(':');
        final slotMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        return slotMin >= customFromMin && slotMin < customToMin;
      }).toList();

      if (filtered.isNotEmpty) {
        final dateKey = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
        slotsMap[dateKey] = filtered;
        // Get slot duration from config
        final daySlot = _availableSlots.firstWhere(
          (s) => s.dayOfWeek == current.weekday,
          orElse: () => AvailableSlot(dayOfWeek: 1, startTime: '09:00', endTime: '17:00', slotMinutes: 60),
        );
        slotDuration = daySlot.slotMinutes;
      }
      current = current.add(const Duration(days: 1));
    }

    // Include astrologer's Google email so clients can send calendar invitation
    final email = GoogleAuthService.userEmail ?? '';

    // Encode as JSON in URL hash
    final jsonStr = '{"slots":${_slotsToJson(slotsMap)},"email":"$email","slotMin":$slotDuration}';
    final encoded = Uri.encodeComponent(jsonStr);

    return 'https://goureesha.github.io/bharatheeyamapp/booking.html#$encoded';
  }

  /// Simple JSON serialization for slots map
  static String _slotsToJson(Map<String, List<String>> slots) {
    final entries = slots.entries.map((e) {
      final times = e.value.map((t) => '"$t"').join(',');
      return '"${e.key}":[$times]';
    }).join(',');
    return '{$entries}';
  }

  /// Clear all cached data
  static void clearCache() {
    _appointments.clear();
    _availableSlots.clear();
    _isLoaded = false;
  }
}
