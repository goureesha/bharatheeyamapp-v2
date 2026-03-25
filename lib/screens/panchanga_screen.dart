import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/events.dart';
import '../services/festival_cache_service.dart';
import '../services/location_service.dart';
import 'package:table_calendar/table_calendar.dart';


class PanchangaScreen extends StatefulWidget {
  const PanchangaScreen({super.key});

  @override
  State<PanchangaScreen> createState() => _PanchangaScreenState();
}

class _PanchangaScreenState extends State<PanchangaScreen> {
  DateTime _selectedDate = DateTime.now();

  PanchangData? _panchang;
  bool _loading = false;

  // Default location from settings
  double get _lat => LocationService.lat;
  double get _lon => LocationService.lon;
  String get _place => LocationService.place;

  DateTime _focusedDay = DateTime.now();

  // Events for current selected day
  List<AstroEvent> _currentEvents = [];

  // Debounce timer for month-change swipe
  Timer? _monthDebounce;

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void dispose() {
    _monthDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initLoad() async {
    await _calcPanchang();
    // If cache not loaded yet for this year, load the current month quickly
    if (!FestivalCacheService.isLoaded) {
      await FestivalCacheService.loadMonth(_focusedDay.year, _focusedDay.month);
      if (mounted) setState(() {});
    }
  }

  List<AstroEvent> _getEventsForDay(DateTime day) {
    return FestivalCacheService.getEventsForDate(day);
  }

  Future<void> _calcPanchang() async {
    setState(() => _loading = true);

    try {
      const hour24 = 6.0; // Fixed sunrise time for festival calculation
      final result = await AstroCalculator.calculate(
        year: _selectedDate.year, month: _selectedDate.month, day: _selectedDate.day,
        hourUtcOffset: LocationService.tzOffset,
        hour24: hour24,
        lat: _lat, lon: _lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );

      if (result != null && mounted) {
        final events = FestivalCacheService.getEventsForDate(_selectedDate);
        // If cache miss, compute from panchang
        final finalEvents = events.isNotEmpty ? events : EventCalculator.getEventsForPanchang(result.panchang);
        setState(() {
          _panchang = result.panchang;
          _currentEvents = finalEvents;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Parse sunrise/sunset string "HH:MM AM/PM" to minutes from midnight ───
  double _parseTimeToMinutes(String timeStr) {
    try {
      final upper = timeStr.toUpperCase().trim();
      final isPM = upper.contains('PM');
      final isAM = upper.contains('AM');
      // Remove AM/PM suffix
      final cleaned = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0].trim());
        final m = int.parse(parts[1].trim());
        if (isPM || isAM) {
          // 12-hour format
          if (isPM && h != 12) h += 12;
          if (isAM && h == 12) h = 0;
        }
        return h * 60.0 + m;
      }
    } catch (_) {}
    return 0;
  }

  String _minutesToTimeStr(double mins) {
    final totalMins = mins.round();
    final h = (totalMins ~/ 60) % 24;
    final m = totalMins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  // ─── Day of week from Panchanga Vara: 0=Sun, 1=Mon, ..., 6=Sat ───
  // Vedic Vara changes at sunrise, not midnight — so use the computed Vara name
  static const _varaMap = {
    'ಭಾನುವಾರ': 0, 'ಸೋಮವಾರ': 1, 'ಮಂಗಳವಾರ': 2, 'ಬುಧವಾರ': 3,
    'ಗುರುವಾರ': 4, 'ಶುಕ್ರವಾರ': 5, 'ಶನಿವಾರ': 6,
    // Hindi
    'रविवार': 0, 'सोमवार': 1, 'मंगलवार': 2, 'बुधवार': 3,
    'गुरुवार': 4, 'शुक्रवार': 5, 'शनिवार': 6,
    // English fallback
    'Sunday': 0, 'Monday': 1, 'Tuesday': 2, 'Wednesday': 3,
    'Thursday': 4, 'Friday': 5, 'Saturday': 6,
  };
  int get _weekday {
    if (_panchang != null) {
      final vara = _panchang!.vara.trim();
      // Try exact match first
      if (_varaMap.containsKey(vara)) return _varaMap[vara]!;
      // Try partial match (vara name might have extra text)
      for (final entry in _varaMap.entries) {
        if (vara.contains(entry.key) || entry.key.contains(vara)) return entry.value;
      }
    }
    // Fallback to calendar weekday
    return _selectedDate.weekday % 7;
  }

  // ─── Rahu Kala, Yamaganda, Gulika Kala ───
  // Each day has 8 muhurtas in daytime. Rahu Kala falls on specific muhurta per weekday.
  // Order: Sun=8,Mon=2,Tue=7,Wed=5,Thu=6,Fri=4,Sat=3 (muhurta # starting from 1)
  static const _rahuKalaMuhurta   = [8, 2, 7, 5, 6, 4, 3]; // Sun..Sat
  static const _yamagandaMuhurta  = [5, 4, 3, 6, 5, 1, 2]; // Sun..Sat (traditional)
  static const _gulikaKalaMuhurta = [7, 6, 5, 4, 3, 2, 1]; // Sun..Sat (traditional)

  Map<String, String> _calcKalaTime(List<int> muhurtaList) {
    if (_panchang == null) return {'start': '--', 'end': '--'};
    final sr = _parseTimeToMinutes(_panchang!.sunrise);
    final ss = _parseTimeToMinutes(_panchang!.sunset);
    final dayDuration = ss - sr;
    final muhurtaDuration = dayDuration / 8.0;
    final muhurtaIndex = muhurtaList[_weekday] - 1; // 0-based
    final start = sr + muhurtaIndex * muhurtaDuration;
    final end = start + muhurtaDuration;
    return {'start': _minutesToTimeStr(start), 'end': _minutesToTimeStr(end)};
  }

  // ─── Chougadiya (Gauri Panchanga) ───
  // 8 day periods + 8 night periods. Each named after: Udveg, Char, Laabh, Amrut, Kaala, Shubh, Rog
  // Day sequence by weekday, Night sequence follows after
  static const _chougNames = ['ಉದ್ವೇಗ', 'ಚಲ', 'ಲಾಭ', 'ಅಮೃತ', 'ಕಾಲ', 'ಶುಭ', 'ರೋಗ'];
  static const _chougNature = ['⚠️', '⬆️', '✅', '🏆', '❌', '✅', '⚠️'];
  // Starting Chougadiya for each weekday (day): Sun=Udveg(0), Mon=Amrut(3), Tue=Rog(6), Wed=Laabh(2), Thu=Shubh(5), Fri=Chal(1), Sat=Kaal(4)
  static const _chougDayStart   = [0, 3, 6, 2, 5, 1, 4]; // Sun..Sat
  static const _chougNightStart = [5, 1, 4, 0, 3, 6, 2]; // Sun..Sat

  List<Map<String, String>> _calcChougadiya(bool isDay) {
    if (_panchang == null) return [];
    final sr = _parseTimeToMinutes(_panchang!.sunrise);
    final ss = _parseTimeToMinutes(_panchang!.sunset);
    final double periodStart;
    final double periodEnd;
    final int startIdx;

    if (isDay) {
      periodStart = sr;
      periodEnd = ss;
      startIdx = _chougDayStart[_weekday];
    } else {
      periodStart = ss;
      periodEnd = sr + 24 * 60; // next sunrise
      startIdx = _chougNightStart[_weekday];
    }

    final duration = (periodEnd - periodStart) / 8.0;
    final List<Map<String, String>> result = [];
    for (int i = 0; i < 8; i++) {
      final idx = (startIdx + i) % 7;
      final s = periodStart + i * duration;
      final e = s + duration;
      result.add({
        'name': _chougNames[idx],
        'nature': _chougNature[idx],
        'start': _minutesToTimeStr(s % (24 * 60)),
        'end': _minutesToTimeStr(e % (24 * 60)),
      });
    }
    return result;
  }

  // ─── Hora (Planetary Hours) ───
  // Planet order for Hora: Sun, Venus, Mercury, Moon, Saturn, Jupiter, Mars
  // The first Hora of a day belongs to the weekday ruler
  static const _horaOrder = ['ಸೂರ್ಯ', 'ಶುಕ್ರ', 'ಬುಧ', 'ಚಂದ್ರ', 'ಶನಿ', 'ಗುರು', 'ಮಂಗಳ'];
  static const _horaIcons = ['☀️', '♀️', '☿️', '🌙', '🪐', '♃', '♂️'];
  // Weekday ruler index in _horaOrder: Sun=0, Mon=3, Tue=6, Wed=2, Thu=5, Fri=1, Sat=4
  static const _weekdayHoraStart = [0, 3, 6, 2, 5, 1, 4]; // Sun..Sat

  List<Map<String, String>> _calcHora(bool isDay) {
    if (_panchang == null) return [];
    final sr = _parseTimeToMinutes(_panchang!.sunrise);
    final ss = _parseTimeToMinutes(_panchang!.sunset);
    final double periodStart;
    final double periodEnd;

    if (isDay) {
      periodStart = sr;
      periodEnd = ss;
    } else {
      periodStart = ss;
      periodEnd = sr + 24 * 60;
    }

    final duration = (periodEnd - periodStart) / 12.0;
    // Day starts at weekday ruler, night continues from where day left off
    final startOffset = _weekdayHoraStart[_weekday] + (isDay ? 0 : 12);
    final List<Map<String, String>> result = [];
    for (int i = 0; i < 12; i++) {
      final idx = (startOffset + i) % 7;
      final s = periodStart + i * duration;
      final e = s + duration;
      result.add({
        'planet': _horaOrder[idx],
        'icon': _horaIcons[idx],
        'start': _minutesToTimeStr(s % (24 * 60)),
        'end': _minutesToTimeStr(e % (24 * 60)),
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year}';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಪಂಚಾಂಗ / Panchanga',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ResponsiveCenter(child: Column(
                children: [
                  // Calendar Card
                  AppCard(
                    child: Column(children: [
                      Row(children: [
                        Icon(Icons.calendar_month, color: kPurple2, size: 20),
                        const SizedBox(width: 8),
                        Text('ದಿನಾಂಕ ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime.now();
                            });
                            _calcPanchang();
                          },
                          icon: Icon(Icons.today, size: 16),
                          label: Text('ಇಂದು', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(12),
                          color: kBg,
                        ),
                        child: TableCalendar<AstroEvent>(
                          firstDay: DateTime.utc(1800, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          currentDay: DateTime.now(),
                          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                          calendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                          eventLoader: _getEventsForDay,
                          startingDayOfWeek: StartingDayOfWeek.sunday,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDate = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _calcPanchang();
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                            // Debounce: wait 300ms after swipe stops before computing
                            _monthDebounce?.cancel();
                            _monthDebounce = Timer(const Duration(milliseconds: 300), () {
                              FestivalCacheService.loadMonth(focusedDay.year, focusedDay.month).then((_) {
                                if (mounted) setState(() {});
                              });
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: kPurple2.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: kPurple2,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonVisible: false,
                            titleTextStyle: TextStyle(color: kPurple2, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: kText, fontWeight: FontWeight.bold),
                            weekendStyle: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ]),
                  ),


                  // Date & Place info
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _kv('ಸ್ಥಳ', _place),
                    _kv('ದಿನಾಂಕ', dateStr),
                  ])),

                  // Events Card - ALWAYS show events for the selected day
                  if (_currentEvents.isNotEmpty)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.festival, color: Colors.green, size: 22),
                              const SizedBox(width: 8),
                              Expanded(child: Text('ಹಬ್ಬಗಳು ಮತ್ತು ವಿಶೇಷ ದಿನಗಳು', 
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._currentEvents.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPurple2)),
                                  const SizedBox(height: 4),
                                  Text(e.description, style: TextStyle(color: kText, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('- ಆಕರ: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      Flexible(child: Text(e.source, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPurple2))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ],
                      ),
                    ),

                  // Loading or Panchanga data
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: kPurple2),
                    )
                  else if (_panchang != null) ...[
                    // ═══  Main Panchanga Table ═══
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _tableRow(['ಸಂವತ್ಸರ', _panchang!.samvatsara]),
                        _tableRow(['ಋತು', _panchang!.rutu]),
                        _tableRow(['ವಾರ', _panchang!.vara]),
                        _tableRow(['ತಿಥಿ', _formatEnd(_panchang!.tithi, _panchang!.tithiEndTime, _panchang!.tithiEndsNextDay)]),
                        _tableRow(['ಚಂದ್ರ ನಕ್ಷತ್ರ', _formatEnd(_panchang!.nakshatra, _panchang!.nakEndTime, _panchang!.nakEndsNextDay)]),
                        _tableRow(['ಯೋಗ', _formatEnd(_panchang!.yoga, _panchang!.yogaEndTime, _panchang!.yogaEndsNextDay)]),
                        _tableRow(['ಕರಣ', _formatEnd(_panchang!.karana, _panchang!.karanaEndTime, _panchang!.karanaEndsNextDay)]),
                        _tableRow(['ಚಂದ್ರ ರಾಶಿ', _panchang!.chandraRashi]),
                        _tableRow(['ಚಂದ್ರ ಮಾಸ', _panchang!.chandraMasa]),
                        _tableRow(['ಸೂರ್ಯ ನಕ್ಷತ್ರ', '${_panchang!.suryaNakshatra} - ಪಾದ ${_panchang!.suryaPada}']),
                        _tableRow(['ಸೌರ ಮಾಸ', _panchang!.souraMasa]),
                        _tableRow(['ಸೌರ ಮಾಸ ಗತ ದಿನ', _panchang!.souraMasaGataDina]),
                        _tableRow(['ಸೂರ್ಯೋದಯ', _panchang!.sunrise]),
                        _tableRow(['ಸೂರ್ಯಾಸ್ತ', _panchang!.sunset]),
                        _tableRow(['ಹಗಲಿನ ಪ್ರಮಾಣ', _panchang!.divamana]),
                        _tableRow(['ರಾತ್ರಿಯ ಪ್ರಮಾಣ', _panchang!.ratrimana]),
                        _tableRow(['ಪರಮ ಘಟಿ', _panchang!.paramaGhati]),
                        _tableRow(['ವಿಷ ಪ್ರಘಟಿ', _panchang!.vishaPraghati]),
                        _tableRow(['ಅಮೃತ ಪ್ರಘಟಿ', _panchang!.amrutaPraghati]),
                      ]),
                    ),

                    // ═══ Rahu Kala / Yamaganda / Gulika ═══
                    _buildKalaCard(),

                    // ═══ Chougadiya (Day) ═══
                    _buildChougadiyaCard(true),

                    // ═══ Chougadiya (Night) ═══
                    _buildChougadiyaCard(false),

                    // ═══ Hora (Day) ═══
                    _buildHoraCard(true),

                    // ═══ Hora (Night) ═══
                    _buildHoraCard(false),
                  ],
                  const SizedBox(height: 24),
                ],
              )),
            ),
          ),

        ],
      ),
    );
  }

  // ─── Rahu Kala / Yamaganda / Gulika Card ───
  Widget _buildKalaCard() {
    final rahu = _calcKalaTime(_rahuKalaMuhurta);
    final yama = _calcKalaTime(_yamagandaMuhurta);
    final gulika = _calcKalaTime(_gulikaKalaMuhurta);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
          const SizedBox(width: 8),
          Text('ಅಶುಭ ಕಾಲ / Inauspicious Periods', style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red)),
        ]),
        const SizedBox(height: 12),
        _kalaRow('ರಾಹು ಕಾಲ', rahu['start']!, rahu['end']!, Colors.red),
        _kalaRow('ಯಮಗಂಡ ಕಾಲ', yama['start']!, yama['end']!, Colors.orange),
        _kalaRow('ಗುಳಿಕ ಕಾಲ', gulika['start']!, gulika['end']!, Colors.deepOrange),
      ]),
    );
  }

  Widget _kalaRow(String name, String start, String end, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(width: 4, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text('$start - $end', style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
        ),
      ]),
    );
  }

  // ─── Chougadiya Card ───
  Widget _buildChougadiyaCard(bool isDay) {
    final items = _calcChougadiya(isDay);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isDay ? Icons.wb_sunny : Icons.nightlight_round,
            color: isDay ? kOrange : kPurple2, size: 22),
          const SizedBox(width: 8),
          Text(isDay ? 'ಹಗಲಿನ ಚೌಘಡಿಯಾ / Day Chougadiya' : 'ರಾತ್ರಿ ಚೌಘಡಿಯಾ / Night Chougadiya',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDay ? kOrange : kPurple2)),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _chougColor(item['nature']!).withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _chougColor(item['nature']!).withOpacity(0.2)),
          ),
          child: Row(children: [
            Text(item['nature']!, style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(item['name']!, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13))),
            Text('${item['start']} - ${item['end']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
          ]),
        )),
      ]),
    );
  }

  Color _chougColor(String nature) {
    switch (nature) {
      case '🏆': return Colors.green;
      case '✅': return Colors.teal;
      case '⬆️': return Colors.blue;
      case '⚠️': return kOrange;
      case '❌': return Colors.red;
      default: return kMuted;
    }
  }

  // ─── Hora Card ───
  Widget _buildHoraCard(bool isDay) {
    final items = _calcHora(isDay);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isDay ? Icons.access_time : Icons.access_time_filled,
            color: isDay ? kTeal : kPurple1, size: 22),
          const SizedBox(width: 8),
          Text(isDay ? 'ಹಗಲಿನ ಹೋರಾ / Day Hora' : 'ರಾತ್ರಿ ಹೋರಾ / Night Hora',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDay ? kTeal : kPurple1)),
        ]),
        const SizedBox(height: 10),
        ...items.map((item) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: kBorder.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Text(item['icon']!, style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(item['planet']!, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13))),
            Text('${item['start']} - ${item['end']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
          ]),
        )),
      ]),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple2)),
        Expanded(child: Text(v, style: TextStyle(color: kText))),
      ]),
    );
  }

  String _formatEnd(String base, String endTime, bool nextDay) {
    if (endTime.isEmpty) return base;
    return '$base (ಅಂತ್ಯ: $endTime${nextDay ? ' ಮುಂದಿನ ದಿನ' : ''})';
  }

  Widget _tableRow(List<String> cols) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: e.key == 0 ? FontWeight.w700 : FontWeight.normal,
                color: kText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )).toList(),
      ),
    );
  }
}
