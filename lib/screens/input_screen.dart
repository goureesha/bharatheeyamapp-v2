import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../services/storage_service.dart';
import '../core/calculator.dart';
import '../constants/places.dart';
import '../core/ephemeris.dart';
import '../services/network_service.dart';
import 'dashboard_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameCtrl    = TextEditingController();
  final _placeCtrl   = TextEditingController(text: 'Yellapur');
  final _latCtrl     = TextEditingController(text: '14.9800');
  final _lonCtrl     = TextEditingController(text: '74.7300');

  DateTime _dob      = DateTime.now();
  int _hour          = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute        = DateTime.now().minute;
  String _ampm       = DateTime.now().hour < 12 ? 'AM' : 'PM';
  String _ayanamsa   = 'ಲಾಹಿರಿ';
  String _nodeMode   = 'ನಿಜ ರಾಹು';
  bool _loading      = false;
  bool _geoLoading   = false;
  String _geoStatus  = '';

  Map<String, Profile> _savedProfiles = {};
  String? _selName;

  bool _isInitStatus = true;
  bool _isNetworkBlocked = false;

  String _loadedNotes = '';
  Map<String, int> _loadedAroodhas = {};
  int? _loadedJanmaNakshatraIdx;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _checkNetwork();
  }

  Future<void> _checkNetwork() async {
    final allowed = await NetworkService.checkAndInitialize();
    if (mounted) {
      setState(() {
        _isNetworkBlocked = !allowed;
        _isInitStatus = false;
      });
    }
  }

  Future<void> _loadProfiles() async {
    final p = await StorageService.loadAll();
    if (mounted) setState(() => _savedProfiles = p);
  }

  void _loadProfile(String name) {
    final p = _savedProfiles[name]!;
    setState(() {
      _nameCtrl.text  = name;
      _placeCtrl.text = p.place;
      _latCtrl.text   = p.lat.toStringAsFixed(4);
      _lonCtrl.text   = p.lon.toStringAsFixed(4);
      _hour   = p.hour;
      _minute = p.minute;
      _ampm   = p.ampm;
      _loadedNotes = p.notes;
      _loadedAroodhas = Map.from(p.aroodhas);
      _loadedJanmaNakshatraIdx = p.janmaNakshatraIdx;
      try {
        final parts = p.date.split('-');
        if (parts.length == 3) {
          _dob = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      } catch (_) {
        _dob = DateTime.now(); // Fallback if corrupted
      }
    });
  }

  Future<void> _geocode() async {
    if (_placeCtrl.text.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(_placeCtrl.text.trim());
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          setState(() {
            _latCtrl.text = lat.toStringAsFixed(4);
            _lonCtrl.text = lon.toStringAsFixed(4);
            _geoStatus    = '📍 ${data[0]['display_name']}';
          });
        } else {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.');
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ. ನೇರವಾಗಿ ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ ನಮೂದಿಸಿ.');
    }
    setState(() => _geoLoading = false);
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

      final aynMode = _ayanamsa == 'ರಾಮನ್'
          ? 'raman' : _ayanamsa == 'ಕೆ.ಪಿ' ? 'kp' : 'lahiri';
      final trueNode = _nodeMode == 'ನಿಜ ರಾಹು';

      final result = await AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: 5.5,
        hour24: localHour,
        lat: lat, lon: lon,
        ayanamsaMode: aynMode,
        trueNode: trueNode,
      );

      if (result != null && mounted) {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => DashboardScreen(
            result: result,
            name: _nameCtrl.text,
            place: _placeCtrl.text,
            dob: _dob,
            hour: _hour,
            minute: _minute,
            ampm: _ampm,
            lat: lat,
            lon: lon,
            initialNotes: _loadedNotes,
            initialAroodhas: _loadedAroodhas,
            initialJanmaNakshatraIdx: _loadedJanmaNakshatraIdx,
            onSave: (notes, aroodhas, janmaIdx) => _saveProfile(notes: notes, aroodhas: aroodhas, janmaNakshatraIdx: janmaIdx),
          ),
        ));

        // Reset the form back to current time/empty strings when returning
        if (mounted) {
          final now = DateTime.now();
          setState(() {
            _nameCtrl.clear();
            _placeCtrl.clear();
            _latCtrl.clear();
            _lonCtrl.clear();
            _dob = now;
            _hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
            _minute = now.minute;
            _ampm = now.hour >= 12 ? 'PM' : 'AM';
            _loadedNotes = '';
            _loadedAroodhas = {};
            _loadedJanmaNakshatraIdx = null;
          });
        }
      }
    } catch (e) {
      _showError('ದೋಷ: $e');
    }
    setState(() => _loading = false);
  }

  void _saveProfile({String notes = '', Map<String, int> aroodhas = const {}, int? janmaNakshatraIdx}) async {
    String name = _nameCtrl.text.trim();
    if (name.isEmpty) name = 'Unknown_${_dob.toIso8601String().substring(0, 10)}';
    final p = Profile(
      name: name,
      date: '${_dob.year}-${_dob.month.toString().padLeft(2,'0')}-${_dob.day.toString().padLeft(2,'0')}',
      hour: _hour, minute: _minute, ampm: _ampm,
      lat: double.tryParse(_latCtrl.text) ?? 14.98,
      lon: double.tryParse(_lonCtrl.text) ?? 74.73,
      place: _placeCtrl.text,
      notes: notes,
      aroodhas: aroodhas,
      janmaNakshatraIdx: janmaNakshatraIdx,
    );
    await StorageService.save(p);
    await _loadProfiles();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600));
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isNetworkBlocked) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.red.shade400),
                const SizedBox(height: 24),
                Text('ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಅಗತ್ಯವಿದೆ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('ನಿಮ್ಮ ಚಂದಾದಾರಿಕೆಯನ್ನು ಪರಿಶೀಲಿಸಲು ದಯವಿಟ್ಟು ೪೮ ಗಂಟೆಗಳಿಗೊಮ್ಮೆ ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಕಲ್ಪಿಸಿ.', 
                    style: TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isInitStatus = true);
                    _checkNetwork();
                  },
                  icon: Icon(Icons.refresh, color: Colors.white),
                  label: Text('ಮರುಪ್ರಯತ್ನಿಸಿ'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        icon: Icon(Icons.folder_open, color: Colors.white),
        label: Text('ಉಳಿಸಿದ ಜಾತಕ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B6CB0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _buildProfileListSheet(),
          );
        },
      ),
    );
  }

  Widget _buildProfileListSheet() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('ಉಳಿಸಿದ ಜಾತಕಗಳು', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2B6CB0))),
          ),
          if (_savedProfiles.isEmpty)
            Padding(padding: EdgeInsets.all(32), child: Text('ಯಾವುದೇ ಜಾತಕ ಉಳಿಸಿಲ್ಲ.'))
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _savedProfiles.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final name = _savedProfiles.keys.elementAt(i);
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFEDF2F7), child: Icon(Icons.person, color: Color(0xFF2B6CB0))),
                    title: Text(name, style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${_savedProfiles[name]!.date} | ${_savedProfiles[name]!.place}'),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadProfile(name);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✨ ಹೊಸ ಜಾತಕ', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: const Color(0xFF2B6CB0))),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'ಹೆಸರು',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),

          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today, color: kMuted),
                const SizedBox(width: 10),
                Text(
                  'ದಿನಾಂಕ: ${_dob.day.toString().padLeft(2,'0')}-${_dob.month.toString().padLeft(2,'0')}-${_dob.year}',
                  style: TextStyle(fontSize: 14, color: kText),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Time picker
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.access_time, color: kMuted),
                const SizedBox(width: 10),
                Text(
                  'ಸಮಯ: ${_hour.toString().padLeft(2,'0')}:${_minute.toString().padLeft(2,'0')} $_ampm',
                  style: TextStyle(fontSize: 14, color: kText),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),

          // Offline place selector
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'ಊರು ಆಯ್ಕೆ',
              prefixIcon: Icon(Icons.location_city),
            ),
            isExpanded: true,
            items: offlinePlaces.keys.map((name) => DropdownMenuItem(
              value: name, child: Text(name, style: TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) {
              if (v != null && offlinePlaces.containsKey(v)) {
                final coords = offlinePlaces[v]!;
                setState(() {
                  _placeCtrl.text = v;
                  _latCtrl.text = coords[0].toStringAsFixed(4);
                  _lonCtrl.text = coords[1].toStringAsFixed(4);
                  _geoStatus = 'ಊರು: $v';
                });
              }
            },
          ),
          if (_geoStatus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
          ],
          const SizedBox(height: 10),

          // Online place search
          Row(children: [
            Expanded(
              child: TextField(
                controller: _placeCtrl,
                decoration: const InputDecoration(labelText: 'ಊರು ಹುಡುಕಿ', prefixIcon: Icon(Icons.search)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _geoLoading ? null : _geocode,
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14)),
              child: _geoLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('ಹುಡುಕಿ', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 14),

          // Lat/Lon
          Row(children: [
            Expanded(
              child: TextField(
                controller: _latCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'ಅಕ್ಷಾಂಶ'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _lonCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'ರೇಖಾಂಶ'),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Advanced options
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('⚙️ ಸುಧಾರಿತ ಆಯ್ಕೆಗಳು', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              children: [
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ayanamsa,
                      decoration: const InputDecoration(labelText: 'ಅಯನಾಂಶ'),
                      items: ['ಲಾಹಿರಿ','ರಾಮನ್','ಕೆ.ಪಿ'].map((v) => DropdownMenuItem(
                        value: v, child: Text(v, style: TextStyle()))).toList(),
                      onChanged: (v) => setState(() => _ayanamsa = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _nodeMode,
                      decoration: const InputDecoration(labelText: 'ರಾಹು'),
                      items: ['ನಿಜ ರಾಹು','ಸರಾಸರಿ ರಾಹು'].map((v) => DropdownMenuItem(
                        value: v, child: Text(v, style: TextStyle()))).toList(),
                      onChanged: (v) => setState(() => _nodeMode = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Three action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => _buildProfileListSheet(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B6CB0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('ತೆರೆಯಿರಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final now = DateTime.now();
                  setState(() {
                    _dob = now;
                    _hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
                    _minute = now.minute;
                    _ampm = now.hour >= 12 ? 'PM' : 'AM';
                    _loadedNotes = '';
                    _loadedAroodhas = {};
                  });
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
                    : Text('ರಚಿಸಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: kPurple2),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _ampm == 'PM' && _hour != 12 ? _hour + 12 : (_ampm == 'AM' && _hour == 12 ? 0 : _hour),
        minute: _minute,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: kPurple2),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        final h24 = picked.hour;
        _ampm = h24 >= 12 ? 'PM' : 'AM';
        _hour = h24 % 12 == 0 ? 12 : h24 % 12;
        _minute = picked.minute;
      });
    }
  }
}
