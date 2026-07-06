import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'client_service.dart';
import '../widgets/common.dart';

/// Appointment data model
class Appointment {
  final String id; // row index
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

  /// Parse from tab-separated cached row
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
      id: '${rowIndex + 1}',
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

/// Manages appointments using LOCAL SharedPreferences cache.
/// Google Sheets and Calendar sync have been removed (sensitive scopes).
class AppointmentService {
  // In-memory cache
  static List<Appointment> _appointments = [];
  static List<AvailableSlot> _availableSlots = [];
  static bool _isLoaded = false;

  static List<Appointment> get appointments => _appointments;
  static List<AvailableSlot> get availableSlots => _availableSlots;
  static bool get isLoaded => _isLoaded;
  
  // Notifier to rebuild UI when background sync happens
  static final ValueNotifier<int> updateNotifier = ValueNotifier(0);

  // ─── Load / Save (Local Cache) ───────────────────────────

  /// Load from local cache instantly (no network)
  static Future<void> loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAppts = prefs.getStringList('cached_appointments') ?? [];
      final cachedSlots = prefs.getStringList('cached_slots') ?? [];

      if (cachedAppts.isNotEmpty) {
        _appointments = [];
        for (int i = 0; i < cachedAppts.length; i++) {
          final parts = cachedAppts[i].split('\t');
          if (parts.length >= 9) {
            _appointments.add(Appointment.fromRow(i + 1, parts));
          }
        }
        _isLoaded = true;
      }

      if (cachedSlots.isNotEmpty) {
        _availableSlots = [];
        for (final s in cachedSlots) {
          final parts = s.split('\t');
          if (parts.isEmpty) continue;
          _availableSlots.add(AvailableSlot(
            dayOfWeek: int.tryParse(parts[0]) ?? 1,
            startTime: parts.length > 1 ? parts[1] : '09:00',
            endTime: parts.length > 2 ? parts[2] : '17:00',
            slotMinutes: parts.length > 3 ? (int.tryParse(parts[3]) ?? 60) : 60,
          ));
        }
      }

      // Initialize default slots if none exist
      if (_availableSlots.isEmpty) {
        for (int d = 1; d <= 6; d++) {
          _availableSlots.add(AvailableSlot(
            dayOfWeek: d, startTime: '09:00', endTime: '17:00', slotMinutes: 60,
          ));
        }
        await _saveToCache();
      }

      debugPrint('AppointmentService: Loaded ${_appointments.length} from cache');
    } catch (e) {
      debugPrint('AppointmentService: Cache load error: $e');
    }
  }

  /// Save current data to local cache
  static Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apptStrings = _appointments.map((a) => a.toRow().join('\t')).toList();
      await prefs.setStringList('cached_appointments', apptStrings);

      final slotStrings = _availableSlots.map((s) =>
        '${s.dayOfWeek}\t${s.startTime}\t${s.endTime}\t${s.slotMinutes}'
      ).toList();
      await prefs.setStringList('cached_slots', slotStrings);
    } catch (e) {
      debugPrint('AppointmentService: Cache save error: $e');
    }
  }

  /// Full load — now same as loadFromCache (no Google Sheets sync)
  static Future<void> loadAll() async {
    await loadFromCache();
    _isLoaded = true;
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
        id: '${_appointments.length + 1}',
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

      _appointments.add(appointment);
      await _saveToCache();
      updateNotifier.value++; // Notify listeners

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
      final idx = _appointments.indexWhere((a) =>
          a.date == appt.date && a.startTime == appt.startTime && a.clientName == appt.clientName);
      if (idx >= 0) {
        _appointments[idx] = Appointment(
          id: appt.id, date: appt.date, startTime: appt.startTime,
          endTime: appt.endTime, clientName: appt.clientName,
          clientPhone: appt.clientPhone, status: newStatus,
          notes: appt.notes, createdAt: appt.createdAt, clientId: appt.clientId,
        );
        await _saveToCache();
        return true;
      }
      return false;
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

  // ─── WhatsApp Message Templates ───────────────────────────

  /// Generate WhatsApp confirmation message
  static String confirmationMessage(Appointment appt) {
    final idLine = appt.clientId.isNotEmpty ? '🆔 ${AppLocale.l("waClientId")}: ${appt.clientId}\n' : '';
    return '${AppLocale.l("bookingMsgNamaskara")} ${appt.clientName},\n\n'
        '${AppLocale.l("waConfirmed")}\n\n'
        '📅 ${AppLocale.l("waDate")}: ${appt.dateStr}\n'
        '⏰ ${AppLocale.l("waTime")}: ${appt.timeRange}\n'
        '$idLine\n'
        '${AppLocale.l("waComeOnTime")}\n\n'
        '${AppLocale.l("bookingMsgSign")}';
  }

  /// Generate WhatsApp reminder message
  static String reminderMessage(Appointment appt) {
    final idLine = appt.clientId.isNotEmpty ? '🆔 ${AppLocale.l("waClientId")}: ${appt.clientId}\n' : '';
    return '${AppLocale.l("bookingMsgNamaskara")} ${appt.clientName},\n\n'
        '${AppLocale.l("waReminder")}\n\n'
        '📅 ${AppLocale.l("waDate")}: ${appt.dateStr}\n'
        '⏰ ${AppLocale.l("waTime")}: ${appt.timeRange}\n'
        '$idLine\n'
        '${AppLocale.l("waComeOnTime")}\n\n'
        '${AppLocale.l("bookingMsgSign")}';
  }

  /// Generate available slots message to share with clients
  static String availableSlotsMessage(DateTime date) {
    final slots = getAvailableSlotsForDate(date);
    if (slots.isEmpty) return AppLocale.l('waNoSlots');

    final dateStr = '${date.day}/${date.month}/${date.year}';
    final slotStr = slots.map((s) {
      final parts = s.split(':');
      final h = int.parse(parts[0]);
      final amPm = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '  ⏰ $h12:${parts[1]} $amPm';
    }).join('\n');

    return '${AppLocale.l("bookingMsgNamaskara")}\n\n'
        '📅 $dateStr ${AppLocale.l("waSlotsOn")}\n\n'
        '$slotStr\n\n'
        '${AppLocale.l("waBookContact")}\n\n'
        '${AppLocale.l("bookingMsgSign")}';
  }

  /// Generate a full weekly/monthly calendar of available slots for sharing
  static String weeklyCalendarMessage({int days = 7}) {
    final dayNames = [AppLocale.l('dayFullMon'), AppLocale.l('dayFullTue'), AppLocale.l('dayFullWed'), AppLocale.l('dayFullThu'), AppLocale.l('dayFullFri'), AppLocale.l('dayFullSat'), AppLocale.l('dayFullSun')];
    final months = [AppLocale.l('month0'), AppLocale.l('month1'), AppLocale.l('month2'), AppLocale.l('month3'), AppLocale.l('month4'), AppLocale.l('month5'), AppLocale.l('month6'), AppLocale.l('month7'), AppLocale.l('month8'), AppLocale.l('month9'), AppLocale.l('month10'), AppLocale.l('month11')];

    final today = DateTime.now();
    final buf = StringBuffer();

    buf.writeln('🙏 *${AppLocale.l("waCalTitle")}*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('');
    buf.writeln(AppLocale.l('waCalView'));
    buf.writeln(AppLocale.l('waCalSelect'));
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
      buf.writeln('❌ ${AppLocale.l("waCalNoSlots").replaceAll("{d}", days.toString())}');
    }

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln(AppLocale.l('waCalBook'));
    buf.writeln('');
    buf.writeln('- *${AppLocale.l("bookingMsgSign")}*');

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
    final dayNames = [AppLocale.l('dayFullMon'), AppLocale.l('dayFullTue'), AppLocale.l('dayFullWed'), AppLocale.l('dayFullThu'), AppLocale.l('dayFullFri'), AppLocale.l('dayFullSat'), AppLocale.l('dayFullSun')];
    final months = [AppLocale.l('month0'), AppLocale.l('month1'), AppLocale.l('month2'), AppLocale.l('month3'), AppLocale.l('month4'), AppLocale.l('month5'), AppLocale.l('month6'), AppLocale.l('month7'), AppLocale.l('month8'), AppLocale.l('month9'), AppLocale.l('month10'), AppLocale.l('month11')];

    final customFromMin = fromHour * 60 + fromMinute;
    final customToMin = toHour * 60 + toMinute;

    final buf = StringBuffer();
    buf.writeln('🙏 *${AppLocale.l("waCalTitle")}*');
    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('');

    // Format time range for header
    String _fmt(int h, int m) {
      final amPm = h >= 12 ? 'PM' : 'AM';
      final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      return '$h12:${m.toString().padLeft(2, '0')} $amPm';
    }

    buf.writeln('⏰ ${AppLocale.l("waTime")}: ${_fmt(fromHour, fromMinute)} - ${_fmt(toHour, toMinute)}');
    buf.writeln(AppLocale.l('waCalSlotSel'));
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
      buf.writeln('❌ ${AppLocale.l("waCalNoSlotsP")}');
    }

    buf.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buf.writeln('*${AppLocale.l("waCalBookTo")}*');
    buf.writeln('✅ ${AppLocale.l("waCalSelSlot")}');
    buf.writeln('✅ ${AppLocale.l("waCalSendInfo")}');
    buf.writeln('');
    buf.writeln('- *${AppLocale.l("bookingMsgSign")}*');

    return buf.toString();
  }



  /// Clear all cached data
  static void clearCache() {
    _appointments.clear();
    _availableSlots.clear();
    _isLoaded = false;
  }
}
