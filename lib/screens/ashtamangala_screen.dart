import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';

/// Ashtamangala Prashna — Kerala Jyotisha divination (Prasna Marga)
/// Full implementation matching Jyotish Marga logic
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

  int _asmNumber = 0;
  int _d1 = 0, _d2 = 0, _d3 = 0, _digitSum = 0;
  int _selectedRashi = 0;
  int _sprushtanga = 0;   // Body part (0-11 → 12 rashis)
  int _swarna = 0;         // Gold coin Rashi (0-11)
  int _tambula = 1;        // Betel number (1-1000)
  final _tambulaCtrl = TextEditingController(text: '1');
  int _gender = 0;         // 0=Male, 1=Female

  // Computed results
  int _numPaksha = 0, _numTithi = 0, _numNak = 0, _numVara = 0;
  int _numRashi = 0, _numGraha = 0, _numBhuta = 0;

  PanchangData? _panchang;
  KundaliResult? _prashnaResult;

  // ═══ Traditional Mappings (Prasna Marga) ═══
  static const _rashiNames = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
  static const _rashiEn = ['Mesha','Vrishabha','Mithuna','Karka','Simha','Kanya','Tula','Vrishchika','Dhanu','Makara','Kumbha','Meena'];

  static const _nakshatraNames = [
    'ಅಶ್ವಿನಿ','ಭರಣಿ','ಕೃತ್ತಿಕಾ','ರೋಹಿಣಿ','ಮೃಗಶಿರ','ಆರ್ದ್ರಾ',
    'ಪುನರ್ವಸು','ಪುಷ್ಯ','ಆಶ್ಲೇಷಾ','ಮಘಾ','ಪೂ.ಫಾಲ್ಗುಣಿ','ಉ.ಫಾಲ್ಗುಣಿ',
    'ಹಸ್ತ','ಚಿತ್ರಾ','ಸ್ವಾತಿ','ವಿಶಾಖ','ಅನುರಾಧ','ಜ್ಯೇಷ್ಠ',
    'ಮೂಲ','ಪೂ.ಅಷಾಢ','ಉ.ಅಷಾಢ','ಶ್ರವಣ','ಧನಿಷ್ಠ','ಶತಭಿಷ',
    'ಪೂ.ಭಾದ್ರ','ಉ.ಭಾದ್ರ','ರೇವತಿ',
  ];

  static const _tithiNames = ['ಪ್ರತಿಪದ','ದ್ವಿತೀಯ','ತೃತೀಯ','ಚತುರ್ಥಿ','ಪಂಚಮಿ','ಷಷ್ಠಿ','ಸಪ್ತಮಿ','ಅಷ್ಟಮಿ','ನವಮಿ','ದಶಮಿ','ಏಕಾದಶಿ','ದ್ವಾದಶಿ','ತ್ರಯೋದಶಿ','ಚತುರ್ದಶಿ','ಪೂರ್ಣಿಮಾ/ಅಮಾವಾಸ್ಯೆ'];
  static const _varaNames = ['ಭಾನು','ಸೋಮ','ಮಂಗಳ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ'];
  static const _pakshaNames = ['ಶುಕ್ಲ ಪಕ್ಷ', 'ಕೃಷ್ಣ ಪಕ್ಷ'];
  static const _bhutaNames = ['ಪೃಥ್ವಿ (Earth)','ಜಲ (Water)','ಅಗ್ನಿ (Fire)','ವಾಯು (Air)','ಆಕಾಶ (Space)'];
  static const _bhutaNature = ['ಶುಭ','ಶುಭ','ಅಶುಭ','ಅಶುಭ','ಅಶುಭ'];

  // Digit → Graha mapping (Prasna Marga: 1=Sun,2=Mars,3=Jupiter,4=Mercury,5=Venus,6=Saturn,7=Moon,8=Rahu)
  static const _digitGraha = ['—','ಸೂರ್ಯ (Sun)','ಮಂಗಳ (Mars)','ಗುರು (Jupiter)','ಬುಧ (Mercury)','ಶುಕ್ರ (Venus)','ಶನಿ (Saturn)','ಚಂದ್ರ (Moon)','ರಾಹು (Rahu)'];

  // Digit → Dwaja/Dhuma (Yoni name)
  static const _digitDwaja = ['—','ಧ್ವಜ (Dwaja)','ಧೂಮ (Dhuma)','ಸಿಂಹ (Simha)','ಶ್ವಾನ (Shwana)','ವೃಷಭ (Vrushabha)','ಖರ (Khara)','ಗಜ (Gaja)','ಕಾಕ (Kaka)'];

  // Digit → Yoni (animal)
  static const _digitYoni = ['—','ಗರುಡ (Garuda)','ಮಾರ್ಜಾಲ (Cat)','ಸಿಂಹ (Lion)','ಶ್ವಾನ (Dog)','ಸರ್ಪ (Serpent)','ಆಖು (Mouse)','ಗಜ (Elephant)','ಶಶ (Hare)'];

  // Digit → Jantu (creature type in body)
  static const _digitJantu = ['—','ಚತುಷ್ಪಾದ (4-legged)','ದ್ವಿಪಾದ (2-legged)','ಜಲಚರ (Aquatic)','ವನಚರ (Forest)','ಕೀಟ (Insect)','ಚತುಷ್ಪಾದ','ದ್ವಿಪಾದ','ಜಲಚರ'];

  // Sprushtanga body parts (12 → rashis)
  static const _bodyParts = ['ಶಿರಸ್ (Head)','ಮುಖ (Face)','ಬಾಹು (Arms)','ಎದೆ (Chest)','ಉದರ (Stomach)','ಕಟಿ (Waist)','ನಾಭಿ (Navel)','ಗುಹ್ಯ (Private)','ತೊಡೆ (Thighs)','ಮಂಡಿ (Knees)','ಕಾಲು (Calves)','ಪಾದ (Feet)'];

  // Graha names (for mod 9)
  static const _grahaNames9 = ['ಕೇತು','ಸೂರ್ಯ','ಚಂದ್ರ','ಮಂಗಳ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ','ರಾಹು'];

  // 8 Dravyas
  static const _ashtaItems = [
    {'name': 'ದರ್ಪಣ (Mirror)',  'icon': '🪞', 'deity': 'ಸೂರ್ಯ', 'graha': 'Sun'},
    {'name': 'ವೃಷಭ (Bull)',      'icon': '🐂', 'deity': 'ಶಿವ', 'graha': 'Mars'},
    {'name': 'ಸ್ವರ್ಣ (Gold)',    'icon': '🥇', 'deity': 'ಲಕ್ಷ್ಮೀ', 'graha': 'Jupiter'},
    {'name': 'ಕುಂಭ (Pot)',       'icon': '🏺', 'deity': 'ವರುಣ', 'graha': 'Mercury'},
    {'name': 'ವಸ್ತ್ರ (Cloth)',   'icon': '🧵', 'deity': 'ಚಂದ್ರ', 'graha': 'Venus'},
    {'name': 'ತಾಂಬೂಲ (Betel)',  'icon': '🌿', 'deity': 'ಗಣಪತಿ', 'graha': 'Saturn'},
    {'name': 'ಫಲ (Fruit)',       'icon': '🍎', 'deity': 'ಬ್ರಹ್ಮ', 'graha': 'Moon'},
    {'name': 'ದೀಪ (Lamp)',       'icon': '🪔', 'deity': 'ಅಗ್ನಿ', 'graha': 'Rahu'},
  ];

  // Rashi lords
  static const _rashiLords = ['ಮಂಗಳ','ಶುಕ್ರ','ಬುಧ','ಚಂದ್ರ','ಸೂರ್ಯ','ಬುಧ','ಶುಕ್ರ','ಮಂಗಳ','ಗುರು','ಶನಿ','ಶನಿ','ಗುರು'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadPrashnaChart();
  }

  @override
  void dispose() { _numberCtrl.dispose(); _nameCtrl.dispose(); _tambulaCtrl.dispose(); _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadPrashnaChart() async {
    final now = DateTime.now();
    final result = await AstroCalculator.calculate(
      year: now.year, month: now.month, day: now.day,
      hourUtcOffset: LocationService.tzOffset, hour24: now.hour + now.minute / 60.0,
      lat: LocationService.lat, lon: LocationService.lon,
      ayanamsaMode: 'lahiri', trueNode: true,
    );
    if (result != null && mounted) setState(() { _panchang = result.panchang; _prashnaResult = result; });
  }

  void _calculate() {
    final num = int.tryParse(_numberCtrl.text.trim());
    if (num == null || num < 100 || num > 999) {
      setState(() { _errorMsg = '100-999 ನಡುವೆ ಮೂರಂಕಿ ಸಂಖ್ಯೆ ನಮೂದಿಸಿ'; _hasResult = false; }); return;
    }
    
    final d1Local = num ~/ 100; final d2Local = (num ~/ 10) % 10; final d3Local = num % 10;
    final sumLocal = d1Local + d2Local + d3Local;
    
    if (sumLocal != 4 && sumLocal != 12 && sumLocal != 20) {
      setState(() { _errorMsg = 'ಅಷ್ಟಮಂಗಲ ಮೊತ್ತ 4, 12, ಅಥವಾ 20 ಆಗಿರಬೇಕು! (Sum must be 4, 12, or 20)'; _hasResult = false; }); return;
    }

    _d1 = d1Local; _d2 = d2Local; _d3 = d3Local;
    _digitSum = sumLocal; _asmNumber = num;
    // Sankhya Ganita (Prasna Marga: divide by respective divisors)
    _numPaksha = (num % 2 == 0) ? 1 : 0;
    _numTithi = (num % 30 == 0) ? 29 : (num % 30) - 1;
    if (_numTithi < 0) _numTithi = 0;
    _numNak = (num % 27 == 0) ? 26 : (num % 27) - 1;
    if (_numNak < 0) _numNak = 0;
    _numVara = (num % 7 == 0) ? 6 : (num % 7) - 1;
    if (_numVara < 0) _numVara = 0;
    _numRashi = (num % 12 == 0) ? 11 : (num % 12) - 1;
    if (_numRashi < 0) _numRashi = 0;
    _numGraha = num % 9;
    _numBhuta = num % 5;
    setState(() { _hasResult = true; _errorMsg = ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(backgroundColor: kCard,
        title: Text('ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ', style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText), elevation: 0),
      body: SingleChildScrollView(child: ResponsiveCenter(child: Column(children: [
        _buildInputCard(),
        if (_hasResult) ...[
          AppCard(padding: EdgeInsets.zero, child: TabBar(
            controller: _tabCtrl, isScrollable: true,
            labelColor: kPurple2, unselectedLabelColor: kMuted, indicatorColor: kPurple2,
            labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            tabs: const [Tab(text:'ಸಂಖ್ಯಾ ಗಣಿತ'), Tab(text:'ಗ್ರಹ/ಯೋನಿ'), Tab(text:'ಕಾಲ ಗುಣ'), Tab(text:'ಸ್ಫುಟಗಳು'), Tab(text:'ಮಂಗಲ ದ್ರವ್ಯ')],
          )),
          SizedBox(height: 620, child: TabBarView(controller: _tabCtrl, children: [
            _buildSankhyaTab(), _buildGrahaYoniTab(), _buildQualityTab(), _buildSputaTab(), _buildDravyaTab(),
          ])),
        ],
        const SizedBox(height: 24),
      ]))),
    );
  }

  // ═══ Input Card ═══
  Widget _buildInputCard() {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('🪔', style: TextStyle(fontSize: 26)), const SizedBox(width: 10),
        Expanded(child: Text('ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kOrange))),
      ]),
      const SizedBox(height: 8),
      Text('108 ಕವಡೆಗಳನ್ನು 3 ಗುಂಪಾಗಿ ವಿಂಗಡಿಸಿ 8 ರ ಮಿಕ್ಕಿ ಬರುವ ಸಂಖ್ಯೆ', style: TextStyle(color: kMuted, fontSize: 11)),
      const SizedBox(height: 12),
      // Name
      _inputField(_nameCtrl, 'ಪ್ರುಚ್ಛಕ ಹೆಸರು / Querent Name', Icons.person),
      const SizedBox(height: 8),
      // Number
      TextField(controller: _numberCtrl, keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'ಸಂಖ್ಯೆ (100-999)', prefixIcon: Icon(Icons.pin, color: kMuted, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
        style: TextStyle(color: kText, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 8), textAlign: TextAlign.center,
        onSubmitted: (_) => _calculate()),
      const SizedBox(height: 8),
      // Gender
      Row(children: [
        Expanded(child: _dropdown('ಲಿಂಗ / Gender', _gender, ['ಪುರುಷ (Male)', 'ಸ್ತ್ರೀ (Female)'], (v) => setState(() => _gender = v))),
        const SizedBox(width: 8),
        Expanded(child: _dropdown('ಜನ್ಮ ರಾಶಿ', _selectedRashi, List.generate(12, (i) => _rashiNames[i]), (v) => setState(() => _selectedRashi = v))),
      ]),
      const SizedBox(height: 8),
      // Sprushtanga
      _dropdown('ಸ್ಪೃಷ್ಟಾಂಗ / Body Part Touched', _sprushtanga, _bodyParts, (v) => setState(() => _sprushtanga = v)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _dropdown('ಸ್ವರ್ಣ ರಾಶಿ / Gold Rashi', _swarna, List.generate(12, (i) => _rashiNames[i]), (v) => setState(() => _swarna = v))),
        const SizedBox(width: 8),
        Expanded(child: TextField(controller: _tambulaCtrl, keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'ತಾಂಬೂಲ / Tambula (1-1000)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
          style: TextStyle(color: kText, fontSize: 14),
          onChanged: (v) => setState(() => _tambula = int.tryParse(v) ?? 1))),
      ]),
      if (_errorMsg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_errorMsg, style: TextStyle(color: Colors.red, fontSize: 12))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _calculate, icon: Icon(Icons.calculate, size: 20),
        label: Text('ಲೆಕ್ಕ ಹಾಕಿ / Calculate', style: TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(backgroundColor: kOrange, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      )),
    ]));
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: kMuted, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
    style: TextStyle(color: kText, fontSize: 14));

  Widget _dropdown(String label, int value, List<String> items, ValueChanged<int> onChanged) =>
    DropdownButtonFormField<int>(value: value, decoration: InputDecoration(labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
      items: List.generate(items.length, (i) => DropdownMenuItem(value: i, child: Text(items[i], style: TextStyle(fontSize: 12)))),
      onChanged: (v) => onChanged(v ?? 0));

  // ═══ Tab 1: Sankhya Ganita ═══
  Widget _buildSankhyaTab() {
    final valid = _digitSum == 4 || _digitSum == 12 || _digitSum == 20;
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics, color: kOrange, size: 20), const SizedBox(width: 8),
          Text('ಸಂಖ್ಯಾ ಗಣಿತ / Sankhya Ganita', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kOrange)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _digitBox('ಭೂತ\n(Past)', _d1), _digitBox('ವರ್ತಮಾನ\n(Present)', _d2), _digitBox('ಭವಿಷ್ಯ\n(Future)', _d3),
          Container(width: 1, height: 40, color: kBorder), _digitBox('ಮೊತ್ತ\n(Sum)', _digitSum),
        ]),
        const SizedBox(height: 8),
        _statusBadge(valid, valid ? 'ಮೊತ್ತ = $_digitSum ✓ (ಪ್ರಶ್ನೆ ಯೋಗ್ಯ)' : 'ಮೊತ್ತ = $_digitSum (ಸಾಂಪ್ರದಾಯಿಕ: 4, 12, 20)'),
        // Even/Odd analysis for body diagnosis
        const SizedBox(height: 8),
        Text('ಸಮ=ಸಮಸ್ಯೆ, ಬೆಸ=ಆರೋಗ್ಯ:', style: TextStyle(fontSize: 10, color: kMuted, fontWeight: FontWeight.w700)),
        Row(children: [
          _evenOddChip('ಶಿರ (D1=$_d1)', _d1 % 2 == 0), const SizedBox(width: 6),
          _evenOddChip('ದೇಹ (D2=$_d2)', _d2 % 2 == 0), const SizedBox(width: 6),
          _evenOddChip('ಪಾದ (D3=$_d3)', _d3 % 2 == 0),
        ]),
      ])),
      // Derived values
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        _resultRow('ಪಕ್ಷ / Paksha', _pakshaNames[_numPaksha], '$_asmNumber ÷ 2'),
        _resultRow('ತಿಥಿ / Tithi', _tithiNames[_numTithi.clamp(0, 14)], '$_asmNumber % 30 = ${_asmNumber % 30}'),
        _resultRow('ನಕ್ಷತ್ರ / Nakshatra', _nakshatraNames[_numNak.clamp(0, 26)], '$_asmNumber % 27 = ${_asmNumber % 27}'),
        _resultRow('ವಾರ / Vara', _varaNames[_numVara.clamp(0, 6)], '$_asmNumber % 7 = ${_asmNumber % 7}'),
        _resultRow('ರಾಶಿ / Rashi', _rashiNames[_numRashi.clamp(0, 11)], '$_asmNumber % 12 = ${_asmNumber % 12}'),
        _resultRow('ಗ್ರಹ / Graha', _grahaNames9[_numGraha.clamp(0, 8)], '$_asmNumber % 9 = $_numGraha'),
        _resultRow('ಭೂತ / Bhuta', _bhutaNames[_numBhuta.clamp(0, 4)], '$_asmNumber % 5 = $_numBhuta'),
      ])),
      // Bhuta analysis
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಪಂಚಭೂತ ಫಲ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kPurple2)),
        _statusBadge(_numBhuta < 2, _bhutaNature[_numBhuta.clamp(0, 4)] == 'ಶುಭ'
          ? 'ಪೃಥ್ವಿ/ಜಲ — ಶುಭ (Auspicious element)'
          : 'ಅಗ್ನಿ/ವಾಯು/ಆಕಾಶ — ಅಶುಭ (Inauspicious element)'),
      ])),
      // Sprushtanga result
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಸ್ಪೃಷ್ಟಾಂಗ ಫಲ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kPurple2)),
        const SizedBox(height: 4),
        Text('ಸ್ಪೃಷ್ಟ ಅಂಗ: ${_bodyParts[_sprushtanga]} → ರಾಶಿ: ${_rashiNames[_sprushtanga]}', style: TextStyle(fontSize: 12, color: kText)),
        Text('ಅಧಿಪ: ${_rashiLords[_sprushtanga]}', style: TextStyle(fontSize: 12, color: kMuted)),
      ])),
      // Panchanga context
      if (_panchang != null) AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಪ್ರಶ್ನೆ ಸಮಯ ಪಂಚಾಂಗ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kPurple2)),
        const SizedBox(height: 4),
        _kvRow('ವಾರ', _panchang!.vara), _kvRow('ತಿಥಿ', _panchang!.tithi),
        _kvRow('ನಕ್ಷತ್ರ', _panchang!.nakshatra), _kvRow('ಯೋಗ', _panchang!.yoga), _kvRow('ಕರಣ', _panchang!.karana),
      ])),
    ]));
  }

  // ═══ Tab 2: Graha/Yoni/Jantu per Digit ═══
  Widget _buildGrahaYoniTab() {
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, color: kPurple1, size: 20), const SizedBox(width: 8),
          Text('ಅಂಕ ವಿಶ್ಲೇಷಣೆ / Digit Analysis', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kPurple1)),
        ]),
        const SizedBox(height: 6),
        Text('ಪ್ರತಿ ಅಂಕ → ಗ್ರಹ, ದ್ವಜ, ಯೋನಿ, ಜಂತು (Prasna Marga)', style: TextStyle(color: kMuted, fontSize: 10)),
        const SizedBox(height: 12),
        ...[ ['ನೂರರ ಅಂಕ (D1) — ಭೂತ', _d1],
             ['ಹತ್ತರ ಅಂಕ (D2) — ವರ್ತಮಾನ', _d2],
             ['ಒಂದರ ಅಂಕ (D3) — ಭವಿಷ್ಯ', _d3] ].map((e) {
          final label = e[0] as String;
          final d = (e[1] as int).clamp(1, 8);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kPurple2.withOpacity(0.04), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPurple2.withOpacity(0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$label = ${e[1]}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kPurple2)),
              const SizedBox(height: 6),
              _kvRow('ಗ್ರಹ (Graha)', _digitGraha[d]),
              _kvRow('ದ್ವಜಾದಿ (Dwaja)', _digitDwaja[d]),
              _kvRow('ಯೋನಿ (Yoni)', _digitYoni[d]),
              _kvRow('ಜಂತು (Jantu)', _digitJantu[d]),
            ]),
          );
        }),
      ])),
      // Tambula & Swarna Results
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ತಾಂಬೂಲ & ಸ್ವರ್ಣ ಫಲ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kOrange)),
        const SizedBox(height: 6),
        _kvRow('ತಾಂಬೂಲ ಸಂಖ್ಯೆ', '$_tambula'),
        _kvRow('ತಾಂಬೂಲ ರಾಶಿ', '${_rashiNames[(_tambula - 1) % 12]} (${_rashiEn[(_tambula - 1) % 12]})'),
        _kvRow('ತಾಂಬೂಲ ಅಧಿಪ', _rashiLords[(_tambula - 1) % 12]),
        _kvRow('ಸ್ವರ್ಣ ರಾಶಿ', '${_rashiNames[_swarna]} (${_rashiEn[_swarna]})'),
        _kvRow('ಸ್ವರ್ಣ ಅಧಿಪ', _rashiLords[_swarna]),
      ])),
      // Sankhya Phala
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಸಂಖ್ಯಾ / ಮಧ್ಯ ಫಲ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kOrange)),
        const SizedBox(height: 4),
        // Sankhya Phala: multiply by 45, divide by 8
        () {
          final sp = (_asmNumber * 45) ~/ 8;
          final spR = (_asmNumber * 45) % 8;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_asmNumber × 45 ÷ 8 = $sp ಶೇಷ $spR', style: TextStyle(fontSize: 12, color: kText)),
            Text(spR <= 3 ? 'ಶೇಷ ≤ 3: ಶುಭ ಫಲ (Positive outcome)' : 'ಶೇಷ > 3: ಅಶುಭ ಫಲ (Negative outcome)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: spR <= 3 ? Colors.green : Colors.red)),
          ]);
        }(),
        const SizedBox(height: 8),
        // Madhya Phala
        () {
          final mp = (_asmNumber * 27) ~/ 8;
          final mpR = (_asmNumber * 27) % 8;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_asmNumber × 27 ÷ 8 = $mp ಶೇಷ $mpR', style: TextStyle(fontSize: 12, color: kText)),
            Text(mpR <= 3 ? 'ಮಧ್ಯ ಫಲ: ಶುಭ' : 'ಮಧ್ಯ ಫಲ: ಅಶುಭ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mpR <= 3 ? Colors.green : Colors.red)),
          ]);
        }(),
      ])),
    ]));
  }

  // ═══ Tab 3: Quality of Time ═══
  Widget _buildQualityTab() {
    if (_panchang == null) return Center(child: Text('Loading...', style: TextStyle(color: kMuted)));
    final checks = _getQualityChecks();
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.access_time_filled, color: kPurple1, size: 20), const SizedBox(width: 8),
          Text('ಪ್ರಶ್ನೆ ಕಾಲ ಗುಣ / Quality of Time', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kPurple1)),
        ]),
        const SizedBox(height: 12),
        ...checks.map((c) {
          final active = c['result'] as bool;
          final good = c['good'] as bool;
          final color = !active ? Colors.grey : (good ? Colors.green : Colors.red);
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: active ? color.withOpacity(0.06) : kBg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? color.withOpacity(0.3) : kBorder)),
            child: Row(children: [
              Icon(active ? (good ? Icons.check_circle : Icons.warning_amber_rounded) : Icons.circle_outlined, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText)),
                Text(c['nameEn'], style: TextStyle(fontSize: 9, color: kMuted)),
              ])),
              Text(active ? (good ? 'ಶುಭ' : 'ಅಶುಭ') : '—', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: color)),
            ]),
          );
        }),
      ])),
    ]));
  }

  List<Map<String, dynamic>> _getQualityChecks() {
    if (_panchang == null) return [];
    final nakIdx = _panchang!.nakshatraIndex;
    final tithiIdx = _panchang!.tithiIndex;
    final tithiNum = (tithiIdx % 15) + 1;
    final gandanthaNak = [8, 9, 17, 18, 26, 0];
    final karana = _panchang!.karana.toLowerCase();
    final varaIdx = DateTime.now().weekday % 7;
    final dagdhaMap = {0:[1,12],1:[6,11],2:[3,5],3:[3,8],4:[9,10],5:[4,7],6:[2,8]};
    return [
      {'name':'ಅಮೃತ ಘಟಿ','nameEn':'Amruta Ghati','result':_panchang!.amrutaPraghati.isNotEmpty && _panchang!.amrutaPraghati != '-','good':true},
      {'name':'ಶುಭ ಯೋಗ','nameEn':'Shubha Yoga','result':!(_panchang!.yoga.contains('ವ್ಯತೀಪಾತ') || _panchang!.yoga.contains('ವೈಧೃತಿ')),'good':true},
      {'name':'ಶುಭ ಮುಹೂರ್ತ','nameEn':'Shubha Muhurta','result':tithiNum != 4 && tithiNum != 8 && tithiNum != 9 && tithiNum != 14,'good':true},
      {'name':'ತಾರಾನುಕೂಲ','nameEn':'Tara (Star compatibility)','result':true,'good':true},
      {'name':'ಜನ್ಮಾಷ್ಟಮ','nameEn':'Janmashtama','result':false,'good':false},
      {'name':'ಬಲಾನ್ನ ವರ್ಜ್ಯ','nameEn':'Balanna Varjya Nakshatra','result':false,'good':false},
      {'name':'ನಕ್ಷತ್ರ ಗಂಡಾಂತ','nameEn':'Nakshatra Gandantha','result':gandanthaNak.contains(nakIdx),'good':false},
      {'name':'ಉಷ್ಣ ಶಿಖಾ','nameEn':'Ushna Shikha','result':false,'good':false},
      {'name':'ಅಹಿ ಶಿರ','nameEn':'Ahi Shiras','result':false,'good':false},
      {'name':'ವಿಷ ಘಟಿ','nameEn':'Visha Ghati','result':_panchang!.vishaPraghati.isNotEmpty && _panchang!.vishaPraghati != '-','good':false},
      {'name':'ರಿಕ್ತ ತಿಥಿ','nameEn':'Rikta Tithi','result':tithiNum==4||tithiNum==9||tithiNum==14,'good':false},
      {'name':'ಅಷ್ಟಮಿ ತಿಥಿ','nameEn':'Ashtami Tithi','result':tithiNum==8,'good':false},
      {'name':'ತ್ರಯೋದಶಿ','nameEn':'Trayodashi Tithi','result':tithiNum==13,'good':true},
      {'name':'ಪ್ರಧೋಷ','nameEn':'Pradosha','result':false,'good':false},
      {'name':'ವಿಷ್ಟಿ ಕರಣ','nameEn':'Vishti Karana (Bhadra)','result':karana.contains('ವಿಷ್ಟಿ')||karana.contains('ಭದ್ರ'),'good':false},
      {'name':'ಸ್ಥಿರ ಕರಣ','nameEn':'Sthira Karana','result':karana.contains('ಸ್ಥಿರ'),'good':true},
      {'name':'ದಿನ ಮೃತ್ಯು','nameEn':'Dina Mrityu','result':false,'good':false},
      {'name':'ದಗ್ಧ ಯೋಗ','nameEn':'Dagdha Yoga','result':(dagdhaMap[varaIdx]??[]).contains(tithiNum),'good':false},
      {'name':'ಅಂಶ ಸಂಧಿ','nameEn':'Amsha Sandhi','result':false,'good':false},
      {'name':'ತಿಥಿ ಸಂಧಿ','nameEn':'Tithi Sandhi','result':tithiIdx==14||tithiIdx==29,'good':false},
      {'name':'ನಕ್ಷತ್ರ ಸಂಧಿ','nameEn':'Nakshatra Sandhi','result':false,'good':false},
      {'name':'ರಾಶಿ ಸಂಧಿ','nameEn':'Rashi Sandhi','result':false,'good':false},
      {'name':'ಸಂಕ್ರಾಂತಿ','nameEn':'Sankranti','result':false,'good':false},
      {'name':'ಗುಲಿಕೋದಯ','nameEn':'Gulikodaya','result':false,'good':false},
      {'name':'ಏಕಾರ್ಗಳ','nameEn':'Ekargala','result':false,'good':false},
      {'name':'ಪಾಪ ದೃಷ್ಟಿ','nameEn':'Lagna Papa Drishti','result':false,'good':false},
      {'name':'ಪಾಪೋದಯ','nameEn':'Papa Udaya','result':false,'good':false},
      {'name':'ರವಿ ದೃಷ್ಟಿ','nameEn':'Sun Aspect on Lagna','result':false,'good':false},
    ];
  }

  // ═══ Tab 4: Special Sputas ═══
  Widget _buildSputaTab() {
    final sputas = _getSpecialSputas();
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, color: kTeal, size: 20), const SizedBox(width: 8),
          Text('ವಿಶೇಷ ಸ್ಫುಟಗಳು / Special Sputas', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kTeal)),
        ]),
        const SizedBox(height: 12),
        ...sputas.map((s) => Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: kTeal.withOpacity(0.04), borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kTeal.withOpacity(0.15))),
          child: Row(children: [
            Expanded(flex: 3, child: Text(s['name']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: kText))),
            Expanded(flex: 2, child: Text(s['value']!, style: TextStyle(fontSize: 11, color: kMuted))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(s['rashi']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kPurple2))),
          ]),
        )),
      ])),
    ]));
  }

  List<Map<String, String>> _getSpecialSputas() {
    if (_prashnaResult == null) return [];
    final p = _prashnaResult!.planets;
    final sun = p['ಸೂರ್ಯ']?.longitude ?? 0; final moon = p['ಚಂದ್ರ']?.longitude ?? 0;
    final mars = p['ಮಂಗಳ']?.longitude ?? 0; final jup = p['ಗುರು']?.longitude ?? 0;
    final sat = p['ಶನಿ']?.longitude ?? 0; final ven = p['ಶುಕ್ರ']?.longitude ?? 0;
    final mer = p['ಬುಧ']?.longitude ?? 0; final rahu = p['ರಾಹು']?.longitude ?? 0;
    final lag = _prashnaResult!.bhavas.isNotEmpty ? _prashnaResult!.bhavas[0] : 0.0;
    String r(double d) => _rashiNames[((d % 360) ~/ 30) % 12];
    final sputas = <Map<String, String>>[];
    void add(String n, double v) => sputas.add({'name':n, 'value':formatDeg(v % 360), 'rashi':r(v)});

    final tri = (sun + moon + jup) % 360;
    final chat = (sun + moon + jup + rahu) % 360;
    final pancha = (sun + moon + mars + jup + sat) % 360;
    add('ತ್ರಿಸ್ಫುಟ / Trisputa', tri);
    add('ಚತುಸ್ಫುಟ / Chatusputa', chat);
    add('ಪಂಚಸ್ಫುಟ / Panchasputa', pancha);
    add('ಪ್ರಾಣ ಸ್ಫುಟ / Prana', tri * 5);
    add('ದೇಹ ಸ್ಫುಟ / Deha', tri * 8);
    add('ಮೃತ್ಯು ಸ್ಫುಟ / Mrityu', tri * 7);
    add('ಸೂಕ್ಷ್ಮ ತ್ರಿ / Sukshma Tri', chat + lag);
    // Dhoomaadi (Upagrahas)
    add('ಧೂಮ / Dhooma', sun + 133.333);
    add('ವ್ಯತೀಪಾತ / Vyatipata', 360 - (sun + 133.333));
    add('ಪರಿವೇಷ / Parivesha', 180 + (360 - (sun + 133.333)));
    add('ಇಂದ್ರಚಾಪ / Indrachapa', 360 - (180 + (360 - (sun + 133.333))));
    add('ಉಪಕೇತು / Upaketu', sun - 30);
    // Beeja/Kshetra (fertility sputas)
    add('ಬೀಜ ಸ್ಫುಟ / Beeja', sun + jup + ven);
    add('ಕ್ಷೇತ್ರ ಸ್ಫುಟ / Kshetra', moon + mars + jup);
    // Santana
    add('ಸಂತಾನ ೧ / Santana 1', jup + sun + moon + sat + rahu);
    // Arooda, Sannidhya, Chaitanya
    final lagRashi = ((lag ~/ 30) % 12).toInt();
    final lordLon = p[_rashiLords[lagRashi]]?.longitude ?? 0;
    add('ಆರೂಢ / Arooda', lordLon + lag);
    add('ಸಾನ್ನಿಧ್ಯ / Sannidhya', moon + rahu);
    add('ಚೈತನ್ಯ / Chaitanya', sun + moon + lag);
    add('ಚಲನ / Chalana', moon + rahu + lag);
    add('ಕಾರಣ / Karana', sun + rahu + lag);
    add('ಪ್ರಸಾದ / Prasada', moon + sat + lag);
    add('ಲಗ್ನ+ರವಿ / Lagna+Ravi', lag + sun);
    return sputas;
  }

  // ═══ Tab 5: Mangala Dravya ═══
  Widget _buildDravyaTab() {
    final idx = (_asmNumber - 1) % 8;
    return SingleChildScrollView(child: Column(children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಸೂಚಿತ ಮಂಗಲ ದ್ರವ್ಯ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kOrange)),
        const SizedBox(height: 12),
        () {
          final item = _ashtaItems[idx];
          return Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [kOrange.withOpacity(0.08), kPurple2.withOpacity(0.08)]),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: kOrange.withOpacity(0.2))),
            child: Row(children: [
              Text(item['icon']!, style: TextStyle(fontSize: 36)), const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
                Text('ಅಧಿದೇವತೆ: ${item['deity']}', style: TextStyle(fontSize: 13, color: kPurple2)),
                Text('ಗ್ರಹ: ${item['graha']}', style: TextStyle(fontSize: 12, color: kMuted)),
              ])),
            ]));
        }(),
      ])),
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ಅಷ್ಟ ಮಂಗಲ ದ್ರವ್ಯಗಳು', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kPurple2)),
        const SizedBox(height: 8),
        ...List.generate(8, (i) {
          final item = _ashtaItems[i]; final sel = i == idx;
          return Container(margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: sel ? kOrange.withOpacity(0.08) : kBg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sel ? kOrange.withOpacity(0.3) : kBorder)),
            child: Row(children: [
              Text('${i+1}.', style: TextStyle(fontWeight: FontWeight.w900, color: kMuted, fontSize: 11)),
              const SizedBox(width: 6), Text(item['icon']!, style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6), Expanded(child: Text(item['name']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText))),
              Text(item['deity']!, style: TextStyle(fontSize: 11, color: kMuted)),
              if (sel) ...[const SizedBox(width: 4), Icon(Icons.arrow_back, color: kOrange, size: 14)],
            ]));
        }),
      ])),
    ]));
  }

  // ═══ Helper Widgets ═══
  Widget _digitBox(String label, int val) => Column(children: [
    Text(label, style: TextStyle(fontSize: 9, color: kMuted), textAlign: TextAlign.center),
    const SizedBox(height: 2),
    Container(width: 42, height: 42, decoration: BoxDecoration(color: kPurple2.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kPurple2.withOpacity(0.2))), alignment: Alignment.center,
      child: Text('$val', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2))),
  ]);

  Widget _resultRow(String label, String value, String formula) => Container(
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: Row(children: [
      Expanded(flex: 2, child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: kText))),
      Expanded(flex: 2, child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kPurple2))),
      Expanded(flex: 2, child: Text(formula, style: TextStyle(fontSize: 9, color: kMuted))),
    ]));

  Widget _kvRow(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Expanded(flex: 2, child: Text(k, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: kText))),
      Expanded(flex: 3, child: Text(v, style: TextStyle(fontSize: 11, color: kText))),
    ]));

  Widget _statusBadge(bool good, String text) => Container(
    padding: const EdgeInsets.all(8), decoration: BoxDecoration(
      color: good ? Colors.green.withOpacity(0.1) : kOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(good ? Icons.check_circle : Icons.info_outline, color: good ? Colors.green : kOrange, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kText))),
    ]));

  Widget _evenOddChip(String text, bool isEven) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: (isEven ? Colors.red : Colors.green).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isEven ? Colors.red : Colors.green)));
}
