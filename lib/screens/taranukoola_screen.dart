import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sweph/sweph.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

class TaranukoolaScreen extends StatefulWidget {
  const TaranukoolaScreen({super.key});

  @override
  State<TaranukoolaScreen> createState() => _TaranukoolaScreenState();
}

class _TaranukoolaScreenState extends State<TaranukoolaScreen> {
  bool _isTwoPersonMode = false;
  int? _janmaNakshatraIdx1;
  int? _janmaNakshatraIdx2;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _dailyNakshatraCache = {};

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
  }

  Future<void> _loadNakshatra() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isTwoPersonMode = prefs.getBool('dashboard_tara_two_person') ?? false;
        _janmaNakshatraIdx1 = prefs.getInt('dashboard_janma_nakshatra');
        _janmaNakshatraIdx2 = prefs.getInt('dashboard_janma_nakshatra2');
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dashboard_tara_two_person', _isTwoPersonMode);
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

  bool _isGoodTara(int taraIdx) {
    return (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
  }

  Widget _buildMarker(DateTime date, List events) {
    if (_janmaNakshatraIdx1 == null) return const SizedBox();
    if (_isTwoPersonMode && _janmaNakshatraIdx2 == null) return const SizedBox();

    int dinaIdx = _getNakshatraForDate(date);
    
    int tara1 = (dinaIdx - _janmaNakshatraIdx1! + 27) % 27 % 9;
    bool isGood1 = _isGoodTara(tara1);

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
      int tara2 = (dinaIdx - _janmaNakshatraIdx2! + 27) % 27 % 9;
      bool isGood2 = _isGoodTara(tara2);
      
      Color dotColor;
      if (isGood1 && isGood2) {
        dotColor = Colors.green; // Good for both
      } else if (!isGood1 && !isGood2) {
        dotColor = Colors.red; // Bad for both
      } else {
        dotColor = Colors.orange; // Half good
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ತಾರಾನುಕೂಲ / Taranukoola',
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
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('೧ ವ್ಯಕ್ತಿ (1 Person)')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('೨ ವ್ಯಕ್ತಿಗಳು (2 Persons)')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(_isTwoPersonMode ? 'ವ್ಯಕ್ತಿ 1ರ ಜನ್ಮ ನಕ್ಷತ್ರ (Person 1):' : 'ನಿಮ್ಮ ಜನ್ಮ ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
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
                      Text('ವ್ಯಕ್ತಿ 2ರ ಜನ್ಮ ನಕ್ಷತ್ರ (Person 2):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
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
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, events) => _buildMarker(date, events),
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
                          bool isGood1 = _isGoodTara(tara1);
                          
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
                                    const SizedBox(height: 8),
                                    Text(_taras[tara1], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor), textAlign: TextAlign.center),
                                  ],
                                ),
                              );
                          } else {
                              int tara2 = (dinaIdx - _janmaNakshatraIdx2! + 27) % 27 % 9;
                              bool isGood2 = _isGoodTara(tara2);
                              
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
                         decoration: BoxDecoration(color: kBorder.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                         child: Text('ಫಲಿತಾಂಶವನ್ನು ನೋಡಲು ಎರಡೂ ನಕ್ಷತ್ರಗಳನ್ನು ಆಯ್ಕೆಮಾಡಿ.', style: TextStyle(color: kMuted))
                       )
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
