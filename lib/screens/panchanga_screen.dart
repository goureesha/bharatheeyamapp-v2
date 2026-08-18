import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../services/location_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sweph/sweph.dart';


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

  List<dynamic> _currentEvents = [];

  // In-memory session cache — computed dates are instant on revisit
  static final Map<String, PanchangData> _panchangCache = {};

  @override
  void initState() {
    super.initState();
    _initLoad();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initLoad() async {
    await _calcPanchang();
  }

  String _cacheKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  Future<void> _calcPanchang() async {
    // Check in-memory cache first (instant — no lag)
    final key = _cacheKey(_selectedDate);
    final cached = _panchangCache[key];
    if (cached != null) {
      setState(() {
        _panchang = cached;
        _currentEvents = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      await Ephemeris.initSweph();
      final srSs = Ephemeris.findSunriseSetForDate(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _lat, _lon, tzOffset: LocationService.tzOffset,
      );
      final srJd = srSs[0];
      final srLocalFrac = ((srJd + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
      final hour24 = (srLocalFrac * 24.0) + (1.0 / 60.0);

      final result = await AstroCalculator.calculate(
        year: _selectedDate.year, month: _selectedDate.month, day: _selectedDate.day,
        hourUtcOffset: LocationService.tzOffset,
        hour24: hour24,
        lat: _lat, lon: _lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );

      if (result != null && mounted) {
        // Store in cache for instant revisit
        _panchangCache[key] = result.panchang;
        setState(() {
          _panchang = result.panchang;
          _currentEvents = [];
          _loading = false;
        });
        // Pre-compute nearby dates in background (no lag on next tap)
        _precomputeNearbyDates();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pre-compute ±3 days around selected date in background
  /// So when user taps nearby dates, they load instantly
  void _precomputeNearbyDates() async {
    for (int offset in [-3, -2, -1, 1, 2, 3]) {
      final d = _selectedDate.add(Duration(days: offset));
      final key = _cacheKey(d);
      if (_panchangCache.containsKey(key)) continue;

      try {
        final srSs = Ephemeris.findSunriseSetForDate(
          d.year, d.month, d.day, _lat, _lon,
          tzOffset: LocationService.tzOffset,
        );
        final srFrac = ((srSs[0] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final h24 = (srFrac * 24.0) + (1.0 / 60.0);

        final result = await AstroCalculator.calculate(
          year: d.year, month: d.month, day: d.day,
          hourUtcOffset: LocationService.tzOffset,
          hour24: h24, lat: _lat, lon: _lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (result != null) {
          _panchangCache[key] = result.panchang;
        }
      } catch (_) {}
      // Yield to UI between each background computation
      await Future.delayed(Duration.zero);
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
    // Tamil
    'ஞாயிறு': 0, 'திங்கள்': 1, 'செவ்வாய்': 2, 'புதன்': 3,
    'வியாழன்': 4, 'வெள்ளி': 5, 'சனி': 6,
    // Telugu
    'ఆదివారం': 0, 'సోమవారం': 1, 'మంగళవారం': 2, 'బుధవారం': 3,
    'గురువారం': 4, 'శుక్రవారం': 5, 'శనివారం': 6,
    // Malayalam
    'ഞായറാഴ്ച': 0, 'തിങ്കളാഴ്ച': 1, 'ചൊവ്വാഴ്ച': 2, 'ബുധനാഴ്ച': 3,
    'വ്യാഴാഴ്ച': 4, 'വെള്ളിയാഴ്ച': 5, 'ശനിയാഴ്ച': 6,
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
  static const _chougKeys = ['choug0', 'choug1', 'choug2', 'choug3', 'choug4', 'choug5', 'choug6'];
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
        'name': AppLocale.l(_chougKeys[idx]),
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
  static const _horaKeys = ['horaSurya', 'horaShukra', 'horaBudha', 'horaChandra', 'horaShani', 'horaGuru', 'horaMangala'];
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
        'planet': AppLocale.l(_horaKeys[idx]),
        'icon': _horaIcons[idx],
        'start': _minutesToTimeStr(s % (24 * 60)),
        'end': _minutesToTimeStr(e % (24 * 60)),
      });
    }
    return result;
  }

  // ─── Agnivasa cache (independent of panchang cache) ───
  final Map<String, bool> _agniVasaCache = {};

  // ─── Check if a day has Agni on Prithvi ───
  bool _isPrithviDay(DateTime day) {
    final key = _cacheKey(day);
    if (_agniVasaCache.containsKey(key)) return _agniVasaCache[key]!;
    try {
      final srSs = Ephemeris.findSunriseSetForDate(
        day.year, day.month, day.day,
        LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
      );
      final srJd = srSs[0];
      final jd = srJd + (1.0 / 1440.0);
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
      final moonPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
      final sunPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
      final tithiIdx = (((moonPos.longitude - sunPos.longitude + 360) % 360) / 12).floor().clamp(0, 29);
      int pyWeekday = day.weekday - 1; // Mon=0..Sun=6
      int wIdx = (pyWeekday + 1) % 7; // Sun=0..Sat=6
      final agniVal = (tithiIdx + wIdx + 3) % 4;
      final isPrithvi = (agniVal == 0 || agniVal == 3);
      _agniVasaCache[key] = isPrithvi;
      return isPrithvi;
    } catch (_) {
      return false;
    }
  }

  // ─── Calendar cell with green dot for Prithvi days ───
  Widget _buildCalendarCell(DateTime day, bool isToday, bool isSelected) {
    final isPrithvi = _isPrithviDay(day);
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected ? kPurple2 : isToday ? kPurple2.withOpacity(0.3) : null,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected ? Colors.white : isToday ? Colors.white : kText,
              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
            ),
          )),
          if (isPrithvi)
            Positioned(
              bottom: 4,
              child: Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Agni Vasa Card ───
  Widget _buildAgniVasaCard() {
    if (_panchang == null) return const SizedBox();
    final agni = _panchang!.agniVasa;
    final isPrithvi = agni.contains('ಭೂಮಿ') || agni.contains('भूमि') || agni.contains('பூமி') || agni.contains('భూమి') || agni.contains('ഭൂമി') || agni.contains('Bhumi');
    final color = isPrithvi ? Colors.green : Colors.red;
    final icon = isPrithvi ? Icons.check_circle : Icons.cancel;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.local_fire_department, color: kOrange, size: 22),
          const SizedBox(width: 8),
          Text(AppLocale.l('agniVasa'), style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 14, color: kOrange)),
        ]),
        const SizedBox(height: 6),
        Text(AppLocale.l('agniVasaDesc'), style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(trAll(agni), style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(
                trAll(_panchang!.agniVasa),
                style: TextStyle(fontSize: 12, color: kMuted),
              ),
            ])),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year}';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text(AppLocale.l('panchanga'),
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
                        Text(AppLocale.l('selectDateLabel'), style: TextStyle(
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
                          label: Text(AppLocale.l('today'), style: TextStyle(fontSize: 12)),
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
                        child: TableCalendar(
                          firstDay: DateTime.utc(1800, 1, 1),
                          lastDay: DateTime.utc(2100, 12, 31),
                          focusedDay: _focusedDay,
                          currentDay: DateTime.now(),
                          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                          calendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
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
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, false, false),
                            todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, true, false),
                            selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, false, true),
                          ),
                        ),
                      ),
                    ]),
                  ),


                  // Date & Place info
                  AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _kv(AppLocale.l('sthala'), _place),
                    _kv(AppLocale.l('dinanka'), dateStr),
                  ])),


                  // Loading or Panchanga data
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: kPurple2),
                    )
                  else if (_panchang != null) ...[
                    // ═══ ಪಂಚಾಂಗ — 5 Core Limbs ═══
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _sectionHeader(Icons.auto_awesome, AppLocale.l('panchanga'), kPurple2),
                        _tableRow([AppLocale.l('tithi'), _formatEnd(trAll(_panchang!.tithi), _panchang!.tithiEndTime, _panchang!.tithiEndsNextDay)]),
                        _tableRow([AppLocale.l('vara'), trAll(_panchang!.vara)]),
                        _tableRow([AppLocale.l('chandraNak'), _formatEnd('${trAll(_panchang!.nakshatra)} - ${AppLocale.l('pada')} ${_chandraPada()}', _panchang!.nakEndTime, _panchang!.nakEndsNextDay)]),
                        _tableRow([AppLocale.l('yoga'), _formatEnd(trAll(_panchang!.yoga), _panchang!.yogaEndTime, _panchang!.yogaEndsNextDay)]),
                        _tableRow([AppLocale.l('karana'), _formatEnd(trAll(_panchang!.karana), _panchang!.karanaEndTime, _panchang!.karanaEndsNextDay)]),
                      ]),
                    ),

                    // ═══ ಸೂರ್ಯ — Sun Details ═══
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _sectionHeader(Icons.wb_sunny, AppLocale.l('surya'), kOrange),
                        _tableRow([AppLocale.l('sunrise'), _panchang!.sunrise]),
                        _tableRow([AppLocale.l('sunset'), _panchang!.sunset]),
                        _tableRow([AppLocale.l('suryaNak'), '${trAll(_panchang!.suryaNakshatra)} - ${AppLocale.l('pada')} ${_panchang!.suryaPada}']),
                        _tableRow([AppLocale.l('souraMasa'), trAll(_panchang!.souraMasa)]),
                        _tableRow([AppLocale.l('souraMasaGataDina'), _panchang!.souraMasaGataDina]),
                      ]),
                    ),

                    // ═══ ಚಂದ್ರ — Moon Details ═══
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _sectionHeader(Icons.nightlight_round, AppLocale.l('chandra'), kTeal),
                        _tableRow([AppLocale.l('chandraRashi'), trAll(_panchang!.chandraRashi)]),
                        _tableRow([AppLocale.l('chandraMasa'), trAll(_panchang!.chandraMasa)]),

                        _tableRow([AppLocale.l('paramaGhati'), _panchang!.paramaGhati]),
                      ]),
                    ),

                    // ═══ ಕಾಲ — Time & Season ═══
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        _sectionHeader(Icons.access_time, AppLocale.l('kala'), kPurple1),
                        _tableRow([AppLocale.l('samvatsara'), trAll(_panchang!.samvatsara)]),
                        _tableRow([AppLocale.l('ayana'), trAll(_panchang!.ayana)]),
                        _tableRow([AppLocale.l('rutu'), trAll(_panchang!.rutu)]),
                        _tableRow([AppLocale.l('divamana'), _panchang!.divamana]),
                        _tableRow([AppLocale.l('ratrimana'), _panchang!.ratrimana]),

                        _tableRow([AppLocale.l('vishaPraghati'), _panchang!.vishaPraghati]),
                        _tableRow([AppLocale.l('amrutaPraghati'), _panchang!.amrutaPraghati]),
                      ]),
                    ),

                    // ═══ ಅಗ್ನಿವಾಸ — Agni Vasa ═══
                    _buildAgniVasaCard(),

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

  // ─── Day Muhurtas (15 divisions of daytime) ───
  // Traditional names and nature: S=Shubha, A=Ashubha, M=Madhyama
  static List<Map<String, String>> get _muhurtaNames => [
    {'name': AppLocale.l('muh0'), 'nameEn': 'Rudra', 'nature': 'A'},
    {'name': AppLocale.l('muh1'), 'nameEn': 'Ahi', 'nature': 'A'},
    {'name': AppLocale.l('muh2'), 'nameEn': 'Mitra', 'nature': 'S'},
    {'name': AppLocale.l('muh3'), 'nameEn': 'Pitru', 'nature': 'A'},
    {'name': AppLocale.l('muh4'), 'nameEn': 'Vasu', 'nature': 'S'},
    {'name': AppLocale.l('muh5'), 'nameEn': 'Varaha', 'nature': 'S'},
    {'name': AppLocale.l('muh6'), 'nameEn': 'Vishwedeva', 'nature': 'S'},
    {'name': AppLocale.l('muh7'), 'nameEn': 'Vidhi', 'nature': 'M'},
    {'name': AppLocale.l('muh8'), 'nameEn': 'Satmukhi', 'nature': 'S'},
    {'name': AppLocale.l('muh9'), 'nameEn': 'Puruhuta', 'nature': 'A'},
    {'name': AppLocale.l('muh10'), 'nameEn': 'Vahini', 'nature': 'A'},
    {'name': AppLocale.l('muh11'), 'nameEn': 'Naktanakara', 'nature': 'M'},
    {'name': AppLocale.l('muh12'), 'nameEn': 'Varuna', 'nature': 'S'},
    {'name': AppLocale.l('muh13'), 'nameEn': 'Aryama', 'nature': 'S'},
    {'name': AppLocale.l('muh14'), 'nameEn': 'Bhaga', 'nature': 'A'},
  ];

  Widget _buildMuhurtaCard() {
    if (_panchang == null) return const SizedBox();
    final sr = _parseTimeToMinutes(_panchang!.sunrise);
    final ss = _parseTimeToMinutes(_panchang!.sunset);
    final duration = (ss - sr) / 15.0;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.schedule, color: const Color(0xFF5B2C6F), size: 22),
          const SizedBox(width: 8),
          Text(AppLocale.l('dayMuhurta'), style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 14, color: const Color(0xFF5B2C6F))),
        ]),
        const SizedBox(height: 6),
        Text(AppLocale.l('dayMuhurtaDesc'), style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 10),
        ...List.generate(15, (i) {
          final item = _muhurtaNames[i];
          final start = sr + i * duration;
          final end = start + duration;
          final nature = item['nature']!;
          final color = nature == 'S' ? Colors.green : nature == 'A' ? Colors.red : kOrange;
          final label = nature == 'S' ? AppLocale.l('shubha') : nature == 'A' ? AppLocale.l('ashubha') : AppLocale.l('madhyama');

          // Check if current time falls in this muhurta
          final now = DateTime.now();
          final nowMins = now.hour * 60.0 + now.minute;
          final isCurrent = _selectedDate.year == now.year && _selectedDate.month == now.month
              && _selectedDate.day == now.day && nowMins >= start && nowMins < end;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent ? color.withOpacity(0.12) : color.withOpacity(0.03),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isCurrent ? color.withOpacity(0.5) : color.withOpacity(0.1)),
            ),
            child: Row(children: [
              SizedBox(width: 20, child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kMuted))),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText)),
                Text(item['nameEn']!, style: TextStyle(fontSize: 9, color: kMuted)),
              ])),
              Text('${_minutesToTimeStr(start)} - ${_minutesToTimeStr(end)}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 4),
                Icon(Icons.play_arrow, size: 14, color: color),
              ],
            ]),
          );
        }),
      ]),
    );
  }

  // ─── Special Muhurta Timings (Abhijit, Durmuhurta, Amrita, Varjyam) ───
  // Traditional Varjyam (Tyajya) ghatis from the START of each Nakshatra's span
  // Each entry is the starting ghati within the nakshatra, duration is 4 ghatis
  // Source: Drik Panchang / Traditional Panchangam tables
  static const _varjyamGhatis = [
    50, 24, 30, 40, 14, 21, 30, 20, 32,  // Ashwini-Ashlesha
    30, 20, 18, 21, 20, 14, 14, 10, 14,  // Magha-Jyeshtha
    56, 24, 20, 10, 10, 18, 16, 24, 30,  // Moola-Revati
  ];

  Widget _buildSpecialMuhurtaCard() {
    if (_panchang == null) return const SizedBox();
    final sr = _parseTimeToMinutes(_panchang!.sunrise);
    final ss = _parseTimeToMinutes(_panchang!.sunset);
    final dayLen = ss - sr;
    final muhurtaDur = dayLen / 15.0; // one muhurta (~48 min for a 12h day)

    final timings = <Map<String, dynamic>>[];

    // ═══ Abhijit Muhurta — midday ± half muhurta ═══
    // Formula: midday = (sunrise + sunset) / 2, then ± muhurtaDur/2
    final midday = (sr + ss) / 2.0;
    final abhijitStart = midday - muhurtaDur / 2.0;
    final abhijitEnd = midday + muhurtaDur / 2.0;
    timings.add({
      'name': AppLocale.l('abhijit'), 'nameEn': 'Abhijit Muhurta',
      'start': _minutesToTimeStr(abhijitStart), 'end': _minutesToTimeStr(abhijitEnd),
      'icon': Icons.star, 'color': Colors.green,
      'desc': AppLocale.l('abhijitDesc'),
    });

    // ═══ Durmuhurta — fixed offsets from sunrise per weekday ═══
    // Traditional: each lasts 48 min (=muhurtaDur), except Saturday = 96 min
    // Offsets in minutes from sunrise:
    // Sun: 624min(10h24m), Mon: 384min(6h24m)+528min(8h48m),
    // Tue: 144min(2h24m), Wed: 336min(5h36m),
    // Thu: 240min(4h)+528min(8h48m), Fri: 144min(2h24m)+528min(8h48m),
    // Sat: 0 (from sunrise, 96min duration)
    final durEntries = <List<List<double>>>[
      [[624, 48]],                    // Sun: 1 period
      [[384, 48], [528, 48]],         // Mon: 2 periods
      [[144, 48]],                    // Tue: 1 period (2nd is after sunset)
      [[336, 48]],                    // Wed: 1 period
      [[240, 48], [528, 48]],         // Thu: 2 periods
      [[144, 48], [528, 48]],         // Fri: 2 periods
      [[0, 96]],                      // Sat: 1 period, 96 min
    ];

    final weekdayDurs = durEntries[_weekday];
    for (int i = 0; i < weekdayDurs.length; i++) {
      final offset = weekdayDurs[i][0];
      final dur = weekdayDurs[i][1];
      final dStart = sr + offset;
      final dEnd = dStart + dur;
      timings.add({
        'name': weekdayDurs.length > 1 ? '${AppLocale.l('durmuhurta')} ${i + 1}' : AppLocale.l('durmuhurta'),
        'nameEn': weekdayDurs.length > 1 ? 'Durmuhurta ${i + 1}' : 'Durmuhurta',
        'start': _minutesToTimeStr(dStart % (24 * 60)), 'end': _minutesToTimeStr(dEnd % (24 * 60)),
        'icon': Icons.dangerous, 'color': Colors.red,
        'desc': AppLocale.l('durmuhurtaDesc'),
      });
    }

    // ═══ Varjyam (Tyajya) — from Nakshatra start, NOT sunrise ═══
    // Varjyam starts at a specific ghati within the nakshatra's span
    // Duration: 4 ghatis (= 96 minutes)
    // One ghati = 24 minutes
    final nakIdx = _panchang!.nakshatraIndex;
    final varjyaStartGhati = _varjyamGhatis[nakIdx % 27];
    // Approximate: offset from sunrise in minutes
    // (varjya ghati offset from nakshatra start × 24 min per ghati)
    // Since we don't have exact nakshatra start time, we use sunrise as approximation
    // for the current nakshatra (common panchanga convention for daily view)
    final varjyaStartMins = sr + (varjyaStartGhati * 24.0);
    final varjyaEndMins = varjyaStartMins + (4 * 24.0); // 4 ghatis = 96 min
    timings.add({
      'name': AppLocale.l('varjya'), 'nameEn': 'Varjyam (Tyajya)',
      'start': _minutesToTimeStr(varjyaStartMins % (24 * 60)),
      'end': _minutesToTimeStr(varjyaEndMins % (24 * 60)),
      'icon': Icons.block, 'color': Colors.orange,
      'desc': AppLocale.l('varjyaDesc'),
    });

    // ═══ Amrita Siddhi Yoga ═══
    // Combinations of Weekday and Nakshatra
    bool hasAmritaSiddhi = false;
    final nIdx = nakIdx % 27;
    switch (_weekday) {
      case 0: hasAmritaSiddhi = (nIdx == 12 || nIdx == 18 || nIdx == 20); break; // Sun: Hasta, Moola, U.Ashadha
      case 1: hasAmritaSiddhi = (nIdx == 21 || nIdx == 3 || nIdx == 4); break;   // Mon: Shravana, Rohini, Mrigashira
      case 2: hasAmritaSiddhi = (nIdx == 0); break;                              // Tue: Ashwini
      case 3: hasAmritaSiddhi = (nIdx == 16); break;                             // Wed: Anuradha
      case 4: hasAmritaSiddhi = (nIdx == 7); break;                              // Thu: Pushya
      case 5: hasAmritaSiddhi = (nIdx == 26); break;                             // Fri: Revati
      case 6: hasAmritaSiddhi = (nIdx == 3); break;                              // Sat: Rohini
    }

    if (hasAmritaSiddhi) {
      final varas = [trAll(knVara[0]), trAll(knVara[1]), trAll(knVara[2]), trAll(knVara[3]), trAll(knVara[4]), trAll(knVara[5]), trAll(knVara[6])];
      final varaName = varas[_weekday];
      final nakName = trAll(_panchang!.nakshatra.split(' ')[0]);
      timings.add({
        'name': AppLocale.l('amritaSiddhi'), 'nameEn': 'Amrita Siddhi Yoga',
        'start': _minutesToTimeStr(sr % (24*60)), 'end': _minutesToTimeStr(ss % (24*60)),
        'icon': Icons.diamond, 'color': Colors.green,
        'desc': '$varaName + $nakName ${AppLocale.l('amritaSiddhiDesc')}',
      });
    }

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.access_alarm, color: kOrange, size: 22),
          const SizedBox(width: 8),
          Text(AppLocale.l('muhurtaTimings'), style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 14, color: kOrange)),
        ]),
        const SizedBox(height: 6),
        Text(AppLocale.l('muhurtaTimingsDesc'), style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 10),
        ...timings.map((t) {
          final color = t['color'] as Color;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(t['icon'] as IconData, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['name'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kText)),
                Text(t['desc'], style: TextStyle(fontSize: 10, color: kMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${t['start']} - ${t['end']}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
          );
        }),
      ]),
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
          Text(AppLocale.l('ashubhaKala'), style: TextStyle(
            fontWeight: FontWeight.w900, fontSize: 14, color: Colors.red)),
        ]),
        const SizedBox(height: 12),
        _kalaRow(AppLocale.l('rahuKala'), rahu['start']!, rahu['end']!, Colors.red),
        _kalaRow(AppLocale.l('yamaKala'), yama['start']!, yama['end']!, Colors.orange),
        _kalaRow(AppLocale.l('gulikaKala'), gulika['start']!, gulika['end']!, Colors.deepOrange),
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
          Text(isDay ? AppLocale.l('dayChougadiya') : AppLocale.l('nightChougadiya'),
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
          Text(isDay ? AppLocale.l('dayHora') : AppLocale.l('nightHora'),
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

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
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
    return '$base (${AppLocale.l('endLabel')}: $endTime${nextDay ? ' ${AppLocale.l('nextDayLabel')}' : ''})';
  }

  int _chandraPada() {
    if (_panchang == null) return 1;
    int p = (_panchang!.nakPercent * 4).floor() + 1;
    if (p < 1) p = 1;
    if (p > 4) p = 4;
    return p;
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
