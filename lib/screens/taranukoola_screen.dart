import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';


class TaranukoolaScreen extends StatefulWidget {
  const TaranukoolaScreen({super.key});

  @override
  State<TaranukoolaScreen> createState() => _TaranukoolaScreenState();
}

class _TaranukoolaScreenState extends State<TaranukoolaScreen> {
  int? _janmaNakshatraIdx;
  int? _dinaNakshatraIdx;

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
    _loadNakshatra();
  }

  Future<void> _loadNakshatra() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _janmaNakshatraIdx = prefs.getInt('dashboard_janma_nakshatra');
        _dinaNakshatraIdx = prefs.getInt('dashboard_dina_nakshatra');
      });
    }
  }

  Future<void> _saveJanmaNakshatra(int? idx) async {
    if (idx != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dashboard_janma_nakshatra', idx);
    }
  }

  Future<void> _saveDinaNakshatra(int? idx) async {
    if (idx != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dashboard_dina_nakshatra', idx);
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
                    Text('ನಿಮ್ಮ ಜನ್ಮ ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
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
                          value: _janmaNakshatraIdx,
                          dropdownColor: kCard,
                          items: List.generate(27, (i) {
                            bool disabled = _dinaNakshatraIdx == i;
                            return DropdownMenuItem<int>(
                              value: disabled ? null : i,
                              child: Text(knNak[i], style: TextStyle(fontSize: 16, color: disabled ? kMuted : kText)),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _janmaNakshatraIdx = val;
                                _saveJanmaNakshatra(val);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('ದಿನದ ನಕ್ಷತ್ರವನ್ನು (ಅಥವಾ ಗುರಿ ನಕ್ಷತ್ರ) ಆಯ್ಕೆಮಾಡಿ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kText)),
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
                          hint: Text('ದಿನದ ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ'),
                          value: _dinaNakshatraIdx,
                          dropdownColor: kCard,
                          items: List.generate(27, (i) {
                            bool disabled = _janmaNakshatraIdx == i;
                            return DropdownMenuItem<int>(
                              value: disabled ? null : i,
                              child: Text(knNak[i], style: TextStyle(fontSize: 16, color: disabled ? kMuted : kText)),
                            );
                          }),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _dinaNakshatraIdx = val;
                                _saveDinaNakshatra(val);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_janmaNakshatraIdx != null && _dinaNakshatraIdx != null) ...[
                      Builder(
                        builder: (context) {
                          int taraIdx = (_dinaNakshatraIdx! - _janmaNakshatraIdx! + 27) % 27 % 9;
                          bool isShubha = (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
                          Color bgColor = isShubha ? Colors.green.shade50 : Colors.red.shade50;
                          Color borderColor = isShubha ? Colors.green.shade500 : Colors.red.shade500;
                          Color textColor = isShubha ? Colors.green.shade900 : Colors.red.shade900;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Column(
                              children: [
                                Text('ಫಲಿತಾಂಶ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.8))),
                                const SizedBox(height: 8),
                                Text(
                                  _taras[taraIdx],
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isShubha ? 'ಇದು ಶುಭ ತಾರೆ. ಅನುಕೂಲಕರ ಫಲಿತಾಂಶಗಳನ್ನು ನಿರೀಕ್ಷಿಸಬಹುದು.' : 'ಇದು ಅಶುಭ ತಾರೆ. ಎಚ್ಚರಿಕೆ ವಹಿಸಿ.',
                                  style: TextStyle(fontSize: 14, color: textColor),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
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
