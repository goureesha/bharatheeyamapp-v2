import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../services/ad_service.dart';

class TaranukoolaScreen extends StatefulWidget {
  const TaranukoolaScreen({super.key});

  @override
  State<TaranukoolaScreen> createState() => _TaranukoolaScreenState();
}

class _TaranukoolaScreenState extends State<TaranukoolaScreen> {
  int? _janmaNakshatraIdx;

  final _taras = [
    'ಜನ್ಮ ತಾರೆ (ಅಶುಭ)',
    'ಸಂಪತ್ ತಾರೆ (ಶುಭ)',
    'ವಿಪತ್ ತಾರೆ (ಅಶುಭ)',
    'ಕ್ಷೇಮ ತಾರೆ (ಶುಭ)',
    'ಪ್ರತ್ಯಕ್ ತಾರೆ (ಅಶುಭ)',
    'ಸಾಧಕ ತಾರೆ (ಶುಭ)',
    'ನೈಧನ ತಾರೆ (ಅಶುಭ)',
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
      });
    }
  }

  Future<void> _saveNakshatra(int? idx) async {
    if (idx != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dashboard_janma_nakshatra', idx);
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
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('ತಾರಾನುಕೂಲ ಫಲಿತಾಂಶಗಳು', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
                    const SizedBox(height: 16),
                    Text('ನಿಮ್ಮ ಜನ್ಮ ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kText)),
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
                          hint: Text('ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ'),
                          value: _janmaNakshatraIdx,
                          dropdownColor: kCard,
                          items: List.generate(27, (i) => DropdownMenuItem<int>(
                            value: i,
                            child: Text(knNak[i], style: TextStyle(fontSize: 16, color: kText)),
                          )),
                          onChanged: (val) {
                            setState(() {
                              _janmaNakshatraIdx = val;
                              _saveNakshatra(val);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_janmaNakshatraIdx != null) ...[
                      Text('ನಿಮ್ಮ ನಕ್ಷತ್ರಕ್ಕೆ ಅನುಗುಣವಾಗಿ ತಾರೆಗಳ ಪಟ್ಟಿ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kText)),
                      const SizedBox(height: 12),
                      ...List.generate(9, (taraIdx) {
                        bool isShubha = (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
                        Color bgColor = isShubha ? Colors.green.shade50 : Colors.red.shade50;
                        Color borderColor = isShubha ? Colors.green.shade200 : Colors.red.shade200;
                        Color textColor = isShubha ? Colors.green.shade800 : Colors.red.shade800;

                        int n1 = (_janmaNakshatraIdx! + taraIdx) % 27;
                        int n2 = (_janmaNakshatraIdx! + taraIdx + 9) % 27;
                        int n3 = (_janmaNakshatraIdx! + taraIdx + 18) % 27;
                        String nakshatrasText = '${knNak[n1]}, ${knNak[n2]}, ${knNak[n3]}';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _taras[taraIdx],
                                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                                )
                              ),
                              Container(width: 1, height: 40, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 12)),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  nakshatrasText,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kText),
                                )
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                       Container(
                         padding: const EdgeInsets.all(16),
                         alignment: Alignment.center,
                         decoration: BoxDecoration(color: kBorder.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                         child: Text('ಫಲಿತಾಂಶವನ್ನು ನೋಡಲು ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ.', style: TextStyle(color: kMuted))
                       )
                    ]
                  ],
                ),
              ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
