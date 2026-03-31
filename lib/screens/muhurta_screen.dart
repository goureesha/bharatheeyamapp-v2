import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
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

  // ── Calendar ──
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  // ── Results ──
  bool _loading = false;
  bool _generated = false;
  Map<DateTime, MuhurtaDayResult> _results = {};

  // ── Location ──
  double get _lat => LocationService.lat;
  double get _lon => LocationService.lon;
  double get _tz => LocationService.tzOffset;

  @override
  void initState() {
    super.initState();
    // Auto 2-person for Vivaha
    _isTwoPersonMode = muhurtaEventNames[_selectedEvent]?.defaultTwoPerson ?? false;
  }

  void _onEventChanged(MuhurtaEvent? event) {
    if (event == null) return;
    setState(() {
      _selectedEvent = event;
      _isTwoPersonMode = muhurtaEventNames[event]?.defaultTwoPerson ?? false;
      _generated = false;
      _results.clear();
    });
  }

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
    });

    try {
      await Ephemeris.initSweph();

      final year = _focusedMonth.year;
      final month = _focusedMonth.month;
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        // Yield to UI thread
        if (day % 3 == 0) await Future.delayed(Duration.zero);

        try {
          // Compute sunrise + 5 min
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

          // Get Jupiter rashi from planets map
          final jupiterInfo = result.planets['ಗುರು'];
          final jupiterRashiIdx = jupiterInfo != null ? jupiterInfo.rashiIndex : 0;

          // Moon rashi index
          final moonRashiIdx = (result.planets['ಚಂದ್ರ']?.rashiIndex ?? 0);

          // Vara index: Panchanga gives vara name, convert to index 0=Sun..6=Sat
          final varaIdx = knVara.indexOf(p.vara);

          // Yoga index
          final yogaIdx = knYoga.indexOf(p.yoga);

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
          );

          _results[DateTime(year, month, day)] = dayResult;
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

  Color _getColorForScore(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildMarker(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    final result = _results[key];
    if (result == null) return const SizedBox();

    return Positioned(
      bottom: 6,
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: _getColorForScore(result.score),
          shape: BoxShape.circle,
        ),
      ),
    );
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

  Widget _buildDayDetail() {
    if (_selectedDay == null) return const SizedBox();
    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final result = _results[key];
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score header
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
                  Text(
                    '${result.score}',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: scoreColor),
                  ),
                  Text('/100', style: TextStyle(fontSize: 18, color: kMuted)),
                ],
              ),
              Text(
                result.verdict,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: scoreColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Panchanga checks
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
            color: kCard,
          ),
          child: Column(
            children: [
              // Header
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
                    Icon(
                      c.passed ? Icons.check_circle : Icons.cancel,
                      color: c.passed ? Colors.green : Colors.red,
                      size: 18,
                    ),
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

        // Person-specific Bala results
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

        // Dosha Bhangas
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

        // Doshas (hard blocks)
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

  @override
  Widget build(BuildContext context) {
    final eventInfo = muhurtaEventNames[_selectedEvent]!;

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
          child: AppCard(
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

                // ── Location ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBorder.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: kMuted),
                      const SizedBox(width: 6),
                      Text(LocationService.place, style: TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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

                // ── Calendar ──
                if (_generated) ...[
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kBorder),
                      borderRadius: BorderRadius.circular(12),
                      color: kCard,
                    ),
                    child: TableCalendar(
                      firstDay: DateTime(_focusedMonth.year, _focusedMonth.month, 1),
                      lastDay: DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0),
                      focusedDay: _selectedDay ?? DateTime(_focusedMonth.year, _focusedMonth.month, 1),
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                        });
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) => _buildMarker(date),
                        dowBuilder: (context, day) {
                          const days = ['ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರವಿ'];
                          return Center(
                            child: Text(
                              days[day.weekday - 1],
                              style: TextStyle(
                                color: day.weekday == 7 ? Colors.red.shade300 : kText,
                                fontWeight: FontWeight.bold, fontSize: 12,
                              ),
                            ),
                          );
                        },
                        defaultBuilder: (context, day, focused) {
                          final key = DateTime(day.year, day.month, day.day);
                          final result = _results[key];
                          Color? bgColor;
                          if (result != null) {
                            if (result.score >= 80) bgColor = Colors.green.withOpacity(0.08);
                            else if (result.score >= 60) bgColor = Colors.orange.withOpacity(0.06);
                            else bgColor = Colors.red.withOpacity(0.04);
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
                        leftChevronVisible: false,
                        rightChevronVisible: false,
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: kText, fontWeight: FontWeight.bold),
                        weekendStyle: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: TextStyle(color: kText),
                        weekendTextStyle: TextStyle(color: Colors.red.shade300),
                        outsideTextStyle: TextStyle(color: kMuted),
                        selectedDecoration: BoxDecoration(color: kPurple1.withOpacity(0.5), shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: kBorder, shape: BoxShape.circle),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Legend
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _legendDot(Colors.green, 'ಶ್ರೇಷ್ಠ (80+)'),
                      _legendDot(Colors.orange, 'ಮಧ್ಯಮ (60-79)'),
                      _legendDot(Colors.red, 'ಅಶುಭ (<60)'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Day detail
                  _buildDayDetail(),
                ],

                // Month navigation (before generate)
                if (!_generated) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: kPurple1),
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                          });
                        },
                      ),
                      Text(
                        _getMonthName(_focusedMonth.month) + ' ${_focusedMonth.year}',
                        style: TextStyle(fontWeight: FontWeight.w800, color: kText, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: kPurple1),
                        onPressed: () {
                          setState(() {
                            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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
}
