import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../core/calculator.dart';
import '../constants/places.dart';
// ephemeris not needed
import '../services/location_service.dart';
import 'prashna_dashboard_screen.dart';

/// Simplified input screen for Prashna (horary) charts.
/// Defaults to current date/time and location.
class PrashnaInputScreen extends StatefulWidget {
  const PrashnaInputScreen({super.key});
  @override
  State<PrashnaInputScreen> createState() => _PrashnaInputScreenState();
}

class _PrashnaInputScreenState extends State<PrashnaInputScreen> {
  final _nameCtrl = TextEditingController();
  late final TextEditingController _placeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _tzCtrl;

  DateTime _dob = DateTime.now();
  int _hour = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute = DateTime.now().minute;
  String _ampm = DateTime.now().hour < 12 ? 'AM' : 'PM';
  String _ayanamsa = 'ಲಾಹಿರಿ';
  String _nodeMode = 'ನಿಜ ರಾಹು';
  bool _loading = false;
  bool _geoLoading = false;
  String _geoStatus = '';

  // Persistent scroll controllers for time wheels
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _ampmCtrl;

  @override
  void initState() {
    super.initState();
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    _tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
    _hourCtrl = FixedExtentScrollController(initialItem: _hour - 1);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _ampmCtrl = FixedExtentScrollController(initialItem: _ampm == 'AM' ? 0 : 1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _ampmCtrl.dispose();
    super.dispose();
  }

  Future<void> _geocode(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ');
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
          _showPlaceOptions(data);
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'ಜಾಲ ದೋಷ');
    }
    setState(() => _geoLoading = false);
  }

  void _showPlaceOptions(List<dynamic> results) {
    showModalBottomSheet(
      context: context, backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('ಸ್ಥಳ ಆಯ್ಕೆ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1))),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true, itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (_, i) {
                  final place = results[i];
                  final displayName = place['display_name'] ?? '';
                  return ListTile(
                    leading: Icon(Icons.location_on, color: kPurple1, size: 20),
                    title: Text(displayName, style: TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final lat = double.parse(place['lat']);
                      final lon = double.parse(place['lon']);
                      final autoTz = await getTimezoneForPlace(displayName, lat, lon);
                      setState(() {
                        _latCtrl.text = lat.toStringAsFixed(4);
                        _lonCtrl.text = lon.toStringAsFixed(4);
                        _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        _geoStatus = '📍 $displayName';
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final lat = double.tryParse(_latCtrl.text) ?? 14.98;
      final lon = double.tryParse(_lonCtrl.text) ?? 74.73;

      int h24 = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
      if (_ampm == 'AM' && _hour == 12) h24 = 0;
      final localHour = h24 + _minute / 60.0;

      final aynMode = _ayanamsa == 'ರಾಮನ್' ? 'raman' : _ayanamsa == 'ಕೆ.ಪಿ' ? 'kp' : 'lahiri';
      final trueNode = _nodeMode == 'ನಿಜ ರಾಹು';
      final tzOffset = double.tryParse(_tzCtrl.text) ?? LocationService.tzOffset;

      final result = await AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: tzOffset,
        hour24: localHour,
        lat: lat, lon: lon,
        ayanamsaMode: aynMode,
        trueNode: trueNode,
      );

      if (result != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PrashnaDashboardScreen(
            result: result,
            name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'ಪ್ರಶ್ನ',
            place: _placeCtrl.text,
            dob: _dob,
            hour: _hour,
            minute: _minute,
            ampm: _ampm,
            lat: lat,
            lon: lon,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ದೋಷ: $e'), backgroundColor: Colors.red.shade600));
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: kText), onPressed: () => Navigator.pop(context)),
        title: Text('ಪ್ರಶ್ನ', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Center(
                      child: Text('ಪ್ರಶ್ನ ಕುಂಡಲಿ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPurple2)),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'ಹೆಸರು (ಐಚ್ಛಿಕ)',
                        labelStyle: TextStyle(color: kMuted, fontWeight: FontWeight.w600),
                        prefixIcon: Icon(Icons.person, color: kPurple2, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                      ),
                      style: TextStyle(color: kText, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dob,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _dob = d);
                      },
                      child: _infoRow(Icons.calendar_today, 'ದಿನಾಂಕ',
                        '${_dob.day.toString().padLeft(2, '0')}/${_dob.month.toString().padLeft(2, '0')}/${_dob.year}'),
                    ),
                    const SizedBox(height: 12),

                    // Time — scrollable wheel pickers
                    Row(
                      children: [
                        Icon(Icons.access_time, color: kPurple2, size: 20),
                        const SizedBox(width: 8),
                        Text('ಸಮಯ:', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        // Hour wheel (1-12)
                        _buildWheel(
                          controller: _hourCtrl,
                          count: 12,
                          label: (i) => '${i + 1}',
                          onChanged: (i) => setState(() => _hour = i + 1),
                          width: 48,
                        ),
                        Text(' : ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kText)),
                        // Minute wheel (0-59)
                        _buildWheel(
                          controller: _minuteCtrl,
                          count: 60,
                          label: (i) => i.toString().padLeft(2, '0'),
                          onChanged: (i) => setState(() => _minute = i),
                          width: 48,
                        ),
                        const SizedBox(width: 8),
                        // AM/PM wheel
                        _buildWheel(
                          controller: _ampmCtrl,
                          count: 2,
                          label: (i) => i == 0 ? 'AM' : 'PM',
                          onChanged: (i) => setState(() => _ampm = i == 0 ? 'AM' : 'PM'),
                          width: 52,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Place (with geocode)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _placeCtrl,
                            decoration: InputDecoration(
                              labelText: 'ಸ್ಥಳ',
                              labelStyle: TextStyle(color: kMuted, fontWeight: FontWeight.w600),
                              prefixIcon: Icon(Icons.location_on, color: kPurple2, size: 20),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                            ),
                            style: TextStyle(color: kText, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _geoLoading
                            ? const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: Icon(Icons.search, color: kPurple2),
                                onPressed: () => _geocode(_placeCtrl.text),
                              ),
                      ],
                    ),
                    if (_geoStatus.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(_geoStatus, style: TextStyle(fontSize: 11, color: kMuted)),
                    ],
                    const SizedBox(height: 12),

                    // Lat/Lon/TZ row
                    Row(
                      children: [
                        Expanded(child: _smallField(_latCtrl, 'ಅಕ್ಷಾಂಶ')),
                        const SizedBox(width: 8),
                        Expanded(child: _smallField(_lonCtrl, 'ರೇಖಾಂಶ')),
                        const SizedBox(width: 8),
                        SizedBox(width: 70, child: _smallField(_tzCtrl, 'TZ')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── ಪ್ರಸ್ತುತ + ಲೆಕ್ಕ ಹಾಕಿ buttons ──
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setState(() {
                              _nameCtrl.clear();
                              _placeCtrl.text = LocationService.place;
                              _latCtrl.text = LocationService.lat.toStringAsFixed(4);
                              _lonCtrl.text = LocationService.lon.toStringAsFixed(4);
                              _tzCtrl.text = '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}';
                              _dob = now;
                              _hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
                              _minute = now.minute;
                              _ampm = now.hour >= 12 ? 'PM' : 'AM';
                            });
                            _hourCtrl.animateToItem(_hour - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            _minuteCtrl.animateToItem(_minute, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                            _ampmCtrl.animateToItem(_ampm == 'AM' ? 0 : 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kTeal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('ಪ್ರಸ್ತುತ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _calculate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOrange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('ಲೆಕ್ಕ ಹಾಕಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kPurple2, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 16)),
      ],
    );
  }

  Widget _smallField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kMuted, fontSize: 12),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: kBorder)),
      ),
      style: TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  /// Compact scrollable wheel picker with persistent controller
  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    double width = 50,
  }) {
    return Container(
      width: width,
      height: 100,
      decoration: BoxDecoration(
        color: kPurple2.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kPurple2.withOpacity(0.2)),
      ),
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 32,
        diameterRatio: 1.4,
        perspective: 0.003,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (ctx, i) {
            return Center(
              child: Text(
                label(i),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: kPurple2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
