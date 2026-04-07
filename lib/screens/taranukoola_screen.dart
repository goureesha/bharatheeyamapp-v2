import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sweph/sweph.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';

class TaranukoolaScreen extends StatefulWidget {
  const TaranukoolaScreen({super.key});

  @override
  State<TaranukoolaScreen> createState() => _TaranukoolaScreenState();
}

class _TaranukoolaScreenState extends State<TaranukoolaScreen> {
  bool _isTwoPersonMode = false;
  bool _excludeNakshatras = false;
  int? _janmaNakshatraIdx1;
  int? _janmaNakshatraIdx2;
  
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  Map<DateTime, int> _dailyNakshatraCache = {};
  KundaliResult? _selectedDayResult;
  bool _isLoadingPanchang = false;
  bool _showTaraCharts = false;

  final _taras = [
    'ಜನ್ಮ ತಾರೆ (ಅಶುಭ)',
    'ಸಂಪತ್ ತಾರೆ (ಶುಭ)',
    'ವಿಪತ್ ತಾರೆ (ಅಶುಭ)',
    'ಕ್ಷೇಮ ತಾರೆ (ಶುಭ)',
    'ಪ್ರತ್ಯಕ್ ತಾರೆ (ಅಶುಭ)',
    'ಸಾಧಕ ತಾರೆ (ಶುಭ)',
    'ವಧ ತಾರೆ (ಅಶುಭ)',
    'ಮಿತ್ರ ತಾರೆ (ಶುಭ)',
    'ಪರಮ ಮಿತ್ರ ತಾರೆ (ಅತ್ಯುತ್ತಮ)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadNakshatra();
    _calculatePanchangForSelectedDay();
  }

  Future<void> _calculatePanchangForSelectedDay() async {
    if (_selectedDay == null) return;
    if (mounted) setState(() => _isLoadingPanchang = true);
    try {
      final result = await AstroCalculator.calculate(
        year: _selectedDay!.year, month: _selectedDay!.month, day: _selectedDay!.day,
        hourUtcOffset: LocationService.tzOffset, 
        hour24: 6.0, 
        lat: LocationService.lat, 
        lon: LocationService.lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );
      if (mounted) setState(() {
        _selectedDayResult = result;
        _isLoadingPanchang = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingPanchang = false);
    }
  }

  Future<void> _loadNakshatra() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isTwoPersonMode = prefs.getBool('dashboard_tara_two_person') ?? false;
        _excludeNakshatras = prefs.getBool('tara_exclude_nakshatras') ?? false;
        _janmaNakshatraIdx1 = prefs.getInt('dashboard_janma_nakshatra');
        _janmaNakshatraIdx2 = prefs.getInt('dashboard_janma_nakshatra2');
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_tara_two_person', _isTwoPersonMode);
    await prefs.setBool('tara_exclude_nakshatras', _excludeNakshatras);
    if (_janmaNakshatraIdx1 != null) await prefs.setInt('dashboard_janma_nakshatra', _janmaNakshatraIdx1!);
    if (_janmaNakshatraIdx2 != null) await prefs.setInt('dashboard_janma_nakshatra2', _janmaNakshatraIdx2!);
  }
  
  int _calculateNakshatraForDate(DateTime date) {
    // Basic calculation for the moon's position on a specific day
    // A more precise version would check the exact time (like sunrise), 
    // but for a general day calendar, 12:00 PM is a good average.
    DateTime noon = DateTime(date.year, date.month, date.day, 12, 0);
    double jd = Sweph.swe_julday(noon.year, noon.month, noon.day, noon.hour + (noon.minute / 60.0), CalendarType.SE_GREG_CAL);
    
    // Calculate Moon
    final pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH);
    double moonLon = pos.longitude;
    return (moonLon / (360.0 / 27.0)).floor();
  }

  int _getNakshatraForDate(DateTime date) {
    DateTime normalized = DateTime(date.year, date.month, date.day);
    if (!_dailyNakshatraCache.containsKey(normalized)) {
       _dailyNakshatraCache[normalized] = _calculateNakshatraForDate(normalized);
    }
    return _dailyNakshatraCache[normalized]!;
  }

  // Nakshatras to exclude when toggle is on
  // Bharani(1), Kruttika(2), Ardra(5), Ashlesha(8), Makha(9),
  // Poorva Phalguni(10), Vishakha(15), Jyeshta(17), Moola(18),
  // Poorvashadha(19), Poorva Bhadra(24)
  static const _excludedNakIndices = {1, 2, 5, 8, 9, 10, 15, 17, 18, 19, 24};

  bool _isGoodTara(int taraIdx) {
    return (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
  }

  /// Check if a day is good, considering nakshatra exclusion
  bool _isDayGood(int dinaIdx, int janmaIdx) {
    int tara = (dinaIdx - janmaIdx + 27) % 27 % 9;
    if (!_isGoodTara(tara)) return false;
    if (_excludeNakshatras && _excludedNakIndices.contains(dinaIdx)) return false;
    return true;
  }

  Widget _buildMarker(DateTime date, List events) {
    if (_janmaNakshatraIdx1 == null) return const SizedBox();
    if (_isTwoPersonMode && _janmaNakshatraIdx2 == null) return const SizedBox();

    int dinaIdx = _getNakshatraForDate(date);
    
    bool isGood1 = _isDayGood(dinaIdx, _janmaNakshatraIdx1!);

    if (!_isTwoPersonMode) {
      Color dotColor = isGood1 ? Colors.green : Colors.red;
      return Positioned(
        bottom: 6,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
      );
    } else {
      bool isGood2 = _isDayGood(dinaIdx, _janmaNakshatraIdx2!);
      
      Color dotColor;
      if (isGood1 && isGood2) {
        dotColor = Colors.green;
      } else if (!isGood1 && !isGood2) {
        dotColor = Colors.red;
      } else {
        dotColor = Colors.orange;
      }

      return Positioned(
        bottom: 6,
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
      );
    }
  }

  Widget _tableRow(List<String> cols, {bool bold0 = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder.withValues(alpha: 0.5))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(cols.length, (i) {
            final isFirst = i == 0;
            return Expanded(
              flex: isFirst ? 3 : 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: i < cols.length - 1 ? Border(right: BorderSide(color: kBorder.withValues(alpha: 0.5))) : null,
                  color: isFirst ? kPurple2.withValues(alpha: 0.05) : kCard,
                ),
                alignment: isFirst ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  cols[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isFirst && bold0) ? FontWeight.bold : (isFirst ? FontWeight.w600 : FontWeight.w500),
                    color: isFirst ? kPurple2 : kText,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _formatEnd(String base, String endTime, bool nextDay) {
    if (endTime.isEmpty) return base;
    return '$base (ಅಂತ್ಯ: $endTime${nextDay ? ' ಮುಂದಿನ ದಿನ' : ''})';
  }

  Widget _buildTaraChart(int janmaIdx, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPurple1)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(8),
            color: kCard,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            separatorBuilder: (context, index) => Divider(height: 1, color: kBorder),
            itemBuilder: (context, i) {
              bool isGood = _isGoodTara(i);
              Color bgColor = isGood ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05);
              Color textColor = isGood ? Colors.green.shade700 : Colors.red.shade700;
              
              int n1 = (janmaIdx + i) % 27;
              int n2 = (janmaIdx + i + 9) % 27;
              int n3 = (janmaIdx + i + 18) % 27;
              String nakshatras = '${knNak[n1]}, ${knNak[n2]}, ${knNak[n3]}';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: bgColor),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(_taras[i], style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(nakshatras, style: TextStyle(color: kText, fontSize: 13), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ತಾರಾನುಕೂಲ',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ResponsiveCenter(child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('ತಾರಾನುಕೂಲ ಫಲಿತಾಂಶಗಳು', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
                    const SizedBox(height: 16),
                    ToggleButtons(
                      isSelected: [!_isTwoPersonMode, _isTwoPersonMode],
                      onPressed: (index) {
                        setState(() {
                          _isTwoPersonMode = index == 1;
                          _saveSettings();
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: kPurple1,
                      color: kText,
                      constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('೧ ವ್ಯಕ್ತಿ')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('೨ ವ್ಯಕ್ತಿಗಳು')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Exclude nakshatras toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _excludeNakshatras ? Colors.orange.withOpacity(0.1) : kBorder.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _excludeNakshatras ? Colors.orange : kBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _excludeNakshatras ? Icons.filter_alt : Icons.filter_alt_outlined,
                            size: 20,
                            color: _excludeNakshatras ? Colors.orange.shade700 : kMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ಅಶುಭ ನಕ್ಷತ್ರ ಹೊರಗಿಡಿ',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _excludeNakshatras ? Colors.orange.shade700 : kMuted),
                            ),
                          ),
                          Switch(
                            value: _excludeNakshatras,
                            activeColor: Colors.orange,
                            onChanged: (val) {
                              setState(() {
                                _excludeNakshatras = val;
                                _dailyNakshatraCache.clear();
                                _saveSettings();
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    if (_excludeNakshatras) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _excludedNakIndices.map((idx) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(knNak[idx], style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text(_isTwoPersonMode ? 'ವ್ಯಕ್ತಿ 1ರ ಜನ್ಮ ನಕ್ಷತ್ರ:' : 'ನಿಮ್ಮ ಜನ್ಮ ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(8),
                        color: kCard,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: Text('ಜನ್ಮ ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ'),
                          value: _janmaNakshatraIdx1,
                          dropdownColor: kCard,
                          items: List.generate(27, (i) {
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(knNak[i], style: TextStyle(fontSize: 16, color: kText)),
                            );
                          }),
                          onChanged: (val) {
                            setState(() {
                              _janmaNakshatraIdx1 = val;
                              _saveSettings();
                            });
                          },
                        ),
                      ),
                    ),
                    if (_isTwoPersonMode) ...[
                      const SizedBox(height: 16),
                      Text('ವ್ಯಕ್ತಿ 2ರ ಜನ್ಮ ನಕ್ಷತ್ರ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(8),
                          color: kCard,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            hint: Text('ಜನ್ಮ ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ'),
                            value: _janmaNakshatraIdx2,
                            dropdownColor: kCard,
                            items: List.generate(27, (i) {
                              return DropdownMenuItem<int>(
                                value: i,
                                child: Text(knNak[i], style: TextStyle(fontSize: 16, color: kText)),
                              );
                            }),
                            onChanged: (val) {
                              setState(() {
                                _janmaNakshatraIdx2 = val;
                                _saveSettings();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(12),
                        color: kCard,
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(DateTime.now().year - 1, DateTime.now().month, DateTime.now().day),
                        lastDay: DateTime.utc(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _calculatePanchangForSelectedDay();
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) => _buildMarker(date, events),
                          dowBuilder: (context, day) {
                            const days = ['ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರವಿ'];
                            return Center(
                              child: Text(
                                days[day.weekday - 1],
                                style: TextStyle(color: day.weekday == 7 ? Colors.red.shade300 : kText, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                          headerTitleBuilder: (context, day) {
                            const months = ['ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', 'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್'];
                            return Text(
                              '${months[day.month - 1]} ${day.year}',
                              style: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16),
                            );
                          },
                        ),
                        headerStyle: HeaderStyle(
                          titleTextStyle: TextStyle(color: kText, fontWeight: FontWeight.bold, fontSize: 16),
                          formatButtonVisible: false,
                          leftChevronIcon: Icon(Icons.chevron_left, color: kPurple1),
                          rightChevronIcon: Icon(Icons.chevron_right, color: kPurple1),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: kText, fontWeight: FontWeight.bold),
                          weekendStyle: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
                        ),
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: TextStyle(color: kText),
                          weekendTextStyle: TextStyle(color: Colors.red.shade300),
                          outsideTextStyle: TextStyle(color: kMuted),
                          selectedDecoration: BoxDecoration(color: kPurple1.withValues(alpha: 0.5), shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: kBorder, shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(_isTwoPersonMode ? 'ಇಬ್ಬರಿಗೂ ಶುಭ' : 'ಶುಭ ದಿನ', style: TextStyle(color: kText, fontSize: 12)),
                        ]),
                        if (_isTwoPersonMode)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('ಒಬ್ಬರಿಗೆ ಮಾತ್ರ ಶುಭ', style: TextStyle(color: kText, fontSize: 12)),
                          ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(_isTwoPersonMode ? 'ಇಬ್ಬರಿಗೂ ಅಶುಭ' : 'ಅಶುಭ ದಿನ', style: TextStyle(color: kText, fontSize: 12)),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    if (_selectedDay != null && _janmaNakshatraIdx1 != null && (!_isTwoPersonMode || _janmaNakshatraIdx2 != null)) ...[
                      Builder(
                        builder: (context) {
                          int dinaIdx = _getNakshatraForDate(_selectedDay!);
                          int tara1 = (dinaIdx - _janmaNakshatraIdx1! + 27) % 27 % 9;
                          bool isGood1 = _isDayGood(dinaIdx, _janmaNakshatraIdx1!);
                          bool isExcluded = _excludeNakshatras && _excludedNakIndices.contains(dinaIdx);
                          
                          if (!_isTwoPersonMode) {
                              Color bgColor = isGood1 ? Colors.green.shade50 : Colors.red.shade50;
                              Color borderColor = isGood1 ? Colors.green.shade500 : Colors.red.shade500;
                              Color textColor = isGood1 ? Colors.green.shade900 : Colors.red.shade900;
                              
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 2), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text('ಆಯ್ಕೆಮಾಡಿದ ದಿನದ ನಕ್ಷತ್ರ: ${knNak[dinaIdx]}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                    if (isExcluded) ...[  
                                      const SizedBox(height: 4),
                                      Text('⚠️ ಹೊರಗಿಡಲಾದ ನಕ್ಷತ್ರ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.orange.shade700)),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(_taras[tara1], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor), textAlign: TextAlign.center),
                                  ],
                                ),
                              );
                          } else {
                              int tara2 = (dinaIdx - _janmaNakshatraIdx2! + 27) % 27 % 9;
                              bool isGood2 = _isDayGood(dinaIdx, _janmaNakshatraIdx2!);
                              
                              Color bgColor = (isGood1 && isGood2) ? Colors.green.shade50 : (!isGood1 && !isGood2) ? Colors.red.shade50 : Colors.orange.shade50;
                              Color borderColor = (isGood1 && isGood2) ? Colors.green.shade500 : (!isGood1 && !isGood2) ? Colors.red.shade500 : Colors.orange.shade500;
                              Color textColor = (isGood1 && isGood2) ? Colors.green.shade900 : (!isGood1 && !isGood2) ? Colors.red.shade900 : Colors.orange.shade900;

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 2), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text('ಆಯ್ಕೆಮಾಡಿದ ದಿನದ ನಕ್ಷತ್ರ: ${knNak[dinaIdx]}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: Column(
                                          children: [
                                            Text('ವ್ಯಕ್ತಿ 1', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                            Text(_taras[tara1], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGood1 ? Colors.green.shade700 : Colors.red.shade700)),
                                          ]
                                        )),
                                        Container(width: 1, height: 40, color: borderColor),
                                        Expanded(child: Column(
                                          children: [
                                            Text('ವ್ಯಕ್ತಿ 2', style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                            Text(_taras[tara2], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGood2 ? Colors.green.shade700 : Colors.red.shade700)),
                                          ]
                                        )),
                                      ],
                                    )
                                  ],
                                ),
                              );
                          }
                        }
                      ),
                     ] else ...[
                       Container(
                         padding: const EdgeInsets.all(16),
                         alignment: Alignment.center,
                         decoration: BoxDecoration(color: kBorder.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                         child: Text('ಫಲಿತಾಂಶವನ್ನು ನೋಡಲು ಎರಡೂ ನಕ್ಷತ್ರಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ.', style: TextStyle(color: kMuted))
                       )
                    ],

                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text('ತಾರಾನುಕೂಲ ಚಾರ್ಟ್', style: TextStyle(fontWeight: FontWeight.bold, color: kPurple2)),
                        initiallyExpanded: _showTaraCharts,
                        onExpansionChanged: (val) => setState(() => _showTaraCharts = val),
                        backgroundColor: kCard,
                        collapsedBackgroundColor: kCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
                        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_janmaNakshatraIdx1 != null)
                                  _buildTaraChart(_janmaNakshatraIdx1!, _isTwoPersonMode ? 'ವ್ಯಕ್ತಿ 1ರ ತಾರಾನುಕೂಲ ಚಾರ್ಟ್' : 'ನಿಮ್ಮ ತಾರಾನುಕೂಲ ಚಾರ್ಟ್'),
                                if (_isTwoPersonMode && _janmaNakshatraIdx2 != null)
                                  _buildTaraChart(_janmaNakshatraIdx2!, 'ವ್ಯಕ್ತಿ 2ರ ತಾರಾನುಕೂಲ ಚಾರ್ಟ್'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingPanchang)
                       const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                    else if (_selectedDayResult != null) ...[
                      Text('ದಿನದ ಪಂಚಾಂಗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final r = _selectedDayResult!;
                        final pan = r.panchang;
                        return AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: kPurple2.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Text(
                                  '${_selectedDay!.day.toString().padLeft(2, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.year}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: kPurple2),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _tableRow(['ಸಂವತ್ಸರ', pan.samvatsara]),
                              _tableRow(['ವಾರ', pan.vara]),
                              _tableRow(['ತಿಥಿ', _formatEnd(pan.tithi, pan.tithiEndTime, pan.tithiEndsNextDay)]),
                              _tableRow(['ಚಂದ್ರ ನಕ್ಷತ್ರ', _formatEnd(() { final moonPada = r.planets['ಚಂದ್ರ']?.pada; final fallback = (pan.nakPercent * 4).floor() + 1; final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback); return '${pan.nakshatra} - ${'ಪಾದ'} $p'; }(), pan.nakEndTime, pan.nakEndsNextDay)]),
                              _tableRow(['ಯೋಗ', _formatEnd(pan.yoga, pan.yogaEndTime, pan.yogaEndsNextDay)]),
                              _tableRow(['ಕರಣ', _formatEnd(pan.karana, pan.karanaEndTime, pan.karanaEndsNextDay)]),
                              _tableRow(['ಚಂದ್ರ ರಾಶಿ', pan.chandraRashi]),
                              _tableRow(['ಚಂದ್ರ ಮಾಸ', pan.chandraMasa]),
                              _tableRow(['ಸೂರ್ಯ ನಕ್ಷತ್ರ', '${pan.suryaNakshatra} - ${'ಪಾದ'} ${pan.suryaPada}']),
                              _tableRow(['ಸೌರ ಮಾಸ', pan.souraMasa]),
                              _tableRow(['ಸೂರ್ಯೋದಯ', pan.sunrise]),
                              _tableRow(['ಸೂರ್ಯಾಸ್ತ', pan.sunset]),
                            ],
                          ),
                        );
                      }),
                    ]

                  ],
                ),
              )),
            ),
          ),

        ],
      ),
    );
  }
}
