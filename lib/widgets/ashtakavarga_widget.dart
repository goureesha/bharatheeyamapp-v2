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
  String _selectedPlanet = 'SAV'; // Default to Sarvashtaka Varga

  @override
  void initState() {
    super.initState();
    _computeAV();
  }

  void _computeAV() {
    // Build rashi positions map from KundaliResult
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
                  _chip('SAV', 'ಸರ್ವಾಷ್ಟಕ'),
                  ...AshtakaVarga.planets.map((p) => _chip(p, p)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Title + Total
            AppCard(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlanet == 'SAV' ? 'ಸರ್ವಾಷ್ಟಕ ವರ್ಗ' : '$_selectedPlanet ಅಷ್ಟಕವರ್ಗ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kText),
                      ),
                      Text(
                        _selectedPlanet == 'SAV' ? 'Sarvashtaka Varga (Total)' : 'Bhinnashtaka Varga',
                        style: TextStyle(fontSize: 11, color: kMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPurple2.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'ಒಟ್ಟು: $total',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kPurple2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4x3 Rashi Grid
            _buildRashiGrid(selectedData),

            const SizedBox(height: 8),

            // Bar chart visualization
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ಬಿಂದು ವಿತರಣೆ / Bindu Distribution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
                  const SizedBox(height: 12),
                  ...List.generate(12, (i) {
                    final maxBindu = _selectedPlanet == 'SAV' ? 49 : 8;
                    final pct = selectedData[i] / maxBindu;
                    final rashiName = knRashi[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 55,
                            child: Text(rashiName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kText)),
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: kBorder.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: pct.clamp(0.0, 1.0),
                                  child: Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _barColor(selectedData[i], _selectedPlanet == 'SAV').withOpacity(0.8),
                                          _barColor(selectedData[i], _selectedPlanet == 'SAV'),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${selectedData[i]}',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kText),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // SAV summary table (only shown for SAV)
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

  Widget _buildRashiGrid(List<int> data) {
    // South Indian style 4x4 grid showing bindus in each rashi
    return AppCard(
      child: Table(
        border: TableBorder.all(color: kBorder, width: 0.5),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _gridRow([11, 0, 1, 2], data),   // Meena, Mesha, Vrishabha, Mithuna
          _gridRow([10, -1, -1, 3], data),  // Kumbha, empty, empty, Karkataka
          _gridRow([9, -1, -1, 4], data),   // Makara, empty, empty, Simha
          _gridRow([8, 7, 6, 5], data),     // Dhanu, Vrischika, Tula, Kanya
        ],
      ),
    );
  }

  TableRow _gridRow(List<int> indices, List<int> data) {
    return TableRow(
      children: indices.map((idx) {
        if (idx == -1) {
          return const SizedBox(height: 56);
        }
        final bindu = data[idx];
        final rashiName = knRashi[idx];
        final isSav = _selectedPlanet == 'SAV';
        return Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          color: _cellColor(bindu, isSav),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rashiName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kMuted)),
              Text('$bindu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _cellColor(int bindu, bool isSav) {
    if (isSav) {
      if (bindu >= 30) return Colors.green.withOpacity(0.12);
      if (bindu >= 25) return Colors.lightGreen.withOpacity(0.08);
      if (bindu < 22) return Colors.red.withOpacity(0.08);
      return Colors.transparent;
    } else {
      if (bindu >= 5) return Colors.green.withOpacity(0.12);
      if (bindu >= 4) return Colors.lightGreen.withOpacity(0.08);
      if (bindu <= 2) return Colors.red.withOpacity(0.08);
      return Colors.transparent;
    }
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

  Widget _buildSAVSummaryTable() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ಗ್ರಹ ಬಿಂದು ಸಾರಾಂಶ / Planet Bindu Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kText)),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: kBorder, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: kPurple2.withOpacity(0.08)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('ಗ್ರಹ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kPurple2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('ಒಟ್ಟು', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kPurple2)),
                  ),
                ],
              ),
              ...AshtakaVarga.planets.map((planet) {
                final bav = _avData[planet] ?? List.filled(12, 0);
                final total = bav.reduce((a, b) => a + b);
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(planet, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kText)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('$total', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kText)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
