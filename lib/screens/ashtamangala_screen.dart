import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';

/// Ashtamangala Prashna — traditional Kerala divination system
/// Uses a 3-digit number (100-999) from the querent to derive answers.
class AshtamangalaScreen extends StatefulWidget {
  const AshtamangalaScreen({super.key});

  @override
  State<AshtamangalaScreen> createState() => _AshtamangalaScreenState();
}

class _AshtamangalaScreenState extends State<AshtamangalaScreen> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _hasResult = false;
  String _errorMsg = '';

  // Results
  int _asmNumber = 0;
  int _d1 = 0, _d2 = 0, _d3 = 0, _digitSum = 0;
  int _rashiIndex = 0; // 0-based
  int _nakshatraIndex = 0;
  int _tithiIndex = 0;
  int _yogaIndex = 0;
  int _karanaIndex = 0;

  // Panchanga context
  PanchangData? _panchang;

  static const _rashiNames = [
    'ಮೇಷ', 'ವೃಷಭ', 'ಮಿಥುನ', 'ಕರ್ಕ', 'ಸಿಂಹ', 'ಕನ್ಯಾ',
    'ತುಲಾ', 'ವೃಶ್ಚಿಕ', 'ಧನು', 'ಮಕರ', 'ಕುಂಭ', 'ಮೀನ',
  ];

  static const _nakshatraNames = [
    'ಅಶ್ವಿನಿ', 'ಭರಣಿ', 'ಕೃತ್ತಿಕಾ', 'ರೋಹಿಣಿ', 'ಮೃಗಶಿರ', 'ಆರ್ದ್ರಾ',
    'ಪುನರ್ವಸು', 'ಪುಷ್ಯ', 'ಆಶ್ಲೇಷಾ', 'ಮಘಾ', 'ಪೂ.ಫಾಲ್ಗುಣಿ', 'ಉ.ಫಾಲ್ಗುಣಿ',
    'ಹಸ್ತ', 'ಚಿತ್ರಾ', 'ಸ್ವಾತಿ', 'ವಿಶಾಖ', 'ಅನುರಾಧ', 'ಜ್ಯೇಷ್ಠ',
    'ಮೂಲ', 'ಪೂ.ಅಷಾಢ', 'ಉ.ಅಷಾಢ', 'ಶ್ರವಣ', 'ಧನಿಷ್ಠ', 'ಶತಭಿಷ',
    'ಪೂ.ಭಾದ್ರ', 'ಉ.ಭಾದ್ರ', 'ರೇವತಿ',
  ];

  static const _tithiNames = [
    'ಪ್ರತಿಪದ', 'ದ್ವಿತೀಯ', 'ತೃತೀಯ', 'ಚತುರ್ಥಿ', 'ಪಂಚಮಿ',
    'ಷಷ್ಠಿ', 'ಸಪ್ತಮಿ', 'ಅಷ್ಟಮಿ', 'ನವಮಿ', 'ದಶಮಿ',
    'ಏಕಾದಶಿ', 'ದ್ವಾದಶಿ', 'ತ್ರಯೋದಶಿ', 'ಚತುರ್ದಶಿ', 'ಪೂರ್ಣಿಮಾ/ಅಮಾವಾಸ್ಯೆ',
  ];

  // 8 Dravyas (objects) of Ashtamangala
  static const _ashtaItems = [
    {'name': 'ದರ್ಪಣ (Mirror)',  'icon': '🪞', 'meaning': 'ಆತ್ಮ ಜ್ಞಾನ, ಸ್ವಯಂ ಅರಿವು'},
    {'name': 'ವೃಷಭ (Bull)',      'icon': '🐂', 'meaning': 'ಧರ್ಮ, ಭದ್ರತೆ, ಸ್ಥಿರತೆ'},
    {'name': 'ಸ್ವರ್ಣ (Gold)',    'icon': '🥇', 'meaning': 'ಸಂಪತ್ತು, ಐಶ್ವರ್ಯ'},
    {'name': 'ಕುಂಭ (Pot)',       'icon': '🏺', 'meaning': 'ಪೂರ್ಣತೆ, ಸಮೃದ್ಧಿ'},
    {'name': 'ವಸ್ತ್ರ (Cloth)',   'icon': '🧵', 'meaning': 'ಮಾನ, ಗೌರವ'},
    {'name': 'ತಾಂಬೂಲ (Betel)',  'icon': '🌿', 'meaning': 'ಶುಭ, ಮಂಗಳ'},
    {'name': 'ಫಲ (Fruit)',       'icon': '🍎', 'meaning': 'ಫಲಪ್ರಾಪ್ತಿ, ಯಶಸ್ಸು'},
    {'name': 'ದೀಪ (Lamp)',       'icon': '🪔', 'meaning': 'ಜ್ಞಾನ, ಬೆಳಕು'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPanchang();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPanchang() async {
    final now = DateTime.now();
    final result = await AstroCalculator.calculate(
      year: now.year, month: now.month, day: now.day,
      hourUtcOffset: LocationService.tzOffset,
      hour24: now.hour + now.minute / 60.0,
      lat: LocationService.lat, lon: LocationService.lon,
      ayanamsaMode: 'lahiri', trueNode: true,
    );
    if (result != null && mounted) {
      setState(() => _panchang = result.panchang);
    }
  }

  void _calculate() {
    final text = _numberCtrl.text.trim();
    final num = int.tryParse(text);

    if (num == null || num < 100 || num > 999) {
      setState(() {
        _errorMsg = '100 ರಿಂದ 999 ರ ನಡುವೆ ಮೂರಂಕಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ';
        _hasResult = false;
      });
      return;
    }

    _d1 = num ~/ 100;
    _d2 = (num ~/ 10) % 10;
    _d3 = num % 10;
    _digitSum = _d1 + _d2 + _d3;

    // Validate: digit sum should be 4, 12, or 20 (traditional rule)
    // Some traditions allow any sum — we'll compute either way but show note
    _asmNumber = num;

    // Derive Rashi from number: (number - 1) mod 12
    _rashiIndex = (num - 1) % 12;

    // Derive Nakshatra: (number - 1) mod 27
    _nakshatraIndex = (num - 1) % 27;

    // Derive Tithi: (number - 1) mod 15
    _tithiIndex = (num - 1) % 15;

    // Derive Yoga: digit sum mod 27
    _yogaIndex = (_digitSum - 1) % 27;

    // Derive Karana: (number - 1) mod 11
    _karanaIndex = (num - 1) % 11;

    setState(() {
      _hasResult = true;
      _errorMsg = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ / Ashtamangala',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(child: Column(
          children: [
            // ═══ Info Card ═══
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('🪔', style: TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(child: Text('ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: kOrange))),
                ]),
                const SizedBox(height: 10),
                Text(
                  'ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆಯು ಕೇರಳದ ಪ್ರಾಚೀನ ಜ್ಯೋತಿಷ ಪದ್ಧತಿ. ಪ್ರಶ್ನೆ ಕೇಳುವವರು '
                  '100 ರಿಂದ 999 ರ ನಡುವಿನ ಮೂರಂಕಿ ಸಂಖ್ಯೆಯನ್ನು ಮನಸ್ಸಿನಲ್ಲಿ ಧ್ಯಾನಿಸಿ ಹೇಳಬೇಕು.',
                  style: TextStyle(color: kText, fontSize: 13, height: 1.5),
                ),
              ]),
            ),

            // ═══ 8 Mangala Items ═══
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ಅಷ್ಟ ಮಂಗಲ ದ್ರವ್ಯಗಳು', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 14, color: kPurple2)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: _ashtaItems.map((item) =>
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPurple2.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kPurple2.withOpacity(0.12)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(item['icon']!, style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(item['name']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                    ]),
                  ),
                ).toList()),
              ]),
            ),

            // ═══ Input Card ═══
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ಪ್ರಶ್ನೆ ನಮೂದಿಸಿ', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 15, color: kTeal)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ಪ್ರುಚ್ಛಕರ ಹೆಸರು / Querent Name (Optional)',
                    prefixIcon: Icon(Icons.person, color: kMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(color: kText),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'ಮೂರಂಕಿ ಸಂಖ್ಯೆ (100-999)',
                    prefixIcon: Icon(Icons.pin, color: kMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'ಉದಾ: 357',
                  ),
                  style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _calculate(),
                ),
                if (_errorMsg.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_errorMsg, style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _calculate,
                    icon: Icon(Icons.calculate, size: 20),
                    label: Text('ಲೆಕ್ಕ ಹಾಕಿ / Calculate', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
            ),

            // ═══ Results ═══
            if (_hasResult) ...[
              // Digit analysis
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.analytics, color: kOrange, size: 22),
                    const SizedBox(width: 8),
                    Text('ಸಂಖ್ಯಾ ವಿಶ್ಲೇಷಣೆ / Number Analysis', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14, color: kOrange)),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _digitBox('ನೂರ', _d1),
                    _digitBox('ಹತ್ತು', _d2),
                    _digitBox('ಒಂದು', _d3),
                    Container(width: 1, height: 40, color: kBorder),
                    _digitBox('ಮೊತ್ತ', _digitSum),
                  ]),
                  const SizedBox(height: 10),
                  if (_digitSum == 4 || _digitSum == 12 || _digitSum == 20)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text('ಅಂಕೆಗಳ ಮೊತ್ತ ₌ $_digitSum (ಪ್ರಶ್ನೆ ಯೋಗ್ಯ)', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.info_outline, color: kOrange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('ಅಂಕೆಗಳ ಮೊತ್ತ ₌ $_digitSum (ಸಾಂಪ್ರದಾಯಿಕ ಮೊತ್ತ 4, 12, ಅಥವಾ 20)',
                          style: TextStyle(color: kOrange, fontSize: 12, fontWeight: FontWeight.w700))),
                      ]),
                    ),
                ]),
              ),

              // Main Prashna Results
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.auto_awesome, color: kPurple1, size: 22),
                    const SizedBox(width: 8),
                    Text('ಪ್ರಶ್ನೆ ಫಲಿತಾಂಶ / Results', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14, color: kPurple1)),
                  ]),
                  const SizedBox(height: 12),
                  _resultRow('ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ', '$_asmNumber'),
                  if (_nameCtrl.text.isNotEmpty)
                    _resultRow('ಪ್ರುಚ್ಛಕ', _nameCtrl.text),
                  _resultRow('ಪ್ರಶ್ನೆ ರಾಶಿ', '${_rashiNames[_rashiIndex]} (${_rashiIndex + 1})'),
                  _resultRow('ಪ್ರಶ್ನೆ ನಕ್ಷತ್ರ', '${_nakshatraNames[_nakshatraIndex]} (${_nakshatraIndex + 1})'),
                  _resultRow('ಪ್ರಶ್ನೆ ತಿಥಿ', '${_tithiNames[_tithiIndex]} (${_tithiIndex + 1})'),
                  if (_panchang != null) ...[
                    const Divider(),
                    Text('ಪ್ರಶ್ನೆ ಸಮಯದ ಪಂಚಾಂಗ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kMuted)),
                    const SizedBox(height: 6),
                    _resultRow('ವಾರ', _panchang!.vara),
                    _resultRow('ತಿಥಿ', _panchang!.tithi),
                    _resultRow('ನಕ್ಷತ್ರ', _panchang!.nakshatra),
                    _resultRow('ಯೋಗ', _panchang!.yoga),
                  ],
                ]),
              ),

              // Which Ashta Mangala Dravya is indicated
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('🪔', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text('ಸೂಚಿತ ಮಂಗಲ ದ್ರವ್ಯ', style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 14, color: kOrange)),
                  ]),
                  const SizedBox(height: 12),
                  () {
                    final idx = (_asmNumber - 1) % 8;
                    final item = _ashtaItems[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kOrange.withOpacity(0.08), kPurple2.withOpacity(0.08)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kOrange.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Text(item['icon']!, style: TextStyle(fontSize: 36)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
                          const SizedBox(height: 4),
                          Text(item['meaning']!, style: TextStyle(fontSize: 13, color: kMuted)),
                        ])),
                      ]),
                    );
                  }(),
                ]),
              ),
            ],
            const SizedBox(height: 24),
          ],
        )),
      ),
    );
  }

  Widget _digitBox(String label, int value) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: kMuted)),
      const SizedBox(height: 4),
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: kPurple2.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPurple2.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPurple2)),
      ),
    ]);
  }

  Widget _resultRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 2, child: Text(k, style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 13))),
        Expanded(flex: 3, child: Text(v, style: TextStyle(color: kText, fontSize: 13))),
      ]),
    );
  }
}
