import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'common.dart';

// ─────────────────────────────────────────────
// Prashna Chart — South Indian chart with:
//   • Drekkana-based vertical placement within each house
//   • Navamsha rashi labels OUTSIDE the chart (Kannada)
//   • Dvadashamsha rashi labels OUTSIDE the chart (Hindi)
//   • Single-letter planet abbreviations
//   • Degrees in DMS format
//   • Long-press bhava reference change
// ─────────────────────────────────────────────

class PrashnaChart extends StatelessWidget {
  final KundaliResult result;
  final bool isBhava;
  final String? centerLabel;
  final void Function(String planetName)? onPlanetTap;
  final void Function(String planetName)? onPlanetLongPress;
  final String? selectedPlanet;
  final String? bhavaFromPlanet;
  final double textScale;

  const PrashnaChart({
    super.key,
    required this.result,
    this.isBhava = false,
    this.centerLabel,
    this.onPlanetTap,
    this.onPlanetLongPress,
    this.selectedPlanet,
    this.bhavaFromPlanet,
    this.textScale = 1.0,
  });

  // South Indian grid: rashi index at each grid cell, null = center
  static const _grid = [
    11, 0, 1, 2,
    10, -1, -1, 3,
    9,  -1, -1, 4,
    8,  7,  6,  5,
  ];

  // Rashi names for navamsha (Kannada)
  static const _rashiKn = ['ಮೇ', 'ವೃ', 'ಮಿ', 'ಕ', 'ಸಿಂ', 'ಕ', 'ತು', 'ವೃ', 'ಧ', 'ಮ', 'ಕುಂ', 'ಮೀ'];
  // Full rashi single letters for navamsha in Kannada
  static const _navRashiKn = ['ಮೇ', 'ವೃಷ', 'ಮಿಥ', 'ಕರ್', 'ಸಿಂ', 'ಕನ್', 'ತುಲ', 'ವೃಶ್', 'ಧನ', 'ಮಕ', 'ಕುಂ', 'ಮೀನ'];
  // Rashi names for dvadashamsha (Hindi)
  static const _dvadRashiHi = ['मे', 'वृ', 'मि', 'क', 'सिं', 'क', 'तु', 'वृ', 'ध', 'म', 'कुं', 'मी'];

  // Planet single-letter names (Kannada)
  static const _pNameKn = <String, String>{
    'ರವಿ': 'ರ', 'ಚಂದ್ರ': 'ಚಂ', 'ಕುಜ': 'ಕು', 'ಬುಧ': 'ಬು',
    'ಗುರು': 'ಗು', 'ಶುಕ್ರ': 'ಶು', 'ಶನಿ': 'ಶ',
    'ರಾಹು': 'ರಾ', 'ಕೇತು': 'ಕೇ', 'ಲಗ್ನ': 'ಲ', 'ಮಾಂದಿ': 'ಮಾ',
  };

  // Planet single-letter names (Hindi)
  static const _pNameHi = <String, String>{
    'ರವಿ': 'र', 'ಚಂದ್ರ': 'चं', 'ಕುಜ': 'कु', 'ಬುಧ': 'बु',
    'ಗುರು': 'गु', 'ಶುಕ್ರ': 'शु', 'ಶನಿ': 'श',
    'ರಾಹು': 'रा', 'ಕೇತು': 'के', 'ಲಗ್ನ': 'ल', 'ಮಾಂದಿ': 'मां',
  };

  // Planet colors
  static Color _planetColor(String name) {
    switch (name) {
      case 'ರವಿ': return const Color(0xFFC53030);
      case 'ಚಂದ್ರ': return const Color(0xFF2C5282);
      case 'ಕುಜ': return const Color(0xFFE53E3E);
      case 'ಬುಧ': return const Color(0xFF2F855A);
      case 'ಗುರು': return const Color(0xFFDD6B20);
      case 'ಶುಕ್ರ': return const Color(0xFFB83280);
      case 'ಶನಿ': return const Color(0xFF1A202C);
      case 'ರಾಹು': return const Color(0xFF744210);
      case 'ಕೇತು': return const Color(0xFF4A5568);
      case 'ಲಗ್ನ': return const Color(0xFFE53E3E);
      case 'ಮಾಂದಿ': return const Color(0xFFE53E3E);
      default: return const Color(0xFF2B6CB0);
    }
  }

  /// Navamsha (D9) rashi index
  int _navamshaRashi(double deg) {
    final block = (deg / 30).floor() % 4;
    final start = [0, 9, 6, 3][block];
    final steps = ((deg % 30) / 3.33333).floor();
    return (start + steps) % 12;
  }

  /// Dvadashamsha (D12) rashi index
  int _dvadRashi(double deg) {
    return ((deg / 30).floor() + ((deg % 30) / 2.5).floor()) % 12;
  }

  /// Degree in DMS format
  String _degStr(double longitude) {
    final degInRashi = longitude % 30;
    final totalSec = (degInRashi * 3600).round();
    int dg = totalSec ~/ 3600;
    int mn = (totalSec % 3600) ~/ 60;
    int sc = totalSec % 60;
    if (dg == 30) { dg = 29; mn = 59; sc = 59; }
    return '$dg°${mn.toString().padLeft(2, '0')}\'${sc.toString().padLeft(2, '0')}"';
  }

  /// Determine drekkana zone (0=first 0-10°, 1=second 10-20°, 2=third 20-30°)
  int _drekkana(double longitude) {
    final dr = longitude % 30;
    if (dr < 10) return 0;
    if (dr < 20) return 1;
    return 2;
  }

  /// Which outer edge does navamsha/dvad text go on for a given grid position?
  /// Returns: 'top', 'bottom', 'left', 'right'
  static String _outerEdge(int rashiIdx) {
    // Top row: 11, 0, 1, 2
    if ([11, 0, 1, 2].contains(rashiIdx)) return 'top';
    // Bottom row: 8, 7, 6, 5
    if ([8, 7, 6, 5].contains(rashiIdx)) return 'bottom';
    // Left column: 10, 9
    if ([10, 9].contains(rashiIdx)) return 'left';
    // Right column: 3, 4
    return 'right';
  }

  @override
  Widget build(BuildContext context) {
    final lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0;
    final lagnaIdx = (lagnaLong / 30).floor() % 12;

    // Reference longitude for bhava
    double refLongitude;
    if (bhavaFromPlanet != null && result.planets.containsKey(bhavaFromPlanet)) {
      refLongitude = result.planets[bhavaFromPlanet]!.longitude;
    } else {
      refLongitude = lagnaLong;
    }

    // Collect planets per rashi, grouped by drekkana
    // Each entry: (name, info, drekkana, degInRashi)
    final Map<int, List<_PlanetEntry>> boxData = {for (int i = 0; i < 12; i++) i: []};

    // Also collect navamsha and dvadashamsha per rashi+drekkana for outer labels
    // Key: rashi index, Value: map of drekkana (0,1,2) -> list of planet abbreviations
    final Map<int, Map<int, List<String>>> navLabels = {for (int i = 0; i < 12; i++) i: {0: [], 1: [], 2: []}};
    final Map<int, Map<int, List<String>>> dvadLabels = {for (int i = 0; i < 12; i++) i: {0: [], 1: [], 2: []}};

    for (final pName in planetOrder) {
      final info = result.planets[pName];
      if (info == null) continue;

      int ri;
      if (isBhava) {
        final d = info.longitude;
        List<double> madhyas;
        if (bhavaFromPlanet != null) {
          final offset = (refLongitude - lagnaLong + 360.0) % 360.0;
          madhyas = List.generate(12, (i) => (result.bhavas[i] + offset) % 360.0);
        } else {
          madhyas = result.bhavas;
        }
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
            if (d >= start && d < end) { bhavaIdx = i; break; }
          } else {
            if (d >= start || d < end) { bhavaIdx = i; break; }
          }
        }
        if (bhavaFromPlanet != null) {
          final planetRashiIdx = (refLongitude / 30).floor() % 12;
          ri = (planetRashiIdx + bhavaIdx) % 12;
        } else {
          ri = (lagnaIdx + bhavaIdx) % 12;
        }
      } else {
        ri = (info.longitude / 30).floor() % 12;
      }
      if (ri < 0 || ri > 11) continue;

      final drek = _drekkana(info.longitude);
      final degInRashi = info.longitude % 30;

      boxData[ri]!.add(_PlanetEntry(
        name: pName,
        info: info,
        drekkana: drek,
        degInRashi: degInRashi,
      ));

      // Navamsha label — drekkana within the navamsha rashi
      // d9Exact = (deg * 9) % 360, degInD9 = d9Exact % 30
      final navRi = _navamshaRashi(info.longitude);
      final d9Exact = (info.longitude * 9) % 360;
      final degInD9 = d9Exact % 30;
      final navDrek = degInD9 < 10 ? 0 : (degInD9 < 20 ? 1 : 2);
      navLabels[navRi]![navDrek]!.add(_pNameKn[pName] ?? pName);

      // Dvadashamsha label — drekkana within the dvad rashi
      // degInD12 = (deg % 2.5) * 12
      final dvadRi = _dvadRashi(info.longitude);
      final degInD12 = (info.longitude % 2.5) * 12;
      final dvadDrek = degInD12 < 10 ? 0 : (degInD12 < 20 ? 1 : 2);
      dvadLabels[dvadRi]![dvadDrek]!.add(_pNameHi[pName] ?? pName);
    }

    // Sort planets within each house by degree
    for (final ri in boxData.keys) {
      boxData[ri]!.sort((a, b) => a.degInRashi.compareTo(b.degInRashi));
    }

    // Outer margin for navamsha/dvad labels
    const outerMargin = 40.0;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Chart takes most of the space, with margin for outer labels
          final availSize = constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;
          final chartSize = availSize - (outerMargin * 2);
          final cw = chartSize / 4;

          return SizedBox(
            width: availSize,
            height: availSize,
            child: Stack(
              children: [
                // Main chart background
                Positioned(
                  top: outerMargin,
                  left: outerMargin,
                  width: chartSize,
                  height: chartSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // 12 rashi boxes
                        ..._buildRashiBoxes(cw, boxData),
                        // Center box
                        Positioned(
                          top: cw, left: cw,
                          width: cw * 2, height: cw * 2,
                          child: _centerBox(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Outer labels: Navamsha (Kannada) & Dvadashamsha (Hindi)
                ..._buildOuterLabels(cw, outerMargin, navLabels, dvadLabels),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildRashiBoxes(double cw, Map<int, List<_PlanetEntry>> boxData) {
    // Positions for each rashi in the 4x4 grid
    final positions = <int, Offset>{
      11: Offset(0, 0),       0: Offset(cw, 0),
      1:  Offset(cw*2, 0),    2: Offset(cw*3, 0),
      10: Offset(0, cw),      3: Offset(cw*3, cw),
      9:  Offset(0, cw*2),    4: Offset(cw*3, cw*2),
      8:  Offset(0, cw*3),    7: Offset(cw, cw*3),
      6:  Offset(cw*2, cw*3), 5: Offset(cw*3, cw*3),
    };

    return positions.entries.map((entry) {
      final ri = entry.key;
      final pos = entry.value;
      return Positioned(
        top: pos.dy, left: pos.dx,
        width: cw, height: cw,
        child: _rashiBox(ri, boxData[ri] ?? []),
      );
    }).toList();
  }

  Widget _rashiBox(int rashiIdx, List<_PlanetEntry> planets) {
    // Group by drekkana
    final drek0 = planets.where((p) => p.drekkana == 0).toList();
    final drek1 = planets.where((p) => p.drekkana == 1).toList();
    final drek2 = planets.where((p) => p.drekkana == 2).toList();

    return Container(
      margin: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E0), width: 1.0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Drekkana 1 (0°-10°)
          Expanded(child: _drekkanaZone(drek0)),
          // Drekkana 2 (10°-20°)
          Expanded(child: _drekkanaZone(drek1)),
          // Drekkana 3 (20°-30°)
          Expanded(child: _drekkanaZone(drek2)),
        ],
      ),
    );
  }

  Widget _drekkanaZone(List<_PlanetEntry> planets) {
    if (planets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 0,
        children: planets.map((p) => _planetChip(p)).toList(),
      ),
    );
  }

  Widget _planetChip(_PlanetEntry p) {
    final shortName = _pNameKn[p.name] ?? p.name;
    final isLagna = p.name == 'ಲಗ್ನ' || p.name == 'ಮಾಂದಿ';
    final color = _planetColor(p.name);
    final isVakri = p.info.speed < 0 && !['ರಾಹು', 'ಕೇತು'].contains(p.name);
    final isCombust = p.info.isCombust;

    String displayText = '$shortName ${_degStr(p.info.longitude)}';
    if (isVakri) displayText = '$displayText↩';
    if (isCombust) displayText = '($displayText)';

    final double opacity = isCombust ? 0.45 : 1.0;
    final bool isSelected = selectedPlanet != null && selectedPlanet == p.name;

    return GestureDetector(
      onTap: () { if (onPlanetTap != null) onPlanetTap!(p.name); },
      onLongPress: () { if (onPlanetLongPress != null) onPlanetLongPress!(p.name); },
      behavior: HitTestBehavior.opaque,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: (isSelected ? 11 : 8.5) * textScale,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: opacity),
          decoration: isSelected ? TextDecoration.underline : null,
          decorationColor: color,
          decorationThickness: 2,
        ),
      ),
    );
  }

  Widget _centerBox() {
    String label = centerLabel ?? 'ಪ್ರಶ್ನ ಕುಂಡಲಿ';
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EC),
        border: Border.all(color: const Color(0xFFDD6B20), width: 1.0),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 40, height: 40),
            const SizedBox(height: 4),
            Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12 * textScale,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFDD6B20),
                letterSpacing: 0.5,
              )),
          ],
        ),
      ),
    );
  }

  /// Build outer labels for navamsha (Kannada green) and dvadashamsha (Hindi purple).
  /// Top/Bottom edges: 3 COLUMNS (one per drekkana, I=left, II=mid, III=right).
  /// Left/Right edges: 3 ROWS (one per drekkana, I=top, II=mid, III=bottom).
  /// Within each slot, nav (green) on top, dvad (purple) below.
  List<Widget> _buildOuterLabels(
    double cw, double outerMargin,
    Map<int, Map<int, List<String>>> navLabels,
    Map<int, Map<int, List<String>>> dvadLabels,
  ) {
    final widgets = <Widget>[];
    final fs = 9 * textScale;
    final navStyle = TextStyle(fontSize: fs, fontWeight: FontWeight.w900, color: const Color(0xFF2F855A));
    final dvadStyle = TextStyle(fontSize: fs, fontWeight: FontWeight.w900, color: const Color(0xFF805AD5));

    final positions = <int, Offset>{
      11: Offset(0, 0),       0: Offset(cw, 0),
      1:  Offset(cw*2, 0),    2: Offset(cw*3, 0),
      10: Offset(0, cw),      3: Offset(cw*3, cw),
      9:  Offset(0, cw*2),    4: Offset(cw*3, cw*2),
      8:  Offset(0, cw*3),    7: Offset(cw, cw*3),
      6:  Offset(cw*2, cw*3), 5: Offset(cw*3, cw*3),
    };

    final drekZone = cw / 3;  // drekkana zone size inside house
    final colW = cw / 3;      // column width for top/bottom edges

    for (final ri in positions.keys) {
      final pos = positions[ri]!;
      final edge = _outerEdge(ri);

      for (int drek = 0; drek < 3; drek++) {
        final navList = navLabels[ri]?[drek] ?? [];
        final dvadList = dvadLabels[ri]?[drek] ?? [];
        if (navList.isEmpty && dvadList.isEmpty) continue;

        final navText = navList.join(' ');
        final dvadText = dvadList.join(' ');

        // Nav on top, dvad below — used for all edges
        Widget labelCol = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (navText.isNotEmpty) Text(navText, style: navStyle, textAlign: TextAlign.center),
            if (dvadText.isNotEmpty) Text(dvadText, style: dvadStyle, textAlign: TextAlign.center),
          ],
        );

        switch (edge) {
          case 'top':
            // 3 columns above the house: drek 0=left, 1=mid, 2=right
            widgets.add(Positioned(
              top: 0,
              left: outerMargin + pos.dx + (drek * colW),
              width: colW,
              height: outerMargin,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: labelCol,
              ),
            ));
            break;

          case 'bottom':
            // 3 columns below the house: drek 0=left, 1=mid, 2=right
            widgets.add(Positioned(
              top: outerMargin + pos.dy + cw,
              left: outerMargin + pos.dx + (drek * colW),
              width: colW,
              height: outerMargin,
              child: Align(
                alignment: Alignment.topCenter,
                child: labelCol,
              ),
            ));
            break;

          case 'left':
            // 3 rows on left: drek 0=top, 1=mid, 2=bottom
            widgets.add(Positioned(
              top: outerMargin + pos.dy + (drek * drekZone),
              left: 0,
              width: outerMargin,
              height: drekZone,
              child: Center(child: labelCol),
            ));
            break;

          case 'right':
          default:
            // 3 rows on right: drek 0=top, 1=mid, 2=bottom
            widgets.add(Positioned(
              top: outerMargin + pos.dy + (drek * drekZone),
              left: outerMargin + pos.dx + cw,
              width: outerMargin,
              height: drekZone,
              child: Center(child: labelCol),
            ));
            break;
        }
      }
    }

    return widgets;
  }
}

class _PlanetEntry {
  final String name;
  final PlanetInfo info;
  final int drekkana; // 0, 1, 2
  final double degInRashi;

  const _PlanetEntry({
    required this.name,
    required this.info,
    required this.drekkana,
    required this.degInRashi,
  });
}
