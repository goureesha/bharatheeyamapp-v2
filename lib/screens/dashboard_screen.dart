import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/export_service.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../widgets/shadbala_widget.dart';

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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _notes = '';
  Map<String, int> _aroodhas = {};
  int? _janmaNakshatraIdx;
  int? _dinaNakshatraIdx;


  bool _syncing = false;



  static const _tabs = [
    'ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಆರೂಢ',
    'ದಶ', 'ಪಂಚಾಂಗ', 'ಭಾವ', 'ಷಡ್ಬಲ',
    'ಟಿಪ್ಪಣಿ'
  ];

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
    // Define all charts in the specific order requested
    final charts = [
      {'label': 'ರಾಶಿ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': false},
      {'label': 'ಭಾವ ಕುಂಡಲಿ', 'varga': 1, 'isBhava': true},
      {'label': 'ನವಾಂಶ ಕುಂಡಲಿ', 'varga': 9, 'isBhava': false},
      {'label': 'ಹೋರಾ ಕುಂಡಲಿ', 'varga': 2, 'isBhava': false},
      {'label': 'ದ್ರೇಕ್ಕಾಣ ಕುಂಡಲಿ', 'varga': 3, 'isBhava': false},
      {'label': 'ದ್ವಾದಶಾಂಶ ಕುಂಡಲಿ', 'varga': 12, 'isBhava': false},
      {'label': 'ತ್ರಿಂಶಾಂಶ ಕುಂಡಲಿ', 'varga': 30, 'isBhava': false},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          ...charts.map((chart) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Text(
                  chart['label'] as String,
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: kPurple2),
                ),
                const SizedBox(height: 6),
                KundaliChart(
                  result: widget.result,
                  varga: chart['varga'] as int,
                  isBhava: chart['isBhava'] as bool,
                  showSphutas: false,
                  centerLabel: chart['label'] as String,
                  onPlanetTap: _showPlanetDetail,
                ),
                const SizedBox(height: 8),
                Divider(thickness: 1, color: kBorder),
              ],
            ),
          )),
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
  // TAB 2: COMBINED SPHUTA (Graha + Upagraha)
  // ─────────────────────────────────────────────
  Widget _buildSphutas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Graha Sphuta Table
          Text('ಗ್ರಹ ಸ್ಫುಟ', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(['ಗ್ರಹ', 'ರಾಶಿ', 'ಸ್ಫುಟ', 'ನಕ್ಷತ್ರ - ಪಾದ']),
                ...planetOrder.map((p) {
                  final info = widget.result.planets[p];
                  if (info == null) return const SizedBox.shrink();
                  final ri = (info.longitude / 30).floor() % 12;
                  return _tableRow([p, knRashi[ri], formatDeg(info.longitude), '${info.nakshatra} - ${info.pada}'],
                    bold0: true);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upagraha Sphuta Table
          Text('ಉಪಗ್ರಹ ಸ್ಫುಟ', style: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(['ಉಪಗ್ರಹ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ']),
                ...sphutas16Order.map((sp) {
                  final deg = widget.result.advSphutas[sp];
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
    final pan = widget.result.panchang;
    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            child: Text(
              'ಶಿಷ್ಟ ದಶೆ: ${pan.dashaLord}  ಉಳಿಕೆ: ${pan.dashaBalance}',
              style: TextStyle(
                color: kOrange, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
          DashaWidget(dashas: widget.result.dashas),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 6: PANCHANG
  // ─────────────────────────────────────────────
  Widget _buildPanchangTab() {
    final pan = widget.result.panchang;
    final dateStr = '${widget.dob.day.toString().padLeft(2,'0')}-${widget.dob.month.toString().padLeft(2,'0')}-${widget.dob.year}';
    final timeStr = '${widget.hour}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Date & Time info
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kv('ಸ್ಥಳ', widget.place),
            _kv('ದಿನಾಂಕ', dateStr),
            _kv('ಸಮಯ', timeStr),
          ])),

          // Panchanga data
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 7: BHAVA
  // ─────────────────────────────────────────────
  Widget _buildBhavaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _tableHeader(['ಭಾವ', 'ಮಧ್ಯ ಸ್ಫುಟ', 'ರಾಶಿ']),
            ...List.generate(12, (i) {
              final deg = widget.result.bhavas[i];
              return _tableRow(
                ['${i+1}', formatDeg(deg), knRashi[(deg/30).floor() % 12]],
                bold0: true,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 8: SHADBALA
  // ─────────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Action buttons
          Row(
            children: [
              if (GoogleAuthService.isSignedIn) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await DocsService.openDoc(widget.name);
                      if (!ok && mounted) {
                        // Create doc first if doesn't exist
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
          const SizedBox(height: 12),
          // Notes text field
          Expanded(
            child: TextField(
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (v) => _notes = v,
              controller: TextEditingController(text: _notes),
              decoration: InputDecoration(
                hintText: 'ನಿಮ್ಮ ಟಿಪ್ಪಣಿಗಳನ್ನು ಇಲ್ಲಿ ಬರೆಯಿರಿ...',
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
              ),
              style: TextStyle(fontSize: 15, height: 1.5, color: kText),
            ),
          ),
        ],
      ),
    );
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
