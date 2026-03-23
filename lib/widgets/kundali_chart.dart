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
  final void Function(String planetName)? onPlanetLongPress;
  final String? selectedPlanet; // for bhava highlight
  final String? bhavaFromPlanet; // planet to calculate bhava from (null = lagna)

  const KundaliChart({
    super.key,
    required this.result,
    required this.varga,
    required this.isBhava,
    required this.showSphutas,
    this.aroodhas,
    this.centerLabel,
    this.onPlanetTap,
    this.onPlanetLongPress,
    this.selectedPlanet,
    this.bhavaFromPlanet,
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
    // Grid is always oriented with lagna's rashi
    final lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0;
    final lagnaIdx = (lagnaLong / 30).floor() % 12;

    // Reference longitude for bhava calculation (planet or lagna)
    double refLongitude;
    if (bhavaFromPlanet != null && result.planets.containsKey(bhavaFromPlanet)) {
      refLongitude = result.planets[bhavaFromPlanet]!.longitude;
    } else {
      refLongitude = lagnaLong;
    }

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
          final d = info.longitude;

          // Determine which bhava madhyas to use
          List<double> madhyas;
          if (bhavaFromPlanet != null) {
            // Shift all Sripathi bhava madhyas by (planet_deg - lagna_deg)
            // This preserves unequal house sizes with planet as 1st house midpoint
            final offset = (refLongitude - lagnaLong + 360.0) % 360.0;
            madhyas = List.generate(12, (i) => (result.bhavas[i] + offset) % 360.0);
          } else {
            madhyas = result.bhavas;
          }

          // Calculate bhava sandhi (boundaries) from midpoints
          List<double> boundaries = List.filled(12, 0.0);
          for (int i = 0; i < 12; i++) {
            final m1 = madhyas[i];
            final m2 = madhyas[(i + 1) % 12];
            double diff = (m2 - m1 + 360.0) % 360.0;
            boundaries[i] = (m1 + (diff / 2.0)) % 360.0;
          }

          // Find which bhava this planet falls in
          int bhavaIdx = 0;
          for (int i = 0; i < 12; i++) {
            final startBoundary = boundaries[(i + 11) % 12];
            final endBoundary = boundaries[i];
            if (startBoundary < endBoundary) {
              if (d >= startBoundary && d < endBoundary) {
                bhavaIdx = i;
                break;
              }
            } else {
              if (d >= startBoundary || d < endBoundary) {
                bhavaIdx = i;
                break;
              }
            }
          }

          if (bhavaFromPlanet != null) {
            final planetRashiIdx = (refLongitude / 30).floor() % 12;
            ri = (planetRashiIdx + bhavaIdx) % 12;
          } else {
            ri = (lagnaIdx + bhavaIdx) % 12;
          }
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

  /// Compute navamsha (D9) rashi index from sidereal longitude
  int _navamshaRashi(double deg) {
    final block = (deg / 30).floor() % 4;
    final start = [0, 9, 6, 3][block];
    final steps = ((deg % 30) / 3.33333).floor();
    return (start + steps) % 12;
  }

  /// Short name map: first 1-2 Kannada characters
  static const _shortNames = <String, String>{
    'ರವಿ': 'ರ', 'ಸೂರ್ಯ': 'ಸೂ',
    'ಚಂದ್ರ': 'ಚಂ',
    'ಕುಜ': 'ಕು', 'ಮಂಗಳ': 'ಮಂ',
    'ಬುಧ': 'ಬು',
    'ಗುರು': 'ಗು',
    'ಶುಕ್ರ': 'ಶು',
    'ಶನಿ': 'ಶ',
    'ರಾಹು': 'ರಾ',
    'ಕೇತು': 'ಕೇ',
    'ಲಗ್ನ': 'ಲ',
    'ಮಾಂದಿ': 'ಮಾ',
  };

  Widget _planetChip(String name, {PlanetInfo? info, required ChipType type}) {
    Color color;
    switch (type) {
      case ChipType.lagna:  color = const Color(0xFFE53E3E); break;
      case ChipType.sphuta: color = const Color(0xFF805AD5); break;
      default:
        switch (name) {
          case 'ರವಿ': color = const Color(0xFFC53030); break;
          case 'ಚಂದ್ರ': color = const Color(0xFF2C5282); break;
          case 'ಕುಜ':
          case 'ಮಂಗಳ': color = const Color(0xFFE53E3E); break;
          case 'ಬುಧ': color = const Color(0xFF2F855A); break;
          case 'ಗುರು': color = const Color(0xFFDD6B20); break;
          case 'ಶುಕ್ರ': color = const Color(0xFFB83280); break;
          case 'ಶನಿ': color = const Color(0xFF1A202C); break;
          case 'ರಾಹು': color = const Color(0xFF744210); break;
          case 'ಕೇತು': color = const Color(0xFF4A5568); break;
          default: color = const Color(0xFF2B6CB0);
        }
        break;
    }

    // Build display text
    final shortName = _shortNames[name] ?? name;
    String displayText = shortName;
    bool isCombust = false;
    bool isVakri = false;

    if (info != null) {
      isCombust = info.isCombust;
      isVakri = info.speed < 0 && !['ರಾಹು', 'ಕೇತು'].contains(info.name);

      // Degree within current rashi — show degrees and minutes (matching sphuta tab)
      final degInRashi = info.longitude % 30;
      final totalSec = (degInRashi * 3600).round();
      int dg = totalSec ~/ 3600;
      int mn = (totalSec % 3600) ~/ 60;
      if (dg == 30) { dg = 29; mn = 59; }
      final degStr = '$dg°${mn.toString().padLeft(2, '0')}\'';
      
      // Navamsha rashi number (1-12) — only for D1 (varga == 1)
      if (varga == 1 || varga == 0) {
        final navIdx = _navamshaRashi(info.longitude);
        final navNum = navIdx + 1; // 1-indexed display
        displayText = '$shortName $degStr·$navNum';
      } else {
        displayText = '$shortName $degStr';
      }

      // Vakri arrow
      if (isVakri) {
        displayText = '$displayText↩';
      }

      // Asta: wrap in brackets
      if (isCombust) {
        displayText = '($displayText)';
      }
    }

    // Dim asta planets
    final double opacity = isCombust ? 0.45 : 1.0;
    final bool isSelected = selectedPlanet != null && selectedPlanet == name;

    return GestureDetector(
      onTap: () {
        if (onPlanetTap != null) onPlanetTap!(name);
      },
      onLongPress: () {
        if (onPlanetLongPress != null) onPlanetLongPress!(name);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: isSelected ? 14 : 11,
            fontWeight: FontWeight.w900,
            color: color.withValues(alpha: opacity),
            decoration: isSelected ? TextDecoration.underline : null,
            decorationColor: color,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}

enum ChipType { lagna, planet, sphuta }
