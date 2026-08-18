import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/common.dart';
import '../services/storage_service.dart';
import '../services/client_service.dart';
import '../services/history_service.dart';
import '../core/calculator.dart';
import '../constants/places.dart';
import '../services/timezone_service.dart';
import '../core/ephemeris.dart';
import '../widgets/date_time_input.dart';

import '../services/google_auth_service.dart';
import '../services/calendar_service.dart';
import '../services/location_service.dart';

import 'dashboard_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _nameCtrl    = TextEditingController();
  late final TextEditingController _placeCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lonCtrl;
  late final TextEditingController _tzCtrl;

  DateTime _dob      = DateTime.now();
  int _hour          = DateTime.now().hour % 12 == 0 ? 12 : DateTime.now().hour % 12;
  int _minute        = DateTime.now().minute;
  String _ampm       = DateTime.now().hour < 12 ? 'AM' : 'PM';
  String _ayanamsa   = 'lahiri';
  String _nodeMode   = 'mean';
  bool _loading      = false;
  bool _geoLoading   = false;
  String _geoStatus  = '';

  Map<String, Profile> _savedProfiles = {};
  String? _selName;

  bool _isInitStatus = false;
  bool _loadedFromSaved = false; // true when user opened an existing profile

  String _loadedNotes = '';
  String? _loadedClientId;
  Map<String, int> _loadedAroodhas = {};
  int? _loadedJanmaNakshatraIdx;
  List<String> _loadedGroupMembers = [];

  // Udayadi Ghati input
  bool _showGhatiInput = false;
  final _ghatiCtrl = TextEditingController();
  final _vighatiCtrl = TextEditingController();




  @override
  void initState() {
    super.initState();
    _placeCtrl = TextEditingController(text: LocationService.place);
    _latCtrl = TextEditingController(text: LocationService.lat.toStringAsFixed(4));
    _lonCtrl = TextEditingController(text: LocationService.lon.toStringAsFixed(4));
    _tzCtrl = TextEditingController(text: '${LocationService.tzOffset >= 0 ? '+' : ''}${LocationService.tzOffset}');
    _loadProfiles();
    HistoryService.load();
    loadWorldCities(); // Load 34K+ world cities for offline autocomplete
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _tzCtrl.dispose();
    _ghatiCtrl.dispose();
    _vighatiCtrl.dispose();
    super.dispose();
  }



  Future<void> _loadProfiles() async {
    final p = await StorageService.loadAll();

    // CRITICAL: Load ClientService data first so the sync can find existing clients/members
    await ClientService.loadAll();

    // ════════════════════════════════════════════════════════════
    // Bi-directional Sync: StorageService ↔ ClientService
    // ════════════════════════════════════════════════════════════

    // Direction 1: Fix stale clientIds AND ensure every profile has a Client+Member entry
    for (final entry in p.entries.toList()) {
      final profile = entry.value;
      if (profile.name.isEmpty || profile.date.isEmpty) continue;
      if (profile.name.contains('Sample') || profile.name.contains('ಮಾದರಿ')) continue;

      // Step 1: Find the canonical clientId for this person
      String? canonicalId;

      // a) Check if a Client with this name already exists
      final matchingClient = ClientService.clients
          .where((c) => c.name.toLowerCase() == entry.key.toLowerCase())
          .toList();
      if (matchingClient.isNotEmpty) {
        canonicalId = matchingClient.first.clientId;
      }

      // b) If no Client by name, check if this person is already a FamilyMember under any Client
      if (canonicalId == null) {
        for (final c in ClientService.clients) {
          final members = ClientService.getMembersForClient(c.clientId);
          if (members.any((m) => m.memberName == profile.name)) {
            canonicalId = c.clientId;
            break;
          }
        }
      }

      // c) If the profile already has a valid clientId from a previous save, use it
      if (canonicalId == null && profile.clientId != null && profile.clientId!.isNotEmpty) {
        canonicalId = profile.clientId;
      }

      // d) Only create a brand new Client if the person is truly not in the system at all
      if (canonicalId == null && profile.lat != 0 && profile.date.isNotEmpty) {
        final newClient = await ClientService.getOrCreateClient(name: profile.name, phone: 'No Phone');
        if (newClient != null) canonicalId = newClient.clientId;
      }

      // Step 2: Sync clientId on the profile if it's wrong or missing
      if (canonicalId != null && profile.clientId != canonicalId) {
        p[entry.key] = Profile(
          name: profile.name, date: profile.date, hour: profile.hour,
          minute: profile.minute, ampm: profile.ampm, lat: profile.lat,
          lon: profile.lon, tzOffset: profile.tzOffset, place: profile.place,
          notes: profile.notes, aroodhas: profile.aroodhas,
          janmaNakshatraIdx: profile.janmaNakshatraIdx,
          clientId: canonicalId,
          groupMembers: profile.groupMembers,
        );
        await StorageService.save(p[entry.key]!);
      }

      // Step 3: Ensure this person exists as a FamilyMember under that client
      if (canonicalId != null && canonicalId.isNotEmpty && profile.lat != 0) {
        final members = ClientService.getMembersForClient(canonicalId);
        if (!members.any((m) => m.memberName == profile.name)) {
          await ClientService.addFamilyMember(FamilyMember(
            clientId: canonicalId,
            memberName: profile.name,
            relation: 'Self',
            dob: profile.date,
            birthTime: '${profile.hour.toString().padLeft(2,'0')}:${profile.minute.toString().padLeft(2,'0')} ${profile.ampm}',
            birthPlace: profile.place,
            lat: profile.lat, lon: profile.lon,
            tzOffset: profile.tzOffset,
            notes: profile.notes,
          ));
        }
      }
    }

    // Direction 2: ClientService → StorageService
    // Ensure every FamilyMember with birth data has a corresponding StorageService profile
    for (final client in ClientService.clients) {
      final members = ClientService.getMembersForClient(client.clientId);
      for (final m in members) {
        if (m.memberName.isEmpty || m.dob.isEmpty || m.lat == 0) continue;
        if (!p.containsKey(m.memberName)) {
          final newProfile = Profile(
            name: m.memberName,
            date: m.dob,
            hour: m.hour12,
            minute: m.minute,
            ampm: m.ampm,
            lat: m.lat, lon: m.lon,
            place: m.birthPlace,
            notes: m.notes,
            clientId: client.clientId,
            tzOffset: m.tzOffset,
          );
          await StorageService.save(newProfile);
          p[m.memberName] = newProfile;
        }
      }
    }

    if (mounted) setState(() => _savedProfiles = p);
  }

  void _loadProfile(Profile p) {
    setState(() {
      _loadedFromSaved = true; // mark as existing — updates go in-place
      _nameCtrl.text  = p.name;
      _placeCtrl.text = p.place;
      _latCtrl.text   = p.lat.toStringAsFixed(4);
      _lonCtrl.text   = p.lon.toStringAsFixed(4);
      _tzCtrl.text    = '${p.tzOffset >= 0 ? '+' : ''}${p.tzOffset}';
      _hour   = p.hour;
      _minute = p.minute;
      _ampm   = p.ampm;
      _loadedNotes = p.notes;
      _loadedClientId = p.clientId;
      _loadedAroodhas = Map.from(p.aroodhas);
      _loadedJanmaNakshatraIdx = p.janmaNakshatraIdx;
      _loadedGroupMembers = List.from(p.groupMembers);
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
          setState(() => _geoStatus = AppLocale.l('placeNotFound'));
        } else if (data.length == 1) {
          // Single result — auto-fill
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: _dob);
          setState(() {
            _placeCtrl.text = placeName.trim();
            _latCtrl.text = lat.toStringAsFixed(4);
            _lonCtrl.text = lon.toStringAsFixed(4);
            _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
            _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
          });
        } else {
          // Multiple results — show disambiguation dialog
          if (mounted) {
            _showPlaceDisambiguation(data);
          }
        }
      }
    } catch (_) {
      setState(() => _geoStatus = AppLocale.l('networkError'));
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
              child: Text(AppLocale.l('selectPlace'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1)),
            ),
            Text(AppLocale.l('multiPlacesFound'), style: TextStyle(fontSize: 13, color: kMuted)),
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
                    onTap: () async {
                      Navigator.pop(ctx);
                      final lat = double.parse(place['lat']);
                      final lon = double.parse(place['lon']);
                      final autoTz = await getTimezoneForPlace(displayName, lat, lon, birthDate: _dob);
                      setState(() {
                        _latCtrl.text = lat.toStringAsFixed(4);
                        _lonCtrl.text = lon.toStringAsFixed(4);
                        _tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                        _geoStatus = '📍 $displayName (TZ: ${autoTz >= 0 ? '+' : ''}$autoTz)';
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

      final aynMode = _ayanamsa;
      final trueNode = _nodeMode == 'true';

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
        String uiNotes = _loadedNotes;
        String? activeClientId = _loadedClientId;

        // ── Auto-save to history (fire-and-forget) ──
        HistoryService.add(HistoryEntry(
          name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : AppLocale.l('unknown'),
          date: '${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}',
          hour: _hour,
          minute: _minute,
          ampm: _ampm,
          lat: lat,
          lon: lon,
          tzOffset: tzOffset,
          place: _placeCtrl.text,
          timestamp: DateTime.now().toIso8601String(),
        ));

        if (!_loadedFromSaved) {
          activeClientId = await ClientService.generateNextClientId();
          final timeStr = '$_hour:${_minute.toString().padLeft(2, '0')} $_ampm';
          final dateStr = '${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}';

          // Forcefully register the client right now so it exists in memory immediately
          await ClientService.addClient(Client(
            clientId: activeClientId,
            name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : '${AppLocale.l('unknown')}',
            phone: '',
            address: _placeCtrl.text,
            createdAt: dateStr,
          ));
        }

        // Navigate to Dashboard
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DashboardScreen(
            result: result,
            name: _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : '${AppLocale.l('unknown')}',
            place: _placeCtrl.text,
            dob: _dob,
            hour: _hour,
            minute: _minute,
            ampm: _ampm,
            lat: lat,
            lon: lon,
            tz: tzOffset,
            extraInfo: {'clientId': activeClientId ?? '', 'ayanamsa': _ayanamsa, 'nodeMode': _nodeMode},
            initialNotes: uiNotes,
            initialAroodhas: _loadedAroodhas,
            initialJanmaNakshatraIdx: _loadedJanmaNakshatraIdx,
            initialGroupMembers: _loadedGroupMembers,
            onSave: (notes, aroodhas, janmaIdx, {bool isNew = true}) =>
                _saveProfile(activeClientId, notes: notes, aroodhas: aroodhas, janmaNakshatraIdx: janmaIdx, isNew: !_loadedFromSaved),
          ),
        )).then((_) async {
          await _loadProfiles();
        });
        setState(() => _loading = false);
      }
    } catch (e) {
      _showError('${AppLocale.l('errorLabel')}: $e');
    }
    setState(() => _loading = false);
  }

  void _saveProfile(String? activeClientId, {String notes = '', Map<String, int> aroodhas = const {}, int? janmaNakshatraIdx, bool isNew = true}) async {
    String name = _nameCtrl.text.trim();
    if (name.isEmpty) name = 'Unknown_${_dob.toIso8601String().substring(0, 10)}';

    final profiles = await StorageService.loadAll();
    final existing = profiles[name];
    String? cId = existing?.clientId ?? activeClientId;

    // 1. Always resolve Client ID through the canonical lookup (matches by name too now)
    final resolvedClient = await ClientService.getOrCreateClient(name: name, phone: 'No Phone');
    if (resolvedClient != null) cId = resolvedClient.clientId;

    final p = Profile(
      name: name,
      date: '${_dob.year}-${_dob.month.toString().padLeft(2,'0')}-${_dob.day.toString().padLeft(2,'0')}',
      hour: _hour, minute: _minute, ampm: _ampm,
      lat: double.tryParse(_latCtrl.text) ?? LocationService.lat,
      lon: double.tryParse(_lonCtrl.text) ?? LocationService.lon,
      tzOffset: double.tryParse(_tzCtrl.text) ?? LocationService.tzOffset,
      place: _placeCtrl.text,
      notes: notes,
      aroodhas: aroodhas,
      janmaNakshatraIdx: janmaNakshatraIdx,
      clientId: cId,
      groupMembers: existing?.groupMembers ?? _loadedGroupMembers,
    );
    
    // 2. Add or Update this profile as a member of the Client
    if (cId != null && cId.isNotEmpty) {
      final member = FamilyMember(
        clientId: cId,
        memberName: name,
        relation: 'Self',
        dob: p.date,
        birthTime: '${p.hour.toString().padLeft(2,'0')}:${p.minute.toString().padLeft(2,'0')} ${p.ampm}',
        birthPlace: p.place,
        lat: p.lat,
        lon: p.lon,
        tzOffset: p.tzOffset,
        notes: p.notes,
      );
      final members = ClientService.getMembersForClient(cId);
      if (!members.any((m) => m.memberName == name)) {
        await ClientService.addFamilyMember(member);
      } else {
        await ClientService.updateFamilyMember(member);
      }
    }

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


    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputCard(),
              const SizedBox(height: 32),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildProfileListSheet() {
    String searchQuery = '';
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        // Core Unification: Merge all current local storage profiles with active Appointment/Client family members dynamically
        final Map<String, Profile> unifiedProfiles = Map.from(_savedProfiles);
        for (var client in ClientService.clients) {
          final members = ClientService.getMembersForClient(client.clientId);
          for (var m in members) {
            if (m.dob.isNotEmpty && m.birthTime.isNotEmpty && m.lat != 0) {
              if (!unifiedProfiles.containsKey(m.memberName)) {
                // Not in StorageService at all
                unifiedProfiles[m.memberName] = Profile(
                  name: m.memberName, date: m.dob, hour: m.hour12, minute: m.minute, ampm: m.ampm,
                  lat: m.lat, lon: m.lon, place: m.birthPlace, notes: m.notes, tzOffset: m.tzOffset,
                  clientId: m.clientId,
                );
              } else {
                // FORCED SYNC: Always overwrite the old StorageService profile with the TRUE Appointments Client ID!
                final op = unifiedProfiles[m.memberName]!;
                unifiedProfiles[m.memberName] = Profile(
                  name: op.name, date: op.date, hour: op.hour, minute: op.minute, ampm: op.ampm,
                  lat: op.lat, lon: op.lon, tzOffset: op.tzOffset, place: op.place, notes: op.notes,
                  aroodhas: op.aroodhas, janmaNakshatraIdx: op.janmaNakshatraIdx,
                  clientId: m.clientId, // Force use the linked Client ID dynamically
                  groupMembers: op.groupMembers, // Preserve multi-person group!
                );
              }
            }
          }
        }

        // Apply Search Filter and Sort Sequentially (In Serial)
        final filteredEntries = unifiedProfiles.entries.where((e) {
          if (searchQuery.isEmpty) return true;
          final sq = searchQuery.toLowerCase();
          return e.key.toLowerCase().contains(sq) ||
                 e.value.place.toLowerCase().contains(sq) ||
                 (e.value.clientId != null && e.value.clientId!.toLowerCase().contains(sq)) ||
                 e.value.date.contains(searchQuery);
        }).toList();

        // Sort by savedAt timestamp (newest first) so new records always appear on top
        // Records without savedAt (old/restored data) fall below, sorted by clientId
        filteredEntries.sort((a, b) {
          final aTime = a.value.savedAt;
          final bTime = b.value.savedAt;
          // Both have savedAt → newest first
          if (aTime != null && bTime != null) return bTime.compareTo(aTime);
          // Only one has savedAt → it goes first
          if (aTime != null && bTime == null) return -1;
          if (aTime == null && bTime != null) return 1;
          // Neither has savedAt → fall back to clientId descending
          final aId = a.value.clientId ?? '';
          final bId = b.value.clientId ?? '';
          return bId.compareTo(aId);
        });

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(AppLocale.l('savedKundali'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2)),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setSheetState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: AppLocale.l('searchHint'),
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
              if (filteredEntries.isEmpty)
                Padding(padding: EdgeInsets.all(32), child: Text(searchQuery.isEmpty ? AppLocale.l('noSavedKundali') : AppLocale.l('noResults'), style: TextStyle(color: kMuted)))
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredEntries.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final name = filteredEntries[i].key;
                      final profile = filteredEntries[i].value;
                      final totalKundalis = 1 + profile.groupMembers.length;
                      final hasGroup = profile.groupMembers.isNotEmpty;
                      return ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: hasGroup ? kPurple2.withOpacity(0.15) : kBorder,
                              child: Icon(hasGroup ? Icons.group : Icons.person, color: kPurple2),
                            ),
                            if (hasGroup)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: kTeal,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: kBg, width: 1.5),
                                  ),
                                  child: Text('$totalKundalis', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                              ),
                          ],
                        ),
                        title: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: name, style: TextStyle(fontWeight: FontWeight.w800, color: kText, fontSize: 16)),
                              if (profile.clientId != null && profile.clientId!.isNotEmpty) 
                                TextSpan(text: '  (${profile.clientId})', style: TextStyle(fontWeight: FontWeight.w600, color: kTeal, fontSize: 12)),
                            ],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${profile.date} | ${profile.place}', style: TextStyle(color: kMuted)),
                            if (hasGroup)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '👥 $totalKundalis ${AppLocale.l('kundaliCount')}: ${profile.groupMembers.join(', ')}',
                                  style: TextStyle(color: kTeal, fontSize: 11, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                              tooltip: AppLocale.l('delete'),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: ctx,
                                  builder: (dCtx) => AlertDialog(
                                    backgroundColor: kBg,
                                    title: Text(AppLocale.l('deleteConfirm'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
                                    content: Text('"$name" ${AppLocale.l('deleteMsg')}', style: TextStyle(color: kMuted)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(AppLocale.l('noBtn'), style: TextStyle(color: kMuted))),
                                      TextButton(onPressed: () => Navigator.pop(dCtx, true), child: Text(AppLocale.l('delete'), style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await StorageService.delete(name);
                                  // Also remove the member from ClientService (properly persist)
                                  if (profile.clientId != null && profile.clientId!.isNotEmpty) {
                                    await ClientService.removeFamilyMember(profile.clientId!, name);
                                  }
                                  await _loadProfiles();
                                  setSheetState(() {}); // refresh the sheet
                                }
                              },
                            ),
                            Icon(Icons.chevron_right, color: kMuted),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _loadProfile(profile);
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

  // ════════════════════════════════════════════════
  // HISTORY SHEET
  // ════════════════════════════════════════════════

  Widget _buildHistorySheet(ScrollController scrollCtrl) {
    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        final items = HistoryService.entries;
        return SafeArea(
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.history, color: const Color(0xFF7B2D8E), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${AppLocale.l('recentKundalis')} (${items.length}/100)',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: const Color(0xFF7B2D8E)),
                      ),
                    ),
                    if (items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              backgroundColor: kBg,
                              title: Text(AppLocale.l('clearHistory'), style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
                              content: Text('${AppLocale.l('clearHistoryConfirm')}', style: TextStyle(color: kMuted)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(AppLocale.l('no'), style: TextStyle(color: kMuted))),
                                TextButton(onPressed: () => Navigator.pop(dCtx, true), child: Text(AppLocale.l('delete'), style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await HistoryService.clearAll();
                            setSheetState(() {});
                          }
                        },
                        icon: Icon(Icons.delete_sweep, color: Colors.red.shade400, size: 18),
                        label: Text(AppLocale.l('delete'), style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off, size: 64, color: kMuted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(AppLocale.l('historyEmpty'), style: TextStyle(fontSize: 16, color: kMuted)),
                        const SizedBox(height: 4),
                        Text(AppLocale.l('historyHint'), style: TextStyle(fontSize: 13, color: kMuted.withOpacity(0.6))),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                    itemBuilder: (ctx, i) {
                      final entry = items[i];
                      // Format relative time
                      final ts = DateTime.tryParse(entry.timestamp) ?? DateTime.now();
                      final diff = DateTime.now().difference(ts);
                      String ago;
                      if (diff.inMinutes < 1) {
                        ago = AppLocale.l('now');
                      } else if (diff.inMinutes < 60) {
                        ago = '${diff.inMinutes}m ${AppLocale.l('ago')}';
                      } else if (diff.inHours < 24) {
                        ago = '${diff.inHours}h ${AppLocale.l('ago')}';
                      } else {
                        ago = '${diff.inDays}d ${AppLocale.l('ago')}';
                      }

                      // Check if already saved
                      final isSaved = _savedProfiles.containsKey(entry.name);

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: isSaved
                              ? kGreen.withOpacity(0.15)
                              : const Color(0xFF7B2D8E).withOpacity(0.1),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.person_outline,
                            color: isSaved ? kGreen : const Color(0xFF7B2D8E),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          entry.name,
                          style: TextStyle(fontWeight: FontWeight.w700, color: kText, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${entry.date}  ${entry.hour.toString().padLeft(2, '0')}:${entry.minute.toString().padLeft(2, '0')} ${entry.ampm}  •  ${entry.place}',
                          style: TextStyle(color: kMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kMuted.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(ago, style: TextStyle(fontSize: 10, color: kMuted)),
                            ),
                            const SizedBox(width: 4),
                            if (!isSaved)
                              IconButton(
                                icon: Icon(Icons.bookmark_add_outlined, color: kTeal, size: 20),
                                tooltip: AppLocale.l('save'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () async {
                                  await HistoryService.promoteToProfile(entry);
                                  await _loadProfiles();
                                  setSheetState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('\u2705 "${entry.name}" ${AppLocale.l('saved')}'),
                                        backgroundColor: kGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red.shade300, size: 18),
                              tooltip: AppLocale.l('delete'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () async {
                                await HistoryService.removeAt(i);
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _loadedFromSaved = false;
                            _nameCtrl.text = entry.name;
                            _placeCtrl.text = entry.place;
                            _latCtrl.text = entry.lat.toStringAsFixed(4);
                            _lonCtrl.text = entry.lon.toStringAsFixed(4);
                            _tzCtrl.text = '${entry.tzOffset >= 0 ? '+' : ''}${entry.tzOffset}';
                            _hour = entry.hour;
                            _minute = entry.minute;
                            _ampm = entry.ampm;
                            _loadedNotes = '';
                            _loadedClientId = null;
                            _loadedAroodhas = {};
                            _loadedJanmaNakshatraIdx = null;
                            _loadedGroupMembers = [];
                            try {
                              final parts = entry.date.split('-');
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



  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✨ ${AppLocale.l('kundaliTitle')}', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: kText),
            decoration: InputDecoration(
              labelText: AppLocale.l('name'),
              prefixIcon: Icon(Icons.person_outline, color: kMuted),
            ),
          ),
          const SizedBox(height: 14),

          // Date input
          DateInputRow(
            date: _dob,
            color: kPurple2,
            onChanged: (d) => setState(() => _dob = d),
          ),
          const SizedBox(height: 14),

          // Time input
          TimeInputRow(
            hour: _hour,
            minute: _minute,
            ampm: _ampm,
            color: kPurple2,
            onChanged: (h, m, a) => setState(() { _hour = h; _minute = m; _ampm = a; }),
          ),
          const SizedBox(height: 8),

          // Udayadi Ghati toggle + input
          GestureDetector(
            onTap: () => setState(() => _showGhatiInput = !_showGhatiInput),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _showGhatiInput ? kPurple2.withOpacity(0.08) : kCard,
                border: Border.all(color: _showGhatiInput ? kPurple2.withOpacity(0.3) : kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.sunny, size: 18, color: _showGhatiInput ? kOrange : kMuted),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  AppLocale.l('udayadiGhatiLabel'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _showGhatiInput ? kPurple2 : kText),
                )),
                Icon(_showGhatiInput ? Icons.expand_less : Icons.expand_more, color: kMuted, size: 20),
              ]),
            ),
          ),
          if (_showGhatiInput) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCard,
                border: Border.all(color: kPurple2.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [
                  Expanded(child: TextField(
                    controller: _ghatiCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      if (n > 60) _ghatiCtrl.text = '60';
                    },
                    decoration: InputDecoration(
                      labelText: AppLocale.l('ghatiLabel'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: TextStyle(fontSize: 14, color: kText),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(
                    controller: _vighatiCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      if (n > 60) _vighatiCtrl.text = '60';
                    },
                    decoration: InputDecoration(
                      labelText: AppLocale.l('vighatiLabel'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    style: TextStyle(fontSize: 14, color: kText),
                  )),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _applyGhatiTime,
                    child: Text(AppLocale.l('applyLabel'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ]),

              ]),
            ),
          ],
          const SizedBox(height: 14),

          // Searchable Place Selector (Offline + Online)
          Autocomplete<String>(
            key: ValueKey(_placeCtrl.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return offlinePlaces.keys.take(15);
              }
              final query = textEditingValue.text.toLowerCase();
              final offline = offlinePlaces.keys.where((name) => name.toLowerCase().contains(query)).toList();
              if (worldCitiesLoaded) {
                final worldResults = searchWorldCities(textEditingValue.text, limit: 15);
                for (final w in worldResults) {
                  final label = worldCityLabel(w);
                  if (!offline.any((o) => o.toLowerCase() == label.toLowerCase())) {
                    offline.add(label);
                  }
                }
              }
              return offline.take(20);
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              // Pre-fill with default location if empty
              if (textEditingController.text.isEmpty && _placeCtrl.text.isNotEmpty) {
                textEditingController.text = _placeCtrl.text;
              }
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                style: TextStyle(color: kText),
                decoration: InputDecoration(
                  labelText: AppLocale.l('searchPlace'),
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
            onSelected: (String selection) async {
              if (offlinePlaces.containsKey(selection)) {
                final coords = offlinePlaces[selection]!;
                setState(() {
                  _placeCtrl.text = selection;
                  _latCtrl.text = coords[0].toStringAsFixed(4);
                  _lonCtrl.text = coords[1].toStringAsFixed(4);
                  _tzCtrl.text = '${coords[2] >= 0 ? '+' : ''}${coords[2]}';
                  _geoStatus = '📍 $selection (TZ: ${coords[2] >= 0 ? '+' : ''}${coords[2]})';
                });
              } else {
                final worldResults = searchWorldCities(selection.split(', ').first, limit: 1);
                if (worldResults.isNotEmpty) {
                  final w = worldResults.first;
                  final lat = (w['la'] as num).toDouble();
                  final lon = (w['lo'] as num).toDouble();
                  final cc = w['c'] as String? ?? '';
                  final tz = cc.isNotEmpty
                      ? getDstAwareOffset(cc, lat, lon, _dob)
                      : (w['tz'] as num).toDouble();
                  setState(() {
                    _placeCtrl.text = selection;
                    _latCtrl.text = lat.toStringAsFixed(4);
                    _lonCtrl.text = lon.toStringAsFixed(4);
                    _tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';
                    _geoStatus = '📍 $selection (TZ: ${tz >= 0 ? '+' : ''}$tz)';
                  });
                } else {
                  // Fallback: online geocode
                  _placeCtrl.text = selection;
                  _geocodeMultiple(selection);
                }
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

          // Lat/Lon/TZ
          Row(children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: _latCtrl,
                style: TextStyle(color: kText),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: AppLocale.l('lat'), isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: TextField(
                controller: _lonCtrl,
                style: TextStyle(color: kText),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: AppLocale.l('lon'), isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _tzCtrl,
                style: TextStyle(color: kText),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: AppLocale.l('tzOffset'), isDense: true),
              ),
            ),
          ]),
          // Single Letter Mode toggle
          ValueListenableBuilder<bool>(
            valueListenable: SingleLetterMode.notifier,
            builder: (context, isActive, _) => Container(
              decoration: BoxDecoration(
                color: isActive ? kPurple2.withOpacity(0.08) : kCard,
                border: Border.all(color: isActive ? kPurple2.withOpacity(0.3) : kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  AppLocale.l('singleLetterMode'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? kPurple2 : kText),
                ),
                value: isActive,
                activeColor: kPurple2,
                onChanged: (v) => SingleLetterMode.toggle(v),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Samshaka Mode toggle
          ValueListenableBuilder<bool>(
            valueListenable: SamshakaMode.notifier,
            builder: (context, isActive, _) => Container(
              decoration: BoxDecoration(
                color: isActive ? kPurple2.withOpacity(0.08) : kCard,
                border: Border.all(color: isActive ? kPurple2.withOpacity(0.3) : kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  AppLocale.l('samshakaLabel'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? kPurple2 : kText),
                ),
                value: isActive,
                activeColor: kPurple2,
                onChanged: (v) => SamshakaMode.toggle(v),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Advanced options
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text('⚙️ ${AppLocale.l('advancedSettings')}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kText)),
              children: [
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ayanamsa,
                      decoration: InputDecoration(labelText: AppLocale.l('ayanamsa')),
                      items: [{'v':'lahiri','l':'Lahiri'},{'v':'raman','l':'Raman'},{'v':'kp','l':'KP'}].map((m) => DropdownMenuItem(
                        value: m['v']!, child: Text(m['l']!, style: TextStyle(color: kText)))).toList(),
                      onChanged: (v) => setState(() => _ayanamsa = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _nodeMode,
                      decoration: InputDecoration(labelText: AppLocale.l('nodeType')),
                      items: [{'v':'true','l':'True Node'},{'v':'mean','l':'Mean Node'}].map((m) => DropdownMenuItem(
                        value: m['v']!, child: Text(m['l']!, style: TextStyle(color: kText)))).toList(),
                      onChanged: (v) => setState(() => _nodeMode = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
            ),
          ),



          // Action buttons
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
                child: Text(AppLocale.l('openSaved'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 6),
            // History button
            SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: kCard,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      minChildSize: 0.3,
                      maxChildSize: 0.9,
                      expand: false,
                      builder: (_, scrollCtrl) => _buildHistorySheet(scrollCtrl),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2D8E),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Get the timezone of the currently selected location
                  final selectedTz = double.tryParse(_tzCtrl.text) ?? LocationService.tzOffset;
                  // Convert device UTC time to the selected location's local time
                  final nowUtc = DateTime.now().toUtc();
                  final locationNow = nowUtc.add(Duration(
                    hours: selectedTz.truncate(),
                    minutes: ((selectedTz - selectedTz.truncate()) * 60).round(),
                  ));
                  setState(() {
                    _loadedFromSaved = false;
                    _nameCtrl.clear();
                    // Keep the currently selected place — don't reset to default
                    _dob = locationNow;
                    _hour = locationNow.hour % 12 == 0 ? 12 : locationNow.hour % 12;
                    _minute = locationNow.minute;
                    _ampm = locationNow.hour >= 12 ? 'PM' : 'AM';
                    _loadedNotes = '';
                    _loadedClientId = null;
                    _loadedAroodhas = {};
                    _loadedJanmaNakshatraIdx = null;
                    _loadedGroupMembers = [];
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(AppLocale.l('currentTime'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(AppLocale.l('generate'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
  /// Calculate birth time from Udayadi Ghati/Vighati
  void _applyGhatiTime() {
    final ghati = int.tryParse(_ghatiCtrl.text) ?? 0;
    final vighati = int.tryParse(_vighatiCtrl.text) ?? 0;

    if (ghati == 0 && vighati == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.l('enterGhatiErr')), backgroundColor: Colors.red),
      );
      return;
    }

    final lat = double.tryParse(_latCtrl.text) ?? 0;
    final lon = double.tryParse(_lonCtrl.text) ?? 0;
    final tzText = _tzCtrl.text.replaceAll('+', '');
    final tz = double.tryParse(tzText) ?? 5.5;

    // Get sunrise JD for the selected date
    // Must use refraction-corrected sunrise (with tzOffset) to match Panchanga calculator
    final srSs = Ephemeris.findSunriseSetForDate(
      _dob.year, _dob.month, _dob.day, lat, lon, tzOffset: tz,
    );
    final sunriseJd = srSs[0];

    // Convert ghati/vighati to JD offset
    // 1 ghati = 24 min = 1/60 day, 1 vighati = 24 sec = 1/3600 day
    final totalGhatis = ghati + (vighati / 60.0);
    final jdBirth = sunriseJd + (totalGhatis / 60.0);

    // Convert sunrise JD to local time string for display
    final sunriseStr = formatTimeFromJd(sunriseJd, tzOffset: tz);

    // Convert birth JD to local civil DateTime
    final localJd = jdBirth + 0.5 + (tz / 24.0);
    double frac = localJd - localJd.floor();
    frac = ((frac % 1.0) + 1.0) % 1.0;
    int totalMinutes = (frac * 24 * 60).round();
    if (totalMinutes >= 1440) totalMinutes -= 1440;
    int h24 = totalMinutes ~/ 60;
    int min = totalMinutes % 60;
    if (h24 >= 24) h24 -= 24;

    // Check if civil date differs from vedic date (time crossed midnight)
    final birthUtcMs = ((jdBirth - 2440587.5) * 86400000).round();
    final birthUtc = DateTime.fromMillisecondsSinceEpoch(birthUtcMs, isUtc: true);
    final birthLocal = birthUtc.add(Duration(minutes: (tz * 60).round()));
    final civilDate = DateTime(birthLocal.year, birthLocal.month, birthLocal.day);
    final crossedMidnight = civilDate.day != _dob.day || civilDate.month != _dob.month || civilDate.year != _dob.year;

    setState(() {
      _dob = civilDate;
      _ampm = h24 >= 12 ? 'PM' : 'AM';
      _hour = h24 % 12 == 0 ? 12 : h24 % 12;
      _minute = min;
    });

    final timeStr = '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} $_ampm';
    final civilStr = crossedMidnight
        ? ' (${civilDate.day.toString().padLeft(2, '0')}-${civilDate.month.toString().padLeft(2, '0')}-${civilDate.year})'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocale.l('timeAdjusted')}: $timeStr$civilStr'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
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
