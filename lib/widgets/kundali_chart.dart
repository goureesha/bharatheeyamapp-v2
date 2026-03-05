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
      // Aroodha chart mode
      for (final entry in aroodhas!.entries) {
        boxes[entry.value]!.add(_planetChip(entry.key, ChipType.lagna));
      }
    } else {
      // Normal planets
      for (final pName in planetOrder) {
        final info = result.planets[pName];
        if (info == null) continue;

        int ri;
        if (isBhava) {
          // Bhava chart: exact Python formula (line 1038)
          // ri = (int(ld/30) + int(((d - ld + 360)%360 + 15)/30)) % 12
          final ld = result.planets['ಲಗ್ನ']?.longitude ?? 0;
          final d = info.longitude;
          ri = ((ld / 30).floor() + (((d - ld + 360) % 360 + 15) / 30).floor()) % 12;
        } else {
          ri = _rashinFor(info.longitude);
        }
        if (ri < 0 || ri > 11) continue;

        final type = (pName == 'ಲಗ್ನ' || pName == 'ಮಾಂದಿ')
            ? ChipType.lagna
            : ChipType.planet;
        boxes[ri]!.add(_planetChip(pName, type));
      }

      // Advanced sphutas overlay
      if (showSphutas) {
        for (final entry in result.advSphutas.entries) {
          final ri = _rashinFor(entry.value);
          if (ri < 0 || ri > 11) continue;
          boxes[ri]!.add(_planetChip(entry.key, ChipType.sphuta));
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
        gradient: const LinearGradient(
          colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.0),
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
        child: Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w900, 
            color: Color(0xFFDD6B20),
            letterSpacing: 1.2,
          )),
      ),
    );
  }
  Widget _planetChip(String name, ChipType type) {
    return GestureDetector(
      onTap: () {
        if (onPlanetTap != null) onPlanetTap!(name);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Text(
          name,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}

enum ChipType { lagna, planet, sphuta }
