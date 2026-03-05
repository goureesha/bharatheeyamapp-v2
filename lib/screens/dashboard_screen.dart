import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../widgets/ashtakavarga_widget.dart';
import '../services/ad_service.dart';

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
  final void Function(String notes, Map<String, int> aroodhas) onSave;

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

  static const _tabs = [
    'ಕುಂಡಲಿ', 'ಗ್ರಹ ಸ್ಫುಟ', 'ಉಪಗ್ರಹ ಸ್ಫುಟ', 'ಆರೂಢ',
    'ದಶ', 'ಪಂಚಾಂಗ', 'ಭಾವ', 'ಅಷ್ಟಕವರ್ಗ',
    'ಟಿಪ್ಪಣಿ', 'ಬಗ್ಗೆ'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _notes = widget.initialNotes;
    _aroodhas = Map.from(widget.initialAroodhas);
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
            // Header with back/save
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kPurple1, kPurple2]),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.name.isNotEmpty ? widget.name : 'ಭಾರತೀಯಮ್',
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: Colors.white),
                    onPressed: () {
                      widget.onSave(_notes, _aroodhas);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ಉಳಿಸಲಾಗಿದೆ!',
                          style: const TextStyle())));
                    },
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: Colors.white,
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
                  _buildGrahaSphutas(),
                  _buildUpagrahaTab(),
                  _buildAroodhaTab(),
                  _buildDashaTab(),
                  _buildPanchangTab(),
                  _buildBhavaTab(),
                  _buildAshtakavargaTab(),
                  _buildNotesTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
            const BannerAdWidget(),
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
      {'label': 'ನವಾಂಶ ಕುಂಡಲಿ (D9)', 'varga': 9, 'isBhava': false},
      {'label': 'ಹೋರಾ ಕುಂಡಲಿ (D2)', 'varga': 2, 'isBhava': false},
      {'label': 'ದ್ರೇಕ್ಕಾಣ ಕುಂಡಲಿ (D3)', 'varga': 3, 'isBhava': false},
      {'label': 'ದ್ವಾದಶಾಂಶ ಕುಂಡಲಿ (D12)', 'varga': 12, 'isBhava': false},
      {'label': 'ತ್ರಿಂಶಾಂಶ ಕುಂಡಲಿ (D30)', 'varga': 30, 'isBhava': false},
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
                  style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800,
                    color: Color(0xFF2B6CB0)),
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
                const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
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
  // TAB 2: GRAHA SPHUTA TABLE
  // ─────────────────────────────────────────────
  Widget _buildGrahaSphutas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _tableHeader(['ಗ್ರಹ', 'ಸ್ಫುಟ', 'ನಕ್ಷತ್ರ - ಪಾದ']),
            ...planetOrder.map((p) {
              final info = widget.result.planets[p];
              if (info == null) return const SizedBox.shrink();
              return _tableRow([p, formatDeg(info.longitude), '${info.nakshatra} - ${info.pada}'],
                bold0: true);
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 3: UPAGRAHA SPHUTA TABLE
  // ─────────────────────────────────────────────
  Widget _buildUpagrahaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
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
                  const SectionTitle('ಆರೂಢ ಚಕ್ರ'),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selAro,
                        items: ['ಆರೂಢ','ಉದಯ','ಲಗ್ನಾಂಶ','ಛತ್ರ','ಸ್ಪೃಷ್ಟಾಂಗ','ಚಂದ್ರ','ತಾಂಬೂಲ']
                          .map((a) => DropdownMenuItem(value: a, child: Text(a, style: const TextStyle()))).toList(),
                        onChanged: (v) => setS(() => _selAro = v!),
                        decoration: const InputDecoration(labelText: 'ಆರೂಢ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selRashiIdx,
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i, child: Text(knRashi[i], style: const TextStyle()))).toList(),
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
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kv('ಸ್ಥಳ', widget.place),
            _kv('ದಿನಾಂಕ', dateStr),
            _kv('ಸಮಯ', timeStr),
          ])),
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
  // TAB 8: ASHTAKAVARGA
  // ─────────────────────────────────────────────
  Widget _buildAshtakavargaTab() {
    return AshtakavargaWidget(
      key: UniqueKey(),
      savBindus: widget.result.savBindus,
      bavBindus: widget.result.bavBindus,
    );
  }

  // ─────────────────────────────────────────────
  // TAB 9: NOTES
  // ─────────────────────────────────────────────
  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
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
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2D3748)),
      ),
    );
  }



  // ─────────────────────────────────────────────
  // TAB 11: ABOUT
  // ─────────────────────────────────────────────
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ಭಾರತೀಯಮ್', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('ಆವೃತ್ತಿ: 1.0.19 (Monetization & Ads)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('ನಿಖರವಾದ ವೈದಿಕ ಜ್ಯೋತಿಷ್ಯ ಲೆಕ್ಕಾಚಾರಗಳಿಗಾಗಿ ವಿನ್ಯಾಸಗೊಳಿಸಲಾಗಿದೆ.',
              style: TextStyle(color: kMuted, height: 1.6)),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(List<String> cols, {bool bold0 = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Colors.white38)),
      ),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(e.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: (e.key == 0 || bold0) ? FontWeight.w900 : FontWeight.w700,
                color: Colors.white,
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
        Text('$k: ', style: TextStyle(fontWeight: FontWeight.w800, color: const Color(0xFF2B6CB0))),
        Expanded(child: Text(v, style: const TextStyle())),
      ]),
    );
  }
}
