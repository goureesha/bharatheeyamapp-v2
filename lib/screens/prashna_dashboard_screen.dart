import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../core/calculator.dart';
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

class _PrashnaDashboardScreenState extends State<PrashnaDashboardScreen> {
  String? _bhavaPlanet; // selected planet for bhava reference

  void _showPlanetDetail(String planetName) {
    final info = widget.result.planets[planetName];
    if (info == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: kBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlanetDetailSheet(info: info, result: widget.result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isLargeScreen = screenWidth > 600 || isLandscape;

    // Chart size: make it large enough to fit the outer labels
    final chartSize = isLargeScreen
        ? (screenWidth * 0.45).clamp(350.0, 550.0)
        : screenWidth * 0.92;
    final textScale = isLargeScreen ? (chartSize / 350.0).clamp(1.1, 1.4) : 1.0;

    final dateStr = '${widget.dob.day.toString().padLeft(2, '0')}/'
        '${widget.dob.month.toString().padLeft(2, '0')}/'
        '${widget.dob.year}';
    final timeStr = '${widget.hour}:${widget.minute.toString().padLeft(2, '0')} ${widget.ampm}';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ಪ್ರಶ್ನ ಕುಂಡಲಿ',
            style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w900)),
        iconTheme: IconThemeData(color: kText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Info header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name.isNotEmpty ? widget.name : 'ಪ್ರಶ್ನ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kPurple2)),
                    const SizedBox(height: 4),
                    Text('$dateStr  $timeStr  •  ${widget.place}',
                        style: TextStyle(fontSize: 13, color: kMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Rashi Kundali ──
            _chartSection(
              label: 'ರಾಶಿ ಕುಂಡಲಿ',
              isBhava: false,
              chartSize: chartSize,
              textScale: textScale,
            ),
            const SizedBox(height: 16),

            // ── Bhava reference buttons ──
            _buildBhavaControls(),
            const SizedBox(height: 8),

            // ── Bhava Kundali ──
            _chartSection(
              label: _bhavaPlanet != null
                  ? 'ಭಾವ ಕುಂಡಲಿ (${_bhavaPlanet!} ಕೇಂದ್ರ)'
                  : 'ಭಾವ ಕುಂಡಲಿ',
              isBhava: true,
              chartSize: chartSize,
              textScale: textScale,
            ),
            const SizedBox(height: 24),
          ],
        ),
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
            result: widget.result,
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
                // Lagna (default)
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
}
