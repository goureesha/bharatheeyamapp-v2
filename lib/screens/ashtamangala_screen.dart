import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';

/// Ashtamangala Prashna — traditional Kerala divination system
/// Enhanced with Sankhya Ganita, Quality of Time, Sutras, and Sputas
class AshtamangalaScreen extends StatefulWidget {
  const AshtamangalaScreen({super.key});

  @override
  State<AshtamangalaScreen> createState() => _AshtamangalaScreenState();
}

class _AshtamangalaScreenState extends State<AshtamangalaScreen> with SingleTickerProviderStateMixin {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _hasResult = false;
  String _errorMsg = '';
  late TabController _tabCtrl;

  // Results
  int _asmNumber = 0;
  int _d1 = 0, _d2 = 0, _d3 = 0, _digitSum = 0;
  int _selectedRashi = 0; // Querent's birth rashi (0-11)
  int _selectedNakshatra = 0; // Querent's janma nakshatra (0-26)

  // Sankhya Ganita results
  int _numPaksha = 0, _numTithi = 0, _numNak = 0, _numVara = 0;
  int _numRashi = 0, _numGraha = 0, _numBhuta = 0;

  // Panchanga context
  PanchangData? _panchang;
  KundaliResult? _prashnaResult;

  static const _rashiNames = [
    'ಮೇಷ', 'ವೃಷಭ', 'ಮಿಥುನ', 'ಕರ್ಕ', 'ಸಿಂಹ', 'ಕನ್ಯಾ',
    'ತುಲಾ', 'ವೃಶ್ಚಿಕ', 'ಧನು', 'ಮಕರ', 'ಕುಂಭ', 'ಮೀನ',
  ];
  static const _rashiEngNames = [
    'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya',
    'Tula', 'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena',
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

  static const _varaNames = ['ಭಾನು', 'ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];
  static const _grahaNames = ['ಸೂರ್ಯ', 'ಚಂದ್ರ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];
  static const _bhutaNames = ['ಪೃಥ್ವಿ', 'ಜಲ', 'ಅಗ್ನಿ', 'ವಾಯು', 'ಆಕಾಶ'];
  static const _pakshaNames = ['ಶುಕ್ಲ ಪಕ್ಷ', 'ಕೃಷ್ಣ ಪಕ್ಷ'];

  // 8 Dravyas (objects) of Ashtamangala
  static const _ashtaItems = [
    {'name': 'ದರ್ಪಣ (Mirror)',  'icon': '🪞', 'deity': 'ಸೂರ್ಯ'},
    {'name': 'ವೃಷಭ (Bull)',      'icon': '🐂', 'deity': 'ಶಿವ'},
    {'name': 'ಸ್ವರ್ಣ (Gold)',    'icon': '🥇', 'deity': 'ಲಕ್ಷ್ಮೀ'},
    {'name': 'ಕುಂಭ (Pot)',       'icon': '🏺', 'deity': 'ವರುಣ'},
    {'name': 'ವಸ್ತ್ರ (Cloth)',   'icon': '🧵', 'deity': 'ಚಂದ್ರ'},
    {'name': 'ತಾಂಬೂಲ (Betel)',  'icon': '🌿', 'deity': 'ಗಣಪತಿ'},
    {'name': 'ಫಲ (Fruit)',       'icon': '🍎', 'deity': 'ಬ್ರಹ್ಮ'},
    {'name': 'ದೀಪ (Lamp)',       'icon': '🪔', 'deity': 'ಅಗ್ನಿ'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadPrashnaChart();
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrashnaChart() async {
    final now = DateTime.now();
    final result = await AstroCalculator.calculate(
      year: now.year, month: now.month, day: now.day,
      hourUtcOffset: LocationService.tzOffset,
      hour24: now.hour + now.minute / 60.0,
      lat: LocationService.lat, lon: LocationService.lon,
      ayanamsaMode: 'lahiri', trueNode: true,
    );
    if (result != null && mounted) {
      setState(() {
        _panchang = result.panchang;
        _prashnaResult = result;
      });
    }
  }

  void _calculate() {
    final text = _numberCtrl.text.trim();
    final num = int.tryParse(text);

    if (num == null || num < 100 || num > 999) {
      setState(() { _errorMsg = '100 ರಿಂದ 999 ರ ನಡುವೆ ಮೂರಂಕಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ'; _hasResult = false; });
      return;
    }

    _d1 = num ~/ 100;
    _d2 = (num ~/ 10) % 10;
    _d3 = num % 10;
    _digitSum = _d1 + _d2 + _d3;
    _asmNumber = num;

    // ═══ Sankhya Ganita ═══
    _numPaksha = (num - 1) % 2;          // 0=Shukla, 1=Krishna
    _numTithi = (num - 1) % 15;          // 0-14
    _numNak = (num - 1) % 27;            // 0-26
    _numVara = (num - 1) % 7;            // 0-6
    _numRashi = (num - 1) % 12;          // 0-11
    _numGraha = (num - 1) % 9;           // 0-8
    _numBhuta = (num - 1) % 5;           // 0-4

    setState(() { _hasResult = true; _errorMsg = ''; });
  }

  // ─── Quality of Time checks ───
  List<Map<String, dynamic>> _getQualityChecks() {
    if (_panchang == null) return [];
    final checks = <Map<String, dynamic>>[];

    // Nakshatra Gandantha check (junction of water & fire signs)
    final nakIdx = _panchang!.nakshatraIndex;
    final gandanthaNak = [8, 9, 17, 18, 26, 0]; // Ashlesha-Magha, Jyeshtha-Moola, Revati-Ashwini
    checks.add({
      'name': 'ನಕ್ಷತ್ರ ಗಂಡಾಂತ',
      'nameEn': 'Nakshatra Gandantha',
      'result': gandanthaNak.contains(nakIdx),
      'good': false,
    });

    // Tithi Sandhi (junction tithis)
    final tithiIdx = _panchang!.tithiIndex;
    checks.add({
      'name': 'ತಿಥಿ ಸಂಧಿ',
      'nameEn': 'Tithi Sandhi',
      'result': tithiIdx == 14 || tithiIdx == 29, // Purnima/Amavasya
      'good': false,
    });

    // Rikta Tithi (4th, 9th, 14th)
    final tithiNum = (tithiIdx % 15) + 1;
    checks.add({
      'name': 'ರಿಕ್ತ ತಿಥಿ',
      'nameEn': 'Rikta Tithi',
      'result': tithiNum == 4 || tithiNum == 9 || tithiNum == 14,
      'good': false,
    });

    // Ashtami Tithi
    checks.add({
      'name': 'ಅಷ್ಟಮಿ ತಿಥಿ',
      'nameEn': 'Ashtami Tithi',
      'result': tithiNum == 8,
      'good': false,
    });

    // Trayodashi Tithi (considered good for certain prashnas)
    checks.add({
      'name': 'ತ್ರಯೋದಶಿ ತಿಥಿ',
      'nameEn': 'Trayodashi Tithi',
      'result': tithiNum == 13,
      'good': true,
    });

    // Vishti Karana (Bhadra)
    final karana = _panchang!.karana.toLowerCase();
    checks.add({
      'name': 'ವಿಷ್ಟಿ ಕರಣ (ಭದ್ರ)',
      'nameEn': 'Vishti Karana',
      'result': karana.contains('ವಿಷ್ಟಿ') || karana.contains('ಭದ್ರ'),
      'good': false,
    });

    // Dagdha Yoga (certain Vara+Tithi combos are dagdha/burnt)
    // Sun=1+12, Mon=11+6, Tue=5+3, Wed=3+8, Thu=10+9, Fri=7+4, Sat=8+2
    final dagdhaMap = {0: [1,12], 1: [6,11], 2: [3,5], 3: [3,8], 4: [9,10], 5: [4,7], 6: [2,8]};
    final varaIdx = DateTime.now().weekday % 7; // Sun=0
    final dagdha = dagdhaMap[varaIdx] ?? [];
    checks.add({
      'name': 'ದಗ್ಧ ಯೋಗ',
      'nameEn': 'Dagdha Yoga',
      'result': dagdha.contains(tithiNum),
      'good': false,
    });

    // Visha Ghati
    final vishaStr = _panchang!.vishaPraghati;
    checks.add({
      'name': 'ವಿಷ ಘಟಿ',
      'nameEn': 'Visha Ghati',
      'result': vishaStr.isNotEmpty && vishaStr != '-' && vishaStr != '0',
      'good': false,
    });

    // Amruta Ghati
    final amrutaStr = _panchang!.amrutaPraghati;
    checks.add({
      'name': 'ಅಮೃತ ಘಟಿ',
      'nameEn': 'Amruta Ghati',
      'result': amrutaStr.isNotEmpty && amrutaStr != '-' && amrutaStr != '0',
      'good': true,
    });

    return checks;
  }

  // ─── Compute special sputas from prashna chart ───
  List<Map<String, String>> _getSpecialSputas() {
    if (_prashnaResult == null) return [];
    final planets = _prashnaResult!.planets;
    final sputas = <Map<String, String>>[];

    final sunLon = planets['ಸೂರ್ಯ']?.longitude ?? 0;
    final moonLon = planets['ಚಂದ್ರ']?.longitude ?? 0;
    final marsLon = planets['ಮಂಗಳ']?.longitude ?? 0;
    final jupLon = planets['ಗುರು']?.longitude ?? 0;
    final satLon = planets['ಶನಿ']?.longitude ?? 0;
    final rahuLon = planets['ರಾಹು']?.longitude ?? 0;
    final lagnaLon = _prashnaResult!.bhavas.isNotEmpty ? _prashnaResult!.bhavas[0] : 0.0;

    // Trisputa = Sun + Moon + Jupiter (mod 360)
    final trisputa = (sunLon + moonLon + jupLon) % 360;
    sputas.add({'name': 'ತ್ರಿಸ್ಫುಟ / Trisputa', 'value': formatDeg(trisputa), 'rashi': _rashiNames[(trisputa ~/ 30) % 12]});

    // Chatusputa = Sun + Moon + Jupiter + Rahu (mod 360) — some traditions add Lagna
    final chatusputa = (sunLon + moonLon + jupLon + rahuLon) % 360;
    sputas.add({'name': 'ಚತುಸ್ಫುಟ / Chatusputa', 'value': formatDeg(chatusputa), 'rashi': _rashiNames[(chatusputa ~/ 30) % 12]});

    // Panchasputa = Sun + Moon + Mars + Jupiter + Saturn (mod 360)
    final panchasputa = (sunLon + moonLon + marsLon + jupLon + satLon) % 360;
    sputas.add({'name': 'ಪಂಚಸ್ಫುಟ / Panchasputa', 'value': formatDeg(panchasputa), 'rashi': _rashiNames[(panchasputa ~/ 30) % 12]});

    // Prana Sputa = Trisputa × 5 (mod 360)
    final prana = (trisputa * 5) % 360;
    sputas.add({'name': 'ಪ್ರಾಣ ಸ್ಫುಟ / Prana Sputa', 'value': formatDeg(prana), 'rashi': _rashiNames[(prana ~/ 30) % 12]});

    // Deha Sputa = Trisputa × 8 (mod 360)
    final deha = (trisputa * 8) % 360;
    sputas.add({'name': 'ದೇಹ ಸ್ಫುಟ / Deha Sputa', 'value': formatDeg(deha), 'rashi': _rashiNames[(deha ~/ 30) % 12]});

    // Mrityu Sputa = Trisputa × 7 (mod 360)
    final mrityu = (trisputa * 7) % 360;
    sputas.add({'name': 'ಮೃತ್ಯು ಸ್ಫುಟ / Mrityu Sputa', 'value': formatDeg(mrityu), 'rashi': _rashiNames[(mrityu ~/ 30) % 12]});

    // Sukshma Trisputa = Chatusputa + Lagna (mod 360)
    final sukshma = (chatusputa + lagnaLon) % 360;
    sputas.add({'name': 'ಸೂಕ್ಷ್ಮ ತ್ರಿಸ್ಫುಟ / Sukshma Trisputa', 'value': formatDeg(sukshma), 'rashi': _rashiNames[(sukshma ~/ 30) % 12]});

    // Arooda Sputa = Lagna lord position + Lagna (mod 360)
    final lagnaRashi = (lagnaLon ~/ 30) % 12;
    final lagnaLord = _getRashiLord(lagnaRashi.toInt());
    final lordLon = planets[lagnaLord]?.longitude ?? 0;
    final arooda = (lordLon + lagnaLon) % 360;
    sputas.add({'name': 'ಆರೂಢ ಸ್ಫುಟ / Arooda Sputa', 'value': formatDeg(arooda), 'rashi': _rashiNames[(arooda ~/ 30) % 12]});

    // Sannidhya Sputa = Moon + Rahu (mod 360)
    final sannidhya = (moonLon + rahuLon) % 360;
    sputas.add({'name': 'ಸಾನ್ನಿಧ್ಯ ಸ್ಫುಟ / Sannidhya', 'value': formatDeg(sannidhya), 'rashi': _rashiNames[(sannidhya ~/ 30) % 12]});

    // Chaitanya Sputa = Sun + Moon + Lagna (mod 360)
    final chaitanya = (sunLon + moonLon + lagnaLon) % 360;
    sputas.add({'name': 'ಚೈತನ್ಯ ಸ್ಫುಟ / Chaitanya', 'value': formatDeg(chaitanya), 'rashi': _rashiNames[(chaitanya ~/ 30) % 12]});

    return sputas;
  }

  String _getRashiLord(int rashiIdx) {
    const lords = ['ಮಂಗಳ', 'ಶುಕ್ರ', 'ಬುಧ', 'ಚಂದ್ರ', 'ಸೂರ್ಯ', 'ಬುಧ',
                   'ಶುಕ್ರ', 'ಮಂಗಳ', 'ಗುರು', 'ಶನಿ', 'ಶನಿ', 'ಗುರು'];
    return lords[rashiIdx % 12];
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
            // ═══ Input Card ═══
            _buildInputCard(),

            // ═══ Results ═══
            if (_hasResult) ...[
              // Tabs
              AppCard(
                padding: EdgeInsets.zero,
                child: TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  labelColor: kPurple2,
                  unselectedLabelColor: kMuted,
                  indicatorColor: kPurple2,
                  labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  tabs: const [
                    Tab(text: 'ಸಂಖ್ಯಾ ಗಣಿತ'),
                    Tab(text: 'ಕಾಲ ಗುಣ'),
                    Tab(text: 'ಸ್ಫುಟಗಳು'),
                    Tab(text: 'ಮಂಗಲ ದ್ರವ್ಯ'),
                  ],
                ),
              ),
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildSankhyaTab(),
                    _buildQualityTab(),
                    _buildSputaTab(),
                    _buildDravyaTab(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        )),
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🪔', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Text('ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kOrange))),
        ]),
        const SizedBox(height: 8),
        Text('ಪ್ರಶ್ನೆ ಕೇಳುವವರು 100 ರಿಂದ 999 ರ ನಡುವಿನ ಮೂರಂಕಿ ಸಂಖ್ಯೆ ಹೇಳಬೇಕು.',
          style: TextStyle(color: kMuted, fontSize: 12)),
        const SizedBox(height: 12),
        // Name
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'ಪ್ರುಚ್ಛಕ ಹೆಸರು / Querent Name',
            prefixIcon: Icon(Icons.person, color: kMuted, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
          ),
          style: TextStyle(color: kText, fontSize: 14),
        ),
        const SizedBox(height: 10),
        // 3 digit number
        TextField(
          controller: _numberCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'ಮೂರಂಕಿ ಸಂಖ್ಯೆ (100-999)',
            prefixIcon: Icon(Icons.pin, color: kMuted, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
          ),
          style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 8),
          textAlign: TextAlign.center,
          onSubmitted: (_) => _calculate(),
        ),
        const SizedBox(height: 10),
        // Birth Rashi selector
        Row(children: [
          Expanded(child: DropdownButtonFormField<int>(
            value: _selectedRashi,
            decoration: InputDecoration(
              labelText: 'ಜನ್ಮ ರಾಶಿ / Birth Rashi',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
            ),
            items: List.generate(12, (i) => DropdownMenuItem(value: i, child: Text('${_rashiNames[i]} (${_rashiEngNames[i]})', style: TextStyle(fontSize: 13)))),
            onChanged: (v) => setState(() => _selectedRashi = v ?? 0),
          )),
        ]),
        const SizedBox(height: 10),
        // Janma Nakshatra selector
        DropdownButtonFormField<int>(
          value: _selectedNakshatra,
          decoration: InputDecoration(
            labelText: 'ಜನ್ಮ ನಕ್ಷತ್ರ / Querent Nakshatra',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
          ),
          items: List.generate(27, (i) => DropdownMenuItem(value: i, child: Text('${i+1}. ${_nakshatraNames[i]}', style: TextStyle(fontSize: 13)))),
          onChanged: (v) => setState(() => _selectedNakshatra = v ?? 0),
        ),
        if (_errorMsg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_errorMsg, style: TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _calculate,
          icon: Icon(Icons.calculate, size: 20),
          label: Text('ಲೆಕ್ಕ ಹಾಕಿ / Calculate', style: TextStyle(fontWeight: FontWeight.w800)),
          style: ElevatedButton.styleFrom(
            backgroundColor: kOrange, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ]),
    );
  }

  // ═══ Tab 1: Sankhya Ganita ═══
  Widget _buildSankhyaTab() {
    return SingleChildScrollView(child: Column(children: [
      // Digit breakdown
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics, color: kOrange, size: 20),
          const SizedBox(width: 8),
          Text('ಸಂಖ್ಯಾ ಗಣಿತ / Prashna Sankhya Ganita', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kOrange)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _digitBox('ನೂರ', _d1),
          _digitBox('ಹತ್ತು', _d2),
          _digitBox('ಒಂದು', _d3),
          Container(width: 1, height: 40, color: kBorder),
          _digitBox('ಮೊತ್ತ', _digitSum),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (_digitSum == 4 || _digitSum == 12 || _digitSum == 20) ? Colors.green.withOpacity(0.1) : kOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Icon((_digitSum == 4 || _digitSum == 12 || _digitSum == 20) ? Icons.check_circle : Icons.info_outline,
              color: (_digitSum == 4 || _digitSum == 12 || _digitSum == 20) ? Colors.green : kOrange, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              (_digitSum == 4 || _digitSum == 12 || _digitSum == 20)
                ? 'ಅಂಕೆಗಳ ಮೊತ್ತ = $_digitSum ✓ (ಪ್ರಶ್ನೆ ಯೋಗ್ಯ)'
                : 'ಅಂಕೆಗಳ ಮೊತ್ತ = $_digitSum (ಸಾಂಪ್ರದಾಯಿಕ: 4, 12 ಅಥವಾ 20)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kText))),
          ]),
        ),
      ])),

      // Derived values table
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        _ganRow('ಪಕ್ಷ / Paksha', _pakshaNames[_numPaksha], '(${_asmNumber} - 1) % 2 = ${_numPaksha}'),
        _ganRow('ತಿಥಿ / Tithi', _tithiNames[_numTithi], '(${_asmNumber} - 1) % 15 = ${_numTithi}'),
        _ganRow('ನಕ್ಷತ್ರ / Nakshatra', _nakshatraNames[_numNak], '(${_asmNumber} - 1) % 27 = ${_numNak}'),
        _ganRow('ವಾರ / Vara', _varaNames[_numVara], '(${_asmNumber} - 1) % 7 = ${_numVara}'),
        _ganRow('ರಾಶಿ / Rashi', _rashiNames[_numRashi], '(${_asmNumber} - 1) % 12 = ${_numRashi}'),
        _ganRow('ಗ್ರಹ / Graha', _grahaNames[_numGraha], '(${_asmNumber} - 1) % 9 = ${_numGraha}'),
        _ganRow('ಪಂಚ ಭೂತ / Bhuta', _bhutaNames[_numBhuta], '(${_asmNumber} - 1) % 5 = ${_numBhuta}'),
      ])),

      // Prashna time context
      if (_panchang != null) AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಪ್ರಶ್ನೆ ಸಮಯದ ಪಂಚಾಂಗ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kPurple2)),
        const SizedBox(height: 6),
        _kvRow('ವಾರ', _panchang!.vara),
        _kvRow('ತಿಥಿ', _panchang!.tithi),
        _kvRow('ನಕ್ಷತ್ರ', _panchang!.nakshatra),
        _kvRow('ಯೋಗ', _panchang!.yoga),
        _kvRow('ಕರಣ', _panchang!.karana),
      ])),
    ]));
  }

  // ═══ Tab 2: Quality of Time ═══
  Widget _buildQualityTab() {
    final checks = _getQualityChecks();
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.access_time_filled, color: kPurple1, size: 20),
          const SizedBox(width: 8),
          Text('ಪ್ರಶ್ನೆ ಕಾಲ ಗುಣ / Quality of Prashna Time', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kPurple1)),
        ]),
        const SizedBox(height: 12),
        ...checks.map((c) {
          final active = c['result'] as bool;
          final good = c['good'] as bool;
          final color = !active ? Colors.grey : (good ? Colors.green : Colors.red);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.06) : kBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? color.withOpacity(0.3) : kBorder),
            ),
            child: Row(children: [
              Icon(active ? (good ? Icons.check_circle : Icons.warning_amber_rounded) : Icons.circle_outlined,
                color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText)),
                Text(c['nameEn'], style: TextStyle(fontSize: 10, color: kMuted)),
              ])),
              Text(active ? (good ? 'ಶುಭ' : 'ಅಶುಭ') : '—',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: color)),
            ]),
          );
        }),
      ])),
    ]));
  }

  // ═══ Tab 3: Special Sputas ═══
  Widget _buildSputaTab() {
    final sputas = _getSpecialSputas();
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, color: kTeal, size: 20),
          const SizedBox(width: 8),
          Text('ವಿಶೇಷ ಸ್ಫುಟಗಳು / Special Sputas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kTeal)),
        ]),
        const SizedBox(height: 6),
        Text('ಪ್ರಶ್ನೆ ಸಮಯದ ಗ್ರಹ ಸ್ಥಾನಗಳಿಂದ ಲೆಕ್ಕಹಾಕಿದ ಸ್ಫುಟಗಳು', style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 12),
        ...sputas.map((s) => Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: kTeal.withOpacity(0.04), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kTeal.withOpacity(0.15)),
          ),
          child: Row(children: [
            Expanded(flex: 3, child: Text(s['name']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText))),
            Expanded(flex: 2, child: Text(s['value']!, style: TextStyle(fontSize: 12, color: kMuted))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(s['rashi']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kPurple2)),
            ),
          ]),
        )),
      ])),
    ]));
  }

  // ═══ Tab 4: Mangala Dravya ═══
  Widget _buildDravyaTab() {
    final idx = (_asmNumber - 1) % 8;
    return SingleChildScrollView(child: Column(children: [
      // Primary indicated dravya
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🪔', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('ಸೂಚಿತ ಮಂಗಲ ದ್ರವ್ಯ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kOrange)),
        ]),
        const SizedBox(height: 12),
        () {
          final item = _ashtaItems[idx];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kOrange.withOpacity(0.08), kPurple2.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kOrange.withOpacity(0.2)),
            ),
            child: Row(children: [
              Text(item['icon']!, style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
                const SizedBox(height: 4),
                Text('ಅಧಿದೇವತೆ: ${item['deity']}', style: TextStyle(fontSize: 13, color: kPurple2)),
              ])),
            ]),
          );
        }(),
      ])),

      // All 8 dravyas
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಅಷ್ಟ ಮಂಗಲ ದ್ರವ್ಯಗಳು', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kPurple2)),
        const SizedBox(height: 10),
        ...List.generate(8, (i) {
          final item = _ashtaItems[i];
          final isSelected = i == idx;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? kOrange.withOpacity(0.08) : kBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? kOrange.withOpacity(0.3) : kBorder),
            ),
            child: Row(children: [
              Text('${i + 1}.', style: TextStyle(fontWeight: FontWeight.w900, color: kMuted, fontSize: 12)),
              const SizedBox(width: 8),
              Text(item['icon']!, style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(child: Text(item['name']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kText))),
              Text(item['deity']!, style: TextStyle(fontSize: 12, color: kMuted)),
              if (isSelected) ...[const SizedBox(width: 6), Icon(Icons.arrow_back, color: kOrange, size: 14)],
            ]),
          );
        }),
      ])),
    ]));
  }

  Widget _digitBox(String label, int value) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: kMuted)),
      const SizedBox(height: 4),
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: kPurple2.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kPurple2.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kPurple2)),
      ),
    ]);
  }

  Widget _ganRow(String label, String value, String formula) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText))),
        Expanded(flex: 2, child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPurple2))),
        Expanded(flex: 2, child: Text(formula, style: TextStyle(fontSize: 9, color: kMuted))),
      ]),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(flex: 2, child: Text(k, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText))),
        Expanded(flex: 3, child: Text(v, style: TextStyle(fontSize: 12, color: kText))),
      ]),
    );
  }
}
