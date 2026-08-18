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

  // Chandra Kriya — 60 Kriyas (Prasna Marga Ch.7)
  static const _chandraKriyas = [
    'ಸ್ಥಾನಭ್ರಂಶ (Sthanabhrashta)', 'ತಪೋವೃತ್ತಿ (Tapovritti)', 'ರಾಜಸೇವಾ (Rajaseva)',
    'ತಸ್ಕರತ್ವ (Taskaratva)', 'ರೋಗಾರ್ತಿ (Rogarti)', 'ಸಿಂಹಾಸನಸ್ಥಿತಿ (Simhasanasthiti)',
    'ರಾಜಪೂಜಾ (Rajapuja)', 'ಯುದ್ಧವೃತ್ತಿ (Yuddhvritti)', 'ಪ್ರವಾಸ (Pravasa)',
    'ಧಾನ್ಯಲಾಭ (Dhanyalabha)', 'ಕೃಷಿ (Krishi)', 'ಪಶುಲಾಭ (Pashulabha)',
    'ಕ್ಷತಕರಚರಣ (Kshatakaracharna)', 'ವಿಷಭಕ್ಷಣ (Vishabhakshana)', 'ಸ್ತ್ರೀಸಂಗ (Strisanga)',
    'ಸ್ವರ್ಣಲಾಭ (Svarnalabha)', 'ಚೋರಭಯ (Chorabhaya)', 'ವ್ಯಾಘ್ರಭಯ (Vyaghrabhaya)',
    'ಜಲಭಯ (Jalabhaya)', 'ಅಗ್ನಿಭಯ (Agnibhaya)', 'ಶೂಲಭಯ (Shulabhaya)',
    'ರಾಜಭಯ (Rajabhaya)', 'ಸರ್ಪಭಯ (Sarpabhaya)', 'ಕಲಹ (Kalaha)',
    'ಈಶ್ವರಕೋಪ (Ishvarakopa)', 'ಮಾತೃಕೋಪ (Matrikopa)', 'ಪಿತೃಕೋಪ (Pitrikopa)',
    'ಬಂಧುಕೋಪ (Bandhukopa)', 'ಮಿತ್ರಕೋಪ (Mitrakopa)', 'ಧನನಾಶ (Dhananasha)',
    'ಕೀರ್ತಿಲಾಭ (Kirtilabha)', 'ವಿವಾಹ (Vivaha)', 'ವಿದ್ಯಾಲಾಭ (Vidyalabha)',
    'ಸಂತಾನಲಾಭ (Santanalabha)', 'ಗೃಹಲಾಭ (Grihalabha)', 'ವಾಹನಲಾಭ (Vahanalabha)',
    'ಭೂಮಿಲಾಭ (Bhumilabha)', 'ರತ್ನಲಾಭ (Ratnalabha)', 'ಅನ್ನಲಾಭ (Annalabha)',
    'ವಸ್ತ್ರಲಾಭ (Vastralabha)', 'ಆಯುಧಲಾಭ (Ayudhalabha)', 'ಗಜಲಾಭ (Gajalabha)',
    'ಅಶ್ವಲಾಭ (Ashvalabha)', 'ಗೋಲಾಭ (Golabha)', 'ಮಹಿಷಲಾಭ (Mahishalabha)',
    'ಛಾಗಲಾಭ (Chagalabha)', 'ಅಜಲಾಭ (Ajalabha)', 'ಕ್ಷೀರಲಾಭ (Kshiralabha)',
    'ಘೃತಲಾಭ (Ghritalabha)', 'ತೈಲಲಾಭ (Tailalabha)', 'ಮಧುಲಾಭ (Madhulabha)',
    'ಫಲಲಾಭ (Phalalabha)', 'ಪುಷ್ಪಲಾಭ (Pushpalabha)', 'ಜಲಲಾಭ (Jalalabha)',
    'ಔಷಧಲಾಭ (Aushadhalabha)', 'ದೇವಪೂಜಾ (Devapuja)', 'ಬ್ರಹ್ಮಪೂಜಾ (Brahmapuja)',
    'ಮೃತ್ಯು (Mrityu)', 'ಸ್ವಲ್ಪಾಯು (Svalpayu)', 'ಮಧ್ಯಾಯು (Madhyayu)',
    'ದೀರ್ಘಾಯು (Dirghayu)',
  ];

  // Chandra Avastha — 12 states (Prasna Marga)
  static const _chandraAvasthas = [
    'ಶಯನ (Shayana)', 'ಉಪವೇಶ (Upavesha)', 'ನೇತ್ರೋನ್ಮೀಲನ (Netronmilana)',
    'ಪ್ರಕಾಶನ (Prakashana)', 'ಗಮನ (Gamana)', 'ಆಗಮನ (Agamana)',
    'ಸಭಾಗಮನ (Sabhagamana)', 'ಆರೋಹಣ (Arohana)', 'ರಾಜಸಭಾ (Rajasabha)',
    'ಆಗಮ (Agama)', 'ಭೋಜನ (Bhojana)', 'ನರ್ತನ (Nartana)',
  ];

  // Chandra Vela — 36 Velas (Prasna Marga Ch.7)
  static const _chandraVelas = [
    'ಮೃತ್ಯು (Mrityu)', 'ಅಗ್ನಿ (Agni)', 'ರಾಜ (Raja)',
    'ಚೋರ (Chora)', 'ಮಂಗಳ (Mangala)', 'ಕಳಹ (Kalaha)',
    'ಅಮೃತ (Amrita)', 'ಉಗ್ರ (Ugra)', 'ರೋಗ (Roga)',
    'ಕಾಲ (Kala)', 'ಸಿದ್ಧಿ (Siddhi)', 'ಶುಭ (Shubha)',
    'ಅಮೃತ (Amrita)', 'ಮುಸಲ (Mushala)', 'ಗದ (Gada)',
    'ಮೃತ್ಯು (Mrityu)', 'ಕಾಲ (Kala)', 'ಅಮೃತ (Amrita)',
    'ಕಂಟಕ (Kantaka)', 'ಶೂಲ (Shula)', 'ಅತಿಗಂಡ (Atiganda)',
    'ಸುಕರ್ಮ (Sukarma)', 'ಧೃತಿ (Dhriti)', 'ಶೂಲ (Shula)',
    'ಗಂಡ (Ganda)', 'ವೃದ್ಧಿ (Vriddhi)', 'ಧ್ರುವ (Dhruva)',
    'ವಜ್ರ (Vajra)', 'ಹರ್ಷ (Harsha)', 'ವಜ್ರಕಂಟಕ (Vajrakantaka)',
    'ಸಿದ್ಧಿ (Siddhi)', 'ವ್ಯತೀಪಾತ (Vyatipata)', 'ವರೀಯಾನ (Variyaan)',
    'ಪರಿಘ (Parigha)', 'ಶಿವ (Shiva)', 'ಸಿದ್ಧ (Siddha)',
  ];

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
          SizedBox(height: 900, child: TabBarView(controller: _tabCtrl, children: [
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
      
      // Graha, Yoni, Dwaja, Jantu from Digits (Restored)
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        ...[ ['ನೂರರ ಅಂಕ / D1 (ಭೂತ/Past)', _d1],
             ['ಹತ್ತರ ಅಂಕ / D2 (ವರ್ತಮಾನ/Present)', _d2],
             ['ಒಂದರ ಅಂಕ / D3 (ಭವಿಷ್ಯ/Future)', _d3] ].map((e) {
          final label = e[0] as String;
          final d = (e[1] as int).clamp(1, 8);
          return Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
            child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
              title: Text('$label = ${e[1]}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPurple2)),
              subtitle: Text('ಗ್ರಹ: ${_digitGraha[d]}  •  ಯೋನಿ: ${_digitYoni[d]}', style: TextStyle(fontSize: 11, color: kMuted)),
              childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              children: [
                _kvRow('ಗ್ರಹ (Graha)', _digitGraha[d]),
                _kvRow('ದ್ವಜಾದಿ (Dwaja)', _digitDwaja[d]),
                _kvRow('ಯೋನಿ (Yoni)', _digitYoni[d]),
                _kvRow('ಜಂತು (Jantu)', _digitJantu[d]),
              ]
          )));
        }),
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
    if (_panchang == null || _prashnaResult == null) return [];
    final tIdx = _panchang!.tithiIndex;
    final tNum = (tIdx % 15) + 1;
    final karana = _panchang!.karana.toLowerCase();
    final p = _prashnaResult!.planets;
    final lag = _prashnaResult!.bhavas.isNotEmpty ? _prashnaResult!.bhavas[0] : 0.0;
    final lagRashi = ((lag ~/ 30) % 12).toInt();

    // Planet longitudes (keys match calculator: ರವಿ=Sun, ಕುಜ=Mars)
    final sun = p['ರವಿ']?.longitude ?? 0; final moon = p['ಚಂದ್ರ']?.longitude ?? 0;
    final mars = p['ಕುಜ']?.longitude ?? 0; final sat = p['ಶನಿ']?.longitude ?? 0;
    final rahu = p['ರಾಹು']?.longitude ?? 0; final ketu = p['ಕೇತು']?.longitude ?? 0;
    final jup = p['ಗುರು']?.longitude ?? 0; final ven = p['ಶುಕ್ರ']?.longitude ?? 0;

    // Helper: is planet in rashi?
    int rashiOf(double lon) => ((lon ~/ 30) % 12).toInt();

    // Pradosha: Trayodashi tithi
    final isPradosha = (tNum == 13);
    // Tithi Sandhi
    final isTithiSandhi = (tIdx == 14 || tIdx == 29 || tIdx == 0 || tIdx == 15);
    // Nakshatra Sandhi (Gandanta)
    final nIdx = _panchang!.nakshatraIndex;
    final isNakSandhi = [8, 9, 17, 18, 26, 0].contains(nIdx);
    // Rashi Sandhi: Lagna near 0° or 30° of sign
    final lagInSign = lag % 30;
    final isRashiSandhi = lagInSign < 1.0 || lagInSign > 29.0;
    // Vishti Karana (Bhadra)
    final isVishti = karana.contains('ವಿಷ್ಟಿ') || karana.contains('ಭದ್ರ');
    // Sthira Karana
    final isSthira = karana.contains('ಸ್ಥಿರ');
    // Papa Kartari: Malefics on both sides of Lagna
    final maleficRashis = [rashiOf(mars), rashiOf(sat), rashiOf(rahu), rashiOf(ketu)];
    final isPapaKartari = maleficRashis.contains((lagRashi + 1) % 12) && maleficRashis.contains((lagRashi + 11) % 12);
    // Shubha Kartari: Benefics on both sides
    final beneficRashis = [rashiOf(jup), rashiOf(ven), rashiOf(moon)];
    final isShubhaKartari = beneficRashis.contains((lagRashi + 1) % 12) && beneficRashis.contains((lagRashi + 11) % 12);
    // Papa Lagna: Malefic in Lagna
    final isPapaLagna = maleficRashis.contains(lagRashi);
    // Papa Drishti: Malefic aspects Lagna (7th from malefic)
    final isPapaDrishti = maleficRashis.any((r) => (r + 6) % 12 == lagRashi);
    // Ravi Drishti: Sun aspects Lagna
    final isRaviDrishti = (rashiOf(sun) + 6) % 12 == lagRashi;
    // Guru Drishti: Jupiter aspects Lagna (5th, 7th, 9th)
    final jupR = rashiOf(jup);
    final isGuruDrishti = [(jupR+4)%12, (jupR+6)%12, (jupR+8)%12].contains(lagRashi);
    // Combust Moon (within 12° of Sun)
    final moonSunDiff = (moon - sun).abs() % 360;
    final isMoonCombust = moonSunDiff < 12 || moonSunDiff > 348;
    // Gulika Udaya: Gulika in Lagna
    final gulika = _computeGulikaLon(lag, sun);
    final isGulikaUdaya = rashiOf(gulika) == lagRashi;
    // Dagdha Yoga: Sun in specific nakshatras on specific days
    final varaStr = _panchang!.vara;
    final varaIdx = _varaNames.indexWhere((v) => varaStr.contains(v));
    final isDagdha = _isDagdhaYoga(varaIdx < 0 ? 0 : varaIdx, nIdx);
    // Sankranti: Sun near 0° of a sign
    final sunInSign = sun % 30;
    final isSankranti = sunInSign < 1.0 || sunInSign > 29.0;
    // Rahu Kala: approximate calculation
    final hourNow = DateTime.now().hour;
    final vi = varaIdx < 0 ? 0 : varaIdx;
    final isRahuKala = _isRahuKala(vi, hourNow);
    // Yamaghanta
    final isYamaghanta = _isYamaghanta(vi, hourNow);
    // Rikta Tithi (4, 9, 14)
    final isRiktaTithi = [4, 9, 14].contains(tNum);

    return [
      {'name':'ಪ್ರದೋಷ (Pradosha)', 'result':isPradosha, 'good':false},
      {'name':'ವಿಷ್ಟಿ/ಭದ್ರ ಕರಣ', 'result':isVishti, 'good':false},
      {'name':'ಸ್ಥಿರ ಕರಣ', 'result':isSthira, 'good':true},
      {'name':'ರಿಕ್ತ ತಿಥಿ (4/9/14)', 'result':isRiktaTithi, 'good':false},
      {'name':'ತಿಥಿ ಸಂಧಿ', 'result':isTithiSandhi, 'good':false},
      {'name':'ನಕ್ಷತ್ರ ಸಂಧಿ (ಗಂಡಾಂತ)', 'result':isNakSandhi, 'good':false},
      {'name':'ರಾಶಿ ಸಂಧಿ', 'result':isRashiSandhi, 'good':false},
      {'name':'ಸಂಕ್ರಾಂತಿ', 'result':isSankranti, 'good':false},
      {'name':'ದಗ್ಧ ಯೋಗ', 'result':isDagdha, 'good':false},
      {'name':'ಗುಳಿಕೋದಯ', 'result':isGulikaUdaya, 'good':false},
      {'name':'ರಾಹು ಕಾಲ', 'result':isRahuKala, 'good':false},
      {'name':'ಯಮಘಂಟ', 'result':isYamaghanta, 'good':false},
      {'name':'ಪಾಪ ಕರ್ತರಿ ಯೋಗ', 'result':isPapaKartari, 'good':false},
      {'name':'ಶುಭ ಕರ್ತರಿ ಯೋಗ', 'result':isShubhaKartari, 'good':true},
      {'name':'ಪಾಪ ಲಗ್ನ', 'result':isPapaLagna, 'good':false},
      {'name':'ಪಾಪ ದೃಷ್ಟಿ', 'result':isPapaDrishti, 'good':false},
      {'name':'ರವಿ ದೃಷ್ಟಿ', 'result':isRaviDrishti, 'good':false},
      {'name':'ಗುರು ದೃಷ್ಟಿ', 'result':isGuruDrishti, 'good':true},
      {'name':'ಚಂದ್ರ ಅಸ್ತ (Combust)', 'result':isMoonCombust, 'good':false},
    ];
  }

  // Gulika longitude (approximate: Saturn's portion of day divided into 8)
  double _computeGulikaLon(double lag, double sun) {
    // Simplified: Gulika = Lagna + (Saturn's Kala portion). This is a rough approximation.
    final hourAngle = (DateTime.now().hour * 15.0) % 360;
    return (lag + hourAngle + 133.33) % 360; // ~Saturn's kala offset
  }

  // Dagdha Yoga: specific Sun-Nakshatra-Vara combination
  bool _isDagdhaYoga(int varaIdx, int nakIdx) {
    // Classical Dagdha Yoga table (Vara → specific Nakshatras that are dagdha)
    const dagdha = {
      0: [11], // Sunday: U.Phalguni
      1: [5],  // Monday: Ardra
      2: [14], // Tuesday: Swati
      3: [9],  // Wednesday: Magha
      4: [7],  // Thursday: Pushya
      5: [12], // Friday: Hasta
      6: [3],  // Saturday: Rohini
    };
    return dagdha[varaIdx]?.contains(nakIdx) ?? false;
  }

  // Rahu Kala approximation
  bool _isRahuKala(int varaIdx, int hour) {
    // Rahu Kala slots (1.5hr each starting from sunrise ~6AM)
    const rahuSlots = [7, 1, 6, 4, 5, 3, 2]; // Sun=7th slot, Mon=1st, etc.
    final slot = rahuSlots[varaIdx];
    final startHour = 6 + ((slot - 1) * 1.5).floor();
    return hour >= startHour && hour < startHour + 2;
  }

  // Yamaghanta approximation
  bool _isYamaghanta(int varaIdx, int hour) {
    const yamaSlots = [4, 3, 2, 1, 6, 5, 7]; // varies by weekday
    final slot = yamaSlots[varaIdx];
    final startHour = 6 + ((slot - 1) * 1.5).floor();
    return hour >= startHour && hour < startHour + 2;
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
    final lag = _prashnaResult?.bhavas.isNotEmpty == true ? _prashnaResult!.bhavas[0] : 0.0;
    final lagRashi = ((lag ~/ 30) % 12).toInt();
    final lagNavamsha = ((lag / (30.0/9.0)) % 12).toInt(); // Navamsha of Lagna

    // Aroodha derivation from Pruchaka number (Prasna Marga)
    final aroRashi = (_pruchaka - 1) ~/ 9;
    final aroNavamsha = (_pruchaka - 1) % 9; // Navamsha of Aroodha

    // 1. Samanya Sutra (Earth) — Parity of Aroodha Rashi vs Lagna Rashi
    // Same parity (both odd or both even) = Roga; Different = Jeeva
    final samanyaRoga = (aroRashi % 2) == (lagRashi % 2);

    // 2. Amsha Sutra (Fire) — Parity of Aroodha Navamsha vs Lagna Navamsha
    final amshaRoga = (aroNavamsha % 2) == (lagNavamsha % 2);

    // 3. Adhipa Sutra (Water) — Lord relationship
    // If lords are same, mutual friends, or one is luminaries pair → Jeeva
    final lordLag = _rashiLords[lagRashi];
    final lordAro = _rashiLords[aroRashi];
    // Natural friendship table (simplified: Jupiter-Sun-Moon-Mars friends; Venus-Mercury-Saturn friends)
    bool areFriends(String l1, String l2) {
      if (l1 == l2) return true;
      const friends = {
        'ಸೂರ್ಯ': ['ಚಂದ್ರ','ಮಂಗಳ','ಗುರು'], 'ಚಂದ್ರ': ['ಸೂರ್ಯ','ಬುಧ'],
        'ಮಂಗಳ': ['ಸೂರ್ಯ','ಚಂದ್ರ','ಗುರು'], 'ಬುಧ': ['ಸೂರ್ಯ','ಶುಕ್ರ'],
        'ಗುರು': ['ಸೂರ್ಯ','ಚಂದ್ರ','ಮಂಗಳ'], 'ಶುಕ್ರ': ['ಬುಧ','ಶನಿ'],
        'ಶನಿ': ['ಬುಧ','ಶುಕ್ರ'],
      };
      return friends[l1]?.contains(l2) ?? false;
    }
    final adhipaJeeva = areFriends(lordLag, lordAro);

    // 4. Nakshatra Sutra (Air) — Tara/Nakshatra balance
    // Count from Aroodha nakshatra to Lagna nakshatra; if result is 1,3,5,7 → Jeeva
    final lagNak = ((lag / 13.3333) % 27).floor();
    final aroNak = (_pruchaka % 27);
    final taraDiff = ((lagNak - aroNak) % 9).abs();
    final nakshatraJeeva = [1, 3, 5, 7].contains(taraDiff);

    // 5. Maha Sutra (Space) — Majority verdict of above 4
    int jeevaCount = 0;
    if (!samanyaRoga) jeevaCount++;
    if (!amshaRoga) jeevaCount++;
    if (adhipaJeeva) jeevaCount++;
    if (nakshatraJeeva) jeevaCount++;
    final mahaJeeva = jeevaCount >= 3; // Majority = Jeeva

    // Madhya Phala — Digit parity interpretation
    final madhyaPhala = (_d1 % 2 == _d2 % 2 && _d2 % 2 == _d3 % 2)
        ? (_d1 % 2 == 0 ? 'ಮೃತ್ಯು (All Even — Death)' : 'ಜೀವ (All Odd — Life)')
        : 'ಮಿಶ್ರ (Mixed — Roga/Recovery)';

    // Sankhya Phala — Final Numerical Verdict
    final sankhyaPhala = jeevaCount >= 4 ? 'ಜೀವ (Jeeva — Full Recovery)'
        : jeevaCount >= 3 ? 'ಜೀವ ಪ್ರಾಯ (Jeeva Praya — Likely Recovery)'
        : jeevaCount == 2 ? 'ಸಂಶಯ (Samshaya — Doubtful/Mixed)'
        : jeevaCount == 1 ? 'ರೋಗ ಪ್ರಾಯ (Roga Praya — Likely Disease)'
        : 'ಮೃತ್ಯು/ರೋಗ (Mrityu/Roga — Grave)';

    // Chandra metrics (Prasna Marga Ch.7)
    final moonLon = _prashnaResult?.planets['ಚಂದ್ರ']?.longitude ?? 0.0;
    final nakRem = moonLon % 13.3333;
    final kriyaIdx = ((nakRem / 13.3333) * 60).floor().clamp(0, 59);
    final avasthaIdx = ((nakRem / 13.3333) * 12).floor().clamp(0, 11);
    final velaIdx = ((nakRem / 13.3333) * 36).floor().clamp(0, 35);

    // Tambula Phala (B.V. Raman / Prasna Marga)
    final tambulaRashi = ((_tambula * 7) + 1) % 12;
    final tGrahaIdx = ((_tambula * 10) + 1) % 7;
    final tambulaGraha = _varaNames[tGrahaIdx];

    // Bhutodaya — element ruling the current hour
    // Prasna Marga: Prithvi→Jala→Agni→Vayu→Akasha cycle, 2.4 ghatikas each
    final bhutodayaIdx = DateTime.now().hour % 5;

    return [
      {'name':'① ಸಾಮಾನ್ಯ ಸೂತ್ರ (ಪೃಥ್ವಿ)', 'value': samanyaRoga ? '⚠️ ರೋಗ' : '✅ ಜೀವ'},
      {'name':'② ಅಂಶ ಸೂತ್ರ (ಅಗ್ನಿ)', 'value': amshaRoga ? '⚠️ ರೋಗ' : '✅ ಜೀವ'},
      {'name':'③ ಅಧಿಪ ಸೂತ್ರ (ಜಲ)', 'value': adhipaJeeva ? '✅ ಜೀವ' : '⚠️ ರೋಗ'},
      {'name':'④ ನಕ್ಷತ್ರ ಸೂತ್ರ (ವಾಯು)', 'value': nakshatraJeeva ? '✅ ಜೀವ' : '⚠️ ರೋಗ'},
      {'name':'⑤ ಮಹಾ ಸೂತ್ರ (ಆಕಾಶ)', 'value': mahaJeeva ? '✅ ಜೀವ' : '⚠️ ರೋಗ/ಮೃತ್ಯು'},
      {'name':'━━━━━━━━━━━━━━━━━━', 'value':'━━━━━━━━━━━━'},
      {'name':'ಮಧ್ಯ ಫಲ (Madhya Phala)', 'value': madhyaPhala},
      {'name':'ಸಂಖ್ಯಾ ಫಲ (Final Verdict)', 'value': sankhyaPhala},
      {'name':'ಜೀವ ಎಣಿಕೆ (Jeeva Count)', 'value': '$jeevaCount / 4'},
      {'name':'━━━━━━━━━━━━━━━━━━', 'value':'━━━━━━━━━━━━'},
      {'name':'ಚಂದ್ರ ಕ್ರಿಯಾ', 'value':'${kriyaIdx+1}. ${_chandraKriyas[kriyaIdx]}'},
      {'name':'ಚಂದ್ರ ಅವಸ್ಥಾ', 'value':'${avasthaIdx+1}. ${_chandraAvasthas[avasthaIdx]}'},
      {'name':'ಚಂದ್ರ ವೇಲಾ', 'value':'${velaIdx+1}. ${_chandraVelas[velaIdx]}'},
      {'name':'━━━━━━━━━━━━━━━━━━', 'value':'━━━━━━━━━━━━'},
      {'name':'ತಾಂಬೂಲ ಗ್ರಹ', 'value': tambulaGraha},
      {'name':'ತಾಂಬೂಲ ರಾಶಿ', 'value': _rashiNames[tambulaRashi]},
      {'name':'ಭೂತೋದಯ', 'value': _bhutaNames[bhutodayaIdx]},
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
    final sun = p['ರವಿ']?.longitude ?? 0; final moon = p['ಚಂದ್ರ']?.longitude ?? 0;
    final mars = p['ಕುಜ']?.longitude ?? 0; final jup = p['ಗುರು']?.longitude ?? 0;
    final sat = p['ಶನಿ']?.longitude ?? 0; final ven = p['ಶುಕ್ರ']?.longitude ?? 0;
    final mer = p['ಬುಧ']?.longitude ?? 0; final rahu = p['ರಾಹು']?.longitude ?? 0;
    final ketu = p['ಕೇತು']?.longitude ?? 0;
    final lag = _prashnaResult!.bhavas.isNotEmpty ? _prashnaResult!.bhavas[0] : 0.0;
    
    // ─── Core Sputas (Prasna Marga Ch.5-6) ───
    final trisputa = (lag + moon + jup) % 360;       // Trisputa
    final chatusputa = (trisputa + sun) % 360;        // Chatusputa
    final panchasputa = (chatusputa + rahu) % 360;    // Panchasputa
    final pranaSputa = (lag * 5 + moon) % 360;        // Prana Sputa
    final dehaSputa = (moon * 8 + lag) % 360;         // Deha Sputa
    final mrityuSputa = (lag * 7 + sun) % 360;        // Mrityu Sputa
    final sukshmaTrisputa = ((lag + moon + sun) / 3) % 360;  // Sukshma Trisputa

    // ─── Upagraha Sputas (Dhuma etc.) ───
    final dhuma = (sun + 133.3333) % 360;             // Dhuma = Sun + 4s13°20'
    final vyatipata = (360 - dhuma) % 360;            // Vyatipata = 360 - Dhuma
    final parivesha = (vyatipata + 180) % 360;        // Parivesha = Vyatipata + 180
    final indrachapa = (360 - parivesha) % 360;       // Indrachapa = 360 - Parivesha
    final upaketu = (indrachapa + 16.6667) % 360;     // Upaketu = Indrachapa + 0s16°40'

    // ─── Aroodha & Related ───
    final aroRashi = (_pruchaka - 1) ~/ 9;
    final lagMod = lag % 30;
    final aroodha = (aroRashi * 30) + lagMod;
    final vithi = (aroodha + lag) % 360;
    final chatra = (aroodha + lag - sun) % 360;

    // ─── Beeja & Kshetra Sputas (Fertility) ───
    final beeja1 = (sun + jup + ven) % 360;           // BeejaSputa 1 (male fertility)
    final beeja2 = (sun + moon + lag) % 360;           // BeejaSputa 2
    final beeja3 = (sun + moon + ven + jup) % 360;     // BeejaSputa 3
    final kshetra1 = (moon + mars + jup) % 360;        // KshetraSputa 1 (female fertility)
    final kshetra2 = (jup + moon) % 360;               // KshetraSputa 2
    final kshetra3 = (moon + ven + mars) % 360;        // KshetraSputa 3

    // ─── Santana Sputas (Progeny) ───
    final santana1 = ((moon * 5) - (sun * 5)) % 360;  // Panchagna
    final santana2 = moon;                              // Chandra Sputa
    final santana3 = (sun + moon) % 360;               // Raveendha

    // ─── Temple/Devalaya Sputas ───
    final prasada = (lag + sun + moon + sat) % 360;
    final ankana = (prasada + mars) % 360;
    final mukha = (prasada + mer) % 360;
    final deepa = (prasada + jup) % 360;
    final acharya = (prasada + ven) % 360;
    final devalaka = (prasada + sat) % 360;
    final dhwajaSp = (prasada + rahu) % 360;

    // ─── Additional Sputas ───
    final chalana = (moon + rahu + lag) % 360;
    final karana = (sun + rahu + lag) % 360;
    final kala = (sun + sat + rahu) % 360;
    final maranashani = sat; // Marana Shani = Saturn's longitude

    return [
      {'name':'① ತ್ರಿಸ್ಫುಟ (Trisputa)','value':_fmt(trisputa)},
      {'name':'② ಚತುಸ್ಫುಟ (Chatusputa)','value':_fmt(chatusputa)},
      {'name':'③ ಪಂಚಸ್ಫುಟ (Panchasputa)','value':_fmt(panchasputa)},
      {'name':'④ ಪ್ರಾಣ ಸ್ಫುಟ (Prana)','value':_fmt(pranaSputa)},
      {'name':'⑤ ದೇಹ ಸ್ಫುಟ (Deha)','value':_fmt(dehaSputa)},
      {'name':'⑥ ಮೃತ್ಯು ಸ್ಫುಟ (Mrityu)','value':_fmt(mrityuSputa)},
      {'name':'⑦ ಸೂಕ್ಷ್ಮ ತ್ರಿಸ್ಫುಟ','value':_fmt(sukshmaTrisputa)},
      {'name':'━━ ಉಪಗ್ರಹ ━━','value':'━━━━━━━'},
      {'name':'⑧ ಧೂಮ (Dhuma)','value':_fmt(dhuma)},
      {'name':'⑨ ವ್ಯತೀಪಾತ (Vyatipata)','value':_fmt(vyatipata)},
      {'name':'⑩ ಪರಿವೇಷ (Parivesha)','value':_fmt(parivesha)},
      {'name':'⑪ ಇಂದ್ರಚಾಪ (Indrachapa)','value':_fmt(indrachapa)},
      {'name':'⑫ ಉಪಕೇತು (Upaketu)','value':_fmt(upaketu)},
      {'name':'━━ ಬೀಜ/ಕ್ಷೇತ್ರ ━━','value':'━━━━━━━'},
      {'name':'⑬ ಬೀಜ ಸ್ಫುಟ 1','value':_fmt(beeja1)},
      {'name':'⑭ ಬೀಜ ಸ್ಫುಟ 2','value':_fmt(beeja2)},
      {'name':'⑮ ಬೀಜ ಸ್ಫುಟ 3','value':_fmt(beeja3)},
      {'name':'⑯ ಕ್ಷೇತ್ರ ಸ್ಫುಟ 1','value':_fmt(kshetra1)},
      {'name':'⑰ ಕ್ಷೇತ್ರ ಸ್ಫುಟ 2','value':_fmt(kshetra2)},
      {'name':'⑱ ಕ್ಷೇತ್ರ ಸ್ಫುಟ 3','value':_fmt(kshetra3)},
      {'name':'━━ ಸಂತಾನ ━━','value':'━━━━━━━'},
      {'name':'⑲ ಸಂತಾನ ಸ್ಫುಟ 1 (ಪಂಚಾಗ್ನ)','value':_fmt(santana1)},
      {'name':'⑳ ಸಂತಾನ ಸ್ಫುಟ 2 (ಚಂದ್ರ)','value':_fmt(santana2)},
      {'name':'㉑ ಸಂತಾನ ಸ್ಫುಟ 3 (ರವೀಂದ್ರ)','value':_fmt(santana3)},
      {'name':'━━ ಇತರೆ ━━','value':'━━━━━━━'},
      {'name':'㉒ ಮಾರಣ ಶನಿ','value':_fmt(maranashani)},
      {'name':'㉓ ಆರೂಢ ಸ್ಫುಟ','value':_fmt(aroodha)},
      {'name':'㉔ ವೀಥಿ ಸ್ಫುಟ','value':_fmt(vithi)},
      {'name':'㉕ ಛತ್ರ ಸ್ಫುಟ','value':_fmt(chatra)},
      {'name':'㉖ ಲಗ್ನ ರವಿ ಯೋಗ','value':_fmt((lag + sun) % 360)},
      {'name':'㉗ ಸಾನ್ನಿಧ್ಯ ಸ್ಫುಟ','value':_fmt((moon + rahu) % 360)},
      {'name':'㉘ ಚೈತನ್ಯ ಸ್ಫುಟ','value':_fmt((sun + moon + lag) % 360)},
      {'name':'㉙ ಚಲನ ಸ್ಫುಟ','value':_fmt(chalana)},
      {'name':'㉚ ಕಾರಣಿ ಸ್ಫುಟ','value':_fmt(karana)},
      {'name':'㉛ ಕಾಲ ಸ್ಫುಟ','value':_fmt(kala)},
      {'name':'━━ ದೇವಾಲಯ ━━','value':'━━━━━━━'},
      {'name':'㉜ ಪ್ರಾಸಾದ ಸ್ಫುಟ','value':_fmt(prasada)},
      {'name':'㉝ ಅಂಕಣ ಸ್ಫುಟ','value':_fmt(ankana)},
      {'name':'㉞ ಮುಖ ಮಂಟಪ ಸ್ಫುಟ','value':_fmt(mukha)},
      {'name':'㉟ ದೀಪ ಸ್ಫುಟ','value':_fmt(deepa)},
      {'name':'㊱ ಆಚಾರ್ಯ ಸ್ಫುಟ','value':_fmt(acharya)},
      {'name':'㊲ ದೇವಲಕ ಸ್ಫುಟ','value':_fmt(devalaka)},
      {'name':'㊳ ಧ್ವಜ ಸ್ಫುಟ','value':_fmt(dhwajaSp)},
      {'name':'㊴ ಪ್ರಶ್ನ ಸ್ಫುಟ','value':_fmt((aroodha + lag) % 360)},
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
