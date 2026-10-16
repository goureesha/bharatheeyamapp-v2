import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../constants/places.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';

/// ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ
/// ನೀಡಲಾದ ದಿನಾಂಕ, ಸಮಯ ಮತ್ತು ಸ್ಥಳಕ್ಕೆ ಪಂಚಾಂಗ, ಸಂಪೂರ್ಣ ಷೋಡಶವರ್ಗ ಕುಂಡಲಿಗಳು ಮತ್ತು ಸ್ಫುಟಗಳನ್ನು ಲೆಕ್ಕಾಚಾರ ಮಾಡುತ್ತದೆ.
class AshtamangalaScreen extends StatefulWidget {
  const AshtamangalaScreen({super.key});

  @override
  State<AshtamangalaScreen> createState() => _AshtamangalaScreenState();
}

class _AshtamangalaScreenState extends State<AshtamangalaScreen> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  DateTime _dob = DateTime.now();
  int _hour = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute = DateTime.now().minute;
  String _ampm = DateTime.now().hour < 12 ? 'AM' : 'PM';

  late final TextEditingController _placeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _tzCtrl;

  bool _geoLoading = false;
  String _geoStatus = '';
  bool _calculating = false;

  bool _hasResult = false;
  String _errorMsg = '';
  int _selectedTab = 0; // 0: ಪಂಚಾಂಗ, 1: ಕುಂಡಲಿ, 2: ಸ್ಫುಟ
  int _selectedVargaIdx = 0;
  bool _showAllVargas = false;
  String? _bhavaPlanet;
  bool _inputExpanded = true;

  KundaliResult? _prashnaResult;

  // ೧೬ ಪಾರಾಶರಿ ಷೋಡಶವರ್ಗ ಕುಂಡಲಿಗಳು + ಭಾವ ಕುಂಡಲಿ (ಕನ್ನಡದಲ್ಲಿ ಮಾತ್ರ)
  static const List<Map<String, dynamic>> _shodashaVargaCharts = [
    {'name': 'ರಾಶಿ', 'fullName': 'ರಾಶಿ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': false},
    {'name': 'ಹೋರಾ', 'fullName': 'ಹೋರಾ ಕುಂಡಲಿ', 'varga': 2, 'isBhava': false},
    {'name': 'ದ್ರೆಕ್ಕಾಣ', 'fullName': 'ದ್ರೆಕ್ಕಾಣ ಕುಂಡಲಿ', 'varga': 3, 'isBhava': false},
    {'name': 'ಚತುರ್ಥಾಂಶ', 'fullName': 'ಚತುರ್ಥಾಂಶ ಕುಂಡಲಿ', 'varga': 4, 'isBhava': false},
    {'name': 'ಸಪ್ತಾಂಶ', 'fullName': 'ಸಪ್ತಾಂಶ ಕುಂಡಲಿ', 'varga': 7, 'isBhava': false},
    {'name': 'ನವಾಂಶ', 'fullName': 'ನವಾಂಶ ಕುಂಡಲಿ', 'varga': 9, 'isBhava': false},
    {'name': 'ದಶಾಂಶ', 'fullName': 'ದಶಾಂಶ ಕುಂಡಲಿ', 'varga': 10, 'isBhava': false},
    {'name': 'ದ್ವಾದಶಾಂಶ', 'fullName': 'ದ್ವಾದಶಾಂಶ ಕುಂಡಲಿ', 'varga': 12, 'isBhava': false},
    {'name': 'ಷೋಡಶಾಂಶ', 'fullName': 'ಷೋಡಶಾಂಶ ಕುಂಡಲಿ', 'varga': 16, 'isBhava': false},
    {'name': 'ವಿಂಶಾಂಶ', 'fullName': 'ವಿಂಶಾಂಶ ಕುಂಡಲಿ', 'varga': 20, 'isBhava': false},
    {'name': 'ಚತುರ್ವಿಂಶಾಂಶ', 'fullName': 'ಚತುರ್ವಿಂಶಾಂಶ ಕುಂಡಲಿ', 'varga': 24, 'isBhava': false},
    {'name': 'ಸಪ್ತವಿಂಶಾಂಶ', 'fullName': 'ಸಪ್ತವಿಂಶಾಂಶ (ಭಾಂಶ) ಕುಂಡಲಿ', 'varga': 27, 'isBhava': false},
    {'name': 'ತ್ರಿಂಶಾಂಶ', 'fullName': 'ತ್ರಿಂಶಾಂಶ ಕುಂಡಲಿ', 'varga': 30, 'isBhava': false},
    {'name': 'ಖವೇದಾಂಶ', 'fullName': 'ಖವೇದಾಂಶ ಕುಂಡಲಿ', 'varga': 40, 'isBhava': false},
    {'name': 'ಅಕ್ಷವೇದಾಂಶ', 'fullName': 'ಅಕ್ಷವೇದಾಂಶ ಕುಂಡಲಿ', 'varga': 45, 'isBhava': false},
    {'name': 'ಷಷ್ಟ್ಯಂಶ', 'fullName': 'ಷಷ್ಟ್ಯಂಶ ಕುಂಡಲಿ', 'varga': 60, 'isBhava': false},
    {'name': 'ಭಾವ', 'fullName': 'ಭಾವ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': true},
  ];

  @override
  void initState() {
    super.initState();
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    _tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
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
            _geoStatus = '📍 $displayName';
          });
        } else {
          if (mounted) _showPlaceDisambiguation(data);
        }
      } else {
        setState(() => _geoStatus = 'ಸರ್ವರ್ ದೋಷ: ${resp.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _geoStatus = 'ದೋಷ: $e');
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
                  _geoStatus = '📍 ${r['display_name']}';
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

  Future<void> _calculate() async {
    setState(() {
      _calculating = true;
      _errorMsg = '';
    });

    try {
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

      if (result != null && mounted) {
        setState(() {
          _prashnaResult = result;
          _hasResult = true;
          _errorMsg = '';
          _inputExpanded = false;
        });
      } else {
        setState(() {
          _errorMsg = 'ಕುಂಡಲಿ ಲೆಕ್ಕಾಚಾರ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ವಿವರಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.';
          _hasResult = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'ದೋಷ: $e';
        _hasResult = false;
      });
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  void _showPlanetDetail(String pName) {
    if (_prashnaResult == null) return;
    final info = _prashnaResult!.planets[pName];
    if (info == null) return;
    final sun = _prashnaResult!.planets['ರವಿ'];
    final detail = AstroCalculator.getPlanetDetail(
      pName, info.longitude, info.speed, sun?.longitude ?? 0.0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanetDetailSheet(pName: pName, detail: detail),
    );
  }

  Map<String, Color> get _dashaLords {
    if (_prashnaResult == null) return {};
    final now = DateTime.now();
    final lords = <String, Color>{};
    for (final md in _prashnaResult!.dashas) {
      if (now.isAfter(md.start) && now.isBefore(md.end)) {
        lords[md.lord] = const Color(0xFFFF8C00);
        for (final ad in md.antardashas) {
          if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
            if (!lords.containsKey(ad.lord)) {
              lords[ad.lord] = const Color(0xFF00C853);
            }
            break;
          }
        }
        break;
      }
    }
    return lords;
  }

  String _trDashaBalance(String bal) {
    if (AppLocale.current == 'kn') return bal;
    const suffixes = {
      'hi': {'ವ': 'व', 'ತಿ': 'म', 'ದಿ': 'दि'},
      'ta': {'ವ': 'வ', 'ತಿ': 'மா', 'ದಿ': 'நா'},
      'te': {'ವ': 'సం', 'ತಿ': 'నె', 'ದಿ': 'రో'},
      'ml': {'ವ': 'വ', 'ತಿ': 'മാ', 'ದಿ': 'ദി'},
    };
    final map = suffixes[AppLocale.current];
    if (map == null) return bal;
    var result = bal;
    for (final entry in map.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  String _formatKannadaTime() {
    final ampmKn = _ampm == 'AM' ? 'ಪೂರ್ವಾಹ್ನ' : 'ಅಪರಾಹ್ನ';
    return '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $ampmKn';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text(
          'ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ',
          style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
        actions: [
          if (_hasResult)
            IconButton(
              icon: Icon(_inputExpanded ? Icons.expand_less : Icons.expand_more, color: kPurple2),
              tooltip: _inputExpanded ? 'ಮಾಹಿತಿ ಮುಚ್ಚಿ' : 'ಮಾಹಿತಿ ವೀಕ್ಷಿಸಿ',
              onPressed: () => setState(() => _inputExpanded = !_inputExpanded),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          child: Column(
            children: [
              _buildInputCard(),
              if (_hasResult && _prashnaResult != null) ...[
                const SizedBox(height: 8),
                _buildOutputTabBar(),
                const SizedBox(height: 8),
                if (_selectedTab == 0)
                  _buildPanchangTab()
                else if (_selectedTab == 1)
                  _buildKundaliTab()
                else
                  _buildSphutaTab(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ ಮಾಹಿತಿ ನಮೂದು ಕಾರ್ಡ್ (Input Card) ═══
  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('🪔', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ಪ್ರಶ್ನ ವಿವರ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kOrange),
                ),
              ),
              if (_hasResult)
                IconButton(
                  icon: Icon(_inputExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: kMuted),
                  onPressed: () => setState(() => _inputExpanded = !_inputExpanded),
                ),
            ],
          ),
          if (!_inputExpanded && _hasResult) ...[
            const SizedBox(height: 4),
            Text(
              '${_dob.day.toString().padLeft(2, '0')}-${_dob.month.toString().padLeft(2, '0')}-${_dob.year}  •  ${_formatKannadaTime()}  •  ${_placeCtrl.text}',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
          if (_inputExpanded || !_hasResult) ...[
            const SizedBox(height: 12),
            // Querent Name
            _inputField(_nameCtrl, 'ಪ್ರುಚ್ಛಕರ ಹೆಸರು', Icons.person),
            const SizedBox(height: 12),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: kPurple2, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ದಿನಾಂಕ: ${_dob.day.toString().padLeft(2, '0')}-${_dob.month.toString().padLeft(2, '0')}-${_dob.year}',
                              style: TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: kCard,
                        border: Border.all(color: kBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, color: kPurple2, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ಸಮಯ: ${_formatKannadaTime()}',
                              style: TextStyle(fontSize: 13, color: kText, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Place Selector
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return offlinePlaces.keys.take(15);
                final query = textEditingValue.text.toLowerCase();
                return offlinePlaces.keys.where((n) => n.toLowerCase().contains(query));
              },
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'ಊರು ಹುಡುಕಿ',
                    prefixIcon: Icon(Icons.search, size: 20),
                    suffixIcon: _geoLoading
                        ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                        : IconButton(
                            icon: Icon(Icons.my_location, color: kTeal, size: 20),
                            onPressed: () {
                              _placeCtrl.text = textEditingController.text;
                              _geocodeMultiple(textEditingController.text);
                            },
                          ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    _placeCtrl.text = textEditingController.text;
                    _geocodeMultiple(textEditingController.text);
                  },
                );
              },
              onSelected: (String selection) async {
                if (offlinePlaces.containsKey(selection)) {
                  final coords = offlinePlaces[selection]!;
                  final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
                  setState(() {
                    _placeCtrl.text = selection;
                    _latCtrl.text = coords[0].toStringAsFixed(4);
                    _lonCtrl.text = coords[1].toStringAsFixed(4);
                    _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                    _geoStatus = '📍 $selection';
                  });
                }
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.location_on, size: 18, color: kPurple2),
                            title: Text(option, style: TextStyle(fontSize: 13)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_geoStatus.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
            ],
            const SizedBox(height: 10),

            // Lat/Lon/TZ Display
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'ಅಕ್ಷಾಂಶ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(8),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _lonCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'ರೇಖಾಂಶ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(8),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _tzCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: 'ಸಮಯ ವಲಯ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(8),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Optional Ashtamangala Number
            TextField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ (ಐಚ್ಛಿಕ)',
                prefixIcon: Icon(Icons.pin, color: kMuted, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700),
              onSubmitted: (_) => _calculate(),
            ),
            if (_errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorMsg, style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 14),

            // Calculate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculating ? null : _calculate,
                icon: _calculating
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.calculate, size: 20),
                label: Text(
                  _calculating ? 'ಲೆಕ್ಕಾಚಾರವಾಗುತ್ತಿದೆ...' : 'ಲೆಕ್ಕ ಹಾಕಿ',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kMuted, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    style: TextStyle(color: kText, fontSize: 14),
  );

  // ═══ ಟ್ಯಾಬ್ ಆಯ್ಕೆ (Output Tabs Switcher: ಪಂಚಾಂಗ, ಕುಂಡಲಿ, ಸ್ಫುಟ) ═══
  Widget _buildOutputTabBar() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _buildTabBtn(0, Icons.calendar_month, 'ಪಂಚಾಂಗ'),
          _buildTabBtn(1, Icons.grid_view, 'ಕುಂಡಲಿ'),
          _buildTabBtn(2, Icons.auto_graph, 'ಸ್ಫುಟ'),
        ],
      ),
    );
  }

  Widget _buildTabBtn(int index, IconData icon, String title) {
    final isSel = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSel ? kPurple2 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: isSel ? kPurple2 : kMuted),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSel ? kPurple2 : kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ ಟ್ಯಾಬ್ ೧: ಪಂಚಾಂಗ ═══
  Widget _buildPanchangTab() {
    if (_prashnaResult == null) return const SizedBox.shrink();
    final r = _prashnaResult!;
    final pan = r.panchang;
    final pName = _nameCtrl.text.trim();
    final dateStr = '${_dob.day.toString().padLeft(2, "0")}-${_dob.month.toString().padLeft(2, "0")}-${_dob.year}';
    final timeStr = _formatKannadaTime();

    // ವಯಸ್ಸು ಲೆಕ್ಕಾಚಾರ
    final now = DateTime.now();
    int ageYears = now.year - _dob.year;
    int ageMonths = now.month - _dob.month;
    int ageDays = now.day - _dob.day;
    if (ageDays < 0) {
      ageMonths--;
      final prevMonth = DateTime(now.year, now.month, 0);
      ageDays += prevMonth.day;
    }
    if (ageMonths < 0) {
      ageYears--;
      ageMonths += 12;
    }
    final ageStr = '$ageYears ವರ್ಷ $ageMonths ತಿಂಗಳು $ageDays ದಿನ';

    // ಪ್ರಸ್ತುತ ದಶಾ ಮತ್ತು ಭುಕ್ತಿ
    String currentDasha = '';
    String dashaEnd = '';
    String currentBhukti = '';
    String bhuktiEnd = '';
    for (final md in r.dashas) {
      if (now.isAfter(md.start) && now.isBefore(md.end)) {
        currentDasha = trAll(md.lord);
        dashaEnd = '${md.end.day.toString().padLeft(2, "0")}-${md.end.month.toString().padLeft(2, "0")}-${md.end.year}';
        for (final ad in md.antardashas) {
          if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
            currentBhukti = trAll(ad.lord);
            bhuktiEnd = '${ad.end.day.toString().padLeft(2, "0")}-${ad.end.month.toString().padLeft(2, "0")}-${ad.end.year}';
            break;
          }
        }
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ವಿವರ ಕಾರ್ಡ್
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pName.isNotEmpty) _kv(AppLocale.l('nameLabel'), pName),
              _kv(AppLocale.l('placeLabel'), _placeCtrl.text),
              _kv(AppLocale.l('dateLabel'), dateStr),
              _kv(AppLocale.l('timeLabel'), timeStr),
              if (_numberCtrl.text.trim().isNotEmpty)
                _kv('ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ', _numberCtrl.text.trim()),
              _kv(AppLocale.l('dashaLord'), '${trAll(pan.dashaLord)}  ${AppLocale.l('dashaBalance')}: ${_trDashaBalance(pan.dashaBalance)}'),
              const Divider(height: 16),
              _kv(AppLocale.l('ageLabel'), ageStr),
              if (currentDasha.isNotEmpty) ...[
                const Divider(height: 16),
                _kv('ಪ್ರಸ್ತುತ ದಶಾ', '$currentDasha  (ಅಂತ್ಯ: $dashaEnd)'),
                if (currentBhukti.isNotEmpty)
                  _kv(AppLocale.l('bhuktiLabel'), '$currentBhukti  (ಅಂತ್ಯ: $bhuktiEnd)'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── 📋 ಪಂಚಾಂಗ (೫ ಅಂಗ) ──
        _sectionLabel('📋 ${AppLocale.l('pHeading')}', kPurple2),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _tableRow([AppLocale.l('varaLabel'), trAll(pan.vara)]),
              _tableRow([AppLocale.l('tithiLabel'), '${trAll(pan.tithi)}${pan.tithiGata.isNotEmpty || pan.tithiParama.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.tithiGata}, ${AppLocale.l('paramaGhati')}: ${pan.tithiParama})' : ''}']),
              _tableRow([
                AppLocale.l('chandraNakshatra'),
                () {
                  final moonPada = r.planets['ಚಂದ್ರ']?.pada;
                  final fallback = (pan.nakPercent * 4).floor() + 1;
                  final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback);
                  return '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} $p';
                }()
              ]),
              _tableRow([AppLocale.l('yogaLabel'), '${trAll(pan.yoga)}${pan.yogaGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.yogaGata})' : ''}']),
              _tableRow([AppLocale.l('karanaLabel'), '${trAll(pan.karana)}${pan.karanaGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.karanaGata})' : ''}']),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── ☀️ ರವಿ ವಿವರ ──
        _sectionLabel('☀️ ${AppLocale.l('raviVivar')}', Colors.orange),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _tableRow([AppLocale.l('sunrise'), pan.sunrise]),
              _tableRow([AppLocale.l('sunset'), pan.sunset]),
              _tableRow([AppLocale.l('divamana'), pan.divamana]),
              _tableRow([AppLocale.l('ratrimana'), pan.ratrimana]),
              _tableRow([AppLocale.l('udayadiGhati'), pan.udayadiGhati]),
              _tableRow([AppLocale.l('suryaNakshatraLabel'), '${trAll(pan.suryaNakshatra)} - ${AppLocale.l('padaLabel')} ${pan.suryaPada}']),
              _tableRow([AppLocale.l('souraMasa'), trAll(pan.souraMasa)]),
              _tableRow([AppLocale.l('souraMasaGataDina'), pan.souraMasaGataDina]),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── 🌙 ಚಂದ್ರ ವಿವರ ──
        _sectionLabel('🌙 ${AppLocale.l('chandraVivar')}', Colors.blue),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _tableRow([
                AppLocale.l('chandraNakshatra'),
                () {
                  final moonPada = r.planets['ಚಂದ್ರ']?.pada;
                  final fallback = (pan.nakPercent * 4).floor() + 1;
                  final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback);
                  return '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} $p (${AppLocale.l('gataGhati')}: ${pan.gataGhati}, ${AppLocale.l('paramaGhati')}: ${pan.paramaGhati})';
                }()
              ]),
              _tableRow([AppLocale.l('chandraRashiLabel'), trAll(pan.chandraRashi)]),
              _tableRow([AppLocale.l('chandraMasa'), trAll(pan.chandraMasa)]),
              _tableRow([AppLocale.l('samvatsara'), trAll(pan.samvatsara)]),
              _tableRow([AppLocale.l('tithiLabel'), '${trAll(pan.tithi)}${pan.tithiGata.isNotEmpty || pan.tithiParama.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.tithiGata}, ${AppLocale.l('paramaGhati')}: ${pan.tithiParama})' : ''}']),
              _tableRow([AppLocale.l('gataGhati'), pan.gataGhati]),
              _tableRow([AppLocale.l('paramaGhati'), pan.paramaGhati]),
              _tableRow([AppLocale.l('sheshaGhati'), pan.shesha]),
              _tableRow([AppLocale.l('vishaPraghati'), pan.vishaPraghati]),
              _tableRow([AppLocale.l('amrutaPraghati'), pan.amrutaPraghati]),
            ],
          ),
        ),
      ],
    );
  }

  // ═══ ಟ್ಯಾಬ್ ೨: ಕುಂಡಲಿ (ಸಂಪೂರ್ಣ ಷೋಡಶವರ್ಗ ಕುಂಡಲಿಗಳು) ═══
  Widget _buildKundaliTab() {
    if (_prashnaResult == null) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final chartSize = isLandscape ? (screenWidth * 0.45).clamp(300.0, 500.0) : (screenWidth - 32).clamp(280.0, 480.0);

    final currentChart = _shodashaVargaCharts[_selectedVargaIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ಹೆಡರ್ ಮತ್ತು ನೋಟ ಬದಲಾವಣೆ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ಷೋಡಶವರ್ಗ ಕುಂಡಲಿಗಳು',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kPurple2),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showAllVargas = !_showAllVargas),
                icon: Icon(_showAllVargas ? Icons.view_carousel : Icons.view_stream, size: 18, color: kOrange),
                label: Text(
                  _showAllVargas ? 'ಒಂದೊಂದಾಗಿ' : 'ಎಲ್ಲಾ ಕುಂಡಲಿಗಳು',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kOrange),
                ),
              ),
            ],
          ),
        ),

        // ವರ್ಗ ಆಯ್ಕೆ ಚಿಪ್ಸ್‌ಗಳು (ಕನ್ನಡದಲ್ಲಿ ಮಾತ್ರ)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: List.generate(_shodashaVargaCharts.length, (i) {
              final c = _shodashaVargaCharts[i];
              final isSel = !_showAllVargas && _selectedVargaIdx == i;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text('${c['name']}'),
                  selected: isSel,
                  selectedColor: kPurple2,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                    color: isSel ? Colors.white : kText,
                  ),
                  backgroundColor: kCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isSel ? kPurple2 : kBorder),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedVargaIdx = i;
                        _showAllVargas = false;
                      });
                    }
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),

        if (!_showAllVargas) ...[
          // ಏಕ ಕುಂಡಲಿ ನೋಟ (ಹಿಂದೆ / ಮುಂದೆ ನ್ಯಾವಿಗೇಷನ್)
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 18, color: _selectedVargaIdx > 0 ? kPurple2 : kMuted),
                      tooltip: 'ಹಿಂದಿನ ಕುಂಡಲಿ',
                      onPressed: _selectedVargaIdx > 0
                          ? () => setState(() => _selectedVargaIdx--)
                          : null,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            currentChart['fullName'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_selectedVargaIdx + 1} / ${_shodashaVargaCharts.length}',
                            style: TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios, size: 18, color: _selectedVargaIdx < _shodashaVargaCharts.length - 1 ? kPurple2 : kMuted),
                      tooltip: 'ಮುಂದಿನ ಕುಂಡಲಿ',
                      onPressed: _selectedVargaIdx < _shodashaVargaCharts.length - 1
                          ? () => setState(() => _selectedVargaIdx++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: _buildChartWidget(currentChart),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ಗ್ರಹದ ಮೇಲೆ ಟ್ಯಾಪ್ ಮಾಡಿ ಹೆಚ್ಚಿನ ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
                  style: TextStyle(fontSize: 11, color: kMuted),
                ),
              ],
            ),
          ),
        ] else ...[
          // ಎಲ್ಲಾ ಕುಂಡಲಿಗಳು ಒಂದರ ಕೆಳಗೆ ಒಂದು
          ..._shodashaVargaCharts.map((chart) {
            return AppCard(
              child: Column(
                children: [
                  Text(
                    chart['fullName'] as String,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPurple2),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: _buildChartWidget(chart),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildChartWidget(Map<String, dynamic> chart) {
    final varga = chart['varga'] as int;
    final isBhava = chart['isBhava'] as bool;
    final label = chart['fullName'] as String;

    return KundaliChart(
      result: _prashnaResult!,
      varga: varga,
      isBhava: isBhava,
      showSphutas: false,
      showNavamshaNumber: true, // ತೋರಿಸು: ಏಕಾಕ್ಷರ ಗ್ರಹ ಹೆಸರು + ನವಾಂಶ ಸಂಖ್ಯೆ
      centerLabel: label,
      onPlanetTap: _showPlanetDetail,
      selectedPlanet: isBhava ? _bhavaPlanet : null,
      onPlanetLongPress: isBhava ? (pName) {
        setState(() => _bhavaPlanet = _bhavaPlanet == pName ? null : pName);
      } : null,
      bhavaFromPlanet: isBhava ? _bhavaPlanet : null,
      highlightPlanets: _dashaLords,
    );
  }

  // ═══ ಟ್ಯಾಬ್ ೩: ಸ್ಫುಟ (ಗ್ರಹ ಸ್ಫುಟ ಮತ್ತು ಇತರ ಸ್ಫುಟಗಳು) ═══
  Widget _buildSphutaTab() {
    if (_prashnaResult == null) return const SizedBox.shrink();
    final r = _prashnaResult!;
    final pMap = r.planets;
    final lag = pMap['ಲಗ್ನ']?.longitude ?? 0.0;
    final sun = pMap['ರವಿ']?.longitude ?? 0.0;
    final moon = pMap['ಚಂದ್ರ']?.longitude ?? 0.0;
    final jup = pMap['ಗುರು']?.longitude ?? 0.0;

    // ಹೆಚ್ಚುವರಿ ಪ್ರಶ್ನಾ ಸ್ಫುಟಗಳು
    final trisphuta = (lag + moon + jup) % 360;
    final chatusphuta = (trisphuta + sun) % 360;
    final aroodha = (lag + 30) % 360; // ಆರೂಢ ಸ್ಫುಟ
    final chatra = (aroodha + lag - sun + 360) % 360; // ಛತ್ರ ಸ್ಫುಟ

    // ಗ್ರಹಗಳ ಪಟ್ಟಿ
    const grahaList = [
      'ಲಗ್ನ', 'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ',
      'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು', 'ಮಾಂದಿ'
    ];

    // ಉಪಗ್ರಹ ಮತ್ತು ವಿಶೇಷ ಸ್ಫುಟಗಳ ಪಟ್ಟಿ
    final otherSphutas = <Map<String, dynamic>>[
      {'name': 'ತ್ರಿಸ್ಫುಟ', 'deg': r.advSphutas['ತ್ರಿಸ್ಫುಟ'] ?? trisphuta},
      {'name': 'ಚತುಃಸ್ಫುಟ', 'deg': r.advSphutas['ಚತುಃಸ್ಫುಟ'] ?? chatusphuta},
      {'name': 'ಪಂಚಸ್ಫುಟ', 'deg': r.advSphutas['ಪಂಚಸ್ಫುಟ'] ?? ((chatusphuta + (pMap['ರಾಹು']?.longitude ?? 0.0)) % 360)},
      {'name': 'ಪ್ರಾಣ ಸ್ಫುಟ', 'deg': r.advSphutas['ಪ್ರಾಣ'] ?? ((lag * 5 + moon) % 360)},
      {'name': 'ದೇಹ ಸ್ಫುಟ', 'deg': r.advSphutas['ದೇಹ'] ?? ((moon * 8 + lag) % 360)},
      {'name': 'ಮೃತ್ಯು ಸ್ಫುಟ', 'deg': r.advSphutas['ಮೃತ್ಯು'] ?? ((lag * 7 + sun) % 360)},
      {'name': 'ಸೂಕ್ಷ್ಮ ತ್ರಿಸ್ಫುಟ', 'deg': r.advSphutas['ಸೂಕ್ಷ್ಮ ತ್ರಿ.'] ?? (((lag + moon + sun) / 3) % 360)},
      {'name': 'ಆರೂಢ ಸ್ಫುಟ', 'deg': aroodha},
      {'name': 'ಛತ್ರ ಸ್ಫುಟ', 'deg': chatra},
      {'name': 'ಧೂಮ', 'deg': r.advSphutas['ಧೂಮ'] ?? ((sun + 133.3333) % 360)},
      {'name': 'ವ್ಯತೀಪಾತ', 'deg': r.advSphutas['ವ್ಯತೀಪಾತ'] ?? ((360 - (r.advSphutas['ಧೂಮ'] ?? ((sun + 133.3333) % 360))) % 360)},
      {'name': 'ಪರಿವೇಷ', 'deg': r.advSphutas['ಪರಿವೇಷ'] ?? 0.0},
      {'name': 'ಇಂದ್ರಚಾಪ', 'deg': r.advSphutas['ಇಂದ್ರಚಾಪ'] ?? 0.0},
      {'name': 'ಉಪಕೇತು', 'deg': r.advSphutas['ಉಪಕೇತು'] ?? 0.0},
      {'name': 'ಭೃಗು ಬಿಂದು', 'deg': r.advSphutas['ಭೃಗು ಬಿ.'] ?? 0.0},
      {'name': 'ಬೀಜ ಸ್ಫುಟ', 'deg': r.advSphutas['ಬೀಜ'] ?? 0.0},
      {'name': 'ಕ್ಷೇತ್ರ ಸ್ಫುಟ', 'deg': r.advSphutas['ಕ್ಷೇತ್ರ'] ?? 0.0},
      {'name': 'ಯೋಗಿ ಸ್ಫುಟ', 'deg': r.advSphutas['ಯೋಗಿ'] ?? 0.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ಗ್ರಹ ಸ್ಫುಟ ──
        _sectionLabel('🪐 ಗ್ರಹ ಸ್ಫುಟ', kPurple2),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _tableHeader(['ಗ್ರಹ', 'ರಾಶಿ', 'ಸ್ಫುಟ', 'ನಕ್ಷತ್ರ - ಪಾದ', 'ಗತಿ']),
              ...grahaList.map((p) {
                final info = pMap[p];
                if (info == null) return const SizedBox.shrink();
                final ri = (info.longitude / 30).floor() % 12;
                final rashiName = knRashi[ri];
                final sphutaDeg = formatDeg(info.longitude);
                final nakPada = '${info.nakshatra} - ${info.pada}';
                String gati;
                if (p == 'ಲಗ್ನ' || p == 'ಮಾಂದಿ') {
                  gati = '-';
                } else if (p == 'ರಾಹು' || p == 'ಕೇತು') {
                  gati = 'ವಕ್ರಿ';
                } else {
                  gati = (info.speed < 0 ? 'ವಕ್ರಿ' : 'ನೇರ') + (info.isCombust ? ' (ಅಸ್ತ)' : '');
                }

                return _tableRow([
                  p,
                  rashiName,
                  sphutaDeg,
                  nakPada,
                  gati,
                ], bold0: true);
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── ಉಪಗ್ರಹ ಮತ್ತು ವಿಶೇಷ ಸ್ಫುಟಗಳು ──
        _sectionLabel('✨ ಉಪಗ್ರಹ ಮತ್ತು ಇತರ ಸ್ಫುಟಗಳು', kTeal),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _tableHeader(['ಸ್ಫುಟ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ - ಪಾದ']),
              ...otherSphutas.map((item) {
                final name = item['name'] as String;
                final deg = (item['deg'] as num).toDouble() % 360;
                final ri = (deg / 30).floor() % 12;
                final rashiName = knRashi[ri];
                final sphutaDeg = formatDeg(deg);
                final nakIdx = (deg / 13.333333).floor() % 27;
                final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                final nakPada = '${knNak[nakIdx]} - $pada';

                return _tableRow([
                  name,
                  rashiName,
                  sphutaDeg,
                  nakPada,
                ], bold0: true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ═══ ಸಹಾಯಕ ವಿಜೆಟ್‌ಗಳು (Helper UI Widgets) ═══
  Widget _tableHeader(List<String> cols) {
    return Container(
      color: kPurple2.withOpacity(0.12),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              e.value,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: kText),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _tableRow(List<String> cols, {bool bold0 = false}) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: (e.key == 0 && bold0) ? FontWeight.w700 : FontWeight.normal,
                color: kText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple2)),
          Expanded(child: Text(v, style: TextStyle())),
        ],
      ),
    );
  }
}
