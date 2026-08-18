import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/strings.dart';
import '../constants/places.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/dasha_widget.dart';
import '../core/match_making.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/client_service.dart';

class MatchMakingTab extends StatefulWidget {
  const MatchMakingTab({super.key});

  @override
  State<MatchMakingTab> createState() => _MatchMakingTabState();
}

class _MatchMakingTabState extends State<MatchMakingTab> {
  // Bride input
  final _bNameCtrl = TextEditingController();
  final _bPlaceCtrl = TextEditingController();
  final _bLatCtrl = TextEditingController(text: '14.98');
  final _bLonCtrl = TextEditingController(text: '74.73');
  final _bTzCtrl = TextEditingController(text: '+5.5');
  DateTime _bDob = DateTime(2000, 1, 1);
  int _bHour = 6, _bMinute = 0;
  String _bAmpm = 'AM';
  bool _bGeoLoading = false;
  String _bGeoStatus = '';

  // Groom input
  final _gNameCtrl = TextEditingController();
  final _gPlaceCtrl = TextEditingController();
  final _gLatCtrl = TextEditingController(text: '14.98');
  final _gLonCtrl = TextEditingController(text: '74.73');
  final _gTzCtrl = TextEditingController(text: '+5.5');
  DateTime _gDob = DateTime(2000, 1, 1);
  int _gHour = 6, _gMinute = 0;
  String _gAmpm = 'AM';
  bool _gGeoLoading = false;
  String _gGeoStatus = '';

  bool _loading = false;
  KundaliResult? _brideResult;
  KundaliResult? _groomResult;
  Map<String, dynamic>? _fullResult;

  Future<void> _calculate() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      final bLat = double.tryParse(_bLatCtrl.text) ?? 14.98;
      final bLon = double.tryParse(_bLonCtrl.text) ?? 74.73;
      final bTz = double.tryParse(_bTzCtrl.text) ?? 5.5;
      int bH24 = _bHour + (_bAmpm == 'PM' && _bHour != 12 ? 12 : 0);
      if (_bAmpm == 'AM' && _bHour == 12) bH24 = 0;

      final gLat = double.tryParse(_gLatCtrl.text) ?? 14.98;
      final gLon = double.tryParse(_gLonCtrl.text) ?? 74.73;
      final gTz = double.tryParse(_gTzCtrl.text) ?? 5.5;
      int gH24 = _gHour + (_gAmpm == 'PM' && _gHour != 12 ? 12 : 0);
      if (_gAmpm == 'AM' && _gHour == 12) gH24 = 0;

      final brideR = await AstroCalculator.calculate(
        year: _bDob.year, month: _bDob.month, day: _bDob.day,
        hourUtcOffset: bTz, hour24: bH24 + _bMinute / 60.0,
        lat: bLat, lon: bLon, ayanamsaMode: 'lahiri', trueNode: true,
      );
      final groomR = await AstroCalculator.calculate(
        year: _gDob.year, month: _gDob.month, day: _gDob.day,
        hourUtcOffset: gTz, hour24: gH24 + _gMinute / 60.0,
        lat: gLat, lon: gLon, ayanamsaMode: 'lahiri', trueNode: true,
      );

      if (brideR == null || groomR == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocale.l('calcFailed')), backgroundColor: Colors.red),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // Extract planet rashi indices
      Map<String, int> extractRashis(KundaliResult r) {
        final m = <String, int>{};
        for (final e in r.planets.entries) {
          m[e.key] = e.value.rashiIndex;
        }
        return m;
      }

      final bRashis = extractRashis(brideR);
      final gRashis = extractRashis(groomR);
      final bLagnaRashi = brideR.planets['ಲಗ್ನ']?.rashiIndex ?? 0;
      final gLagnaRashi = groomR.planets['ಲಗ್ನ']?.rashiIndex ?? 0;
      final bMoonRashi = brideR.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
      final gMoonRashi = groomR.planets['ಚಂದ್ರ']?.rashiIndex ?? 0;
      final bNakIdx = brideR.panchang.nakshatraIndex;
      final gNakIdx = groomR.panchang.nakshatraIndex;

      // Navamsha rashis
      final bNavLagna = MatchMakingLogic.navamshaRashi(brideR.planets['ಲಗ್ನ']?.longitude ?? 0);
      final bNavMoon = MatchMakingLogic.navamshaRashi(brideR.planets['ಚಂದ್ರ']?.longitude ?? 0);
      final gNavLagna = MatchMakingLogic.navamshaRashi(groomR.planets['ಲಗ್ನ']?.longitude ?? 0);
      final gNavMoon = MatchMakingLogic.navamshaRashi(groomR.planets['ಚಂದ್ರ']?.longitude ?? 0);

      final fullResult = MatchMakingLogic.calculateFullCompatibility(
        brideNakIdx: bNakIdx, brideMoonRashi: bMoonRashi, brideLagnaRashi: bLagnaRashi, bridePlanetRashis: bRashis,
        brideNavLagnaRashi: bNavLagna, brideNavMoonRashi: bNavMoon,
        groomNakIdx: gNakIdx, groomMoonRashi: gMoonRashi, groomLagnaRashi: gLagnaRashi, groomPlanetRashis: gRashis,
        groomNavLagnaRashi: gNavLagna, groomNavMoonRashi: gNavMoon,
      );

      setState(() {
        _brideResult = brideR;
        _groomResult = groomR;
        _fullResult = fullResult;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocale.l('calcFailed')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  // Geocode helper
  Future<void> _geocode(String placeName, TextEditingController latCtrl, TextEditingController lonCtrl, TextEditingController tzCtrl, void Function(bool) setGeoLoading, void Function(String) setGeoStatus) async {
    if (placeName.trim().isEmpty) return;
    setGeoLoading(true);
    setGeoStatus('');
    try {
      final q = Uri.encodeComponent(placeName.trim());
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$q&format=json&limit=5');
      final resp = await http.get(url, headers: {'User-Agent': 'BharatheeyamApp/1.0'}).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        if (data.isEmpty) {
          setGeoStatus(AppLocale.l('placeNotFound'));
        } else if (data.length == 1) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final displayName = data[0]['display_name'] as String;
          final autoTz = await getTimezoneForPlace(displayName, lat, lon);
          setState(() {
            latCtrl.text = lat.toStringAsFixed(4);
            lonCtrl.text = lon.toStringAsFixed(4);
            tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
          });
          setGeoStatus('📍 $displayName');
        } else {
          if (mounted) _showPlaceDisambiguation(data, latCtrl, lonCtrl, tzCtrl, setGeoStatus);
        }
      }
    } catch (_) {
      setGeoStatus(AppLocale.l('networkError'));
    }
    setGeoLoading(false);
  }

  void _showPlaceDisambiguation(List<dynamic> results, TextEditingController latCtrl, TextEditingController lonCtrl, TextEditingController tzCtrl, void Function(String) setGeoStatus) {
    showModalBottomSheet(
      context: context, backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.all(16), child: Text(AppLocale.l('selectPlace'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple1))),
        Flexible(child: ListView.separated(
          shrinkWrap: true, itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final place = results[i];
            final displayName = place['display_name'] ?? '';
            return ListTile(
              leading: CircleAvatar(backgroundColor: kPurple1.withOpacity(0.1), child: Icon(Icons.location_on, color: kPurple1, size: 20)),
              title: Text(displayName, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () async {
                Navigator.pop(ctx);
                final lat = double.parse(place['lat']);
                final lon = double.parse(place['lon']);
                final autoTz = await getTimezoneForPlace(displayName, lat, lon);
                setState(() {
                  latCtrl.text = lat.toStringAsFixed(4);
                  lonCtrl.text = lon.toStringAsFixed(4);
                  tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
                });
                setGeoStatus('📍 $displayName');
              },
            );
          },
        )),
        const SizedBox(height: 16),
      ])),
    );
  }

  /// Show bottom sheet to pick a saved kundali profile
  void _showProfilePicker({
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required void Function(DateTime) onDobChanged,
    required void Function(int, int, String) onTimeChanged,
    required void Function(String) onGeoStatusChanged,
  }) async {
    final profiles = await StorageService.loadAll();
    if (profiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.l('noSavedProfiles')), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.person_search, color: kPurple1, size: 24),
                const SizedBox(width: 8),
                Text(AppLocale.l('selectSavedKundali'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple1)),
              ]),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: profiles.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: kBorder),
                itemBuilder: (_, i) {
                  final name = profiles.keys.elementAt(i);
                  final p = profiles[name]!;
                  final dateStr = p.date;
                  final timeStr = '${p.hour.toString().padLeft(2, "0")}:${p.minute.toString().padLeft(2, "0")} ${p.ampm}';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kPurple1.withOpacity(0.1),
                      child: Icon(Icons.person, color: kPurple1, size: 20),
                    ),
                    title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                    subtitle: Text('$dateStr  $timeStr  ${p.place}', style: TextStyle(fontSize: 11, color: kMuted)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 14, color: kMuted),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadProfileIntoFields(
                        profile: p, profileName: name,
                        nameCtrl: nameCtrl, placeCtrl: placeCtrl,
                        latCtrl: latCtrl, lonCtrl: lonCtrl, tzCtrl: tzCtrl,
                        onDobChanged: onDobChanged, onTimeChanged: onTimeChanged,
                        onGeoStatusChanged: onGeoStatusChanged,
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  void _loadProfileIntoFields({
    required Profile profile,
    required String profileName,
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required void Function(DateTime) onDobChanged,
    required void Function(int, int, String) onTimeChanged,
    required void Function(String) onGeoStatusChanged,
  }) {
    setState(() {
      nameCtrl.text = profileName;
      placeCtrl.text = profile.place;
      latCtrl.text = profile.lat.toStringAsFixed(4);
      lonCtrl.text = profile.lon.toStringAsFixed(4);
      final tz = profile.tzOffset;
      tzCtrl.text = '${tz >= 0 ? '+' : ''}$tz';

      // Parse date
      final parts = profile.date.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? 2000;
        final m = int.tryParse(parts[1]) ?? 1;
        final d = int.tryParse(parts[2]) ?? 1;
        onDobChanged(DateTime(y, m, d));
      }

      onTimeChanged(profile.hour, profile.minute, profile.ampm);
      onGeoStatusChanged('📍 ${profile.place}');
    });
  }

  /// Save a person's data as a profile with Client sync
  Future<void> _savePersonProfile({
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required DateTime dob,
    required int hour,
    required int minute,
    required String ampm,
  }) async {
    String name = nameCtrl.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.l('enterName')), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final lat = double.tryParse(latCtrl.text) ?? 14.98;
    final lon = double.tryParse(lonCtrl.text) ?? 74.73;
    final tz = double.tryParse(tzCtrl.text) ?? 5.5;
    final dateStr = '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';

    // Resolve or create Client
    await ClientService.loadAll();
    final resolvedClient = await ClientService.getOrCreateClient(name: name, phone: 'No Phone');
    String? cId = resolvedClient?.clientId;

    final p = Profile(
      name: name,
      date: dateStr,
      hour: hour, minute: minute, ampm: ampm,
      lat: lat, lon: lon, tzOffset: tz,
      place: placeCtrl.text,
      clientId: cId,
    );

    // Sync as FamilyMember
    if (cId != null && cId.isNotEmpty) {
      final member = FamilyMember(
        clientId: cId,
        memberName: name,
        relation: 'Self',
        dob: dateStr,
        birthTime: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm',
        birthPlace: placeCtrl.text,
        lat: lat, lon: lon,
        notes: '',
      );
      final members = ClientService.getMembersForClient(cId);
      if (!members.any((m) => m.memberName == name)) {
        await ClientService.addFamilyMember(member);
      } else {
        await ClientService.updateFamilyMember(member);
      }
    }

    await StorageService.save(p);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocale.l('savedSuccess')} - $name'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildPersonInput({
    required String title,
    required Color color,
    required TextEditingController nameCtrl,
    required TextEditingController placeCtrl,
    required TextEditingController latCtrl,
    required TextEditingController lonCtrl,
    required TextEditingController tzCtrl,
    required DateTime dob,
    required int hour,
    required int minute,
    required String ampm,
    required bool geoLoading,
    required String geoStatus,
    required void Function(DateTime) onDobChanged,
    required void Function(int, int, String) onTimeChanged,
    required void Function(bool) onGeoLoadingChanged,
    required void Function(String) onGeoStatusChanged,
    required VoidCallback onLoadSaved,
    required VoidCallback onSave,
  }) {
    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: SectionTitle(title, color: color)),
        TextButton.icon(
          onPressed: onLoadSaved,
          icon: Icon(Icons.folder_open, size: 14, color: color),
          label: Text(AppLocale.l('loadSaved'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            backgroundColor: color.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: onSave,
          icon: Icon(Icons.save, size: 14, color: Colors.green),
          label: Text(AppLocale.l('saveBtn'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            backgroundColor: Colors.green.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      TextField(
        controller: nameCtrl,
        style: TextStyle(color: kText),
        decoration: InputDecoration(labelText: AppLocale.l('name'), prefixIcon: Icon(Icons.person_outline, color: kMuted), isDense: true),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(context: context, initialDate: dob, firstDate: DateTime(1800), lastDate: DateTime(2100),
            builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: color)), child: child!));
          if (picked != null) onDobChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.calendar_today, color: kMuted, size: 18),
            const SizedBox(width: 8),
            Text('${dob.day.toString().padLeft(2, "0")}-${dob.month.toString().padLeft(2, "0")}-${dob.year}', style: TextStyle(fontSize: 13, color: kText)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(context: context,
            initialTime: TimeOfDay(hour: ampm == 'PM' && hour != 12 ? hour + 12 : (ampm == 'AM' && hour == 12 ? 0 : hour), minute: minute),
            builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: color)), child: child!));
          if (picked != null) {
            final h24 = picked.hour;
            onTimeChanged(h24 % 12 == 0 ? 12 : h24 % 12, picked.minute, h24 >= 12 ? 'PM' : 'AM');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: kCard, border: Border.all(color: kBorder), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.access_time, color: kMuted, size: 18),
            const SizedBox(width: 8),
            Text('${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")} $ampm', style: TextStyle(fontSize: 13, color: kText)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Autocomplete<String>(
        key: ValueKey(placeCtrl.text),
        optionsBuilder: (TextEditingValue v) {
          if (v.text.isEmpty) return offlinePlaces.keys.take(15);
          return offlinePlaces.keys.where((n) => n.toLowerCase().contains(v.text.toLowerCase()));
        },
        fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
          if (textCtrl.text.isEmpty && placeCtrl.text.isNotEmpty) textCtrl.text = placeCtrl.text;
          return TextField(
            controller: textCtrl, focusNode: focusNode, style: TextStyle(color: kText),
            decoration: InputDecoration(
              labelText: AppLocale.l('searchPlace'), prefixIcon: const Icon(Icons.search), isDense: true,
              suffixIcon: geoLoading
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(icon: Icon(Icons.my_location, color: kTeal, size: 18), onPressed: () {
                    placeCtrl.text = textCtrl.text;
                    _geocode(textCtrl.text, latCtrl, lonCtrl, tzCtrl, (v) => setState(() => onGeoLoadingChanged(v)), (v) => setState(() => onGeoStatusChanged(v)));
                  }),
            ),
            onSubmitted: (_) {
              placeCtrl.text = textCtrl.text;
              _geocode(textCtrl.text, latCtrl, lonCtrl, tzCtrl, (v) => setState(() => onGeoLoadingChanged(v)), (v) => setState(() => onGeoStatusChanged(v)));
            },
          );
        },
        onSelected: (String selection) async {
          if (offlinePlaces.containsKey(selection)) {
            final coords = offlinePlaces[selection]!;
            final autoTz = await getTimezoneForPlace(selection, coords[0], coords[1]);
            setState(() {
              placeCtrl.text = selection;
              latCtrl.text = coords[0].toStringAsFixed(4);
              lonCtrl.text = coords[1].toStringAsFixed(4);
              tzCtrl.text = '${autoTz >= 0 ? '+' : ''}$autoTz';
            });
          }
        },
        optionsViewBuilder: (context, onSelected, options) => Align(alignment: Alignment.topLeft, child: Material(elevation: 4.0, borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 64),
            child: ListView.builder(padding: EdgeInsets.zero, itemCount: options.length, shrinkWrap: true,
              itemBuilder: (context, i) {
                final o = options.elementAt(i);
                return ListTile(dense: true, leading: Icon(Icons.location_on, size: 16, color: color), title: Text(o, style: const TextStyle(fontSize: 12)), onTap: () => onSelected(o));
              }),
          ),
        )),
      ),
      if (geoStatus.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(geoStatus, style: TextStyle(fontSize: 11, color: kGreen))),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(flex: 4, child: TextField(controller: latCtrl, style: TextStyle(color: kText, fontSize: 12), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: AppLocale.l('lat'), isDense: true))),
        const SizedBox(width: 6),
        Expanded(flex: 4, child: TextField(controller: lonCtrl, style: TextStyle(color: kText, fontSize: 12), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: AppLocale.l('lon'), isDense: true))),
        const SizedBox(width: 6),
        Expanded(flex: 3, child: TextField(controller: tzCtrl, style: TextStyle(color: kText, fontSize: 12), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: AppLocale.l('tzOffset'), isDense: true))),
      ]),
    ]));
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }

  Widget _doshaChip(String label, bool hasDosha, {String? detail}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasDosha ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasDosha ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(hasDosha ? Icons.warning_amber : Icons.check_circle, color: hasDosha ? Colors.red : Colors.green, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasDosha ? Colors.red.shade800 : Colors.green.shade800)),
        if (detail != null) Text(' ($detail)', style: TextStyle(fontSize: 11, color: kMuted)),
      ]),
    );
  }

  Widget _tableRow2(List<String> cells, {bool header = false, Color? bg}) {
    return Container(
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: kBorder))),
      child: Row(children: cells.asMap().entries.map((e) => Expanded(
        flex: e.key == 0 ? 2 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: header ? FontWeight.w900 : FontWeight.w600, color: header ? kPurple2 : kText), textAlign: e.key == 0 ? TextAlign.left : TextAlign.center),
        ),
      )).toList()),
    );
  }

  Widget _buildResults() {
    if (_brideResult == null || _groomResult == null || _fullResult == null) return const SizedBox.shrink();
    final br = _brideResult!;
    final gr = _groomResult!;
    final fr = _fullResult!;

    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── INDIVIDUAL DETAILS ──
      _sectionHeader('$gName — ${AppLocale.l('chart')}', Icons.male, kTeal),
      _buildPersonSummary(gr, gName, _gDob, _gHour, _gMinute, _gAmpm, _gPlaceCtrl.text),
      _sectionHeader('$bName — ${AppLocale.l('chart')}', Icons.female, kOrange),
      _buildPersonSummary(br, bName, _bDob, _bHour, _bMinute, _bAmpm, _bPlaceCtrl.text),

      // ── KUJA DOSHA ──
      _sectionHeader(AppLocale.l('kujaDosha'), Icons.brightness_7, Colors.red.shade700),
      _buildKujaDoshaSection(fr),

      // ── PAPA DOSHA ──
      _sectionHeader(AppLocale.l('papaDosha'), Icons.shield, Colors.deepOrange),
      _buildPapaDoshaSection(fr),

      // ── GRAHA MAITRI ──
      _sectionHeader(AppLocale.l('grahaMaitriAmsha'), Icons.handshake, kPurple2),
      _buildGrahaMaitriSection(fr),

      // ── SHATHA ASHTAKA & DVIRDVADASHA ──
      _sectionHeader('${AppLocale.l('shathaAshtaka')} & ${AppLocale.l('dvirdvadasha')}', Icons.compare_arrows, Colors.indigo),
      _buildShathaAshtakaDvirdvadashaSection(fr),

      // ── ASHTA KOOTA ──
      _sectionHeader(AppLocale.l('matchResult'), Icons.stars, kPurple1),
      _buildAshtaKootaTable(fr['ashtaKoota']),

      const SizedBox(height: 32),
    ]);
  }

  Widget _buildPersonSummary(KundaliResult r, String name, DateTime dob, int hour, int minute, String ampm, String place) {
    final pan = r.panchang;
    final dateStr = '${dob.day.toString().padLeft(2, "0")}-${dob.month.toString().padLeft(2, "0")}-${dob.year}';
    final timeStr = '${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")} $ampm';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _kv(AppLocale.l('nameLabel'), name),
        _kv(AppLocale.l('placeLabel'), place),
        _kv(AppLocale.l('dateLabel'), dateStr),
        _kv(AppLocale.l('timeLabel'), timeStr),
        _kv(AppLocale.l('chandraNakshatra'), '${trAll(pan.nakshatra)} - ${AppLocale.l('padaLabel')} ${r.planets['ಚಂದ್ರ']?.pada ?? 1}'),
        _kv(AppLocale.l('chandraRashiLabel'), trAll(pan.chandraRashi)),
        _kv(AppLocale.l('dashaLord'), '${trAll(pan.dashaLord)} ${AppLocale.l('dashaBalance')}: ${pan.dashaBalance}'),
      ])),
      const SizedBox(height: 8),
      // Charts — horizontally swipeable
      SizedBox(
        height: MediaQuery.of(context).size.width * 0.75 + 30,
        child: _ChartSlider(result: r),
      ),
      const SizedBox(height: 12),
    ]);
  }

  Widget _kv(String key, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text('$key: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: kMuted)),
        Flexible(child: Text(val, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kText))),
      ]),
    );
  }

  Widget _buildKujaDoshaSection(Map<String, dynamic> fr) {
    final bk = fr['brideKujaDosha'] as Map<String, dynamic>;
    final gk = fr['groomKujaDosha'] as Map<String, dynamic>;
    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    Widget doshaRow(String label, Map<String, dynamic> d) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kText)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _doshaChip(AppLocale.l('lagna'), d['fromLagna'] > 0, detail: d['fromLagna'] > 0 ? '${d['fromLagna']}' : null),
          _doshaChip(AppLocale.l('chandraRashiLabel'), d['fromChandra'] > 0, detail: d['fromChandra'] > 0 ? '${d['fromChandra']}' : null),
          _doshaChip(AppLocale.l('planetShukra'), d['fromShukra'] > 0, detail: d['fromShukra'] > 0 ? '${d['fromShukra']}' : null),
        ]),
        const SizedBox(height: 10),
      ]);
    }

    final bothHave = bk['hasDosha'] == true && gk['hasDosha'] == true;
    final neitherHas = bk['hasDosha'] == false && gk['hasDosha'] == false;
    String verdict;
    Color vColor;
    if (bothHave || neitherHas) {
      verdict = bothHave ? 'ಇಬ್ಬರಿಗೂ ಕುಜ ದೋಷ ✅' : 'ಇಬ್ಬರಿಗೂ ಕುಜ ದೋಷ ಇಲ್ಲ ✅';
      vColor = Colors.green.shade700;
    } else {
      verdict = 'ಕುಜ ದೋಷ ಅಸಮಾನ ⚠️';
      vColor = Colors.red.shade700;
    }

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      doshaRow(gName, gk),
      const Divider(),
      doshaRow(bName, bk),
      const Divider(),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: vColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(bothHave || neitherHas ? Icons.check_circle : Icons.warning, color: vColor, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(verdict, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: vColor))),
        ]),
      ),
    ]));
  }

  Widget _buildPapaDoshaSection(Map<String, dynamic> fr) {
    final bp = fr['bridePapaDosha'] as Map<String, dynamic>;
    final gp = fr['groomPapaDosha'] as Map<String, dynamic>;
    final ps = fr['papaSamya'] as Map<String, dynamic>;
    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _tableRow2([AppLocale.l('papaDosha'), gName, bName], header: true, bg: kPurple2.withOpacity(0.08)),
      _tableRow2([AppLocale.l('lagna'), '${gp['fromLagna']}', '${bp['fromLagna']}']),
      _tableRow2([AppLocale.l('chandraRashiLabel'), '${gp['fromChandra']}', '${bp['fromChandra']}']),
      _tableRow2([AppLocale.l('planetShukra'), '${gp['fromShukra']}', '${bp['fromShukra']}']),
      _tableRow2([AppLocale.l('totalGuna'), '${gp['total']}', '${bp['total']}'], bg: kPurple1.withOpacity(0.05)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (ps['isSamya'] as bool) ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon((ps['isSamya'] as bool) ? Icons.check_circle : Icons.warning, color: (ps['isSamya'] as bool) ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(
            (ps['isSamya'] as bool) ? 'ಪಾಪ ಸಾಮ್ಯ ✅ (ವ್ಯತ್ಯಾಸ: ${ps['difference']})' : 'ಪಾಪ ಅಸಮಾನ ⚠️ (ವ್ಯತ್ಯಾಸ: ${ps['difference']})',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: (ps['isSamya'] as bool) ? Colors.green.shade800 : Colors.red.shade800),
          )),
        ]),
      ),
    ]));
  }

  Widget _buildGrahaMaitriSection(Map<String, dynamic> fr) {
    final gm = fr['grahaMaitri'] as Map<String, dynamic>;
    final rows = gm['rows'] as List<Map<String, dynamic>>;

    Color maitriColor(String m) {
      if (m == 'ಮಿತ್ರ') return Colors.green;
      if (m == 'ಶತ್ರು') return Colors.red;
      return Colors.orange;
    }

    final bName = _bNameCtrl.text.isNotEmpty ? _bNameCtrl.text : AppLocale.l('brideDetails');
    final gName = _gNameCtrl.text.isNotEmpty ? _gNameCtrl.text : AppLocale.l('groomDetails');

    return AppCard(padding: EdgeInsets.zero, child: Column(children: [
      _tableRow2(['', bName, gName, 'ಫಲ'], header: true, bg: kPurple2.withOpacity(0.08)),
      ...rows.map((r) => Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
        child: Row(children: [
          Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(trAll(r['label']), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)))),
          Expanded(child: Text(trAll(r['brideLordName']), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted))),
          Expanded(child: Text(trAll(r['groomLordName']), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted))),
          Expanded(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(color: maitriColor(r['maitri']).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(trAll(r['maitri']), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: maitriColor(r['maitri']))),
          )),
        ]),
      )),
    ]));
  }

  Widget _buildShathaAshtakaDvirdvadashaSection(Map<String, dynamic> fr) {
    final sa = fr['shathaAshtaka'] as Map<String, dynamic>;
    final dv = fr['dvirdvadasha'] as Map<String, dynamic>;

    Widget subRow(String label, Map<String, dynamic> d) {
      final has = d['hasDosha'] as bool;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [
          Icon(has ? Icons.close : Icons.check, color: has ? Colors.red : Colors.green, size: 14),
          const SizedBox(width: 4),
          Text('$label: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
          Text(has ? 'ದೋಷ ಇದೆ' : 'ದೋಷ ಇಲ್ಲ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: has ? Colors.red.shade700 : Colors.green.shade700)),
          Text(' (${d['brideFromGroom']}/${d['groomFromBride']})', style: TextStyle(fontSize: 10, color: kMuted)),
        ]),
      );
    }

    Widget doshaCard(String title, Map<String, dynamic> d) {
      final has = d['hasDosha'] as bool;
      final fromChandra = d['fromChandra'] as Map<String, dynamic>;
      final fromLagna = d['fromLagna'] as Map<String, dynamic>;
      return Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: has ? Colors.red.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: has ? Colors.red.shade200 : Colors.green.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Icon(has ? Icons.warning_amber : Icons.check_circle, color: has ? Colors.red : Colors.green, size: 24)),
          const SizedBox(height: 4),
          Center(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kText))),
          const SizedBox(height: 6),
          subRow(AppLocale.l('chandraRashiLabel'), fromChandra),
          subRow(AppLocale.l('lagna'), fromLagna),
        ]),
      ));
    }

    return Row(children: [
      doshaCard(AppLocale.l('shathaAshtaka'), sa),
      const SizedBox(width: 10),
      doshaCard(AppLocale.l('dvirdvadasha'), dv),
    ]);
  }

  Widget _buildAshtaKootaTable(Map<String, dynamic> result) {
    final total = result['total'] as double;
    String verdict;
    Color verdictColor;
    if (total <= 18) { verdict = AppLocale.l('matchPoor'); verdictColor = Colors.red.shade700; }
    else if (total <= 25) { verdict = AppLocale.l('matchMedium'); verdictColor = Colors.orange.shade700; }
    else { verdict = AppLocale.l('matchGood'); verdictColor = Colors.green.shade700; }

    TableRow row(String name, double pts, int max) {
      return TableRow(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
        children: [
          Padding(padding: const EdgeInsets.all(10), child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Padding(padding: const EdgeInsets.all(10), child: Text(pts.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          Padding(padding: const EdgeInsets.all(10), child: Text(max.toString(), textAlign: TextAlign.center, style: TextStyle(color: kMuted, fontSize: 13))),
        ],
      );
    }

    return AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Table(columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)}, children: [
        TableRow(
          decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('koota'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('padeGuna'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('garishThaGuna'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
        row(AppLocale.l('varna'), result['varna'], 1),
        row(AppLocale.l('vashya'), result['vashya'], 2),
        row(AppLocale.l('tara'), result['tara'], 3),
        row(AppLocale.l('yoni'), result['yoni'], 4),
        row(AppLocale.l('grahaMaitri'), result['graha'], 5),
        row(AppLocale.l('gana'), result['gana'], 6),
        row(AppLocale.l('bhakoot'), result['bhakoot'], 7),
        row(AppLocale.l('naadi'), result['nadi'], 8),
        TableRow(
          decoration: BoxDecoration(color: kPurple1.withOpacity(0.05)),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text(AppLocale.l('totalGuna'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Padding(padding: const EdgeInsets.all(10), child: Text(total.toStringAsFixed(1), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kPurple1))),
            Padding(padding: const EdgeInsets.all(10), child: Text('36', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kMuted))),
          ],
        ),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: verdictColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: verdictColor.withOpacity(0.3))),
        child: Column(children: [
          Text('${AppLocale.l('result')}:', style: TextStyle(fontSize: 13, color: verdictColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(verdict, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: verdictColor)),
        ]),
      ),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Groom input
        _buildPersonInput(
          title: AppLocale.l('groomDetails'), color: kTeal,
          nameCtrl: _gNameCtrl, placeCtrl: _gPlaceCtrl, latCtrl: _gLatCtrl, lonCtrl: _gLonCtrl, tzCtrl: _gTzCtrl,
          dob: _gDob, hour: _gHour, minute: _gMinute, ampm: _gAmpm,
          geoLoading: _gGeoLoading, geoStatus: _gGeoStatus,
          onDobChanged: (d) => setState(() => _gDob = d),
          onTimeChanged: (h, m, a) => setState(() { _gHour = h; _gMinute = m; _gAmpm = a; }),
          onGeoLoadingChanged: (v) => _gGeoLoading = v,
          onGeoStatusChanged: (v) => _gGeoStatus = v,
          onLoadSaved: () => _showProfilePicker(
            nameCtrl: _gNameCtrl, placeCtrl: _gPlaceCtrl,
            latCtrl: _gLatCtrl, lonCtrl: _gLonCtrl, tzCtrl: _gTzCtrl,
            onDobChanged: (d) => setState(() => _gDob = d),
            onTimeChanged: (h, m, a) => setState(() { _gHour = h; _gMinute = m; _gAmpm = a; }),
            onGeoStatusChanged: (v) => setState(() => _gGeoStatus = v),
          ),
          onSave: () => _savePersonProfile(
            nameCtrl: _gNameCtrl, placeCtrl: _gPlaceCtrl,
            latCtrl: _gLatCtrl, lonCtrl: _gLonCtrl, tzCtrl: _gTzCtrl,
            dob: _gDob, hour: _gHour, minute: _gMinute, ampm: _gAmpm,
          ),
        ),
        const SizedBox(height: 12),
        // Bride input
        _buildPersonInput(
          title: AppLocale.l('brideDetails'), color: kOrange,
          nameCtrl: _bNameCtrl, placeCtrl: _bPlaceCtrl, latCtrl: _bLatCtrl, lonCtrl: _bLonCtrl, tzCtrl: _bTzCtrl,
          dob: _bDob, hour: _bHour, minute: _bMinute, ampm: _bAmpm,
          geoLoading: _bGeoLoading, geoStatus: _bGeoStatus,
          onDobChanged: (d) => setState(() => _bDob = d),
          onTimeChanged: (h, m, a) => setState(() { _bHour = h; _bMinute = m; _bAmpm = a; }),
          onGeoLoadingChanged: (v) => _bGeoLoading = v,
          onGeoStatusChanged: (v) => _bGeoStatus = v,
          onLoadSaved: () => _showProfilePicker(
            nameCtrl: _bNameCtrl, placeCtrl: _bPlaceCtrl,
            latCtrl: _bLatCtrl, lonCtrl: _bLonCtrl, tzCtrl: _bTzCtrl,
            onDobChanged: (d) => setState(() => _bDob = d),
            onTimeChanged: (h, m, a) => setState(() { _bHour = h; _bMinute = m; _bAmpm = a; }),
            onGeoStatusChanged: (v) => setState(() => _bGeoStatus = v),
          ),
          onSave: () => _savePersonProfile(
            nameCtrl: _bNameCtrl, placeCtrl: _bPlaceCtrl,
            latCtrl: _bLatCtrl, lonCtrl: _bLonCtrl, tzCtrl: _bTzCtrl,
            dob: _bDob, hour: _bHour, minute: _bMinute, ampm: _bAmpm,
          ),
        ),
        const SizedBox(height: 16),
        // Calculate button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _calculate,
            icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.calculate),
            label: Text(_loading ? '${AppLocale.l('calcInProgress')}' : AppLocale.l('checkMatch'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurple1, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildResults(),
      ]),
    );
  }
}

/// Horizontally swipeable chart slider with dot indicators
class _ChartSlider extends StatefulWidget {
  final KundaliResult result;
  const _ChartSlider({required this.result});

  @override
  State<_ChartSlider> createState() => _ChartSliderState();
}

class _ChartSliderState extends State<_ChartSlider> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final labels = [
      AppLocale.l('rashiKundali'),
      AppLocale.l('navamshaKundali'),
      AppLocale.l('bhavaKundali'),
    ];
    return Column(children: [
      Expanded(
        child: PageView(
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 1, isBhava: false, showSphutas: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 9, isBhava: false, showSphutas: false),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: KundaliChart(result: widget.result, varga: 1, isBhava: true, showSphutas: false),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      // Label + dots
      Text(labels[_page], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kPurple2)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _page == i ? 18 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: _page == i ? kPurple2 : kBorder,
          borderRadius: BorderRadius.circular(4),
        ),
      ))),
    ]);
  }
}
