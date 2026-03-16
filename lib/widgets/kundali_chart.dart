import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'common.dart';

// ─────────────────────────────────────────────
// 4×4 South-Indian style Kundali chart widget
// ─────────────────────────────────────────────

class KundaliChart extends StatelessWidget {
  final KundaliResult result;
  final int varga;
  final bool isBhava;
  final bool showSphutas;
  final Map<String, int>? aroodhas; // for Aroodha tab
  final String? centerLabel;
  final void Function(String planetName)? onPlanetTap;

  const KundaliChart({
    super.key,
    required this.result,
    required this.varga,
    required this.isBhava,
    required this.showSphutas,
    this.aroodhas,
    this.centerLabel,
    this.onPlanetTap,
  });

  // Grid layout: indices into rashi boxes, null = center
  static const List<int?> _grid = [
    11, 0, 1, 2,
    10, null, null, 3,
    9,  null, null, 4,
    8,  7,    6,    5,
  ];

  /// Compute which rashi index each planet falls in for the chosen varga
  int _rashinFor(double deg) {
    switch (varga) {
      case 2: // Hora
        final r = (deg / 30).floor() % 12;
        final dr = deg % 30;
        final isOdd = r % 2 == 0;
        return isOdd ? (dr < 15 ? 4 : 3) : (dr < 15 ? 3 : 4);
      case 3: // Drekkana
        return ((deg / 30).floor() + ((deg % 30) / 10).floor() * 4) % 12;
      case 9: // Navamsa
        final block = (deg / 30).floor() % 4;
        final start = [0, 9, 6, 3][block];
        final steps = ((deg % 30) / 3.33333).floor();
        return (start + steps) % 12;
      case 12: // Dvadashamsa
        return ((deg / 30).floor() + ((deg % 30) / 2.5).floor()) % 12;
      case 30: // Trimshamsa
        final r = (deg / 30).floor() % 12;
        final dr = deg % 30;
        final isOdd = r % 2 == 0;
        if (isOdd) {
          if (dr < 5) return 0;
          if (dr < 10) return 10;
          if (dr < 18) return 8;
          if (dr < 25) return 2;
          return 6;
        } else {
          if (dr < 5) return 5;
          if (dr < 12) return 2;
          if (dr < 20) return 8;
          if (dr < 25) return 10;
          return 0;
        }
      default: // Rashi (D1)
        if (isBhava) {
          // Bhava chart: place based on house number from lagna
          return -1; // handled separately
        }
        return (deg / 30).floor() % 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lagnaRashi = (result.planets['ಲಗ್ನ']?.longitude ?? 0) / 30;
    final lagnaIdx   = lagnaRashi.floor() % 12;

    // Build box contents
    final Map<int, List<Widget>> boxes = {for (int i = 0; i < 12; i++) i: []};

    if (aroodhas != null) {
      // Aroodha chart mode: show planets first
      for (final pName in planetOrder) {
        final info = result.planets[pName];
        if (info == null) continue;
        final ri = _rashinFor(info.longitude);
        if (ri >= 0 && ri < 12) {
          boxes[ri]!.add(_planetChip(pName, info: info, type: pName == 'ಲಗ್ನ' ? ChipType.lagna : ChipType.planet));
        }
      }
      // Then add aroodha labels
      for (final entry in aroodhas!.entries) {
        boxes[entry.value]!.add(_planetChip(entry.key, type: ChipType.lagna));
      }
    } else {
      // Normal planets
      for (final pName in planetOrder) {
        final info = result.planets[pName];
        if (info == null) continue;

        int ri;
        if (isBhava) {
          // Bhava chart: place planet based on which unequal house it falls into.
          // result.bhavas contains the 12 precise Sripathi Bhava Madhyas (midpoints).
          // We must calculate the Bhava Sandhi (boundaries) midway between adjacent midpoints.
          final d = info.longitude;
          List<double> boundaries = List.filled(12, 0.0);
          for (int i = 0; i < 12; i++) {
            final m1 = result.bhavas[i];
            final m2 = result.bhavas[(i + 1) % 12];
            
            // Calculate midpoint of the shortest arc bridging m1 and m2
            double diff = (m2 - m1 + 360.0) % 360.0;
            boundaries[i] = (m1 + (diff / 2.0)) % 360.0;
          }

          int bhavaIdx = 0;
          for (int i = 0; i < 12; i++) {
            final startBoundary = boundaries[(i + 11) % 12]; // Boundary *before* this house's midpoint
            final endBoundary = boundaries[i];              // Boundary *after* this house's midpoint
            
            if (startBoundary < endBoundary) {
              if (d >= startBoundary && d < endBoundary) {
                bhavaIdx = i;
                break;
              }
            } else {
              // Wrap-around case (e.g. start=350, end=20)
              if (d >= startBoundary || d < endBoundary) {
                bhavaIdx = i;
                break;
              }
            }
          }
          ri = (lagnaIdx + bhavaIdx) % 12;
        } else {
          ri = _rashinFor(info.longitude);
        }
        if (ri < 0 || ri > 11) continue;

        final type = (pName == 'ಲಗ್ನ' || pName == 'ಮಾಂದಿ')
            ? ChipType.lagna
            : ChipType.planet;
        boxes[ri]!.add(_planetChip(pName, info: info, type: type));
      }

      // Advanced sphutas overlay
      if (showSphutas) {
        for (final entry in result.advSphutas.entries) {
          final ri = _rashinFor(entry.value);
          if (ri < 0 || ri > 11) continue;
          boxes[ri]!.add(_planetChip(entry.key, type: ChipType.sphuta));
        }
      }
    }

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
                // Top Row
                Positioned(top: 0, left: 0, width: cw, height: cw, child: _rashiBox(11, boxes[11]!)),
                Positioned(top: 0, left: cw, width: cw, height: cw, child: _rashiBox(0, boxes[0]!)),
                Positioned(top: 0, left: cw*2, width: cw, height: cw, child: _rashiBox(1, boxes[1]!)),
                Positioned(top: 0, left: cw*3, width: cw, height: cw, child: _rashiBox(2, boxes[2]!)),
                // Right Col
                Positioned(top: cw, left: cw*3, width: cw, height: cw, child: _rashiBox(3, boxes[3]!)),
                Positioned(top: cw*2, left: cw*3, width: cw, height: cw, child: _rashiBox(4, boxes[4]!)),
                Positioned(top: cw*3, left: cw*3, width: cw, height: cw, child: _rashiBox(5, boxes[5]!)),
                // Bottom Row
                Positioned(top: cw*3, left: cw*2, width: cw, height: cw, child: _rashiBox(6, boxes[6]!)),
                Positioned(top: cw*3, left: cw, width: cw, height: cw, child: _rashiBox(7, boxes[7]!)),
                Positioned(top: cw*3, left: 0, width: cw, height: cw, child: _rashiBox(8, boxes[8]!)),
                // Left Col
                Positioned(top: cw*2, left: 0, width: cw, height: cw, child: _rashiBox(9, boxes[9]!)),
                Positioned(top: cw, left: 0, width: cw, height: cw, child: _rashiBox(10, boxes[10]!)),
                // Center big box
                Positioned(top: cw, left: cw, width: cw*2, height: cw*2, child: _centerBox()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rashiBox(int rashiIdx, List<Widget> planets) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFCBD5E0), width: 1.0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: planets.map((p) => Padding(padding: const EdgeInsets.only(bottom: 2), child: p)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerBox() {
    final label = centerLabel ?? 'ಭಾರತೀಯಮ್';
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
            Image.asset(
              'assets/images/logo.png',
              width: 48, height: 48,
            ),
            const SizedBox(height: 4),
            Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDD6B20),
                letterSpacing: 1.0,
              )),
          ],
        ),
      ),
    );
  }

  Widget _planetChip(String name, {PlanetInfo? info, required ChipType type}) {
    Color color;
    switch (type) {
      case ChipType.lagna:  color = const Color(0xFFE53E3E); break;
      case ChipType.sphuta: color = const Color(0xFF805AD5); break;
      default:
        // Assign specific colors to planets, ensuring they remain dark enough to be visible on light backgrounds
        switch (name) {
          case 'ರವಿ': color = const Color(0xFFC53030); break; // Sun: Deep Red
          case 'ಚಂದ್ರ': color = const Color(0xFF2C5282); break; // Moon: Indigo/Deep Blue
          case 'ಕುಜ':
          case 'ಮಂಗಳ': color = const Color(0xFFE53E3E); break; // Mars: Bright Red
          case 'ಬುಧ': color = const Color(0xFF2F855A); break; // Mercury: Green
          case 'ಗುರು': color = const Color(0xFFDD6B20); break; // Jupiter: Orange/Gold
          case 'ಶುಕ್ರ': color = const Color(0xFFB83280); break; // Venus: Magenta/Pink
          case 'ಶನಿ': color = const Color(0xFF1A202C); break; // Saturn: Near Black
          case 'ರಾಹು': color = const Color(0xFF744210); break; // Rahu: Dark Brown
          case 'ಕೇತು': color = const Color(0xFF4A5568); break; // Ketu: Dark Greyish Blue
          default: color = const Color(0xFF2B6CB0); // Default Blue
        }
        break;
    }

    String displayName = name;
    if (info != null) {
      // 1. Asta (Combust) -> Wrap in brackets
      if (info.isCombust) {
        displayName = '($displayName)';
      }
      // 2. Vakri (Retrograde) -> Reverse Arrow
      if (info.speed < 0 && !['ರಾಹು', 'ಕೇತು'].contains(info.name)) {
        displayName = '$displayName ↩';
      } else if (info.speed < 0 && ['ರಾಹು', 'ಕೇತು'].contains(info.name)) {
        // Technically Rahu/Ketu are always retrograde, usually we don't need to put arrows on them. 
        // We'll skip the arrow for Rahu/Ketu to keep it clean.
      }
    }

    return GestureDetector(
      onTap: () {
        if (onPlanetTap != null) onPlanetTap!(name);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Text(
          displayName,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
        ),
      ),
    );
  }
}

enum ChipType { lagna, planet, sphuta }
