import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sweph/sweph.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../services/location_service.dart';
import '../core/muhurta_rules.dart';

class TaranukoolaScreen extends StatefulWidget {
  const TaranukoolaScreen({super.key});

  @override
  State<TaranukoolaScreen> createState() => _TaranukoolaScreenState();
}

class _TaranukoolaScreenState extends State<TaranukoolaScreen> {
  bool _isTwoPersonMode = false;
  bool _excludeNakshatras = false;
  bool _includeAgniVasa = false;
  int? _janmaNakshatraIdx1;
  int? _janmaNakshatraIdx2;
  
  DateTime _focusedDay = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime? _selectedDay;
  Map<DateTime, int> _dailyNakshatraCache = {};
  Map<DateTime, bool> _dailyAgniVasaCache = {};
  KundaliResult? _selectedDayResult;
  bool _isLoadingPanchang = false;
  bool _showTaraCharts = false;
  MuhurtaEvent _selectedMuhurtaEvent = MuhurtaEvent.vivaha;

  List<String> get _taras => List.generate(9, (i) => AppLocale.l('tara$i'));

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
      // Compute sunrise for this date — vara starts at sunrise
      await Ephemeris.initSweph();
      final srSs = Ephemeris.findSunriseSetForDate(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
        LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
      );
      final srJd = srSs[0];
      final srLocalFrac = ((srJd + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
      final hour24 = (srLocalFrac * 24.0) + (1.0 / 60.0); // sunrise + 1 min

      final result = await AstroCalculator.calculate(
        year: _selectedDay!.year, month: _selectedDay!.month, day: _selectedDay!.day,
        hourUtcOffset: LocationService.tzOffset, 
        hour24: hour24,
        lat: LocationService.lat, 
        lon: LocationService.lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );
      if (mounted) setState(() {
        _selectedDayResult = result;
        _isLoadingPanchang = false;
      });
      _computeLagnaWindows();
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
        _includeAgniVasa = prefs.getBool('tara_include_agnivasa') ?? false;
        _janmaNakshatraIdx1 = prefs.getInt('dashboard_janma_nakshatra');
        _janmaNakshatraIdx2 = prefs.getInt('dashboard_janma_nakshatra2');
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_tara_two_person', _isTwoPersonMode);
    await prefs.setBool('tara_exclude_nakshatras', _excludeNakshatras);
    await prefs.setBool('tara_include_agnivasa', _includeAgniVasa);
    if (_janmaNakshatraIdx1 != null) await prefs.setInt('dashboard_janma_nakshatra', _janmaNakshatraIdx1!);
    if (_janmaNakshatraIdx2 != null) await prefs.setInt('dashboard_janma_nakshatra2', _janmaNakshatraIdx2!);
  }
  
  int _calculateNakshatraForDate(DateTime date) {
    // Calculate Moon's SIDEREAL position at sunrise for accurate Vedic nakshatra
    final srSs = Ephemeris.findSunriseSetForDate(
      date.year, date.month, date.day,
      LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
    );
    final srJd = srSs[0];
    // Use sunrise + 1 min to be safely past sunrise (matching panchanga)
    final jd = srJd + (1.0 / 1440.0);
    
    // Sidereal Moon using Lahiri ayanamsa
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    final pos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, 
        SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
    double moonLon = pos.longitude % 360.0;
    return (moonLon / (360.0 / 27.0)).floor() % 27;
  }

  /// Compute Agnivasa for a date: true = Prithvi (Earth, Shubha)
  bool _computeAgniVasaForDate(DateTime date) {
    DateTime normalized = DateTime(date.year, date.month, date.day);
    if (_dailyAgniVasaCache.containsKey(normalized)) {
      return _dailyAgniVasaCache[normalized]!;
    }
    try {
      final srSs = Ephemeris.findSunriseSetForDate(
        normalized.year, normalized.month, normalized.day,
        LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
      );
      final srJd = srSs[0];
      final jd = srJd + (1.0 / 1440.0);
      // Tithi at sunrise
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
      final moonPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
      final sunPos = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL);
      final tithiIdx = (((moonPos.longitude - sunPos.longitude + 360) % 360) / 12).floor().clamp(0, 29);
      // Weekday at sunrise: Sun=0..Sat=6
      // Vedic vara from panchanga sunrise
      int pyWeekday = normalized.weekday - 1; // Mon=0..Sun=6
      int wIdx = (pyWeekday + 1) % 7; // Sun=0..Sat=6
      // Check if birth JD is before sunrise — if so, use previous day's vara
      // For daily calendar, we use the date's own vara (sunrise-based)
      final agniVal = (tithiIdx + wIdx + 3) % 4;
      final isPrithvi = (agniVal == 0 || agniVal == 3);
      _dailyAgniVasaCache[normalized] = isPrithvi;
      return isPrithvi;
    } catch (_) {
      return true; // Default to good if calculation fails
    }
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

  /// Check if a day is good, considering nakshatra exclusion and Agnivasa
  bool _isDayGood(int dinaIdx, int janmaIdx, {DateTime? date}) {
    int tara = (dinaIdx - janmaIdx + 27) % 27 % 9;
    if (!_isGoodTara(tara)) return false;
    if (_excludeNakshatras && _excludedNakIndices.contains(dinaIdx)) return false;
    if (_includeAgniVasa && date != null && !_computeAgniVasaForDate(date)) return false;
    return true;
  }

  Widget _buildMarker(DateTime date, List events) {
    if (_janmaNakshatraIdx1 == null) return const SizedBox();
    if (_isTwoPersonMode && _janmaNakshatraIdx2 == null) return const SizedBox();

    int dinaIdx = _getNakshatraForDate(date);
    
    bool isGood1 = _isDayGood(dinaIdx, _janmaNakshatraIdx1!, date: date);

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
      bool isGood2 = _isDayGood(dinaIdx, _janmaNakshatraIdx2!, date: date);
      
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
    return '$base (${AppLocale.l('endLabel')}: $endTime${nextDay ? ' ${AppLocale.l('nextDayLabel')}' : ''})';
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
              String nakshatras = '${trAll(knNak[n1])}, ${trAll(knNak[n2])}, ${trAll(knNak[n3])}';

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
        title: Text(AppLocale.l('taranukoola'),
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
                    Text(AppLocale.l('taraResults'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
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
                      children: [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppLocale.l('onePerson'))),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text(AppLocale.l('twoPersons'))),
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
                              AppLocale.l('excludeBadNak'),
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
                          child: Text(trAll(knNak[idx]), style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Agnivasa toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _includeAgniVasa ? Colors.green.withOpacity(0.1) : kBorder.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _includeAgniVasa ? Colors.green : kBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 20,
                            color: _includeAgniVasa ? Colors.green.shade700 : kMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocale.l('agniVasa') + ' / Agni Vasa',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _includeAgniVasa ? Colors.green.shade700 : kMuted),
                            ),
                          ),
                          Switch(
                            value: _includeAgniVasa,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              setState(() {
                                _includeAgniVasa = val;
                                _dailyAgniVasaCache.clear();
                                _saveSettings();
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(_isTwoPersonMode ? AppLocale.l('person1BirthNak') : AppLocale.l('yourBirthNak'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
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
                          hint: Text(AppLocale.l('selectNakHint')),
                          value: _janmaNakshatraIdx1,
                          dropdownColor: kCard,
                          items: List.generate(27, (i) {
                            return DropdownMenuItem<int>(
                              value: i,
                              child: Text(trAll(knNak[i]), style: TextStyle(fontSize: 16, color: kText)),
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
                      Text(AppLocale.l('person2BirthNak'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
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
                            hint: Text(AppLocale.l('selectNakHint')),
                            value: _janmaNakshatraIdx2,
                            dropdownColor: kCard,
                            items: List.generate(27, (i) {
                              return DropdownMenuItem<int>(
                                value: i,
                                child: Text(trAll(knNak[i]), style: TextStyle(fontSize: 16, color: kText)),
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
                            final days = [AppLocale.l('wdMon'), AppLocale.l('wdTue'), AppLocale.l('wdWed'), AppLocale.l('wdThu'), AppLocale.l('wdFri'), AppLocale.l('wdSat'), AppLocale.l('wdSun')];
                            return Center(
                              child: Text(
                                days[day.weekday - 1],
                                style: TextStyle(color: day.weekday == 7 ? Colors.red.shade300 : kText, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                          headerTitleBuilder: (context, day) {
                            final months = [AppLocale.l('jan'), AppLocale.l('feb'), AppLocale.l('mar'), AppLocale.l('apr'), AppLocale.l('may'), AppLocale.l('jun'), AppLocale.l('jul'), AppLocale.l('aug'), AppLocale.l('sep'), AppLocale.l('oct'), AppLocale.l('nov'), AppLocale.l('dec')];
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
                          Text(_isTwoPersonMode ? AppLocale.l('goodBoth') : AppLocale.l('goodDay'), style: TextStyle(color: kText, fontSize: 12)),
                        ]),
                        if (_isTwoPersonMode)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(AppLocale.l('goodOnePerson'), style: TextStyle(color: kText, fontSize: 12)),
                          ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(_isTwoPersonMode ? AppLocale.l('badBoth') : AppLocale.l('badDay'), style: TextStyle(color: kText, fontSize: 12)),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    if (_selectedDay != null && _janmaNakshatraIdx1 != null && (!_isTwoPersonMode || _janmaNakshatraIdx2 != null)) ...[
                      Builder(
                        builder: (context) {
                          int dinaIdx = _getNakshatraForDate(_selectedDay!);
                          int tara1 = (dinaIdx - _janmaNakshatraIdx1! + 27) % 27 % 9;
                          bool isGood1 = _isDayGood(dinaIdx, _janmaNakshatraIdx1!, date: _selectedDay!);
                          bool isExcluded = _excludeNakshatras && _excludedNakIndices.contains(dinaIdx);
                          bool isPrithvi = _includeAgniVasa ? _computeAgniVasaForDate(_selectedDay!) : true;
                          
                          if (!_isTwoPersonMode) {
                              // If excluded, always show RED
                              Color bgColor = isExcluded ? Colors.red.shade50 : (isGood1 ? Colors.green.shade50 : Colors.red.shade50);
                              Color borderColor = isExcluded ? Colors.red.shade500 : (isGood1 ? Colors.green.shade500 : Colors.red.shade500);
                              Color textColor = isExcluded ? Colors.red.shade900 : (isGood1 ? Colors.green.shade900 : Colors.red.shade900);
                              
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 2), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text('${AppLocale.l('selectedDayNak')}: ${trAll(knNak[dinaIdx])}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                    if (isExcluded) ...[  
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.shade400),
                                        ),
                                        child: Text('⚠️ ${AppLocale.l('excludedNak')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.orange.shade900)),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(_taras[tara1], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor), textAlign: TextAlign.center),
                                    if (_includeAgniVasa) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isPrithvi ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isPrithvi ? Colors.green : Colors.red),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.local_fire_department, size: 16, color: isPrithvi ? Colors.green : Colors.red),
                                          const SizedBox(width: 6),
                                          Text(
                                            isPrithvi ? '${AppLocale.l('agniVasa')}: ${AppLocale.l('bhumiShubha')}' : '${AppLocale.l('agniVasa')}: ${AppLocale.l('patalaAshubha')}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isPrithvi ? Colors.green.shade700 : Colors.red.shade700),
                                          ),
                                        ]),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                          } else {
                              int tara2 = (dinaIdx - _janmaNakshatraIdx2! + 27) % 27 % 9;
                              bool isGood2 = _isDayGood(dinaIdx, _janmaNakshatraIdx2!, date: _selectedDay!);
                              
                              // If excluded, always show RED
                              Color bgColor = isExcluded ? Colors.red.shade50 : ((isGood1 && isGood2) ? Colors.green.shade50 : (!isGood1 && !isGood2) ? Colors.red.shade50 : Colors.orange.shade50);
                              Color borderColor = isExcluded ? Colors.red.shade500 : ((isGood1 && isGood2) ? Colors.green.shade500 : (!isGood1 && !isGood2) ? Colors.red.shade500 : Colors.orange.shade500);
                              Color textColor = isExcluded ? Colors.red.shade900 : ((isGood1 && isGood2) ? Colors.green.shade900 : (!isGood1 && !isGood2) ? Colors.red.shade900 : Colors.orange.shade900);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 2), borderRadius: BorderRadius.circular(12)),
                                child: Column(
                                  children: [
                                    Text('${AppLocale.l('selectedDayNak')}: ${trAll(knNak[dinaIdx])}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                    if (isExcluded) ...[  
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.shade400),
                                        ),
                                        child: Text('⚠️ ${AppLocale.l('excludedNak')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.orange.shade900)),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: Column(
                                          children: [
                                            Text(AppLocale.l('person1'), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                            Text(_taras[tara1], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGood1 ? Colors.green.shade700 : Colors.red.shade700)),
                                          ]
                                        )),
                                        Container(width: 1, height: 40, color: borderColor),
                                        Expanded(child: Column(
                                          children: [
                                            Text(AppLocale.l('person2'), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                                            Text(_taras[tara2], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGood2 ? Colors.green.shade700 : Colors.red.shade700)),
                                          ]
                                        )),
                                      ],
                                    ),
                                    if (_includeAgniVasa) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isPrithvi ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: isPrithvi ? Colors.green : Colors.red),
                                        ),
                                        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Icon(Icons.local_fire_department, size: 16, color: isPrithvi ? Colors.green : Colors.red),
                                          const SizedBox(width: 6),
                                          Text(
                                            isPrithvi ? '${AppLocale.l('agniVasa')}: ${AppLocale.l('bhumiShubha')}' : '${AppLocale.l('agniVasa')}: ${AppLocale.l('patalaAshubha')}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isPrithvi ? Colors.green.shade700 : Colors.red.shade700),
                                          ),
                                        ]),
                                      ),
                                    ],
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
                         child: Text(AppLocale.l('selectBothNak'), style: TextStyle(color: kMuted))
                       )
                    ],

                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(AppLocale.l('taraChart'), style: TextStyle(fontWeight: FontWeight.bold, color: kPurple2)),
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
                                  _buildTaraChart(_janmaNakshatraIdx1!, _isTwoPersonMode ? AppLocale.l('person1TaraChart') : AppLocale.l('yourTaraChart')),
                                if (_isTwoPersonMode && _janmaNakshatraIdx2 != null)
                                  _buildTaraChart(_janmaNakshatraIdx2!, AppLocale.l('person2TaraChart')),
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
                      Text(AppLocale.l('dayPanchanga'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
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
                              _tableRow([AppLocale.l('samvatsaraLabel'), trAll(pan.samvatsara)]),
                              _tableRow([AppLocale.l('varaLabel'), trAll(pan.vara)]),
                              _tableRow([AppLocale.l('tithiLabel'), _formatEnd(trAll(pan.tithi), pan.tithiEndTime, pan.tithiEndsNextDay)]),
                              _tableRow([AppLocale.l('chandraNakLabel'), _formatEnd(() { final moonPada = r.planets['ಚಂದ್ರ']?.pada; final fallback = (pan.nakPercent * 4).floor() + 1; final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback); return '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} $p'; }(), pan.nakEndTime, pan.nakEndsNextDay)]),
                              _tableRow([AppLocale.l('yogaLabel'), _formatEnd(trAll(pan.yoga), pan.yogaEndTime, pan.yogaEndsNextDay)]),
                              _tableRow([AppLocale.l('karanaLabel'), _formatEnd(trAll(pan.karana), pan.karanaEndTime, pan.karanaEndsNextDay)]),
                              _tableRow([AppLocale.l('chandraRashiLabel'), trAll(pan.chandraRashi)]),
                              _tableRow([AppLocale.l('chandraMasaLabel'), trAll(pan.chandraMasa)]),
                              _tableRow([AppLocale.l('suryaNakLabel'), '${trAll(pan.suryaNakshatra)} - ${AppLocale.l('padaLabel')} ${pan.suryaPada}']),
                              _tableRow([AppLocale.l('souraMasaLabel'), trAll(pan.souraMasa)]),
                              _tableRow([AppLocale.l('sunriseLabel'), pan.sunrise]),
                              _tableRow([AppLocale.l('sunsetLabel'), pan.sunset]),
                            ],
                          ),
                        );
                      }),
                    ],

                  // ── Muhurta Section ──
                  if (!_isLoadingPanchang && _selectedDayResult != null)
                    _buildMuhurtaSection(),

                  ],
                ),
              )),
            ),
          ),

        ],
      ),
    );
  }

  // ============================================================
  // MUHURTA SECTIONS
  // ============================================================

  Widget _buildMuhurtaSection() {
    if (_selectedDayResult == null) return const SizedBox();
    final r = _selectedDayResult!;
    final pan = r.panchang;
    final rules = muhurtaRules[_selectedMuhurtaEvent];
    if (rules == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        // ── Event Selector ──
        Text(AppLocale.l('muhurtaRules'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
        const SizedBox(height: 10),
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
              value: _selectedMuhurtaEvent,
              dropdownColor: kCard,
              items: MuhurtaEvent.values.map((e) {
                final info = muhurtaEventNames[e]!;
                return DropdownMenuItem(
                  value: e,
                  child: Text('${AppLocale.l(info.localeKey)} (${info.englishName})',
                      style: TextStyle(fontSize: 13, color: kText)),
                );
              }).toList(),
              onChanged: (e) { if (e != null) setState(() { _selectedMuhurtaEvent = e; _computeLagnaWindows(); }); },
            ),
          ),
        ),

        // ── 5 Rules Display ──
        const SizedBox(height: 12),
        _buildEventRulesCard(rules),


        // ── Panchanga Shuddhi ──
        const SizedBox(height: 12),
        _buildPanchangaShuddhi(pan, rules),

        // ── Nimma Balagalu ──
        if (_janmaNakshatraIdx1 != null) ...[
          const SizedBox(height: 12),
          _buildBala(r, 1),
          if (_isTwoPersonMode && _janmaNakshatraIdx2 != null) ...[
            const SizedBox(height: 8),
            _buildBala(r, 2),
          ],
        ],

        // ── 15 Day Muhurtas ──
        const SizedBox(height: 12),
        _buildMuhurtaTimings(pan, true),

        // ── 15 Night Muhurtas ──
        const SizedBox(height: 12),
        _buildMuhurtaTimings(pan, false),

        // ── Day Lagna Shuddhi ──
        const SizedBox(height: 12),
        _buildLagnaShuddhi(true, rules),

        // ── Night Lagna Shuddhi ──
        const SizedBox(height: 12),
        _buildLagnaShuddhi(false, rules),
      ],
    );
  }

  // ── Event Rules Card ──
  Widget _buildEventRulesCard(MuhurtaEventRules rules) {
    String tithiText = rules.allowedTithis == null
        ? AppLocale.l('allTithi')
        : rules.allowedTithis!.map((i) => trAll(knTithi[i])).join(', ');
    if (rules.requireShukla) tithiText = '${AppLocale.l('shuklaOnly')}: $tithiText';

    String nakText = rules.allowedNakshatras == null
        ? AppLocale.l('allNak')
        : rules.allowedNakshatras!.map((i) => trAll(knNak[i])).join(', ');
    String varaText = rules.allowedVaras == null
        ? AppLocale.l('allVara')
        : rules.allowedVaras!.map((i) => trAll(knVara[i])).join(', ');

    final shuddhis = rules.requiredShuddhis.map((s) {
      switch (s) {
        case ShuddhiType.lagna: return AppLocale.l('lagnaLabel');
        case ShuddhiType.saptama: return AppLocale.l('saptama');
        case ShuddhiType.ashtama: return AppLocale.l('ashtama');
        case ShuddhiType.dashama: return AppLocale.l('dashama');
        case ShuddhiType.chandraSaptama: return AppLocale.l('chandraSaptama');
      }
    }).join(' + ');

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocale.l('rulesTitle'), style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
          const SizedBox(height: 8),
          _ruleRow(AppLocale.l('rTithi'), tithiText),
          const SizedBox(height: 4),
          _ruleRow(AppLocale.l('rNak'), nakText),
          const SizedBox(height: 4),
          _ruleRow(AppLocale.l('rVara'), varaText),
          const SizedBox(height: 4),
          _ruleRow(AppLocale.l('rLagna'), rules.allowedLagnas == null ? AppLocale.l('anyLagna') : rules.allowedLagnas!.map((i) => trAll(knRashi[i])).join(', ')),
          const SizedBox(height: 4),
          _ruleRow(AppLocale.l('rShuddhi'), shuddhis, valueColor: kPurple1, valueBold: true),
        ],
      ),
    );
  }

  Widget _ruleRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: TextStyle(
          color: valueColor ?? kMuted, fontSize: 12,
          fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
        ), softWrap: true)),
      ]),
    );
  }

  // ── Panchanga Shuddhi ──
  Widget _buildPanchangaShuddhi(PanchangData pan, MuhurtaEventRules rules) {
    final tIdx = pan.tithiIndex;
    final nIdx = pan.nakshatraIndex;
    final varaIdx = knVara.indexOf(pan.vara);
    final isVishti = pan.karana.contains('ವಿಷ್ಟಿ') || pan.karana.contains('ಭದ್ರ');

    final tithiOk = rules.allowedTithis == null || rules.allowedTithis!.contains(tIdx);
    final nakOk = rules.allowedNakshatras == null || rules.allowedNakshatras!.contains(nIdx);
    final varaOk = rules.allowedVaras == null || rules.allowedVaras!.contains(varaIdx);
    final karanaOk = !rules.avoidVishti || !isVishti;
    final pakshaOk = !rules.requireShukla || (tIdx >= 0 && tIdx <= 14);

    final checks = [
      {'label': AppLocale.l('tithiLabel'), 'value': trAll(pan.tithi), 'ok': tithiOk},
      {'label': AppLocale.l('nakshatra'), 'value': trAll(pan.nakshatra), 'ok': nakOk},
      {'label': AppLocale.l('varaLabel'), 'value': trAll(pan.vara), 'ok': varaOk},
      {'label': AppLocale.l('karanaLabel'), 'value': trAll(pan.karana), 'ok': karanaOk},
      if (rules.requireShukla)
        {'label': AppLocale.l('paksha'), 'value': tIdx <= 14 ? AppLocale.l('shukla') : AppLocale.l('krishna'), 'ok': pakshaOk},
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: kCard,
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kPurple1.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(AppLocale.l('panchaShuddhi'), style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 14)),
        ),
        ...checks.map((c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5))),
          ),
          child: Row(children: [
            Icon(c['ok'] as bool ? Icons.check_circle : Icons.cancel,
                color: c['ok'] as bool ? Colors.green : Colors.red, size: 18),
            const SizedBox(width: 10),
            Text(c['label'] as String, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13)),
            const Spacer(),
            Text(c['value'] as String, style: TextStyle(color: kMuted, fontSize: 13)),
          ]),
        )),
      ]),
    );
  }

  // ── Bala (Person Strength) ──
  Widget _buildBala(KundaliResult r, int personNum) {
    final janmaIdx = personNum == 1 ? _janmaNakshatraIdx1! : _janmaNakshatraIdx2!;
    final dinaIdx = r.panchang.nakshatraIndex;
    final taraIdx = (dinaIdx - janmaIdx + 27) % 27 % 9;
    final isGoodTara = (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
    final taraName = _taras[taraIdx];

    // Chandra Bala: Moon in upachaya (3, 6, 10, 11) from janma rashi
    final moonRashi = r.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
    final janmaRashi = (janmaIdx ~/ 3) % 12; // approximate rashi from nakshatra
    final moonHouse = ((moonRashi - janmaRashi + 12) % 12) + 1;
    final chandraBala = const [3, 6, 10, 11].contains(moonHouse);

    final label = _isTwoPersonMode ? '👤 ${AppLocale.l(personNum == 1 ? 'person1' : 'person2')} ${AppLocale.l('personBalas')}' : '👤 ${AppLocale.l('yourBalas')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(10),
        color: kCard,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
        const SizedBox(height: 8),
        _balaChipRow(AppLocale.l('taraBala'), taraName, isGoodTara),
        _balaChipRow(AppLocale.l('chandraBala'), chandraBala ? AppLocale.l('anukoola') : AppLocale.l('pratikoola'), chandraBala),
      ]),
    );
  }

  Widget _balaChipRow(String label, String value, bool good) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(good ? Icons.check_circle : Icons.cancel, color: good ? Colors.green : Colors.red, size: 16),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: kText, fontSize: 12)),
        const Spacer(),
        Text(value, style: TextStyle(color: good ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }

  // ── Muhurta Timings (Day / Night) ──
  static List<String> get _dayMuhurtaNames => [
    for (int i = 0; i < 15; i++) AppLocale.l('muh$i'),
  ];
  static const List<bool?> _dayMuhurtaNature = [
    false, false, true, false, true,
    true, true, true, true, true,
    false, false, true, null, false,
  ];
  static List<String> get _nightMuhurtaNames => [
    for (int i = 0; i < 15; i++) AppLocale.l('nmuh$i'),
  ];
  static const List<bool?> _nightMuhurtaNature = [
    false, false, false, true, true,
    false, false, true, false, true,
    true, true, true, false, false,
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
    int totalMins = mins.round();
    if (totalMins < 0) totalMins += 1440;
    int h = (totalMins ~/ 60) % 24;
    final m = totalMins % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildMuhurtaTimings(PanchangData pan, bool isDay) {
    final sr = _parseTimeToMinutes(pan.sunrise);
    final ss = _parseTimeToMinutes(pan.sunset);
    final names = isDay ? _dayMuhurtaNames : _nightMuhurtaNames;
    final natures = isDay ? _dayMuhurtaNature : _nightMuhurtaNature;
    final Color headerColor = isDay ? const Color(0xFF8E44AD) : const Color(0xFF2C3E50);
    final String headerText = isDay ? '☀️ ${AppLocale.l('dayMuhurtaTimings')}' : '🌙 ${AppLocale.l('nightMuhurtaTimings')}';

    double duration;
    double startMin;
    if (isDay) {
      duration = (ss - sr) / 15.0;
      startMin = sr;
    } else {
      // Night: sunset to next sunrise (~= sunset + (24h - dayLen))
      final nightLen = 1440.0 - (ss - sr);
      duration = nightLen / 15.0;
      startMin = ss;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: kCard,
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(headerText, style: TextStyle(fontWeight: FontWeight.w800, color: headerColor, fontSize: 14)),
        ),
        ...List.generate(15, (i) {
          final start = startMin + i * duration;
          final end = start + duration;
          final nature = natures[i];
          final isAbhijit = isDay && i == 7;

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
              border: i < 14 ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4))) : null,
            ),
            child: Row(children: [
              SizedBox(width: 24, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w700, color: kMuted, fontSize: 12))),
              Text(natureIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(names[i], style: TextStyle(
                fontWeight: isAbhijit ? FontWeight.w900 : FontWeight.w600,
                color: isAbhijit ? Colors.amber.shade800 : kText, fontSize: 13,
              ))),
              Text('${_minutesToTimeStr(start)} - ${_minutesToTimeStr(end)}', style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Lagna Shuddhi (Day + Night) ──
  List<LagnaWindow>? _dayLagnaWindows;
  List<LagnaWindow>? _nightLagnaWindows;

  void _computeLagnaWindows() {
    if (_selectedDay == null || _selectedDayResult == null) return;
    final r = _selectedDayResult!;
    final rules = muhurtaRules[_selectedMuhurtaEvent];
    final allowedLagnas = rules?.allowedLagnas;

    // Get planet rashi positions (exclude Mandi — we compute it per-period)
    final Map<String, int> basePlanetRashis = {};
    for (final entry in r.planets.entries) {
      if (entry.key == 'ಮಾಂದಿ') continue;
      basePlanetRashis[entry.key] = entry.value.rashiIndex;
    }
    final guruRashiIdx = basePlanetRashis['ಗುರು'] ?? -1;

    try {
      // Panchanga sunrise/sunset (with tzOffset) — for lagna window scanning
      final srSs = Ephemeris.findSunriseSetForDate(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
        LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
      );
      final double srJd = srSs[0];
      final double ssJd = srSs[1];

      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
      final ayn = Sweph.swe_get_ayanamsa(srJd);

      // Mandi sunrise/sunset (WITHOUT tzOffset, 0° horizon) — matching calcMandi exactly
      final mandiSrSs = Ephemeris.findSunriseSetForDate(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
        LocationService.lat, LocationService.lon,
      );
      final double mandiSr = mandiSrSs[0];
      final double mandiSs = mandiSrSs[1];

      // Vedic weekday: Sun=0..Sat=6
      int pyWeekday = _selectedDay!.weekday - 1; // Mon=0..Sun=6
      int vedicWday = (pyWeekday + 1) % 7; // Sun=0..Sat=6

      // ── DAY Mandi ──
      final dayDuration = mandiSs - mandiSr;
      const dayFactors = [26, 22, 18, 14, 10, 6, 2];
      final dayMandiJd = mandiSr + (dayDuration * dayFactors[vedicWday] / 30.0);
      final dayMandiRashi = _mandiRashiFromJd(dayMandiJd);

      final dayPlanetRashis = Map<String, int>.from(basePlanetRashis);
      if (dayMandiRashi >= 0) dayPlanetRashis['ಮಾಂದಿ'] = dayMandiRashi;

      final dayW = _scanLagnaRange(srJd, ssJd, ayn, dayPlanetRashis, guruRashiIdx, allowedLagnas, rules);

      // ── NIGHT Mandi ──
      final nextDay = _selectedDay!.add(const Duration(days: 1));
      final nextSrSs = Ephemeris.findSunriseSetForDate(
        nextDay.year, nextDay.month, nextDay.day,
        LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
      );
      final double nextSrJd = nextSrSs[0];

      // Night Mandi sunrise: next day's sunrise WITHOUT tzOffset
      final nextMandiSrSs = Ephemeris.findSunriseSetForDate(
        nextDay.year, nextDay.month, nextDay.day,
        LocationService.lat, LocationService.lon,
      );
      final double nextMandiSr = nextMandiSrSs[0];

      final nightDuration = nextMandiSr - mandiSs;
      const nightFactors = [10, 6, 2, 26, 22, 18, 14];
      final nightMandiJd = mandiSs + (nightDuration * nightFactors[vedicWday] / 30.0);
      final nightMandiRashi = _mandiRashiFromJd(nightMandiJd);

      final nightPlanetRashis = Map<String, int>.from(basePlanetRashis);
      if (nightMandiRashi >= 0) nightPlanetRashis['ಮಾಂದಿ'] = nightMandiRashi;

      final nightW = _scanLagnaRange(ssJd, nextSrJd, ayn, nightPlanetRashis, guruRashiIdx, allowedLagnas, rules);

      if (mounted) setState(() {
        _dayLagnaWindows = dayW;
        _nightLagnaWindows = nightW;
      });
    } catch (_) {
      if (mounted) setState(() {
        _dayLagnaWindows = [];
        _nightLagnaWindows = [];
      });
    }
  }

  /// Get Mandi rashi from its JD — matches calculator.dart lines 612-617 exactly
  int _mandiRashiFromJd(double mandiJd) {
    try {
      final houses = Ephemeris.placidusHousesFull(
        mandiJd, LocationService.lat, LocationService.lon,
      );
      if (houses != null && houses.ascmc.length >= 1) {
        // Ayanamsa at mandiJd — NOT at sunrise (matching calcMandi)
        Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
        final aMandi = Sweph.swe_get_ayanamsa(mandiJd);
        final mandiDeg = ((houses.ascmc[0] as double) - aMandi + 360.0) % 360.0;
        return (mandiDeg / 30.0).floor() % 12;
      }
    } catch (_) {}
    return -1;
  }

  List<LagnaWindow> _scanLagnaRange(double startJd, double endJd, double ayn,
      Map<String, int> planetRashis, int guruRashiIdx, List<int>? allowedLagnas, MuhurtaEventRules? rules) {
    final double step = 10.0 / (24.0 * 60.0); // 10 min
    final List<_AscSample> samples = [];
    double jd = startJd;
    while (jd <= endJd + step) {
      final houses = Ephemeris.placidusHousesFull(jd, LocationService.lat, LocationService.lon);
      if (houses != null && houses.ascmc.length >= 1) {
        final sidAsc = ((houses.ascmc[0] as double) - ayn) % 360.0;
        final rashiIdx = (sidAsc / 30.0).floor() % 12;
        final localFrac = ((jd + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final localMins = localFrac * 24.0 * 60.0;
        samples.add(_AscSample(jd: jd, rashiIdx: rashiIdx, localMins: localMins));
      }
      jd += step;
    }
    if (samples.isEmpty) return [];

    // English → Kannada planet name mapping for Ephemeris.calcAll keys
    const engToKn = {
      'Sun': 'ರವಿ', 'Moon': 'ಚಂದ್ರ', 'Mercury': 'ಬುಧ', 'Venus': 'ಶುಕ್ರ',
      'Mars': 'ಕುಜ', 'Jupiter': 'ಗುರು', 'Saturn': 'ಶನಿ',
      'Rahu': 'ರಾಹು', 'Ketu': 'ಕೇತು',
    };

    final List<LagnaWindow> windows = [];
    int currentRashi = samples.first.rashiIdx;
    double startMins = samples.first.localMins;
    double windowStartJd = samples.first.jd;

    for (int i = 1; i < samples.length; i++) {
      if (samples[i].rashiIdx != currentRashi || i == samples.length - 1) {
        final endMins = samples[i].localMins;
        final windowEndJd = samples[i].jd;

        // ── Recalculate planet positions at this window's midpoint ──
        final midJd = (windowStartJd + windowEndJd) / 2.0;
        final freshPositions = Ephemeris.calcAll(midJd, 'lahiri', true);

        // Build per-window planet rashi map from fresh sidereal longitudes
        final Map<String, int> windowPlanetRashis = {};
        for (final entry in freshPositions.entries) {
          final knName = engToKn[entry.key];
          if (knName != null) {
            windowPlanetRashis[knName] = (entry.value[0] / 30.0).floor() % 12;
          }
        }
        // Keep Mandi from the passed-in map (already computed for day/night)
        if (planetRashis.containsKey('ಮಾಂದಿ')) {
          windowPlanetRashis['ಮಾಂದಿ'] = planetRashis['ಮಾಂದಿ']!;
        }

        // Per-window Guru rashi from fresh positions
        final windowGuruRashiIdx = windowPlanetRashis['ಗುರು'] ?? -1;

        final saptamaRashi = (currentRashi + 6) % 12;
        final ashtamaRashi = (currentRashi + 7) % 12;
        final dashamaRashi = (currentRashi + 9) % 12;

        final lagnaM = findAllPlanetsInRashi(currentRashi, windowPlanetRashis);
        final saptamaM = _selectedMuhurtaEvent == MuhurtaEvent.vivaha
            ? findAllPlanetsInRashi(saptamaRashi, windowPlanetRashis)
            : findMaleficsInRashi(saptamaRashi, windowPlanetRashis);
        final ashtamaM = findAllPlanetsInRashi(ashtamaRashi, windowPlanetRashis);
        final rashiLords = [4, 5, 3, 1, 0, 3, 5, 4, 8, 6, 6, 8];
        if (rashiLords[currentRashi] == rashiLords[ashtamaRashi]) ashtamaM.clear();
        final dashamaM = findAllPlanetsInRashi(dashamaRashi, windowPlanetRashis);

        final chandraRashi = windowPlanetRashis['ಚಂದ್ರ'] ?? -1;
        final chandraSaptamaRashi = chandraRashi >= 0 ? (chandraRashi + 6) % 12 : -1;
        final List<String> chandraSaptamaM = [];
        if (chandraSaptamaRashi >= 0) {
          if (windowPlanetRashis['ರವಿ'] == chandraSaptamaRashi) chandraSaptamaM.add('ರವಿ');
          if (windowPlanetRashis['ಕುಜ'] == chandraSaptamaRashi) chandraSaptamaM.add('ಕುಜ');
          if (windowPlanetRashis['ಶನಿ'] == chandraSaptamaRashi) chandraSaptamaM.add('ಶನಿ');
        }

        final guruOk = windowGuruRashiIdx >= 0 ? isGuruAnukoolaForLagna(currentRashi, windowGuruRashiIdx) : false;
        final guruHouse = windowGuruRashiIdx >= 0 ? ((windowGuruRashiIdx - currentRashi + 12) % 12) + 1 : 0;
        final bool isLagnaAllowed = allowedLagnas == null || allowedLagnas.contains(currentRashi);

        windows.add(LagnaWindow(
          rashiIndex: currentRashi,
          rashiName: appRashi[currentRashi],
          startTime: _minutesToTimeStr(startMins),
          endTime: _minutesToTimeStr(endMins),
          isAllowed: isLagnaAllowed,
          lagnaShuddhi: lagnaM.isEmpty,
          saptamaShuddhi: saptamaM.isEmpty,
          ashtamaShuddhi: ashtamaM.isEmpty,
          dashamaShuddhi: dashamaM.isEmpty,
          chandraSaptamaShuddhi: chandraSaptamaM.isEmpty,
          guruAnukoola: guruOk,
          lagnaGrahas: lagnaM,
          saptamaGrahas: saptamaM,
          ashtamaGrahas: ashtamaM,
          dashamaGrahas: dashamaM,
          chandraSaptamaGrahas: chandraSaptamaM,
          guruFromLagna: guruHouse,
          requiredShuddhis: rules?.requiredShuddhis ?? const {ShuddhiType.lagna},
        ));

        currentRashi = samples[i].rashiIdx;
        startMins = samples[i].localMins;
        windowStartJd = samples[i].jd;
      }
    }
    return windows;
  }

  Widget _buildLagnaShuddhi(bool isDay, MuhurtaEventRules rules) {
    final windows = isDay ? _dayLagnaWindows : _nightLagnaWindows;
    if (windows == null || windows.isEmpty) return const SizedBox();

    final Color headerColor = isDay ? const Color(0xFF2E86AB) : const Color(0xFF2C3E50);
    final String headerText = isDay ? '🏠 ${AppLocale.l('dayLagnaLabel')}' : '🌙 ${AppLocale.l('nightLagnaLabel')}';

    final req = rules.requiredShuddhis;
    final parts = <String>[];
    if (req.contains(ShuddhiType.lagna)) parts.add(AppLocale.l('lagnaLabel'));
    if (req.contains(ShuddhiType.saptama)) parts.add(AppLocale.l('saptama'));
    if (req.contains(ShuddhiType.ashtama)) parts.add(AppLocale.l('ashtama'));
    if (req.contains(ShuddhiType.dashama)) parts.add(AppLocale.l('dashama'));
    if (req.contains(ShuddhiType.chandraSaptama)) parts.add(AppLocale.l('chandraSaptamaShort'));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
        color: kCard,
      ),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(headerText, style: TextStyle(fontWeight: FontWeight.w800, color: headerColor, fontSize: 14), softWrap: true),
            const SizedBox(height: 4),
            Text('${AppLocale.l('needShuddhi')}: ${parts.join(' + ')} ${AppLocale.l('shuddhaLabel')} + ${AppLocale.l('guruAnukoola').split(' ')[0]} ${AppLocale.l('anukoola')}',
                style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w500), softWrap: true),
          ]),
        ),
        ...windows.asMap().entries.map((entry) {
          final i = entry.key;
          final lw = entry.value;

          Color rowBg;
          IconData rowIcon;
          Color iconColor;
          if (lw.isPerfect) {
            rowBg = Colors.green.withOpacity(0.1);
            rowIcon = Icons.star;
            iconColor = Colors.amber.shade700;
          } else if (lw.isShubha) {
            rowBg = Colors.green.withOpacity(0.05);
            rowIcon = Icons.check_circle;
            iconColor = Colors.green;
          } else if (lw.isAllowed) {
            rowBg = Colors.orange.withOpacity(0.05);
            rowIcon = Icons.warning_amber_rounded;
            iconColor = Colors.orange;
          } else {
            rowBg = Colors.red.withOpacity(0.03);
            rowIcon = Icons.remove_circle_outline;
            iconColor = Colors.red.shade300;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: rowBg,
              border: i < windows.length - 1 ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4))) : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(rowIcon, color: iconColor, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(trAll(lw.rashiName), style: TextStyle(
                  fontWeight: lw.isShubha ? FontWeight.w800 : FontWeight.w500,
                  color: lw.isShubha ? kText : kMuted, fontSize: 13,
                ))),
                Text('${lw.startTime} - ${lw.endTime}', style: TextStyle(
                  fontSize: 12, color: lw.isShubha ? Colors.green.shade700 : kMuted, fontWeight: FontWeight.w600,
                )),
              ]),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                _shuddhiChip(AppLocale.l('lagnaLabel'), lw.lagnaShuddhi, lw.lagnaGrahas,
                    required: lw.requiredShuddhis.contains(ShuddhiType.lagna)),
                _shuddhiChip(AppLocale.l('saptamaShort'), lw.saptamaShuddhi, lw.saptamaGrahas,
                    required: lw.requiredShuddhis.contains(ShuddhiType.saptama)),
                _shuddhiChip(AppLocale.l('ashtamaShort'), lw.ashtamaShuddhi, lw.ashtamaGrahas,
                    required: lw.requiredShuddhis.contains(ShuddhiType.ashtama)),
                _shuddhiChip(AppLocale.l('dashamaShort'), lw.dashamaShuddhi, lw.dashamaGrahas,
                    required: lw.requiredShuddhis.contains(ShuddhiType.dashama)),
                if (lw.requiredShuddhis.contains(ShuddhiType.chandraSaptama) || lw.chandraSaptamaGrahas.isNotEmpty)
                  _shuddhiChip(AppLocale.l('chandraSaptamaShort'), lw.chandraSaptamaShuddhi, lw.chandraSaptamaGrahas,
                      required: lw.requiredShuddhis.contains(ShuddhiType.chandraSaptama)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lw.guruAnukoola ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: lw.guruAnukoola ? Colors.amber.shade600 : Colors.grey.shade300, width: 0.5),
                  ),
                  child: Text(
                    lw.guruAnukoola ? '${AppLocale.l('guruAnukoola').split(' ')[0]} ✓ (${lw.guruFromLagna})' : '${AppLocale.l('guruPratikoola').split(' ')[0]} ✗ (${lw.guruFromLagna})',
                    style: TextStyle(fontSize: 10, color: lw.guruAnukoola ? Colors.amber.shade800 : kMuted, fontWeight: FontWeight.w700),
                  ),
                ),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _shuddhiChip(String label, bool isShuddha, List<String> grahas, {bool required = true}) {
    if (!required) {
      final text = isShuddha ? '$label ✓' : '$label ✗ ${grahas.map((m) => trAll(m)).join(',')}';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(text, style: TextStyle(fontSize: 9, color: kMuted, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic), softWrap: true),
      );
    }
    final MaterialColor color = isShuddha ? Colors.green : Colors.red;
    final text = isShuddha ? '$label ✓' : '$label ✗ ${grahas.map((m) => trAll(m)).join(',')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.w700), softWrap: true),
    );
  }
}

class _AscSample {
  final double jd;
  final int rashiIdx;
  final double localMins;
  _AscSample({required this.jd, required this.rashiIdx, required this.localMins});
}
