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
import '../services/google_auth_service.dart';
import '../services/calendar_service.dart';
import '../services/ad_service.dart';
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
  bool _loadedFromSaved = false; // true when user opened an existing profile

  String _loadedNotes = '';
  Map<String, int> _loadedAroodhas = {};
  int? _loadedJanmaNakshatraIdx;

  // Additional info
  final _gotraCtrl  = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  String _gender = 'ಗಂಡು';
  bool _showExtraInfo = false;

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
      _loadedFromSaved = true; // mark as existing — updates go in-place
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
        _dob = DateTime.now();
      }
    });
  }

  Future<void> _geocodeMultiple(String placeName) async {
    if (placeName.trim().isEmpty) return;
    setState(() { _geoLoading = true; _geoStatus = ''; });
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setState(() => _geoStatus = 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.');
        } else if (data.length == 1) {
          // Single result — auto-fill
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          setState(() {
            _placeCtrl.text = placeName.trim();
            _latCtrl.text = lat.toStringAsFixed(4);
            _lonCtrl.text = lon.toStringAsFixed(4);
            _geoStatus = '📍 ${data[0]['display_name']}';
          });
        } else {
          // Multiple results — show disambiguation dialog
          if (mounted) {
            _showPlaceDisambiguation(data);
          }
        }
      }
    } catch (_) {
      setState(() => _geoStatus = 'ಸ್ಥಳ ಸಂಪರ್ಕ ದೋಷ. ನೇರವಾಗಿ ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ ನಮೂದಿಸಿ.');
    }
    setState(() => _geoLoading = false);
  }

  void _showPlaceDisambiguation(List<dynamic> results) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('ಸ್ಥಳ ಆಯ್ಕೆಮಾಡಿ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1)),
            ),
            Text('ಒಂದೇ ಹೆಸರಿನ ಹಲವು ಸ್ಥಳಗಳು ಕಂಡುಬಂದಿವೆ:', style: TextStyle(fontSize: 13, color: kMuted)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (_, i) {
                  final place = results[i];
                  final displayName = place['display_name'] ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPurple1.withOpacity(0.1),
                      child: Icon(Icons.location_on, color: kPurple1, size: 20),
                    ),
                    title: Text(displayName, style: TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(ctx);
                      final lat = double.parse(place['lat']);
                      final lon = double.parse(place['lon']);
                      setState(() {
                        _latCtrl.text = lat.toStringAsFixed(4);
                        _lonCtrl.text = lon.toStringAsFixed(4);
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
        // Show interstitial ad before opening Dashboard
        void navigateToDashboard() {
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(
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
              extraInfo: {
                'gotra': _gotraCtrl.text.trim(),
                'father': _fatherCtrl.text.trim(),
                'mother': _motherCtrl.text.trim(),
                'gender': _gender,
              },
              onSave: (notes, aroodhas, janmaIdx, {bool isNew = true}) =>
                  _saveProfile(notes: notes, aroodhas: aroodhas, janmaNakshatraIdx: janmaIdx, isNew: !_loadedFromSaved),
            ),
          ));
        }
        setState(() => _loading = false);
        AdService.showInterstitialAd(context, onDismissed: navigateToDashboard);
        return; // loading flag already cleared above

        // Reset the form back to current time/empty strings when returning
        if (mounted) {
          final now = DateTime.now();
          setState(() {
            _loadedFromSaved = false;
            _nameCtrl.clear();
            _placeCtrl.clear();
            _latCtrl.clear();
            _lonCtrl.clear();
            _gotraCtrl.clear();
            _fatherCtrl.clear();
            _motherCtrl.clear();
            _gender = 'ಗಂಡು';
            _showExtraInfo = false;
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

  void _saveProfile({String notes = '', Map<String, int> aroodhas = const {}, int? janmaNakshatraIdx, bool isNew = true}) async {
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
              // Google sign-in + appointment row
              _buildGoogleRow(),
              const SizedBox(height: 8),
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
          backgroundColor: kPurple2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: kBg,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (_) => _buildProfileListSheet(),
          );
        },
      ),
    );
  }

  Widget _buildProfileListSheet() {
    String searchQuery = '';
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        final filtered = searchQuery.isEmpty
          ? _savedProfiles
          : Map.fromEntries(_savedProfiles.entries.where((e) =>
              e.key.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.value.place.toLowerCase().contains(searchQuery.toLowerCase()) ||
              e.value.date.contains(searchQuery)));

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('ಉಳಿಸಿದ ಜಾತಕಗಳು', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2)),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setSheetState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'ಹೆಸರು, ಸ್ಥಳ ಅಥವಾ ದಿನಾಂಕ ಹುಡುಕಿ...',
                    prefixIcon: Icon(Icons.search, color: kMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                    fillColor: kCard,
                    filled: true,
                  ),
                  style: TextStyle(color: kText),
                ),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Padding(padding: EdgeInsets.all(32), child: Text(searchQuery.isEmpty ? 'ಯಾವುದೇ ಜಾತಕ ಉಳಿಸಿಲ್ಲ.' : 'ಯಾವುದೇ ಫಲಿತಾಂಶ ಕಂಡುಬಂದಿಲ್ಲ.', style: TextStyle(color: kMuted)))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final name = filtered.keys.elementAt(i);
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: kBorder, child: Icon(Icons.person, color: kPurple2)),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                        subtitle: Text('${filtered[name]!.date} | ${filtered[name]!.place}', style: TextStyle(color: kMuted)),
                        trailing: Icon(Icons.chevron_right, color: kMuted),
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
      },
    );
  }

  Widget _buildGoogleRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: GoogleAuthService.isSignedIn
        ? Row(children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              GoogleAuthService.userEmail ?? '',
              style: TextStyle(fontSize: 12, color: kMuted),
              overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showAppointmentDialog(),
              icon: Icon(Icons.event, size: 16),
              label: Text('ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
          ])
        : Row(children: [
            Icon(Icons.account_circle, color: kPurple2, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Google Sign In ಮಾಡಿ',
              style: TextStyle(fontSize: 13, color: kText),
            )),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await GoogleAuthService.signIn();
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Google Sign In ಯಶಸ್ವಿ!' : 'Sign In ವಿಫಲ'),
                  ));
                }
              },
              icon: Icon(Icons.login, size: 16),
              label: Text('Sign In', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPurple2,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
            ),
          ]),
    );
  }

  void _showAppointmentDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int durationMinutes = 60;
    final clientNameCtrl = TextEditingController(text: _nameCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: kCard,
          title: Text('ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ರಚಿಸಿ', style: TextStyle(color: kText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientNameCtrl,
                decoration: InputDecoration(
                  labelText: 'ಗ್ರಾಹಕರ ಹೆಸರು',
                  labelStyle: TextStyle(color: kMuted),
                  isDense: true,
                ),
                style: TextStyle(color: kText),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.calendar_today, color: kPurple2),
                title: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: TextStyle(color: kText)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDialogState(() => selectedDate = d);
                },
              ),
              ListTile(
                leading: Icon(Icons.access_time, color: kPurple2),
                title: Text(selectedTime.format(ctx), style: TextStyle(color: kText)),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (t != null) setDialogState(() => selectedTime = t);
                },
              ),
              ListTile(
                leading: Icon(Icons.timer, color: kPurple2),
                title: Text('$durationMinutes ನಿಮಿಷ', style: TextStyle(color: kText)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: Icon(Icons.remove, color: kMuted), onPressed: () {
                    if (durationMinutes > 15) setDialogState(() => durationMinutes -= 15);
                  }),
                  IconButton(icon: Icon(Icons.add, color: kMuted), onPressed: () {
                    setDialogState(() => durationMinutes += 15);
                  }),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ರದ್ದು', style: TextStyle(color: kMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final startTime = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                );
                final name = clientNameCtrl.text.isEmpty ? 'ಗ್ರಾಹಕ' : clientNameCtrl.text;
                final ok = await CalendarService.createAppointment(
                  clientName: name,
                  startTime: startTime,
                  duration: Duration(minutes: durationMinutes),
                  description: 'ಜಾತಕ ವಿಶ್ಲೇಷಣೆ - $name',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Calendar ಗೆ ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ಸೇರಿಸಲಾಗಿದೆ!' : 'ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್ ವಿಫಲ'),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
              child: Text('ರಚಿಸಿ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✨ ಹೊಸ ಜಾತಕ', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
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
                color: kCard,
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
                color: kCard,
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

          // Searchable Place Selector (Offline + Online)
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return offlinePlaces.keys.take(15);
              }
              final query = textEditingValue.text.toLowerCase();
              return offlinePlaces.keys.where(
                  (name) => name.toLowerCase().contains(query));
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'ಊರು ಹುಡುಕಿ',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _geoLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : IconButton(
                        icon: Icon(Icons.my_location, color: kTeal),
                        onPressed: () {
                          _placeCtrl.text = textEditingController.text;
                          _geocodeMultiple(textEditingController.text);
                        },
                      ),
                ),
                onSubmitted: (_) {
                  _placeCtrl.text = textEditingController.text;
                  _geocodeMultiple(textEditingController.text);
                },
              );
            },
            onSelected: (String selection) {
              if (offlinePlaces.containsKey(selection)) {
                final coords = offlinePlaces[selection]!;
                setState(() {
                  _placeCtrl.text = selection;
                  _latCtrl.text = coords[0].toStringAsFixed(4);
                  _lonCtrl.text = coords[1].toStringAsFixed(4);
                  _geoStatus = '📍 $selection';
                });
              }
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
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
            const SizedBox(height: 6),
            Text(_geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
          ],
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
          // ─── Additional Info dropdown ───────────────────────────
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showExtraInfo = !_showExtraInfo),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: Row(children: [
                Icon(Icons.person_outline, color: kPurple2, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('ಹೆಚ್ಚಿನ ವಿವರ (ಗೋತ್ರ, ತಂದೆ, ತಾಯಿ)', style: TextStyle(color: kText, fontSize: 13))),
                Icon(_showExtraInfo ? Icons.expand_less : Icons.expand_more, color: kMuted),
              ]),
            ),
          ),
          if (_showExtraInfo) ...[
            const SizedBox(height: 8),
            // Gender
            Row(children: [
              Text('ಲಿಂಗ: ', style: TextStyle(color: kText, fontSize: 13)),
              const SizedBox(width: 8),
              ...['ಗಂಡು', 'ಹೆಂಣು', 'ಇತರ'].map((g) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(g, style: TextStyle(color: _gender == g ? Colors.white : kText)),
                  selected: _gender == g,
                  selectedColor: kPurple2,
                  backgroundColor: kCard,
                  side: BorderSide(color: kBorder),
                  onSelected: (_) => setState(() => _gender = g),
                ),
              )).toList(),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _gotraCtrl,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'ಗೋತ್ರ (Gotra)',
                labelStyle: TextStyle(color: kMuted),
                prefixIcon: Icon(Icons.family_restroom, color: kPurple2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                fillColor: kCard, filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fatherCtrl,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'ತಂದೆ ಹೆಸರು',
                labelStyle: TextStyle(color: kMuted),
                prefixIcon: Icon(Icons.man, color: kPurple2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                fillColor: kCard, filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _motherCtrl,
              style: TextStyle(color: kText),
              decoration: InputDecoration(
                labelText: 'ತಾಯಿ ಹೆಸರು',
                labelStyle: TextStyle(color: kMuted),
                prefixIcon: Icon(Icons.woman, color: kPurple2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kBorder)),
                fillColor: kCard, filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],

          // Three action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: kCard,
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
