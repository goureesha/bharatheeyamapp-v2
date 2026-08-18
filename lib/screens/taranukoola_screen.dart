import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sweph/sweph.dart' hide kIsWeb;
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../services/location_service.dart';
import '../core/muhurta_rules.dart';
import '../services/panchanga_cache.dart';
import '../core/user_muhurta_rules.dart';
import '../widgets/muhurta_rules_editor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/app_access_service.dart';
import 'support_screen.dart';
import 'dashboard_screen.dart';

class TaranukoolaScreen extends StatefulWidget {
  const TaranukoolaScreen({super.key});

  @override
  State<TaranukoolaScreen> createState() => _TaranukoolaScreenState();
}



class _TaranukoolaScreenState extends State<TaranukoolaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
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

  // ── Muhurta Finder state (Tab 2) ──
  int _mfRashiIdx = 0;
  int _mfNakIdx = 0;
  MuhurtaEvent _mfEvent = MuhurtaEvent.grihaPrevesha;
  DateTime _mfMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _mfMonthEnd = DateTime(DateTime.now().year, DateTime.now().month + 2);
  bool _mfSearching = false;
  List<Map<String, dynamic>> _mfResults = [];
  Map<String, dynamic>? _mfStats;
  int _mfDisplayCount = 20;
  bool _mfUsedCache = false; // whether results came from cached scan
  final Set<String> _expandedResults = {};

  // Cache state
  bool _cacheGenerating = false;
  bool _cacheComplete = false;
  int _cacheProgress = 0;
  int _cacheTotal = 0;

  // ── Ready Muhurta state (Tab 3) ──


  /// Returns nakshatra indices belonging to a rashi (each rashi spans ~2.25 nakshatras)
  List<int> _naksForRashi(int rashiIdx) {
    final naks = <int>[];
    for (int n = 0; n < 27; n++) {
      for (int p = 0; p < 4; p++) {
        if ((n * 4 + p) ~/ 9 == rashiIdx) {
          naks.add(n);
          break;
        }
      }
    }
    return naks;
  }

  List<String> get _taras => List.generate(9, (i) => AppLocale.l('tara$i'));

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _loadNakshatra();
    _calculatePanchangForSelectedDay();
    // Load pre-computed panchanga cache
    PanchangaCache.instance.loadFromStorage().then((_) {
      if (mounted) setState(() {});
    });
    // Load user-customized rules
    UserRulesManager.instance.loadAll().then((_) {
      if (mounted) setState(() {});
    });
  }



  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: kPurple1,
          unselectedLabelColor: kMuted,
          indicatorColor: kPurple1,
          labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(text: AppLocale.l('taranukoola')),
            Tab(text: AppLocale.l('muhurtaShodhane')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ════ TAB 1: Existing Taranukoola Calendar ════
          _buildTaranukoolaTab(),
          // ════ TAB 2: Muhurta Finder ════
          _buildMuhurtaFinderTab(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // TAB 1: Existing Taranukoola Calendar
  // ════════════════════════════════════════════════
  Widget _buildTaranukoolaTab() {
    return Column(
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
      );
  }

  // ════════════════════════════════════════════════
  // TAB 2: Muhurta Finder
  // ════════════════════════════════════════════════

  // Rahu Kala muhurta indices per weekday (Sun=0..Sat=6)
  static const _rahuKalaMuhurta = [8, 2, 7, 5, 6, 4, 3];

  String _rahuKalaTime(DateTime date, String sunrise, String sunset) {
    final srMins = _parseTimeToMins(sunrise);
    final ssMins = _parseTimeToMins(sunset);
    if (srMins < 0 || ssMins < 0) return '';
    final dayLen = ssMins - srMins;
    final kalaLen = dayLen ~/ 8;
    final idx = _rahuKalaMuhurta[date.weekday % 7];
    final start = srMins + (idx - 1) * kalaLen;
    final end = start + kalaLen;
    return '${_minsToTime(start)} - ${_minsToTime(end)}';
  }

  int _parseTimeToMins(String t) {
    try {
      final parts = t.replaceAll(RegExp(r'[APMapm\s]'), '').split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      if (t.toUpperCase().contains('PM') && h != 12) h += 12;
      if (t.toUpperCase().contains('AM') && h == 12) h = 0;
      return h * 60 + m;
    } catch (_) { return -1; }
  }

  String _minsToTime(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
  }

  /// Generate panchanga cache (configurable years)
  Future<void> _generateCache() async {
    if (_cacheGenerating) return;

    // Ask user for year range
    final years = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text(AppLocale.l('mGenerateCacheTitle'), style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppLocale.l('mYearsCachePrompt')}\nLocation: ${LocationService.place}',
              style: TextStyle(color: kMuted, fontSize: 13)),
            const SizedBox(height: 12),
            ...[1, 5, 10, 20].map((y) => ListTile(
              dense: true,
              title: Text('$y ${AppLocale.l('mYear')} (~${y * 365} ${AppLocale.l('mDaysApprox')})', style: TextStyle(color: kText, fontWeight: FontWeight.w600)),
              trailing: Icon(Icons.arrow_forward_ios, size: 14, color: kMuted),
              onTap: () => Navigator.pop(ctx, y),
            )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('cancel'), style: TextStyle(color: kMuted))),
        ],
      ),
    );
    if (years == null) return;

    setState(() { _cacheGenerating = true; _cacheComplete = false; _cacheProgress = 0; _cacheTotal = 0; });
    await Future.delayed(const Duration(milliseconds: 50));

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = now.add(Duration(days: 365 * years));

    await PanchangaCache.instance.generate(
      startDate: startDate,
      endDate: endDate,
      lat: LocationService.lat,
      lon: LocationService.lon,
      tzOffset: LocationService.tzOffset,
      zoneName: LocationService.place,
      onProgress: (cur, total) {
        if (mounted) setState(() { _cacheProgress = cur; _cacheTotal = total; });
      },
    );

    if (mounted) {
      setState(() { _cacheGenerating = false; _cacheComplete = true; });
    }
  }

  /// Compute lagna windows on-demand for a single cached result
  Future<void> _computeLagnaForResult(Map<String, dynamic> r) async {
    if (r['needsLagna'] != true) return;
    final date = r['date'] as DateTime;
    try {
      await Ephemeris.initSweph();
      final srSs = Ephemeris.findSunriseSetForDate(
        date.year, date.month, date.day,
        LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
      );
      final srLocalFrac = ((srSs[0] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
      final hour24 = (srLocalFrac * 24.0) + (1.0 / 60.0);

      final kr = await AstroCalculator.calculate(
        year: date.year, month: date.month, day: date.day,
        hourUtcOffset: LocationService.tzOffset,
        hour24: hour24,
        lat: LocationService.lat, lon: LocationService.lon,
        ayanamsaMode: 'lahiri', trueNode: true,
      );
      if (kr == null) return;

      final Map<String, int> basePlanetRashis = {};
      for (final entry in kr.planets.entries) {
        if (entry.key == 'ಮಾಂದಿ') continue;
        basePlanetRashis[entry.key] = entry.value.rashiIndex;
      }
      final guruRashiIdx = basePlanetRashis['ಗುರು'] ?? -1;

      final double srJd = srSs[0];
      final double ssJd = srSs[1];
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
      final ayn = Sweph.swe_get_ayanamsa(srJd);

      // Mandi
      final mandiSrSs = Ephemeris.findSunriseSetForDate(
        date.year, date.month, date.day,
        LocationService.lat, LocationService.lon,
      );
      final dayDuration = mandiSrSs[1] - mandiSrSs[0];
      final vedWday = ((date.weekday - 1) + 1) % 7;
      const dayFactors = [26, 22, 18, 14, 10, 6, 2];
      final dayMandiJd = mandiSrSs[0] + (dayDuration * dayFactors[vedWday] / 30.0);
      final dayMandiRashi = _mandiRashiFromJd(dayMandiJd);
      if (dayMandiRashi >= 0) basePlanetRashis['ಮಾಂದಿ'] = dayMandiRashi;

      final rules = muhurtaRules[_mfEvent];
      final allowedLagnas = rules?.allowedLagnas;

      final scanEndJd = _mfEvent == MuhurtaEvent.grihaPrevesha
          ? ssJd
          : (srJd + 7.0 / 24.0).clamp(srJd, ssJd);

      final lagnaWindows = _scanLagnaRange(srJd, scanEndJd, ayn, basePlanetRashis, guruRashiIdx, allowedLagnas, rules, mandiSidDeg: _mandiDegFromJd(dayMandiJd));

      // Compute rahu kala and visha ghati
      final rahuKala = _rahuKalaTime(date, kr.panchang.sunrise, kr.panchang.sunset);
      final vishaGhati = kr.panchang.vishaPraghati;

      if (mounted) {
        setState(() {
          r['lagnaWindows'] = lagnaWindows;
          r['rahuKala'] = rahuKala;
          r['vishaGhati'] = vishaGhati;
          r['needsLagna'] = false;
        });
      }
    } catch (e) {
      debugPrint('Lagna compute error for $date: $e');
      if (mounted) setState(() { r['needsLagna'] = false; });
    }
  }

  /// INSTANT search using pre-computed cache
  Future<void> _searchMuhurtasCached() async {
    // Keep screen on during long calculation
    WakelockPlus.enable();
    final cache = PanchangaCache.instance;
    if (!cache.isLoaded) {
      // Auto-generate cache for the search range so detailed rejection tracking works
      setState(() { _mfSearching = true; _mfResults = []; _mfStats = null; _mfDisplayCount = 20; _expandedResults.clear(); });
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        final startDate = DateTime(_mfMonth.year, _mfMonth.month);
        final endDate = DateTime(_mfMonthEnd.year, _mfMonthEnd.month + 1, 0);
        await cache.generate(
          startDate: startDate,
          endDate: endDate,
          lat: LocationService.lat,
          lon: LocationService.lon,
          tzOffset: LocationService.tzOffset,
          zoneName: LocationService.place,
        );
      } catch (e) {
        // If cache generation fails, fall back to non-cached
        return _searchMuhurtas();
      }
    }

    setState(() { _mfSearching = true; _mfResults = []; _mfStats = null; _mfDisplayCount = 20; _expandedResults.clear(); _mfUsedCache = true; });
    await Future.delayed(const Duration(milliseconds: 20));

    final userRules = UserRulesManager.instance.getRules(_mfEvent);
    final defaultRules = muhurtaRules[_mfEvent];
    if (defaultRules == null) {
      WakelockPlus.disable();
      setState(() { _mfSearching = false; });
      return;
    }

    // End of month range
    final endDate = DateTime(_mfMonthEnd.year, _mfMonthEnd.month + 1, 0);
    final startDate = DateTime(_mfMonth.year, _mfMonth.month, 1);

    // INSTANT filter — milliseconds!
    final filterResult = cache.filterByUserRules(
      userRules: userRules,
      startDate: startDate,
      endDate: endDate,
      janmaNakIdx: _mfNakIdx,
      janmaRashiIdx: _mfRashiIdx,
    );
    final filteredDays = filterResult.days;
    final rejectedDays = filterResult.rejectedDays;

    // Build a MuhurtaEventRules from user's customized rules for evaluateMuhurta
    final userOverrideRules = MuhurtaEventRules(
      allowedTithis: userRules.allowedTithis ?? defaultRules.allowedTithis,
      allowedNakshatras: userRules.allowedNakshatras ?? defaultRules.allowedNakshatras,
      allowedVaras: userRules.allowedVaras ?? defaultRules.allowedVaras,
      avoidVishti: userRules.avoidVishti,
      requireShukla: userRules.requireShukla,
      requireUttarayana: userRules.requireUttarayana,
      allowedLagnas: userRules.allowedLagnas ?? defaultRules.allowedLagnas,
      requiredShuddhis: userRules.requiredShuddhis,
      shloka: defaultRules.shloka,
      shastraRef: defaultRules.shastraRef,
      tithiShloka: defaultRules.tithiShloka,
      varaShloka: defaultRules.varaShloka,
      nakshatraShloka: defaultRules.nakshatraShloka,
      lagnaShloka: defaultRules.lagnaShloka,
      lagnaShuddhiShloka: defaultRules.lagnaShuddhiShloka,
    );

    // Build results from cached data
    final results = <Map<String, dynamic>>[];
    int totalDays = cache.getDaysInRange(startDate, endDate).length;

    for (final day in filteredDays) {
      final mResult = evaluateMuhurta(
        event: _mfEvent,
        tithiIndex: day.tithiIndex,
        tithiName: day.tithiName,
        nakshatraIndex: day.nakshatraIndex,
        nakshatraName: day.nakshatraName,
        varaIndex: day.varaIndex,
        varaName: day.varaName,
        yogaIndex: day.yogaIndex,
        yogaName: day.yogaName,
        karanaName: day.karanaName,
        moonRashiIndex: day.moonRashiIndex,
        jupiterRashiIndex: day.jupiterRashiIndex,
        sunRashiIndex: day.sunRashiIndex,
        janmaNakIdx1: _mfNakIdx,
        janmaRashiIdx1: _mfRashiIdx,
        overrideRules: userOverrideRules,
      );

      final guruBala = mResult.personResults.isNotEmpty ? mResult.personResults[0].guruBala : null;
      final taraBala = mResult.personResults.isNotEmpty ? mResult.personResults[0].taraBala : null;

      final shukraCombust = (_mfEvent == MuhurtaEvent.vivaha) ? day.venusCombust : false;

      // ── Compute lagna windows inline ──
      List<LagnaWindow> dayLagnaWindows = [];
      String rahuKala = '';
      String vishaGhati = '';
      try {
        await Ephemeris.initSweph();
        final srSs = Ephemeris.findSunriseSetForDate(
          day.date.year, day.date.month, day.date.day,
          LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
        );
        final srLocalFrac = ((srSs[0] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final hour24 = (srLocalFrac * 24.0) + (1.0 / 60.0);

        final kr = await AstroCalculator.calculate(
          year: day.date.year, month: day.date.month, day: day.date.day,
          hourUtcOffset: LocationService.tzOffset,
          hour24: hour24,
          lat: LocationService.lat, lon: LocationService.lon,
          ayanamsaMode: 'lahiri', trueNode: true,
        );

        if (kr != null) {
          final Map<String, int> basePlanetRashis = {};
          for (final entry in kr.planets.entries) {
            if (entry.key == 'ಮಾಂದಿ') continue;
            basePlanetRashis[entry.key] = entry.value.rashiIndex;
          }
          final guruRashiIdx2 = basePlanetRashis['ಗುರು'] ?? -1;

          final double srJd = srSs[0];
          final double ssJd = srSs[1];
          Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
          final ayn = Sweph.swe_get_ayanamsa(srJd);

          // Mandi
          final mandiSrSs = Ephemeris.findSunriseSetForDate(
            day.date.year, day.date.month, day.date.day,
            LocationService.lat, LocationService.lon,
          );
          final dayDuration = mandiSrSs[1] - mandiSrSs[0];
          final vedWday = ((day.date.weekday - 1) + 1) % 7;
          const dayFactors = [26, 22, 18, 14, 10, 6, 2];
          final dayMandiJd = mandiSrSs[0] + (dayDuration * dayFactors[vedWday] / 30.0);
          final dayMandiRashi = _mandiRashiFromJd(dayMandiJd);
          if (dayMandiRashi >= 0) basePlanetRashis['ಮಾಂದಿ'] = dayMandiRashi;

          final allowedLagnas = userRules.allowedLagnas ?? defaultRules.allowedLagnas;

          // fullDayScan: scan sunrise to 11 PM (srJd + 17h covers ~6AM to 11PM)
          final scanEndJd = userRules.fullDayScan
              ? (srJd + 17.0 / 24.0)
              : (_mfEvent == MuhurtaEvent.grihaPrevesha
                  ? ssJd
                  : (srJd + 7.0 / 24.0).clamp(srJd, ssJd));

          dayLagnaWindows = _scanLagnaRange(srJd, scanEndJd, ayn, basePlanetRashis, guruRashiIdx2, allowedLagnas, userOverrideRules, useBhavaShuddhi: userRules.useBhavaShuddhi, mandiSidDeg: _mandiDegFromJd(dayMandiJd));


          // Filter: only keep windows that pass shuddhi (rashi OR bhava fallback)
          dayLagnaWindows = dayLagnaWindows.where((w) {
            if (!w.isAllowed) return false;
            if (!w.isShubha) return false;
            if (userRules.requireGuruAnukoolaForLagna && !w.guruAnukoola) return false;
            return true;
          }).toList();

          // Abhijit muhurta is universally auspicious — compute only if toggle is ON
          // No panchanga or shuddhi checks needed
          if (userRules.considerAbhijit) {
            // Abhijit muhurta = 8th muhurta of 15 daytime muhurtas (midday)
            final srMins = _parseTimeToMins(day.sunrise).toDouble();
            final ssMins = _parseTimeToMins(day.sunset).toDouble();
            final muhDuration = (ssMins - srMins) / 15.0;
            final abhijitStart = srMins + 7 * muhDuration;
            final abhijitEnd = abhijitStart + muhDuration;
            // Compute lagna at Abhijit midpoint
            final abhijitMidJd = srJd + ((abhijitStart + muhDuration / 2 - srMins * 1.0) / (24.0 * 60.0));
            final abhijitHouses = Ephemeris.placidusHousesFull(abhijitMidJd, LocationService.lat, LocationService.lon);
            if (abhijitHouses != null && abhijitHouses.ascmc.length >= 1) {
              final abhijitSidDeg = ((abhijitHouses.ascmc[0] as double) - ayn) % 360.0;
              final abhijitRashi = (abhijitSidDeg / 30).floor() % 12;
            final knRashiNames = [for (final r in ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ']) trAll(r)];
            dayLagnaWindows.add(LagnaWindow(
              rashiIndex: abhijitRashi,
              rashiName: '${knRashiNames[abhijitRashi]} (ಅಭಿಜಿತ್)',
              startTime: _minsToTime(abhijitStart.round()),
              endTime: _minsToTime(abhijitEnd.round()),
              lagnaShuddhi: true,
              saptamaShuddhi: true,
              ashtamaShuddhi: true,
              dashamaShuddhi: true,
              guruAnukoola: true,
              guruFromLagna: 0,
            ));
            } // end abhijitHouses check
          }

          rahuKala = _rahuKalaTime(day.date, kr.panchang.sunrise, kr.panchang.sunset);
          vishaGhati = kr.panchang.vishaPraghati;
        }
      } catch (_) {}

      // Yield to UI EVERY day to prevent ANR on long searches
      await Future.delayed(Duration.zero);
      if (mounted) setState(() {});

      // If no lagna windows passed shuddhi → reject this date
      if (dayLagnaWindows.isEmpty) {
        rejectedDays.putIfAbsent('lagna', () => []);
        rejectedDays['lagna']!.add(day);
        continue;
      }

      results.add({
        'date': day.date,
        'vara': day.varaName,
        'tithi': day.tithiName,
        'tithiEnd': day.tithiEndTime,
        'nakshatra': day.nakshatraName,
        'nakEnd': day.nakEndTime,
        'pada': day.pada,
        'yoga': day.yogaName,
        'karana': day.karanaName,
        'sunrise': day.sunrise,
        'sunset': day.sunset,
        'chandraMasa': day.chandraMasa,
        'souraMasa': day.souraMasa,
        'samvatsara': day.samvatsara,
        'taraBala': taraBala,
        'guruBala': guruBala,
        'chandraBala': null,
        'jupRashi': day.jupiterRashiIndex,
        'rahuKala': rahuKala,
        'vishaGhati': vishaGhati,
        'doshas': mResult.doshas,
        'doshaBhangas': mResult.doshaBhangas,
        'checks': mResult.checks,
        'shubhaMuhurtas': <Map<String, String>>[],
        'lagnaWindows': dayLagnaWindows,
        'isPerfect': dayLagnaWindows.any((w) => w.isPerfect),
        'isCandidate': !dayLagnaWindows.any((w) => w.isPerfect) && dayLagnaWindows.isNotEmpty,
        'partialReasons': <String>[],
        'score': mResult.score,
        'verdict': mResult.verdict,
        'needsLagna': false,
      });
    }

    // Sort by score
    results.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final stats = {
      'totalDays': totalDays,
      'countTaraFailed': rejectedDays['tara']?.length ?? 0,
      'countGuruFailed': rejectedDays['guru']?.length ?? 0,
      'countGuruCombust': 0,
      'countShukraCombust': 0,
      'countPanchangaFailed': (rejectedDays['tithi']?.length ?? 0) + (rejectedDays['nakshatra']?.length ?? 0) + (rejectedDays['vara']?.length ?? 0) + (rejectedDays['yoga']?.length ?? 0) + (rejectedDays['karana']?.length ?? 0),
      'countNoLagnaShuddhi': rejectedDays['lagna']?.length ?? 0,
      'rejectedDays': rejectedDays,
    };

    WakelockPlus.disable();
    if (mounted) setState(() { _mfResults = results; _mfStats = stats; _mfSearching = false; });
  }

  Future<void> _searchMuhurtas() async {
    // Keep screen on during long calculation
    WakelockPlus.enable();
    setState(() { _mfSearching = true; _mfResults = []; _mfStats = null; _mfDisplayCount = 20; _mfUsedCache = false; });
    await Future.delayed(const Duration(milliseconds: 50));

    final results = <Map<String, dynamic>>[];
    int totalDays = 0;
    int countGuruCombust = 0;
    int countShukraCombust = 0;
    int countNoLagnaShuddhi = 0;
    // Store rejected dates per rule (same format as cached path for clickable chips)
    final rej = <String, List<Map<String, dynamic>>>{
      'tithi': [], 'nakshatra': [], 'vara': [], 'yoga': [],
      'karana': [], 'dagdha': [], 'shukla': [], 'uttarayana': [],
      'tara': [], 'guru': [], 'guruAsta': [], 'shukraAsta': [],
      'lagna': [],
    };

    await Ephemeris.initSweph();
    // Loop through each month in the range
    DateTime curMonth = DateTime(_mfMonth.year, _mfMonth.month);
    final endMonth = DateTime(_mfMonthEnd.year, _mfMonthEnd.month);
    while (!curMonth.isAfter(endMonth)) {
      final daysInMonth = DateTime(curMonth.year, curMonth.month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        // Yield to UI EVERY day to prevent ANR on long searches
        await Future.delayed(Duration.zero);
        try {
          totalDays++;
          final date = DateTime(curMonth.year, curMonth.month, d);
          final srSs = Ephemeris.findSunriseSetForDate(
            date.year, date.month, date.day,
            LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
          );
          final srJd = srSs[0];
          final srLocalFrac = ((srJd + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
          final hour24 = (srLocalFrac * 24.0) + (1.0 / 60.0);

          final kr = await AstroCalculator.calculate(
            year: date.year, month: date.month, day: date.day,
            hourUtcOffset: LocationService.tzOffset,
            hour24: hour24,
            lat: LocationService.lat, lon: LocationService.lon,
            ayanamsaMode: 'lahiri', trueNode: true,
          );
          if (kr == null) continue;
          final pan = kr.panchang;

          // Derive indices from string names
          final varaIdx = knVara.indexOf(pan.vara);
          final yogaIdx = knYoga.indexOf(pan.yoga);
          final moonRashiIdx = knRashi.indexOf(pan.chandraRashi);

          // Get Jupiter & Sun rashi
          final jupDeg = kr.planets['ಗುರು']?.longitude ?? 0;
          final jupRashi = (jupDeg / 30).floor() % 12;
          final sunDeg = kr.planets['ರವಿ']?.longitude ?? 0;
          final sunRashi = (sunDeg / 30).floor() % 12;

          // ── Apply user rules filtering ──
          final userRules = UserRulesManager.instance.getRules(_mfEvent);
          final defaultRulesNonCached = muhurtaRules[_mfEvent]!;
          final userOverrideRules2 = MuhurtaEventRules(
            allowedTithis: userRules.allowedTithis ?? defaultRulesNonCached.allowedTithis,
            allowedNakshatras: userRules.allowedNakshatras ?? defaultRulesNonCached.allowedNakshatras,
            allowedVaras: userRules.allowedVaras ?? defaultRulesNonCached.allowedVaras,
            avoidVishti: userRules.avoidVishti,
            requireShukla: userRules.requireShukla,
            requireUttarayana: userRules.requireUttarayana,
            allowedLagnas: userRules.allowedLagnas ?? defaultRulesNonCached.allowedLagnas,
            requiredShuddhis: userRules.requiredShuddhis,
            shloka: defaultRulesNonCached.shloka,
            shastraRef: defaultRulesNonCached.shastraRef,
            tithiShloka: defaultRulesNonCached.tithiShloka,
            varaShloka: defaultRulesNonCached.varaShloka,
            nakshatraShloka: defaultRulesNonCached.nakshatraShloka,
            lagnaShloka: defaultRulesNonCached.lagnaShloka,
            lagnaShuddhiShloka: defaultRulesNonCached.lagnaShuddhiShloka,
          );

          // Check ALL rules — collect all failures (date can appear in multiple rejection lists)
          final dayInfo = {
            'date': date, 'vara': pan.vara, 'tithi': pan.tithi,
            'nakshatra': pan.nakshatra, 'yoga': pan.yoga, 'karana': pan.karana,
          };
          final failures = <String>[];

          if (userRules.allowedTithis != null && !userRules.allowedTithis!.contains(pan.tithiIndex)) {
            rej['tithi']!.add(dayInfo); failures.add('tithi');
          }
          if (userRules.allowedNakshatras != null && !userRules.allowedNakshatras!.contains(pan.nakshatraIndex)) {
            rej['nakshatra']!.add(dayInfo); failures.add('nakshatra');
          }
          if (userRules.allowedVaras != null && !userRules.allowedVaras!.contains(varaIdx)) {
            rej['vara']!.add(dayInfo); failures.add('vara');
          }
          final blocked = userRules.blockedYogas ?? <int>[];
          if (blocked.contains(yogaIdx)) {
            rej['yoga']!.add(dayInfo); failures.add('yoga');
          }
          if (userRules.avoidVishti && (pan.karana.contains('ವಿಷ್ಟಿ') || pan.karana.contains('ಭದ್ರಾ'))) {
            rej['karana']!.add(dayInfo); failures.add('karana');
          }
          if (userRules.requireShukla && pan.tithiIndex >= 15) {
            rej['shukla']!.add(dayInfo); failures.add('shukla');
          }
          if (userRules.requireUttarayana) {
            final isUttarayana = (sunRashi >= 9 || sunRashi <= 2);
            if (!isUttarayana) { rej['uttarayana']!.add(dayInfo); failures.add('uttarayana'); }
          }
          if (userRules.blockDagdhaYoga) {
            final dagdhaList = dagdhaYogaTable[varaIdx];
            if (dagdhaList != null && dagdhaList.contains(pan.nakshatraIndex)) { rej['dagdha']!.add(dayInfo); failures.add('dagdha'); }
          }
          final guruCombustEarly = kr.planets['ಗುರು']?.isCombust ?? false;
          if (guruCombustEarly) { countGuruCombust++; }
          if (userRules.requireTaraBala) {
            final tb = calculateTaraBala(_mfNakIdx, pan.nakshatraIndex);
            if (!userRules.allowedTaras.contains(tb.taraIndex)) { rej['tara']!.add(dayInfo); failures.add('tara'); }
          }
          if (userRules.requireGuruBala) {
            final gb = calculateGuruBala(_mfRashiIdx, jupRashi);
            if (gb.score == 0) { rej['guru']!.add(dayInfo); failures.add('guru'); }
          }
          // Guru Asta (Jupiter combust) check
          if (userRules.blockGuruAsta) {
            final guruCombust = kr.planets['ಗುರು']?.isCombust ?? false;
            if (guruCombust) { rej['guruAsta']!.add(dayInfo); failures.add('guruAsta'); }
          }
          // Shukra Asta (Venus combust) check
          if (userRules.blockShukraAsta) {
            final shukraCombust = kr.planets['ಶುಕ್ರ']?.isCombust ?? false;
            if (shukraCombust) { rej['shukraAsta']!.add(dayInfo); failures.add('shukraAsta'); }
          }
          if (failures.isNotEmpty) continue; // Skip day only after checking ALL rules

          // Evaluate muhurta using existing engine
          final mResult = evaluateMuhurta(
            event: _mfEvent,
            tithiIndex: pan.tithiIndex,
            tithiName: pan.tithi,
            nakshatraIndex: pan.nakshatraIndex,
            nakshatraName: pan.nakshatra,
            varaIndex: varaIdx,
            varaName: pan.vara,
            yogaIndex: yogaIdx,
            yogaName: pan.yoga,
            karanaName: pan.karana,
            moonRashiIndex: moonRashiIdx,
            jupiterRashiIndex: jupRashi,
            sunRashiIndex: sunRashi,
            janmaNakIdx1: _mfNakIdx,
            janmaRashiIdx1: _mfRashiIdx,
            overrideRules: userOverrideRules2,
          );

          // Evaluate individual checks
          final allChecksPassed = mResult.checks.every((c) => c.passed);
          final taraBala = mResult.personResults.isNotEmpty ? mResult.personResults[0].taraBala : null;
          final isTaraOk = (taraBala == null || taraBala.isGood);

          final guruBala = mResult.personResults.isNotEmpty ? mResult.personResults[0].guruBala : null;
          final isGuruOk = (guruBala == null || guruBala.score > 0);

          final guruCombust = kr.planets['ಗುರು']?.isCombust ?? false;
          final shukraCombust = (_mfEvent == MuhurtaEvent.vivaha) ? (kr.planets['ಶುಕ್ರ']?.isCombust ?? false) : false;
          final isAstaOk = !guruCombust && !shukraCombust;

          if (guruCombust) countGuruCombust++;
          if (shukraCombust) countShukraCombust++;

          // Compute avoidance times
          final rahuKala = _rahuKalaTime(date, pan.sunrise, pan.sunset);
          final vishaGhati = pan.vishaPraghati;

          // Compute shubha muhurta timings (15 day muhurtas)
          final srMins = _parseTimeToMins(pan.sunrise).toDouble();
          final ssMins = _parseTimeToMins(pan.sunset).toDouble();
          final muhDuration = (ssMins - srMins) / 15.0;
          final shubhaMuhurtas = <Map<String, String>>[];
          const muhNames = [
            {'kn': 'ರುದ್ರ', 'en': 'Rudra', 'n': 'A'},
            {'kn': 'ಅಹಿ', 'en': 'Ahi', 'n': 'A'},
            {'kn': 'ಮಿತ್ರ', 'en': 'Mitra', 'n': 'S'},
            {'kn': 'ಪಿತೃ', 'en': 'Pitru', 'n': 'A'},
            {'kn': 'ವಸು', 'en': 'Vasu', 'n': 'S'},
            {'kn': 'ವರಾಹ', 'en': 'Varaha', 'n': 'S'},
            {'kn': 'ವಿಶ್ವೇದೇವ', 'en': 'Vishwedeva', 'n': 'S'},
            {'kn': 'ವಿಧಿ', 'en': 'Vidhi', 'n': 'M'},
            {'kn': 'ಸತ್ಮುಖಿ', 'en': 'Satmukhi', 'n': 'S'},
            {'kn': 'ಪುರುಹೂತ', 'en': 'Puruhuta', 'n': 'A'},
            {'kn': 'ವಾಹಿನಿ', 'en': 'Vahini', 'n': 'A'},
            {'kn': 'ನಕ್ತನಕರ', 'en': 'Naktanakara', 'n': 'M'},
            {'kn': 'ವರುಣ', 'en': 'Varuna', 'n': 'S'},
            {'kn': 'ಅರ್ಯಮ', 'en': 'Aryama', 'n': 'S'},
            {'kn': 'ಭಗ', 'en': 'Bhaga', 'n': 'A'},
          ];
          for (int mi = 0; mi < 15; mi++) {
            if (muhNames[mi]['n'] == 'S') {
              final s = srMins + mi * muhDuration;
              final e = s + muhDuration;
              shubhaMuhurtas.add({
                'name': trAll(muhNames[mi]['kn']!),
                'en': muhNames[mi]['en']!,
                'time': '${_minsToTime(s.round())} - ${_minsToTime(e.round())}',
              });
            }
          }

          // Always compute lagna windows for every day (no basicViable guard)
          final allowedLagnas = userRules.allowedLagnas ?? defaultRulesNonCached.allowedLagnas;
          List<LagnaWindow> dayLagnaWindows = [];
          bool hasPerfectLagna = false;
          bool hasShubhaLagna = false;

          {
            final Map<String, int> basePlanetRashis = {};
            for (final entry in kr.planets.entries) {
              if (entry.key == 'ಮಾಂದಿ') continue;
              basePlanetRashis[entry.key] = entry.value.rashiIndex;
            }
            final guruRashiIdx2 = basePlanetRashis['ಗುರು'] ?? -1;

            try {
              final srSs2 = Ephemeris.findSunriseSetForDate(
                date.year, date.month, date.day,
                LocationService.lat, LocationService.lon, tzOffset: LocationService.tzOffset,
              );
              final double srJd2 = srSs2[0];
              final double ssJd2 = srSs2[1];
              Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
              final ayn = Sweph.swe_get_ayanamsa(srJd2);

              final mandiSrSs = Ephemeris.findSunriseSetForDate(
                date.year, date.month, date.day,
                LocationService.lat, LocationService.lon,
              );
              final double mandiSr = mandiSrSs[0];
              final double mandiSs = mandiSrSs[1];

              final vedWday = ((date.weekday - 1) + 1) % 7;
              final dayDuration = mandiSs - mandiSr;
              const dayFactors = [26, 22, 18, 14, 10, 6, 2];
              final dayMandiJd = mandiSr + (dayDuration * dayFactors[vedWday] / 30.0);
              final dayMandiRashi = _mandiRashiFromJd(dayMandiJd);
              if (dayMandiRashi >= 0) basePlanetRashis['ಮಾಂದಿ'] = dayMandiRashi;

              // fullDayScan: scan sunrise to 11 PM
              final scanEndJd = userRules.fullDayScan
                  ? (srJd2 + 17.0 / 24.0)
                  : (_mfEvent == MuhurtaEvent.grihaPrevesha
                      ? ssJd2
                      : (srJd2 + 7.0 / 24.0).clamp(srJd2, ssJd2));

              dayLagnaWindows = _scanLagnaRange(srJd2, scanEndJd, ayn, basePlanetRashis, guruRashiIdx2, allowedLagnas, userOverrideRules2, useBhavaShuddhi: userRules.useBhavaShuddhi, mandiSidDeg: _mandiDegFromJd(dayMandiJd));


              // Filter: only keep windows that pass shuddhi (rashi OR bhava fallback)
              dayLagnaWindows = dayLagnaWindows.where((w) {
                if (!w.isAllowed) return false;
                if (!w.isShubha) return false;
                if (userRules.requireGuruAnukoolaForLagna && !w.guruAnukoola) return false;
                return true;
              }).toList();

              // Abhijit muhurta — universally auspicious (if user has it enabled)
              if (userRules.considerAbhijit) {
                final srMinsLagna = ((srSs2[0] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 * 24.0 * 60.0);
                final ssMinsLagna = ((srSs2[1] + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 * 24.0 * 60.0);
                final muhDurLagna = (ssMinsLagna - srMinsLagna) / 15.0;
                final abhijitStart = srMinsLagna + 7 * muhDurLagna;
                final abhijitEnd = abhijitStart + muhDurLagna;
                final abhijitMidJd = srJd2 + ((abhijitStart + muhDurLagna / 2 - srMinsLagna) / (24.0 * 60.0));
                final abhijitHouses = Ephemeris.placidusHousesFull(abhijitMidJd, LocationService.lat, LocationService.lon);
                if (abhijitHouses != null && abhijitHouses.ascmc.length >= 1) {
                  final abhijitSidDeg = ((abhijitHouses.ascmc[0] as double) - ayn) % 360.0;
                  final abhijitRashi = (abhijitSidDeg / 30).floor() % 12;
                  final knRashiNames = [for (final r in ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ']) trAll(r)];
                  dayLagnaWindows.add(LagnaWindow(
                    rashiIndex: abhijitRashi,
                    rashiName: '${knRashiNames[abhijitRashi]} (ಅಭಿಜಿತ್)',
                    startTime: _minsToTime(abhijitStart.round()),
                    endTime: _minsToTime(abhijitEnd.round()),
                    isAllowed: true,
                    lagnaShuddhi: true,
                    saptamaShuddhi: true,
                    ashtamaShuddhi: true,
                    dashamaShuddhi: true,
                    chandraSaptamaShuddhi: true,
                    guruAnukoola: true,
                  ));
                }
              }
            } catch (_) {}

            hasPerfectLagna = dayLagnaWindows.any((w) => w.isPerfect);
            hasShubhaLagna = dayLagnaWindows.any((w) => w.isShubha || w.isAllowed);
          }

          if (!hasPerfectLagna) countNoLagnaShuddhi++;

          // If no lagna windows passed shuddhi → reject this date
          if (dayLagnaWindows.isEmpty) {
            rej['lagna']!.add({'date': date, 'vara': pan.vara, 'nakshatra': pan.nakshatra, 'tithi': pan.tithi});
            continue;
          }

          final is100PercentPerfect = allChecksPassed && isTaraOk && isGuruOk && isAstaOk && hasPerfectLagna;

          final partialReasons = <String>[];
          if (!isTaraOk) partialReasons.add(AppLocale.l('mTaraAnukoola'));
          if (!isGuruOk) partialReasons.add(AppLocale.l('mGuruBalaLack'));
          if (guruCombust) partialReasons.add(AppLocale.l('mGuruAstaDosha'));
          if (shukraCombust) partialReasons.add(AppLocale.l('mShukraAstaDosha'));
          if (!allChecksPassed) {
            final failedList = mResult.checks.where((c) => !c.passed).map((c) => c.label).join(', ');
            partialReasons.add('${AppLocale.l('mPanchDosha')} ($failedList)');
          }
          if (!hasPerfectLagna) {
            if (hasShubhaLagna) {
              partialReasons.add(AppLocale.l('mPartialLagna'));
            } else {
              partialReasons.add(AppLocale.l('mNoLagna'));
            }
          }

          final dayData = {
            'date': date,
            'vara': pan.vara,
            'tithi': pan.tithi,
            'tithiEnd': pan.tithiEndTime,
            'nakshatra': pan.nakshatra,
            'nakEnd': pan.nakEndTime,
            'pada': () { final mp = kr.planets['ಚಂದ್ರ']?.pada; return mp ?? ((pan.nakPercent * 4).floor() + 1); }(),
            'yoga': pan.yoga,
            'karana': pan.karana,
            'sunrise': pan.sunrise,
            'sunset': pan.sunset,
            'chandraMasa': pan.chandraMasa,
            'souraMasa': pan.souraMasa,
            'samvatsara': pan.samvatsara,
            'taraBala': mResult.personResults.isNotEmpty ? mResult.personResults[0].taraBala : null,
            'guruBala': mResult.personResults.isNotEmpty ? mResult.personResults[0].guruBala : null,
            'chandraBala': mResult.personResults.isNotEmpty ? mResult.personResults[0].chandraBala : null,
            'jupRashi': jupRashi,
            'rahuKala': rahuKala,
            'vishaGhati': vishaGhati,
            'doshas': mResult.doshas,
            'doshaBhangas': mResult.doshaBhangas,
            'checks': mResult.checks,
            'shubhaMuhurtas': shubhaMuhurtas,
            'lagnaWindows': dayLagnaWindows,
          };

          // Add ALL days to results (matching cached path behavior)
          results.add({
            ...dayData,
            'isPerfect': is100PercentPerfect,
            'isCandidate': !is100PercentPerfect && (hasShubhaLagna || dayLagnaWindows.isNotEmpty),
            'partialReasons': partialReasons,
            'score': is100PercentPerfect ? mResult.score : (mResult.score * 0.75).round(),
            'verdict': is100PercentPerfect ? mResult.verdict : AppLocale.l('mConditional'),
            'needsLagna': false,
          });
        } catch (_) {}
      }
      curMonth = DateTime(curMonth.year, curMonth.month + 1);
    }

    // Sort: 100% perfect first, then by score descending
    results.sort((a, b) {
      final aPerf = a['isPerfect'] == true ? 1 : 0;
      final bPerf = b['isPerfect'] == true ? 1 : 0;
      if (aPerf != bPerf) return bPerf.compareTo(aPerf);
      return (b['score'] as int).compareTo(a['score'] as int);
    });

    final stats = <String, dynamic>{
      'totalDays': totalDays,
      'countTaraFailed': rej['tara']!.length,
      'countGuruFailed': rej['guru']!.length,
      'countGuruCombust': countGuruCombust,
      'countShukraCombust': countShukraCombust,
      'countPanchangaFailed': rej['tithi']!.length + rej['nakshatra']!.length + rej['vara']!.length + rej['yoga']!.length + rej['karana']!.length,
      'countNoLagnaShuddhi': rej['lagna']!.length,
      'rejTithi': rej['tithi']!.length,
      'rejNak': rej['nakshatra']!.length,
      'rejVara': rej['vara']!.length,
      'rejYoga': rej['yoga']!.length,
      'rejKarana': rej['karana']!.length,
      'rejShukla': rej['shukla']!.length,
      'rejUttarayana': rej['uttarayana']!.length,
      'rejDagdha': rej['dagdha']!.length,
      'rejectedDays': rej,
      'rejGuruAsta': rej['guruAsta']!.length,
      'rejShukraAsta': rej['shukraAsta']!.length,
    };

    WakelockPlus.disable();
    if (mounted) setState(() { _mfResults = results; _mfStats = stats; _mfSearching = false; });
  }

  Widget _buildMuhurtaFinderTab() {
    final rashiNames = List.generate(12, (i) => trAll(knRashi[i]));
    final nakNames = List.generate(27, (i) => trAll(knNak[i]));
    final months = List.generate(12, (i) {
      final m = DateTime(DateTime.now().year, DateTime.now().month + i);
      return m;
    });

    final searchForm = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Inputs ──
        AppCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocale.l('muhurtaShodhane'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple1)),
            const SizedBox(height: 12),

            // Rashi
            Text(AppLocale.l('selectRashi'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
              child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                isExpanded: true, value: _mfRashiIdx, dropdownColor: kCard,
                style: TextStyle(color: kText, fontSize: 14),
                items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text(rashiNames[i]))),
                onChanged: (v) {
                  final naks = _naksForRashi(v!);
                  setState(() {
                    _mfRashiIdx = v;
                    if (!naks.contains(_mfNakIdx)) _mfNakIdx = naks.first;
                  });
                },
              )),
            ),
            const SizedBox(height: 10),

            // Nakshatra
            Text(AppLocale.l('nakshatra'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
              child: DropdownButtonHideUnderline(child: DropdownButton<int>(
                isExpanded: true, value: _mfNakIdx, dropdownColor: kCard,
                style: TextStyle(color: kText, fontSize: 14),
                items: _naksForRashi(_mfRashiIdx).map((i) => DropdownMenuItem(value: i, child: Text(nakNames[i]))).toList(),
                onChanged: (v) => setState(() => _mfNakIdx = v!),
              )),
            ),
            const SizedBox(height: 10),

            // Event
            Text(AppLocale.l('selectEvent'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
              child: DropdownButtonHideUnderline(child: DropdownButton<MuhurtaEvent>(
                isExpanded: true, value: _mfEvent, dropdownColor: kCard,
                style: TextStyle(color: kText, fontSize: 14),
                items: MuhurtaEvent.values.map((e) {
                  final info = muhurtaEventNames[e]!;
                  return DropdownMenuItem(value: e, child: Text('${AppLocale.l(info.localeKey)} (${info.englishName})'));
                }).toList(),
                onChanged: (v) => setState(() => _mfEvent = v!),
              )),
            ),
            const SizedBox(height: 10),
          ],
        )),

        // ── Rules Editor (collapsible) ──
        const SizedBox(height: 8),
        MuhurtaRulesEditor(
          event: _mfEvent,
          onRulesChanged: () {
            setState(() {});
          },
        ),
        const SizedBox(height: 8),

        AppCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Month Range
            Text('${AppLocale.l('selectMonth')} (From - To)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: DropdownButtonHideUnderline(child: DropdownButton<DateTime>(
                  isExpanded: true, value: _mfMonth, dropdownColor: kCard,
                  style: TextStyle(color: kText, fontSize: 13),
                  items: months.map((m) {
                    final mNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    return DropdownMenuItem(value: m, child: Text('${mNames[m.month]} ${m.year}'));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() {
                      _mfMonth = v;
                      if (_mfMonthEnd.isBefore(v)) _mfMonthEnd = v;
                    });
                  },
                )),
              )),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('→', style: TextStyle(fontSize: 18, color: kMuted))),
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                child: DropdownButtonHideUnderline(child: DropdownButton<DateTime>(
                  isExpanded: true, value: _mfMonthEnd, dropdownColor: kCard,
                  style: TextStyle(color: kText, fontSize: 13),
                  items: months.where((m) => !m.isBefore(_mfMonth)).map((m) {
                    final mNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    return DropdownMenuItem(value: m, child: Text('${mNames[m.month]} ${m.year}'));
                  }).toList(),
                  onChanged: (v) => setState(() => _mfMonthEnd = v!),
                )),
              )),
            ]),
            const SizedBox(height: 14),

            // ── Panchanga Data Status ──
            Builder(builder: (_) {
              final cache = PanchangaCache.instance;
              if (cache.isLoaded) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x104CAF50),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x404CAF50)),
                  ),
                  child: Row(children: [
                    Icon(Icons.check_circle, color: kTeal, size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      '⚡ ${cache.statusSummary}',
                      style: TextStyle(fontSize: 11, color: kTeal, fontWeight: FontWeight.w600),
                    )),
                  ]),
                );
              }
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kOrange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kOrange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, color: kOrange, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    AppLocale.l('mCacheNotLoaded'),
                    style: TextStyle(fontSize: 11, color: kOrange, fontWeight: FontWeight.w600),
                  )),
                ]),
              );
            }),
            const SizedBox(height: 10),

            // Search button
            ElevatedButton.icon(
              onPressed: _mfSearching ? null : _searchMuhurtasCached,
              icon: _mfSearching ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.search),
              label: Text(
                _mfSearching ? '...' : (PanchangaCache.instance.isLoaded ? '⚡ ${AppLocale.l('searchMuhurta')}' : AppLocale.l('searchMuhurta')),
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple1, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        )),
      ],
    );

    final searchResults = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mfSearching)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: kPurple1)),
          ),
        if (!_mfSearching && _mfStats != null) ...[
          _buildSearchDiagnosticsCard(),
          if (_mfResults.isNotEmpty) ...[
            Row(
              children: [
                Text('${_mfResults.length} ${AppLocale.l('mDaysFound')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kTeal)),
                const SizedBox(width: 8),
                Text('(${_mfResults.where((r) => r['isPerfect'] == true).length} ${AppLocale.l('mPerfect')}, ${_mfResults.where((r) => r['isCandidate'] == true).length} ${AppLocale.l('mConditional')})',
                  style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            // Lazy-load results: show only _mfDisplayCount at a time
            ...List.generate(
              _mfResults.length < _mfDisplayCount ? _mfResults.length : _mfDisplayCount,
              (i) => _buildMuhurtaResultCard(_mfResults[i]),
            ),
            if (_mfDisplayCount < _mfResults.length)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() { _mfDisplayCount += 20; }),
                  icon: Icon(Icons.expand_more, color: kPurple2),
                  label: Text('${AppLocale.l('mShowMore')} (${_mfResults.length - _mfDisplayCount} ${AppLocale.l('mRemaining')})',
                    style: TextStyle(color: kPurple2, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ],
      ],
    );

    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ResponsiveCenter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchForm,
                  const SizedBox(height: 12),
                  searchResults,
                ],
              ),
            ),
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: searchForm,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: searchResults,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildSearchDiagnosticsCard() {
    if (_mfStats == null) return const SizedBox();
    final stats = _mfStats!;
    final totalDays = (stats['totalDays'] as int?) ?? 0;
    final perfectCount = _mfResults.where((r) => r['isPerfect'] == true).length;
    final candidateCount = _mfResults.where((r) => r['isCandidate'] == true).length;

    final countTara = (stats['countTaraFailed'] as int?) ?? 0;
    final countGuru = (stats['countGuruFailed'] as int?) ?? 0;
    final countCombust = ((stats['countGuruCombust'] as int?) ?? 0) + ((stats['countShukraCombust'] as int?) ?? 0);
    final countPanchanga = (stats['countPanchangaFailed'] as int?) ?? 0;
    final countLagna = (stats['countNoLagnaShuddhi'] as int?) ?? 0;

    final isNoPerfect = perfectCount == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNoPerfect ? Colors.orange.withOpacity(0.06) : kPurple1.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNoPerfect ? Colors.orange.withOpacity(0.4) : kPurple1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isNoPerfect ? Icons.warning_amber_rounded : Icons.analytics_outlined,
              color: isNoPerfect ? Colors.orange.shade800 : kPurple1, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isNoPerfect ? AppLocale.l('mNoPerfectMuhurta') : AppLocale.l('mSearchSummary'),
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isNoPerfect ? Colors.orange.shade900 : kText),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            '${AppLocale.l('mTotalChecked')}: $totalDays | ${AppLocale.l('mPerfectMuhurta')}: $perfectCount | ${AppLocale.l('mConditionalDays')}: $candidateCount',
            style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 16),
          Text(AppLocale.l('mRejectionReasons'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              if (((stats['rejTithi'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mTithiLack'), (stats['rejTithi'] as int?) ?? 0, Colors.teal),
              if (((stats['rejNak'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mNakshatraLack'), (stats['rejNak'] as int?) ?? 0, Colors.indigo),
              if (((stats['rejVara'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mVaraLack'), (stats['rejVara'] as int?) ?? 0, Colors.brown),
              if (((stats['rejYoga'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mYogaLack'), (stats['rejYoga'] as int?) ?? 0, Colors.pink),
              if (((stats['rejKarana'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mKaranaLack'), (stats['rejKarana'] as int?) ?? 0, Colors.cyan.shade800),
              if (((stats['rejShukla'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mShuklapaksha'), (stats['rejShukla'] as int?) ?? 0, Colors.grey),
              if (((stats['rejUttarayana'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mUttarayana'), (stats['rejUttarayana'] as int?) ?? 0, Colors.blue),
              if (((stats['rejDagdha'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mDagdhaYoga'), (stats['rejDagdha'] as int?) ?? 0, Colors.red.shade800),
              if (((stats['rejGuruAsta'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mGuruAsta'), (stats['rejGuruAsta'] as int?) ?? 0, Colors.deepPurple),
              if (((stats['rejShukraAsta'] as int?) ?? 0) > 0) _diagChip(AppLocale.l('mShukraAsta'), (stats['rejShukraAsta'] as int?) ?? 0, Colors.purple),
              if (countPanchanga > 0 && stats['rejTithi'] == null) _diagChip(AppLocale.l('mPanchDosha'), countPanchanga, Colors.red),
              if (countTara > 0) _diagChip(AppLocale.l('mTaraLack'), countTara, Colors.deepOrange),
              if (countGuru > 0) _diagChip(AppLocale.l('mGuruBalaLack'), countGuru, Colors.amber.shade900),
              if (countCombust > 0) _diagChip(AppLocale.l('mGuruShukraAstaDosha'), countCombust, Colors.purple),
              if (countLagna > 0) _diagChip(AppLocale.l('mLagnaShuddhi'), countLagna, Colors.blueGrey),
            ],
          ),
          // Detailed per-rule rejection breakdown — clickable chips
          if (stats['rejectedDays'] != null) ...[
            const SizedBox(height: 10),
            Text(AppLocale.l('mRejectedByRule'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Builder(builder: (_) {
              final rejDays = stats['rejectedDays'] as Map<String, List>;
              return Wrap(
                spacing: 6, runSpacing: 4,
                children: [
                  for (final entry in {
                    'tithi': (AppLocale.l('mTithi'), Colors.teal),
                    'nakshatra': (AppLocale.l('mNakshatra'), Colors.indigo),
                    'vara': (AppLocale.l('mVara'), Colors.brown),
                    'yoga': (AppLocale.l('mYogaLack'), Colors.pink),
                    'karana': (AppLocale.l('mKaranaLack'), Colors.cyan.shade800),
                    'dagdha': (AppLocale.l('mDagdhaYoga'), Colors.red.shade800),
                    'shukla': (AppLocale.l('mShuklapaksha'), Colors.grey),
                    'uttarayana': (AppLocale.l('mUttarayana'), Colors.blue),
                    'tara': (AppLocale.l('mTaraBala'), Colors.deepOrange),
                    'guru': (AppLocale.l('mGuruBala'), Colors.amber.shade900),
                    'guruAsta': (AppLocale.l('mGuruAsta'), Colors.deepPurple),
                    'shukraAsta': (AppLocale.l('mShukraAsta'), Colors.purple),
                    'lagna': (AppLocale.l('mLagnaShuddhi'), Colors.blueGrey),
                  }.entries)
                    if ((rejDays[entry.key]?.isNotEmpty ?? false))
                      _clickableDiagChip(
                        entry.value.$1,
                        rejDays[entry.key]!.length,
                        entry.value.$2,
                        rejDays[entry.key]!,
                        entry.value.$1,
                      ),
                ],
              );
            }),
          ],
          if (isNoPerfect && candidateCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade900, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocale.l('mConditionalAdvice'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _diagChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text('$label: $count ${AppLocale.l('mDayUnit')}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _clickableDiagChip(String label, int count, Color color, List rejectedDays, String ruleName) {
    return GestureDetector(
      onTap: () => _showRejectedDatesSheet(rejectedDays, ruleName, color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: $count ${AppLocale.l('mDayUnit')}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 11, color: color),
          ],
        ),
      ),
    );
  }

  void _showRejectedDatesSheet(List rejectedDays, String ruleName, Color color) {
    final varaNames = [for (final v in ['ರವಿ', 'ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) trAll(v)];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1218),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.block, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '\"$ruleName\" ${AppLocale.l('mRejectedByRuleTitle')}: ${rejectedDays.length} ${AppLocale.l('mDaysLabel')}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
                      ),
                    ),
                  ]),
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: rejectedDays.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final day = rejectedDays[i];
                      // Handle both CachedPanchangaDay (cached path) and Map (non-cached path)
                      final DateTime d;
                      final String vara, tithi, nakshatra, yoga;
                      if (day is Map) {
                        d = day['date'] as DateTime;
                        vara = (day['vara'] as String?) ?? '';
                        tithi = (day['tithi'] as String?) ?? '';
                        nakshatra = (day['nakshatra'] as String?) ?? '';
                        yoga = (day['yoga'] as String?) ?? '';
                      } else {
                        d = day.date as DateTime;
                        final vi = day.varaIndex as int;
                        vara = vi < varaNames.length ? varaNames[vi] : '';
                        tithi = day.tithiName as String;
                        nakshatra = day.nakshatraName as String;
                        yoga = day.yogaName as String;
                      }
                      final dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(dateStr, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text(vara, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              '${AppLocale.l('tithiLabel')}: $tithi  |  ${AppLocale.l('nakshatraShort')}: $nakshatra  |  ${AppLocale.l('yogaLabel')}: $yoga',
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMuhurtaResultCard(Map<String, dynamic> r) {
    final isCandidate = r['isCandidate'] == true;
    final isPerfect = r['isPerfect'] == true;
    final partialReasons = (r['partialReasons'] as List<String>?) ?? [];

    final date = r['date'] as DateTime;
    final score = r['score'] as int;
    final Color scoreColor = isCandidate ? Colors.amber.shade800 : (score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red);
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    final dateKey = '${date.year}-${date.month}-${date.day}';
    final isExpanded = _expandedResults.contains(dateKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── ALWAYS VISIBLE: Tappable Header ──
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) { _expandedResults.remove(dateKey); }
                else { _expandedResults.add(dateKey); }
              });
              if (!isExpanded && r['needsLagna'] == true) {
                _computeLagnaForResult(r);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.08),
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(11))
                    : BorderRadius.circular(11),
              ),
              child: Row(children: [
                Icon(isPerfect ? Icons.stars : (isCandidate ? Icons.warning_amber_rounded : Icons.calendar_today), size: 16, color: scoreColor),
                const SizedBox(width: 8),
                Expanded(child: Text('$dateStr  ${trAll(r['vara'])}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: scoreColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('$score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: scoreColor)),
                ),
                const SizedBox(width: 6),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20, color: kMuted),
              ]),
            ),
          ),

          // ── EXPANDABLE: Full Details ──
          if (isExpanded) ...[
          if (isCandidate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: Colors.amber.withOpacity(0.12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Text(AppLocale.l('mConditionalMuhurta'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.amber.shade900)),
                  ]),
                  if (partialReasons.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('${AppLocale.l('mReasonsLabel')}: ${partialReasons.join(" • ")}', style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),

          // ── Panchanga Shuddhi Table ──
          if (r['checks'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPurple1.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Text(AppLocale.l('panchaShuddhi'), style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
                  ),
                  ...(r['checks'] as List<MuhurtaCheckItem>).map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5)))),
                    child: Row(children: [
                      Icon(c.passed ? Icons.check_circle : Icons.cancel,
                          color: c.passed ? Colors.green : Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(c.label, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 12)),
                      const Spacer(),
                      Flexible(child: Text(c.value, style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
                    ]),
                  )),
                ]),
              ),
            ),

          // ── Masa & Samvatsara Info ──
          if ((r['samvatsara'] as String? ?? '').isNotEmpty ||
              (r['chandraMasa'] as String? ?? '').isNotEmpty ||
              (r['souraMasa'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(10),
                  color: kCard,
                ),
                child: Column(children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Text(AppLocale.l('masaVivar'), style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange, fontSize: 13)),
                  ),
                  if ((r['samvatsara'] as String? ?? '').isNotEmpty)
                    _infoRow(AppLocale.l('samvatsara'), trAll(r['samvatsara'] as String)),
                  if ((r['chandraMasa'] as String? ?? '').isNotEmpty)
                    _infoRow(AppLocale.l('chandraMasa'), trAll(r['chandraMasa'] as String)),
                  if ((r['souraMasa'] as String? ?? '').isNotEmpty)
                    _infoRow(AppLocale.l('souraMasa'), trAll(r['souraMasa'] as String)),
                ]),
              ),
            ),

          // ── Nimma Balagalu ──
          if (r['taraBala'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: kBorder),
                  borderRadius: BorderRadius.circular(10),
                  color: kCard,
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('👤 ${AppLocale.l('yourBalas')}', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple1, fontSize: 13)),
                  const SizedBox(height: 6),
                  _balaChipRow(AppLocale.l('taraBala'),
                    '${AppLocale.l('tara${(r['taraBala'] as TaraResult).taraIndex}')} (${(r['taraBala'] as TaraResult).isGood ? AppLocale.l('shubha') : AppLocale.l('ashubha')})',
                    (r['taraBala'] as TaraResult).isGood),
                  if (r['chandraBala'] != null)
                    _balaChipRow(AppLocale.l('chandraBala'),
                      (r['chandraBala'] as bool) ? AppLocale.l('anukoola') : AppLocale.l('pratikoola'),
                      r['chandraBala'] as bool),
                  if (r['guruBala'] != null)
                    _balaChipRow('${AppLocale.l('mGuruBala')} (${trAll(knRashi[r['jupRashi'] as int])})',
                      (r['guruBala'] as BalaScore).score > 0 ? AppLocale.l('shubha') : AppLocale.l('ashubha'),
                      (r['guruBala'] as BalaScore).score > 0),
                ]),
              ),
            ),

          // ── Avoidance Times ──
          if ((r['rahuKala'] as String).isNotEmpty || (r['vishaGhati'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('⚠ ${AppLocale.l('avoidTime')}:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red.shade700)),
                  const SizedBox(height: 4),
                  if ((r['rahuKala'] as String).isNotEmpty)
                    Text('${AppLocale.l('rahuKala')}: ${r['rahuKala']}', style: TextStyle(fontSize: 12, color: kText)),
                  if ((r['vishaGhati'] as String).isNotEmpty)
                    Text('${AppLocale.l('vishaGhati')}: ${r['vishaGhati']}', style: TextStyle(fontSize: 12, color: kText)),
                ]),
              ),
            ),

          // ── Lagna loading indicator ──
          if (r['needsLagna'] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: kPurple1)),
                const SizedBox(width: 8),
                Text(AppLocale.l('mLagnaComputing'), style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600)),
              ]),
            ),

          // ── Lagna Windows (shows perfect, shubha & allowed windows) ──
          if (r['lagnaWindows'] != null) ...[
            () {
              final displayLws = (r['lagnaWindows'] as List<LagnaWindow>);
              if (displayLws.isEmpty) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E86AB).withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Text('🏠 ${AppLocale.l('dayLagnaLabel')}', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFF2E86AB), fontSize: 13)),
                    ),
                    ...displayLws.asMap().entries.map((entry) {
                      final lw = entry.value;
                      final bool isAbhijitWindow = lw.rashiName.contains('ಅಭಿಜಿತ್');

                      // ── Abhijit: simplified (just lagna name + timing) ──
                      if (isAbhijitWindow) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            border: entry.key < displayLws.length - 1 ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4))) : null,
                          ),
                          child: Row(children: [
                            Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 14),
                            const SizedBox(width: 6),
                            Expanded(child: Text(trAll(lw.rashiName), style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber.shade900, fontSize: 12))),
                            GestureDetector(
                              onTap: () => _openMuhurtaKundali(lw.startTime, lw.endTime, date: date, useCachedLocation: _mfUsedCache),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.amber.shade600, width: 0.5),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.open_in_new, size: 10, color: Colors.amber.shade800),
                                  const SizedBox(width: 3),
                                  Text('${lw.startTime} - ${lw.endTime}', style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            ),
                          ]),
                        );
                      }

                      // ── Normal lagna window ──
                      final rowBg = lw.isPerfect
                          ? Colors.green.withOpacity(0.1)
                          : (lw.isShubha ? Colors.amber.withOpacity(0.08) : Colors.blue.withOpacity(0.04));
                      final rowIcon = lw.isPerfect ? Icons.star : (lw.isShubha ? Icons.check_circle_outline : Icons.info_outline);
                      final iconColor = lw.isPerfect ? Colors.amber.shade700 : (lw.isShubha ? Colors.green : Colors.blue);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: rowBg,
                          border: entry.key < displayLws.length - 1 ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4))) : null,
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(rowIcon, color: iconColor, size: 14),
                            const SizedBox(width: 6),
                            Expanded(child: Text(trAll(lw.rashiName), style: TextStyle(fontWeight: FontWeight.w800, color: kText, fontSize: 12))),
                            GestureDetector(
                              onTap: () => _openMuhurtaKundali(lw.startTime, lw.endTime, date: date, useCachedLocation: _mfUsedCache),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: iconColor.withOpacity(0.4), width: 0.5),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.open_in_new, size: 10, color: iconColor),
                                  const SizedBox(width: 3),
                                  Text('${lw.startTime} - ${lw.endTime}', style: TextStyle(fontSize: 11, color: iconColor, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 3),
                          Wrap(spacing: 4, runSpacing: 3, children: [
                            _shuddhiChip(AppLocale.l('lagnaLabel'), lw.lagnaShuddhi, lw.lagnaGrahas,
                                required: lw.requiredShuddhis.contains(ShuddhiType.lagna)),
                            _shuddhiChip(AppLocale.l('saptamaShort'), lw.saptamaShuddhi, lw.saptamaGrahas,
                                required: lw.requiredShuddhis.contains(ShuddhiType.saptama)),
                            _shuddhiChip(AppLocale.l('ashtamaShort'), lw.ashtamaShuddhi, lw.ashtamaGrahas,
                                required: lw.requiredShuddhis.contains(ShuddhiType.ashtama)),
                            _shuddhiChip(AppLocale.l('dashamaShort'), lw.dashamaShuddhi, lw.dashamaGrahas,
                                required: lw.requiredShuddhis.contains(ShuddhiType.dashama)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: lw.guruAnukoola ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: lw.guruAnukoola ? Colors.amber.shade600 : Colors.grey.shade300, width: 0.5),
                              ),
                              child: Text(
                                lw.guruAnukoola ? '${AppLocale.l('guruLabel')} ✓ (${lw.guruFromLagna})' : '${AppLocale.l('guruLabel')} ✗ (${lw.guruFromLagna})',
                                style: TextStyle(fontSize: 9, color: lw.guruAnukoola ? Colors.amber.shade800 : kMuted, fontWeight: FontWeight.w700),
                              ),
                            ),
                            // Bhava Shuddhi indicator
                            if (lw.usedBhavaFallback && lw.isShubha)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.deepPurple.shade300, width: 0.5),
                                ),
                                child: Text(
                                  '${AppLocale.l('mUseBhavaShuddhi').split(' (')[0]} ✓',
                                  style: TextStyle(fontSize: 9, color: Colors.deepPurple.shade700, fontWeight: FontWeight.w700),
                                ),
                              ),
                          ]),
                        ]),
                      );
                    }),
                  ]),
                ),
              );
            }(),
          ],

          // ── Doshas ──
          if ((r['doshas'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ...((r['doshas'] as List<String>).map((d) => Text('❌ $d', style: TextStyle(fontSize: 11, color: Colors.red.shade700)))),
              ]),
            ),

          // ── Dosha Bhangas ──
          if ((r['doshaBhangas'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ...((r['doshaBhangas'] as List<String>).map((d) => Text('✅ $d', style: TextStyle(fontSize: 11, color: Colors.green.shade700)))),
              ]),
            ),

          const SizedBox(height: 12),
          ], // end if(isExpanded)
        ],
      ),
    );
  }




  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: kMuted, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _balaBadge(String label, String value, bool isGood) {
    final color = isGood ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Text('$label: $value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color.shade700)),
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

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5)))),
      child: Row(children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 12)),
        const Spacer(),
        Flexible(child: Text(value, style: TextStyle(color: kMuted, fontSize: 12), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
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

  /// Open kundali for a muhurta lagna window — shows BOTH start and end time
  /// as a 2-person view so the user can compare charts at window boundaries.
  /// For cached results, pass useCachedLocation: true to use PanchangaCache lat/lon.
  void _openMuhurtaKundali(String startTime, String endTime, {DateTime? date, bool useCachedLocation = false}) async {
    final dt = date ?? _selectedDay;
    if (dt == null) return;

    // Parse "HH:MM AM/PM" to 24h minutes
    int _parse24(String t) {
      final parts = t.trim().split(' ');
      final hm = parts[0].split(':');
      int h = int.parse(hm[0]);
      final m = int.parse(hm[1]);
      final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
      if (isPm && h != 12) h += 12;
      if (!isPm && h == 12) h = 0;
      return h * 60 + m;
    }

    // Convert 24h minutes to 12h components
    Map<String, dynamic> _to12h(int mins) {
      final hour24 = mins ~/ 60;
      final minute = mins % 60;
      final ampm = hour24 >= 12 ? 'PM' : 'AM';
      int hour12 = hour24 > 12 ? hour24 - 12 : hour24;
      if (hour12 == 0) hour12 = 12;
      return {'hour24': hour24, 'minute': minute, 'hour12': hour12, 'ampm': ampm};
    }

    final startMins = _parse24(startTime);
    final endMins = _parse24(endTime);

    final startParts = _to12h(startMins);
    final endParts = _to12h(endMins);

    DateTime useDate = dt;

    // Use cached location if available and requested, else default LocationService
    final cache = PanchangaCache.instance;
    final double lat;
    final double lon;
    final double tz;
    final String place;
    if (useCachedLocation && cache.cachedLat != null && cache.cachedLon != null) {
      lat = cache.cachedLat!;
      lon = cache.cachedLon!;
      tz = LocationService.tzOffset;
      place = cache.zoneName ?? LocationService.place;
    } else {
      lat = LocationService.lat;
      lon = LocationService.lon;
      tz = LocationService.tzOffset;
      place = LocationService.place;
    }

    // Compute kundali for START time
    final startResult = await AstroCalculator.calculate(
      year: useDate.year, month: useDate.month, day: useDate.day,
      hourUtcOffset: tz,
      hour24: startParts['hour24'] + (startParts['minute'] / 60.0),
      lat: lat, lon: lon,
      ayanamsaMode: 'lahiri',
      trueNode: true,
    );

    // Compute kundali for END time
    final endResult = await AstroCalculator.calculate(
      year: useDate.year, month: useDate.month, day: useDate.day,
      hourUtcOffset: tz,
      hour24: endParts['hour24'] + (endParts['minute'] / 60.0),
      lat: lat, lon: lon,
      ayanamsaMode: 'lahiri',
      trueNode: true,
    );

    if (startResult != null && mounted) {
      // Build end-time extra person (if end kundali computed)
      final extraPersons = <PersonEntry>[];
      if (endResult != null) {
        extraPersons.add(PersonEntry(
          name: '${AppLocale.l('muhurtaShodhane')} $endTime',
          result: endResult,
          dob: useDate,
          hour: endParts['hour12'] as int,
          minute: endParts['minute'] as int,
          ampm: endParts['ampm'] as String,
          lat: lat,
          lon: lon,
          tz: tz,
          place: place,
        ));
      }

      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DashboardScreen(
          result: startResult,
          name: '${AppLocale.l('muhurtaShodhane')} $startTime',
          place: place,
          dob: useDate,
          hour: startParts['hour12'] as int,
          minute: startParts['minute'] as int,
          ampm: startParts['ampm'] as String,
          lat: lat,
          lon: lon,
          tz: tz,
          extraInfo: {'ayanamsa': 'lahiri', 'nodeMode': 'true'},
          initialExtraPersons: extraPersons,
          onSave: (notes, aroodhas, janmaIdx, {bool isNew = true}) {},
        ),
      ));
    }
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
    final userRulesLocal = UserRulesManager.instance.getRules(_selectedMuhurtaEvent);
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

      final dayW = _scanLagnaRange(srJd, ssJd, ayn, dayPlanetRashis, guruRashiIdx, allowedLagnas, rules, useBhavaShuddhi: userRulesLocal.useBhavaShuddhi, mandiSidDeg: _mandiDegFromJd(dayMandiJd));

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

      final nightW = _scanLagnaRange(ssJd, nextSrJd, ayn, nightPlanetRashis, guruRashiIdx, allowedLagnas, rules, useBhavaShuddhi: userRulesLocal.useBhavaShuddhi, mandiSidDeg: _mandiDegFromJd(nightMandiJd));

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

  /// Get Mandi's sidereal degree from its JD (for bhava house computation)
  double _mandiDegFromJd(double mandiJd) {
    try {
      final houses = Ephemeris.placidusHousesFull(
        mandiJd, LocationService.lat, LocationService.lon,
      );
      if (houses != null && houses.ascmc.length >= 1) {
        Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
        final aMandi = Sweph.swe_get_ayanamsa(mandiJd);
        return ((houses.ascmc[0] as double) - aMandi + 360.0) % 360.0;
      }
    } catch (_) {}
    return -1.0;
  }

  List<LagnaWindow> _scanLagnaRange(double startJd, double endJd, double ayn,
      Map<String, int> planetRashis, int guruRashiIdx, List<int>? allowedLagnas, MuhurtaEventRules? rules, {bool useBhavaShuddhi = false, double mandiSidDeg = -1.0}) {
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

        // ── Bhava Shuddhi Fallback (2-minute fine scan) ──
        // When toggle ON + any required shuddhi fails in Rashi chart,
        // scan in 2-min increments to find ALL exact sub-windows where Bhava shuddhi is clear.
        final reqShuddhis = rules?.requiredShuddhis ?? const {ShuddhiType.lagna};

        final bool needsBhava = useBhavaShuddhi && (
          (lagnaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.lagna)) ||
          (saptamaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.saptama)) ||
          (ashtamaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.ashtama)) ||
          (dashamaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.dashama))
        );

        if (needsBhava) {
          // 2-minute scan within [windowStartJd, windowEndJd]
          final double fineStep = 2.0 / (24.0 * 60.0); // 2 min in JD
          double scanJd = windowStartJd;
          double? cleanStart;
          double cleanStartMins = 0;

          // Shuddhi types that failed in Rashi
          final bool checkL = lagnaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.lagna);
          final bool checkS = saptamaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.saptama);
          final bool checkA = ashtamaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.ashtama);
          final bool checkD = dashamaM.isNotEmpty && reqShuddhis.contains(ShuddhiType.dashama);

          // Collect ALL clean sub-windows
          final List<List<double>> cleanSubWindows = []; // each: [startMins, endMins]

          while (scanJd <= windowEndJd + fineStep * 0.5) {
            final bh = Ephemeris.placidusHousesFull(scanJd, LocationService.lat, LocationService.lon);
            bool allClear = true;

            if (bh != null && bh.ascmc.length >= 2) {
              final cusps = calcSripathiBhavaCusps(bh.ascmc[0] as double, bh.ascmc[1] as double, ayn);
              // Recalculate planet positions at this exact moment
              final pos = Ephemeris.calcAll(scanJd, 'lahiri', true);

              // Helper: check if all planets in list are NOT in target bhava
              bool isClear(List<String> planets, int targetHouse) {
                for (final planet in planets) {
                  // Mandi: use pre-computed sidereal degree for bhava check
                  if (planet == 'ಮಾಂದಿ') {
                    if (mandiSidDeg >= 0 && getBhavaHouse(normDegMuhurta(mandiSidDeg), cusps) == targetHouse) return false;
                    continue;
                  }
                  final engName = engToKn.entries.firstWhere(
                    (e) => e.value == planet,
                    orElse: () => const MapEntry('', ''),
                  ).key;
                  if (engName.isNotEmpty && pos.containsKey(engName)) {
                    if (getBhavaHouse(normDegMuhurta(pos[engName]![0]), cusps) == targetHouse) return false;
                  }
                }
                return true;
              }

              if (checkL && !isClear(lagnaM, 1)) allClear = false;
              if (checkS && !isClear(saptamaM, 7)) allClear = false;
              if (checkA && !isClear(ashtamaM, 8)) allClear = false;
              if (checkD && !isClear(dashamaM, 10)) allClear = false;
            } else {
              allClear = false;
            }

            final localFrac = ((scanJd + 0.5 + (LocationService.tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
            final localMins = localFrac * 24.0 * 60.0;

            if (allClear) {
              if (cleanStart == null) {
                cleanStart = scanJd;
                cleanStartMins = localMins;
              }
            } else {
              if (cleanStart != null) {
                // Found a clean sub-window: cleanStartMins to localMins
                cleanSubWindows.add([cleanStartMins, localMins]);
                cleanStart = null;
              }
            }
            scanJd += fineStep;
          }

          // Handle clean window that extends to end of lagna window
          if (cleanStart != null) {
            cleanSubWindows.add([cleanStartMins, endMins]);
          }

          // Shared properties for all sub-windows from this rashi window
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

          if (cleanSubWindows.isNotEmpty) {
            // Emit each clean sub-window as a separate LagnaWindow
            for (final sw in cleanSubWindows) {
              windows.add(LagnaWindow(
                rashiIndex: currentRashi,
                rashiName: appRashi[currentRashi],
                startTime: _minutesToTimeStr(sw[0]),
                endTime: _minutesToTimeStr(sw[1]),
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
                requiredShuddhis: reqShuddhis,
                usedBhavaFallback: true,
                lagnaBhavaShuddhi: true,
                saptamaBhavaShuddhi: true,
                ashtamaBhavaShuddhi: true,
                dashamaBhavaShuddhi: true,
                lagnaBhavaGrahas: const [],
                saptamaBhavaGrahas: const [],
                ashtamaBhavaGrahas: const [],
                dashamaBhavaGrahas: const [],
              ));
            }
          } else {
            // No clean sub-window — emit the rashi window with bhava shuddhi failed
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
              requiredShuddhis: reqShuddhis,
              usedBhavaFallback: true,
              lagnaBhavaShuddhi: !checkL,
              saptamaBhavaShuddhi: !checkS,
              ashtamaBhavaShuddhi: !checkA,
              dashamaBhavaShuddhi: !checkD,
              lagnaBhavaGrahas: const [],
              saptamaBhavaGrahas: const [],
              ashtamaBhavaGrahas: const [],
              dashamaBhavaGrahas: const [],
            ));
          }
        } else {
          // ── No bhava fallback needed: standard rashi-based window ──
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
            requiredShuddhis: reqShuddhis,
            usedBhavaFallback: false,
            lagnaBhavaShuddhi: true,
            saptamaBhavaShuddhi: true,
            ashtamaBhavaShuddhi: true,
            dashamaBhavaShuddhi: true,
            lagnaBhavaGrahas: const [],
            saptamaBhavaGrahas: const [],
            ashtamaBhavaGrahas: const [],
            dashamaBhavaGrahas: const [],
          ));
        }

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
          final bool isAbhijitWindow = lw.rashiName.contains('ಅಭಿಜಿತ್');

          // ── Abhijit: simplified display (just lagna name + timing) ──
          if (isAbhijitWindow) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                border: i < windows.length - 1 ? Border(bottom: BorderSide(color: kBorder.withOpacity(0.4))) : null,
              ),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(trAll(lw.rashiName), style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.amber.shade900, fontSize: 13,
                ))),
                GestureDetector(
                  onTap: () => _openMuhurtaKundali(lw.startTime, lw.endTime),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade600, width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.open_in_new, size: 12, color: Colors.amber.shade800),
                      const SizedBox(width: 4),
                      Text('${lw.startTime} - ${lw.endTime}', style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.w700,
                      )),
                    ]),
                  ),
                ),
              ]),
            );
          }

          // ── Normal lagna window with shuddhi chips ──
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
                GestureDetector(
                  onTap: () => _openMuhurtaKundali(lw.startTime, lw.endTime),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (lw.isShubha ? Colors.green : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: lw.isShubha ? Colors.green.shade400 : Colors.grey.shade400, width: 0.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.open_in_new, size: 12, color: lw.isShubha ? Colors.green.shade700 : kMuted),
                      const SizedBox(width: 4),
                      Text('${lw.startTime} - ${lw.endTime}', style: TextStyle(
                        fontSize: 12, color: lw.isShubha ? Colors.green.shade700 : kMuted, fontWeight: FontWeight.w600,
                      )),
                    ]),
                  ),
                ),
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
                // Bhava Shuddhi indicator — shown when bhava fallback was used
                if (lw.usedBhavaFallback && lw.isShubha && !lw.lagnaShuddhi || !lw.saptamaShuddhi || !lw.ashtamaShuddhi || !lw.dashamaShuddhi)
                  if (lw.usedBhavaFallback && lw.isShubha)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.deepPurple.shade300, width: 0.5),
                      ),
                      child: Text(
                        '${AppLocale.l('mUseBhavaShuddhi').split(' (')[0]} ✓',
                        style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade700, fontWeight: FontWeight.w700),
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

// ── Helper classes ──
class LagnaWindow {
  final int rashiIdx;
  final int rashiIndex; // alias
  final String rashiName;
  final String startTime;
  final String endTime;
  final bool isAllowed;
  final bool lagnaShuddhi;
  final bool saptamaShuddhi;
  final bool ashtamaShuddhi;
  final bool dashamaShuddhi;
  final bool chandraSaptamaShuddhi;
  final bool guruAnukoola;
  final List<String> lagnaGrahas;
  final List<String> saptamaGrahas;
  final List<String> ashtamaGrahas;
  final List<String> dashamaGrahas;
  final List<String> chandraSaptamaGrahas;
  final int guruFromLagna;
  final Set<ShuddhiType> requiredShuddhis;
  final List<String> issues;

  // Bhava-based shuddhi (fallback when Rashi fails)
  final bool usedBhavaFallback;
  final bool lagnaBhavaShuddhi;
  final bool saptamaBhavaShuddhi;
  final bool ashtamaBhavaShuddhi;
  final bool dashamaBhavaShuddhi;
  final List<String> lagnaBhavaGrahas;
  final List<String> saptamaBhavaGrahas;
  final List<String> ashtamaBhavaGrahas;
  final List<String> dashamaBhavaGrahas;

  bool _checkShuddhi(bool rashiResult, bool bhavaResult) {
    if (rashiResult) return true;
    if (usedBhavaFallback) return bhavaResult;
    return false;
  }

  bool get isPerfect => isShubha && guruAnukoola;
  bool get isShubha {
    if (!isAllowed) return false;
    if (requiredShuddhis.contains(ShuddhiType.lagna) && !_checkShuddhi(lagnaShuddhi, lagnaBhavaShuddhi)) return false;
    if (requiredShuddhis.contains(ShuddhiType.saptama) && !_checkShuddhi(saptamaShuddhi, saptamaBhavaShuddhi)) return false;
    if (requiredShuddhis.contains(ShuddhiType.ashtama) && !_checkShuddhi(ashtamaShuddhi, ashtamaBhavaShuddhi)) return false;
    if (requiredShuddhis.contains(ShuddhiType.dashama) && !_checkShuddhi(dashamaShuddhi, dashamaBhavaShuddhi)) return false;
    if (requiredShuddhis.contains(ShuddhiType.chandraSaptama) && !chandraSaptamaShuddhi) return false;
    return true;
  }

  LagnaWindow({
    int? rashiIdx,
    required this.rashiIndex,
    required this.rashiName,
    required this.startTime,
    required this.endTime,
    this.isAllowed = true,
    required this.lagnaShuddhi,
    required this.saptamaShuddhi,
    required this.ashtamaShuddhi,
    required this.dashamaShuddhi,
    this.chandraSaptamaShuddhi = true,
    required this.guruAnukoola,
    this.lagnaGrahas = const [],
    this.saptamaGrahas = const [],
    this.ashtamaGrahas = const [],
    this.dashamaGrahas = const [],
    this.chandraSaptamaGrahas = const [],
    this.guruFromLagna = 0,
    this.requiredShuddhis = const {ShuddhiType.lagna},
    this.issues = const [],
    this.usedBhavaFallback = false,
    this.lagnaBhavaShuddhi = true,
    this.saptamaBhavaShuddhi = true,
    this.ashtamaBhavaShuddhi = true,
    this.dashamaBhavaShuddhi = true,
    this.lagnaBhavaGrahas = const [],
    this.saptamaBhavaGrahas = const [],
    this.ashtamaBhavaGrahas = const [],
    this.dashamaBhavaGrahas = const [],
  }) : rashiIdx = rashiIdx ?? rashiIndex;
}

class _AscSample {
  final double jd;
  final int rashiIdx;
  final double localMins;
  _AscSample({required this.jd, required this.rashiIdx, required this.localMins});
}
