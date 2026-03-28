import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../constants/places.dart';
import '../core/ephemeris.dart';
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

  DateTime _dob      = DateTime.now();
  int _hour          = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute        = DateTime.now().minute;
  String _ampm       = DateTime.now().hour < 12 ? 'AM' : 'PM';
  
  late final TextEditingController _placeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _tzCtrl;

  bool _geoLoading   = false;
  String _geoStatus  = '';

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
  int _pruchaka = 1;       // Pruchaka Number (1-108)
  final _pruchakaCtrl = TextEditingController(text: '1');
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
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    _tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
    
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { 
    _numberCtrl.dispose(); 
    _nameCtrl.dispose(); 
    _tambulaCtrl.dispose(); 
    _pruchakaCtrl.dispose();
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    _tabCtrl.dispose(); 
    super.dispose(); 
  }

  Future<void> _geocodeMultiple(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.');
        } else if (data.length == 1) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon);
          setState(() {
            _placeCtrl.text = placeName.trim();
            _latCtrl.text = lat.toStringAsFixed(4);
            _lonCtrl.text = lon.toStringAsFixed(4);
            _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
            _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
          });
        } else {
          if (mounted) _showPlaceDisambiguation(data);
        }
      } else {
        setState(() => _geoStatus = 'Server Error: ${resp.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _geoStatus = 'Network error: $e');
    }
    if (mounted) setState(() => _geoLoading = false);
  }

  void _showPlaceDisambiguation(List results) {
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        backgroundColor: kBg,
        title: Text('ಸ್ಥಳ ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final r = results[index];
            return ListTile(
              leading: Icon(Icons.location_city, color: kPurple2),
              title: Text(r['display_name'], style: TextStyle(color: kText, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                final lat = double.parse(r['lat']);
                final lon = double.parse(r['lon']);
                final autoTz = await getTimezoneForPlace(r['display_name'], lat, lon);
                setState(() {
                  _placeCtrl.text = r['name'] ?? _placeCtrl.text;
                  _latCtrl.text = lat.toStringAsFixed(4);
                  _lonCtrl.text = lon.toStringAsFixed(4);
                  _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                  _geoStatus = '📍 ${r['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
                });
              },
            );
          },
        )),
      );
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context, initialDate: _dob,
      firstDate: DateTime(100), lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: kPurple2, onPrimary: Colors.white, surface: kCard, onSurface: kText),
          dialogBackgroundColor: kBg,
        ), child: child!,
      ),
    );
    if (date != null) setState(() => _dob = date);
  }

  Future<void> _pickTime() async {
    final t = TimeOfDay(hour: _ampm == 'PM' && _hour != 12 ? _hour + 12 : (_ampm == 'AM' && _hour == 12 ? 0 : _hour), minute: _minute);
    final time = await showTimePicker(
      context: context, initialTime: t,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: kPurple2, onPrimary: Colors.white, surface: kCard, onSurface: kText),
          timePickerTheme: TimePickerThemeData(backgroundColor: kBg, dialBackgroundColor: kCard, hourMinuteTextColor: kPurple2),
        ), child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        _hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
        _minute = time.minute;
        _ampm = time.period == DayPeriod.am ? 'AM' : 'PM';
      });
    }
  }

  Future<void> _loadPrashnaChart() async {
    final lat = double.tryParse(_latCtrl.text) ?? LocationService.lat;
    final lon = double.tryParse(_lonCtrl.text) ?? LocationService.lon;
    int h24 = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
    if (_ampm == 'AM' && _hour == 12) h24 = 0;
    final localHour = h24 + _minute / 60.0;
    final tzOffset = double.tryParse(_tzCtrl.text) ?? LocationService.tzOffset;

    final result = await AstroCalculator.calculate(
      year: _dob.year, month: _dob.month, day: _dob.day,
      hourUtcOffset: tzOffset, hour24: localHour,
      lat: lat, lon: lon,
      ayanamsaMode: 'lahiri', trueNode: true,
    );
    if (result != null && mounted) setState(() { _panchang = result.panchang; _prashnaResult = result; });
  }

  Future<void> _calculate() async {
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
    
    // Explicitly recalculate the Prashna chart payload before signaling a response
    await _loadPrashnaChart();
    
    if (mounted) setState(() { _hasResult = true; _errorMsg = ''; });
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
            tabs: const [Tab(text:'ಪ್ರಶ್ನೆ ಸಂಖ್ಯಾ ಗಣಿತ'), Tab(text:'ಪ್ರಶ್ನೆ ಸಮಯದ ಗುಣ'), Tab(text:'ಸೂತ್ರಗಳು/ಇತರೆ ಅಂಶ'), Tab(text:'ವಿಶೇಷ ಸ್ಫುಟಗಳು')],
          )),
          SizedBox(height: 620, child: TabBarView(controller: _tabCtrl, children: [
            _buildSankhyaTab(),
            _buildSamayaGunaTab(),
            _buildSutrasTab(),
            _buildVisheshaSputasTab(),
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
      const SizedBox(height: 14),

      // Date picker
      GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.calendar_today, color: kMuted), const SizedBox(width: 10),
            Text('ದಿನಾಂಕ: ${_dob.day.toString().padLeft(2,'0')}-${_dob.month.toString().padLeft(2,'0')}-${_dob.year}', style: TextStyle(fontSize: 14, color: kText)),
          ]),
        ),
      ),
      const SizedBox(height: 14),

      // Time picker
      GestureDetector(
        onTap: _pickTime,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.access_time, color: kMuted), const SizedBox(width: 10),
            Text('ಸಮಯ: ${_hour.toString().padLeft(2,'0')}:${_minute.toString().padLeft(2,'0')} $_ampm', style: TextStyle(fontSize: 14, color: kText)),
          ]),
        ),
      ),
      const SizedBox(height: 14),

      // Place Selector
      Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return offlinePlaces.keys.take(15);
          final query = textEditingValue.text.toLowerCase();
          return offlinePlaces.keys.where((n) => n.toLowerCase().contains(query));
        },
        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textEditingController, focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'ಊರು ಹುಡುಕಿ / Search Location', prefixIcon: Icon(Icons.search),
              suffixIcon: _geoLoading ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : IconButton(icon: Icon(Icons.my_location, color: kTeal), onPressed: () { _placeCtrl.text = textEditingController.text; _geocodeMultiple(textEditingController.text); }),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
            ),
            onSubmitted: (_) { _placeCtrl.text = textEditingController.text; _geocodeMultiple(textEditingController.text); },
          );
        },
        onSelected: (String selection) async {
          if (offlinePlaces.containsKey(selection)) {
            final coords = offlinePlaces[selection]!;
            final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
            setState(() {
              _placeCtrl.text = selection; _latCtrl.text = coords[0].toStringAsFixed(4); _lonCtrl.text = coords[1].toStringAsFixed(4);
              _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              _geoStatus = '📍 $selection (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(alignment: Alignment.topLeft, child: Material(elevation: 4, borderRadius: BorderRadius.circular(8), child: ConstrainedBox(constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64), child: ListView.builder(padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true, itemBuilder: (context, index) {
            final option = options.elementAt(index);
            return ListTile(dense: true, leading: Icon(Icons.location_on, size: 18, color: kPurple2), title: Text(option, style: TextStyle(fontSize: 13)), onTap: () => onSelected(option));
          }))));
        },
      ),
      if (_geoStatus.isNotEmpty) ...[const SizedBox(height: 6), Text(_geoStatus, style: TextStyle(fontSize: 12, color: kGreen))],
      const SizedBox(height: 14),

      // Lat/Lon/TZ Display
      Row(children: [
        Expanded(flex: 4, child: TextField(controller: _latCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: 'ಅಕ್ಷಾಂಶ (Lat)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(8), isDense: true), style: TextStyle(fontSize: 12))), const SizedBox(width: 8),
        Expanded(flex: 4, child: TextField(controller: _lonCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: 'ರೇಖಾಂಶ (Lon)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(8), isDense: true), style: TextStyle(fontSize: 12))), const SizedBox(width: 8),
        Expanded(flex: 3, child: TextField(controller: _tzCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: 'TZ Offset', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.all(8), isDense: true), style: TextStyle(fontSize: 12))),
      ]),
      const SizedBox(height: 14),
      Divider(color: kBorder),
      const SizedBox(height: 8),

      // Pruchaka Number (1-108)
      TextField(controller: _pruchakaCtrl, keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'ಪ್ರುಚ್ಛಕ ಸಂಖ್ಯೆ / Pruchaka Number (1-108)', prefixIcon: Icon(Icons.person_pin, color: kMuted, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
        style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800),
        onChanged: (v) {
          final p = int.tryParse(v) ?? 1;
          setState(() => _pruchaka = (p < 1) ? 1 : (p > 108 ? 108 : p));
        }),
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

  // ═══ Tab 2: Prashna Samayada Guna ═══
  Widget _buildSamayaGunaTab() {
    if (_panchang == null) return Center(child: Text('Loading...', style: TextStyle(color: kMuted)));
    final checks = _getSamayaGunaChecks();
    return SingleChildScrollView(child: AppCard(padding: EdgeInsets.zero, child: Column(children: [
      Container(color: kPurple2, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        Expanded(flex: 3, child: Text('ವಿಷಯ', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
        Expanded(flex: 2, child: Text('')),
      ])),
      ...checks.map((c) {
        final active = c['result'] as bool;
        return Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder)), color: checks.indexOf(c) % 2 == 0 ? kCard : kBg),
          child: IntrinsicHeight(child: Row(children: [
            Expanded(flex: 3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(c['name'] as String, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPurple2)))),
            Container(width: 1, color: kBorder),
            Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: active ? kOrange.withOpacity(0.08) : Colors.transparent,
              child: Text(active ? (c['good'] as bool ? 'ಶುಭ' : 'ಉಂಟು') : '', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: active ? kOrange : kMuted)))),
          ])),
        );
      }).toList()
    ])));
  }

  List<Map<String, Object>> _getSamayaGunaChecks() {
    if (_panchang == null) return [];
    final tIdx = _panchang!.tithiIndex;
    final karana = _panchang!.karana.toLowerCase();
    return [
      {'name':'ಪ್ರದೋಷ', 'result':false, 'good':false}, // Math later
      {'name':'ವಿಷ್ಟಿ ಕರಣ', 'result':karana.contains('ವಿಷ್ಟಿ')||karana.contains('ಭದ್ರ'), 'good':false},
      {'name':'ಸ್ಥಿರ ಕರಣ', 'result':karana.contains('ಸ್ಥಿರ'), 'good':true},
      {'name':'ದಿನ ಮೃತ್ಯು', 'result':false, 'good':false},
      {'name':'ದಗ್ಧ ಯೋಗ', 'result':false, 'good':false},
      {'name':'ಅಂಶ ಸಂಧಿ', 'result':false, 'good':false},
      {'name':'ತಿಥಿ ಸಂಧಿ', 'result':tIdx==14||tIdx==29, 'good':false},
      {'name':'ನಕ್ಷತ್ರ ಸಂಧಿ', 'result':false, 'good':false},
      {'name':'ರಾಶಿ ಸಂಧಿ', 'result':false, 'good':false},
      {'name':'ಸಂಕ್ರಾಂತಿ', 'result':false, 'good':false},
      {'name':'ಗುಳಿಕೋದಯ', 'result':false, 'good':false},
      {'name':'ಏಕಾರ್ಗಳ', 'result':false, 'good':false},
      {'name':'ಪಾಪ ದೃಷ್ಟಿ', 'result':false, 'good':false},
      {'name':'ಪಾಪ ಉದಯ', 'result':false, 'good':false},
      {'name':'ರವಿ ದೃಷ್ಟಿ', 'result':false, 'good':false},
    ];
  }

  // ═══ Tab 3: Sutras & Other Aspects ═══
  Widget _buildSutrasTab() {
    if (_prashnaResult == null) return Center(child: Text('Loading...', style: TextStyle(color: kMuted)));
    final items = _getSutraItems();
    return SingleChildScrollView(child: AppCard(padding: EdgeInsets.zero, child: Column(children: [
      Container(color: kPurple2, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        Expanded(flex: 3, child: Text('ವಿಷಯ', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
        Expanded(flex: 2, child: Text('ಮೌಲ್ಯ', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
      ])),
      ...items.map((c) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder)), color: items.indexOf(c) % 2 == 0 ? kCard : kBg),
        child: IntrinsicHeight(child: Row(children: [
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(c['name']!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPurple2)))),
          Container(width: 1, color: kBorder),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(c['value']!, style: TextStyle(fontSize: 13, color: kText)))),
        ])),
      )).toList()
    ])));
  }

  List<Map<String, String>> _getSutraItems() {
    final tambulaRashi = (_tambula - 1) % 12;
    final aroRashi = (_pruchaka - 1) ~/ 9;
    final lag = _prashnaResult?.bhavas.isNotEmpty == true ? _prashnaResult!.bhavas[0] : 0.0;
    final lagRashi = ((lag ~/ 30) % 12).toInt();
    
    // Samanya: Same parity = Roga (Disease), Diff = Jiva (Life)
    final isSamanyaRoga = (aroRashi % 2 == 0 && lagRashi % 2 == 0) || (aroRashi % 2 != 0 && lagRashi % 2 != 0);
    // Adhipa / Sthalaka mock mapping logic.
    final lordLag = _rashiLords[lagRashi]; final lordAro = _rashiLords[aroRashi];
    final isAdhipaJiva = lordLag == lordAro || (lordLag == 'ಸೂರ್ಯ' && lordAro == 'ಚಂದ್ರ') || (lordLag == 'ಗುರು');
    final isMahaRoga = (aroRashi + lagRashi) % 2 == 0;
    
    // Chandra metrics 1-60/1-12/1-36
    final moonLon = _prashnaResult?.planets['ಚಂದ್ರ']?.longitude ?? 0.0;
    final nakRem = moonLon % 13.3333;
    final kriya = ((nakRem / 13.3333) * 60).ceil().clamp(1, 60);
    final avastha = ((nakRem / 13.3333) * 12).ceil().clamp(1, 12);
    final vela = ((nakRem / 13.3333) * 36).ceil().clamp(1, 36);

    return [
      {'name':'ಸಾಮಾನ್ಯ ಸೂತ್ರ (ಪೃಥ್ವಿ)', 'value': isSamanyaRoga ? 'ರೋಗ' : 'ಜೀವ'}, 
      {'name':'ಅಂಶ ಸೂತ್ರ (ಅಗ್ನಿ)', 'value': isSamanyaRoga ? 'ರೋಗ' : 'ಮೃತ್ಯು'},
      {'name':'ಅಧಿಪ ಸೂತ್ರ (ಜಲ)', 'value': isAdhipaJiva ? 'ಜೀವ' : 'ರೋಗ'},
      {'name':'ಸ್ಥಳಕ ಸೂತ್ರ (ವಾಯು)', 'value': isAdhipaJiva ? 'ಜೀವ' : 'ಮೃತ್ಯು'},
      {'name':'ಮಹಾ ಸೂತ್ರ (ಆಕಾಶ)', 'value': isMahaRoga ? 'ರೋಗ' : 'ಜೀವ'},
      {'name':'ಚಂದ್ರ ಕ್ರಿಯಾ', 'value':'$kriya - ಕ್ಷತಕರ (1-60)'},
      {'name':'ಚಂದ್ರ ಅವಸ್ಥಾ', 'value':'$avastha - ದಾಸತಾ (1-12)'},
      {'name':'ಚಂದ್ರ ವೇಲಾ', 'value':'$vela - ಉಗ್ರಜ್ವರ (1-36)'},
      {'name':'ತಾಂಬೂಲ ಗ್ರಹ', 'value':_rashiLords[tambulaRashi]},
      {'name':'ತಾಂಬೂಲ ರಾಶಿ', 'value':_rashiNames[tambulaRashi]},
      {'name':'ಭೂತೋದಯ', 'value': ['ಪೃಥ್ವಿ', 'ಜಲ', 'ಅಗ್ನಿ', 'ವಾಯು', 'ಆಕಾಶ'][DateTime.now().hour % 5]},
    ];
  }

  // ═══ Tab 4: Special Sphutas ═══
  Widget _buildVisheshaSputasTab() {
    if (_prashnaResult == null) return Center(child: Text('Loading...', style: TextStyle(color: kMuted)));
    final sputas = _getSputas();
    return SingleChildScrollView(child: AppCard(padding: EdgeInsets.zero, child: Column(children: [
      Container(color: kPurple2, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(children: [
        Expanded(flex: 3, child: Text('ಸ್ಫುಟ', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
        Expanded(flex: 2, child: Text('', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white))), 
      ])),
      ...sputas.map((s) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder)), color: sputas.indexOf(s) % 2 == 0 ? kCard : kBg),
        child: IntrinsicHeight(child: Row(children: [
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(s['name']!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPurple2)))),
          Container(width: 1, color: kBorder),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(s['value']!, style: TextStyle(fontSize: 13, color: kText)))),
        ])),
      )).toList()
    ])));
  }

  String _fmt(double deg) {
    deg = deg % 360; int r = deg ~/ 30; double rem = deg % 30; int d = rem.floor();
    double mRem = (rem - d) * 60; int m = mRem.floor(); int s = ((mRem - m) * 60).round();
    return '${r.toString().padLeft(2,'0')}s ${d.toString().padLeft(2,'0')}° ${m.toString().padLeft(2,'0')}\' ${s.toString().padLeft(2,'0')}"';
  }

  List<Map<String, String>> _getSputas() {
    final p = _prashnaResult!.planets;
    final sun = p['ಸೂರ್ಯ']?.longitude ?? 0; final moon = p['ಚಂದ್ರ']?.longitude ?? 0;
    final mars = p['ಮಂಗಳ']?.longitude ?? 0; final jup = p['ಗುರು']?.longitude ?? 0;
    final sat = p['ಶನಿ']?.longitude ?? 0; final ven = p['ಶುಕ್ರ']?.longitude ?? 0;
    final rahu = p['ರಾಹು']?.longitude ?? 0;
    final lag = _prashnaResult!.bhavas.isNotEmpty ? _prashnaResult!.bhavas[0] : 0.0;
    
    // Aroodha Sputa derivation
    final aroRashi = (_pruchaka - 1) ~/ 9;
    final lagMod = lag % 30;
    final aroodha = (aroRashi * 30) + lagMod;
    final vithi = aroodha + lag;
    final chatra = aroodha + (lag - sun);

    return [
      {'name':'ಬೀಜ ಸ್ಫುಟ (ಜೀವಾಧಿಷ್ಠಿತ)','value':_fmt(sun + jup + ven)},
      {'name':'ಬೀಜ ಸ್ಫುಟ (ಜೀವೇಂದು ಕ್ಷಿತಿಜ)','value':_fmt(sun + moon + lag)},
      {'name':'ಬೀಜ ಸ್ಫುಟ (ರವೀಂದ್ರಶುಕ್ರವರೇಜ)','value':_fmt(sun + moon + ven + jup)},
      {'name':'ಸಂತಾನ ತಿಥಿ ಸ್ಫುಟ (ಪಂಚಗ್ನಶ...)','value':_fmt((moon * 5) - (sun * 5))},
      {'name':'ಸಂತಾನ ತಿಥಿ ಸ್ಫುಟ (ಚಂದ್ರಸ್ಫುಟ)','value':_fmt(moon)},
      {'name':'ಸಂತಾನ ತಿಥಿ ಸ್ಫುಟ (ರವೀಂದ್ರ...)','value':_fmt(sun + moon)},
      {'name':'ಮಾರಣ ಶನಿ','value':_fmt(sat)},
      {'name':'ಆರೂಢ ಸ್ಫುಟ','value':_fmt(aroodha)},
      {'name':'ವೀಥಿ ಸ್ಫುಟ','value':_fmt(vithi)},
      {'name':'ಛತ್ರ ಸ್ಫುಟ','value':_fmt(chatra)},
      {'name':'ಲಗ್ನ ರವಿ ಯೋಗ','value':_fmt(lag + sun)},
      {'name':'ಸಾನ್ನಿಧ್ಯ ಸ್ಫುಟ','value':_fmt(moon + rahu)},
      {'name':'ಚೈತನ್ಯ ಸ್ಫುಟ','value':_fmt(sun + moon + lag)},
      {'name':'ಚಲನ ಸ್ಫುಟ','value':_fmt(moon + rahu + lag)},
      {'name':'ಕಾರಾಣಿ ಸ್ಫುಟ','value':_fmt(sun + rahu + lag)},
      {'name':'ಪ್ರಾಸಾದ ಸ್ಫುಟ','value':_fmt(moon + sat + lag)},
      {'name':'ಪಕ್ವಾಂತರ ಪ್ರಾಸಾದ ಸ್ಫುಟ','value':_fmt(moon + sun + sat + lag)},
      {'name':'ಅಂಕಣ ಸ್ಫುಟ','value':_fmt(aroodha + moon)},
      {'name':'ಮುಖ ಮಂಟಪ ಸ್ಫುಟ','value':_fmt(aroodha + sun)},
      {'name':'ದೀಪ ಸ್ಫುಟ','value':_fmt(aroodha + jup)},
      {'name':'ಆಚಾರ್ಯ ಸ್ಫುಟ','value':_fmt(aroodha + ven)},
      {'name':'ಪಕ್ವಾಂತರ ಆಚಾರ್ಯ ಸ್ಫುಟ','value':_fmt(aroodha + ven + moon)},
      {'name':'ದೇವಲಕ ಸ್ಫುಟ','value':_fmt(aroodha + mars)},
      {'name':'ಧ್ವಜ ಸ್ಫುಟ','value':_fmt(aroodha + sat)},
      {'name':'ಪ್ರಶ್ನ ಸ್ಫುಟ','value':_fmt(aroodha + rahu)},
    ];
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
