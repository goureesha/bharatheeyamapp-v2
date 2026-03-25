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
                  else if (_panchang != null)
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
                        _tableRow(['ಗತ ಘಟಿ', _panchang!.gataGhati]),
                        _tableRow(['ಪರಮ ಘಟಿ', _panchang!.paramaGhati]),
                        _tableRow(['ಶೇಷ ಘಟಿ', _panchang!.shesha]),
                        _tableRow(['ವಿಷ ಪ್ರಘಟಿ', _panchang!.vishaPraghati]),
                        _tableRow(['ಅಮೃತ ಪ್ರಘಟಿ', _panchang!.amrutaPraghati]),
                      ]),
                    ),
                  const SizedBox(height: 24),
                ],
              )),
            ),
          ),

        ],
      ),
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
