import 'package:flutter/material.dart';
import '../core/calculator.dart';

import '../core/graha_phala.dart';
import '../core/bhava_phala.dart';
import '../core/yoga_phala.dart';
import '../constants/strings.dart';
import '../widgets/common.dart';
import '../widgets/prashna_chart.dart';
import '../widgets/planet_detail_sheet.dart';
import '../widgets/dasha_widget.dart';
import '../services/storage_service.dart';
import '../services/backup_service.dart';

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
  int _selectedBook = 0; // 0 = Brihat Jataka, 1 = Saravali
  String? _selectedGraha; // null = show all planets
  String _bhavaLagnaMode = 'ಲಗ್ನ'; // lagna selector for bhava phala
  bool _yogaNavamsha = false;
  bool _yogaDvadashamsha = false;



  static const _tabs = ['ಕುಂಡಲಿ', 'ಸ್ಫುಟ', 'ಪಂಚಾಂಗ', 'ಷಡ್ವರ್ಗ', 'ದಶಾ'];

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

  Future<void> _savePrashna() async {
    // Build a name with date/time for easy identification
    final dateStr = '${_dob.day.toString().padLeft(2, "0")}/${_dob.month.toString().padLeft(2, "0")}/${_dob.year}';
    final timeStr = '$_hour:${_minute.toString().padLeft(2, "0")} $_ampm';
    final defaultName = widget.name.isNotEmpty
        ? widget.name
        : 'ಪ್ರಶ್ನ $dateStr $timeStr';

    // Ask user for a name
    final controller = TextEditingController(text: defaultName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kCard,
        title: Text('ಪ್ರಶ್ನ ಉಳಿಸಿ', style: TextStyle(color: kText, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: kText),
          decoration: InputDecoration(
            hintText: 'ಹೆಸರು ನಮೂದಿಸಿ',
            hintStyle: TextStyle(color: kMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: kPurple2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ರದ್ದು', style: TextStyle(color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPurple2),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('ಉಳಿಸಿ'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !mounted) return;

    final profile = Profile(
      name: name,
      date: '${_dob.year}-${_dob.month.toString().padLeft(2, "0")}-${_dob.day.toString().padLeft(2, "0")}',
      hour: _hour,
      minute: _minute,
      ampm: _ampm,
      lat: widget.lat,
      lon: widget.lon,
      place: widget.place,
    );
    await StorageService.save(profile);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "$name" ಉಳಿಸಲಾಗಿದೆ'),
        backgroundColor: kTeal,
      ),
    );
  }

  Future<void> _backupData() async {
    final success = await BackupService.exportData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '✅ ಬ್ಯಾಕಪ್ ಯಶಸ್ವಿ'
            : '❌ ಬ್ಯಾಕಪ್ ವಿಫಲ'),
        backgroundColor: success ? kTeal : Colors.red,
      ),
    );
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
        actions: [
          IconButton(
            icon: Icon(Icons.save_outlined, color: kPurple2),
            tooltip: 'ಉಳಿಸಿ',
            onPressed: _savePrashna,
          ),
          IconButton(
            icon: Icon(Icons.backup_outlined, color: kTeal),
            tooltip: 'ಬ್ಯಾಕಪ್',
            onPressed: _backupData,
          ),
        ],
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
                _buildDashaTab(),
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
          const SizedBox(height: 24),

          // ── Rashi Phala Section ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildGrahaPhalas(_result),
                ..._buildBhavaPhalas(_result),
                ..._buildChandraRashiPhala(_result),
                ..._buildYogaSection(_result),
              ],
            ),
          ),
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
  // TAB 5: DASHA
  // ═══════════════════════════════════════════
  Widget _buildDashaTab() {
    final r = _result;
    final pan = r.panchang;
    final now = DateTime.now();

    // Find current running Mahadasha, Bhukti, Pratyantara
    String currentMD = '', mdEnd = '';
    String currentAD = '', adEnd = '';
    String currentPD = '', pdEnd = '';
    for (final md in r.dashas) {
      if (now.isAfter(md.start) && now.isBefore(md.end)) {
        currentMD = md.lord;
        mdEnd = '${md.end.day.toString().padLeft(2, "0")}-${md.end.month.toString().padLeft(2, "0")}-${md.end.year}';
        for (final ad in md.antardashas) {
          if (now.isAfter(ad.start) && now.isBefore(ad.end)) {
            currentAD = ad.lord;
            adEnd = '${ad.end.day.toString().padLeft(2, "0")}-${ad.end.month.toString().padLeft(2, "0")}-${ad.end.year}';
            for (final pd in ad.antardashas) {
              if (now.isAfter(pd.start) && now.isBefore(pd.end)) {
                currentPD = pd.lord;
                pdEnd = '${pd.end.day.toString().padLeft(2, "0")}-${pd.end.month.toString().padLeft(2, "0")}-${pd.end.year}';
                break;
              }
            }
            break;
          }
        }
        break;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dasha balance info
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome, color: kOrange, size: 18),
                  const SizedBox(width: 6),
                  Text('ದಶಾ ಶೇಷ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kOrange)),
                ]),
                const SizedBox(height: 8),
                _dashaInfoRow('ಜನನ ದಶಾ ನಾಥ', pan.dashaLord),
                _dashaInfoRow('ದಶಾ ಶೇಷ', pan.dashaBalance),
                if (currentMD.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(children: [
                    Icon(Icons.timeline, color: kPurple2, size: 18),
                    const SizedBox(width: 6),
                    Text('ಪ್ರಸ್ತುತ ದಶಾ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kPurple2)),
                  ]),
                  const SizedBox(height: 8),
                  _dashaInfoRow('ಮಹಾದಶಾ', '$currentMD  →  $mdEnd'),
                  if (currentAD.isNotEmpty)
                    _dashaInfoRow('ಅಂತರ್ದಶಾ', '$currentAD  →  $adEnd'),
                  if (currentPD.isNotEmpty)
                    _dashaInfoRow('ಪ್ರತ್ಯಂತರ', '$currentPD  →  $pdEnd'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Full Dasha widget (expandable tree)
          DashaWidget(dashas: r.dashas),
        ],
      ),
    );
  }

  Widget _dashaInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kMuted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kText)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HELPER: planet bhava from cusp boundaries
  // ═══════════════════════════════════════════
  int _planetBhavaNum(double planetLon, List<double> madhyas) {
    // Calculate boundaries (sandhi) between adjacent bhava madhyas
    List<double> boundaries = List.filled(12, 0.0);
    for (int i = 0; i < 12; i++) {
      final m1 = madhyas[i];
      final m2 = madhyas[(i + 1) % 12];
      double diff = (m2 - m1 + 360.0) % 360.0;
      boundaries[i] = (m1 + (diff / 2.0)) % 360.0;
    }
    int bhavaIdx = 0;
    for (int i = 0; i < 12; i++) {
      final start = boundaries[(i + 11) % 12];
      final end = boundaries[i];
      if (start < end) {
        if (planetLon >= start && planetLon < end) { bhavaIdx = i; break; }
      } else {
        if (planetLon >= start || planetLon < end) { bhavaIdx = i; break; }
      }
    }
    return bhavaIdx + 1; // 1-based bhava number
  }

  // ═══════════════════════════════════════════
  // BHAVA PHALA CARDS (below Graha Phala)
  // ═══════════════════════════════════════════
  List<Widget> _buildBhavaPhalas(KundaliResult r) {
    const planetNames = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];
    if (r.bhavas.isEmpty) return [];

    // Lagna options: main lagna + planet lagnas + 12 rashis
    final lagnaOptions = ['ಲಗ್ನ', ...planetNames, ...knRashi];
    final lagnaLon = r.planets['ಲಗ್ನ']?.longitude ?? (r.bhavas.isNotEmpty ? r.bhavas[0] : 0.0);
    final lagnaIdx = (lagnaLon / 30).floor() % 12;

    // Compute bhava madhyas based on lagna selection
    List<double> madhyas;
    int displayLagnaIdx;
    if (_bhavaLagnaMode == 'ಲಗ್ನ') {
      madhyas = r.bhavas;
      displayLagnaIdx = lagnaIdx;
    } else if (planetNames.contains(_bhavaLagnaMode)) {
      // Planet lagna: shift bhava cusps by offset
      final refLon = r.planets[_bhavaLagnaMode]?.longitude ?? 0.0;
      final offset = (refLon - lagnaLon + 360.0) % 360.0;
      madhyas = List.generate(12, (i) => (r.bhavas[i] + offset) % 360.0);
      displayLagnaIdx = (refLon / 30).floor() % 12;
    } else {
      // Rashi lagna: shift bhava cusps to that rashi
      final rashiIdx = knRashi.indexOf(_bhavaLagnaMode);
      final refLon = (rashiIdx < 0 ? 0 : rashiIdx) * 30.0;
      final offset = (refLon - lagnaLon + 360.0) % 360.0;
      madhyas = List.generate(12, (i) => (r.bhavas[i] + offset) % 360.0);
      displayLagnaIdx = rashiIdx < 0 ? 0 : rashiIdx;
    }

    return [
      const SizedBox(height: 8),
      AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: false,
          title: Text('ಭಾವ ಫಲ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
          subtitle: Text('ಚಮತ್ಕಾರ ಚಿಂತಾಮಣಿ', style: TextStyle(fontSize: 10, color: kMuted)),
          children: [
            // Lagna selector
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: lagnaOptions.map((opt) {
                final sel = _bhavaLagnaMode == opt;
                return GestureDetector(
                  onTap: () => setState(() => _bhavaLagnaMode = opt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? kTeal : kTeal.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: sel ? kTeal : kBorder),
                    ),
                    child: Text(opt,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                          color: sel ? Colors.white : kText,
                        )),
                  ),
                );
              }).toList(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('ಲಗ್ನ ರಾಶಿ: ${knRashi[displayLagnaIdx]}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTeal)),
            ),
            // Planet bhava phala cards
            ...planetNames.map((planet) {
              final pInfo = r.planets[planet];
              if (pInfo == null) return const SizedBox.shrink();
              final bhava = _planetBhavaNum(pInfo.longitude, madhyas);
              final pRashiIdx = (pInfo.longitude / 30).floor() % 12;
              final shloka = BhavaPhala.getPhala(planet, bhava);
              if (shloka.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kTeal.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kTeal.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(planet, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kPurple2)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: kTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('ಭಾವ $bhava • ${knRashi[pRashiIdx]}',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kTeal)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    // Chamatkara Chintamani shloka
                    Text(shloka,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText, height: 1.6)),
                    // Common bhava phala shlokas
                    ...BhavaPhala.getCommonPhala(bhava).map((cs) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(cs,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kMuted, height: 1.5)),
                    )),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════
  // YOGA SECTION
  // ═══════════════════════════════════════════
  List<Widget> _buildYogaSection(KundaliResult r) {
    final yogas = YogaPhala.evaluate(r, navamsha: _yogaNavamsha, dvadashamsha: _yogaDvadashamsha);
    if (yogas.isEmpty) return [];

    return [
      const SizedBox(height: 8),
      AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: false,
          title: Text('ಯೋಗ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
          subtitle: Text('ಬೃಹಜ್ಜಾತಕ • ${yogas.length} ಯೋಗಗಳು', style: TextStyle(fontSize: 10, color: kMuted)),
          children: [
            // ── Toggle buttons ──
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _yogaChip('ನವಾಂಶ (D9)', _yogaNavamsha, (v) => setState(() => _yogaNavamsha = v)),
                  const SizedBox(width: 8),
                  _yogaChip('ದ್ವಾದಶಾಂಶ (D12)', _yogaDvadashamsha, (v) => setState(() => _yogaDvadashamsha = v)),
                ],
              ),
            ),
            // ── Yoga cards ──
            ...yogas.map((y) {
              final isDiv = y.chart != 'ರಾಶಿ';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDiv ? Colors.deepPurple.withOpacity(0.04) : kOrange.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDiv ? Colors.deepPurple.withOpacity(0.2) : kOrange.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(y.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isDiv ? Colors.deepPurple : kOrange)),
                        ),
                        if (isDiv)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(y.chart, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(y.shloka,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText, height: 1.6)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }

  Widget _yogaChip(String label, bool selected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? kOrange.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? kOrange : kMuted.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? kOrange : kMuted)),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CHANDRA RASHI PHALA
  // ═══════════════════════════════════════════
  List<Widget> _buildChandraRashiPhala(KundaliResult r) {
    final moonInfo = r.planets['ಚಂದ್ರ'];
    if (moonInfo == null) return [];
    final moonRashiIdx = (moonInfo.longitude / 30).floor() % 12;
    final moonRashi = knRashi[moonRashiIdx];
    final shloka = BhavaPhala.getChandraRashiPhala(moonRashi);
    if (shloka.isEmpty) return [];

    return [
      const SizedBox(height: 8),
      AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: false,
          title: Text('ಚಂದ್ರ ರಾಶಿ ಫಲ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
          subtitle: Text('ಚಂದ್ರ ರಾಶಿ: $moonRashi', style: TextStyle(fontSize: 10, color: kMuted)),
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF90CAF9).withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF90CAF9).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('ಚಂದ್ರ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF90CAF9))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF90CAF9).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(moonRashi,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0))),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(shloka,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kText, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // ═══════════════════════════════════════════
  // GRAHA PHALA CARDS
  // ═══════════════════════════════════════════
  List<Widget> _buildGrahaPhalas(KundaliResult r) {
    final phalas = GrahaPhala.generate(r);
    if (phalas.isEmpty) return [];
    const planetColors = {
      'ರವಿ': Color(0xFFE65100),
      'ಚಂದ್ರ': Color(0xFF90CAF9),
      'ಕುಜ': Color(0xFFD32F2F),
      'ಬುಧ': Color(0xFF388E3C),
      'ಗುರು': Color(0xFFFFA000),
      'ಶುಕ್ರ': Color(0xFFEC407A),
      'ಶನಿ': Color(0xFF5C6BC0),
    };
    const bookNames = ['ಬೃಹತ್ ಜಾತಕ', 'ಸಾರಾವಳಿ'];
    return [
      AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: false,
          title: Text('ಗ್ರಹ ಫಲ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kText)),
          subtitle: Text('ರಾಶಿ · ನವಾಂಶ · ದ್ವಾದಶಾಂಶ · ದ್ರೇಕ್ಕಾಣ', style: TextStyle(fontSize: 10, color: kMuted)),
          children: [
            // ── Book Switcher ──
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: List.generate(bookNames.length, (i) {
                  final sel = _selectedBook == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(bookNames[i], style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : kPurple2,
                      )),
                      selected: sel,
                      selectedColor: kPurple2,
                      backgroundColor: kPurple2.withOpacity(0.08),
                      side: BorderSide(color: sel ? kPurple2 : kPurple2.withOpacity(0.3)),
                      onSelected: (_) => setState(() => _selectedBook = i),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),
              ),
            ),
            // ── Planet Selector ──
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _grahaChip(null, 'ಎಲ್ಲಾ', kTeal),
                  ...phalas.map((gp) => _grahaChip(gp.planet, gp.planet, planetColors[gp.planet] ?? kTeal)),
                ],
              ),
            ),
            // ── Planet Phalas ──
            ...phalas.where((gp) => _selectedGraha == null || gp.planet == _selectedGraha).map((gp) {
              final pColor = planetColors[gp.planet] ?? kTeal;
              final rashiPhalaText = _selectedBook == 0 ? gp.rashiShloka : gp.saravaliRashiPhala;
              final shlokaText = _selectedBook == 0 ? '' : '';
              final navPhalaText = _selectedBook == 0 ? gp.navamshaShloka : gp.saravaliNavamshaPhala;
              final dvadPhalaText = _selectedBook == 0 ? gp.dvadamshaShloka : gp.saravaliDvadashamshaPhala;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: pColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Planet name header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: pColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(gp.planet, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: pColor)),
                      ),
                      const SizedBox(width: 8),
                      Text(gp.rashi, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kText)),
                    ]),
                    const SizedBox(height: 8),
                    // Phala rows
                    _phalaRow('ರಾಶಿ ಫಲ', gp.rashi, rashiPhalaText, pColor),
                    _phalaRow('ನವಾಂಶ ಫಲ', gp.navamshaRashi, navPhalaText, pColor),
                    _phalaRow('ದ್ವಾದಶಾಂಶ ಫಲ', gp.dvadamshaRashi, dvadPhalaText, pColor),
                    _phalaRow('ದ್ರೇಕ್ಕಾಣ ಫಲ', gp.drekkanaRashi, gp.drekkanaPhala, pColor),
                    _phalaRow('D9 ದ್ರೇಕ್ಕಾಣ', gp.d9DrekkanaRashi, gp.d9DrekkanaPhala, pColor),
                    _phalaRow('D12 ದ್ರೇಕ್ಕಾಣ', gp.d12DrekkanaRashi, gp.d12DrekkanaPhala, pColor),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ];
  }

  Widget _grahaChip(String? value, String label, Color color) {
    final sel = _selectedGraha == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGraha = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? color : color.withOpacity(0.3)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: sel ? Colors.white : color,
        )),
      ),
    );
  }

  Widget _phalaRow(String label, String rashi, String phala, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
          ),
          SizedBox(
            width: 50,
            child: Text(rashi, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kMuted)),
          ),
          Expanded(
            child: Text(phala, style: TextStyle(fontSize: 10, color: kText)),
          ),
        ],
      ),
    );
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
