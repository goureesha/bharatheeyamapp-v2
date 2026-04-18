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

    // Column headers
    const hGraha = 'ಗ್ರಹ';
    const hD3 = 'ದ್ರೇಕ್';
    const hD2 = 'ಹೋರ';
    const hD9 = 'ನ';
    const hD30 = 'ತ್ರಿಶಾಂಸ';
    const hD12 = 'ದ್ವಾಧ';
    const hKshetra = 'ಕ್ಷೇಕ್';

    String getRashiLord(String rashiNameKn) {
      int idx = knRashi.indexOf(rashiNameKn);
      if (idx < 0) return rashiNameKn;
      switch (idx) {
        case 0: return 'ಕುಜ';
        case 1: return 'ಶುಕ್ರ';
        case 2: return 'ಬುಧ';
        case 3: return 'ಚಂ';
        case 4: return 'ಸೂ';
        case 5: return 'ಬುಧ';
        case 6: return 'ಶುಕ್ರ';
        case 7: return 'ಕುಜ';
        case 8: return 'ಗುರು';
        case 9: return 'ಶ';
        case 10: return 'ಶ';
        case 11: return 'ಗುರು';
      }
      return '';
    }

    int rowIdx = 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Title
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
                          fontWeight: FontWeight.w900, fontSize: 13, color: kPurple2,
                        )),
                      ),
                    ).toList(),
                  ),
                  // Data rows
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
                        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                          displayName, textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: kTeal),
                        )),
                        ...[details['d3'], details['d2'], details['d9'], details['d30'], details['d12'], details['d1']].map((v) =>
                          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
                            getRashiLord(v as String), textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText),
                          )),
                        ),
                      ],
                    );
                  }),
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
    final yogas = _detectYogas();
    if (yogas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: Center(child: Text('ಯೋಗಗಳು ಕಂಡುಬಂದಿಲ್ಲ', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600))),
        ),
      );
    }

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
                Text('ಯೋಗಗಳು', style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: kTeal,
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${yogas.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kTeal)),
                ),
              ],
            ),
          ),
          // Yoga list
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
              children: yogas.asMap().entries.map((entry) {
                final y = entry.value;
                final isEven = entry.key % 2 == 0;
                final isShubha = y['shubha'] == true;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isEven ? kBg.withOpacity(0.4) : kCard,
                    border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.5))),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isShubha ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 16,
                        color: isShubha ? const Color(0xFF2F855A) : const Color(0xFFE53E3E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(y['name'] as String, style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 13,
                              color: isShubha ? const Color(0xFF2F855A) : const Color(0xFFE53E3E),
                            )),
                            const SizedBox(height: 2),
                            Text(y['desc'] as String, style: TextStyle(
                              fontSize: 11, color: kMuted, fontWeight: FontWeight.w600,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _detectYogas() {
    final r = _result;
    final yogas = <Map<String, dynamic>>[];

    // Helper: get rashi index of a planet
    int ri(String p) {
      final info = r.planets[p];
      return info != null ? (info.longitude / 30).floor() % 12 : -1;
    }

    // Helper: get bhava of a planet (1-12)
    int bhava(String p) {
      final info = r.planets[p];
      if (info == null) return -1;
      final lagnaRi = ri('ಲಗ್ನ');
      final pRi = (info.longitude / 30).floor() % 12;
      return ((pRi - lagnaRi + 12) % 12) + 1;
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

    // Helper: is planet in kendra from lagna?
    bool inKendraFromLagna(String p) {
      final b = bhava(p);
      return [1, 4, 7, 10].contains(b);
    }

    // Helper: is planet in trikona from lagna?
    bool inTrikonaFromLagna(String p) {
      final b = bhava(p);
      return [1, 5, 9].contains(b);
    }

    final lagnaRi = ri('ಲಗ್ನ');
    final moonRi = ri('ಚಂದ್ರ');
    final sunRi = ri('ರವಿ');
    final marsRi = ri('ಕುಜ');
    final mercRi = ri('ಬುಧ');
    final jupRi = ri('ಗುರು');
    final venRi = ri('ಶುಕ್ರ');
    final satRi = ri('ಶನಿ');

    // 1. Gaja Kesari Yoga — Jupiter in kendra from Moon
    if (inKendra('ಚಂದ್ರ', 'ಗುರು')) {
      yogas.add({'name': 'ಗಜ ಕೇಸರಿ ಯೋಗ', 'desc': 'ಗುರು ಚಂದ್ರನಿಂದ ಕೇಂದ್ರದಲ್ಲಿ — ಕೀರ್ತಿ, ಬುದ್ಧಿ, ಸಂಪತ್ತು', 'shubha': true});
    }

    // 2. Chandra-Mangala Yoga — Moon conjunct Mars
    if (conjunct('ಚಂದ್ರ', 'ಕುಜ')) {
      yogas.add({'name': 'ಚಂದ್ರ-ಮಂಗಳ ಯೋಗ', 'desc': 'ಚಂದ್ರ-ಕುಜ ಸಂಯೋಗ — ಧನ ಲಾಭ, ಸಾಹಸ', 'shubha': true});
    }

    // 3. Budha-Aditya Yoga — Sun conjunct Mercury
    if (conjunct('ರವಿ', 'ಬುಧ')) {
      yogas.add({'name': 'ಬುಧ-ಆದಿತ್ಯ ಯೋಗ', 'desc': 'ರವಿ-ಬುಧ ಸಂಯೋಗ — ಬುದ್ಧಿ, ವಾಕ್ಪಟುತ್ವ', 'shubha': true});
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
        });
      }
    }

    // 5. Amala Yoga — Benefic in 10th from lagna
    for (final p in ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ']) {
      if (bhava(p) == 10) {
        yogas.add({'name': 'ಅಮಲ ಯೋಗ', 'desc': '$p 10ನೇ ಭಾವದಲ್ಲಿ — ಕೀರ್ತಿ, ಶುಭ ಕರ್ಮ', 'shubha': true});
        break;
      }
    }

    // 6. Dhana Yoga — Lord of 2nd/11th in kendra/trikona
    for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ']) {
      final b = bhava(p);
      if ((b == 2 || b == 11) && (inKendraFromLagna(p) || inTrikonaFromLagna(p))) {
        yogas.add({'name': 'ಧನ ಯೋಗ', 'desc': '$p 2/11ನೇ ಭಾವಾಧಿಪತಿ ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿ', 'shubha': true});
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
        yogas.add({'name': 'ಕೇಮದ್ರುಮ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 2/12ರಲ್ಲಿ ಯಾವ ಗ್ರಹವೂ ಇಲ್ಲ — ಕಷ್ಟ, ಬಡತನ', 'shubha': false});
      }
    }

    // 8. Shakata Yoga — Jupiter 6th/8th/12th from Moon
    if (moonRi >= 0 && jupRi >= 0) {
      final diff = (jupRi - moonRi + 12) % 12;
      if ([5, 7, 11].contains(diff)) {
        yogas.add({'name': 'ಶಕಟ ಯೋಗ', 'desc': 'ಗುರು ಚಂದ್ರನಿಂದ 6/8/12ರಲ್ಲಿ — ಅಸ್ಥಿರ ಭಾಗ್ಯ', 'shubha': false});
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
            yogas.add({'name': 'ವಿಪರೀತ ರಾಜಯೋಗ', 'desc': '$p + $p2 ದುಸ್ಥಾನದಲ್ಲಿ ಸಂಯೋಗ — ಕಷ್ಟದಿಂದ ಲಾಭ', 'shubha': true});
            break;
          }
        }
        break;
      }
    }

    // 10. Guru-Chandala Yoga — Jupiter conjunct Rahu
    if (conjunct('ಗುರು', 'ರಾಹು')) {
      yogas.add({'name': 'ಗುರು-ಚಾಂಡಾಲ ಯೋಗ', 'desc': 'ಗುರು-ರಾಹು ಸಂಯೋಗ — ಧರ್ಮ ಹಾನಿ, ಭ್ರಷ್ಟ ಬುದ್ಧಿ', 'shubha': false});
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
        yogas.add({'name': 'ದುರುಧರ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 2 ಮತ್ತು 12ರಲ್ಲಿ ಗ್ರಹ — ಧನವಂತ', 'shubha': true});
      } else if (has2) {
        yogas.add({'name': 'ಸುನಫ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 2ರಲ್ಲಿ ಗ್ರಹ — ಸ್ವಯಂ ಸಂಪಾದನೆ', 'shubha': true});
      } else if (has12) {
        yogas.add({'name': 'ಅನಫ ಯೋಗ', 'desc': 'ಚಂದ್ರನ 12ರಲ್ಲಿ ಗ್ರಹ — ಪೂರ್ವ ಪುಣ್ಯ', 'shubha': true});
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
        yogas.add({'name': 'ಶುಭ ಕರ್ತರಿ ಯೋಗ', 'desc': 'ಲಗ್ನದ 2/12ರಲ್ಲಿ ಶುಭ ಗ್ರಹ — ರಕ್ಷಣೆ, ಶುಭ', 'shubha': true});
      }
      // Papa Kartari
      final malefics = ['ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];
      bool mal2 = false, mal12 = false;
      for (final p in malefics) {
        if (ri(p) == l2) mal2 = true;
        if (ri(p) == l12) mal12 = true;
      }
      if (mal2 && mal12) {
        yogas.add({'name': 'ಪಾಪ ಕರ್ತರಿ ಯೋಗ', 'desc': 'ಲಗ್ನದ 2/12ರಲ್ಲಿ ಪಾಪ ಗ್ರಹ — ಅಡಚಣೆ, ಕಷ್ಟ', 'shubha': false});
      }
    }

    // 13. Neecha Bhanga Raja Yoga — debilitated planet with cancellation
    final debil = <String, int>{'ರವಿ': 6, 'ಚಂದ್ರ': 7, 'ಕುಜ': 3, 'ಬುಧ': 11, 'ಗುರು': 9, 'ಶುಕ್ರ': 5, 'ಶನಿ': 0};
    final exalt = <String, int>{'ರವಿ': 0, 'ಚಂದ್ರ': 1, 'ಕುಜ': 9, 'ಬುಧ': 5, 'ಗುರು': 3, 'ಶುಕ್ರ': 11, 'ಶನಿ': 6};
    for (final p in debil.keys) {
      if (ri(p) == debil[p] && inKendraFromLagna(p)) {
        yogas.add({'name': 'ನೀಚ ಭಂಗ ರಾಜಯೋಗ', 'desc': '$p ನೀಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿ — ನೀಚ ಭಂಗ', 'shubha': true});
        break;
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
