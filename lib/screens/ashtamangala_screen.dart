import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../constants/places.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/date_time_input.dart';
import '../core/ashtamangala_calculator.dart';

// ─────────────────────────────────────────────
// ೧. ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನ - ಮಾಹಿತಿ ನಮೂದು ಪರದೆ (Input Screen)
// ─────────────────────────────────────────────

class AshtamangalaScreen extends StatefulWidget {
  const AshtamangalaScreen({super.key});

  @override
  State<AshtamangalaScreen> createState() => _AshtamangalaScreenState();
}

class _AshtamangalaScreenState extends State<AshtamangalaScreen> {
  final _numberCtrl = TextEditingController();
  final _tamboolaCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  int? _sprashtangaNum; // 1 to 12
  int? _svarnaroodhaRashi; // 0 to 11
  int? _prucchakaRashi; // 0 to 11
  int? _prucchakaNak; // 0 to 26

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
    _tamboolaCtrl.dispose();
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
    } finally {
      if (mounted) setState(() => _geoLoading = false);
    }
  }

  void _showPlaceDisambiguation(List results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('ಸ್ಥಳ ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kText)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: results.length,
                itemBuilder: (_, i) {
                  final r = results[i];
                  return ListTile(
                    leading: Icon(Icons.location_on, color: kPurple2),
                    title: Text(r['display_name'], style: TextStyle(fontSize: 13, color: kText)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final lat = double.parse(r['lat']);
                      final lon = double.parse(r['lon']);
                      final autoTz = await getTimezoneForPlace(r['display_name'], lat, lon);
                      setState(() {
                        _placeCtrl.text = r['display_name'].split(',')[0].trim();
                        _latCtrl.text = lat.toStringAsFixed(4);
                        _lonCtrl.text = lon.toStringAsFixed(4);
                        _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        _geoStatus = '📍 ${r['display_name']}';
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _calculate() async {
    setState(() => _calculating = true);
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
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AshtamangalaDashboardScreen(
            result: result,
            name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ',
            ashtamangalaNumber: _numberCtrl.text.trim(),
            tamboolaNumber: _tamboolaCtrl.text.trim(),
            sprashtangaNum: _sprashtangaNum,
            svarnaroodhaRashi: _svarnaroodhaRashi,
            prucchakaRashi: _prucchakaRashi != null ? knRashi[_prucchakaRashi!] : null,
            prucchakaNakshatra: _prucchakaNak != null ? knNak[_prucchakaNak!] : null,
            place: _placeCtrl.text.trim().isNotEmpty ? _placeCtrl.text.trim() : LocationService.place,
            dob: _dob,
            hour: _hour,
            minute: _minute,
            ampm: _ampm,
            lat: lat,
            lon: lon,
            tzOffset: tzOffset,
          ),
        ));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ಕುಂಡಲಿ ಲೆಕ್ಕಾಚಾರ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ವಿವರಗಳನ್ನು ಪರಿಶೀಲಿಸಿ.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ದೋಷ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನೆ',
          style: TextStyle(color: kText, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🪔', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ಪ್ರಶ್ನ ವಿವರ ನಮೂದಿಸಿ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kOrange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Querent Name
                    _inputField(_nameCtrl, 'ಪ್ರುಚ್ಛಕರ ಹೆಸರು (ಐಚ್ಛಿಕ)', Icons.person),
                    const SizedBox(height: 12),

                    // ಪ್ರುಚ್ಛಕರ ರಾಶಿ ಮತ್ತು ನಕ್ಷತ್ರ
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _prucchakaRashi,
                            decoration: InputDecoration(
                              labelText: 'ಪ್ರುಚ್ಛಕರ ರಾಶಿ',
                              prefixIcon: Icon(Icons.nightlight_round, color: kMuted, size: 20),
                              suffixIcon: _prucchakaRashi != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () => setState(() => _prucchakaRashi = null),
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            hint: const Text('ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontSize: 13)),
                            isExpanded: true,
                            items: List.generate(12, (i) => DropdownMenuItem<int>(
                              value: i,
                              child: Text(knRashi[i], style: TextStyle(color: kText, fontSize: 13)),
                            )),
                            onChanged: (v) => setState(() => _prucchakaRashi = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _prucchakaNak,
                            decoration: InputDecoration(
                              labelText: 'ಪ್ರುಚ್ಛಕರ ನಕ್ಷತ್ರ',
                              prefixIcon: Icon(Icons.star_border, color: kMuted, size: 20),
                              suffixIcon: _prucchakaNak != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () => setState(() => _prucchakaNak = null),
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            hint: const Text('ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontSize: 13)),
                            isExpanded: true,
                            items: List.generate(27, (i) => DropdownMenuItem<int>(
                              value: i,
                              child: Text(knNak[i], style: TextStyle(color: kText, fontSize: 13)),
                            )),
                            onChanged: (v) => setState(() => _prucchakaNak = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ ಮತ್ತು ತಾಂಬೂಲ ಸಂಖ್ಯೆ
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numberCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ',
                              hintText: 'ಉದಾ: 108',
                              prefixIcon: Icon(Icons.pin, color: kMuted, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            style: TextStyle(color: kText, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _tamboolaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'ತಾಂಬೂಲ ಸಂಖ್ಯೆ',
                              hintText: 'ಉದಾ: 8',
                              prefixIcon: Icon(Icons.eco, color: kMuted, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              isDense: true,
                            ),
                            style: TextStyle(color: kText, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ಸ್ಪೃಷ್ಟಾಂಗ ರಾಶಿ (1-12 ಸಂಖ್ಯೆ ಆಯ್ಕೆ) ಮತ್ತು ಸ್ವರ್ಣಾರೂಢ ರಾಶಿ
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _sprashtangaNum,
                            decoration: InputDecoration(
                              labelText: 'ಸ್ಪೃಷ್ಟಾಂಗ ರಾಶಿ (1-12)',
                              prefixIcon: Icon(Icons.touch_app, color: kMuted, size: 20),
                              suffixIcon: _sprashtangaNum != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () => setState(() => _sprashtangaNum = null),
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            hint: const Text('ಸಂಖ್ಯೆ 1-12', style: TextStyle(fontSize: 13)),
                            isExpanded: true,
                            items: List.generate(12, (i) {
                              final num = i + 1;
                              return DropdownMenuItem<int>(
                                value: num,
                                child: Text('$num - ${knRashi[i]}', style: TextStyle(color: kText, fontSize: 13)),
                              );
                            }),
                            onChanged: (v) => setState(() => _sprashtangaNum = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _svarnaroodhaRashi,
                            decoration: InputDecoration(
                              labelText: 'ಸ್ವರ್ಣಾರೂಢ ರಾಶಿ',
                              prefixIcon: Icon(Icons.stars, color: kMuted, size: 20),
                              suffixIcon: _svarnaroodhaRashi != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () => setState(() => _svarnaroodhaRashi = null),
                                    )
                                  : null,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            hint: const Text('ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontSize: 13)),
                            isExpanded: true,
                            items: List.generate(12, (i) => DropdownMenuItem<int>(
                              value: i,
                              child: Text(knRashi[i], style: TextStyle(color: kText, fontSize: 13)),
                            )),
                            onChanged: (v) => setState(() => _svarnaroodhaRashi = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date & Time Typable Inputs (ಟೈಪ್ ಮಾಡಬಹುದಾದ ದಿನಾಂಕ & ಸಮಯ)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 500;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: DateInputRow(
                                  date: _dob,
                                  color: kPurple2,
                                  onChanged: (d) => setState(() => _dob = d),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TimeInputRow(
                                  hour: _hour,
                                  minute: _minute,
                                  ampm: _ampm,
                                  color: kPurple2,
                                  onChanged: (h, m, a) => setState(() {
                                    _hour = h;
                                    _minute = m;
                                    _ampm = a;
                                  }),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DateInputRow(
                                date: _dob,
                                color: kPurple2,
                                onChanged: (d) => setState(() => _dob = d),
                              ),
                              const SizedBox(height: 10),
                              TimeInputRow(
                                hour: _hour,
                                minute: _minute,
                                ampm: _ampm,
                                color: kPurple2,
                                onChanged: (h, m, a) => setState(() {
                                  _hour = h;
                                  _minute = m;
                                  _ampm = a;
                                }),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Place Autocomplete
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _placeCtrl.text),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                        return offlinePlaces.keys.where((place) =>
                          place.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (selection) async {
                        final coords = offlinePlaces[selection]!;
                        final autoTz = coords.length > 2 ? coords[2] : await getTimezoneForPlace(selection, coords[0], coords[1]);
                        setState(() {
                          _placeCtrl.text = selection;
                          _latCtrl.text = coords[0].toStringAsFixed(4);
                          _lonCtrl.text = coords[1].toStringAsFixed(4);
                          _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                          _geoStatus = '📍 $selection (${coords[0]}, ${coords[1]})';
                        });
                      },
                      fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                        return TextField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          decoration: InputDecoration(
                            labelText: 'ಸ್ಥಳ',
                            prefixIcon: Icon(Icons.location_city, color: kMuted, size: 20),
                            suffixIcon: _geoLoading
                                ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                : IconButton(
                                    icon: Icon(Icons.search, color: kPurple2, size: 20),
                                    onPressed: () {
                                      _placeCtrl.text = fieldTextEditingController.text;
                                      _geocodeMultiple(fieldTextEditingController.text);
                                    },
                                  ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          style: TextStyle(color: kText, fontSize: 14),
                          onChanged: (val) => _placeCtrl.text = val,
                        );
                      },
                    ),

                    if (_geoStatus.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(_geoStatus, style: TextStyle(fontSize: 11, color: kPurple2)),
                      ),
                    const SizedBox(height: 12),

                    // Lat, Lon, TZ
                    Row(
                      children: [
                        Expanded(child: _inputField(_latCtrl, 'ಅಕ್ಷಾಂಶ', Icons.my_location)),
                        const SizedBox(width: 8),
                        Expanded(child: _inputField(_lonCtrl, 'ರೇಖಾಂಶ', Icons.my_location)),
                        const SizedBox(width: 8),
                        Expanded(child: _inputField(_tzCtrl, 'ಕಾಲ ವಲಯ', Icons.schedule)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculating ? null : _calculate,
                        icon: _calculating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.calculate, size: 20),
                        label: Text(
                          _calculating ? 'ಲೆಕ್ಕಾಚಾರವಾಗುತ್ತಿದೆ...' : 'ಲೆಕ್ಕ ಹಾಕಿ',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
                ),
              ),
            ],
          ),
        ),
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
}

// ─────────────────────────────────────────────
// ೨. ಅಷ್ಟಮಂಗಲ ಪ್ರಶ್ನ - ಡ್ಯಾಶ್‌ಬೋರ್ಡ್ ಪರದೆ (Dashboard Screen)
//    ಕುಂಡಲಿ ಮುಖ್ಯ ವಿಭಾಗದಂತೆಯೇ ಪೂರ್ಣ ಸ್ಕ್ರೀನ್, ವರ್ಟಿಕಲ್ ಮೋಡ್ & ಲ್ಯಾಂಡ್‌ಸ್ಕೇಪ್ ಬೆಂಬಲ
// ─────────────────────────────────────────────

class AshtamangalaDashboardScreen extends StatefulWidget {
  final KundaliResult result;
  final String name;
  final String ashtamangalaNumber;
  final String tamboolaNumber;
  final int? sprashtangaNum;
  final int? svarnaroodhaRashi;
  final String? prucchakaRashi;
  final String? prucchakaNakshatra;
  final String place;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final double tzOffset;

  const AshtamangalaDashboardScreen({
    super.key,
    required this.result,
    required this.name,
    required this.ashtamangalaNumber,
    required this.tamboolaNumber,
    this.sprashtangaNum,
    this.svarnaroodhaRashi,
    this.prucchakaRashi,
    this.prucchakaNakshatra,
    required this.place,
    required this.dob,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.tzOffset,
  });

  @override
  State<AshtamangalaDashboardScreen> createState() => _AshtamangalaDashboardScreenState();
}

class _AshtamangalaDashboardScreenState extends State<AshtamangalaDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _chartPageIndex = 0;
  String? _bhavaPlanet;

  // ಬಳಕೆದಾರರು ಕೇಳಿದ ೪ ಟ್ಯಾಬ್‌ಗಳು
  static const _tabs = ['ಪಂಚಾಂಗ', 'ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಅಷ್ಟಮಂಗಲ'];

  // ೧೬ ಪಾರಾಶರಿ ಷೋಡಶವರ್ಗ ಕುಂಡಲಿಗಳು + ಭಾವ ಕುಂಡಲಿ
  static const List<Map<String, dynamic>> _shodashaVargaCharts = [
    {'name': 'ರಾಶಿ', 'fullName': 'ರಾಶಿ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': false},
    {'name': 'ಭಾವ', 'fullName': 'ಭಾವ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': true},
    {'name': 'ನವಾಂಶ', 'fullName': 'ನವಾಂಶ ಕುಂಡಲಿ', 'varga': 9, 'isBhava': false},
    {'name': 'ಹೋರಾ', 'fullName': 'ಹೋರಾ ಕುಂಡಲಿ', 'varga': 2, 'isBhava': false},
    {'name': 'ದ್ರೆಕ್ಕಾಣ', 'fullName': 'ದ್ರೆಕ್ಕಾಣ ಕುಂಡಲಿ', 'varga': 3, 'isBhava': false},
    {'name': 'ಚತುರ್ಥಾಂಶ', 'fullName': 'ಚತುರ್ಥಾಂಶ ಕುಂಡಲಿ', 'varga': 4, 'isBhava': false},
    {'name': 'ಸಪ್ತಾಂಶ', 'fullName': 'ಸಪ್ತಾಂಶ ಕುಂಡಲಿ', 'varga': 7, 'isBhava': false},
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
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showPlanetDetail(String pName) {
    final info = widget.result.planets[pName];
    if (info == null) return;
    final sun = widget.result.planets['ರವಿ'];
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
    final now = DateTime.now();
    final lords = <String, Color>{};
    for (final md in widget.result.dashas) {
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

  String _formatKannadaTime() {
    final ap = widget.ampm == 'AM' ? 'ಪೂರ್ವಾಹ್ನ' : 'ಅಪರಾಹ್ನ';
    return '${widget.hour.toString().padLeft(2, '0')}:${widget.minute.toString().padLeft(2, '0')} $ap';
  }

  String _trDashaBalance(String dashaBalance) {
    return dashaBalance
        .replaceAll('years', 'ವರ್ಷ')
        .replaceAll('year', 'ವರ್ಷ')
        .replaceAll('months', 'ತಿಂಗಳು')
        .replaceAll('month', 'ತಿಂಗಳು')
        .replaceAll('days', 'ದಿನ')
        .replaceAll('day', 'ದಿನ');
  }

  Widget _buildChartWidget(Map<String, dynamic> chart) {
    final varga = chart['varga'] as int;
    final isBhava = chart['isBhava'] as bool;
    final label = chart['fullName'] as String;

    // ನವಾಂಶ ಸಂಖ್ಯೆಯನ್ನು ಕೇವಲ ರಾಶಿ ಕುಂಡಲಿ (D1) ಮತ್ತು ಭಾವ ಕುಂಡಲಿಗಳಲ್ಲಿ ಮಾತ್ರ ತೋರಿಸಿ
    final bool isRashiOrBhava = (varga == 1 && !isBhava) || isBhava;

    Map<String, int>? aroodhas;
    if (varga == 1 && !isBhava && (widget.svarnaroodhaRashi != null || widget.sprashtangaNum != null)) {
      aroodhas = {
        if (widget.svarnaroodhaRashi != null) 'ಆರೂಢ': widget.svarnaroodhaRashi!,
        if (widget.sprashtangaNum != null) 'ಸ್ಪೃಷ್ಟಾಂಗ': widget.sprashtangaNum! - 1,
      };
    }

    return KundaliChart(
      result: widget.result,
      varga: varga,
      isBhava: isBhava,
      showSphutas: false,
      showNavamshaNumber: isRashiOrBhava, // ಕೇವಲ ರಾಶಿ & ಭಾವ ಕುಂಡಲಿಗಳಲ್ಲಿ ಮಾತ್ರ ನವಾಂಶ ಸಂಖ್ಯೆ
      forceSingleLetter: true, // ಎಲ್ಲ ಕುಂಡಲಿಗಳಲ್ಲೂ ಸಿಂಗಲ್ ಲೆಟರ್ ಗ್ರಹ ಹೆಸರುಗಳು
      aroodhas: aroodhas,
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

  // ═══ ಟ್ಯಾಬ್ ೧: ಪಂಚಾಂಗ (Panchanga Tab) ═══
  Widget _buildPanchangTab() {
    final r = widget.result;
    final pan = r.panchang;
    final dateStr = '${widget.dob.day.toString().padLeft(2, "0")}-${widget.dob.month.toString().padLeft(2, "0")}-${widget.dob.year}';
    final timeStr = _formatKannadaTime();

    // ವಯಸ್ಸು ಲೆಕ್ಕಾಚಾರ
    final now = DateTime.now();
    int ageYears = now.year - widget.dob.year;
    int ageMonths = now.month - widget.dob.month;
    int ageDays = now.day - widget.dob.day;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ವಿವರ ಕಾರ್ಡ್
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('ಪ್ರುಚ್ಛಕರ ಹೆಸರು', widget.name),
                if (widget.prucchakaRashi != null || widget.prucchakaNakshatra != null)
                  _kv('ಪ್ರುಚ್ಛಕರ ರಾಶಿ / ನಕ್ಷತ್ರ', [
                    if (widget.prucchakaRashi != null) 'ರಾಶಿ: ${widget.prucchakaRashi}',
                    if (widget.prucchakaNakshatra != null) 'ನಕ್ಷತ್ರ: ${widget.prucchakaNakshatra}',
                  ].join('  •  ')),
                _kv('ಸ್ಥಳ', widget.place),
                _kv('ದಿನಾಂಕ', dateStr),
                _kv('ಸಮಯ', timeStr),
                if (widget.ashtamangalaNumber.isNotEmpty)
                  _kv('ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ', widget.ashtamangalaNumber),
                if (widget.tamboolaNumber.isNotEmpty)
                  _kv('ತಾಂಬೂಲ ಸಂಖ್ಯೆ', widget.tamboolaNumber),
                if (widget.svarnaroodhaRashi != null)
                  _kv('ಸ್ವರ್ಣಾರೂಢ ರಾಶಿ', knRashi[widget.svarnaroodhaRashi!]),
                if (widget.sprashtangaNum != null)
                  _kv('ಸ್ಪೃಷ್ಟಾಂಗ ರಾಶಿ', '${widget.sprashtangaNum} (${knRashi[widget.sprashtangaNum! - 1]})'),
                _kv('ಶಿಷ್ಟ ದಶಾಧಿಪತಿ', '${trAll(pan.dashaLord)}  ಶಿಷ್ಟ ಶೇಷ: ${_trDashaBalance(pan.dashaBalance)}'),
                const Divider(height: 16),
                _kv('ವಯಸ್ಸು', ageStr),
                if (currentDasha.isNotEmpty) ...[
                  const Divider(height: 16),
                  _kv('ಪ್ರಸ್ತುತ ದಶಾ', '$currentDasha  (ಅಂತ್ಯ: $dashaEnd)'),
                  if (currentBhukti.isNotEmpty)
                    _kv('ಪ್ರಸ್ತುತ ಭುಕ್ತಿ', '$currentBhukti  (ಅಂತ್ಯ: $bhuktiEnd)'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 📋 ಪಂಚಾಂಗ (೫ ಅಂಗ) ──
          _sectionLabel('📋 ಪಂಚಾಂಗ ವಿವರ', kPurple2),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableRow(['ವಾರ', trAll(pan.vara)]),
                _tableRow(['ತಿಥಿ', '${trAll(pan.tithi)}${pan.tithiGata.isNotEmpty || pan.tithiParama.isNotEmpty ? ' (ಗತ: ${pan.tithiGata}, ಪರಮ: ${pan.tithiParama})' : ''}']),
                _tableRow([
                  'ನಕ್ಷತ್ರ',
                  () {
                    final moonPada = r.planets['ಚಂದ್ರ']?.pada;
                    final fallback = (pan.nakPercent * 4).floor() + 1;
                    final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback);
                    return '${trAll(pan.nakshatra)} - ಪಾದ $p';
                  }()
                ]),
                _tableRow(['ಯೋಗ', '${trAll(pan.yoga)}${pan.yogaGata.isNotEmpty ? ' (ಗತ: ${pan.yogaGata})' : ''}']),
                _tableRow(['ಕರಣ', '${trAll(pan.karana)}${pan.karanaGata.isNotEmpty ? ' (ಗತ: ${pan.karanaGata})' : ''}']),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── ☀️ ರವಿ ವಿವರ ──
          _sectionLabel('☀️ ರವಿ ವಿವರ', Colors.orange),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableRow(['ಸೂರ್ಯೋದಯ', pan.sunrise]),
                _tableRow(['ಸೂರ್ಯಾಸ್ತ', pan.sunset]),
                _tableRow(['ದಿನಮಾನ', pan.divamana]),
                _tableRow(['ರಾತ್ರಿಮಾನ', pan.ratrimana]),
                _tableRow(['ಉದಯಾದಿ ಘಟಿ', pan.udayadiGhati]),
                _tableRow(['ಸೂರ್ಯ ನಕ್ಷತ್ರ', '${trAll(pan.suryaNakshatra)} - ಪಾದ ${pan.suryaPada}']),
                _tableRow(['ಸೌರ ಮಾಸ', trAll(pan.souraMasa)]),
                _tableRow(['ಸೌರ ಮಾಸ ಗತ ದಿನ', pan.souraMasaGataDina]),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── 🌙 ಚಂದ್ರ ವಿವರ ──
          _sectionLabel('🌙 ಚಂದ್ರ ವಿವರ', Colors.blue),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableRow([
                  'ಚಂದ್ರ ನಕ್ಷತ್ರ',
                  () {
                    final moonPada = r.planets['ಚಂದ್ರ']?.pada;
                    final fallback = (pan.nakPercent * 4).floor() + 1;
                    final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback);
                    return '${trAll(pan.nakshatra)} - ಪಾದ $p (ಗತ ಘಟಿ: ${pan.gataGhati}, ಪರಮ ಘಟಿ: ${pan.paramaGhati})';
                  }()
                ]),
                _tableRow(['ಚಂದ್ರ ರಾಶಿ', trAll(pan.chandraRashi)]),
                _tableRow(['ಚಾಂದ್ರ ಮಾಸ', trAll(pan.chandraMasa)]),
                _tableRow(['ಸಂವತ್ಸರ', trAll(pan.samvatsara)]),
                _tableRow(['ಗತ ಘಟಿ', pan.gataGhati]),
                _tableRow(['ಪರಮ ಘಟಿ', pan.paramaGhati]),
                _tableRow(['ಶೇಷ ಘಟಿ', pan.shesha]),
                _tableRow(['ವಿಷ ಘಟಿ', pan.vishaPraghati]),
                _tableRow(['ಅಮೃತ ಘಟಿ', pan.amrutaPraghati]),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══ ಟ್ಯಾಬ್ ೨: ಕುಂಡಲಿ (Kundali Tab) ═══
  // ವರ್ಟಿಕಲ್ ಮೋಡ್: ಸ್ವೈಪ್ ಮಾಡಬಹುದಾದ ಸಿಂಗಲ್ ಚಾರ್ಟ್ + ಡಾಟ್ಸ್‌ ಇಂಡಿಕೇಟರ್
  // ಲ್ಯಾಂಡ್‌ಸ್ಕೇಪ್ ಮೋಡ್: ಪಕ್ಕಪಕ್ಕದಲ್ಲಿ ೨ ಚಾರ್ಟ್‌ಗಳು
  Widget _buildKundaliTab({required bool isLandscape}) {
    if (!isLandscape) {
      // ── PORTRAIT (ವರ್ಟಿಕಲ್ ಮೋಡ್): ಸಿಂಗಲ್ ಕುಂಡಲಿ ಪೇಜ್‌ವ್ಯೂ + ಡಾಟ್ಸ್‌ ──
      final screenWidth = MediaQuery.of(context).size.width;
      final chartSize = (screenWidth - 32).clamp(280.0, 480.0);

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  SizedBox(
                    height: chartSize,
                    child: PageView.builder(
                      onPageChanged: (i) => setState(() => _chartPageIndex = i),
                      itemCount: _shodashaVargaCharts.length,
                      itemBuilder: (context, i) {
                        final chart = _shodashaVargaCharts[i];
                        return Center(
                          child: SizedBox(
                            width: chartSize,
                            height: chartSize,
                            child: _buildChartWidget(chart),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ಡಾಟ್ಸ್‌ ಇಂಡಿಕೇಟರ್
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_shodashaVargaCharts.length, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: _chartPageIndex == i ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _chartPageIndex == i ? kPurple2 : kBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
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
          ],
        ),
      );
    } else {
      // ── LANDSCAPE: ೨ ಕುಂಡಲಿಗಳು ಪಕ್ಕಪಕ್ಕದಲ್ಲಿ (ರಾಶಿ ಕುಂಡಲಿ ಮತ್ತು ಭಾವ ಕುಂಡಲಿ) ──
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      final topPad = MediaQuery.of(context).padding.top;
      final bottomPad = MediaQuery.of(context).padding.bottom;
      final availableHeight = screenHeight - topPad - bottomPad - 130;
      final chartSize = availableHeight.clamp(200.0, screenHeight * 0.75);
      final chartWidth = screenWidth / 2.0;
      final squareSize = math.min(chartWidth - 16, chartSize);

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            SizedBox(
              height: squareSize + 8,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _shodashaVargaCharts.length,
                  itemBuilder: (context, i) {
                    final chart = _shodashaVargaCharts[i];
                    return SizedBox(
                      width: chartWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Center(
                          child: SizedBox(
                            width: squareSize,
                            height: squareSize,
                            child: _buildChartWidget(chart),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ಗ್ರಹದ ಮೇಲೆ ಟ್ಯಾಪ್ ಮಾಡಿ ಹೆಚ್ಚಿನ ವಿವರಗಳನ್ನು ವೀಕ್ಷಿಸಿ  •  ಸ್ವೈಪ್ ಮಾಡಿ ಇತರೆ ವರ್ಗ ಕುಂಡಲಿಗಳನ್ನು ವೀಕ್ಷಿಸಿ',
              style: TextStyle(fontSize: 11, color: kMuted),
            ),
          ],
        ),
      );
    }
  }

  // ═══ ಟ್ಯಾಬ್ ೩: ಸ್ಫುಟ (Sphuta Tab) ═══
  Widget _buildSphutaTab() {
    final r = widget.result;
    final pMap = r.planets;
    final lag = pMap['ಲಗ್ನ']?.longitude ?? 0.0;
    final sun = pMap['ರವಿ']?.longitude ?? 0.0;
    final moon = pMap['ಚಂದ್ರ']?.longitude ?? 0.0;
    final jup = pMap['ಗುರು']?.longitude ?? 0.0;

    // ಹೆಚ್ಚುವರಿ ಪ್ರಶ್ನಾ ಸ್ಫುಟಗಳು
    final trisphuta = (lag + moon + jup) % 360;
    final chatusphuta = (trisphuta + sun) % 360;
    final aroodha = widget.svarnaroodhaRashi != null
        ? ((widget.svarnaroodhaRashi! * 30.0 + (lag % 30.0)) % 360)
        : ((lag + 30) % 360); // ಆರೂಢ ಸ್ಫುಟ
    final chatra = (aroodha + lag - sun + 360) % 360; // ಛತ್ರ ಸ್ಫುಟ
    final sprashtangaDeg = widget.sprashtangaNum != null
        ? (((widget.sprashtangaNum! - 1) * 30.0 + (lag % 30.0)) % 360)
        : null;
    final tambInt = int.tryParse(widget.tamboolaNumber);
    final tamboolaSphuta = tambInt != null
        ? ((tambInt * 30.0 + (lag % 30.0)) % 360)
        : null;

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
      if (sprashtangaDeg != null)
        {'name': 'ಸ್ಪೃಷ್ಟಾಂಗ ಸ್ಫುಟ', 'deg': sprashtangaDeg},
      if (tamboolaSphuta != null)
        {'name': 'ತಾಂಬೂಲ ಸ್ಫುಟ', 'deg': tamboolaSphuta},
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══ ಸಹಾಯಕ ವಿಜೆಟ್‌ಗಳು ═══
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

  // ═══ ಟ್ಯಾಬ್ ೪: ಅಷ್ಟಮಂಗಲ (Ashtamangala Tab) ═══
  Widget _buildAshtamangalaTab() {
    int? nakIdx;
    if (widget.prucchakaNakshatra != null) {
      final idx = knNak.indexOf(widget.prucchakaNakshatra!);
      if (idx != -1) nakIdx = idx;
    }

    final d = AshtamangalaCalculator.calculate(
      result: widget.result,
      ashtamangalaNumber: widget.ashtamangalaNumber,
      svarnaroodhaRashi: widget.svarnaroodhaRashi,
      sprashtangaNum: widget.sprashtangaNum,
      prucchakaNakshatraIdx: nakIdx,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ೧. ಅಷ್ಟಮಂಗಲ ವಿಭಾಗ
              _buildAshtamangalaCard(
                title: 'ಅಷ್ಟಮಂಗಲ',
                rows: [
                  ['ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ', d.ashtamangalaNumber],
                  ['ಅಷ್ಟಮಂಗಲ ಗ್ರಹ', d.graha],
                  ['ಅಷ್ಟಮಂಗಲ ಯೋನಿ', d.yoni],
                  ['ಅಷ್ಟಮಂಗಲ ಜಂತು', d.jantu],
                  ['ಅಷ್ಟಮಂಗಲ ಪಂಚಭೂತ', d.panchabhuta],
                  ['ಅಷ್ಟಮಂಗಲ ಪಕ್ಷ', d.paksha],
                  ['ಅಷ್ಟಮಂಗಲ ತಿಥಿ', d.tithi],
                  ['ಅಷ್ಟಮಂಗಲ ನಕ್ಷತ್ರ', d.nakshatra],
                  ['ಅಷ್ಟಮಂಗಲ ವಾರ', d.vara],
                  ['ಅಷ್ಟಮಂಗಲ ರಾಶಿ', d.rashi],
                ],
              ),
              const SizedBox(height: 14),

              // ೨. ಧೂಮಾದಿ ಪಂಚಸ್ಫುಟ ವಿಭಾಗ
              _buildAshtamangalaCard(
                title: 'ಧೂಮಾದಿ ಪಂಚಸ್ಫುಟ',
                rows: [
                  ['ಧೂಮ ಸ್ಫುಟ', d.dhooma],
                  ['ವ್ಯತೀಪಾತ ಸ್ಫುಟ', d.vyatipata],
                  ['ಪರಿವೇಷ ಸ್ಫುಟ', d.parivesha],
                  ['ಇಂದ್ರಚಾಪ ಸ್ಫುಟ', d.indrachapa],
                  ['ಉಪಕೇತು ಸ್ಫುಟ', d.upaketu],
                  ['ಚಂದ್ರ ಕ್ರಿಯಾ', d.chandraKriya],
                  ['ಚಂದ್ರ ಅವಸ್ಥಾ', d.chandraAvastha],
                  ['ಚಂದ್ರ ವೇಲಾ', d.chandraVela],
                ],
              ),
              const SizedBox(height: 14),

              // ೩. ಪಂಚಸೂತ್ರ ವಿಭಾಗ
              _buildAshtamangalaCard(
                title: 'ಪಂಚಸೂತ್ರ',
                rows: [
                  ['ಸಾಮಾನ್ಯ ಸೂತ್ರ - ಪೃಥ್ವೀ', d.samanyaSutra],
                  ['ಅಧಿಪ ಸೂತ್ರ - ಜಲ', d.adhipaSutra],
                  ['ಅಂಶ ಸೂತ್ರ - ಅಗ್ನಿ', d.amshaSutra],
                  ['ನಕ್ಷತ್ರ ಸೂತ್ರ - ವಾಯು', d.nakshatraSutra],
                  ['ಮಹಾ ಸೂತ್ರ - ಆಕಾಶ', d.mahaSutra],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAshtamangalaCard({
    required String title,
    required List<List<String>> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE67E22),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Column(
              children: [
                // Solid orange top banner
                Container(
                  height: 32,
                  color: const Color(0xFFF6B042),
                ),
                ...rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final r = entry.value;
                  final isLast = idx == rows.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                r[0],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: kText,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                r[1],
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: (r[1] == 'ಜೀವ')
                                      ? const Color(0xFF2E7D32)
                                      : (r[1] == 'ಮೃತ್ಯು')
                                          ? const Color(0xFFC62828)
                                          : (r[1] == 'ರೋಗ')
                                              ? const Color(0xFFE65100)
                                              : kText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            return Column(
              children: [
                // Minimal header bar (back button, title, edit button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: kText),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.dob.day.toString().padLeft(2, '0')}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.year}  •  ${_formatKannadaTime()}  •  ${widget.place}',
                              style: TextStyle(fontSize: 11, color: kMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: kPurple2, size: 20),
                        tooltip: 'ವಿವರ ಬದಲಿಸಿ',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ಎಲ್ಲ ಮೋಡ್‌ಗಳಲ್ಲೂ (ವರ್ಟಿಕಲ್ ಮತ್ತು ಲ್ಯಾಂಡ್‌ಸ್ಕೇಪ್) ಪೂರ್ಣ ಅಗಲದ ಟ್ಯಾಬ್ ಬಾರ್
                Container(
                  color: kCard,
                  child: TabBar(
                    controller: _tabCtrl,
                    labelColor: kPurple2,
                    unselectedLabelColor: kMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    indicatorColor: kPurple2,
                    indicatorWeight: 3,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildPanchangTab(),
                      _buildKundaliTab(isLandscape: isLandscape),
                      _buildSphutaTab(),
                      _buildAshtamangalaTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
