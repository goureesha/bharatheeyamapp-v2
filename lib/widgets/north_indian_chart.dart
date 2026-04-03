import 'package:flutter/material.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'common.dart';

// ─────────────────────────────────────────────
// North Indian diamond-style Kundali chart
// Houses are FIXED, rashis rotate based on lagna
// House 1 (Ascendant) is always at top center
// ─────────────────────────────────────────────

class NorthIndianChart extends StatelessWidget {
  final KundaliResult result;
  final int varga;
  final bool isBhava;
  final bool showSphutas;
  final Map<String, int>? aroodhas;
  final String? centerLabel;
  final void Function(String planetName)? onPlanetTap;
  final void Function(String planetName)? onPlanetLongPress;
  final String? selectedPlanet;
  final String? bhavaFromPlanet;
  final double textScale;

  const NorthIndianChart({
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
    this.textScale = 1.0,
  });

  /// Compute which rashi index a planet falls in for the chosen varga
  int _rashinFor(double deg) {
    switch (varga) {
      case 2:
        final r = (deg / 30).floor() % 12;
        final dr = deg % 30;
        final isOdd = r % 2 == 0;
        return isOdd ? (dr < 15 ? 4 : 3) : (dr < 15 ? 3 : 4);
      case 3:
        return ((deg / 30).floor() + ((deg % 30) / 10).floor() * 4) % 12;
      case 9:
        final block = (deg / 30).floor() % 4;
        final start = [0, 9, 6, 3][block];
        final steps = ((deg % 30) / 3.33333).floor();
        return (start + steps) % 12;
      case 12:
        return ((deg / 30).floor() + ((deg % 30) / 2.5).floor()) % 12;
      case 30:
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
      default:
        if (isBhava) return -1;
        return (deg / 30).floor() % 12;
    }
  }

  /// Convert rashi index to house number (1-12) based on ascendant
  int _rashiToHouse(int rashiIdx, int lagnaRashiIdx) {
    return ((rashiIdx - lagnaRashiIdx + 12) % 12);
  }

  @override
  Widget build(BuildContext context) {
    final lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0;
    final lagnaIdx = (lagnaLong / 30).floor() % 12;

    // Reference longitude for bhava calculation
    double refLongitude;
    if (bhavaFromPlanet != null && result.planets.containsKey(bhavaFromPlanet)) {
      refLongitude = result.planets[bhavaFromPlanet]!.longitude;
    } else {
      refLongitude = lagnaLong;
    }

    // Determine which rashi goes in house 1
    // If bhavaFromPlanet is set, that planet's rashi goes to house 1
    final int firstHouseRashiIdx;
    if (bhavaFromPlanet != null && result.planets.containsKey(bhavaFromPlanet)) {
      firstHouseRashiIdx = (refLongitude / 30).floor() % 12;
    } else {
      firstHouseRashiIdx = lagnaIdx;
    }

    // Build house contents (0 = House 1 = top center)
    final Map<int, List<Widget>> houses = {for (int i = 0; i < 12; i++) i: []};
    // Rashi numbers for each house
    final Map<int, String> houseRashi = {};
    for (int i = 0; i < 12; i++) {
      final rashiIdx = (firstHouseRashiIdx + i) % 12;
      houseRashi[i] = '${rashiIdx + 1}'; // Rashi number: Mesha=1 ... Meena=12
    }

    if (aroodhas != null) {
      for (final pName in planetOrder) {
        final info = result.planets[pName];
        if (info == null) continue;
        final ri = _rashinFor(info.longitude);
        if (ri >= 0 && ri < 12) {
          final h = _rashiToHouse(ri, firstHouseRashiIdx);
          houses[h]!.add(_planetChip(pName, info: info));
        }
      }
      for (final entry in aroodhas!.entries) {
        final h = _rashiToHouse(entry.value, firstHouseRashiIdx);
        houses[h]!.add(_aroodhaChip(entry.key));
      }
    } else {
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
            final startBoundary = boundaries[(i + 11) % 12];
            final endBoundary = boundaries[i];
            if (startBoundary < endBoundary) {
              if (d >= startBoundary && d < endBoundary) { bhavaIdx = i; break; }
            } else {
              if (d >= startBoundary || d < endBoundary) { bhavaIdx = i; break; }
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
        final h = _rashiToHouse(ri, firstHouseRashiIdx);
        houses[h]!.add(_planetChip(pName, info: info));
      }

      if (showSphutas) {
        for (final entry in result.advSphutas.entries) {
          final ri = _rashinFor(entry.value);
          if (ri < 0 || ri > 11) continue;
          final h = _rashiToHouse(ri, firstHouseRashiIdx);
          houses[h]!.add(_sphutaChip(entry.key));
        }
      }
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E0), width: 1.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              return CustomPaint(
                painter: _NorthIndianPainter(houseRashi: houseRashi),
                child: Stack(children: _buildHouseWidgets(size, houses, houseRashi)),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build positioned widgets for each house in the diamond layout.
  /// The diamond + diagonals create 12 triangular regions.
  /// Houses go clockwise: 0=top-center(asc), 1=top-right-corner, 2=right-upper, etc.
  List<Widget> _buildHouseWidgets(double size, Map<int, List<Widget>> houses, Map<int, String> houseRashi) {
    final widgets = <Widget>[];
    final s = size;
    final boxW = s * 0.22;  // widget width
    final boxH = s * 0.18;  // widget height

    // Centroids of each triangular house (as fractions of size)
    // North Indian houses go COUNTER-CLOCKWISE from top:
    //   H1(asc)=top, H2=upper-left, H3=left-upper, H4=left-center,
    //   H5=left-lower, H6=bottom-left, H7=bottom, H8=bottom-right,
    //   H9=right-lower, H10=right-center, H11=right-upper, H12=upper-right
    final centroids = <int, Offset>{
      0:  Offset(0.50, 0.17),   // H1  - top center (ascendant)
      1:  Offset(0.25, 0.08),   // H2  - upper-left corner
      2:  Offset(0.08, 0.25),   // H3  - left-upper
      3:  Offset(0.17, 0.50),   // H4  - left center
      4:  Offset(0.08, 0.75),   // H5  - left-lower
      5:  Offset(0.25, 0.92),   // H6  - bottom-left corner
      6:  Offset(0.50, 0.83),   // H7  - bottom center
      7:  Offset(0.75, 0.92),   // H8  - bottom-right corner
      8:  Offset(0.92, 0.75),   // H9  - right-lower
      9:  Offset(0.83, 0.50),   // H10 - right center
      10: Offset(0.92, 0.25),   // H11 - right-upper
      11: Offset(0.75, 0.08),   // H12 - upper-right corner
    };

    for (int h = 0; h < 12; h++) {
      final center = centroids[h]!;
      final rashiNum = houseRashi[h] ?? '';
      final planets = houses[h] ?? [];

      // Smaller boxes for corner houses (odd indices), wider for edge-center houses
      final isCorner = (h % 3 != 0); // corners are 1,2,4,5,7,8,10,11
      final w = isCorner ? boxW * 0.85 : boxW;
      final ht = isCorner ? boxH * 0.85 : boxH;

      widgets.add(Positioned(
        left: center.dx * s - w / 2,
        top: center.dy * s - ht / 2,
        width: w,
        height: ht,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rashi number label
            Text(rashiNum,
              style: TextStyle(
                fontSize: s * 0.028 * textScale,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF718096),
              ),
            ),
            // Planet chips
            ...planets.take(5),
          ],
        ),
      ));
    }

    // Center box (inner square from s/4 to 3s/4)
    widgets.add(Positioned(
      left: s * 0.25,
      top: s * 0.25,
      width: s * 0.50,
      height: s * 0.50,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 36, height: 36),
            const SizedBox(height: 2),
            Text(AppLocale.isHindi && centerLabel != null ? centerLabel!.split('\n').map((line) => tr(line)).join('\n') : (centerLabel ?? AppLocale.l('appName')),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12 * textScale,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFDD6B20),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    ));

    return widgets;
  }

  Widget _planetChip(String name, {PlanetInfo? info}) {
    final map = AppLocale.isHindi ? _shortNamesHi : _shortNamesKn;
    final shortName = map[name] ?? name;
    String displayText = shortName;
    bool isCombust = false;
    bool isVakri = false;

    if (info != null) {
      isCombust = info.isCombust;
      isVakri = info.speed < 0 && !['ರಾಹು', 'ಕೇತು'].contains(info.name);
      final degInRashi = info.longitude % 30;
      final totalSec = (degInRashi * 3600).round();
      int dg = totalSec ~/ 3600;
      int mn = (totalSec % 3600) ~/ 60;
      int sc = totalSec % 60;
      if (dg == 30) { dg = 29; mn = 59; sc = 59; }
      displayText = '$shortName $dg°${mn.toString().padLeft(2, '0')}\'';

      if (isVakri) displayText = '$displayText↩';
      if (isCombust) displayText = '($displayText)';
    }

    Color color;
    switch (name) {
      case 'ರವಿ': case 'ಸೂರ್ಯ': color = const Color(0xFFD69E2E); break;
      case 'ಚಂದ್ರ': color = const Color(0xFF4299E1); break;
      case 'ಕುಜ': case 'ಮಂಗಳ': color = const Color(0xFFE53E3E); break;
      case 'ಬುಧ': color = const Color(0xFF2F855A); break;
      case 'ಗುರು': color = const Color(0xFFDD6B20); break;
      case 'ಶುಕ್ರ': color = const Color(0xFFB83280); break;
      case 'ಶನಿ': color = const Color(0xFF1A202C); break;
      case 'ರಾಹು': color = const Color(0xFF744210); break;
      case 'ಕೇತು': color = const Color(0xFF4A5568); break;
      case 'ಲಗ್ನ': color = const Color(0xFFDD6B20); break;
      case 'ಮಾಂದಿ': color = const Color(0xFF553C9A); break;
      default: color = const Color(0xFF2B6CB0);
    }

    final opacity = isCombust ? 0.45 : 1.0;
    final isSelected = selectedPlanet != null && selectedPlanet == name;

    return GestureDetector(
      onTap: () { if (onPlanetTap != null) onPlanetTap!(name); },
      onLongPress: () { if (onPlanetLongPress != null) onPlanetLongPress!(name); },
      behavior: HitTestBehavior.opaque,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: (isSelected ? 12 : 9) * textScale,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: opacity),
          decoration: isSelected ? TextDecoration.underline : null,
        ),
      ),
    );
  }

  Widget _aroodhaChip(String label) {
    return Text(label,
      style: TextStyle(fontSize: 9 * textScale, fontWeight: FontWeight.w800, color: const Color(0xFFDD6B20)),
    );
  }

  Widget _sphutaChip(String label) {
    return Text(label,
      style: TextStyle(fontSize: 8 * textScale, fontWeight: FontWeight.w600, color: Colors.purple.withOpacity(0.6)),
    );
  }

  String _translateCenter(String label) {
    // Now handled inline via tr()
    return label.split('\n').map((line) => tr(line)).join('\n');
  }

  static const _shortNamesKn = <String, String>{
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
    'ಮಾಂದಿ': 'ಮಾಂ',
  };

  static const _shortNamesHi = <String, String>{
    'ರವಿ': 'सू', 'ಸೂರ್ಯ': 'सू',
    'ಚಂದ್ರ': 'चं',
    'ಕುಜ': 'मं', 'ಮಂಗಳ': 'मं',
    'ಬುಧ': 'बु',
    'ಗುರು': 'गु',
    'ಶುಕ್ರ': 'शु',
    'ಶನಿ': 'श',
    'ರಾಹು': 'रा',
    'ಕೇತು': 'के',
    'ಲಗ್ನ': 'ल',
    'ಮಾಂದಿ': 'मां',
  };
}

// ─────────────────────────────────────────────
// Custom painter for the North Indian diamond lines
// ─────────────────────────────────────────────
class _NorthIndianPainter extends CustomPainter {
  final Map<int, String> houseRashi;
  _NorthIndianPainter({required this.houseRashi});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePaint = Paint()
      ..color = const Color(0xFF718096)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    // Inner diamond (connecting midpoints of outer rectangle sides)
    final topMid = Offset(w / 2, 0);
    final rightMid = Offset(w, h / 2);
    final bottomMid = Offset(w / 2, h);
    final leftMid = Offset(0, h / 2);

    final diamondPath = Path()
      ..moveTo(topMid.dx, topMid.dy)
      ..lineTo(rightMid.dx, rightMid.dy)
      ..lineTo(bottomMid.dx, bottomMid.dy)
      ..lineTo(leftMid.dx, leftMid.dy)
      ..close();
    canvas.drawPath(diamondPath, linePaint);

    // Diagonal lines from corners to create 12 houses
    canvas.drawLine(Offset(0, 0), Offset(w, h), linePaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), linePaint);
  }

  @override
  bool shouldRepaint(covariant _NorthIndianPainter oldDelegate) => false;
}
