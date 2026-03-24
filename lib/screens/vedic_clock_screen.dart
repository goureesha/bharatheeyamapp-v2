import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/calculator.dart';
import '../services/location_service.dart';

class VedicClockScreen extends StatefulWidget {
  const VedicClockScreen({super.key});
  @override
  State<VedicClockScreen> createState() => _VedicClockScreenState();
}

class _VedicClockScreenState extends State<VedicClockScreen> {
  String get _place => LocationService.place;
  double get _lat => LocationService.lat;
  double get _lon => LocationService.lon;
  Timer? _timer;
  Timer? _lagnaTimer;

  // Sunrise hour24 for today (IST, e.g. 6.39 = 6:23 AM)
  double _sunriseHour24 = 6.0;
  double _lagnaLong = 0;
  String _sunriseStr = '';
  String _sunsetStr = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initSunrise();
    // Update every second for live anu-vighati hand
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lagnaTimer?.cancel();
    super.dispose();
  }

  Future<void> _initSunrise() async {
    final now = DateTime.now();
    final y = now.year, m = now.month, d = now.day;
    final hour24 = now.hour + now.minute / 60.0 + now.second / 3600.0;

    // Get panchanga which includes sunrise/sunset
    final result = await AstroCalculator.calculate(
      year: y, month: m, day: d,
      hourUtcOffset: LocationService.tzOffset, hour24: hour24, lat: _lat, lon: _lon,
      ayanamsaMode: 'lahiri', trueNode: true,
    );

    if (result == null || !mounted) return;

    // Parse sunrise time from panchanga string (format: "06:23 AM" or "06:23:45 AM")
    final srParts = result.panchang.sunrise.split(':');
    final srHour = double.tryParse(srParts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 6;
    final srMin = double.tryParse(srParts.length > 1 ? srParts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0') ?? 0;
    final srSec = double.tryParse(srParts.length > 2 ? srParts[2].replaceAll(RegExp(r'[^0-9]'), '') : '0') ?? 0;

    setState(() {
      _sunriseHour24 = srHour + srMin / 60.0 + srSec / 3600.0;
      _sunriseStr = result.panchang.sunrise;
      _sunsetStr = result.panchang.sunset;
      _lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0;
      _initialized = true;
    });

    // Save sunrise for native widget
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sunrise_hour24', _sunriseHour24);

    // Recalculate lagna every 2 minutes
    _lagnaTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (!mounted) return;
      final n = DateTime.now();
      final h = n.hour + n.minute / 60.0 + n.second / 3600.0;
      final r = await AstroCalculator.calculate(
        year: n.year, month: n.month, day: n.day,
        hourUtcOffset: 5.5, hour24: h, lat: _lat, lon: _lon,
        ayanamsaMode: 'lahiri', trueNode: true,
      );
      if (r != null && mounted) {
        setState(() => _lagnaLong = r.planets['ಲಗ್ನ']?.longitude ?? 0);
      }
    });
  }

  /// Live udayadi ghati calculated from sunrise hour24
  double _currentGhati() {
    final now = DateTime.now();
    final nowHour24 = now.hour + now.minute / 60.0 + now.second / 3600.0;
    // Elapsed hours since sunrise, converted to ghati (1 day = 60 ghati, 1 day = 24 hours)
    final elapsedHours = nowHour24 - _sunriseHour24;
    return elapsedHours * (60.0 / 24.0); // hours to ghati
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final clockSize = (screenW < 500 ? screenW - 32 : 460).toDouble();
    final udGhati = _currentGhati();

    // Display values
    final gh = udGhati.floor() % 60;
    final viTotal = ((udGhati - udGhati.floor()) * 60);
    final vi = viTotal.floor();
    final av = ((viTotal - vi) * 60).floor();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ವೈದಿಕ ಘಡಿಯಾರ',
          style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText), elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ResponsiveCenter(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // LIVE CLOCK (all info inside)
              if (!_initialized)
                Padding(padding: const EdgeInsets.all(48), child: CircularProgressIndicator(color: kPurple2))
              else
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF0F0F1A),
                    boxShadow: [BoxShadow(color: const Color(0xFF5B2C6F).withOpacity(0.3), blurRadius: 24, spreadRadius: 2)],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    width: clockSize, height: clockSize,
                    child: CustomPaint(painter: _GhatiClockPainter(
                      udayadiGhati: udGhati,
                      lagnaLong: _lagnaLong,
                      ghati: gh,
                      vighati: vi,
                      anuVighati: av,
                      sunriseStr: _sunriseStr,
                      sunsetStr: _sunsetStr,
                    )),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          )),
        ),
      ),
    );
  }
}

// ============================================================
// GHATI CLOCK PAINTER - 3 hands + digital info inside clock
// ============================================================

class _GhatiClockPainter extends CustomPainter {
  final double udayadiGhati;
  final double lagnaLong;
  final int ghati;
  final int vighati;
  final int anuVighati;
  final String sunriseStr;
  final String sunsetStr;

  _GhatiClockPainter({
    required this.udayadiGhati,
    required this.lagnaLong,
    required this.ghati,
    required this.vighati,
    required this.anuVighati,
    required this.sunriseStr,
    required this.sunsetStr,
  });

  static double _d2r(double d) => d * pi / 180;

  static const _rashiColors = [
    Color(0xFFE74C3C), Color(0xFF27AE60), Color(0xFF3498DB), Color(0xFF8E44AD),
    Color(0xFFE67E22), Color(0xFF2ECC71), Color(0xFF2980B9), Color(0xFF9B59B6),
    Color(0xFFD35400), Color(0xFF1ABC9C), Color(0xFF2471A3), Color(0xFF7D3C98),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final center = Offset(cx, cy);
    final R = min(cx, cy) - 4;

    // Extract time components
    final ghatiF = udayadiGhati;
    final vighatiTotal = (ghatiF - ghatiF.floor()) * 60;
    final vighatiWhole = vighatiTotal.floor();
    final anuVighatiF = ((vighatiTotal - vighatiWhole) * 60);

    // Angles (360° / 60 = 6° per unit, top = 0)
    final ghatiAngle = _d2r((ghatiF % 60) * 6.0 - 90);
    final vighatiAngle = _d2r(vighatiTotal * 6.0 - 90);
    final anuAngle = _d2r(anuVighatiF * 6.0 - 90);

    // === BACKGROUND ===
    final bg = Paint()..shader = RadialGradient(
      colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: R));
    canvas.drawCircle(center, R, bg);

    // === OUTER GOLD RING ===
    canvas.drawCircle(center, R, Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.stroke..strokeWidth = 3);

    // === RASHI RING (rotates independently based on lagna) ===
    final ghatiDeg = (ghatiF % 60) * 6.0;
    final rashiOffset = ghatiDeg - lagnaLong;
    final outerR = R;
    final innerRashi = R * 0.92;
    final midRashi = (outerR + innerRashi) / 2;

    for (int i = 0; i < 12; i++) {
      final sa = _d2r(i * 30.0 + rashiOffset - 90);
      const sw = 30 * pi / 180;
      final p = Path()
        ..moveTo(cx + innerRashi * cos(sa), cy + innerRashi * sin(sa))
        ..arcTo(Rect.fromCircle(center: center, radius: outerR), sa, sw, false)
        ..arcTo(Rect.fromCircle(center: center, radius: innerRashi), sa + sw, -sw, false)
        ..close();
      canvas.drawPath(p, Paint()..color = _rashiColors[i].withOpacity(0.25));
      canvas.drawPath(p, Paint()..color = _rashiColors[i].withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 0.8);

      final la = _d2r(i * 30.0 + 15 + rashiOffset - 90);
      _txt(canvas, knRashi[i], cx + midRashi * cos(la), cy + midRashi * sin(la),
        Colors.white.withOpacity(0.9), outerR * 0.055, true);
    }

    canvas.drawCircle(center, innerRashi, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1);

    // === GHATI MARKERS (0–59) ===
    for (int i = 0; i < 60; i++) {
      final a = _d2r(i * 6.0 - 90);
      final isMajor = i % 5 == 0;
      final len = isMajor ? R * 0.08 : R * 0.03;
      final w = isMajor ? 2.5 : 0.8;
      final r1 = innerRashi;
      final r2 = r1 - len;
      final c = isMajor ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.2);
      canvas.drawLine(
        Offset(cx + r2 * cos(a), cy + r2 * sin(a)),
        Offset(cx + r1 * cos(a), cy + r1 * sin(a)),
        Paint()..color = c..strokeWidth = w);

      if (isMajor) {
        final numR = R * 0.72;
        final label = i == 0 ? 'ಉದಯ' : '$i';
        final fontSize = i == 0 ? R * 0.052 : R * 0.046;
        final color = i == 0 ? Colors.amber : Colors.white.withOpacity(0.7);
        _txt(canvas, label, cx + numR * cos(a), cy + numR * sin(a), color, fontSize, i == 0 || i % 15 == 0);
      }
    }

    // === INNER RING ===
    canvas.drawCircle(center, R * 0.62, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // === DIGITAL INFO INSIDE CLOCK (above center) ===
    // Digital ghati display
    final digitalY = cy - R * 0.28;
    final digitFs = R * 0.085;
    final labelFs = R * 0.035;

    // Ghati value (red)
    final ghStr = '$ghati';
    final viStr = vighati.toString().padLeft(2, '0');
    final avStr = anuVighati.toString().padLeft(2, '0');
    final fullDigital = '$ghStr : $viStr : $avStr';
    _txt(canvas, fullDigital, cx, digitalY, Colors.white.withOpacity(0.95), digitFs, true);

    // Labels below digits
    _txt(canvas, 'ಘಟಿ    ವಿಘಟಿ   ಅನುವಿಘಟಿ', cx, digitalY + digitFs * 0.9, Colors.white.withOpacity(0.4), labelFs, false);

    // === SUNRISE/SUNSET INFO (below center) ===
    final infoY = cy + R * 0.28;
    final infoFs = R * 0.042;

    // Sunrise
    _txt(canvas, '☀ ಉದಯ $sunriseStr', cx - R * 0.18, infoY,
      const Color(0xFFFFAB40), infoFs, true);
    // Sunset
    _txt(canvas, '🌙 ಅಸ್ತ $sunsetStr', cx + R * 0.18, infoY,
      const Color(0xFF7986CB), infoFs, true);

    // === GHATI HAND (short, thick, red) ===
    _drawHand(canvas, cx, cy, ghatiAngle, R * 0.45, 4.5, const Color(0xFFE53E3E), R * 0.08);

    // === VIGHATI HAND (medium, blue) ===
    _drawHand(canvas, cx, cy, vighatiAngle, R * 0.60, 3.0, const Color(0xFF2B6CB0), R * 0.06);

    // === ANU-VIGHATI HAND (long, thin, green) ===
    _drawHand(canvas, cx, cy, anuAngle, R * 0.75, 1.5, const Color(0xFF38A169), R * 0.04);

    // === CENTER HUB ===
    canvas.drawCircle(center, 14, Paint()..shader = RadialGradient(
      colors: [const Color(0xFFD4AF37), const Color(0xFF8B6914)],
    ).createShader(Rect.fromCircle(center: center, radius: 14)));
    canvas.drawCircle(center, 14, Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF1A1A2E));

    // === LEGEND ===
    final legendY = cy + R * 0.42;
    _txt(canvas, '● ಘಟಿ', cx - R * 0.22, legendY, const Color(0xFFE53E3E), R * 0.038, true);
    _txt(canvas, '● ವಿಘಟಿ', cx, legendY, const Color(0xFF2B6CB0), R * 0.038, true);
    _txt(canvas, '● ಅನುವಿಘಟಿ', cx + R * 0.25, legendY, const Color(0xFF38A169), R * 0.038, true);
  }

  void _drawHand(Canvas canvas, double cx, double cy, double angle, double length, double width, Color color, double tailLen) {
    final tipX = cx + length * cos(angle);
    final tipY = cy + length * sin(angle);
    final tailX = cx - tailLen * cos(angle);
    final tailY = cy - tailLen * sin(angle);

    canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY),
      Paint()..color = color.withOpacity(0.2)..strokeWidth = width + 4..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY),
      Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);

    final aW = width * 2.5;
    final aL = width * 4;
    final b1x = tipX - aL * cos(angle) + aW / 2 * cos(angle + pi / 2);
    final b1y = tipY - aL * sin(angle) + aW / 2 * sin(angle + pi / 2);
    final b2x = tipX - aL * cos(angle) - aW / 2 * cos(angle + pi / 2);
    final b2y = tipY - aL * sin(angle) - aW / 2 * sin(angle + pi / 2);
    canvas.drawPath(Path()..moveTo(tipX, tipY)..lineTo(b1x, b1y)..lineTo(b2x, b2y)..close(),
      Paint()..color = color);
  }

  void _txt(Canvas c, String t, double x, double y, Color col, double fs, bool b) {
    final p = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: col, fontSize: fs, fontWeight: b ? FontWeight.w800 : FontWeight.normal)),
      textDirection: TextDirection.ltr)..layout();
    p.paint(c, Offset(x - p.width / 2, y - p.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GhatiClockPainter o) =>
    o.udayadiGhati != udayadiGhati || o.lagnaLong != lagnaLong ||
    o.ghati != ghati || o.vighati != vighati || o.anuVighati != anuVighati;
}
