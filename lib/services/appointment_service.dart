import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/calendar/v3.dart' as cal;
import 'google_auth_service.dart';

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
  });

  /// Parse from sheet row [date, startTime, endTime, clientName, phone, status, notes, createdAt]
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
    );
  }

  List<Object> toRow() => [
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    startTime, endTime, clientName, clientPhone, status, notes, createdAt,
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
        sheets.ValueRange(values: [['Date', 'Start', 'End', 'Client', 'Phone', 'Status', 'Notes', 'CreatedAt']]),
        id, '$_apptTab!A1:H1',
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

      // Load appointments
      final apptResp = await api.spreadsheets.values.get(sid, '$_apptTab!A:H');
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

      _isLoaded = true;
      debugPrint('AppointmentService: Loaded ${_appointments.length} appointments, ${_availableSlots.length} slots');
    } catch (e) {
      debugPrint('AppointmentService: Load error: $e');
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
      );

      await api.spreadsheets.values.append(
        sheets.ValueRange(values: [appointment.toRow()]),
        sid, '$_apptTab!A:H',
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
      final apptResp = await api.spreadsheets.values.get(sid, '$_apptTab!A:H');
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
        .where((a) => a.date.year == date.year && a.date.month == date.month && a.date.day == date.day && a.status != 'cancelled')
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get all dates that have appointments (for calendar dots)
  static Map<DateTime, List<Appointment>> getAppointmentsByDate() {
    final map = <DateTime, List<Appointment>>{};
    for (final a in _appointments) {
      if (a.status == 'cancelled') continue;
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

  /// Create Google Calendar events as bookable time blocks and return the calendar share link
  static Future<String?> createGoogleCalendarBookingLink({
    required DateTime fromDate,
    required DateTime toDate,
    required String fromTime,
    required String toTime,
  }) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return null;

      final calApi = cal.CalendarApi(client);
      final fromParts = fromTime.split(':');
      final toParts = toTime.split(':');
      final fromHour = int.parse(fromParts[0]);
      final fromMinute = int.parse(fromParts[1]);
      final toHour = int.parse(toParts[0]);
      final toMinute = int.parse(toParts[1]);

      DateTime current = fromDate;
      int slotCount = 0;

      while (!current.isAfter(toDate)) {
        final allSlots = getAvailableSlotsForDate(current);
        final customFromMin = fromHour * 60 + fromMinute;
        final customToMin = toHour * 60 + toMinute;

        final filtered = allSlots.where((s) {
          final parts = s.split(':');
          final slotMin = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          return slotMin >= customFromMin && slotMin < customToMin;
        }).toList();

        for (final slot in filtered) {
          final sParts = slot.split(':');
          final sH = int.parse(sParts[0]);
          final sM = int.parse(sParts[1]);

          // Find slot duration
          final daySlot = _availableSlots.firstWhere(
            (s) => s.dayOfWeek == current.weekday,
            orElse: () => AvailableSlot(dayOfWeek: 1, startTime: '09:00', endTime: '17:00', slotMinutes: 60),
          );
          final endTotal = sH * 60 + sM + daySlot.slotMinutes;
          final eH = endTotal ~/ 60;
          final eM = endTotal % 60;

          final start = DateTime(current.year, current.month, current.day, sH, sM);
          final end = DateTime(current.year, current.month, current.day, eH, eM);

          final event = cal.Event(
            summary: '🟢 ಲಭ್ಯ - ಜಾತಕ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್',
            description: 'ಈ ಸಮಯ ಲಭ್ಯವಿದೆ. ಬುಕ್ ಮಾಡಲು ಸಂಪರ್ಕಿಸಿ.\n\nThis slot is available for booking.',
            start: cal.EventDateTime(dateTime: start, timeZone: 'Asia/Kolkata'),
            end: cal.EventDateTime(dateTime: end, timeZone: 'Asia/Kolkata'),
            transparency: 'transparent', // Shows as "free" in calendar
            status: 'tentative',
          );

          await calApi.events.insert(event, 'primary');
          slotCount++;
        }
        current = current.add(const Duration(days: 1));
      }

      if (slotCount == 0) return null;

      // Get the calendar's share link
      final calendarId = 'primary';
      final calendar = await calApi.calendars.get(calendarId);

      // Make calendar public for viewing
      try {
        await calApi.acl.insert(
          cal.AclRule(
            scope: cal.AclRuleScope(type: 'default'),
            role: 'reader',
          ),
          calendarId,
        );
      } catch (_) {
        // Already public or permission denied — that's ok
      }

      final email = GoogleAuthService.userEmail ?? '';
      // Google Calendar embed URL for sharing
      final shareLink = 'https://calendar.google.com/calendar/embed?src=${Uri.encodeComponent(email)}&mode=WEEK';

      debugPrint('AppointmentService: Created $slotCount available slot events');
      return shareLink;
    } catch (e) {
      debugPrint('AppointmentService: Google Calendar booking error: $e');
      return null;
    }
  }

  /// Clear all cached data
  static void clearCache() {
    _appointments.clear();
    _availableSlots.clear();
    _isLoaded = false;
  }
}
