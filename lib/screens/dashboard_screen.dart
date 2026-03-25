import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../services/google_auth_service.dart';
import '../services/sheets_service.dart';
import '../services/docs_service.dart';
import '../services/calendar_service.dart';
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
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _notes = '';
  final _newNoteController = TextEditingController();
  Map<String, int> _aroodhas = {};
  int? _janmaNakshatraIdx;
  int? _dinaNakshatraIdx;
  String? _bhavaPlanet; // planet selected for bhava recalculation

  // Multi-person support
  final List<_PersonEntry> _extraPersons = [];

  bool _syncing = false;



  static List<String> get _tabs => AppLocale.isHindi
    ? ['कुंडली', 'स्फुट', 'आरूढ', 'दशा', 'पंचांग', 'भाव', 'षड्बल', 'अष्टक', 'टिप्पणी']
    : ['ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಆರೂಢ', 'ದಶ', 'ಪಂಚಾಂಗ', 'ಭಾವ', 'ಷಡ್ಬಲ', 'ಅಷ್ಟಕ', 'ಟಿಪ್ಪಣಿ'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _notes = widget.initialNotes;
    _aroodhas = Map.from(widget.initialAroodhas);
    _janmaNakshatraIdx = widget.initialJanmaNakshatraIdx;


    final panchangNakName = widget.result.panchang.nakshatra.split(' ')[0];
    int panchangNakIdx = knNak.indexWhere((n) => panchangNakName.startsWith(n));
    _dinaNakshatraIdx = panchangNakIdx != -1 ? panchangNakIdx : 0;

    _loadJanmaNakshatra();


  }

  /// Show dialog to add a person from saved profiles
  void _showAddPersonDialog() async {
    final profiles = await StorageService.loadAll();
    if (!mounted) return;

    // Filter out the primary person
    final otherProfiles = profiles.values
        .where((p) => p.name != widget.name)
        .where((p) => !_extraPersons.any((ep) => ep.name == p.name))
        .toList();

    if (otherProfiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ಬೇರೆ ಪ್ರೊಫೈಲ್‌ಗಳಿಲ್ಲ — ಮೊದಲು ಹೊಸ ಜಾತಕ ಉಳಿಸಿ')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        title: Text('ವ್ಯಕ್ತಿ ಸೇರಿಸಿ', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
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
                onTap: () async {
                  Navigator.pop(ctx);
                  // Compute kundali for this person
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('⏳ ${p.name} ಕುಂಡಲಿ ಲೆಕ್ಕಿಸಲಾಗುತ್ತಿದೆ...')),
                  );
                  try {
                    final dateParts = p.date.split('-');
                    final dob = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2]));
                    final result = await Calculator.compute(
                      dob: dob,
                      hour: p.hour,
                      minute: p.minute,
                      ampm: p.ampm,
                      lat: p.lat,
                      lon: p.lon,
                      tzOffset: p.tzOffset,
                    );
                    if (mounted) {
                      setState(() {
                        _extraPersons.add(_PersonEntry(
                          name: p.name,
                          result: result,
                          dob: dob,
                          hour: p.hour,
                          minute: p.minute,
                          ampm: p.ampm,
                          lat: p.lat,
                          lon: p.lon,
                          place: p.place,
                          notes: p.notes,
                        ));
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('❌ ಕುಂಡಲಿ ಲೆಕ್ಕ ವಿಫಲ: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ಮುಚ್ಚಿ', style: TextStyle(color: kMuted))),
        ],
      ),
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
      buf.writeln('ಜಾತಕ ವಿವರ,,');
      buf.writeln('ಹೆಸರು,$name,');
      buf.writeln('ಸ್ಥಳ,${widget.place},');
      buf.writeln('ದಿನಾಂಕ,$dateStr,');
      buf.writeln('ಸಮಯ,$timeStr,');
      buf.writeln('ಅಕ್ಷಾಂಶ,${widget.lat},');
      buf.writeln('ರೇಖಾಂಶ,${widget.lon},');
      buf.writeln(',');

      // Panchanga
      buf.writeln('ಪಂಚಾಂಗ,,');
      buf.writeln('ಸಂವತ್ಸರ,${pan.samvatsara},');
      buf.writeln('ವಾರ,${pan.vara},');
      buf.writeln('ತಿಥಿ,${pan.tithi},');
      buf.writeln('ನಕ್ಷತ್ರ,${pan.nakshatra},');
      buf.writeln('ಯೋಗ,${pan.yoga},');
      buf.writeln('ಕರಣ,${pan.karana},');
      buf.writeln('ಚಂದ್ರ ರಾಶಿ,${pan.chandraRashi},');
      buf.writeln('ಚಂದ್ರ ಮಾಸ,${pan.chandraMasa},');
      buf.writeln('ಸೌರ ಮಾಸ,${pan.souraMasa},');
      buf.writeln('ಸೂರ್ಯೋದಯ,${pan.sunrise},');
      buf.writeln('ಸೂರ್ಯಾಸ್ತ,${pan.sunset},');
      buf.writeln('ದಶಾ ನಾಥ,${pan.dashaLord},');
      buf.writeln('ದಶಾ ಉಳಿಕೆ,${pan.dashaBalance},');
      buf.writeln(',');

      // Graha Sphuta
      buf.writeln('ಗ್ರಹ ಸ್ಫುಟ,,,');
      buf.writeln('ಗ್ರಹ,ರಾಶಿ,ಸ್ಫುಟ,ನಕ್ಷತ್ರ - ಪಾದ');
      for (final p in planetOrder) {
        final info = r.planets[p];
        if (info == null) continue;
        final ri = (info.longitude / 30).floor() % 12;
        buf.writeln('$p,${knRashi[ri]},${formatDeg(info.longitude)},${info.nakshatra} - ${info.pada}');
      }
      buf.writeln(',');

      // Upagraha Sphuta
      buf.writeln('ಉಪಗ್ರಹ ಸ್ಫುಟ,,,');
      buf.writeln('ಉಪಗ್ರಹ,ರಾಶಿ,ಅಂಶ,ನಕ್ಷತ್ರ');
      for (final sp in sphutas16Order) {
        final deg = r.advSphutas[sp];
        if (deg == null) continue;
        final ri = (deg / 30).floor() % 12;
        final nakIdx = (deg / 13.333333).floor() % 27;
        final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
        buf.writeln('$sp,${knRashi[ri]},${formatDeg(deg)},${knNak[nakIdx]}-$pada');
      }

      // Save CSV to temp and share
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ವೆಬ್‌ನಲ್ಲಿ ಹಂಚಿಕೊಳ್ಳಲು ಸಾಧ್ಯವಿಲ್ಲ.')));
        }
        return;
      }

      final fileName = '${name.replaceAll(' ', '_')}_$dateStr.csv';
      await ExportService.shareCSV(
        csvContent: buf.toString(),
        fileName: fileName,
        shareText: '$name ಜಾತಕ - $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ದೋಷ: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
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
                      tooltip: 'ವ್ಯಕ್ತಿ ಸೇರಿಸಿ',
                      onPressed: _showAddPersonDialog,
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: kTeal),
                      tooltip: 'Share CSV',
                      onPressed: _exportAndShareCSV,
                    ),
                    IconButton(
                      icon: _syncing
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kTeal))
                        : Icon(Icons.save, color: kText),
                      tooltip: 'Save & Sync',
                      onPressed: _syncing ? null : () async {
                            widget.onSave(_notes, _aroodhas, _janmaNakshatraIdx, isNew: false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ಉಳಿಸಲಾಗಿದೆ!')));

                            if (GoogleAuthService.isSignedIn) {
                              setState(() => _syncing = true);
                              final profile = Profile(
                                name: widget.name,
                                date: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.day.toString().padLeft(2,'0')}',
                                hour: widget.hour,
                                minute: widget.minute,
                                ampm: widget.ampm,
                                lat: widget.lat,
                                lon: widget.lon,
                                place: widget.place,
                                notes: _notes,
                                aroodhas: _aroodhas,
                                janmaNakshatraIdx: _janmaNakshatraIdx,
                              );
                              final sheetOk = await SheetsService.syncProfile(profile, isNew: false);
                              final docOk = await DocsService.syncNotes(widget.name, _notes);
                              if (mounted) {
                                setState(() => _syncing = false);
                                final msg = (sheetOk && docOk)
                                  ? 'Google Sheets ಮತ್ತು Docs ಗೆ ಸಿಂಕ್ ಆಗಿದೆ!'
                                  : 'ಸಿಂಕ್ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                  _buildKundaliTab(),
                  _buildSphutas(),
                  _buildAroodhaTab(),
                  _buildDashaTab(),
                  _buildPanchangTab(),
                  _buildBhavaTab(),
                  _buildShadbalaTab(),
                  _buildAshtakaTab(),
                  _buildNotesTab(),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 1: KUNDALI (All vargas stacked vertically)
  // ─────────────────────────────────────────────
  Widget _buildKundaliTab() {
    final charts = [
      {'label': 'ರಾಶಿ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': false},
      {'label': 'ನವಾಂಶ ಕುಂಡಲಿ', 'varga': 9, 'isBhava': false},
      {'label': 'ಭಾವ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': true},
      {'label': 'ಹೋರಾ ಕುಂಡಲಿ', 'varga': 2, 'isBhava': false},
      {'label': 'ದ್ರೇಕ್ಕಾಣ ಕುಂಡಲಿ', 'varga': 3, 'isBhava': false},
      {'label': 'ದ್ವಾದಶಾಂಶ ಕುಂಡಲಿ', 'varga': 12, 'isBhava': false},
      {'label': 'ತ್ರಿಂಶಾಂಶ ಕುಂಡಲಿ', 'varga': 30, 'isBhava': false},
    ];

    // All persons: primary + extras
    final allPersons = <Map<String, dynamic>>[
      {'name': widget.name, 'result': widget.result, 'isPrimary': true},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'isPrimary': false}),
    ];

    final chartSize = MediaQuery.of(context).size.width * 0.85;

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
                        child: Text(personName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isPrimary ? kPurple2 : kTeal)),
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
                  height: chartSize + 30,
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
                              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: kPurple2)),
                              const SizedBox(height: 4),
                              Expanded(
                                child: KundaliChart(
                                  result: personResult,
                                  varga: chart['varga'] as int,
                                  isBhava: isBhavaChart,
                                  showSphutas: false,
                                  centerLabel: label,
                                  onPlanetTap: isPrimary ? _showPlanetDetail : null,
                                  selectedPlanet: (isPrimary && isBhavaChart) ? _bhavaPlanet : null,
                                  onPlanetLongPress: (isPrimary && isBhavaChart) ? (pName) {
                                    setState(() => _bhavaPlanet = _bhavaPlanet == pName ? null : pName);
                                  } : null,
                                  bhavaFromPlanet: (isPrimary && isBhavaChart) ? _bhavaPlanet : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
              label: Text('ವ್ಯಕ್ತಿ ಸೇರಿಸಿ', style: TextStyle(color: kPurple2, fontWeight: FontWeight.w800)),
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
      {'name': widget.name, 'result': widget.result},
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
              Text('ಉಪಗ್ರಹ ಸ್ಫುಟ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _tableHeader(['ಉಪಗ್ರಹ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ']),
                    ...sphutas16Order.map((sp) {
                      final deg = personResult.advSphutas[sp];
                      if (deg == null) return const SizedBox.shrink();
                      final ri = (deg / 30).floor() % 12;
                      final nakIdx = (deg / 13.333333).floor() % 27;
                      final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                      return _tableRow([sp, knRashi[ri], formatDeg(deg), '${knNak[nakIdx]}-$pada'],
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
  Widget _buildAroodhaTab() {
    String _selAro = 'ಆರೂಢ';
    int _selRashiIdx = 0;
    return StatefulBuilder(builder: (ctx, setS) {
      return SingleChildScrollView(
        child: Column(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle('ಆರೂಢ ಚಕ್ರ'),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selAro,
                        items: ['ಆರೂಢ','ಉದಯ','ಲಗ್ನಾಂಶ','ಛತ್ರ','ಸ್ಪೃಷ್ಟಾಂಗ','ಚಂದ್ರ','ತಾಂಬೂಲ']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selAro = v!),
                        decoration: const InputDecoration(labelText: 'ಆರೂಢ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selRashiIdx,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i, child: Text(knRashi[i], style: TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selRashiIdx = v!),
                        decoration: const InputDecoration(labelText: 'ರಾಶಿ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setS(() => _aroodhas[_selAro] = _selRashiIdx),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10)),
                      child: Text('ಸೇರಿಸಿ', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  if (_aroodhas.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setS(() => _aroodhas.clear()),
                      child: Text('ತೆರವುಗೊಳಿಸಿ', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KundaliChart(
                result: widget.result,
                varga: 1,
                isBhava: false,
                showSphutas: false,
                aroodhas: _aroodhas,
                centerLabel: 'ಆರೂಢ\nಚಕ್ರ',
                onPlanetTap: _showPlanetDetail,
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
      {'name': widget.name, 'result': widget.result},
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
                  'ಶಿಷ್ಟ ದಶೆ: ${pan.dashaLord}  ಉಳಿಕೆ: ${pan.dashaBalance}',
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
      {'name': widget.name, 'result': widget.result, 'dob': widget.dob, 'hour': widget.hour, 'minute': widget.minute, 'ampm': widget.ampm, 'place': widget.place},
      ..._extraPersons.map((p) => {'name': p.name, 'result': p.result, 'dob': p.dob, 'hour': p.hour, 'minute': p.minute, 'ampm': p.ampm, 'place': p.place}),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: allPersons.map((person) {
          final r = person['result'] as KundaliResult;
          final pan = r.panchang;
          final pName = person['name'] as String;
          final dob = person['dob'] as DateTime;
          final dateStr = '${dob.day.toString().padLeft(2,"0")}-${dob.month.toString().padLeft(2,"0")}-${dob.year}';
          final timeStr = '${person["hour"]}:${(person["minute"] as int).toString().padLeft(2,"0")} ${person["ampm"]}';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (allPersons.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(pName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (pName.isNotEmpty) _kv('ಹೆಸರು', pName),
                _kv('ಸ್ಥಳ', person['place'] as String),
                _kv('ದಿನಾಂಕ', dateStr),
                _kv('ಸಮಯ', timeStr),
              ])),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  _tableRow(['ಸಂವತ್ಸರ', pan.samvatsara]),
                  _tableRow(['ವಾರ', pan.vara]),
                  _tableRow(['ತಿಥಿ', pan.tithi]),
                  _tableRow(['ಚಂದ್ರ ನಕ್ಷತ್ರ', pan.nakshatra]),
                  _tableRow(['ಯೋಗ', pan.yoga]),
                  _tableRow(['ಕರಣ', pan.karana]),
                  _tableRow(['ಚಂದ್ರ ರಾಶಿ', pan.chandraRashi]),
                  _tableRow(['ಚಂದ್ರ ಮಾಸ', pan.chandraMasa]),
                  _tableRow(['ಸೂರ್ಯ ನಕ್ಷತ್ರ', '${pan.suryaNakshatra} - ಪಾದ ${pan.suryaPada}']),
                  _tableRow(['ಸೌರ ಮಾಸ', pan.souraMasa]),
                  _tableRow(['ಸೌರ ಮಾಸ ಗತ ದಿನ', pan.souraMasaGataDina]),
                  _tableRow(['ಸೂರ್ಯೋದಯ', pan.sunrise]),
                  _tableRow(['ಸೂರ್ಯಾಸ್ತ', pan.sunset]),
                  _tableRow(['ಉದಯಾದಿ ಘಟಿ', pan.udayadiGhati]),
                  _tableRow(['ಗತ ಘಟಿ', pan.gataGhati]),
                  _tableRow(['ಪರಮ ಘಟಿ', pan.paramaGhati]),
                  _tableRow(['ಶೇಷ ಘಟಿ', pan.shesha]),
                  _tableRow(['ವಿಷ ಪ್ರಘಟಿ', pan.vishaPraghati]),
                  _tableRow(['ಅಮೃತ ಪ್ರಘಟಿ', pan.amrutaPraghati]),
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
  // TAB 7: BHAVA
  // ─────────────────────────────────────────────
  Widget _buildBhavaTab() {
    final lagnaLong = widget.result.planets['ಲಗ್ನ']?.longitude ?? 0;

    // Planet selector list
    final selectablePlanets = planetOrder.where((p) => p != 'ಲಗ್ನ' && p != 'ಮಾಂದಿ').toList();

    // Calculate shifted bhava madhyas
    List<double> getMadhyas(String? planet) {
      if (planet == null || !widget.result.planets.containsKey(planet)) {
        return widget.result.bhavas;
      }
      final pDeg = widget.result.planets[planet]!.longitude;
      final offset = (pDeg - lagnaLong + 360.0) % 360.0;
      return List.generate(12, (i) => (widget.result.bhavas[i] + offset) % 360.0);
    }

    final currentMadhyas = getMadhyas(_bhavaPlanet);
    final title = _bhavaPlanet != null
        ? 'ಭಾವ ಮಧ್ಯ ಸ್ಫುಟ (${_bhavaPlanet} ಆಧಾರ)'
        : 'ಭಾವ ಮಧ್ಯ ಸ್ಫುಟ (ಲಗ್ನ)';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Planet selector
          Text('ಗ್ರಹ ಆಧಾರ ಭಾವ', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // Lagna chip
              GestureDetector(
                onTap: () => setState(() => _bhavaPlanet = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _bhavaPlanet == null ? kTeal : kCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _bhavaPlanet == null ? kTeal : kBorder),
                  ),
                  child: Text('ಲಗ್ನ', style: TextStyle(
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
                    child: Text(p, style: TextStyle(
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

          // Bhava Madhya Sphuta table
          Text(title, style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15,
            color: _bhavaPlanet != null ? kTeal : kPurple2)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(['ಭಾವ', 'ಮಧ್ಯ ಸ್ಫುಟ', 'ರಾಶಿ']),
                ...List.generate(12, (i) {
                  final deg = currentMadhyas[i];
                  return _tableRow(
                    ['${i+1}', formatDeg(deg), knRashi[(deg/30).floor() % 12]],
                    bold0: true,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
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
      {'name': widget.name, 'result': widget.result},
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
    return ShadbalaWidget(
      key: UniqueKey(),
      shadbala: widget.result.shadbala,
    );
  }



  // ─────────────────────────────────────────────
  // TAB 10: NOTES
  // ─────────────────────────────────────────────
  Widget _buildNotesTab() {
    // For multi-person: show primary person's notes section
    // Extra persons' notes are shown below
    final entries = _parseNoteEntries(_notes);

    // Build formatted text for share/print
    String _buildShareText() {
      final clientId = widget.extraInfo['clientId'] ?? '';
      final dobStr = '${widget.dob.day.toString().padLeft(2, '0')}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.year}';
      final timeStr = '${widget.hour.toString().padLeft(2, '0')}:${widget.minute.toString().padLeft(2, '0')} ${widget.ampm}';

      final buf = StringBuffer();
      buf.writeln('═══════════════════════════');
      buf.writeln('   ✨ ಭಾರತೀಯಮ್ ✨');
      buf.writeln('═══════════════════════════');
      buf.writeln();
      buf.writeln('👤 ಹೆಸರು: ${widget.name}');
      if (clientId.isNotEmpty) buf.writeln('🆔 ಗ್ರಾಹಕ ID: $clientId');
      buf.writeln('📅 ಜನ್ಮ ದಿನಾಂಕ: $dobStr');
      buf.writeln('⏰ ಜನ್ಮ ಸಮಯ: $timeStr');
      buf.writeln('📍 ಜನ್ಮ ಸ್ಥಳ: ${widget.place}');
      buf.writeln('🌐 ಅಕ್ಷಾಂಶ/ರೇಖಾಂಶ: ${widget.lat.toStringAsFixed(4)}, ${widget.lon.toStringAsFixed(4)}');
      buf.writeln();
      buf.writeln('───────────────────────────');
      buf.writeln('   📝 ಟಿಪ್ಪಣಿಗಳು');
      buf.writeln('───────────────────────────');
      buf.writeln();
      if (entries.isEmpty) {
        buf.writeln('ಯಾವುದೇ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ');
      } else {
        for (int i = 0; i < entries.length; i++) {
          buf.writeln('🕐 ${entries[i]['date']}');
          buf.writeln('   ${entries[i]['text']}');
          if (i < entries.length - 1) buf.writeln();
        }
      }
      buf.writeln();
      buf.writeln('═══════════════════════════');
      return buf.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons row 1: Google Docs + Appointment
          Row(
            children: [
              if (GoogleAuthService.isSignedIn) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await DocsService.openDoc(widget.name);
                      if (!ok && mounted) {
                        await DocsService.syncNotes(widget.name, _notes);
                        await DocsService.openDoc(widget.name);
                      }
                    },
                    icon: Icon(Icons.description, size: 18),
                    label: Text('Google Docs', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPurple2,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAppointmentDialog(),
                    icon: Icon(Icons.event, size: 18),
                    label: Text('ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ] else
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBorder.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.info_outline, size: 16, color: kMuted),
                      const SizedBox(width: 8),
                      Expanded(child: Text('ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ Google Sign In ಮಾಡಿ Docs & Calendar ಬಳಸಿ', style: TextStyle(fontSize: 12, color: kMuted))),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Action buttons row 2: Share + Print
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = _buildShareText();
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ನಕಲಿಸಲಾಗಿದೆ! ✅')),
                    );
                    // Also try to open WhatsApp share
                    final encoded = Uri.encodeComponent(text);
                    launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
                  },
                  icon: Icon(Icons.share, size: 18),
                  label: Text('ಹಂಚಿಕೊಳ್ಳಿ', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = _buildShareText();
                    _showPrintPreview(text);
                  },
                  icon: Icon(Icons.print, size: 18),
                  label: Text('ಪ್ರಿಂಟ್', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Client info header card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPurple2.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPurple2.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: kPurple2),
                    const SizedBox(width: 6),
                    Expanded(child: Text(widget.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple2))),
                    if (widget.extraInfo['clientId'] != null && widget.extraInfo['clientId']!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(widget.extraInfo['clientId']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: kTeal)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '📅 ${widget.dob.day.toString().padLeft(2, '0')}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.year} | ⏰ ${widget.hour.toString().padLeft(2, '0')}:${widget.minute.toString().padLeft(2, '0')} ${widget.ampm} | 📍 ${widget.place}'
                  '${(widget.extraInfo['clientId'] ?? '').isNotEmpty ? ' | 🆔 ${widget.extraInfo['clientId']}' : ''}',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // New note input — bigger
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _newNoteController,
                  maxLines: 20,
                  minLines: 10,
                  decoration: InputDecoration(
                    hintText: 'ಹೊಸ ಟಿಪ್ಪಣಿ ಸೇರಿಸಿ...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kBorder),
                    ),
                    fillColor: kCard,
                    filled: true,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  style: TextStyle(fontSize: 14, height: 1.5, color: kText),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final text = _newNoteController.text.trim();
                  if (text.isEmpty) return;
                  final now = DateTime.now();
                  final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                  final entry = '[$stamp] $text';
                  setState(() {
                    _notes = _notes.isEmpty ? entry : '$entry\n---\n$_notes';
                    _newNoteController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kTeal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Section title
          Text('📋 ಟಿಪ್ಪಣಿ ಇತಿಹಾಸ (${entries.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText)),
          const SizedBox(height: 8),

          // Notes history — inline (parent handles scroll)
          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    Icon(Icons.note_alt_outlined, size: 48, color: kMuted.withOpacity(0.3)),
                    const SizedBox(height: 8),
                    Text('ಇನ್ನೂ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ', style: TextStyle(color: kMuted)),
                  ],
                ),
              ),
            )
          else
            ...entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
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
                        Icon(Icons.access_time, size: 14, color: kTeal),
                        const SizedBox(width: 6),
                        Text(e['date'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTeal)),
                        const Spacer(),
                        // Edit button
                        GestureDetector(
                          onTap: () {
                            // Pre-fill the text input with this note's text for editing
                            _newNoteController.text = e['text'] ?? '';
                            // Remove this entry from notes
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              _notes = updatedEntries.map((en) => '[${en['date']}] ${en['text']}').join('\n---\n');
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✏️ ಟಿಪ್ಪಣಿ ಸಂಪಾದನೆಗೆ ಲೋಡ್ ಆಗಿದೆ'), duration: Duration(seconds: 2)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit, size: 18, color: kPurple2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Delete button
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: kBg,
                                title: Text('ಟಿಪ್ಪಣಿ ಅಳಿಸಿ?', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
                                content: Text('ಈ ಟಿಪ್ಪಣಿಯನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಲಾಗುವುದು.', style: TextStyle(color: kMuted)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ಬೇಡ', style: TextStyle(color: kMuted))),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      final updatedEntries = List<Map<String, String>>.from(entries);
                                      updatedEntries.removeAt(i);
                                      setState(() {
                                        _notes = updatedEntries.map((en) => '[${en['date']}] ${en['text']}').join('\n---\n');
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('🗑️ ಟಿಪ್ಪಣಿ ಅಳಿಸಲಾಗಿದೆ'), backgroundColor: Colors.red),
                                      );
                                    },
                                    child: Text('ಅಳಿಸಿ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('#${entries.length - i}', style: TextStyle(fontSize: 11, color: kMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(e['text'] ?? '', style: TextStyle(fontSize: 14, height: 1.4, color: kText)),
                  ],
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
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
          Text('ಪ್ರಿಂಟ್ ಪ್ರಿವ್ಯೂ', style: TextStyle(color: kText)),
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
            child: Text('ಮುಚ್ಚಿ', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ನಕಲಿಸಲಾಗಿದೆ — ಯಾವುದೇ ಟೆಕ್ಸ್ಟ್ ಎಡಿಟರ್‌ನಲ್ಲಿ ಪೇಸ್ಟ್ ಮಾಡಿ ಪ್ರಿಂಟ್ ಮಾಡಿ ✅')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('ನಕಲಿಸಿ & ಪ್ರಿಂಟ್'),
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
        entries.add({'date': 'ಹಳೆಯ ಟಿಪ್ಪಣಿ', 'text': trimmed});
      }
    }
    return entries;
  }

  void _showAppointmentDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    int durationMinutes = 60;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: kCard,
          title: Text('ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ರಚಿಸಿ', style: TextStyle(color: kText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                final ok = await CalendarService.createAppointment(
                  clientName: widget.name,
                  startTime: startTime,
                  duration: Duration(minutes: durationMinutes),
                  description: 'ಜಾತಕ ವಿಶ್ಲೇಷಣೆ - ${widget.name}\nಸ್ಥಳ: ${widget.place}',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Calendar ಗೆ ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ಸೇರಿಸಲಾಗಿದೆ!' : 'ಅಪಾಯಿಂಟ್‌ಮೆಂಟ್ ವಿಫಲ'),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: (e.key == 0 && bold0) ? FontWeight.w700 : FontWeight.normal,
                color: kText,
              ),
              maxLines: 1,
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
