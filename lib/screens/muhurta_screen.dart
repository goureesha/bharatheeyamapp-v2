import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sweph/sweph.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/muhurta_rules.dart';
import '../services/location_service.dart';

class MuhurtaScreen extends StatefulWidget {
  const MuhurtaScreen({super.key});

  @override
  State<MuhurtaScreen> createState() => _MuhurtaScreenState();
}

class _MuhurtaScreenState extends State<MuhurtaScreen> {
  // ── Event selection ──
  MuhurtaEvent _selectedEvent = MuhurtaEvent.vivaha;

  // ── Person mode ──
  bool _isTwoPersonMode = true;

  // ── Person 1 ──
  int? _rashiIdx1;
  int? _nakIdx1;

  // ── Person 2 ──
  int? _rashiIdx2;
  int? _nakIdx2;

  // ── Place ──
  late TextEditingController _placeCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _tzCtrl;
  bool _geoLoading = false;
  String _geoStatus = '';

  // ── Calendar ──
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  // ── Results ──
  bool _loading = false;
  bool _generated = false;
  Map<DateTime, MuhurtaDayResult> _results = {};
  // Store panchanga data for muhurta timing display
  Map<DateTime, PanchangData> _panchangCache = {};
  // Store lagna windows per day (computed on-tap)
  Map<DateTime, List<LagnaWindow>> _lagnaCache = {};
  // Store sunrise/sunset JDs per day for lagna scanning
  Map<DateTime, List<double>> _srssCache = {};

  @override
  void initState() {
    super.initState();
    _isTwoPersonMode = muhurtaEventNames[_selectedEvent]?.defaultTwoPerson ?? false;
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    _tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    super.dispose();
  }

  double get _lat => double.tryParse(_latCtrl.text) ?? LocationService.lat;
  double get _lon => double.tryParse(_lonCtrl.text) ?? LocationService.lon;
  double get _tz => double.tryParse(_tzCtrl.text) ?? LocationService.tzOffset;

  // ============================================================
  // PLACE SEARCH (same pattern as input_screen.dart)
  // ============================================================

  Future<void> _geocodeMultiple(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = AppLocale.l('placeNotFound'));
        } else if (data.length == 1) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon);
          setState(() {
            _placeCtrl.text = placeName.trim();
            _latCtrl.text = lat.toStringAsFixed(4);
            _lonCtrl.text = lon.toStringAsFixed(4);
            _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
            _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
          });
        } else {
          if (mounted) _showPlaceDisambiguation(data);
        }
      }
    } catch (_) {
      setState(() => _geoStatus = AppLocale.l('networkError'));
    }
    setState(() => _geoLoading = false);
  }

  void _showPlaceDisambiguation(List<dynamic> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(AppLocale.l('selectPlace'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1)),
            ),
            Text(AppLocale.l('multiPlacesFound'), style: TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (_, i) {
                  final place = results[i];
                  final displayName = place['display_name'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPurple1.withOpacity(0.1),
                      child: Icon(Icons.location_on, color: kPurple1, size: 20),
                    ),
                    title: Text(displayName, style: TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final lat = double.parse(place['lat']);
                      final lon = double.parse(place['lon']);
                      final autoTz = await getTimezoneForPlace(displayName, lat, lon);
                      setState(() {
                        _latCtrl.text = lat.toStringAsFixed(4);
                        _lonCtrl.text = lon.toStringAsFixed(4);
                        _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // EVENT CHANGED
  // ============================================================

  void _onEventChanged(MuhurtaEvent? event) {
    if (event == null) return;
    setState(() {
      _selectedEvent = event;
      _isTwoPersonMode = muhurtaEventNames[event]?.defaultTwoPerson ?? false;
      _generated = false;
      _results.clear();
      _panchangCache.clear();
    });
  }

  // ============================================================
  // GENERATE MUHURTAS FOR MONTH
  // ============================================================

  Future<void> _generate() async {
    if (_nakIdx1 == null || _rashiIdx1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ವ್ಯಕ್ತಿ 1ರ ರಾಶಿ ಮತ್ತು ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ')),
      );
      return;
    }
    if (_isTwoPersonMode && (_nakIdx2 == null || _rashiIdx2 == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ವ್ಯಕ್ತಿ 2ರ ರಾಶಿ ಮತ್ತು ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _generated = false;
      _results.clear();
      _panchangCache.clear();
      _lagnaCache.clear();
      _srssCache.clear();
      _selectedDay = null;
    });

    try {
      await Ephemeris.initSweph();

      final year = _focusedMonth.year;
      final month = _focusedMonth.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        if (day % 3 == 0) await Future.delayed(Duration.zero);

        try {
          final srSs = Ephemeris.findSunriseSetForDate(year, month, day, _lat, _lon, tzOffset: _tz);
          final srFrac = ((srSs[0] + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;
          final h24 = (srFrac * 24.0) + (5.0 / 60.0);

          final result = await AstroCalculator.calculate(
            year: year, month: month, day: day,
            hourUtcOffset: _tz,
            hour24: h24,
            lat: _lat, lon: _lon,
            ayanamsaMode: 'lahiri',
            trueNode: true,
          );

          if (result == null) continue;

          final p = result.panchang;
          final jupiterRashiIdx = result.planets['ಗುರು']?.rashiIndex ?? 0;
          final moonRashiIdx = result.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
          final varaIdx = knVara.indexOf(p.vara);
          final yogaIdx = knYoga.indexOf(p.yoga);

          // Compute Abhijit muhurta time (8th of 15 periods)
          final srMins = _parseTimeToMinutes(p.sunrise);
          final ssMins = _parseTimeToMinutes(p.sunset);
          final muhDur = (ssMins - srMins) / 15.0;
          final abhijitStart = srMins + 7 * muhDur;
          final abhijitEnd = abhijitStart + muhDur;
          final abhijitTimeStr = '${_minutesToTimeStr(abhijitStart)} - ${_minutesToTimeStr(abhijitEnd)}';

          // Compute Godhuli Lagna time (sunset ±24 minutes)
          final godhuliStart = ssMins - 24;
          final godhuliEnd = ssMins + 24;
          final godhuliTimeStr = '${_minutesToTimeStr(godhuliStart)} - ${_minutesToTimeStr(godhuliEnd)}';

          final dayResult = evaluateMuhurta(
            event: _selectedEvent,
            tithiIndex: p.tithiIndex,
            tithiName: p.tithi,
            nakshatraIndex: p.nakshatraIndex,
            nakshatraName: p.nakshatra,
            varaIndex: varaIdx >= 0 ? varaIdx : 0,
            varaName: p.vara,
            yogaIndex: yogaIdx >= 0 ? yogaIdx : 0,
            yogaName: p.yoga,
            karanaName: p.karana,
            moonRashiIndex: moonRashiIdx,
            jupiterRashiIndex: jupiterRashiIdx,
            janmaNakIdx1: _nakIdx1!,
            janmaRashiIdx1: _rashiIdx1!,
            janmaNakIdx2: _isTwoPersonMode ? _nakIdx2 : null,
            janmaRashiIdx2: _isTwoPersonMode ? _rashiIdx2 : null,
            abhijitTimeWindow: abhijitTimeStr,
            godhuliTimeWindow: (_selectedEvent == MuhurtaEvent.vivaha) ? godhuliTimeStr : null,
          );

          final dateKey = DateTime(year, month, day);
          _results[dateKey] = dayResult;
          _panchangCache[dateKey] = p;
          _srssCache[dateKey] = srSs;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _generated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ದೋಷ: $e')),
        );
      }
    }
  }

  // ============================================================
  // LAGNA WINDOW SCANNING
  // ============================================================
  // Scans ascendant from sunrise to sunset at 10-minute intervals
  // and finds when each rashi rises/sets to create time windows.

  Future<List<LagnaWindow>> _scanLagnaWindows(DateTime date) async {
    // Check cache first
    final key = DateTime(date.year, date.month, date.day);
    if (_lagnaCache.containsKey(key)) return _lagnaCache[key]!;

    final srSs = _srssCache[key];
    if (srSs == null) return [];

    final rules = muhurtaRules[_selectedEvent];
    final allowedLagnas = rules?.allowedLagnas;

    try {
      final double srJd = srSs[0];
      final double ssJd = srSs[1];

      // Get ayanamsa at sunrise
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
      final ayn = Sweph.swe_get_ayanamsa(srJd);

      // Sample ascendant at 10-minute intervals
      final double step = 10.0 / (24.0 * 60.0); // 10 min in JD
      final List<_AscSample> samples = [];

      double jd = srJd;
      while (jd <= ssJd + step) {
        final houses = Ephemeris.placidusHousesFull(jd, _lat, _lon);
        if (houses != null && houses.ascmc.length >= 1) {
          final sidAsc = ((houses.ascmc[0] as double) - ayn) % 360.0;
          final rashiIdx = (sidAsc / 30.0).floor() % 12;
          // Convert JD to local time minutes
          final localFrac = ((jd + 0.5 + (_tz / 24.0)) % 1.0 + 1.0) % 1.0;
          final localMins = localFrac * 24.0 * 60.0;
          samples.add(_AscSample(jd: jd, rashiIdx: rashiIdx, localMins: localMins));
        }
        jd += step;
      }

      if (samples.isEmpty) return [];

      // Extract rashi transitions
      final List<LagnaWindow> windows = [];
      int currentRashi = samples.first.rashiIdx;
      double startMins = samples.first.localMins;

      for (int i = 1; i < samples.length; i++) {
        if (samples[i].rashiIdx != currentRashi || i == samples.length - 1) {
          final endMins = (i == samples.length - 1 && samples[i].rashiIdx == currentRashi)
              ? samples[i].localMins
              : samples[i].localMins;

          windows.add(LagnaWindow(
            rashiIndex: currentRashi,
            rashiName: knRashi[currentRashi],
            startTime: _minutesToTimeStr(startMins),
            endTime: _minutesToTimeStr(endMins),
            isAllowed: allowedLagnas == null || allowedLagnas.contains(currentRashi),
          ));

          currentRashi = samples[i].rashiIdx;
          startMins = samples[i].localMins;
        }
      }

      _lagnaCache[key] = windows;
      return windows;
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // 15 MUHURTA TIMING CALCULATION
  // ============================================================

  static const List<String> muhurtaPeriodNames = [
    'ರುದ್ರ', 'ಅಹಿ (ಸರ್ಪ)', 'ಮಿತ್ರ', 'ಪಿತೃ', 'ವಸು',
    'ವಾರಾಹ', 'ವಿಶ್ವೇದೇವ', 'ಅಭಿಜಿತ್ (ವಿಧಿ)', 'ಸತಮುಖೀ', 'ಪುರುಹೂತ',
    'ವಾಹಿನಿ', 'ನಕ್ತನಕರಾ', 'ವರುಣ', 'ಅರ್ಯಮ', 'ಭಗ',
  ];

  // Nature: true = shubha, false = ashubha, null = conditional
  static const List<bool?> muhurtaPeriodNature = [
    false, false, true, false, true,
    true, true, true, true, true,
    false, false, true, null, false,
  ];

  double _parseTimeToMinutes(String timeStr) {
    try {
      final upper = timeStr.toUpperCase().trim();
      final isPM = upper.contains('PM');
      final isAM = upper.contains('AM');
      final cleaned = upper.replaceAll('AM', '').replaceAll('PM', '').trim();
      final parts = cleaned.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0].trim());
        final m = int.parse(parts[1].trim());
        if (isPM || isAM) {
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
    int h = (totalMins ~/ 60) % 24;
    final m = totalMins % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
  }

  List<Map<String, dynamic>> _calc15Muhurtas(PanchangData p) {
    final sr = _parseTimeToMinutes(p.sunrise);
    final ss = _parseTimeToMinutes(p.sunset);
    final dayDuration = ss - sr;
    final muhurtaDuration = dayDuration / 15.0;

    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < 15; i++) {
      final start = sr + i * muhurtaDuration;
      final end = start + muhurtaDuration;
      list.add({
        'name': muhurtaPeriodNames[i],
        'start': _minutesToTimeStr(start),
        'end': _minutesToTimeStr(end),
        'nature': muhurtaPeriodNature[i],
        'isAbhijit': i == 7,
      });
    }
    return list;
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Color _getColorForScore(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPersonInput(String title, int? rashiIdx, int? nakIdx,
      ValueChanged<int?> onRashiChanged, ValueChanged<int?> onNakChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPurple1)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(8),
                  color: kCard,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: Text('ರಾಶಿ', style: TextStyle(color: kMuted, fontSize: 13)),
                    value: rashiIdx,
                    dropdownColor: kCard,
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i,
                      child: Text(knRashi[i], style: TextStyle(fontSize: 13, color: kText)),
                    )),
                    onChanged: onRashiChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(8),
                  color: kCard,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: Text('ನಕ್ಷತ್ರ', style: TextStyle(color: kMuted, fontSize: 13)),
                    value: nakIdx,
                    dropdownColor: kCard,
                    items: List.generate(27, (i) => DropdownMenuItem(
                      value: i,
                      child: Text(knNak[i], style: TextStyle(fontSize: 13, color: kText)),
                    )),
                    onChanged: onNakChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DAY DETAIL CARD WITH MUHURTA TIMINGS
  // ============================================================

  Widget _buildDayDetail() {
    if (_selectedDay == null) return const SizedBox();
    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final result = _results[key];
    final panchang = _panchangCache[key];
    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBorder.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('ಈ ದಿನದ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ', style: TextStyle(color: kMuted)),
      );
    }

    final Color scoreColor = _getColorForScore(result.score);
    final bool isTwoPerson = result.personResults.length > 1;

    // 15 Muhurta timings
    final muhurtas = panchang != null ? _calc15Muhurtas(panchang) : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Score header ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scoreColor.withOpacity(0.15), scoreColor.withOpacity(0.05)],
            ),
            border: Border.all(color: scoreColor.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                style: TextStyle(fontSize: 14, color: kMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${result.score}',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: scoreColor)),
                  Text('/100', style: TextStyle(fontSize: 18, color: kMuted)),
                ],
              ),
              Text(result.verdict, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scoreColor)),
              if (panchang != null) ...[
                const SizedBox(height: 8),
                Text('☀️ ${panchang.sunrise}  →  🌙 ${panchang.sunset}',
                    style: TextStyle(fontSize: 12, color: kMuted)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Panchanga checks ──
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
            color: kCard,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kPurple1.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Text('ಪಂಚಾಂಗ ಶುದ್ಧಿ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 14)),
              ),
              ...result.checks.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    Icon(c.passed ? Icons.check_circle : Icons.cancel,
                        color: c.passed ? Colors.green : Colors.red, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(c.label, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(c.value, style: TextStyle(color: kMuted, fontSize: 13), textAlign: TextAlign.right)),
                            ],
                          ),
                          if (c.note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(c.note!, style: TextStyle(fontSize: 11, color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),

        // ── Person Bala Results ──
        if (result.personResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(result.personResults.length, (i) {
            final pr = result.personResults[i];
            final label = isTwoPerson
                ? (_selectedEvent == MuhurtaEvent.vivaha
                    ? (i == 0 ? '👤 ವರ (Groom)' : '👤 ವಧು (Bride)')
                    : '👤 ವ್ಯಕ್ತಿ ${i + 1}')
                : '👤 ನಿಮ್ಮ ಬಲಗಳು';

            return Container(
              margin: EdgeInsets.only(bottom: i < result.personResults.length - 1 ? 8 : 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(10),
                color: kCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
                  const SizedBox(height: 8),
                  _balaRow('ತಾರಾ ಬಲ', pr.taraBala.taraName, pr.taraBala.isGood),
                  _balaRow('ಚಂದ್ರ ಬಲ', pr.chandraBala ? 'ಅನುಕೂಲ' : 'ಪ್ರತಿಕೂಲ', pr.chandraBala),
                  _balaRow('ಗುರು ಬಲ', pr.guruBala ? 'ಅನುಕೂಲ' : 'ಪ್ರತಿಕೂಲ', pr.guruBala),
                ],
              ),
            );
          }),
        ],

        // ── Lagna Windows ──
        if (result.lagnaWindows.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(12),
              color: kCard,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E86AB).withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Text('🏠 ಲಗ್ನ ಸಮಯ (Lagna Windows)', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFF2E86AB), fontSize: 14)),
                ),
                ...result.lagnaWindows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final lw = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: lw.isAllowed ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.03),
                      border: i < result.lagnaWindows.length - 1
                          ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4)))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          lw.isAllowed ? Icons.check_circle : Icons.remove_circle_outline,
                          color: lw.isAllowed ? Colors.green : Colors.red.shade300,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(lw.rashiName, style: TextStyle(
                            fontWeight: lw.isAllowed ? FontWeight.w800 : FontWeight.w500,
                            color: lw.isAllowed ? kText : kMuted,
                            fontSize: 13,
                          )),
                        ),
                        Text('${lw.startTime} - ${lw.endTime}', style: TextStyle(
                          fontSize: 12,
                          color: lw.isAllowed ? Colors.green.shade700 : kMuted,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // ── 15 Muhurta Timings ──
        if (muhurtas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(12),
              color: kCard,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E44AD).withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Text('⏰ ೧೫ ಮುಹೂರ್ತ ಸಮಯ', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFF8E44AD), fontSize: 14)),
                ),
                ...muhurtas.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  final nature = m['nature'] as bool?;
                  final isAbhijit = m['isAbhijit'] as bool;

                  Color rowBg;
                  String natureIcon;
                  if (isAbhijit) {
                    rowBg = Colors.amber.withOpacity(0.12);
                    natureIcon = '🌟';
                  } else if (nature == true) {
                    rowBg = Colors.green.withOpacity(0.05);
                    natureIcon = '✅';
                  } else if (nature == false) {
                    rowBg = Colors.red.withOpacity(0.04);
                    natureIcon = '❌';
                  } else {
                    rowBg = Colors.orange.withOpacity(0.05);
                    natureIcon = '🟡';
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: rowBg,
                      border: i < 14
                          ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4)))
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text('${i + 1}', style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: kMuted, fontSize: 12)),
                        ),
                        Text(natureIcon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(m['name'], style: TextStyle(
                            fontWeight: isAbhijit ? FontWeight.w900 : FontWeight.w600,
                            color: isAbhijit ? Colors.amber.shade800 : kText,
                            fontSize: 13,
                          )),
                        ),
                        Text('${m['start']} - ${m['end']}', style: TextStyle(
                          fontSize: 12,
                          color: kMuted,
                          fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // ── Dosha Bhangas ──
        if (result.doshaBhangas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              border: Border.all(color: Colors.amber.shade600),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✨ ದೋಷ ಭಂಗ (Exceptions)', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber.shade700, fontSize: 13)),
                const SizedBox(height: 6),
                ...result.doshaBhangas.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $d', style: TextStyle(color: Colors.amber.shade800, fontSize: 12)),
                )),
              ],
            ),
          ),
        ],

        // ── Doshas (hard blocks) ──
        if (result.doshas.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              border: Border.all(color: Colors.red.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('⚠️ ದೋಷಗಳು', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red.shade700, fontSize: 13)),
                const SizedBox(height: 6),
                ...result.doshas.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('• $d', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _balaRow(String label, String value, bool good) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(good ? Icons.check_circle : Icons.cancel, color: good ? Colors.green : Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: kText, fontSize: 12)),
          const Spacer(),
          Text(value, style: TextStyle(color: good ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: kText, fontSize: 12)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್',
                     'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];
    return months[month - 1];
  }

  // ============================================================
  // BEST DAYS SUMMARY
  // ============================================================

  Widget _buildBestDaysSummary() {
    if (!_generated || _results.isEmpty) return const SizedBox();

    // Sort by score descending, take top 5
    final sorted = _results.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));
    final top5 = sorted.take(5).toList();

    // Count by category
    final shreshtha = _results.values.where((r) => r.score >= 80).length;
    final madhyama = _results.values.where((r) => r.score >= 60 && r.score < 80).length;
    final ashubha = _results.values.where((r) => r.score < 60).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text('ಶ್ರೇಷ್ಠ ದಿನಗಳು (Best Days)',
                  style: TextStyle(fontWeight: FontWeight.w900, color: kPurple1, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),

          // Summary counts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _countChip('🟢 ಶ್ರೇಷ್ಠ', shreshtha, Colors.green),
              _countChip('🟡 ಮಧ್ಯಮ', madhyama, Colors.orange),
              _countChip('🔴 ಅಶುಭ', ashubha, Colors.red),
            ],
          ),
          const SizedBox(height: 12),

          // Top 5 days
          ...top5.map((entry) {
            final date = entry.key;
            final result = entry.value;
            final scoreColor = _getColorForScore(result.score);
            final bool isSelected = _selectedDay != null && isSameDay(_selectedDay!, date);

            return InkWell(
              onTap: () async {
                setState(() => _selectedDay = date);
                // Trigger lagna scan
                final existing = _results[date];
                if (existing != null && existing.lagnaWindows.isEmpty) {
                  final windows = await _scanLagnaWindows(date);
                  if (windows.isNotEmpty && mounted) {
                    setState(() {
                      _results[date] = MuhurtaDayResult(
                        score: existing.score,
                        verdict: existing.verdict,
                        checks: existing.checks,
                        personResults: existing.personResults,
                        doshas: existing.doshas,
                        doshaBhangas: existing.doshaBhangas,
                        lagnaWindows: windows,
                        hasAbhijit: existing.hasAbhijit,
                        hasGodhuli: existing.hasGodhuli,
                        abhijitTime: existing.abhijitTime,
                        godhuliTime: existing.godhuliTime,
                      );
                    });
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? kPurple1.withOpacity(0.1) : scoreColor.withOpacity(0.05),
                  border: Border.all(
                    color: isSelected ? kPurple1 : scoreColor.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text('${date.day}', style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16, color: scoreColor)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${date.day}/${date.month}/${date.year}',
                              style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13)),
                          Text(result.verdict,
                              style: TextStyle(fontSize: 11, color: scoreColor, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Text('${result.score}/100',
                        style: TextStyle(fontWeight: FontWeight.w900, color: scoreColor, fontSize: 16)),
                    if (result.hasAbhijit) ...[
                      const SizedBox(width: 4),
                      Text('🌟', style: TextStyle(fontSize: 14)),
                    ],
                    if (result.hasGodhuli) ...[
                      const SizedBox(width: 4),
                      Text('🐄', style: TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$label: $count',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಮುಹೂರ್ತ / Muhurta',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ══════════════ INPUT CARD ══════════════
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Event Selector ──
                    Text('ಮುಹೂರ್ತ ವರ್ಗ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kPurple1)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(8),
                        color: kCard,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MuhurtaEvent>(
                          isExpanded: true,
                          value: _selectedEvent,
                          dropdownColor: kCard,
                          items: MuhurtaEvent.values.map((e) {
                            final info = muhurtaEventNames[e]!;
                            return DropdownMenuItem(
                              value: e,
                              child: Text('${info.kannadaName} (${info.englishName})',
                                  style: TextStyle(fontSize: 14, color: kText)),
                            );
                          }).toList(),
                          onChanged: _onEventChanged,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Person Toggle ──
                    ToggleButtons(
                      isSelected: [!_isTwoPersonMode, _isTwoPersonMode],
                      onPressed: (index) {
                        setState(() {
                          _isTwoPersonMode = index == 1;
                          _generated = false;
                          _results.clear();
                          _panchangCache.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: kPurple1,
                      color: kText,
                      constraints: const BoxConstraints(minHeight: 38, minWidth: 120),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('೧ ವ್ಯಕ್ತಿ')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('೨ ವ್ಯಕ್ತಿಗಳು')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Person 1 Input ──
                    _buildPersonInput(
                      _isTwoPersonMode
                          ? (_selectedEvent == MuhurtaEvent.vivaha ? '👤 ವರ (Groom)' : '👤 ವ್ಯಕ್ತಿ 1')
                          : '👤 ನಿಮ್ಮ ವಿವರ',
                      _rashiIdx1, _nakIdx1,
                      (v) => setState(() { _rashiIdx1 = v; _generated = false; }),
                      (v) => setState(() { _nakIdx1 = v; _generated = false; }),
                    ),

                    // ── Person 2 Input ──
                    if (_isTwoPersonMode) ...[
                      const SizedBox(height: 12),
                      _buildPersonInput(
                        _selectedEvent == MuhurtaEvent.vivaha ? '👤 ವಧು (Bride)' : '👤 ವ್ಯಕ್ತಿ 2',
                        _rashiIdx2, _nakIdx2,
                        (v) => setState(() { _rashiIdx2 = v; _generated = false; }),
                        (v) => setState(() { _nakIdx2 = v; _generated = false; }),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ── Place Selector (Searchable — same as Kundali) ──
                    Text('📍 ಸ್ಥಳ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPurple1)),
                    const SizedBox(height: 8),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return offlinePlaces.keys.take(15);
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return offlinePlaces.keys.where(
                            (name) => name.toLowerCase().contains(query));
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        // Sync initial value
                        if (textEditingController.text.isEmpty && _placeCtrl.text.isNotEmpty) {
                          textEditingController.text = _placeCtrl.text;
                        }
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: AppLocale.l('searchPlace'),
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: _geoLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : IconButton(
                                  icon: Icon(Icons.my_location, color: kTeal),
                                  onPressed: () {
                                    _placeCtrl.text = textEditingController.text;
                                    _geocodeMultiple(textEditingController.text);
                                  },
                                ),
                          ),
                          onSubmitted: (_) {
                            _placeCtrl.text = textEditingController.text;
                            _geocodeMultiple(textEditingController.text);
                          },
                        );
                      },
                      onSelected: (String selection) async {
                        if (offlinePlaces.containsKey(selection)) {
                          final coords = offlinePlaces[selection]!;
                          final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
                          setState(() {
                            _placeCtrl.text = selection;
                            _latCtrl.text = coords[0].toStringAsFixed(4);
                            _lonCtrl.text = coords[1].toStringAsFixed(4);
                            _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                            _geoStatus = '📍 $selection (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
                          });
                        }
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    leading: Icon(Icons.location_on, size: 18, color: kPurple2),
                                    title: Text(option, style: TextStyle(fontSize: 13)),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_geoStatus.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(_geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
                    ],
                    const SizedBox(height: 8),

                    // Lat/Lon/TZ row
                    Row(children: [
                      Expanded(flex: 4, child: TextField(
                        controller: _latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: AppLocale.l('lat'), isDense: true),
                      )),
                      const SizedBox(width: 8),
                      Expanded(flex: 4, child: TextField(
                        controller: _lonCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: AppLocale.l('lon'), isDense: true),
                      )),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: TextField(
                        controller: _tzCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(labelText: AppLocale.l('tzOffset'), isDense: true),
                      )),
                    ]),

                    const SizedBox(height: 16),

                    // ── Month Selector ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: kPurple1),
                          onPressed: () {
                            setState(() {
                              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                              _generated = false;
                              _results.clear();
                              _panchangCache.clear();
                            });
                          },
                        ),
                        Text(
                          '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                          style: TextStyle(fontWeight: FontWeight.w800, color: kText, fontSize: 16),
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: kPurple1),
                          onPressed: () {
                            setState(() {
                              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                              _generated = false;
                              _results.clear();
                              _panchangCache.clear();
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Generate Button ──
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _generate,
                        icon: _loading
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 20),
                        label: Text(
                          _loading ? 'ಲೆಕ್ಕ ಹಾಕುತ್ತಿದೆ...' : 'ಮುಹೂರ್ತ ರಚಿಸಿ / Generate',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ══════════════ RESULTS SECTION ══════════════
              if (_generated) ...[
                const SizedBox(height: 16),

                // ── Calendar with month navigation ──
                AppCard(
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime(2020, 1, 1),
                        lastDay: DateTime(2040, 12, 31),
                        focusedDay: _selectedDay ?? DateTime(_focusedMonth.year, _focusedMonth.month, 1),
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selected, focused) async {
                          setState(() {
                            _selectedDay = selected;
                          });
                          // Compute lagna windows on-tap
                          final key = DateTime(selected.year, selected.month, selected.day);
                          final existing = _results[key];
                          if (existing != null && existing.lagnaWindows.isEmpty) {
                            final windows = await _scanLagnaWindows(selected);
                            if (windows.isNotEmpty && mounted) {
                              setState(() {
                                _results[key] = MuhurtaDayResult(
                                  score: existing.score,
                                  verdict: existing.verdict,
                                  checks: existing.checks,
                                  personResults: existing.personResults,
                                  doshas: existing.doshas,
                                  doshaBhangas: existing.doshaBhangas,
                                  lagnaWindows: windows,
                                  hasAbhijit: existing.hasAbhijit,
                                  hasGodhuli: existing.hasGodhuli,
                                  abhijitTime: existing.abhijitTime,
                                  godhuliTime: existing.godhuliTime,
                                );
                              });
                            }
                          }
                        },
                        onPageChanged: (focusedDay) {
                          // When user swipes calendar month, allow re-generate
                          if (focusedDay.month != _focusedMonth.month || focusedDay.year != _focusedMonth.year) {
                            setState(() {
                              _focusedMonth = focusedDay;
                              _generated = false;
                              _results.clear();
                              _panchangCache.clear();
                              _lagnaCache.clear();
                              _srssCache.clear();
                            });
                          }
                        },
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) {
                            final key = DateTime(date.year, date.month, date.day);
                            final result = _results[key];
                            if (result == null) return const SizedBox();
                            return Positioned(
                              bottom: 4,
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: _getColorForScore(result.score),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                          dowBuilder: (context, day) {
                            const days = ['ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರವಿ'];
                            return Center(
                              child: Text(days[day.weekday - 1],
                                  style: TextStyle(
                                    color: day.weekday == 7 ? Colors.red.shade300 : kText,
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            );
                          },
                          defaultBuilder: (context, day, focused) {
                            final key = DateTime(day.year, day.month, day.day);
                            final result = _results[key];
                            Color? bgColor;
                            if (result != null) {
                              if (result.score >= 80) bgColor = Colors.green.withOpacity(0.10);
                              else if (result.score >= 60) bgColor = Colors.orange.withOpacity(0.08);
                              else bgColor = Colors.red.withOpacity(0.06);
                            }
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text('${day.day}', style: TextStyle(color: kText)),
                            );
                          },
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16),
                          formatButtonVisible: false,
                          leftChevronIcon: Icon(Icons.chevron_left, color: kPurple1),
                          rightChevronIcon: Icon(Icons.chevron_right, color: kPurple1),
                        ),
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: TextStyle(color: kText),
                          weekendTextStyle: TextStyle(color: Colors.red.shade300),
                          outsideDaysVisible: false,
                          selectedDecoration: BoxDecoration(color: kPurple1, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: kBorder, shape: BoxShape.circle),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16, runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _legendDot(Colors.green, 'ಶ್ರೇಷ್ಠ (80+)'),
                          _legendDot(Colors.orange, 'ಮಧ್ಯಮ (60-79)'),
                          _legendDot(Colors.red, 'ಅಶುಭ (<60)'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Best Days Summary ──
                _buildBestDaysSummary(),

                const SizedBox(height: 16),

                // ── Detailed card when day is tapped ──
                _buildDayDetail(),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for lagna ascendant sampling
class _AscSample {
  final double jd;
  final int rashiIdx;
  final double localMins;
  _AscSample({required this.jd, required this.rashiIdx, required this.localMins});
}
