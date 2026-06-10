import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/export_service.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../widgets/shadbala_widget.dart';
import '../widgets/ashtakavarga_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/storage_service.dart';
import '../services/client_service.dart'; // FIX: Imported missing ClientService
import '../services/history_service.dart';

import '../services/google_auth_service.dart';
import '../services/sheets_service.dart';
import '../services/docs_service.dart';
import '../services/calendar_service.dart';
import '../services/location_service.dart';
import '../services/janma_patrike_service.dart'; // NEW
import '../services/pdf_theme.dart';
import '../constants/places.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final KundaliResult result;
  final String name;
  final String place;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final String initialNotes;
  final Map<String, int> initialAroodhas;
  final int? initialJanmaNakshatraIdx;
  final Map<String, String> extraInfo;
  final List<String> initialGroupMembers;
  final void Function(String notes, Map<String, int> aroodhas, int? janmaNakshatraIdx, {bool isNew}) onSave;

  const DashboardScreen({
    super.key,
    required this.result,
    required this.name,
    required this.place,
    required this.dob,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    this.initialNotes = '',
    this.initialAroodhas = const {},
    this.initialJanmaNakshatraIdx,
    this.extraInfo = const {},
    this.initialGroupMembers = const [],
    required this.onSave,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _PersonEntry {
  final String name;
  final KundaliResult result;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final String place;
  String notes;

  _PersonEntry({
    required this.name,
    required this.result,
    required this.dob,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.place,
    this.notes = '',
  });
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabCtrl;
  String _notes = '';
  final _newNoteController = TextEditingController();
  int _resumeKey = 0; // Incremented on app resume to force full repaint
  Map<String, int> _aroodhas = {};
  int? _janmaNakshatraIdx;
  int? _dinaNakshatraIdx;
  String? _bhavaPlanet; // planet selected for bhava recalculation
  KundaliResult? _prastutaResult; // For Aroodha tab's Prastuta button
  DateTime? _prastutaTime; // Time used for prastuta chart
  String _prastutaPlace = ''; // Place used for prastuta chart
  double _prastutaLat = 0;
  double _prastutaLon = 0;
  double _prastutaTz = 5.5;
  
  // Janma Patrike states
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _gotraCtrl = TextEditingController();
  final _jyotishiNameCtrl = TextEditingController();
  final _jyotishiPhoneCtrl = TextEditingController();
  String _selectedThemeId = 'traditional';


  // Multi-person support
  final List<_PersonEntry> _extraPersons = [];

  // Mutable primary person (editable)
  late String _primaryName;
  late KundaliResult _primaryResult;
  late DateTime _primaryDob;
  late int _primaryHour;
  late int _primaryMinute;
  late String _primaryAmpm;
  late double _primaryLat;
  late double _primaryLon;
  late String _primaryPlace;

  bool _syncing = false;

  /// Translate dasha balance suffixes (ವ=years, ತಿ=months, ದಿ=days)
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



  static List<String> get _tabs {
    switch (AppLocale.current) {
      case 'hi': return ['पंचांग', 'कुंडली', 'स्फुट', 'आरूढ', 'दशा', 'भाव', 'ग्रह षड्वर्ग', 'षड्बल', 'अष्टक', 'टिप्पणी', 'पत्रिका'];
      case 'ta': return ['பஞ்சாங்கம்', 'ஜாதகம்', 'ஸ்புடம்', 'ஆரூடம்', 'தசை', 'பாவம்', 'ஷட்வர்கம்', 'ஷட்பலம்', 'அஷ்டகம்', 'குறிப்பு', 'பத்ரிகை'];
      case 'te': return ['పంచాంగం', 'కుండలి', 'స్ఫుటం', 'ఆరూఢం', 'దశ', 'భావం', 'షడ్వర్గం', 'షడ్బలం', 'అష్టకం', 'గమనికలు', 'పత్రిక'];
      case 'ml': return ['പഞ്ചാംഗം', 'ജാതകം', 'സ്ഫുടം', 'ആരൂഢം', 'ദശ', 'ഭാവം', 'ഷഡ്വർഗം', 'ഷഡ്ബലം', 'അഷ്ടകം', 'കുറിപ്പുകൾ', 'പത്രിക'];
      default: return ['ಪಂಚಾಂಗ', 'ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಆರೂಢ', 'ದಶ', 'ಭಾವ', 'ಗ್ರಹ ಷಡ್ವರ್ಗ', 'ಷಡ್ಬಲ', 'ಅಷ್ಟಕ', 'ಟಿಪ್ಪಣಿ', 'ಪತ್ರಿಕೆ'];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabCtrl = TabController(length: _tabs.length, vsync: this); // 11 tabs
    _notes = widget.initialNotes;
    _aroodhas = Map.from(widget.initialAroodhas);
    _janmaNakshatraIdx = widget.initialJanmaNakshatraIdx;

    // Initialize mutable primary person from widget
    _primaryName = widget.name;
    _primaryResult = widget.result;
    _primaryDob = widget.dob;
    _primaryHour = widget.hour;
    _primaryMinute = widget.minute;
    _primaryAmpm = widget.ampm;
    _primaryLat = widget.lat;
    _primaryLon = widget.lon;
    _primaryPlace = widget.place;


    final panchangNakName = widget.result.panchang.nakshatra.split(' ')[0];
    int panchangNakIdx = knNak.indexWhere((n) => panchangNakName.startsWith(n));
    _dinaNakshatraIdx = panchangNakIdx != -1 ? panchangNakIdx : 0;

    _loadJanmaNakshatra();

    // Auto-load group members if saved previously
    if (widget.initialGroupMembers.isNotEmpty) {
      _loadGroupMembers();
    }

    _loadJyotishiDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.dispose();
    _newNoteController.dispose();
    _fatherNameCtrl.dispose();
    _motherNameCtrl.dispose();
    _gotraCtrl.dispose();
    _jyotishiNameCtrl.dispose();
    _jyotishiPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lightweight repaint on resume — fixes blank charts without destroying widget tree
    if (state == AppLifecycleState.resumed && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
    }
  }
  Future<void> _loadJyotishiDetails() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _jyotishiNameCtrl.text = prefs.getString('jyotishi_name') ?? '';
        _jyotishiPhoneCtrl.text = prefs.getString('jyotishi_phone') ?? '';
      });
    }
  }

  Future<void> _saveJyotishiDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jyotishi_name', _jyotishiNameCtrl.text.trim());
    await prefs.setString('jyotishi_phone', _jyotishiPhoneCtrl.text.trim());
  }

  /// Show simple 2-option dialog to add a person
  void _showAddPersonDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Text(AppLocale.l('addPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: kTeal.withOpacity(0.15),
                child: Icon(Icons.add, color: kTeal),
              ),
              title: Text(AppLocale.l('addNewPerson'), style: TextStyle(color: kTeal, fontWeight: FontWeight.w800)),
              subtitle: Text(AppLocale.l('newPersonHint'), style: TextStyle(color: kMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showNewPersonForm();
              },
            ),
            Divider(color: kBorder),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: kPurple2.withOpacity(0.15),
                child: Icon(Icons.folder_open, color: kPurple2),
              ),
              title: Text(AppLocale.l('addFromSaved'), style: TextStyle(color: kPurple2, fontWeight: FontWeight.w800)),
              subtitle: Text(AppLocale.l('savedListHint'), style: TextStyle(color: kMuted, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _showSavedProfilesListDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
        ],
      ),
    );
  }

  /// Show the combined list of saved profiles (StorageService + ClientService)
  void _showSavedProfilesListDialog() async {
    final storageProfilesResponse = await StorageService.loadAll();
    final allProfiles = storageProfilesResponse.values.toList();
    
    // Merge Appointment Members
    for (var client in ClientService.clients) {
      final members = ClientService.getMembersForClient(client.clientId);
      for (var m in members) {
        if (m.dob.isNotEmpty && m.birthTime.isNotEmpty && m.lat != 0) {
          // Unconditionally sync the Profile inside allProfiles to match the True Appointments Client ID!
          final index = allProfiles.indexWhere((p) => p.name == m.memberName);
          if (index == -1) {
            allProfiles.add(Profile(
              name: m.memberName,
              date: m.dob,
              hour: m.hour12,
              minute: m.minute,
              ampm: m.ampm,
              lat: m.lat,
              lon: m.lon,
              place: m.birthPlace,
              notes: m.notes,
              tzOffset: LocationService.tzOffset,
              clientId: m.clientId,
            ));
          } else {
            final op = allProfiles[index];
            allProfiles[index] = Profile(
               name: op.name, date: op.date, hour: op.hour, minute: op.minute, ampm: op.ampm,
               lat: op.lat, lon: op.lon, tzOffset: op.tzOffset, place: op.place, notes: op.notes,
               aroodhas: op.aroodhas, janmaNakshatraIdx: op.janmaNakshatraIdx,
               clientId: m.clientId, // Force exact sync with Appointment Database
               groupMembers: op.groupMembers, // Preserve multi-person group!
            );
          }
        }
      }
    }

    if (!mounted) return;

    final otherProfiles = allProfiles
        .where((p) => p.name != widget.name)
        .where((p) => !_extraPersons.any((ep) => ep.name == p.name))
        .toList();

    // Sort ascending by Client ID ("BH-2026-0001", "BH-2026-0002" ...) so they display in exact serial order
    otherProfiles.sort((a, b) {
      final aId = a.clientId ?? '';
      final bId = b.clientId ?? '';
      if (aId.isEmpty && bId.isNotEmpty) return 1;
      if (aId.isNotEmpty && bId.isEmpty) return -1;
      return aId.compareTo(bId); // Ascending serial order
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Text(AppLocale.l('selectSavedProfile'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: otherProfiles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocale.l('noOtherProfiles'), textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherProfiles.length,
                  itemBuilder: (context, i) {
                    final p = otherProfiles[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPurple2.withOpacity(0.15),
                        child: Text(p.name.isNotEmpty ? p.name[0] : '?', style: TextStyle(color: kPurple2, fontWeight: FontWeight.w900)),
                      ),
                      title: Text(p.name, style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
                      subtitle: Text('${p.date} | ${p.place}', style: TextStyle(color: kMuted, fontSize: 12)),
                      onTap: () => _addSavedProfile(ctx, p),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('back'), style: TextStyle(color: kMuted))),
        ],
      ),
    );
  }

  /// Add a saved profile as an extra person
  void _addSavedProfile(BuildContext ctx, Profile p) async {
    Navigator.pop(ctx);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⏳ ${p.name} ${AppLocale.l('calcInProgress')}')),
    );
    try {
      final dateParts = p.date.split('-');
      final dob = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
      int h24 = p.hour;
      if (p.ampm == 'PM' && h24 != 12) h24 += 12;
      if (p.ampm == 'AM' && h24 == 12) h24 = 0;
      final localHour = h24 + p.minute / 60.0;
      final result = await AstroCalculator.calculate(
        year: dob.year, month: dob.month, day: dob.day,
        hourUtcOffset: p.tzOffset, hour24: localHour,
        lat: p.lat, lon: p.lon, ayanamsaMode: 'lahiri', trueNode: true,
      );
      if (result == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
        return;
      }
      if (mounted) {
        setState(() {
          _extraPersons.add(_PersonEntry(name: p.name, result: result, dob: dob, hour: p.hour, minute: p.minute, ampm: p.ampm, lat: p.lat, lon: p.lon, place: p.place, notes: p.notes));
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red));
    }
  }

  /// Show form to add a brand new person
  void _showNewPersonForm() {
    final nameCtrl = TextEditingController();
    final placeCtrl = TextEditingController(text: LocationService.place);
    final latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    final lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    final tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
    
    DateTime dob = DateTime.now();
    int hour = dob.hour % 12 == 0 ? 12 : dob.hour % 12;
    int minute = dob.minute;
    String ampm = dob.hour >= 12 ? 'PM' : 'AM';
    
    bool geoLoading = false;
    String geoStatus = '';

    Future<void> performGeocode(String placeName, Function setS) async {
      if (placeName.trim().isEmpty) return;
      setS(() { geoLoading = true; geoStatus = ''; });
      try {
        final q = Uri.encodeComponent(placeName.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
        final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as List;
          if (data.isEmpty) {
            setS(() => geoStatus = AppLocale.l('placeNotFoundDash'));
          } else {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final displayName = data[0]['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon);
            setS(() {
              placeCtrl.text = placeName.trim();
              latCtrl.text = lat.toStringAsFixed(4);
              lonCtrl.text = lon.toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        }
      } catch (_) {
        setS(() => geoStatus = AppLocale.l('placeError'));
      }
      setS(() => geoLoading = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return AlertDialog(
          backgroundColor: kBg,
          title: Text(AppLocale.l('newPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx2,
                      initialDate: dob,
                      firstDate: DateTime(1800),
                      lastDate: DateTime(2100),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!),
                    );
                    if (d != null) setS(() => dob = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: kMuted),
                      const SizedBox(width: 10),
                      Text('${AppLocale.l('dateLabel')}: ${dob.day.toString().padLeft(2,'0')}-${dob.month.toString().padLeft(2,'0')}-${dob.year}', style: TextStyle(fontSize: 14, color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // Time picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay(
                        hour: ampm == 'PM' && hour != 12 ? hour + 12 : (ampm == 'AM' && hour == 12 ? 0 : hour),
                        minute: minute,
                      ),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!),
                    );
                    if (picked != null) {
                      setS(() {
                        final h24 = picked.hour;
                        ampm = h24 >= 12 ? 'PM' : 'AM';
                        hour = h24 % 12 == 0 ? 12 : h24 % 12;
                        minute = picked.minute;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.access_time, color: kMuted),
                      const SizedBox(width: 10),
                      Text('${AppLocale.l('timeLabel')}: ${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')} $ampm', style: TextStyle(fontSize: 14, color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),

                // Searchable Place Selector
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return offlinePlaces.keys.take(15);
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return offlinePlaces.keys.where((name) => name.toLowerCase().contains(query));
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Start with the Place populated, unlike input_screen which manages it via state
                    if (placeCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                      textEditingController.text = placeCtrl.text;
                    }
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocale.l('searchPlace'),
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: geoLoading
                          ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(
                              icon: Icon(Icons.my_location, color: kTeal),
                              onPressed: () {
                                placeCtrl.text = textEditingController.text;
                                performGeocode(textEditingController.text, setS);
                              },
                            ),
                      ),
                      onSubmitted: (_) {
                        placeCtrl.text = textEditingController.text;
                        performGeocode(textEditingController.text, setS);
                      },
                      onChanged: (val) {
                        placeCtrl.text = val;
                      },
                    );
                  },
                  onSelected: (String selection) async {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                        tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        geoStatus = '📍 $selection (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
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
                if (geoStatus.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(geoStatus, style: TextStyle(fontSize: 12, color: kGreen)),
                ],
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: AppLocale.l('latLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: InputDecoration(labelText: AppLocale.l('lonLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'TZ', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⏳ $name ${AppLocale.l('calcInProgress')}')));
                try {
                  int h24 = hour;
                  if (ampm == 'PM' && h24 != 12) h24 += 12;
                  if (ampm == 'AM' && h24 == 12) h24 = 0;
                  final localHour = h24 + minute / 60.0;
                  final lat = double.tryParse(latCtrl.text) ?? 14.98;
                  final lon = double.tryParse(lonCtrl.text) ?? 74.73;
                  final tz = double.tryParse(tzCtrl.text) ?? 5.5;
                  
                  final result = await AstroCalculator.calculate(
                    year: dob.year, month: dob.month, day: dob.day,
                    hourUtcOffset: tz, hour24: localHour,
                    lat: lat, lon: lon, ayanamsaMode: 'lahiri', trueNode: true,
                  );
                  
                  if (result == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
                    return;
                  }
                  
                  if (mounted) {
                    setState(() {
                      _extraPersons.add(_PersonEntry(name: name, result: result, dob: dob, hour: hour, minute: minute, ampm: ampm, lat: lat, lon: lon, place: placeCtrl.text));
                    });
                    HistoryService.add(HistoryEntry(
                      name: name,
                      date: '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}',
                      hour: hour, minute: minute, ampm: ampm,
                      lat: lat, lon: lon, tzOffset: tz,
                      place: placeCtrl.text,
                      timestamp: DateTime.now().toIso8601String(),
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $name ${AppLocale.l('calcSuccess')}'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocale.l('calculate'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  /// Show form to edit an existing extra person's details
  void _showEditPersonDialog(String personName) {
    final idx = _extraPersons.indexWhere((p) => p.name == personName);
    if (idx == -1) return;
    final existing = _extraPersons[idx];

    final nameCtrl = TextEditingController(text: existing.name);
    final placeCtrl = TextEditingController(text: existing.place);
    final latCtrl = TextEditingController(text: existing.lat.toStringAsFixed(4));
    final lonCtrl = TextEditingController(text: existing.lon.toStringAsFixed(4));
    final tzCtrl = TextEditingController(text: '+5.5');

    DateTime dob = existing.dob;
    int hour = existing.hour;
    int minute = existing.minute;
    String ampm = existing.ampm;

    bool geoLoading = false;
    String geoStatus = '';

    Future<void> performGeocode(String placeName, Function setS) async {
      if (placeName.trim().isEmpty) return;
      setS(() { geoLoading = true; geoStatus = ''; });
      try {
        final q = Uri.encodeComponent(placeName.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
        final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as List;
          if (data.isEmpty) {
            setS(() => geoStatus = AppLocale.l('placeNotFoundDash'));
          } else {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final displayName = data[0]['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon);
            setS(() {
              placeCtrl.text = placeName.trim();
              latCtrl.text = lat.toStringAsFixed(4);
              lonCtrl.text = lon.toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        }
      } catch (_) {
        setS(() => geoStatus = AppLocale.l('placeError'));
      }
      setS(() => geoLoading = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return AlertDialog(
          backgroundColor: kBg,
          title: Text(AppLocale.l('editPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx2, initialDate: dob,
                      firstDate: DateTime(1800), lastDate: DateTime(2100),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!),
                    );
                    if (d != null) setS(() => dob = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: kMuted), const SizedBox(width: 10),
                      Text('${AppLocale.l('dateLabel')}: ${dob.day.toString().padLeft(2,'0')}-${dob.month.toString().padLeft(2,'0')}-${dob.year}', style: TextStyle(fontSize: 14, color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay(
                        hour: ampm == 'PM' && hour != 12 ? hour + 12 : (ampm == 'AM' && hour == 12 ? 0 : hour),
                        minute: minute,
                      ),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!),
                    );
                    if (picked != null) {
                      setS(() {
                        final h24 = picked.hour;
                        ampm = h24 >= 12 ? 'PM' : 'AM';
                        hour = h24 % 12 == 0 ? 12 : h24 % 12;
                        minute = picked.minute;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.access_time, color: kMuted), const SizedBox(width: 10),
                      Text('${AppLocale.l('timeLabel')}: ${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')} $ampm', style: TextStyle(fontSize: 14, color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return offlinePlaces.keys.take(15);
                    final query = textEditingValue.text.toLowerCase();
                    return offlinePlaces.keys.where((name) => name.toLowerCase().contains(query));
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (placeCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                      textEditingController.text = placeCtrl.text;
                    }
                    return TextField(
                      controller: textEditingController, focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocale.l('searchPlace'), prefixIcon: Icon(Icons.search),
                        suffixIcon: geoLoading
                          ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: Icon(Icons.my_location, color: kTeal), onPressed: () { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); }),
                      ),
                      onSubmitted: (_) { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); },
                      onChanged: (val) => placeCtrl.text = val,
                    );
                  },
                  onSelected: (String selection) async {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                        tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        geoStatus = '📍 $selection (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
                      });
                    }
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0, borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                          child: ListView.builder(
                            padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(dense: true, leading: Icon(Icons.location_on, size: 18, color: kPurple2), title: Text(option, style: TextStyle(fontSize: 13)), onTap: () => onSelected(option));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (geoStatus.isNotEmpty) ...[const SizedBox(height: 6), Text(geoStatus, style: TextStyle(fontSize: 12, color: kGreen))],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: AppLocale.l('latLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: InputDecoration(labelText: AppLocale.l('lonLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'TZ', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⏳ $name ${AppLocale.l('calcInProgress')}')));
                try {
                  int h24 = hour;
                  if (ampm == 'PM' && h24 != 12) h24 += 12;
                  if (ampm == 'AM' && h24 == 12) h24 = 0;
                  final localHour = h24 + minute / 60.0;
                  final lat = double.tryParse(latCtrl.text) ?? 14.98;
                  final lon = double.tryParse(lonCtrl.text) ?? 74.73;
                  final tz = double.tryParse(tzCtrl.text) ?? 5.5;

                  final result = await AstroCalculator.calculate(
                    year: dob.year, month: dob.month, day: dob.day,
                    hourUtcOffset: tz, hour24: localHour,
                    lat: lat, lon: lon, ayanamsaMode: 'lahiri', trueNode: false,
                  );

                  if (result == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
                    return;
                  }

                  if (mounted) {
                    setState(() {
                      _extraPersons[idx] = _PersonEntry(name: name, result: result, dob: dob, hour: hour, minute: minute, ampm: ampm, lat: lat, lon: lon, place: placeCtrl.text, notes: existing.notes);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $name ${AppLocale.l('calcSuccess')}'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocale.l('calculate'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  /// Show form to edit the primary person's details
  void _showEditPrimaryDialog() {
    final nameCtrl = TextEditingController(text: _primaryName);
    final placeCtrl = TextEditingController(text: _primaryPlace);
    final latCtrl = TextEditingController(text: _primaryLat.toStringAsFixed(4));
    final lonCtrl = TextEditingController(text: _primaryLon.toStringAsFixed(4));
    final tzCtrl = TextEditingController(text: '+5.5');

    DateTime dob = _primaryDob;
    int hour = _primaryHour;
    int minute = _primaryMinute;
    String ampm = _primaryAmpm;

    bool geoLoading = false;
    String geoStatus = '';

    Future<void> performGeocode(String placeName, Function setS) async {
      if (placeName.trim().isEmpty) return;
      setS(() { geoLoading = true; geoStatus = ''; });
      try {
        final q = Uri.encodeComponent(placeName.trim());
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=1');
        final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as List;
          if (data.isEmpty) {
            setS(() => geoStatus = AppLocale.l('placeNotFoundDash'));
          } else {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final displayName = data[0]['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon);
            setS(() {
              placeCtrl.text = placeName.trim();
              latCtrl.text = lat.toStringAsFixed(4);
              lonCtrl.text = lon.toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
              geoStatus = '📍 ${data[0]['display_name']} (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
            });
          }
        }
      } catch (_) {
        setS(() => geoStatus = AppLocale.l('placeError'));
      }
      setS(() => geoLoading = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setS) {
        return AlertDialog(
          backgroundColor: kBg,
          title: Text(AppLocale.l('editPerson'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: AppLocale.l('nameLabel'), prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx2, initialDate: dob,
                      firstDate: DateTime(1800), lastDate: DateTime(2100),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!),
                    );
                    if (d != null) setS(() => dob = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: kMuted), const SizedBox(width: 10),
                      Text('${AppLocale.l('dateLabel')}: ${dob.day.toString().padLeft(2,'0')}-${dob.month.toString().padLeft(2,'0')}-${dob.year}', style: TextStyle(fontSize: 14, color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay(
                        hour: ampm == 'PM' && hour != 12 ? hour + 12 : (ampm == 'AM' && hour == 12 ? 0 : hour),
                        minute: minute,
                      ),
                      builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!),
                    );
                    if (picked != null) {
                      setS(() {
                        final h24 = picked.hour;
                        ampm = h24 >= 12 ? 'PM' : 'AM';
                        hour = h24 % 12 == 0 ? 12 : h24 % 12;
                        minute = picked.minute;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.access_time, color: kMuted), const SizedBox(width: 10),
                      Text('${AppLocale.l('timeLabel')}: ${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')} $ampm', style: TextStyle(fontSize: 14, color: kText)),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) return offlinePlaces.keys.take(15);
                    final query = textEditingValue.text.toLowerCase();
                    return offlinePlaces.keys.where((name) => name.toLowerCase().contains(query));
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    if (placeCtrl.text.isNotEmpty && textEditingController.text.isEmpty) {
                      textEditingController.text = placeCtrl.text;
                    }
                    return TextField(
                      controller: textEditingController, focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: AppLocale.l('searchPlace'), prefixIcon: Icon(Icons.search),
                        suffixIcon: geoLoading
                          ? Padding(padding: const EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: Icon(Icons.my_location, color: kTeal), onPressed: () { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); }),
                      ),
                      onSubmitted: (_) { placeCtrl.text = textEditingController.text; performGeocode(textEditingController.text, setS); },
                      onChanged: (val) => placeCtrl.text = val,
                    );
                  },
                  onSelected: (String selection) async {
                    if (offlinePlaces.containsKey(selection)) {
                      final coords = offlinePlaces[selection]!;
                      final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
                      setS(() {
                        placeCtrl.text = selection;
                        latCtrl.text = coords[0].toStringAsFixed(4);
                        lonCtrl.text = coords[1].toStringAsFixed(4);
                        tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        geoStatus = '📍 $selection (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
                      });
                    }
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0, borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 64),
                          child: ListView.builder(
                            padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(dense: true, leading: Icon(Icons.location_on, size: 18, color: kPurple2), title: Text(option, style: TextStyle(fontSize: 13)), onTap: () => onSelected(option));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (geoStatus.isNotEmpty) ...[const SizedBox(height: 6), Text(geoStatus, style: TextStyle(fontSize: 12, color: kGreen))],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: AppLocale.l('latLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: lonCtrl, decoration: InputDecoration(labelText: AppLocale.l('lonLabel'), isDense: true), keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: tzCtrl, decoration: const InputDecoration(labelText: 'TZ', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⏳ $name ${AppLocale.l('recalculating')}')));
                try {
                  int h24 = hour;
                  if (ampm == 'PM' && h24 != 12) h24 += 12;
                  if (ampm == 'AM' && h24 == 12) h24 = 0;
                  final localHour = h24 + minute / 60.0;
                  final lat = double.tryParse(latCtrl.text) ?? 14.98;
                  final lon = double.tryParse(lonCtrl.text) ?? 74.73;
                  final tz = double.tryParse(tzCtrl.text) ?? 5.5;

                  final result = await AstroCalculator.calculate(
                    year: dob.year, month: dob.month, day: dob.day,
                    hourUtcOffset: tz, hour24: localHour,
                    lat: lat, lon: lon, ayanamsaMode: 'lahiri', trueNode: false,
                  );

                  if (result == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('calcFailed')}'), backgroundColor: Colors.red));
                    return;
                  }

                  if (mounted) {
                    setState(() {
                      _primaryName = name;
                      _primaryResult = result;
                      _primaryDob = dob;
                      _primaryHour = hour;
                      _primaryMinute = minute;
                      _primaryAmpm = ampm;
                      _primaryLat = lat;
                      _primaryLon = lon;
                      _primaryPlace = placeCtrl.text;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $name ${AppLocale.l('calcSuccess')}'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
                }
              },
              child: Text(AppLocale.l('recalcBtn'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _loadJanmaNakshatra() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        final val = prefs.getInt('dashboard_janma_nakshatra');
        if (val != null) _janmaNakshatraIdx = val;
      });
    }
  }

  /// Load all group members from saved profiles and calculate their kundalis
  Future<void> _loadGroupMembers() async {
    final profiles = await StorageService.loadAll();
    final newEntries = <_PersonEntry>[];

    for (final memberName in widget.initialGroupMembers) {
      // Skip if already loaded or if it's the primary person
      if (memberName == widget.name) continue;
      if (_extraPersons.any((ep) => ep.name == memberName)) continue;

      final p = profiles[memberName];
      if (p == null) continue;

      try {
        final dateParts = p.date.split('-');
        final dob = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
        int h24 = p.hour;
        if (p.ampm == 'PM' && h24 != 12) h24 += 12;
        if (p.ampm == 'AM' && h24 == 12) h24 = 0;
        final localHour = h24 + p.minute / 60.0;
        final result = await AstroCalculator.calculate(
          year: dob.year, month: dob.month, day: dob.day,
          hourUtcOffset: p.tzOffset, hour24: localHour,
          lat: p.lat, lon: p.lon, ayanamsaMode: 'lahiri', trueNode: true,
        );
        if (result != null) {
          newEntries.add(_PersonEntry(
            name: p.name, result: result, dob: dob,
            hour: p.hour, minute: p.minute, ampm: p.ampm,
            lat: p.lat, lon: p.lon, place: p.place, notes: p.notes,
          ));
        }
      } catch (e) {
        debugPrint('Failed to load group member $memberName: $e');
      }
    }

    // Single setState for all members — avoids N full screen rebuilds
    if (newEntries.isNotEmpty && mounted) {
      setState(() => _extraPersons.addAll(newEntries));
    }
  }

  Future<void> _saveSelectedJanmaNakshatra(int? idx) async {
    if (idx != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dashboard_janma_nakshatra', idx);
    }
  }

  Future<void> _exportAndShareCSV() async {
    try {
      final r = widget.result;
      final pan = r.panchang;
      final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
      final timeStr = '${widget.hour}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';
      final name = widget.name.isNotEmpty ? widget.name : 'Unknown';

      final buf = StringBuffer();
      // BOM for Excel UTF-8
      buf.write('\uFEFF');

      // Personal Info
      buf.writeln('${AppLocale.l('jatakaVivar')},,');
      buf.writeln('${AppLocale.l('nameLabel')},$name,');
      buf.writeln('${AppLocale.l('placeLabel')},${widget.place},');
      buf.writeln('${AppLocale.l('dateLabel')},$dateStr,');
      buf.writeln('${AppLocale.l('timeLabel')},$timeStr,');
      buf.writeln('${AppLocale.l('latLabel')},${widget.lat},');
      buf.writeln('${AppLocale.l('lonLabel')},${widget.lon},');
      buf.writeln(',');

      // Panchanga
      buf.writeln('${AppLocale.l('pHeading')},,');
      buf.writeln('${AppLocale.l('samvatsara')},${pan.samvatsara},');
      buf.writeln('${AppLocale.l('varaLabel')},${pan.vara},');
      buf.writeln('${AppLocale.l('tithiLabel')},${pan.tithi},');
      buf.writeln('${AppLocale.l('nakshatraShort')},${pan.nakshatra},');
      buf.writeln('${AppLocale.l('yogaLabel')},${pan.yoga},');
      buf.writeln('${AppLocale.l('karanaLabel')},${pan.karana},');
      buf.writeln('${AppLocale.l('chandraRashiLabel')},${pan.chandraRashi},');
      buf.writeln('${AppLocale.l('chandraMasa')},${pan.chandraMasa},');
      buf.writeln('${AppLocale.l('souraMasa')},${pan.souraMasa},');
      buf.writeln('${AppLocale.l('sunrise')},${pan.sunrise},');
      buf.writeln('${AppLocale.l('sunset')},${pan.sunset},');
      buf.writeln('${AppLocale.l('dashaLord')},${pan.dashaLord},');
      buf.writeln('${AppLocale.l('dashaBalanceLabel')},${pan.dashaBalance},');
      buf.writeln(',');

      // Graha Sphuta
      buf.writeln('${AppLocale.l('grahaSphuta')},,,');
      buf.writeln('${AppLocale.l('hGraha')},${AppLocale.l('hRashi')},${AppLocale.l('hSphuta')},${AppLocale.l('hNakPada')}');
      for (final p in planetOrder) {
        final info = r.planets[p];
        if (info == null) continue;
        final ri = (info.longitude / 30).floor() % 12;
        buf.writeln('${tr(p)},${appRashi[ri]},${formatDeg(info.longitude)},${trAll(info.nakshatra)} - ${info.pada}');
      }
      buf.writeln(',');

      // Upagraha Sphuta
      buf.writeln('${AppLocale.l('upagrahaTitle')},,,');
      buf.writeln('${AppLocale.l('hUpagraha')},${AppLocale.l('hRashi')},${AppLocale.l('hDegree')},${AppLocale.l('hNakshatraCol')}');
      for (final sp in sphutas16Order) {
        final deg = r.advSphutas[sp];
        if (deg == null) continue;
        final ri = (deg / 30).floor() % 12;
        final nakIdx = (deg / 13.333333).floor() % 27;
        final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
        buf.writeln('$sp,${appRashi[ri]},${formatDeg(deg)},${appNak[nakIdx]}-$pada');
      }

      // Save CSV to temp and share
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.l('webShareError'))));
        }
        return;
      }

      final fileName = '${name.replaceAll(' ', '_')}_$dateStr.csv';
      await ExportService.shareCSV(
        csvContent: buf.toString(),
        fileName: fileName,
        shareText: '$name ${AppLocale.l('kundaliLabel')} - $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: KeyedSubtree(
        key: ValueKey(_resumeKey),
        child: SafeArea(
        child: Column(
          children: [
            // Minimal header with back/save
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: kText),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(children: [
                    IconButton(
                      icon: Icon(Icons.person_add, color: kPurple2),
                      tooltip: AppLocale.l('addPerson'),
                      onPressed: _showAddPersonDialog,
                    ),

                    IconButton(
                      icon: _syncing
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                        : Icon(Icons.save, color: kText),
                      tooltip: 'Save & Sync',
                      onPressed: _syncing ? null : () async {
                            if (!mounted) return;
                            final cId = widget.extraInfo['clientId'] ?? '';
                            
                            // Build the group members list
                            final groupNames = _extraPersons.map((p) => p.name).toList();
                            final dateStr = '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}';

                            // 1. Resolve Client ID
                            String? resolvedCId = (cId is String && cId.isNotEmpty) ? cId : null;
                            if (resolvedCId == null) {
                              final client = await ClientService.getOrCreateClient(name: widget.name, phone: 'No Phone');
                              if (client != null) resolvedCId = client.clientId;
                            }

                            // 2. Save primary profile WITH groupMembers
                            await StorageService.save(Profile(
                              name: widget.name,
                              date: dateStr,
                              hour: widget.hour, minute: widget.minute, ampm: widget.ampm,
                              lat: widget.lat, lon: widget.lon, place: widget.place,
                              tzOffset: LocationService.tzOffset,
                              notes: _notes,
                              aroodhas: _aroodhas,
                              janmaNakshatraIdx: _janmaNakshatraIdx,
                              clientId: resolvedCId,
                              groupMembers: groupNames,
                            ));

                            // 3. Update primary person in ClientService
                            if (resolvedCId != null && resolvedCId.isNotEmpty) {
                              await ClientService.updateFamilyMember(FamilyMember(
                                clientId: resolvedCId,
                                memberName: widget.name,
                                relation: 'Self',
                                dob: dateStr,
                                birthTime: '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}',
                                birthPlace: widget.place,
                                lat: widget.lat, lon: widget.lon,
                                notes: _notes,
                              ));
                            }

                            // 4. Save each extra person individually
                            for (final ep in _extraPersons) {
                              final epDateStr = '${ep.dob.year}-${ep.dob.month.toString().padLeft(2, '0')}-${ep.dob.day.toString().padLeft(2, '0')}';
                              await StorageService.save(Profile(
                                name: ep.name,
                                date: epDateStr,
                                hour: ep.hour, minute: ep.minute, ampm: ep.ampm,
                                lat: ep.lat, lon: ep.lon, place: ep.place,
                                tzOffset: LocationService.tzOffset,
                                notes: ep.notes,
                                clientId: resolvedCId,
                              ));
                              // Also sync extra person to ClientService
                              if (resolvedCId != null && resolvedCId.isNotEmpty) {
                                await ClientService.updateFamilyMember(FamilyMember(
                                  clientId: resolvedCId,
                                  memberName: ep.name,
                                  relation: 'Group Member',
                                  dob: epDateStr,
                                  birthTime: '${ep.hour.toString().padLeft(2,'0')}:${ep.minute.toString().padLeft(2,'0')} ${ep.ampm}',
                                  birthPlace: ep.place,
                                  lat: ep.lat, lon: ep.lon,
                                  notes: ep.notes,
                                ));
                              }
                            }

                            final totalCount = 1 + groupNames.length;
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ ${AppLocale.l('savedSuccess')} ($totalCount ${AppLocale.l('kundaliCount')})\nClient ID: ${resolvedCId ?? ''}'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              )
                            );
                            if (GoogleAuthService.isSignedIn) {
                              setState(() => _syncing = true);
                              final sheetOk = await SheetsService.syncProfile({}, isNew: false);
                              final docOk = await DocsService.syncNotes(widget.name, _notes);
                              if (mounted) {
                                setState(() => _syncing = false);
                              }
                            }
                      },
                    ),
                  ]),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: kCard,
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildPanchangTab(),
                  _buildKundaliTab(),
                  _buildSphutas(),
                  _buildAroodhaTab(),
                  _buildDashaTab(),
                  _buildBhavaTab(),
                  _buildGrahaShadvargaTab(),
                  _buildShadbalaTab(),
                  _buildAshtakaTab(),
                  _buildNotesTab(),
                  _buildJanmaPatrikeTab(),
                ],
              ),
            ),

          ],
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: KUNDALI (All vargas stacked vertically)
  // ─────────────────────────────────────────────
  Widget _buildKundaliTab() {
    final charts = [
      {'label': AppLocale.l('rashiKundali'), 'varga': 1, 'isBhava': false},
      {'label': AppLocale.l('navamshaKundali'), 'varga': 9, 'isBhava': false},
      {'label': AppLocale.l('bhavaKundali'), 'varga': 1, 'isBhava': true},
      {'label': AppLocale.l('horaKundali'), 'varga': 2, 'isBhava': false},
      {'label': AppLocale.l('drekkanaKundali'), 'varga': 3, 'isBhava': false},
      {'label': AppLocale.l('dvadashamsha'), 'varga': 12, 'isBhava': false},
      {'label': AppLocale.l('trimshamsha'), 'varga': 30, 'isBhava': false},
    ];

    // All persons: primary + extras
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult, 'isPrimary': true},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'isPrimary': false}),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isLargeScreen = screenWidth > 600 || isLandscape;

    // Use 45% of screen width for 2 charts side-by-side on large screens, or 85% for single chart on mobile
    final chartSize = isLargeScreen ? (screenWidth * 0.45).clamp(350.0, 550.0) : screenWidth * 0.85;
    
    // Scale text up slightly on bigger charts for readability
    final textScale = isLargeScreen ? (chartSize / 350.0).clamp(1.1, 1.4) : 1.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Each person's charts in a horizontal scrollable row
          ...allPersons.map((person) {
            final personResult = person['result'] as KundaliResult;
            final personName = person['name'] as String;
            final isPrimary = person['isPrimary'] as bool;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: isPrimary ? kPurple2 : kTeal),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(personName, style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.w900, color: isPrimary ? kPurple2 : kTeal)),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 18, color: kPurple2),
                        tooltip: AppLocale.l('editTooltip'),
                        onPressed: () => isPrimary ? _showEditPrimaryDialog() : _showEditPersonDialog(personName),
                      ),
                      if (!isPrimary)
                        IconButton(
                          icon: Icon(Icons.close, size: 18, color: Colors.redAccent),
                          onPressed: () => setState(() => _extraPersons.removeWhere((p) => p.name == personName)),
                        ),
                    ],
                  ),
                ),
                // Horizontal scrollable charts
                SizedBox(
                  height: chartSize + (40 * textScale),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: charts.length,
                    itemBuilder: (context, i) {
                      final chart = charts[i];
                      final isBhavaChart = chart['isBhava'] as bool;
                      final label = chart['label'] as String;
                      return SizedBox(
                        width: chartSize,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Text(label, style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.w800, color: kPurple2)),
                              SizedBox(height: 4 * textScale),
                              Expanded(
                                child: KundaliChart(
                                  result: personResult,
                                  varga: chart['varga'] as int,
                                  isBhava: isBhavaChart,
                                  textScale: textScale,
                                  showSphutas: false,
                                  centerLabel: label,
                                  onPlanetTap: _showPlanetDetail,
                                  selectedPlanet: isBhavaChart ? _bhavaPlanet : null,
                                  onPlanetLongPress: isBhavaChart ? (pName) {
                                    setState(() => _bhavaPlanet = _bhavaPlanet == pName ? null : pName);
                                  } : null,
                                  bhavaFromPlanet: isBhavaChart ? _bhavaPlanet : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ),
                Divider(thickness: 1, color: kBorder),
              ],
            );
          }),
          // Add person button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _showAddPersonDialog,
              icon: Icon(Icons.person_add, color: kPurple2),
              label: Text(AppLocale.l('addPerson'), style: TextStyle(color: kPurple2, fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: kPurple2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPlanetDetail(String pName) {
    final info = widget.result.planets[pName];
    if (info == null) return;
    final sun = widget.result.planets['ರವಿ'];
    final detail = AstroCalculator.getPlanetDetail(
      pName, info.longitude, info.speed, sun?.longitude ?? 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlanetDetailSheet(pName: pName, detail: detail),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 2: UPAGRAHA SPHUTA (multi-person)
  // ─────────────────────────────────────────────
  Widget _buildSphutas() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final personResult = person['result'] as KundaliResult;
          final personName = person['name'] as String;
          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(personName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              // Graha Sphuta added back per user request
              Text(AppLocale.l('grahaSphuta'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _tableHeader([AppLocale.l('hGraha'), AppLocale.l('hRashi'), AppLocale.l('hSphuta'), AppLocale.l('hNakPada')]),
                    ...planetOrder.map((p) {
                      final info = personResult.planets[p];
                      if (info == null) return const SizedBox.shrink();
                      final ri = (info.longitude / 30).floor() % 12;
                      return _tableRow([
                        tr(p),
                        appRashi[ri],
                        formatDeg(info.longitude),
                        '${trAll(info.nakshatra)} - ${info.pada}'
                      ], bold0: true);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(AppLocale.l('upagrahaTitle'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _tableHeader([AppLocale.l('hUpagraha'), AppLocale.l('hRashi'), AppLocale.l('hDegree'), AppLocale.l('hNakshatraCol')]),
                    ...sphutas16Order.map((sp) {
                      final deg = personResult.advSphutas[sp];
                      if (deg == null) return const SizedBox.shrink();
                      final ri = (deg / 30).floor() % 12;
                      final nakIdx = (deg / 13.333333).floor() % 27;
                      final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                      return _tableRow([trAll(sp), appRashi[ri], formatDeg(deg), '${appNak[nakIdx]}-$pada'],
                        bold0: true);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 4: AROODHA
  // ─────────────────────────────────────────────
  Future<void> _openPrastutaChart() async {
    final now = DateTime.now();
    // Use custom prastuta location if set, else default
    final useLat = _prastutaLat != 0 ? _prastutaLat : LocationService.lat;
    final useLon = _prastutaLon != 0 ? _prastutaLon : LocationService.lon;
    final useTz = _prastutaLat != 0 ? _prastutaTz : LocationService.tzOffset;
    final usePlace = _prastutaPlace.isNotEmpty ? _prastutaPlace : LocationService.place;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      // Same method as InputScreen: pass local time directly (hour + minute, NO seconds — matches birth chart precision).
      // The calculator internally does (hour24 - hourUtcOffset) to get UTC.
      final localHour = now.hour + now.minute / 60.0;

      // Use same ayanamsa & node settings as the birth chart
      final ayanamsa = widget.extraInfo['ayanamsa'] ?? 'lahiri';
      final trueNode = (widget.extraInfo['nodeMode'] ?? 'mean') == 'true';
      final result = await AstroCalculator.calculate(
        year: now.year, month: now.month, day: now.day,
        hourUtcOffset: useTz,
        hour24: localHour,
        lat: useLat, lon: useLon,
        ayanamsaMode: ayanamsa,
        trueNode: trueNode,
      );
      if (mounted) Navigator.pop(context); // close dialog
      if (result != null && mounted) {
        setState(() {
          _prastutaResult = result;
          _prastutaTime = now;
          _prastutaPlace = usePlace;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('loadingPrastuta')))); // Current-time chart loaded
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocale.l('errorLabel')}: $e')));
    }
  }

  Future<void> _searchPrastutaPlace(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final q = Uri.encodeComponent(query.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && mounted) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('placeNotFoundDash'))));
        } else {
          final selected = data.length == 1 ? data[0] : await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: kCard,
              title: Text('${AppLocale.l('selectLocation')}', style: TextStyle(color: kText, fontWeight: FontWeight.w900, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                  itemBuilder: (ctx, i) {
                    final item = data[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.location_on, color: kPurple2, size: 20),
                      title: Text(item['display_name'] ?? '', style: TextStyle(fontSize: 13, color: kText), maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${double.tryParse(item['lat']?.toString() ?? '')?.toStringAsFixed(2)}°, ${double.tryParse(item['lon']?.toString() ?? '')?.toStringAsFixed(2)}°', style: TextStyle(fontSize: 11, color: kMuted)),
                      onTap: () => Navigator.pop(ctx, item),
                    );
                  },
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocale.l('cancel'), style: TextStyle(color: kMuted)))],
            ),
          );
          if (selected != null && mounted) {
            final lat = double.parse(selected['lat'].toString());
            final lon = double.parse(selected['lon'].toString());
            final displayName = selected['display_name'] as String;
            final autoTz = await getTimezoneForPlace(displayName, lat, lon);
            setState(() {
              _prastutaPlace = query.trim();
              _prastutaLat = lat;
              _prastutaLon = lon;
              _prastutaTz = autoTz;
              _prastutaResult = null; // Clear old result since location changed
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('📍 $displayName'), backgroundColor: Colors.green));
          }
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.l('placeError'))));
    }
  }

  Widget _buildAroodhaTab() {
    String _selAro = AppLocale.l('aroodha');
    int _selRashiIdx = 0;
    return StatefulBuilder(builder: (ctx, setS) {
      final activeResult = _prastutaResult ?? widget.result;

      // Varga charts for horizontal scrolling
      final charts = [
        {'label': AppLocale.l('rashiKundali'), 'varga': 1, 'isBhava': false},
        {'label': AppLocale.l('navamshaKundali'), 'varga': 9, 'isBhava': false},
        {'label': AppLocale.l('bhavaKundali'), 'varga': 1, 'isBhava': true},
        {'label': AppLocale.l('horaKundali'), 'varga': 2, 'isBhava': false},
        {'label': AppLocale.l('drekkanaKundali'), 'varga': 3, 'isBhava': false},
        {'label': AppLocale.l('dvadashamsha'), 'varga': 12, 'isBhava': false},
        {'label': AppLocale.l('trimshamsha'), 'varga': 30, 'isBhava': false},
      ];

      final screenWidth = MediaQuery.of(context).size.width;
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final isLargeScreen = screenWidth > 600 || isLandscape;
      final chartSize = isLargeScreen ? (screenWidth * 0.45).clamp(350.0, 550.0) : screenWidth * 0.85;
      final textScale = isLargeScreen ? (chartSize / 350.0).clamp(1.1, 1.4) : 1.0;

      // Shadvarga helper
      String getRashiLord(String rashiNameKn) {
        int idx = knRashi.indexOf(rashiNameKn);
        if (idx < 0) return rashiNameKn;
        final lordAbbr = const <String, List<String>>{
          'kn': ['ಕು','ಶು','ಬು','ಚ','ರ','ಬು','ಶು','ಕು','ಗು','ಶ','ಶ','ಗು'],
          'hi': ['मं','शु','बु','चं','सू','बु','शु','मं','गु','श','श','गु'],
          'ta': ['செ','சு','பு','சந்','சூ','பு','சு','செ','கு','ச','ச','கு'],
          'te': ['కు','శు','బు','చం','ర','బు','శు','కు','గు','శ','శ','గు'],
          'ml': ['കു','ശു','ബു','ചം','ര','ബു','ശു','കു','ഗു','ശ','ശ','ഗു'],
        };
        return (lordAbbr[AppLocale.current] ?? lordAbbr['kn']!)[idx];
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            // ── Prastuta Location & Time ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SectionTitle(AppLocale.l('aroodhaChakra')),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(AppLocale.l('prastuta'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _openPrastutaChart,
                      ),
                    ],
                  ),
                  // ── Location search ──
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '${AppLocale.l('searchLocation')} / Search',
                          prefixIcon: Icon(Icons.location_on, size: 18, color: kPurple2),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        style: TextStyle(fontSize: 13, color: kText),
                        onSubmitted: (v) => _searchPrastutaPlace(v),
                      ),
                    ),
                  ]),
                  // ── Current place info ──
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPurple2.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.place, size: 14, color: kPurple2),
                      const SizedBox(width: 4),
                      Expanded(child: Text(
                        _prastutaPlace.isNotEmpty ? _prastutaPlace : LocationService.place,
                        style: TextStyle(fontSize: 11, color: kText, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ),
                  // ── Prastuta time display ──
                  if (_prastutaTime != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.access_time, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${AppLocale.l('prastuta')}: ${_prastutaTime!.day.toString().padLeft(2,'0')}/${_prastutaTime!.month.toString().padLeft(2,'0')}/${_prastutaTime!.year} ${_prastutaTime!.hour.toString().padLeft(2,'0')}:${_prastutaTime!.minute.toString().padLeft(2,'0')}:${_prastutaTime!.second.toString().padLeft(2,'0')}',
                          style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ],
                  // ── Aroodha controls ──
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selAro,
                        items: List.generate(7, (i) => AppLocale.l('aroType$i'))
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selAro = v!),
                        decoration: InputDecoration(labelText: AppLocale.l('aroodhaLabel')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selRashiIdx,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i, child: Text(appRashi[i], style: TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selRashiIdx = v!),
                        decoration: InputDecoration(labelText: AppLocale.l('rashiLabel')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setS(() => _aroodhas[_selAro] = _selRashiIdx),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10)),
                      child: Text(AppLocale.l('addLabel'), style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  if (_aroodhas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setS(() => _aroodhas.clear()),
                      child: Text(AppLocale.l('clearLabel'), style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),

            // ── All varga charts (horizontal scroll) ──
            SizedBox(
              height: chartSize + (40 * textScale),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: charts.length,
                  itemBuilder: (context, i) {
                    final chart = charts[i];
                    final isBhavaChart = chart['isBhava'] as bool;
                    final label = chart['label'] as String;
                    return SizedBox(
                      width: chartSize,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            Text(label, style: TextStyle(fontSize: 15 * textScale, fontWeight: FontWeight.w800, color: kPurple2)),
                            SizedBox(height: 4 * textScale),
                            Expanded(
                              child: KundaliChart(
                                result: activeResult,
                                varga: chart['varga'] as int,
                                isBhava: isBhavaChart,
                                textScale: textScale,
                                showSphutas: false,
                                aroodhas: _aroodhas,
                                centerLabel: _prastutaResult != null ? '${AppLocale.l('prastuta')}\n$label' : label,
                                onPlanetTap: _showPlanetDetail,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Graha Sputa Table ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(AppLocale.l('grahaSphuta'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _tableHeader([AppLocale.l('hGraha'), AppLocale.l('hRashi'), AppLocale.l('hSphuta'), AppLocale.l('hNakPada')]),
                        ...planetOrder.map((p) {
                          final info = activeResult.planets[p];
                          if (info == null) return const SizedBox.shrink();
                          final ri = (info.longitude / 30).floor() % 12;
                          return _tableRow([
                            tr(p),
                            appRashi[ri],
                            formatDeg(info.longitude),
                            '${trAll(info.nakshatra)} - ${info.pada}'
                          ], bold0: true);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upagraha Sputa
                  Text(AppLocale.l('upagrahaTitle'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _tableHeader([AppLocale.l('hUpagraha'), AppLocale.l('hRashi'), AppLocale.l('hDegree'), AppLocale.l('hNakshatraCol')]),
                        ...sphutas16Order.map((sp) {
                          final deg = activeResult.advSphutas[sp];
                          if (deg == null) return const SizedBox.shrink();
                          final ri = (deg / 30).floor() % 12;
                          final nakIdx = (deg / 13.333333).floor() % 27;
                          final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                          return _tableRow([trAll(sp), appRashi[ri], formatDeg(deg), '${appNak[nakIdx]}-$pada'],
                            bold0: true);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Graha Shadvarga Table ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kPurple1.withOpacity(0.12), kPurple2.withOpacity(0.06)]),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14), topRight: Radius.circular(14),
                      ),
                      border: Border(bottom: BorderSide(color: kPurple2.withOpacity(0.3), width: 2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grid_view_rounded, size: 18, color: kPurple2),
                        const SizedBox(width: 8),
                        Text(AppLocale.l('shadvarga'), style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16, color: kPurple2,
                        )),
                      ],
                    ),
                  ),
                  Builder(builder: (_) {
                    final hGraha = AppLocale.l('hGraha');
                    final hD3 = AppLocale.l('hD3');
                    final hD2 = AppLocale.l('hD2');
                    final hD9 = AppLocale.l('hD9');
                    final hD30 = AppLocale.l('hD30');
                    final hD12 = AppLocale.l('hD12');
                    final hKshetra = AppLocale.l('hKshetra');
                    int rowIdx = 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                        ),
                        border: Border.all(color: kBorder),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                        ),
                        child: Table(
                          border: TableBorder.symmetric(
                            inside: BorderSide(color: kBorder.withOpacity(0.6), width: 0.5),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1.3),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                            4: FlexColumnWidth(1),
                            5: FlexColumnWidth(1),
                            6: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [kPurple1.withOpacity(0.15), kPurple2.withOpacity(0.08)]),
                              ),
                              children: [hGraha, hD3, hD2, hD9, hD30, hD12, hKshetra].map((h) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Text(h, textAlign: TextAlign.center, style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 14, color: kPurple2,
                                  )),
                                ),
                              ).toList(),
                            ),
                            ...planetOrder.map((pNameKey) {
                              final pInfo = activeResult.planets[pNameKey];
                              if (pInfo == null) return const TableRow(children: [SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox()]);
                              final details = AstroCalculator.getPlanetDetail(pNameKey, pInfo.longitude, pInfo.speed, activeResult.planets['ರವಿ']?.longitude ?? 0.0);
                              final displayName = tr(pNameKey);
                              final isEvenRow = rowIdx++ % 2 == 0;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEvenRow ? kBg.withOpacity(0.5) : kCard,
                                ),
                                children: [
                                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                                    displayName, textAlign: TextAlign.center,
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kTeal),
                                  )),
                                  ...[details['d3'], details['d2'], details['d9'], details['d30'], details['d12'], details['d1']].map((v) =>
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                                      getRashiLord(v as String), textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText),
                                    )),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  // ─────────────────────────────────────────────
  // TAB 5: DASHA
  // ─────────────────────────────────────────────
  Widget _buildDashaTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];
    return SingleChildScrollView(
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          final pan = r.panchang;
          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              AppCard(
                child: Text(
                  '${AppLocale.l('dashaLord')}: ${trAll(pan.dashaLord)}  ${AppLocale.l('dashaBalance')}: ${_trDashaBalance(pan.dashaBalance)}',
                  style: TextStyle(color: kOrange, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              DashaWidget(dashas: r.dashas),
              if (allPersons.length > 1) Divider(thickness: 1, color: kBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 6: PANCHANG
  // ─────────────────────────────────────────────
  Widget _buildPanchangTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult, 'dob': _primaryDob, 'hour': _primaryHour, 'minute': _primaryMinute, 'ampm': _primaryAmpm, 'place': _primaryPlace},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'dob': p.dob, 'hour': p.hour, 'minute': p.minute, 'ampm': p.ampm, 'place': p.place}),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pan = r.panchang;
          final pName = person['name'] as String;
          final dob = person['dob'] as DateTime;
          final dateStr = '${dob.day.toString().padLeft(2,"0")}-${dob.month.toString().padLeft(2,"0")}-${dob.year}';
          final timeStr = '${person["hour"]}:${(person["minute"] as int).toString().padLeft(2,"0")} ${person["ampm"]}';

          // Calculate age
          final now = DateTime.now();
          int ageYears = now.year - dob.year;
          int ageMonths = now.month - dob.month;
          int ageDays = now.day - dob.day;
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

          // Find current Dasha and Bhukti from existing r.dashas
          String currentDasha = '';
          String dashaEnd = '';
          String currentBhukti = '';
          String bhuktiEnd = '';
          for (final md in r.dashas) {
            if (now.isAfter(md.start) && now.isBefore(md.end)) {
              currentDasha = trAll(md.lord);
              dashaEnd = '${md.end.day.toString().padLeft(2,"0")}-${md.end.month.toString().padLeft(2,"0")}-${md.end.year}';
              for (final ad in md.antardashas) {
                if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
                  currentBhukti = trAll(ad.lord);
                  bhuktiEnd = '${ad.end.day.toString().padLeft(2,"0")}-${ad.end.month.toString().padLeft(2,"0")}-${ad.end.year}';
                  break;
                }
              }
              break;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pName.isNotEmpty) _kv(AppLocale.l('nameLabel'), pName),
                _kv(AppLocale.l('placeLabel'), person['place'] as String),
                _kv(AppLocale.l('dateLabel'), dateStr),
                _kv(AppLocale.l('timeLabel'), timeStr),
                _kv(AppLocale.l('dashaLord'), '${trAll(pan.dashaLord)}  ${AppLocale.l('dashaBalance')}: ${_trDashaBalance(pan.dashaBalance)}'),
                const Divider(height: 16),
                _kv(AppLocale.l('ageLabel'), ageStr),
                if (currentDasha.isNotEmpty) ...[
                  const Divider(height: 16),
                  _kv('${AppLocale.l('dasha')}', '$currentDasha  (${AppLocale.l('end')}: $dashaEnd)'),
                  if (currentBhukti.isNotEmpty)
                    _kv(AppLocale.l('bhuktiLabel'), '$currentBhukti  (${AppLocale.l('end')}: $bhuktiEnd)'),
                ],
              ])),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _tableRow([AppLocale.l('samvatsara'), trAll(pan.samvatsara)]),
                  _tableRow([AppLocale.l('varaLabel'), trAll(pan.vara)]),
                  _tableRow([AppLocale.l('tithiLabel'), '${trAll(pan.tithi)}${pan.tithiGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.tithiGata})' : ''}']),
                  _tableRow([AppLocale.l('chandraNakshatra'), () { final moonPada = r.planets['ಚಂದ್ರ']?.pada; final fallback = (pan.nakPercent * 4).floor() + 1; final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback); return '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} $p (${AppLocale.l('gataGhati')}: ${pan.gataGhati})'; }()]),
                  _tableRow([AppLocale.l('yogaLabel'), '${trAll(pan.yoga)}${pan.yogaGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.yogaGata})' : ''}']),
                  _tableRow([AppLocale.l('karanaLabel'), '${trAll(pan.karana)}${pan.karanaGata.isNotEmpty ? ' (${AppLocale.l('gataGhati')}: ${pan.karanaGata})' : ''}']),
                  _tableRow([AppLocale.l('chandraRashiLabel'), trAll(pan.chandraRashi)]),
                  _tableRow([AppLocale.l('chandraMasa'), trAll(pan.chandraMasa)]),
                  _tableRow([AppLocale.l('suryaNakshatraLabel'), '${trAll(pan.suryaNakshatra)} - ${AppLocale.l('padaLabel')} ${pan.suryaPada}']),
                  _tableRow([AppLocale.l('souraMasa'), trAll(pan.souraMasa)]),
                  _tableRow([AppLocale.l('souraMasaGataDina'), pan.souraMasaGataDina]),
                  _tableRow([AppLocale.l('sunrise'), pan.sunrise]),
                  _tableRow([AppLocale.l('sunset'), pan.sunset]),
                  _tableRow([AppLocale.l('udayadiGhati'), pan.udayadiGhati]),
                  _tableRow([AppLocale.l('gataGhati'), pan.gataGhati]),
                  _tableRow([AppLocale.l('paramaGhati'), pan.paramaGhati]),
                  _tableRow([AppLocale.l('sheshaGhati'), pan.shesha]),
                  _tableRow([AppLocale.l('vishaPraghati'), pan.vishaPraghati]),
                  _tableRow([AppLocale.l('amrutaPraghati'), pan.amrutaPraghati]),
                ]),
              ),
              if (allPersons.length > 1) Divider(thickness: 2, color: kBorder),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }
  // ─────────────────────────────────────────────
  // TAB 7.5: BHAVA DREKKAANA
  // ─────────────────────────────────────────────
  Widget _buildBhavaDrekkaanaTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;

          final title = AppLocale.l('grahaVishlesha');

          final hBhava = AppLocale.l('hBhava');
          final hD9 = AppLocale.l('hD9');
          final hD3D1 = AppLocale.l('hD3');
          final hD3D9 = AppLocale.l('hD9');
          final hD3D12 = AppLocale.l('hD12');

          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              Text(title, style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15,
                color: kPurple2)),
              const SizedBox(height: 12),
              
              AppCard(
                padding: EdgeInsets.zero,
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: kBorder),
                    verticalInside: BorderSide(color: kBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.4),
                    3: FlexColumnWidth(1.4),
                    4: FlexColumnWidth(1.4),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: kPurple2.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                      children: [
                        Padding(padding: const EdgeInsets.all(8), child: Text(hBhava, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD9, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD3D1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD3D9, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(8), child: Text(hD3D12, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                      ],
                    ),
                    ...List.generate(12, (i) {
                      final madhya = r.bhavas[i];
                      final details = AstroCalculator.getPlanetDetail('ಲಗ್ನ', madhya, 0, 0);

                      // Helper to translate 'Rashi N' format
                      String formatPart(String raw) {
                        final parts = raw.split(' ');
                        if (parts.length == 2) {
                          return '${parts[0]} ${parts[1]}';
                        }
                        return raw;
                      }

                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(8), child: Text('${i+1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(details['d9'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(formatPart(details['subDrekD1'] as String), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(formatPart(details['subDrekD9'] as String), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(8), child: Text(formatPart(details['subDrekD12'] as String), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocale.l('shadvargaTitle'), style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15,
                color: kPurple2)),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Table(
                  border: TableBorder(
                    horizontalInside: BorderSide(color: kBorder),
                    verticalInside: BorderSide(color: kBorder),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(0.8),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1),
                    6: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: kPurple2.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                      children: [
                        Padding(padding: const EdgeInsets.all(6), child: Text(hBhava, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D1', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D2', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D3', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D9', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D12', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                        Padding(padding: const EdgeInsets.all(6), child: Text('D30', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                      ],
                    ),
                    ...List.generate(12, (i) {
                      final madhya = r.bhavas[i];
                      final details = AstroCalculator.getPlanetDetail('ಲಗ್ನ', madhya, 0, 0);

                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(6), child: Text('${i+1}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d1'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d2'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d3'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d9'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d12'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                          Padding(padding: const EdgeInsets.all(6), child: Text(details['d30'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              if (allPersons.length > 1) const SizedBox(height: 16),
            ]
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 7: BHAVA
  // ─────────────────────────────────────────────
  Widget _buildBhavaTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];

    // Planet selector list
    final selectablePlanets = planetOrder.where((p) => p != 'ಲಗ್ನ' && p != 'ಮಾಂದಿ').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Planet selector (for primary person)
          Text(AppLocale.l('bhavaKaksha'), style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              GestureDetector(
                onTap: () => setState(() => _bhavaPlanet = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bhavaPlanet == null ? kTeal : kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _bhavaPlanet == null ? kTeal : kBorder),
                  ),
                  child: Text(AppLocale.l('lagna'), style: TextStyle(
                    fontSize: 13,
                    fontWeight: _bhavaPlanet == null ? FontWeight.w900 : FontWeight.w600,
                    color: _bhavaPlanet == null ? Colors.white : kText,
                  )),
                ),
              ),
              ...selectablePlanets.map((p) {
                final isSelected = _bhavaPlanet == p;
                return GestureDetector(
                  onTap: () => setState(() => _bhavaPlanet = isSelected ? null : p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? kTeal : kCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? kTeal : kBorder),
                    ),
                    child: Text(tr(p), style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? Colors.white : kText,
                    )),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-person bhava madhya tables
          ...allPersons.map((person) {
            final r = person['result'] as KundaliResult;
            final pName = person['name'] as String;
            final lagnaLong = r.planets['ಲಗ್ನ']?.longitude ?? 0;

            List<double> getMadhyas(String? planet) {
              if (planet == null || !r.planets.containsKey(planet)) return r.bhavas;
              final pDeg = r.planets[planet]!.longitude;
              final offset = (pDeg - lagnaLong + 360.0) % 360.0;
              return List.generate(12, (i) => (r.bhavas[i] + offset) % 360.0);
            }

            final currentMadhyas = getMadhyas(_bhavaPlanet);
            final title = _bhavaPlanet != null
                ? '${AppLocale.l('bhavaRecalc')} (${_bhavaPlanet!})'
                : '${AppLocale.l('bhavaRecalcFor')} (${AppLocale.l('lagna')})';

            // Compute Adi (start) and Antya (end) sphuta for each bhava
            String rashiName(double deg) {
              final idx = (deg / 30).floor() % 12;
              return appRashi[idx];
            }

            Widget bhavaCell(double deg) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatDeg(deg), style: TextStyle(fontSize: 11, color: kText)),
                      const SizedBox(height: 2),
                      Text(rashiName(deg), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kPurple2)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (allPersons.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                  ),
                Text(title, style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15,
                  color: _bhavaPlanet != null ? kTeal : kPurple2)),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _tableHeader([AppLocale.l('hBhavaNo'), AppLocale.l('hBhavaStart'), AppLocale.l('hBhavaMid'), AppLocale.l('hBhavaEnd')]),
                      ...List.generate(12, (i) {
                        final madhya = currentMadhyas[i];
                        final prevMadhya = currentMadhyas[(i + 11) % 12];
                        final nextMadhya = currentMadhyas[(i + 1) % 12];

                        // Adi = midpoint of previous madhya and current madhya
                        final adiDiff = (madhya - prevMadhya + 360.0) % 360.0;
                        final adi = (prevMadhya + adiDiff / 2.0) % 360.0;

                        // Antya = midpoint of current madhya and next madhya
                        final antyaDiff = (nextMadhya - madhya + 360.0) % 360.0;
                        final antya = (madhya + antyaDiff / 2.0) % 360.0;

                        return Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 36,
                                  child: Center(child: Text('${i+1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText))),
                                ),
                                bhavaCell(adi),
                                bhavaCell(madhya),
                                bhavaCell(antya),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (allPersons.length > 1) Divider(thickness: 2, color: kBorder),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 7.6: GRAHA SHADVARGA
  // ─────────────────────────────────────────────
  Widget _buildGrahaShadvargaTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];

    final hGraha = AppLocale.l('hGraha');
    final hD3 = AppLocale.l('hD3');
    final hD2 = AppLocale.l('hD2');
    final hD9 = AppLocale.l('hD9');
    final hD30 = AppLocale.l('hD30');
    final hD12 = AppLocale.l('hD12');
    final hKshetra = AppLocale.l('hKshetra');

    String getRashiLord(String rashiNameKn) {
      int idx = knRashi.indexOf(rashiNameKn);
      if (idx < 0) return rashiNameKn; 
      
      final lordAbbr = const <String, List<String>>{
        'kn': ['ಕು','ಶು','ಬು','ಚ','ರ','ಬು','ಶು','ಕು','ಗು','ಶ','ಶ','ಗು'],
        'hi': ['मं','शु','बु','चं','सू','बु','शु','मं','गु','श','श','गु'],
        'ta': ['செ','சு','பு','சந்','சூ','பு','சு','செ','கு','ச','ச','கு'],
        'te': ['కు','శు','బు','చం','ర','బు','శు','కు','గు','శ','శ','గు'],
        'ml': ['കു','ശു','ബു','ചം','ര','ബു','ശു','കു','ഗു','ശ','ശ','ഗു'],
      };
      return (lordAbbr[AppLocale.current] ?? lordAbbr['kn']!)[idx];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          int rowIdx = 0;

          return Column(
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              // Title with gradient accent
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kPurple1.withOpacity(0.12), kPurple2.withOpacity(0.06)]),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14), topRight: Radius.circular(14),
                  ),
                  border: Border(bottom: BorderSide(color: kPurple2.withOpacity(0.3), width: 2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: kPurple2),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('shadvarga'), style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16, color: kPurple2,
                    )),
                  ],
                ),
              ),
              
              // Table
              Container(
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
                  ),
                  child: Table(
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: kBorder.withOpacity(0.6), width: 0.5),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1.3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                      4: FlexColumnWidth(1),
                      5: FlexColumnWidth(1),
                      6: FlexColumnWidth(1),
                    },
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kPurple1.withOpacity(0.15), kPurple2.withOpacity(0.08)]),
                        ),
                        children: [hGraha, hD3, hD2, hD9, hD30, hD12, hKshetra].map((h) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(h, textAlign: TextAlign.center, style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 14, color: kPurple2,
                            )),
                          ),
                        ).toList(),
                      ),
                      // Data rows with alternating shading
                      ...planetOrder.map((pNameKey) {
                        final pInfo = r.planets[pNameKey];
                        if (pInfo == null) return const TableRow(children: [SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox(), SizedBox()]);
                        
                        final details = AstroCalculator.getPlanetDetail(pNameKey, pInfo.longitude, pInfo.speed, r.planets['ರವಿ']?.longitude ?? 0.0);
                        final displayName = tr(pNameKey);
                        final isEvenRow = rowIdx++ % 2 == 0;

                        return TableRow(
                          decoration: BoxDecoration(
                            color: isEvenRow ? kBg.withOpacity(0.5) : kCard,
                          ),
                          children: [
                            // Planet name column
                            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                              displayName, textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: kTeal),
                            )),
                            // Varga lord columns
                            ...[details['d3'], details['d2'], details['d9'], details['d30'], details['d12'], details['d1']].map((v) =>
                              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                                getRashiLord(v as String), textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText),
                              )),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              if (allPersons.length > 1) const SizedBox(height: 24),
            ]
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 8: SHADBALA
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // TAB 8: ASHTAKA VARGA (multi-person)
  // ─────────────────────────────────────────────
  Widget _buildAshtakaTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];

    if (allPersons.length == 1) {
      return AshtakaVargaWidget(result: widget.result);
    }

    return SingleChildScrollView(
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
              ),
              AshtakaVargaWidget(result: r),
              Divider(thickness: 2, color: kBorder),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShadbalaTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'result': _primaryResult},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result}),
    ];

    if (allPersons.length == 1) {
      return ShadbalaWidget(key: UniqueKey(), shadbala: widget.result.shadbala);
    }

    return SingleChildScrollView(
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pName = person['name'] as String;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
              ),
              ShadbalaWidget(key: UniqueKey(), shadbala: r.shadbala),
              Divider(thickness: 2, color: kBorder),
            ],
          );
        }).toList(),
      ),
    );
  }



  // ─────────────────────────────────────────────
  // TAB 10: NOTES
  // ─────────────────────────────────────────────
  final Map<String, TextEditingController> _noteControllers = {};

  TextEditingController _getNoteController(String name) {
    if (!_noteControllers.containsKey(name)) {
      _noteControllers[name] = TextEditingController();
    }
    return _noteControllers[name]!;
  }
  
  void _saveIndividualNote(String name, bool isPrimary, _PersonEntry? entry, String newNotes) {
    final cId = widget.extraInfo['clientId'] ?? '';
    
    if (isPrimary) {
      StorageService.save(Profile(
        name: widget.name, date: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}',
        hour: widget.hour, minute: widget.minute, ampm: widget.ampm, lat: widget.lat, lon: widget.lon, place: widget.place,
        tzOffset: LocationService.tzOffset, notes: newNotes, aroodhas: _aroodhas, janmaNakshatraIdx: _janmaNakshatraIdx, clientId: (cId is String && cId.isNotEmpty) ? cId : null,
      ));
      if (cId is String && cId.isNotEmpty) {
        ClientService.updateFamilyMember(FamilyMember(clientId: cId, memberName: widget.name, relation: 'Self', dob: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}', birthTime: '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}', birthPlace: widget.place, lat: widget.lat, lon: widget.lon, notes: newNotes));
      }
    } else if (entry != null) {
       final dateStr = '${entry.dob.year}-${entry.dob.month.toString().padLeft(2, '0')}-${entry.dob.day.toString().padLeft(2, '0')}';
       StorageService.save(Profile(
         name: entry.name, date: dateStr, hour: entry.hour, minute: entry.minute, ampm: entry.ampm, lat: entry.lat, lon: entry.lon, place: entry.place,
         tzOffset: LocationService.tzOffset, notes: newNotes, clientId: (cId is String && cId.isNotEmpty) ? cId : null,
       ));
       if (cId is String && cId.isNotEmpty) {
         ClientService.updateFamilyMember(FamilyMember(clientId: cId, memberName: entry.name, relation: 'Group Member', dob: dateStr, birthTime: '${entry.hour.toString().padLeft(2,'0')}:${entry.minute.toString().padLeft(2,'0')} ${entry.ampm}', birthPlace: entry.place, lat: entry.lat, lon: entry.lon, notes: newNotes));
       }
    }
  }

  Widget _buildIndividualNoteSection({required String name, required bool isPrimary, required _PersonEntry? entry}) {
    final currentNotes = isPrimary ? _notes : (entry?.notes ?? '');
    final entries = _parseNoteEntries(currentNotes);
    final ctrl = _getNoteController(name);
    
    void shareNotes() {
      final dobDate = isPrimary ? widget.dob : entry!.dob;
      final dobStr = '${dobDate.day.toString().padLeft(2, '0')}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.year}';
      final birthHour = isPrimary ? widget.hour : entry!.hour;
      final birthMin = isPrimary ? widget.minute : entry!.minute;
      final birthAmpm = isPrimary ? widget.ampm : entry!.ampm;
      final birthPlace = isPrimary ? widget.place : entry!.place;
      final timeStr = '${birthHour.toString().padLeft(2, '0')}:${birthMin.toString().padLeft(2, '0')} $birthAmpm';
      final clientId = widget.extraInfo['clientId'] ?? '';
      final buf = StringBuffer();
      buf.writeln('═══════════════════════════');
      buf.writeln('   ✨ ${AppLocale.l('appName')} ✨');
      buf.writeln('═══════════════════════════\n');
      if (clientId.isNotEmpty) buf.writeln('🪪 ${AppLocale.l('idLabel')}: $clientId');
      buf.writeln('👤 ${AppLocale.l('nameLabel')}: $name');
      buf.writeln('📅 ${AppLocale.l('birthDate')}: $dobStr');
      buf.writeln('🕰️ ${AppLocale.l('birthTime')}: $timeStr');
      buf.writeln('📍 ${AppLocale.l('birthPlace')}: $birthPlace\n');
      buf.writeln('───────────────────────────');
      buf.writeln('   📝 ${AppLocale.l('notesLabel')}');
      buf.writeln('───────────────────────────\n');
      if (entries.isEmpty) {
        buf.writeln(AppLocale.l('noNotes'));
      } else {
        for (int i = 0; i < entries.length; i++) {
          buf.writeln('🕐 ${entries[i]['date']}\n   ${entries[i]['text']}');
          if (i < entries.length - 1) buf.writeln();
        }
      }
      buf.writeln('\n═══════════════════════════');
      final text = buf.toString();
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocale.l('copiedToClipboard')} ✅')));
      final encoded = Uri.encodeComponent(text);
      launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: isPrimary,
        backgroundColor: kCard,
        collapsedBackgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w900, color: kTeal)),
        subtitle: Text(isPrimary ? AppLocale.l('primaryPersonNotes') : AppLocale.l('groupMemberNotes'), style: TextStyle(fontSize: 12, color: kMuted)),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: shareNotes,
                  icon: Icon(Icons.share, size: 18),
                  label: Text(AppLocale.l('shareLabel'), style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final dobDate = isPrimary ? widget.dob : entry!.dob;
                    final dobStr = '${dobDate.day.toString().padLeft(2, '0')}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.year}';
                    final birthHour = isPrimary ? widget.hour : entry!.hour;
                    final birthMin = isPrimary ? widget.minute : entry!.minute;
                    final birthAmpm = isPrimary ? widget.ampm : entry!.ampm;
                    final birthPlace = isPrimary ? widget.place : entry!.place;
                    final timeStr = '${birthHour.toString().padLeft(2, '0')}:${birthMin.toString().padLeft(2, '0')} $birthAmpm';
                    final clientId = widget.extraInfo['clientId'] ?? '';
                    final buf = StringBuffer();
                    buf.writeln('═══════════════════════════');
                    buf.writeln('   ✨ ${AppLocale.l('appName')} ✨');
                    buf.writeln('═══════════════════════════\n');
                    if (clientId.isNotEmpty) buf.writeln('🪪 ${AppLocale.l('idLabel')}: $clientId');
                    buf.writeln('👤 ${AppLocale.l('nameLabel')}: $name');
                    buf.writeln('📅 ${AppLocale.l('birthDate')}: $dobStr');
                    buf.writeln('🕰️ ${AppLocale.l('birthTime')}: $timeStr');
                    buf.writeln('📍 ${AppLocale.l('birthPlace')}: $birthPlace\n');
                    buf.writeln('───────────────────────────');
                    buf.writeln('   📝 ${AppLocale.l('notesLabel')}');
                    buf.writeln('───────────────────────────\n');
                    if (entries.isEmpty) {
                      buf.writeln(AppLocale.l('noNotes'));
                    } else {
                      for (int i = 0; i < entries.length; i++) {
                        buf.writeln('🕐 ${entries[i]['date']}\n   ${entries[i]['text']}');
                        if (i < entries.length - 1) buf.writeln();
                      }
                    }
                    buf.writeln('\n═══════════════════════════');
                    _showPrintPreview(buf.toString());
                  },
                  icon: Icon(Icons.print, size: 18),
                  label: Text(AppLocale.l('printLabel'), style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPurple2, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: 8,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: AppLocale.l('addNoteHint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    fillColor: kBg, filled: true, contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: 14, height: 1.5, color: kText),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  final now = DateTime.now();
                  final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                  final newEntry = '[$stamp] $text';
                  setState(() {
                    String updatedNotes = currentNotes.isEmpty ? newEntry : '$newEntry\n---\n$currentNotes';
                    if (isPrimary) {
                      _notes = updatedNotes;
                    } else if (entry != null) {
                      entry.notes = updatedNotes;
                    }
                    ctrl.clear();
                    _saveIndividualNote(name, isPrimary, entry, updatedNotes);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${AppLocale.l('noteSaved')}'), backgroundColor: Colors.green));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text(AppLocale.l('noNotes'), style: TextStyle(color: kMuted))))
          else
            ...entries.asMap().entries.map((en) {
              final i = en.key;
              final e = en.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: kTeal), const SizedBox(width: 6),
                        Text(e['date'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTeal)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            ctrl.text = e['text'] ?? '';
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              String updatedNotes = updatedEntries.map((enx) => '[${enx['date']}] ${enx['text']}').join('\n---\n');
                              if (isPrimary) _notes = updatedNotes;
                              else if (entry != null) entry.notes = updatedNotes;
                            });
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: kPurple2)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              String updatedNotes = updatedEntries.map((enx) => '[${enx['date']}] ${enx['text']}').join('\n---\n');
                              if (isPrimary) _notes = updatedNotes;
                              else if (entry != null) entry.notes = updatedNotes;
                              _saveIndividualNote(name, isPrimary, entry, updatedNotes);
                            });
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(e['text'] ?? '', style: TextStyle(fontSize: 14, height: 1.4, color: kText)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': _primaryName, 'isPrimary': true, 'entry': null},
      ..._extraPersons.map((p) => {'name': p.name, 'isPrimary': false, 'entry': p}),
    ];

    return ListView.builder(
      itemCount: allPersons.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (ctx, i) {
        final pData = allPersons[i];
        return _buildIndividualNoteSection(
           name: pData['name'] as String,
           isPrimary: pData['isPrimary'] as bool,
           entry: pData['entry'] as _PersonEntry?,
        );
      },
    );
  }

  void _showPrintPreview(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Row(children: [
          Icon(Icons.print, color: kPurple2),
          const SizedBox(width: 8),
          Text(AppLocale.l('printPreview'), style: TextStyle(color: kText)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                text,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocale.l('close'), style: TextStyle(color: kMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocale.l('copiedMsg'))),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(AppLocale.l('copyAndPrint')),
            style: ElevatedButton.styleFrom(backgroundColor: kTeal, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Parse notes string into list of {date, text} entries
  List<Map<String, String>> _parseNoteEntries(String notes) {
    if (notes.trim().isEmpty) return [];
    final parts = notes.split('\n---\n');
    final entries = <Map<String, String>>[];
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final match = RegExp(r'^\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2})\]\s*(.*)$', dotAll: true).firstMatch(trimmed);
      if (match != null) {
        entries.add({'date': match.group(1)!, 'text': match.group(2)!.trim()});
      } else {
        entries.add({'date': AppLocale.l('oldNote'), 'text': trimmed});
      }
    }
    return entries;
  }






  // ─────────────────────────────────────────────
  // TAB 11: JANMA PATRIKE (PDF GENERATION)
  // ─────────────────────────────────────────────
  Widget _buildJanmaPatrikeTab() {
    final selectedTheme = PdfThemes.getById(_selectedThemeId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Theme Picker ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette, color: kPurple2),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('pdfThemeSelect'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(AppLocale.l('pdfThemeDesc'), style: TextStyle(fontSize: 12, color: kMuted)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: PdfThemes.all.map((t) {
                    final isSelected = t.id == _selectedThemeId;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedThemeId = t.id);
                        PdfThemes.save(t.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected ? t.primaryLight.withOpacity(0.1) : kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? t.primaryLight : kBorder,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(color: t.primaryLight.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
                          ] : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Mini page preview
                            Container(
                              width: 44,
                              height: 56,
                              decoration: BoxDecoration(
                                color: t.pageBg,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: t.borderColor1, width: 1.5),
                              ),
                              child: Column(
                                children: [
                                  // Mini header
                                  Container(
                                    height: 10,
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: t.headerBg,
                                      borderRadius: BorderRadius.circular(1),
                                      border: Border.all(color: t.primaryDark, width: 0.5),
                                    ),
                                  ),
                                  // Mini table header
                                  Container(
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    color: t.tableHeaderBg,
                                  ),
                                  // Mini rows
                                  Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                    color: t.detailBoxBg,
                                  ),
                                  Container(
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    color: t.tableAltRow,
                                  ),
                                  // Mini border line
                                  const Spacer(),
                                  Container(
                                    height: 2,
                                    margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(color: t.borderColor2, width: 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(AppLocale.current == 'kn' ? t.nameKn : t.nameEn, style: TextStyle(
                              fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                              color: isSelected ? t.primaryLight : kText,
                            )),
                            Text(t.nameEn, style: TextStyle(fontSize: 9, color: kMuted)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Form Fields ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedTheme.primaryLight.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: selectedTheme.primaryLight),
                    const SizedBox(width: 8),
                    Text(AppLocale.l('createPatrike'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocale.l('patrikeDesc'),
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
                const SizedBox(height: 16),

                // Family Details
                Text(AppLocale.l('familyDetails'), style: TextStyle(fontWeight: FontWeight.w800, color: kTeal)),
                const SizedBox(height: 8),
                TextField(
                  controller: _fatherNameCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('fatherName'), prefixIcon: Icon(Icons.person_outline, size: 18), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _motherNameCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('motherName'), prefixIcon: Icon(Icons.person_3_outlined, size: 18), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _gotraCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('gotraLabel'), prefixIcon: Icon(Icons.hub_outlined, size: 18), isDense: true),
                ),
                const SizedBox(height: 20),

                // Jyotishi Details
                Text(AppLocale.l('jyotishiSection'), style: TextStyle(fontWeight: FontWeight.w800, color: kTeal)),
                const SizedBox(height: 8),
                TextField(
                  controller: _jyotishiNameCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('jyotishiName'), prefixIcon: Icon(Icons.storefront, size: 18), isDense: true),
                  onChanged: (_) => _saveJyotishiDetails(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _jyotishiPhoneCtrl,
                  decoration: InputDecoration(labelText: AppLocale.l('jyotishiPhone'), prefixIcon: Icon(Icons.phone, size: 18), isDense: true),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _saveJyotishiDetails(),
                ),
                const SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.print),
                    label: Text('${AppLocale.l('pdfPrint')} — ${AppLocale.current == 'kn' ? selectedTheme.nameKn : selectedTheme.nameEn}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    onPressed: () async {
                      final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
                      final timeStr = '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';

                      final ud = UserDetails(
                        name: widget.name,
                        dateStr: dateStr,
                        timeStr: timeStr,
                        place: widget.place,
                        fatherName: _fatherNameCtrl.text.trim(),
                        motherName: _motherNameCtrl.text.trim(),
                        gotra: _gotraCtrl.text.trim(),
                        jyotishiName: _jyotishiNameCtrl.text.trim(),
                        jyotishiPhone: _jyotishiPhoneCtrl.text.trim(),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('⏳ ${AppLocale.current == 'kn' ? selectedTheme.nameKn : selectedTheme.nameEn} ${AppLocale.l('pdfCreating')}'))
                      );

                      try {
                        await JanmaPatrikeService.generateAndPrint(ud, widget.result, theme: selectedTheme);
                      } catch (e) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ ${AppLocale.l('errorLabel')}: $e'), backgroundColor: Colors.red)
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  Widget _tableHeader(List<String> cols) {
    return Container(
      color: kPurple2.withOpacity(0.12),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(e.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kText)),
          ),
        )).toList(),
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
            child: Text(e.value,
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
      child: Row(children: [
        Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple2)),
        Expanded(child: Text(v, style: TextStyle())),
      ]),
    );
  }
}
