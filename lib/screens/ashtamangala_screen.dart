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

/// Ashtamangala Prashna Screen
/// Calculates Panchanga & full Shodashavarga Kundali for given Prashna date, time & place.
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
  int _selectedTab = 0; // 0: Panchanga, 1: Kundali (Shodashavarga)
  int _selectedVargaIdx = 0; // index into Shodashavarga charts list
  bool _showAllVargas = false; // toggle single chart vs all charts stacked
  String? _bhavaPlanet;
  bool _inputExpanded = true;

  KundaliResult? _prashnaResult;

  // 16 classical Shodashavarga charts (Parashari BPHS) + Bhava
  static const List<Map<String, dynamic>> _shodashaVargaCharts = [
    {'code': 'D1', 'name': 'ರಾಶಿ', 'fullName': 'ರಾಶಿ ಕುಂಡಲಿ (D-1)', 'varga': 1, 'isBhava': false},
    {'code': 'D2', 'name': 'ಹೋರಾ', 'fullName': 'ಹೋರಾ ಕುಂಡಲಿ (D-2)', 'varga': 2, 'isBhava': false},
    {'code': 'D3', 'name': 'ದ್ರೆಕ್ಕಾಣ', 'fullName': 'ದ್ರೆಕ್ಕಾಣ ಕುಂಡಲಿ (D-3)', 'varga': 3, 'isBhava': false},
    {'code': 'D4', 'name': 'ಚತುರ್ಥಾಂಶ', 'fullName': 'ಚತುರ್ಥಾಂಶ ಕುಂಡಲಿ (D-4)', 'varga': 4, 'isBhava': false},
    {'code': 'D7', 'name': 'ಸಪ್ತಾಂಶ', 'fullName': 'ಸಪ್ತಾಂಶ ಕುಂಡಲಿ (D-7)', 'varga': 7, 'isBhava': false},
    {'code': 'D9', 'name': 'ನವಾಂಶ', 'fullName': 'ನವಾಂಶ ಕುಂಡಲಿ (D-9)', 'varga': 9, 'isBhava': false},
    {'code': 'D10', 'name': 'ದಶಾಂಶ', 'fullName': 'ದಶಾಂಶ ಕುಂಡಲಿ (D-10)', 'varga': 10, 'isBhava': false},
    {'code': 'D12', 'name': 'ದ್ವಾದಶಾಂಶ', 'fullName': 'ದ್ವಾದಶಾಂಶ ಕುಂಡಲಿ (D-12)', 'varga': 12, 'isBhava': false},
    {'code': 'D16', 'name': 'ಷೋಡಶಾಂಶ', 'fullName': 'ಷೋಡಶಾಂಶ ಕುಂಡಲಿ (D-16)', 'varga': 16, 'isBhava': false},
    {'code': 'D20', 'name': 'ವಿಂಶಾಂಶ', 'fullName': 'ವಿಂಶಾಂಶ ಕುಂಡಲಿ (D-20)', 'varga': 20, 'isBhava': false},
    {'code': 'D24', 'name': 'ಚತುರ್ವಿಂಶಾಂಶ', 'fullName': 'ಚತುರ್ವಿಂಶಾಂಶ ಕುಂಡಲಿ (D-24)', 'varga': 24, 'isBhava': false},
    {'code': 'D27', 'name': 'ಸಪ್ತವಿಂಶಾಂಶ', 'fullName': 'ಸಪ್ತವಿಂಶಾಂಶ / ಭಾಂಶ (D-27)', 'varga': 27, 'isBhava': false},
    {'code': 'D30', 'name': 'ತ್ರಿಂಶಾಂಶ', 'fullName': 'ತ್ರಿಂಶಾಂಶ ಕುಂಡಲಿ (D-30)', 'varga': 30, 'isBhava': false},
    {'code': 'D40', 'name': 'ಖವೇದಾಂಶ', 'fullName': 'ಖವೇದಾಂಶ ಕುಂಡಲಿ (D-40)', 'varga': 40, 'isBhava': false},
    {'code': 'D45', 'name': 'ಅಕ್ಷವೇದಾಂಶ', 'fullName': 'ಅಕ್ಷವೇದಾಂಶ ಕುಂಡಲಿ (D-45)', 'varga': 45, 'isBhava': false},
    {'code': 'D60', 'name': 'ಷಷ್ಟ್ಯಂಶ', 'fullName': 'ಷಷ್ಟ್ಯಂಶ ಕುಂಡಲಿ (D-60)', 'varga': 60, 'isBhava': false},
    {'code': 'ಭಾವ', 'name': 'ಭಾವ ಕುಂಡಲಿ', 'fullName': 'ಭಾವ ಕುಂಡಲಿ (Bhava)', 'varga': 1, 'isBhava': true},
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
          _inputExpanded = false; // Collapse input card to highlight output
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
      pName, info.longitude, info.speed, sun?.longitude ?? 0);
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
        lords[md.lord] = const Color(0xFFFF8C00); // Orange for Dasha
        for (final ad in md.antardashas) {
          if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
            if (!lords.containsKey(ad.lord)) {
              lords[ad.lord] = const Color(0xFF00C853); // Green for Bhukti
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
                else
                  _buildKundaliTab(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ Input Card ═══
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
                  'ಪ್ರಶ್ನ ವಿವರ / Prashna Details',
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
              '${_dob.day.toString().padLeft(2, '0')}-${_dob.month.toString().padLeft(2, '0')}-${_dob.year}  •  ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $_ampm  •  ${_placeCtrl.text}',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
          if (_inputExpanded || !_hasResult) ...[
            const SizedBox(height: 12),
            // Querent Name
            _inputField(_nameCtrl, 'ಪ್ರುಚ್ಛಕ ಹೆಸರು / Querent Name', Icons.person),
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
                              '${_dob.day.toString().padLeft(2, '0')}-${_dob.month.toString().padLeft(2, '0')}-${_dob.year}',
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
                              '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $_ampm',
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
                    labelText: 'ಊರು ಹುಡುಕಿ / Search Location',
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
                    _geoStatus = '📍 $selection (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
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
                      labelText: 'ಅಕ್ಷಾಂಶ (Lat)',
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
                      labelText: 'ರೇಖಾಂಶ (Lon)',
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
                      labelText: 'TZ Offset',
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
                labelText: 'ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ / Ashtamangala Number (ಐಚ್ಛಿಕ/Optional)',
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
                  _calculating ? 'ಲೆಕ್ಕಾಚಾರವಾಗುತ್ತಿದೆ...' : 'ಲೆಕ್ಕ ಹಾಕಿ / Calculate Kundali',
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

  // ═══ Output Tabs Switcher ═══
  Widget _buildOutputTabBar() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? kPurple2 : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, size: 18, color: _selectedTab == 0 ? kPurple2 : kMuted),
                    const SizedBox(width: 8),
                    Text(
                      'ಪಂಚಾಂಗ (Panchanga)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _selectedTab == 0 ? kPurple2 : kMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1 ? kPurple2 : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view, size: 18, color: _selectedTab == 1 ? kPurple2 : kMuted),
                    const SizedBox(width: 8),
                    Text(
                      'ಕುಂಡಲಿ (ಷೋಡಶವರ್ಗ)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _selectedTab == 1 ? kPurple2 : kMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ Tab 1: Panchanga (Like in Kundali Main Section) ═══
  Widget _buildPanchangTab() {
    if (_prashnaResult == null) return const SizedBox.shrink();
    final r = _prashnaResult!;
    final pan = r.panchang;
    final pName = _nameCtrl.text.trim();
    final dateStr = '${_dob.day.toString().padLeft(2, "0")}-${_dob.month.toString().padLeft(2, "0")}-${_dob.year}';
    final timeStr = '${_hour.toString().padLeft(2, "0")}:${_minute.toString().padLeft(2, "0")} $_ampm';

    // Calculate age (time from selected date)
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
    final ageStr = '$ageYears ${AppLocale.l('yearShort')} $ageMonths ${AppLocale.l('monthShort')} $ageDays ${AppLocale.l('dayShort')}';

    // Current Dasha and Bhukti from existing r.dashas
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
        // Basic Info Card
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
                _kv('${AppLocale.l('dasha')}', '$currentDasha  (${AppLocale.l('end')}: $dashaEnd)'),
                if (currentBhukti.isNotEmpty)
                  _kv(AppLocale.l('bhuktiLabel'), '$currentBhukti  (${AppLocale.l('end')}: $bhuktiEnd)'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── 📋 Panchanga (5 Angas) ──
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

        // ── ☀️ Ravi (Sun) Details ──
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

        // ── 🌙 Chandra (Moon) Details ──
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

  // ═══ Tab 2: Kundali (All Shodashavarga Kundalis) ═══
  Widget _buildKundaliTab() {
    if (_prashnaResult == null) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final chartSize = isLandscape ? (screenWidth * 0.45).clamp(300.0, 500.0) : (screenWidth - 32).clamp(280.0, 480.0);

    final currentChart = _shodashaVargaCharts[_selectedVargaIdx];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View Mode Switcher Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'ಷೋಡಶವರ್ಗ ಕುಂಡಲಿಗಳು (${_shodashaVargaCharts.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kPurple2),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _showAllVargas = !_showAllVargas),
                icon: Icon(_showAllVargas ? Icons.view_carousel : Icons.view_stream, size: 18, color: kOrange),
                label: Text(
                  _showAllVargas ? 'ಒಂದೊಂದಾಗಿ / Single' : 'ಎಲ್ಲಾ ಕುಂಡಲಿಗಳು / All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kOrange),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Quick-Selector Chips for all 16 vargas + Bhava
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
                  label: Text('${c['code']} ${c['name']}'),
                  selected: isSel,
                  selectedColor: kPurple2,
                  labelStyle: TextStyle(
                    fontSize: 11,
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
          // Single Chart Viewer with Prev / Next Navigation
          AppCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 18, color: _selectedVargaIdx > 0 ? kPurple2 : kMuted),
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
          // All 16+ Charts Stacked View
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

  // ═══ Helper UI Widgets ═══
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
