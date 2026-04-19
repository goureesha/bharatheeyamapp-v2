import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/prashna_chart.dart';
import '../widgets/planet_detail_sheet.dart';

class PrashnaDashboardScreen extends StatefulWidget {
  final KundaliResult result;
  final String name;
  final String place;
  final DateTime dob;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;

  const PrashnaDashboardScreen({
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
  });

  @override
  State<PrashnaDashboardScreen> createState() => _PrashnaDashboardScreenState();
}

class _PrashnaDashboardScreenState extends State<PrashnaDashboardScreen>
    with SingleTickerProviderStateMixin {
  String? _bhavaPlanet;
  late TabController _tabCtrl;
  late KundaliResult _result;
  late DateTime _dob;
  late int _hour;
  late int _minute;
  late String _ampm;
  bool _recalculating = false;

  static const _tabs = ['ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಪಂಚಾಂಗ', 'ಷಡ್ವರ್ಗ'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _result = widget.result;
    _dob = widget.dob;
    _hour = widget.hour;
    _minute = widget.minute;
    _ampm = widget.ampm;
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    // Pick date
    final newDate = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (newDate == null || !mounted) return;

    // Pick time
    int h24 = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
    if (_ampm == 'AM' && _hour == 12) h24 = 0;
    final newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h24, minute: _minute),
    );
    if (newTime == null || !mounted) return;

    // Convert back to 12h
    final newHour = newTime.hourOfPeriod == 0 ? 12 : newTime.hourOfPeriod;
    final newAmpm = newTime.hour < 12 ? 'AM' : 'PM';

    setState(() {
      _dob = newDate;
      _hour = newHour;
      _minute = newTime.minute;
      _ampm = newAmpm;
      _recalculating = true;
    });

    // Recalculate
    try {
      int h24r = _hour + (_ampm == 'PM' && _hour != 12 ? 12 : 0);
      if (_ampm == 'AM' && _hour == 12) h24r = 0;
      final localHour = h24r + _minute / 60.0;

      final result = await AstroCalculator.calculate(
        year: _dob.year, month: _dob.month, day: _dob.day,
        hourUtcOffset: 5.5,
        hour24: localHour,
        lat: widget.lat, lon: widget.lon,
        ayanamsaMode: 'lahiri',
        trueNode: true,
      );
      if (result != null && mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ದೋಷ: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _recalculating = false);
  }

  void _showPlanetDetail(String pName) {
    try {
      final info = _result.planets[pName];
      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Planet "$pName" not found in result')));
        return;
      }
      final sun = _result.planets['ರವಿ'];
      final detail = AstroCalculator.getPlanetDetail(
        pName, info.longitude, info.speed, sun?.longitude ?? 0);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PlanetDetailSheet(pName: pName, detail: detail),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error for $pName: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಪ್ರಶ್ನ ಕುಂಡಲಿ',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info header — tappable to change date/time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: InkWell(
              onTap: _recalculating ? null : _pickDateTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name.isNotEmpty ? widget.name : 'ಪ್ರಶ್ನ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple2)),
                          const SizedBox(height: 2),
                          Text(
                            '${_dob.day.toString().padLeft(2, '0')}/${_dob.month.toString().padLeft(2, '0')}/${_dob.year}  '
                            '$_hour:${_minute.toString().padLeft(2, '0')} $_ampm  •  ${widget.place}',
                            style: TextStyle(fontSize: 12, color: kMuted),
                          ),
                        ],
                      ),
                    ),
                    if (_recalculating)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Icon(Icons.edit_calendar, color: kPurple2, size: 22),
                  ],
                ),
              ),
            ),
          ),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TabBar(
              controller: _tabCtrl,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
              labelColor: kPurple2,
              unselectedLabelColor: kMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              indicatorColor: kPurple2,
              indicatorWeight: 3,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildKundaliTab(),
                _buildSphutas(),
                _buildPanchangTab(),
                _buildShadvargaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: KUNDALI (Rashi + Bhava charts)
  // ═══════════════════════════════════════════
  Widget _buildKundaliTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isLargeScreen = screenWidth > 600 || isLandscape;
    final chartSize = isLargeScreen
        ? (screenWidth * 0.45).clamp(350.0, 550.0)
        : screenWidth * 0.92;
    final textScale = isLargeScreen ? (chartSize / 350.0).clamp(1.1, 1.4) : 1.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _chartSection(
            label: 'ರಾಶಿ ಕುಂಡಲಿ',
            isBhava: false,
            chartSize: chartSize,
            textScale: textScale,
          ),
          const SizedBox(height: 16),
          _buildBhavaControls(),
          const SizedBox(height: 8),
          _chartSection(
            label: _bhavaPlanet != null
                ? 'ಭಾವ ಕುಂಡಲಿ ($_bhavaPlanet ಕೇಂದ್ರ)'
                : 'ಭಾವ ಕುಂಡಲಿ',
            isBhava: true,
            chartSize: chartSize,
            textScale: textScale,
          ),
          const SizedBox(height: 16),
          _buildYogaSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _chartSection({
    required String label,
    required bool isBhava,
    required double chartSize,
    required double textScale,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(
          fontSize: 15 * textScale,
          fontWeight: FontWeight.w800,
          color: kPurple2,
        )),
        const SizedBox(height: 4),
        SizedBox(
          width: chartSize,
          height: chartSize,
          child: PrashnaChart(
            result: _result,
            isBhava: isBhava,
            textScale: textScale,
            centerLabel: isBhava ? 'ಭಾವ\nಕುಂಡಲಿ' : 'ರಾಶಿ\nಕುಂಡಲಿ',
            onPlanetTap: _showPlanetDetail,
            selectedPlanet: isBhava ? _bhavaPlanet : null,
            onPlanetLongPress: isBhava ? (pName) {
              setState(() => _bhavaPlanet = _bhavaPlanet == pName ? null : pName);
            } : null,
            bhavaFromPlanet: isBhava ? _bhavaPlanet : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBhavaControls() {
    final planets = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          children: [
            Text('ಭಾವ ಕೇಂದ್ರ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kMuted)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _bhavaChip('ಲಗ್ನ', null),
                ...planets.map((p) => _bhavaChip(p, p)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bhavaChip(String label, String? planet) {
    final isActive = _bhavaPlanet == planet;
    return GestureDetector(
      onTap: () => setState(() => _bhavaPlanet = planet),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? kTeal : kCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? kTeal : kBorder),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: isActive ? Colors.white : kText,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: SPHUTA (Graha + Upagraha)
  // ═══════════════════════════════════════════
  Widget _buildSphutas() {
    final r = _result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Graha Sphuta
          Text('ಗ್ರಹ ಸ್ಫುಟ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(['ಗ್ರಹ', 'ರಾಶಿ', 'ಸ್ಫುಟ', 'ನಕ್ಷತ್ರ - ಪದ']),
                ...planetOrder.map((p) {
                  final info = r.planets[p];
                  if (info == null) return const SizedBox.shrink();
                  final ri = (info.longitude / 30).floor() % 12;
                  return _tableRow([
                    appPlanetNames[p] ?? p,
                    appRashi[ri],
                    formatDeg(info.longitude),
                    '${info.nakshatra} - ${info.pada}',
                  ], bold0: true);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Upagraha Sphuta
          Text('ಉಪಗ್ರಹ ಸ್ಫುಟ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tableHeader(['ಉಪಗ್ರಹ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ']),
                ...sphutas16Order.map((sp) {
                  final deg = r.advSphutas[sp];
                  if (deg == null) return const SizedBox.shrink();
                  final ri = (deg / 30).floor() % 12;
                  final nakIdx = (deg / 13.333333).floor() % 27;
                  final pada = ((deg % 13.333333) / 3.333333).floor() + 1;
                  return _tableRow([
                    sp, appRashi[ri], formatDeg(deg), '${appNak[nakIdx]}-$pada',
                  ], bold0: true);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 3: PANCHANGA
  // ═══════════════════════════════════════════
  Widget _buildPanchangTab() {
    final r = _result;
    final pan = r.panchang;
    final dateStr = '${widget.dob.day.toString().padLeft(2, "0")}-${widget.dob.month.toString().padLeft(2, "0")}-${widget.dob.year}';
    final timeStr = '${widget.hour}:${widget.minute.toString().padLeft(2, "0")} ${widget.ampm}';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.name.isNotEmpty) _kv('ಹೆಸರು', widget.name),
            _kv('ಸ್ಥಳ', widget.place),
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
              _tableRow(['ಚಂದ್ರ ನಕ್ಷತ್ರ', () {
                final moonPada = r.planets['ಚಂದ್ರ']?.pada;
                final fallback = (pan.nakPercent * 4).floor() + 1;
                final p = moonPada ?? (fallback < 1 ? 1 : fallback > 4 ? 4 : fallback);
                return '${pan.nakshatra} - ಪದ $p';
              }()]),
              _tableRow(['ಯೋಗ', pan.yoga]),
              _tableRow(['ಕರಣ', pan.karana]),
              _tableRow(['ಚಂದ್ರ ರಾಶಿ', pan.chandraRashi]),
              _tableRow(['ಚಂದ್ರ ಮಾಸ', pan.chandraMasa]),
              _tableRow(['ಸೌರ ನಕ್ಷತ್ರ', '${pan.suryaNakshatra} - ಪದ ${pan.suryaPada}']),
              _tableRow(['ಸೌರ ಮಾಸ', pan.souraMasa]),
              _tableRow(['ಸೌರ ಮಾಸ ಗತ ದಿನ', pan.souraMasaGataDina]),
              _tableRow(['ಸೂರ್ಯೋದಯ', pan.sunrise]),
              _tableRow(['ಸೂರ್ಯಾಸ್ತ', pan.sunset]),
              _tableRow(['ಉದಯಾದಿ ಘಟಿ', pan.udayadiGhati]),
              _tableRow(['ಗತ ಘಟಿ', pan.gataGhati]),
              _tableRow(['ಪರಮ ಘಟಿ', pan.paramaGhati]),
              _tableRow(['ಶೇಷ ಘಟಿ', pan.shesha]),
              _tableRow(['ವಿಷ ಘಟಿ', pan.vishaPraghati]),
              _tableRow(['ಅಮೃತ ಘಟಿ', pan.amrutaPraghati]),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 4: SHADVARGA
  // ═══════════════════════════════════════════
  Widget _buildShadvargaTab() {
    final r = _result;

    // Column headers (matching kundali section)
    final hGraha = 'ಗ್ರಹ';
    final hD3 = 'ದ್ರೇ';
    final hD2 = 'ಹೋ';
    final hD9 = 'ನ';
    final hD30 = 'ತ್ರಿಂ';
    final hD12 = 'ದ್ವಾ';
    final hKshetra = 'ಕ್ಷೇ';

    String getRashiLord(String rashiNameKn) {
      int idx = knRashi.indexOf(rashiNameKn);
      if (idx < 0) return rashiNameKn;
      switch (idx) {
        case 0: return 'ಕು';
        case 1: return 'ಶು';
        case 2: return 'ಬು';
        case 3: return 'ಚ';
        case 4: return 'ರ';
        case 5: return 'ಬು';
        case 6: return 'ಶು';
        case 7: return 'ಕು';
        case 8: return 'ಗು';
        case 9: return 'ಶ';
        case 10: return 'ಶ';
        case 11: return 'ಗು';
      }
      return '';
    }

    int rowIdx = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                Text('ಷಡ್ವರ್ಗ', style: TextStyle(
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
                    final displayName = appPlanetNames[pNameKey] ?? pNameKey;
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // YOGA SECTION (in Kundali tab)
  // ═══════════════════════════════════════════
  Widget _buildYogaSection() {
    // Detect yogas for all 12 rashis
    final allYogas = <int, List<Map<String, dynamic>>>{};
    int totalCount = 0;
    for (int r = 0; r < 12; r++) {
      final yogas = _detectYogas(virtualLagnaRi: r);
      if (yogas.isNotEmpty) {
        allYogas[r] = yogas;
        totalCount += yogas.length;
      }
    }

    if (allYogas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: Center(child: Text('ಯೋಗಗಳು ಕಂಡುಬಂದಿಲ್ಲ', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600))),
        ),
      );
    }

    final lagnaRi = (_result.planets['ಲಗ್ನ']?.longitude ?? 0) ~/ 30 % 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kTeal.withOpacity(0.15), kPurple2.withOpacity(0.08)]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14), topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: kTeal.withOpacity(0.4), width: 2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 18, color: kTeal),
                const SizedBox(width: 8),
                Text('ಯೋಗಗಳು (ಎಲ್ಲ ರಾಶಿ)', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: kTeal,
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$totalCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              ],
            ),
          ),
          // Per-rashi yoga list
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              children: List.generate(12, (rIdx) {
                final yogas = allYogas[rIdx];
                if (yogas == null || yogas.isEmpty) return const SizedBox.shrink();
                final rashiName = knRashi[rIdx];
                final isLagna = rIdx == lagnaRi;
                final bhavaNum = ((rIdx - lagnaRi + 12) % 12) + 1;

                return ExpansionTile(
                  initiallyExpanded: isLagna,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                  childrenPadding: EdgeInsets.zero,
                  backgroundColor: kBg.withOpacity(0.3),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLagna ? kTeal : kPurple2.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$bhavaNum', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900,
                          color: isLagna ? Colors.white : kPurple2,
                        )),
                      ),
                      const SizedBox(width: 8),
                      Text(rashiName, style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 17,
                        color: isLagna ? kTeal : kText,
                      )),
                      if (isLagna) Text(' (ಲಗ್ನ)', style: TextStyle(fontSize: 14, color: kTeal, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: kTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${yogas.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kTeal)),
                      ),
                    ],
                  ),
                  children: yogas.asMap().entries.map((entry) {
                    final y = entry.value;
                    final isEven = entry.key % 2 == 0;
                    final isShubha = y['shubha'] == true;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isEven ? kBg.withOpacity(0.4) : kCard,
                        border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isShubha ? Icons.check_circle : Icons.warning_amber_rounded,
                                size: 18,
                                color: isShubha ? const Color(0xFF2F855A) : const Color(0xFFE53E3E),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(y['name'] as String, style: TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 16,
                                      color: isShubha ? const Color(0xFF2F855A) : const Color(0xFFE53E3E),
                                    )),
                                    const SizedBox(height: 3),
                                    Text(y['desc'] as String, style: TextStyle(
                                      fontSize: 13, color: kMuted, fontWeight: FontWeight.w600,
                                    )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (y['shloka'] != null && (y['shloka'] as String).isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFE082), width: 0.5),
                              ),
                              child: Text(y['shloka'] as String, style: const TextStyle(
                                fontSize: 13, fontStyle: FontStyle.italic,
                                color: Color(0xFF5D4037), fontWeight: FontWeight.w600,
                                height: 1.4,
                              )),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _detectYogas({required int virtualLagnaRi}) {
    final r = _result;
    final yogas = <Map<String, dynamic>>[];

    // Helper: get rashi index of a planet
    int ri(String p) {
      final info = r.planets[p];
      return info != null ? (info.longitude / 30).floor() % 12 : -1;
    }

    // Helper: get bhava of a planet (1-12) from virtual lagna
    int bhava(String p) {
      final info = r.planets[p];
      if (info == null) return -1;
      final pRi = (info.longitude / 30).floor() % 12;
      return ((pRi - virtualLagnaRi + 12) % 12) + 1;
    }

    // Helper: are two planets in kendra (1,4,7,10) from each other?
    bool inKendra(String p1, String p2) {
      final r1 = ri(p1), r2 = ri(p2);
      if (r1 < 0 || r2 < 0) return false;
      final diff = (r2 - r1 + 12) % 12;
      return [0, 3, 6, 9].contains(diff);
    }

    // Helper: are two planets conjunct (same rashi)?
    bool conjunct(String p1, String p2) => ri(p1) == ri(p2) && ri(p1) >= 0;

    // Helper: is planet in kendra from virtual lagna?
    bool inKendraFromLagna(String p) {
      final b = bhava(p);
      return [1, 4, 7, 10].contains(b);
    }

    // Helper: is planet in trikona from virtual lagna?
    bool inTrikonaFromLagna(String p) {
      final b = bhava(p);
      return [1, 5, 9].contains(b);
    }

    final lagnaRi = virtualLagnaRi;
    final moonRi = ri('ಚಂದ್ರ');
    final sunRi = ri('ರವಿ');
    final marsRi = ri('ಕುಜ');
    final mercRi = ri('ಬುಧ');
    final jupRi = ri('ಗುರು');
    final venRi = ri('ಶುಕ್ರ');
    final satRi = ri('ಶನಿ');

    // 1. Gaja Kesari Yoga — Jupiter in kendra from Moon
    if (inKendra('ಚಂದ್ರ', 'ಗುರು')) {
      yogas.add({'name': 'ಗಜ ಕೇಸರಿ ಯೋಗ', 'desc': 'ಗುರು ಚಂದ್ರನಿಂದ ಕೇಂದ್ರದಲ್ಲಿ — ಕೀರ್ತಿ, ಬುದ್ಧಿ, ಸಂಪತ್ತು', 'shubha': true, 'shloka': 'केन्द्रे देवगुरौ शशाङ्कसहिते गोवाजिराजप्रदम् ।\nगजकेसरी योगस्तु चन्द्रात् केन्द्रे बृहस्पतिः ॥ — फलदीपिका'});
    }

    // 2. Chandra-Mangala Yoga — Moon conjunct Mars
    if (conjunct('ಚಂದ್ರ', 'ಕುಜ')) {
      yogas.add({'name': 'ಚಂದ್ರ-ಮಂಗಳ ಯೋಗ', 'desc': 'ಚಂದ್ರ-ಕುಜ ಸಂಯೋಗ — ಧನ ಲಾಭ, ಸಾಹಸ', 'shubha': true, 'shloka': 'चन्द्रमङ्गलयोगोऽयं धनदो मातृसौख्यदः ।\nसाहसी क्रूरकर्मा च भवेज्जातो न संशयः ॥ — फलदीपिका'});
    }

    // 3. Budha-Aditya Yoga — Sun conjunct Mercury
    if (conjunct('ರವಿ', 'ಬುಧ')) {
      yogas.add({'name': 'ಬುಧ-ಆದಿತ್ಯ ಯೋಗ', 'desc': 'ರವಿ-ಬುಧ ಸಂಯೋಗ — ಬುದ್ಧಿ, ವಾಕ್ಪಟುತ್ವ', 'shubha': true, 'shloka': 'बुधादित्ययोगो भवति यदा रविबुधयोः सहवासः ।\nविद्वान् वक्ता कुशलो राजसभायां प्रियो भवेत् ॥ — बृहत्पाराशरहोराशास्त्र'});
    }

    // 4. Pancha Mahapurusha Yogas
    final ownHouses = <String, List<int>>{
      'ಕುಜ': [0, 7],     // Aries, Scorpio
      'ಬುಧ': [2, 5],     // Gemini, Virgo
      'ಗುರು': [8, 11],   // Sagittarius, Pisces
      'ಶುಕ್ರ': [1, 6],   // Taurus, Libra
      'ಶನಿ': [9, 10],    // Capricorn, Aquarius
    };
    final exaltH = <String, int>{'ಕುಜ': 9, 'ಬುಧ': 5, 'ಗುರು': 3, 'ಶುಕ್ರ': 11, 'ಶನಿ': 6};
    final yogaNames = <String, String>{'ಕುಜ': 'ರುಚಕ', 'ಬುಧ': 'ಭದ್ರ', 'ಗುರು': 'ಹಂಸ', 'ಶುಕ್ರ': 'ಮಾಲವ್ಯ', 'ಶನಿ': 'ಶಶ'};

    for (final p in ['ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
      final pRi = ri(p);
      if (pRi < 0) continue;
      final inOwn = ownHouses[p]!.contains(pRi);
      final inExalt = exaltH[p] == pRi;
      if ((inOwn || inExalt) && inKendraFromLagna(p)) {
        yogas.add({
          'name': '${yogaNames[p]} ಯೋಗ (ಪಂಚ ಮಹಾಪುರುಷ)',
          'desc': '$p ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿ — ಮಹಾ ಫಲ',
          'shubha': true,
          'shloka': 'स्वोच्चे स्वक्षेत्रे वा केन्द्रस्थिते ग्रहे ।\nपञ्चमहापुरुषयोगः स्यात् — बृ.पा.हो.शा.',
        });
      }
    }

    // 5. Amala Yoga — Benefic in 10th from lagna
    for (final p in ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ']) {
      if (bhava(p) == 10) {
        yogas.add({'name': 'ಅಮಲ ಯೋಗ', 'desc': '$p 10ನೇ ಭಾವದಲ್ಲಿ — ಕೀರ್ತಿ, ಶುಭ ಕರ್ಮ', 'shubha': true, 'shloka': 'दशमे शुभग्रहे स्थिते अमलयोगः प्रकीर्तितः ।\nकीर्तिमान् धर्मशीलश्च सुखी चायुष्मान् भवेत् ॥ — सारावली'});
        break;
      }
    }

    // 6. Dhana Yoga — Lord of 2nd/11th in kendra/trikona
    for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
      final b = bhava(p);
      if ((b == 2 || b == 11) && (inKendraFromLagna(p) || inTrikonaFromLagna(p))) {
        yogas.add({'name': 'ಧನ ಯೋಗ', 'desc': '$p 2/11ನೇ ಭಾವಾಧಿಪತಿ ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿ', 'shubha': true, 'shloka': 'धनेशे लाभेशे केन्द्रत्रिकोणगे ।\nधनयोगः समाख्यातो धनधान्यसमृद्धिदः ॥ — बृ.पा.हो.शा.'});
        break;
      }
    }

    // 7. Kemadruma Yoga — No planet in 2nd/12th from Moon
    if (moonRi >= 0) {
      final m2 = (moonRi + 1) % 12;
      final m12 = (moonRi + 11) % 12;
      bool hasFlank = false;
      for (final p in ['ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
        final pR = ri(p);
        if (pR == m2 || pR == m12) { hasFlank = true; break; }
      }
      if (!hasFlank) {
        yogas.add({'name': 'ಕೇಮದ್ರುಮ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 2/12ರಲ್ಲಿ ಯಾವ ಗ್ರಹವೂ ಇಲ್ಲ — ಕಷ್ಟ, ಬಡತನ', 'shubha': false, 'shloka': 'चन्द्राद्द्वितीयद्वादशे ग्रहैर्विहीने केमद्रुमः ।\nनिर्धनो दुःखितश्चैव परान्नभोजी भवेन्नरः ॥ — फलदीपिका'});
      }
    }

    // 8. Shakata Yoga — Jupiter 6th/8th/12th from Moon
    if (moonRi >= 0 && jupRi >= 0) {
      final diff = (jupRi - moonRi + 12) % 12;
      if ([5, 7, 11].contains(diff)) {
        yogas.add({'name': 'ಶಕಟ ಯೋಗ', 'desc': 'ಗುರು ಚಂದ್ರನಿಂದ 6/8/12ರಲ್ಲಿ — ಅಸ್ಥಿರ ಭಾಗ್ಯ', 'shubha': false, 'shloka': 'चन्द्राद्षष्ठाष्टमव्यये गुरौ शकटयोगः स्यात् ।\nलब्धं नष्टं पुनर्लब्धं चक्रवत् भवति ध्रुवम् ॥ — फलदीपिका'});
      }
    }

    // 9. Vipareeta Raja Yoga — Lord of 6/8/12 in 6/8/12
    final dusthanas = [6, 8, 12];
    for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
      final b = bhava(p);
      if (dusthanas.contains(b)) {
        // Check if any other dusthana lord is also in a dusthana
        for (final p2 in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
          if (p2 == p) continue;
          final b2 = bhava(p2);
          if (dusthanas.contains(b2) && conjunct(p, p2)) {
            yogas.add({'name': 'ವಿಪರೀತ ರಾಜಯೋಗ', 'desc': '$p + $p2 ದುಸ್ಥಾನದಲ್ಲಿ ಸಂಯೋಗ — ಕಷ್ಟದಿಂದ ಲಾಭ', 'shubha': true, 'shloka': 'षष्ठाष्टव्ययनाथानां दुःस्थानस्थितिसंयुतेः ।\nविपरीतराजयोगः स्यात् कष्टात् राज्यमवाप्नुयात् ॥ — बृ.पा.हो.शा.'});
            break;
          }
        }
        break;
      }
    }

    // 10. Guru-Chandala Yoga — Jupiter conjunct Rahu
    if (conjunct('ಗುರು', 'ರಾಹು')) {
      yogas.add({'name': 'ಗುರು-ಚಾಂಡಾಲ ಯೋಗ', 'desc': 'ಗುರು-ರಾಹು ಸಂಯೋಗ — ಧರ್ಮ ಹಾನಿ, ಭ್ರಷ್ಟ ಬುದ್ಧಿ', 'shubha': false, 'shloka': 'राहुणा सह संयुक्ते गुरौ चाण्डालयोगकः ।\nधर्महीनो भवेज्जातो गुरुनिन्दाकरो नरः ॥ — बृ.पा.हो.शा.'});
    }

    // 11. Sunapha/Anapha Yoga
    if (moonRi >= 0) {
      final m2 = (moonRi + 1) % 12;
      final m12 = (moonRi + 11) % 12;
      bool has2 = false, has12 = false;
      for (final p in ['ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
        if (ri(p) == m2) has2 = true;
        if (ri(p) == m12) has12 = true;
      }
      if (has2 && has12) {
        yogas.add({'name': 'ದುರುಧರ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 2 ಮತ್ತು 12ರಲ್ಲಿ ಗ್ರಹ — ಧನವಂತ', 'shubha': true, 'shloka': 'चन्द्राद्द्वादशद्वितीये ग्रहे दुरुधरो भवेत् ।\nधनी दानपरो विद्वान् सुखभाक् सर्वसम्पदा ॥ — फलदीपिका'});
      } else if (has2) {
        yogas.add({'name': 'ಸುನಫ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 2ರಲ್ಲಿ ಗ್ರಹ — ಸ್ವಯಂ ಸಂಪಾದನೆ', 'shubha': true, 'shloka': 'चन्द्राद्द्वितीये ग्रहे सुनफयोगः प्रकीर्तितः ।\nस्वोपार्जितधनो धीमान् यशस्वी राजसम्मतः ॥ — फलदीपिका'});
      } else if (has12) {
        yogas.add({'name': 'ಅನಫ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 12ರಲ್ಲಿ ಗ್ರಹ — ಪೂರ್ವ ಪುಣ್ಯ', 'shubha': true, 'shloka': 'चन्द्राद्व्यये ग्रहे जाते अनफयोगः प्रकीर्तितः ।\nवपुष्मान् गुणवान् विद्वान् सत्कीर्तिः सुखभाग् भवेत् ॥ — फलदीपिका'});
      }
    }

    // 12. Shubha Kartari — Benefics in 2nd and 12th from lagna
    if (lagnaRi >= 0) {
      final l2 = (lagnaRi + 1) % 12;
      final l12 = (lagnaRi + 11) % 12;
      final benefics = ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ'];
      bool ben2 = false, ben12 = false;
      for (final p in benefics) {
        if (ri(p) == l2) ben2 = true;
        if (ri(p) == l12) ben12 = true;
      }
      if (ben2 && ben12) {
        yogas.add({'name': 'ಶುಭ ಕರ್ತರಿ ಯೋಗ', 'desc': 'ಲಗ್ನದ 2/12ರಲ್ಲಿ ಶುಭ ಗ್ರಹ — ರಕ್ಷಣೆ, ಶುಭ', 'shubha': true, 'shloka': 'शुभग्रहैर्द्वितीयद्वादशे शुभकर्तरी ।\nसुखी धनवान् कीर्तिमान् रक्षितो भवेन्नरः ॥ — फलदीपिका'});
      }
      // Papa Kartari
      final malefics = ['ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];
      bool mal2 = false, mal12 = false;
      for (final p in malefics) {
        if (ri(p) == l2) mal2 = true;
        if (ri(p) == l12) mal12 = true;
      }
      if (mal2 && mal12) {
        yogas.add({'name': 'ಪಾಪ ಕರ್ತರಿ ಯೋಗ', 'desc': 'ಲಗ್ನದ 2/12ರಲ್ಲಿ ಪಾಪ ಗ್ರಹ — ಅಡಚಣೆ, ಕಷ್ಟ', 'shubha': false, 'shloka': 'पापग्रहैर्द्वितीयद्वादशे पापकर्तरी ।\nपीडितो भवेज्जातो दुःखी रोगवान् नराधमः ॥ — फलदीपिका'});
      }
    }

    // 13. Neecha Bhanga Raja Yoga — debilitated planet with cancellation
    final debil = <String, int>{'ರವಿ': 6, 'ಚಂದ್ರ': 7, 'ಕುಜ': 3, 'ಬುಧ': 11, 'ಗುರು': 9, 'ಶುಕ್ರ': 5, 'ಶನಿ': 0};
    final exaltMap = <String, int>{'ರವಿ': 0, 'ಚಂದ್ರ': 1, 'ಕುಜ': 9, 'ಬುಧ': 5, 'ಗುರು': 3, 'ಶುಕ್ರ': 11, 'ಶನಿ': 6};
    for (final p in debil.keys) {
      if (ri(p) == debil[p] && inKendraFromLagna(p)) {
        yogas.add({'name': 'ನೀಚ ಭಂಗ ರಾಜಯೋಗ', 'desc': '$p ನೀಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿ — ನೀಚ ಭಂಗ', 'shubha': true, 'shloka': 'नीचग्रहे केन्द्रस्थे नीचभङ्गराजयोगकः ।\nभवेत् प्रबलो राजा पूर्वजन्मकृतपुण्यतः ॥ — बृ.पा.हो.शा.'});
        break;
      }
    }

    // 14. Adhi Yoga — Benefics in 6th, 7th, 8th from Moon
    if (moonRi >= 0) {
      final m6 = (moonRi + 5) % 12;
      final m7 = (moonRi + 6) % 12;
      final m8 = (moonRi + 7) % 12;
      int count = 0;
      for (final p in ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ']) {
        final pR = ri(p);
        if (pR == m6 || pR == m7 || pR == m8) count++;
      }
      if (count >= 2) {
        yogas.add({'name': 'ಅಧಿ ಯೋಗ', 'desc': 'ಚಂದ್ರನಿಂದ 6/7/8ರಲ್ಲಿ ಶುಭ ಗ್ರಹಗಳು — ನಾಯಕತ್ವ, ಅಧಿಕಾರ', 'shubha': true, 'shloka': 'चन्द्राच्छष्ठसप्तमाष्टमे शुभग्रहैरधियोगः ।\nनृपतिवत् सुखभाग् भवेत् सर्वसम्पद्भाग् ॥ — सारावली'});
      }
    }

    // 15. Kalasarpa Yoga — All planets between Rahu and Ketu
    final rahuRi = ri('ರಾಹು');
    final ketuRi = ri('ಕೇತು');
    if (rahuRi >= 0 && ketuRi >= 0) {
      bool allBetween = true;
      for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
        final pR = ri(p);
        if (pR < 0) continue;
        // Check if planet is between Rahu and Ketu (going clockwise)
        final span = (ketuRi - rahuRi + 12) % 12;
        final pSpan = (pR - rahuRi + 12) % 12;
        if (pSpan > 0 && pSpan < span) continue; // between Rahu→Ketu
        if (pSpan == 0 || pSpan == span) continue; // on Rahu or Ketu
        allBetween = false;
        break;
      }
      if (allBetween) {
        yogas.add({'name': 'ಕಾಲಸರ್ಪ ಯೋಗ', 'desc': 'ಎಲ್ಲ ಗ್ರಹಗಳು ರಾಹು-ಕೇತು ನಡುವೆ — ಅಡಚಣೆ, ವಿಳಂಬ', 'shubha': false, 'shloka': 'राहुकेतुमध्यगताः सर्वग्रहाः कालसर्पयोगकः ।\nविलम्बो विघ्नश्चैव कार्यहानिर्भवेद् ध्रुवम् ॥'});
      }
    }

    // 16. Angarak Yoga — Mars conjunct Rahu
    if (conjunct('ಕುಜ', 'ರಾಹು')) {
      yogas.add({'name': 'ಅಂಗಾರಕ ಯೋಗ', 'desc': 'ಕುಜ-ರಾಹು ಸಂಯೋಗ — ಕ್ರೋಧ, ಅಪಘಾತ ಭಯ', 'shubha': false, 'shloka': 'राहुर्कुजसंयोगे अङ्गारकयोगकः ।\nक्रूरबुद्धिर्विवादी दुर्घटनाभयं भवेत् ॥'});
    }

    // 17. Shani-Mangala Yoga — Saturn conjunct Mars
    if (conjunct('ಶನಿ', 'ಕುಜ')) {
      yogas.add({'name': 'ಶನಿ-ಮಂಗಳ ಯೋಗ', 'desc': 'ಶನಿ-ಕುಜ ಸಂಯೋಗ — ಹಿಂಸೆ, ಜಗಳ, ಕಾರ್ಯ ವಿಘ್ನ', 'shubha': false, 'shloka': 'शनैर्मङ्गलसंयोगे क्रौर्यं हिंसा च जायते ।\nकार्यविघ्नकरो जातो दुःखभाग् भवेन्नरः ॥'});
    }

    // 18. Vasumathi Yoga — Benefics in 3, 6, 10, 11 from Lagna
    if (lagnaRi >= 0) {
      final upachaya = [(lagnaRi + 2) % 12, (lagnaRi + 5) % 12, (lagnaRi + 9) % 12, (lagnaRi + 10) % 12];
      int upCount = 0;
      for (final p in ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ']) {
        if (upachaya.contains(ri(p))) upCount++;
      }
      if (upCount >= 2) {
        yogas.add({'name': 'ವಸುಮತಿ ಯೋಗ', 'desc': 'ಶುಭ ಗ್ರಹ 3/6/10/11ರಲ್ಲಿ — ಸಂಪತ್ತು, ಐಶ್ವರ್ಯ', 'shubha': true, 'shloka': 'उपचयगताः शुभग्रहा वसुमतीयोगः ।\nसम्पद्भाग् भवेज्जातो धनवान् कीर्तिमान् नरः ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 19. Saraswati Yoga — Jupiter, Venus, Mercury in kendra/trikona/2nd
    {
      bool jOk = false, vOk = false, mOk = false;
      for (final p in ['ಗುರು']) {
        final b = bhava(p);
        if ([1,2,4,5,7,9,10].contains(b)) jOk = true;
      }
      for (final p in ['ಶುಕ್ರ']) {
        final b = bhava(p);
        if ([1,2,4,5,7,9,10].contains(b)) vOk = true;
      }
      for (final p in ['ಬುಧ']) {
        final b = bhava(p);
        if ([1,2,4,5,7,9,10].contains(b)) mOk = true;
      }
      if (jOk && vOk && mOk) {
        yogas.add({'name': 'ಸರಸ್ವತಿ ಯೋಗ', 'desc': 'ಗುರು, ಶುಕ್ರ, ಬುಧ ಕೇಂದ್ರ/ತ್ರಿಕೋಣ/2ರಲ್ಲಿ — ವಿದ್ಯೆ, ಕಲೆ', 'shubha': true, 'shloka': 'गुरुशुक्रबुधाः केन्द्रत्रिकोणद्वितीयगाः ।\nसरस्वतीयोगे जातो विद्वान् कलाविदो भवेत् ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 20. Parivartana Yoga — Two planets exchange signs
    final rashiLords = <int, String>{0: 'ಕುಜ', 1: 'ಶುಕ್ರ', 2: 'ಬುಧ', 3: 'ಚಂದ್ರ', 4: 'ರವಿ', 5: 'ಬುಧ', 6: 'ಶುಕ್ರ', 7: 'ಕುಜ', 8: 'ಗುರು', 9: 'ಶನಿ', 10: 'ಶನಿ', 11: 'ಗುರು'};
    bool foundParivartana = false;
    for (final p1 in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
      if (foundParivartana) break;
      final p1Ri = ri(p1);
      if (p1Ri < 0) continue;
      final lordOfP1Rashi = rashiLords[p1Ri];
      if (lordOfP1Rashi == null || lordOfP1Rashi == p1) continue;
      final lordRi = ri(lordOfP1Rashi);
      // Check if lord is in p1's own sign
      final p1OwnSigns = rashiLords.entries.where((e) => e.value == p1).map((e) => e.key).toList();
      if (p1OwnSigns.contains(lordRi)) {
        yogas.add({'name': 'ಪರಿವರ್ತನ ಯೋಗ', 'desc': '$p1 ↔ $lordOfP1Rashi ರಾಶಿ ವಿನಿಮಯ — ಪರಸ್ಪರ ಬಲ', 'shubha': true, 'shloka': 'परस्परक्षेत्रगतौ परिवर्तनयोगकः ।\nउभयोर्बलसम्पन्नो सुखदो भवेन्नरः ॥ — बृ.पा.हो.शा.'});
        foundParivartana = true;
      }
    }

    // 21. Daridra Yoga — Lord of 11th in 6th/8th/12th
    if (lagnaRi >= 0) {
      final lord11Ri = (lagnaRi + 10) % 12;
      final lord11 = rashiLords[lord11Ri];
      if (lord11 != null) {
        final lord11Bhava = bhava(lord11);
        if ([6, 8, 12].contains(lord11Bhava)) {
          yogas.add({'name': 'ದಾರಿದ್ರ ಯೋಗ', 'desc': '11ನೇ ಅಧಿಪತಿ $lord11 ದುಸ್ಥಾನದಲ್ಲಿ — ಧನ ಹಾನಿ', 'shubha': false, 'shloka': 'लाभेशे दुःस्थानगते दारिद्रयोगकः ।\nनिर्धनो दुःखितश्चैव धनहानिर्भवेद् ध्रुवम् ॥ — बृ.पा.हो.शा.'});
        }
      }
    }

    // 22. Raja Yoga — Kendra lord + Trikona lord conjunction
    if (lagnaRi >= 0) {
      final kendraHouses = [0, 3, 6, 9].map((d) => (lagnaRi + d) % 12).toList();
      final trikonaHouses = [0, 4, 8].map((d) => (lagnaRi + d) % 12).toList();
      final kendraLords = kendraHouses.map((h) => rashiLords[h]).whereType<String>().toSet();
      final trikonaLords = trikonaHouses.map((h) => rashiLords[h]).whereType<String>().toSet();
      bool foundRaja = false;
      for (final kl in kendraLords) {
        if (foundRaja) break;
        for (final tl in trikonaLords) {
          if (kl == tl) continue; // same planet
          if (conjunct(kl, tl)) {
            yogas.add({'name': 'ರಾಜಯೋಗ', 'desc': 'ಕೇಂದ್ರಾಧಿಪತಿ $kl + ತ್ರಿಕೋಣಾಧಿಪತಿ $tl ಸಂಯೋಗ — ಅಧಿಕಾರ, ಯಶಸ್ಸು', 'shubha': true, 'shloka': 'केन्द्रत्रिकोणाधिपयोः संयोगे राजयोगकः ।\nअधिकारवान् यशस्वी राजा भवेन्नरः ॥ — बृ.पा.हो.शा.'});
            foundRaja = true;
            break;
          }
        }
      }
    }

    // 23. Viparita Yoga (enhanced) — Lord of 6 in 8 or 12, or lord of 8 in 6 or 12
    // (already partially covered in #9, this adds specific cases)

    // 24. Lakshmi Yoga — Lord of 9th in kendra, strong
    if (lagnaRi >= 0) {
      final ninth = (lagnaRi + 8) % 12;
      final lord9 = rashiLords[ninth];
      if (lord9 != null && inKendraFromLagna(lord9)) {
        yogas.add({'name': 'ಲಕ್ಷ್ಮೀ ಯೋಗ', 'desc': '9ನೇ ಅಧಿಪತಿ $lord9 ಕೇಂದ್ರದಲ್ಲಿ — ಐಶ್ವರ್ಯ, ಭಾಗ್ಯ', 'shubha': true, 'shloka': 'धर्मेशे केन्द्रगते लक्ष्मीयोगः प्रकीर्तितः ।\nऐश्वर्यवान् भाग्यवान् सर्वसम्पद्भाग् भवेत् ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 25. Chandal Yoga — Rahu/Ketu conjunct any planet (except Guru-Chandala already covered)
    for (final shadow in ['ರಾಹು', 'ಕೇತು']) {
      for (final p in ['ಚಂದ್ರ', 'ಕುಜ', 'ಶುಕ್ರ', 'ಶನಿ']) {
        if (conjunct(shadow, p)) {
          yogas.add({'name': 'ಚಂಡಾಲ ಯೋಗ', 'desc': '$shadow-$p ಸಂಯೋಗ — ಅಶುದ್ಧ, ದೋಷ', 'shubha': false, 'shloka': 'राहुकेतुसहग्रहे चाण्डालयोगकः ।\nअशुद्धमना जातो दोषभाग् भवेन्नरः ॥'});
          break;
        }
      }
    }

    // 26. Graha Malika Yoga — 4+ planets in consecutive houses
    if (lagnaRi >= 0) {
      for (int start = 0; start < 12; start++) {
        int chain = 0;
        for (int h = 0; h < 12; h++) {
          final houseRi = (start + h) % 12;
          bool hasPlanet = false;
          for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
            if (ri(p) == houseRi) { hasPlanet = true; break; }
          }
          if (hasPlanet) {
            chain++;
          } else {
            break;
          }
        }
        if (chain >= 4) {
          yogas.add({'name': 'ಗ್ರಹ ಮಾಲಿಕಾ ಯೋಗ', 'desc': '$chain ಗ್ರಹಗಳು ಸತತ ರಾಶಿಗಳಲ್ಲಿ — ರಾಜಯೋಗ ಫಲ', 'shubha': true, 'shloka': 'ग्रहमालिकायोगे सततराशिगताः ग्रहाः ।\nराजयोगफलं लभेत् सर्वसम्पद्भाग् भवेत् ॥ — सारावली'});
          break;
        }
      }
    }

    // 27. Chaturasagara Yoga — Planets in all 4 kendras
    if (lagnaRi >= 0) {
      final k1 = lagnaRi;
      final k4 = (lagnaRi + 3) % 12;
      final k7 = (lagnaRi + 6) % 12;
      final k10 = (lagnaRi + 9) % 12;
      bool has1 = false, has4 = false, has7 = false, has10 = false;
      for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
        final pR = ri(p);
        if (pR == k1) has1 = true;
        if (pR == k4) has4 = true;
        if (pR == k7) has7 = true;
        if (pR == k10) has10 = true;
      }
      if (has1 && has4 && has7 && has10) {
        yogas.add({'name': 'ಚತುರಸಾಗರ ಯೋಗ', 'desc': 'ಎಲ್ಲ ಕೇಂದ್ರಗಳಲ್ಲಿ ಗ್ರಹ — ಮಹಾ ಅಧಿಕಾರ', 'shubha': true, 'shloka': 'चतुर्केन्द्रेषु ग्रहेषु चतुरसागरयोगकः ।\nमहाधिकारवान् राजा सर्वलोकवन्दितः ॥ — सारावली'});
      }
    }

    // 28. Kahala Yoga — 4th lord and Jupiter in mutual kendra
    if (lagnaRi >= 0) {
      final fourth = (lagnaRi + 3) % 12;
      final lord4 = rashiLords[fourth];
      if (lord4 != null && lord4 != 'ಗುರು' && inKendra(lord4, 'ಗುರು')) {
        yogas.add({'name': 'ಕಹಲ ಯೋಗ', 'desc': '4ನೇ ಅಧಿಪತಿ $lord4 - ಗುರು ಪರಸ್ಪರ ಕೇಂದ್ರ — ಧೈರ್ಯ, ಸೈನ್ಯ', 'shubha': true, 'shloka': 'चतुर्थेशगुरुकेन्द्रयोगे कहलयोगकः ।\nधैर्यवान् सैन्यपतिश्च भूपतिः सुखभाग् भवेत् ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 29. Amavasya Yoga — Sun-Moon conjunction
    if (conjunct('ರವಿ', 'ಚಂದ್ರ')) {
      yogas.add({'name': 'ಅಮಾವಾಸ್ಯೆ ಯೋಗ', 'desc': 'ರವಿ-ಚಂದ್ರ ಸಂಯೋಗ — ಮನೋ ದೌರ್ಬಲ್ಯ, ಪಿತೃ ದೋಷ', 'shubha': false, 'shloka': 'रविचन्द्रसंयोगे अमावास्यायोगकः ।\nमनोदौर्बल्यमाप्नोति पितृदोषभवेद् ध्रुवम् ॥'});
    }

    // 30. Ubhayachari Yoga — Planets on both sides of Sun (2nd and 12th from Sun)
    if (sunRi >= 0) {
      final s2 = (sunRi + 1) % 12;
      final s12 = (sunRi + 11) % 12;
      bool hasBefore = false, hasAfter = false;
      for (final p in ['ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
        if (ri(p) == s2) hasAfter = true;
        if (ri(p) == s12) hasBefore = true;
      }
      if (hasBefore && hasAfter) {
        yogas.add({'name': 'ಉಭಯಚಾರಿ ಯೋಗ', 'desc': 'ರವಿಯ ಎರಡೂ ಬದಿ ಗ್ರಹ — ಕೀರ್ತಿ, ಸಮೃದ್ಧಿ', 'shubha': true, 'shloka': 'रवेर्द्वादशद्वितीये ग्रहे उभयचारी ।\nकीर्तिमान् समृद्धश्च सर्वसम्पद्भाग् भवेत् ॥ — फलदीपिका'});
      } else if (hasAfter) {
        yogas.add({'name': 'ವೇಶಿ ಯೋಗ', 'desc': 'ರವಿಯ 2ರಲ್ಲಿ ಗ್ರಹ — ಪರಾಕ್ರಮ', 'shubha': true, 'shloka': 'रवेर्द्वितीये ग्रहे वेशीयोगः प्रकीर्तितः ।\nपराक्रमवान् धनवान् कीर्तिमान् भवेत् ॥ — फलदीपिका'});
      } else if (hasBefore) {
        yogas.add({'name': 'ವೋಶಿ ಯೋಗ', 'desc': 'ರವಿಯ 12ರಲ್ಲಿ ಗ್ರಹ — ದಾನ ಗುಣ', 'shubha': true, 'shloka': 'रवेर्व्यये ग्रहे वोशीयोगः प्रकीर्तितः ।\nदानशीलो गुणवान् सुखभाग् भवेन्नरः ॥ — फलदीपिका'});
      }
    }

    // ═══════════════════════════════════════════
    // VEDIC DRISHTI (ASPECT) HELPER
    // ═══════════════════════════════════════════
    // All planets aspect 7th. Mars: +4,+8. Jupiter: +5,+9. Saturn: +3,+10.
    bool aspects(String planet, int targetRi) {
      final pRi = ri(planet);
      if (pRi < 0) return false;
      final diff = (targetRi - pRi + 12) % 12;
      // All planets aspect 7th
      if (diff == 6) return true;
      // Special aspects
      if (planet == 'ಕುಜ' && (diff == 3 || diff == 7)) return true;  // Mars: 4th & 8th
      if (planet == 'ಗುರು' && (diff == 4 || diff == 8)) return true;  // Jupiter: 5th & 9th
      if (planet == 'ಶನಿ' && (diff == 2 || diff == 9)) return true;  // Saturn: 3rd & 10th
      return false;
    }

    // Helper: is rashi a benefic (saumya) sign?
    // Saumya rashis = owned by benefics (Mercury, Venus, Jupiter, Moon)
    bool isSaumyaRashi(int rashi) {
      return [1, 2, 3, 5, 6, 8, 11].contains(rashi);
      // Taurus(1), Gemini(2), Cancer(3), Virgo(5), Libra(6), Sagittarius(8), Pisces(11)
    }

    // Helper: get navamsha rashi of a planet
    int navamshaRi(String planet) {
      final info = r.planets[planet];
      if (info == null) return -1;
      final deg = info.longitude;
      final rashiIdx = (deg / 30).floor() % 12;
      final posInRashi = deg - (rashiIdx * 30);
      final navPada = (posInRashi / 3.3333).floor() % 9;
      // Navamsha starts from: Fire signs→Aries, Earth→Cap, Air→Libra, Water→Cancer
      final starts = [0, 9, 6, 3]; // Aries, Cap, Libra, Cancer
      final element = rashiIdx % 4;
      return (starts[element] + navPada) % 12;
    }

    // ═══════════════════════════════════════════
    // SHLOKA-BASED YOGAS (Classical Texts)
    // ═══════════════════════════════════════════

    // 31. Sadanta Yoga (सदन्तः) — Brihat Jataka
    // सौम्यर्क्षांशे रविजरुधिरौ चेत्सदन्तोऽत्र जातः
    // Saturn & Mars in benefic rashi/navamsha → good teeth
    if (satRi >= 0 && marsRi >= 0) {
      final satNav = navamshaRi('ಶನಿ');
      final marsNav = navamshaRi('ಕುಜ');
      if ((isSaumyaRashi(satRi) || isSaumyaRashi(satNav)) &&
          (isSaumyaRashi(marsRi) || isSaumyaRashi(marsNav))) {
        yogas.add({'name': 'ಸದಂತ ಯೋಗ', 'desc': 'ಶನಿ-ಕುಜ ಸೌಮ್ಯ ರಾಶಿ/ಅಂಶದಲ್ಲಿ — ಉತ್ತಮ ದಂತ (ಬೃಹತ್ ಜಾತಕ)', 'shubha': true, 'shloka': 'सौम्यर्क्षांशे रविजरुधिरौ चेत्सदन्तोऽत्र जातः । — बृहज्जातक'});
      }
    }

    // 32. Kubja Yoga (कुब्जः) — Brihat Jataka
    // कुब्जः स्वर्क्षे शशिनि तनुगे मन्दमाहेयदृष्टे
    // Moon in own sign in Lagna, aspected by Saturn & Mars → deformity
    if (moonRi == 3 && bhava('ಚಂದ್ರ') == 1) { // Moon in Cancer (own sign) in lagna
      if (aspects('ಶನಿ', moonRi) && aspects('ಕುಜ', moonRi)) {
        yogas.add({'name': 'ಕುಬ್ಜ ಯೋಗ', 'desc': 'ಚಂದ್ರ ಸ್ವಕ್ಷೇತ್ರ ಲಗ್ನದಲ್ಲಿ, ಶನಿ-ಕುಜ ದೃಷ್ಟಿ — ಕುಬ್ಜತೆ (ಬೃಹತ್ ಜಾತಕ)', 'shubha': false, 'shloka': 'कुब्जः स्वर्क्षे शशिनि तनुगे मन्दमाहेयदृष्टे ॥ — बृहज्जातक'});
      }
    }

    // 33. Gaja Yoga — Jupiter in Lagna/Kendra, unafflicted
    if (bhava('ಗುರು') == 1 && !conjunct('ಗುರು', 'ರಾಹು') && !conjunct('ಗುರು', 'ಕೇತು')) {
      yogas.add({'name': 'ಗಜ ಯೋಗ', 'desc': 'ಗುರು ಲಗ್ನದಲ್ಲಿ ಅಪೀಡಿತ — ದೊಡ್ಡ ಶರೀರ, ಗೌರವ', 'shubha': true, 'shloka': 'लग्ने गुरौ अपीडिते गजयोगः प्रकीर्तितः ।\nगजवत् शरीरवान् गौरववान् भवेन्नरः ॥ — बृ.पा.हो.शा.'});
    }

    // 34. Sunapha/Anapha from Lagna — planets in 2nd/12th from Lagna
    {
      final l2 = (lagnaRi + 1) % 12;
      final l12 = (lagnaRi + 11) % 12;
      bool has2 = false, has12 = false;
      for (final p in ['ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
        if (ri(p) == l2) has2 = true;
        if (ri(p) == l12) has12 = true;
      }
      if (has2 && has12) {
        yogas.add({'name': 'ಲಗ್ನ ದುರುಧರ ಯೋಗ', 'desc': 'ಲಗ್ನದ 2 ಮತ್ತು 12ರಲ್ಲಿ ಗ್ರಹ — ಸ್ಥಿರ ಸಂಪತ್ತು', 'shubha': true, 'shloka': 'लग्नाद्द्वादशद्वितीये ग्रहे लग्नदुरुधरो भवेत् ।\nस्थिरसम्पद्भाग् धनवान् सुखी भवेन्नरः ॥'});
      }
    }

    // 35. Hamsa Yoga (specific) — Jupiter in Cancer/Sagittarius/Pisces in Kendra
    if (jupRi >= 0) {
      if ([3, 8, 11].contains(jupRi) && inKendraFromLagna('ಗುರು')) {
        yogas.add({'name': 'ಹಂಸ ಯೋಗ (ವಿಶೇಷ)', 'desc': 'ಗುರು ಉಚ್ಚ/ಸ್ವಕ್ಷೇತ್ರ ಕೇಂದ್ರದಲ್ಲಿ — ಧರ್ಮ, ಜ್ಞಾನ, ಸನ್ಮಾನ', 'shubha': true, 'shloka': 'हंसः कर्कधनुस्वक्षेत्रे केन्द्रस्थिते गुरौ ।\nधर्मज्ञः सन्मानी विद्वान् महापुरुषो भवेत् ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 36. Malavya Yoga (specific) — Venus in Taurus/Libra/Pisces in Kendra
    if (venRi >= 0) {
      if ([1, 6, 11].contains(venRi) && inKendraFromLagna('ಶುಕ್ರ')) {
        yogas.add({'name': 'ಮಾಲವ್ಯ ಯೋಗ (ವಿಶೇಷ)', 'desc': 'ಶುಕ್ರ ಉಚ್ಚ/ಸ್ವಕ್ಷೇತ್ರ ಕೇಂದ್ರದಲ್ಲಿ — ಸೌಂದರ್ಯ, ಸುಖ, ವಾಹನ', 'shubha': true, 'shloka': 'मालव्यः वृषतुलामीनस्वक्षेत्रे केन्द्रस्थिते शुक्रे ।\nसौन्दर्यवान् सुखभाग् वाहनयुतो भवेत् ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 37. Shakata Bhanga — Jupiter in Kendra cancels Shakata Yoga
    if (moonRi >= 0 && jupRi >= 0) {
      final diff = (jupRi - moonRi + 12) % 12;
      if ([5, 7, 11].contains(diff) && inKendraFromLagna('ಗುರು')) {
        yogas.add({'name': 'ಶಕಟ ಭಂಗ ಯೋಗ', 'desc': 'ಗುರು 6/8/12 ಚಂದ್ರನಿಂದ ಆದರೆ ಕೇಂದ್ರದಲ್ಲಿ — ಶಕಟ ನಿವಾರಣೆ', 'shubha': true, 'shloka': 'शकटयोगे गुरौ केन्द्रे शकटभङ्गयोगकः ।\nपूर्वभाग्यमाप्नोति सुखी भवेन्नरः ॥ — फलदीपिका'});
      }
    }

    // 38. Shubha Vargottama — Benefic planet in same sign in rashi & navamsha
    for (final p in ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ']) {
      final pRi = ri(p);
      final pNav = navamshaRi(p);
      if (pRi >= 0 && pRi == pNav) {
        final pName = {'ಗುರು': 'ಗುರು', 'ಶುಕ್ರ': 'ಶುಕ್ರ', 'ಬುಧ': 'ಬುಧ'}[p]!;
        yogas.add({'name': 'ಶುಭ ವರ್ಗೋತ್ತಮ', 'desc': '$pName ವರ್ಗೋತ್ತಮ (ರಾಶಿ=ನವಾಂಶ) — ಅತಿ ಬಲ', 'shubha': true, 'shloka': 'राश्यांशे नवांशे च समराशिगते वर्गोत्तमः ।\nअतिबलवान् शुभग्रहो महाफलप्रदो भवेत् ॥'});
      }
    }

    // 39. Papa Vargottama — Malefic in same sign in rashi & navamsha (stronger malefic)
    for (final p in ['ಕುಜ', 'ಶನಿ']) {
      final pRi = ri(p);
      final pNav = navamshaRi(p);
      if (pRi >= 0 && pRi == pNav) {
        yogas.add({'name': 'ಪಾಪ ವರ್ಗೋತ್ತಮ', 'desc': '$p ವರ್ಗೋತ್ತಮ (ರಾಶಿ=ನವಾಂಶ) — ಪಾಪ ಅತಿಬಲ, ಕಷ್ಟ', 'shubha': false, 'shloka': 'पापग्रहे वर्गोत्तमे पापबलं वर्धते ।\nकष्टभाग् भवेज्जातो दुःखी पीडितो नरः ॥'});
      }
    }

    // 40. Uccha Graha Yoga — Exalted planet in kendra
    final exaltSigns = <String, int>{'ರವಿ': 0, 'ಚಂದ್ರ': 1, 'ಕುಜ': 9, 'ಬುಧ': 5, 'ಗುರು': 3, 'ಶುಕ್ರ': 11, 'ಶನಿ': 6};
    for (final p in exaltSigns.keys) {
      if (ri(p) == exaltSigns[p] && inKendraFromLagna(p)) {
        yogas.add({'name': 'ಉಚ್ಚ ಗ್ರಹ ಯೋಗ', 'desc': '$p ಉಚ್ಚ ರಾಶಿಯಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿ — ಮಹಾ ಶುಭ', 'shubha': true, 'shloka': 'उच्चराशौ केन्द्रस्थिते उच्चग्रहयोगकः ।\nमहाशुभफलं लभेत् सर्वसम्पद्भाग् भवेत् ॥'});
      }
    }

    // 41. Neecha Graha Dosha — Debilitated planet in kendra (without cancellation)
    final debilSigns = <String, int>{'ರವಿ': 6, 'ಚಂದ್ರ': 7, 'ಕುಜ': 3, 'ಬುಧ': 11, 'ಗುರು': 9, 'ಶುಕ್ರ': 5, 'ಶನಿ': 0};
    for (final p in debilSigns.keys) {
      if (ri(p) == debilSigns[p] && inKendraFromLagna(p)) {
        // Check if cancellation exists (lord of debilitation sign aspects)
        final lordOfDebSign = rashiLords[debilSigns[p]!];
        final hasCancellation = lordOfDebSign != null && (aspects(lordOfDebSign, ri(p)) || conjunct(lordOfDebSign, p));
        if (!hasCancellation) {
          yogas.add({'name': 'ನೀಚ ಗ್ರಹ ದೋಷ', 'desc': '$p ನೀಚ ರಾಶಿಯಲ್ಲಿ ಕೇಂದ್ರ — ಕಷ್ಟ, ಅವಮಾನ', 'shubha': false, 'shloka': 'नीचराशौ केन्द्रस्थिते नीचग्रहदोषकः ।\nकष्टभाग् अवमानी दुःखी दुर्भाग्यो भवेत् ॥'});
        }
      }
    }

    // 42. Kendradhipati Dosha — Benefic owning kendra becomes functional malefic
    {
      final kendraRashis = [lagnaRi, (lagnaRi + 3) % 12, (lagnaRi + 6) % 12, (lagnaRi + 9) % 12];
      for (final p in ['ಗುರು', 'ಶುಕ್ರ']) {
        final pRi = ri(p);
        if (pRi < 0) continue;
        // Check if this benefic owns a kendra sign
        final owns = rashiLords.entries.where((e) => e.value == p).map((e) => e.key).toList();
        bool ownsKendra = owns.any((s) => kendraRashis.contains(s));
        if (ownsKendra && inKendraFromLagna(p)) {
          yogas.add({'name': 'ಕೇಂದ್ರಾಧಿಪತಿ ದೋಷ', 'desc': '$p ಶುಭ ಗ್ರಹ ಕೇಂದ್ರಾಧಿಪತಿ — ಶುಭ ಫಲ ಕ್ಷೀಣ', 'shubha': false, 'shloka': 'केन्द्राधिपतिदोषे शुभग्रहः कार्यक्षमो भवेत् ।\nशुभफलक्षीणो भवेत् निष्फलो भवेन्नरः ॥ — बृ.पा.हो.शा.'});
        }
      }
    }

    // 43. Trikona Adhipati Yoga — Lord of 5th/9th in Kendra
    {
      final fifth = (lagnaRi + 4) % 12;
      final ninth = (lagnaRi + 8) % 12;
      final lord5 = rashiLords[fifth];
      final lord9 = rashiLords[ninth];
      if (lord5 != null && inKendraFromLagna(lord5)) {
        yogas.add({'name': 'ತ್ರಿಕೋಣಾಧಿಪತಿ ಯೋಗ', 'desc': '5ನೇ ಅಧಿಪತಿ $lord5 ಕೇಂದ್ರದಲ್ಲಿ — ಪೂರ್ವ ಪುಣ್ಯ ಫಲ', 'shubha': true, 'shloka': 'त्रिकोणाधिपतेः केन्द्रगते पूर्वपुण्यफलं लभेत् ।\nसुखी भाग्यवान् विद्वान् सर्वसम्पद्भाग् भवेत् ॥ — बृ.पा.हो.शा.'});
      }
      if (lord9 != null && lord9 != lord5 && inKendraFromLagna(lord9)) {
        yogas.add({'name': 'ಭಾಗ್ಯಾಧಿಪತಿ ಯೋಗ', 'desc': '9ನೇ ಅಧಿಪತಿ $lord9 ಕೇಂದ್ರದಲ್ಲಿ — ಭಾಗ್ಯ ವೃದ್ಧಿ', 'shubha': true, 'shloka': 'भाग्याधिपतेः केन्द्रगते भाग्यवृद्धिर्भवेत् ।\nधर्मार्थकाममोक्षेषु सर्वसिद्धिर्भवेत् ॥ — बृ.पा.हो.शा.'});
      }
    }

    // 44. Duryoga — Lord of 10th in 6th/8th/12th
    {
      final tenth = (lagnaRi + 9) % 12;
      final lord10 = rashiLords[tenth];
      if (lord10 != null) {
        final b10 = bhava(lord10);
        if ([6, 8, 12].contains(b10)) {
          yogas.add({'name': 'ದುರ್ಯೋಗ', 'desc': '10ನೇ ಅಧಿಪತಿ $lord10 ದುಸ್ಥಾನದಲ್ಲಿ — ವೃತ್ತಿ ಕಷ್ಟ', 'shubha': false, 'shloka': 'कर्मेशे दुःस्थानगते दुर्योगः प्रकीर्तितः ।\nवृत्तिकष्टमाप्नोति दुर्भाग्यो भवेन्नरः ॥ — बृ.पा.हो.शा.'});
        }
      }
    }

    // 45. Graha Yuddha — Two non-luminary planets within 1° (planetary war)
    for (int i = 0; i < 5; i++) {
      for (int j = i + 1; j < 5; j++) {
        final planets5 = ['ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];
        final p1 = r.planets[planets5[i]];
        final p2 = r.planets[planets5[j]];
        if (p1 == null || p2 == null) continue;
        final diff = (p1.longitude - p2.longitude).abs();
        if (diff < 1.0 || diff > 359.0) {
          yogas.add({'name': 'ಗ್ರಹ ಯುದ್ಧ', 'desc': '${planets5[i]} - ${planets5[j]} ಒಂದು ಅಂಶದಲ್ಲಿ — ಸಂಘರ್ಷ', 'shubha': false, 'shloka': 'ग्रहयुद्धे समीपस्थितौ ग्रहौ संघर्षफलदौ ।\nदुर्बलो पराजितो भवेत् बलवान् जयी भवेत् ॥ — सारावली'});
        }
      }
    }

    return yogas;
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  Widget _tableHeader(List<String> cols) {
    return Container(
      color: kPurple2.withOpacity(0.12),
      child: Row(
        children: cols.map((c) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(c, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: kText)),
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
        Expanded(child: Text(v, style: const TextStyle())),
      ]),
    );
  }
}
