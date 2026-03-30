import 'package:flutter/material.dart';
import '../core/ashtakavarga.dart';
import '../core/calculator.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';

class AshtakaVargaWidget extends StatefulWidget {
  final KundaliResult result;
  const AshtakaVargaWidget({super.key, required this.result});

  @override
  State<AshtakaVargaWidget> createState() => _AshtakaVargaWidgetState();
}

class _AshtakaVargaWidgetState extends State<AshtakaVargaWidget> {
  late Map<String, List<int>> _avData;
  String _selectedPlanet = 'SAV';

  @override
  void initState() {
    super.initState();
    _computeAV();
  }

  void _computeAV() {
    final rashiPos = <String, int>{};
    for (final entry in widget.result.planets.entries) {
      rashiPos[entry.key] = entry.value.rashiIndex;
    }
    _avData = AshtakaVarga.computeAll(rashiPos);
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = _avData[_selectedPlanet] ?? List.filled(12, 0);
    final total = selectedData.reduce((a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: ResponsiveCenter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planet selector chips
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('SAV', tr('ಸರ್ವಾಷ್ಟಕ')),
                  ...AshtakaVarga.planets.map((p) => _chip(p, p)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // South Indian style Kundali chart with bindus
            _buildAVKundaliChart(selectedData, total),

            const SizedBox(height: 8),

            // Bar chart visualization
            _buildBarChart(selectedData),

            // SAV summary table
            if (_selectedPlanet == 'SAV') ...[
              const SizedBox(height: 8),
              _buildSAVSummaryTable(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String key, String label) {
    final isSelected = _selectedPlanet == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedPlanet = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? kPurple2 : kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? kPurple2 : kBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : kText,
            ),
          ),
        ),
      ),
    );
  }

  // ─── South Indian 4×4 Kundali Chart ───────────────────────
  Widget _buildAVKundaliChart(List<int> data, int total) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dim = constraints.maxWidth;
            final cw = dim / 4;
            return Stack(
              children: [
                // Top Row: Meena(11), Mesha(0), Vrishabha(1), Mithuna(2)
                Positioned(top: 0, left: 0, width: cw, height: cw, child: _rashiBox(11, data[11])),
                Positioned(top: 0, left: cw, width: cw, height: cw, child: _rashiBox(0, data[0])),
                Positioned(top: 0, left: cw*2, width: cw, height: cw, child: _rashiBox(1, data[1])),
                Positioned(top: 0, left: cw*3, width: cw, height: cw, child: _rashiBox(2, data[2])),
                // Right Col: Kataka(3), Simha(4)
                Positioned(top: cw, left: cw*3, width: cw, height: cw, child: _rashiBox(3, data[3])),
                Positioned(top: cw*2, left: cw*3, width: cw, height: cw, child: _rashiBox(4, data[4])),
                // Bottom Row: Kanya(5), Tula(6), Vrischika(7), Dhanu(8)
                Positioned(top: cw*3, left: cw*3, width: cw, height: cw, child: _rashiBox(5, data[5])),
                Positioned(top: cw*3, left: cw*2, width: cw, height: cw, child: _rashiBox(6, data[6])),
                Positioned(top: cw*3, left: cw, width: cw, height: cw, child: _rashiBox(7, data[7])),
                Positioned(top: cw*3, left: 0, width: cw, height: cw, child: _rashiBox(8, data[8])),
                // Left Col: Makara(9), Kumbha(10)
                Positioned(top: cw*2, left: 0, width: cw, height: cw, child: _rashiBox(9, data[9])),
                Positioned(top: cw, left: 0, width: cw, height: cw, child: _rashiBox(10, data[10])),
                // Center box with title and total
                Positioned(
                  top: cw, left: cw, width: cw*2, height: cw*2,
                  child: _centerBox(total),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rashiBox(int rashiIdx, int bindu) {
    final isSav = _selectedPlanet == 'SAV';
    return Container(
      margin: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        color: _cellColor(bindu, isSav),
        border: Border.all(color: const Color(0xFFCBD5E0), width: 1.0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            appRashi[rashiIdx],
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF718096)),
          ),
          const SizedBox(height: 2),
          Text(
            '$bindu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _binduColor(bindu, isSav),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerBox(int total) {
    final label = _selectedPlanet == 'SAV'
        ? tr('ಸರ್ವಾಷ್ಟಕ ವರ್ಗ')
        : '$_selectedPlanet\n${tr('ಅಷ್ಟಕವರ್ಗ')}';
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        border: Border.all(color: const Color(0xFFDD6B20), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 36, height: 36),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDD6B20),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kPurple2.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${tr('ಒಟ್ಟು')}: $total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kPurple2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _cellColor(int bindu, bool isSav) {
    if (isSav) {
      if (bindu >= 30) return const Color(0xFFE6F4EA);
      if (bindu >= 25) return Colors.white;
      if (bindu < 22) return const Color(0xFFFDE8E8);
      return Colors.white;
    } else {
      if (bindu >= 5) return const Color(0xFFE6F4EA);
      if (bindu >= 4) return Colors.white;
      if (bindu <= 2) return const Color(0xFFFDE8E8);
      return Colors.white;
    }
  }

  Color _binduColor(int bindu, bool isSav) {
    if (isSav) {
      if (bindu >= 30) return const Color(0xFF2F855A);
      if (bindu < 22) return const Color(0xFFC53030);
      return const Color(0xFF1A202C);
    } else {
      if (bindu >= 5) return const Color(0xFF2F855A);
      if (bindu <= 2) return const Color(0xFFC53030);
      return const Color(0xFF1A202C);
    }
  }

  // ─── Bar Chart ────────────────────────────────────────────
  Widget _buildBarChart(List<int> data) {
    final maxBindu = _selectedPlanet == 'SAV' ? 49.0 : 8.0;
    final isSav = _selectedPlanet == 'SAV';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${tr('ಬಿಂದು ವಿತರಣೆ')} / Bindu Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 12),
          ...List.generate(12, (i) {
            final pct = data[i] / maxBindu;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 55, child: Text(appRashi[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kText))),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(height: 20, decoration: BoxDecoration(color: kBorder.withOpacity(0.2), borderRadius: BorderRadius.circular(4))),
                        FractionallySizedBox(
                          widthFactor: pct.clamp(0.0, 1.0),
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_barColor(data[i], isSav).withOpacity(0.8), _barColor(data[i], isSav)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 28, child: Text('${data[i]}', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kText))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _barColor(int bindu, bool isSav) {
    if (isSav) {
      if (bindu >= 30) return Colors.green;
      if (bindu >= 25) return kTeal;
      if (bindu < 22) return Colors.redAccent;
      return kPurple2;
    } else {
      if (bindu >= 5) return Colors.green;
      if (bindu >= 4) return kTeal;
      if (bindu <= 2) return Colors.redAccent;
      return kPurple2;
    }
  }

  // ─── SAV Summary Table ────────────────────────────────────
  Widget _buildSAVSummaryTable() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${tr('ಗ್ರಹ ಬಿಂದು ಸಾರಾಂಶ')} / Planet Bindu Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: kBorder, width: 0.5),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: BoxDecoration(color: kPurple2.withOpacity(0.08)),
                children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(tr('ಗ್ರಹ'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kPurple2))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(tr('ಒಟ್ಟು'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kPurple2))),
                ],
              ),
              ...AshtakaVarga.planets.map((planet) {
                final bav = _avData[planet] ?? List.filled(12, 0);
                final planetTotal = bav.reduce((a, b) => a + b);
                return TableRow(children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(planet, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText))),
                  Padding(padding: const EdgeInsets.all(8), child: Text('$planetTotal', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kText))),
                ]);
              }),
            ],
          ),
        ],
      ),
    );
  }
}
