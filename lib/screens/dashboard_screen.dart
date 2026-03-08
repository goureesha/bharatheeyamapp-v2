import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/kundali_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../widgets/shadbala_widget.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import 'match_making_tab.dart';

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
  final void Function(String notes, Map<String, int> aroodhas, int? janmaNakshatraIdx) onSave;

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

  static const _tabs = [
    'ಕುಂಡಲಿ', 'ಗ್ರಹ ಸ್ಫುಟ', 'ಉಪಗ್ರಹ ಸ್ಫುಟ', 'ಆರೂಢ',
    'ದಶ', 'ಪಂಚಾಂಗ', 'ಭಾವ', 'ಷಡ್ಬಲ', 'ತಾರಾನುಕೂಲ', 'ಹೊಂದಾಣಿಕೆ',
    'ಟಿಪ್ಪಣಿ', 'ಸೆಟ್ಟಿಂಗ್ಸ್'
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
                  IconButton(
                    icon: Icon(Icons.save, color: kText),
                    tooltip: 'Save Profile',
                    onPressed: () {
                      widget.onSave(_notes, _aroodhas, _janmaNakshatraIdx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ಉಳಿಸಲಾಗಿದೆ!')));
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
                  _buildShadbalaTab(),
                  _buildTaranukoolaTab(),
                  const MatchMakingTab(),
                  _buildNotesTab(),
                  _buildSettingsTab(),
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
                Divider(thickness: 1, color: Color(0xFFE2E8F0)),
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
  // TAB 8: SHADBALA
  // ─────────────────────────────────────────────
  Widget _buildShadbalaTab() {
    return ShadbalaWidget(
      key: UniqueKey(),
      shadbala: widget.result.shadbala,
    );
  }

  // ─────────────────────────────────────────────
  // TAB 9: TARANUKOOLA
  // ─────────────────────────────────────────────
  Widget _buildTaranukoolaTab() {
    final taras = [
      'ಜನ್ಮ ತಾರೆ (ಅಶುಭ)',        
      'ಸಂಪತ್ ತಾರೆ (ಶುಭ)',           
      'ವಿಪತ್ ತಾರೆ (ಅಶುಭ)',       
      'ಕ್ಷೇಮ ತಾರೆ (ಶುಭ)',           
      'ಪ್ರತ್ಯಕ್ ತಾರೆ (ಅಶುಭ)',      
      'ಸಾಧಕ ತಾರೆ (ಶುಭ)',           
      'ನೈಧನ ತಾರೆ (ಅಶುಭ)',        
      'ಮಿತ್ರ ತಾರೆ (ಶುಭ)',           
      'ಪರಮ ಮಿತ್ರ ತಾರೆ (ಅತ್ಯುತ್ತಮ)',      
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ತಾರಾನುಕೂಲ ಫಲಿತಾಂಶಗಳು', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurple1)),
            const SizedBox(height: 16),
            Text('ನಿಮ್ಮ ಜನ್ಮ ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  hint: Text('ನಕ್ಷತ್ರ ಆಯ್ಕೆಮಾಡಿ'),
                  value: _janmaNakshatraIdx,
                  items: List.generate(27, (i) => DropdownMenuItem<int>(
                    value: i,
                    child: Text(knNak[i], style: TextStyle(fontSize: 16)),
                  )),
                  onChanged: (val) {
                    setState(() {
                      _janmaNakshatraIdx = val;
                      _saveSelectedJanmaNakshatra(val);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            if (_janmaNakshatraIdx != null) ...[
              Text('ನಿಮ್ಮ ನಕ್ಷತ್ರಕ್ಕೆ ಅನುಗುಣವಾಗಿ ತಾರೆಗಳ ಪಟ್ಟಿ:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(9, (taraIdx) {
                // Determine if this Tara is Shubha or Ashubha
                bool isShubha = (taraIdx == 1 || taraIdx == 3 || taraIdx == 5 || taraIdx == 7 || taraIdx == 8);
                Color bgColor = isShubha ? Colors.green.shade50 : Colors.red.shade50;
                Color borderColor = isShubha ? Colors.green.shade200 : Colors.red.shade200;
                Color textColor = isShubha ? Colors.green.shade800 : Colors.red.shade800;

                // Calculate the 3 Nakshatras that fall under this Tara
                int n1 = (_janmaNakshatraIdx! + taraIdx) % 27;
                int n2 = (_janmaNakshatraIdx! + taraIdx + 9) % 27;
                int n3 = (_janmaNakshatraIdx! + taraIdx + 18) % 27;
                String nakshatrasText = '${knNak[n1]}, ${knNak[n2]}, ${knNak[n3]}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          taras[taraIdx],
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                        )
                      ),
                      Container(width: 1, height: 40, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Expanded(
                        flex: 3,
                        child: Text(
                          nakshatrasText,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                        )
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
               Container(
                 padding: const EdgeInsets.all(16),
                 alignment: Alignment.center,
                 decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                 child: Text('ಫಲಿತಾಂಶವನ್ನು ನೋಡಲು ನಕ್ಷತ್ರವನ್ನು ಆಯ್ಕೆಮಾಡಿ.', style: TextStyle(color: Colors.grey.shade600))
               )
            ]
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB 10: NOTES
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
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          fillColor: Colors.white,
          filled: true,
        ),
        style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2D3748)),
      ),
    );
  }



  // ─────────────────────────────────────────────
  // TAB 11: SETTINGS
  // ─────────────────────────────────────────────
  Widget _buildSettingsTab() {
    final themes = ['ಸ್ಟ್ಯಾಂಡರ್ಡ್ ಲೈಟ್', 'ಡಾರ್ಕ್ ಮೋಡ್', 'ಸ್ವರ್ಣ', 'ಸಾಗರ', 'ಹಸಿರು'];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme selection
            SectionTitle('ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್ಸ್'),
            const SizedBox(height: 10),
            ValueListenableBuilder<int>(
              valueListenable: AppThemes.themeNotifier,
              builder: (context, currentTheme, _) {
                return Column(
                  children: List.generate(themes.length, (i) {
                    return RadioListTile<int>(
                      value: i,
                      groupValue: currentTheme,
                      title: Text(themes[i], style: TextStyle(fontWeight: FontWeight.w800, color: kText)),
                      activeColor: kPurple2,
                      onChanged: (val) {
                        if (val != null) {
                          AppThemes.setTheme(val);
                        }
                      },
                    );
                  }),
                );
              }
            ),
            const SizedBox(height: 24),
            Divider(color: kBorder),
            const SizedBox(height: 24),
            
            // Purchase Premium
            SectionTitle('ಪ್ರೀಮಿಯಂ ಚಂದಾದಾರಿಕೆ'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SubscriptionService.hasAdFree ? Colors.green.shade50 : kPurple1.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SubscriptionService.hasAdFree ? Colors.green.shade200 : kPurple2.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                     children: [
                       Icon(
                         SubscriptionService.hasAdFree ? Icons.check_circle : Icons.star, 
                         color: SubscriptionService.hasAdFree ? Colors.green.shade700 : kOrange,
                         size: 28,
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           SubscriptionService.hasAdFree 
                              ? 'ನೀವು ಪ್ರೀಮಿಯಂ ಸದಸ್ಯರು! (Ad-Free Active)' 
                              : 'ಜಾಹೀರಾತು ಮುಕ್ತ ಅನುಭವ ಪಡೆಯಿರಿ',
                           style: TextStyle(
                             fontSize: SubscriptionService.hasAdFree ? 16 : 18, 
                             fontWeight: FontWeight.bold,
                             color: SubscriptionService.hasAdFree ? Colors.green.shade800 : kPurple1
                           ),
                         ),
                       ),
                     ],
                   ),
                   if (!SubscriptionService.hasAdFree) ...[
                     const SizedBox(height: 12),
                     Text(
                       'ವರ್ಷಕ್ಕೆ ಕೇವಲ ₹೫೦೦ ಪಾವತಿಸಿ ಮತ್ತು ಅಪ್ಲಿಕೇಶನ್ ಅನ್ನು ಯಾವುದೇ ಜಾಹೀರಾತುಗಳಿಲ್ಲದೆ ಬಳಸಿ.',
                       style: TextStyle(fontSize: 14, color: kText, height: 1.4),
                     ),
                     const SizedBox(height: 20),
                     ElevatedButton(
                       onPressed: () async {
                         final success = await SubscriptionService.buyAdFreeSubscription();
                         if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ಚಂದಾದಾರಿಕೆ ಪ್ರಕ್ರಿಯೆ ವಿಫಲವಾಗಿದೆ ಅಥವಾ ನೀವು ವೆಬ್ ಬಳಸುತ್ತಿದ್ದೀರಿ.'))
                            );
                         }
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: kOrange,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 14),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       ),
                       child: const Text('₹500 / ವರ್ಷಕ್ಕೆ ಚಂದಾದಾರರಾಗಿ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                     const SizedBox(height: 12),
                     TextButton(
                       onPressed: () async {
                          await SubscriptionService.restorePurchases();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ಹಿಂದಿನ ಖರೀದಿಗಳನ್ನು ಮರುಸ್ಥಾಪಿಸಲಾಗಿದೆ.'))
                          );
                       },
                       child: Text('ಹಿಂದಿನ ಖರೀದಿಯನ್ನು ಮರುಸ್ಥಾಪಿಸಿ (Restore)', style: TextStyle(color: kPurple2, fontWeight: FontWeight.w600)),
                     )
                   ]
                ],
              ),
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
      color: const Color(0xFFEDF2F7),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(e.value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(List<String> cols, {bool bold0 = false}) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7)))),
      child: Row(
        children: cols.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: (e.key == 0 && bold0) ? FontWeight.w700 : FontWeight.normal,
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
        Expanded(child: Text(v, style: TextStyle())),
      ]),
    );
  }
}
