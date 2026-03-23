import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../constants/strings.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';

class VedicClockScreen extends StatefulWidget {
  const VedicClockScreen({super.key});
  @override
  State<VedicClockScreen> createState() => _VedicClockScreenState();
}

class _VedicClockScreenState extends State<VedicClockScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _loading = false;
  String _place = 'Yellapur';
  double _lat = 14.98;
  double _lon = 74.73;
  Map<String, double> _planetLongs = {};
  double _lagnaLong = 0;

  @override
  void initState() { super.initState(); _calculate(); }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    try {
      final hour24 = _selectedTime.hour + _selectedTime.minute / 60.0;
      final result = await AstroCalculator.calculate(
        year: _selectedDate.year, month: _selectedDate.month, day: _selectedDate.day,
        hourUtcOffset: 5.5, hour24: hour24, lat: _lat, lon: _lon,
        ayanamsaMode: 'lahiri', trueNode: true,
      );
      if (result != null && mounted) {
        final longs = <String, double>{};
        for (final e in result.planets.entries) longs[e.key] = e.value.longitude;
        setState(() { _planetLongs = longs; _lagnaLong = longs['ಲಗ್ನ'] ?? 0; _loading = false; });
      } else { if (mounted) setState(() => _loading = false); }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year}';
    final timeStr = _selectedTime.format(context);
    final screenW = MediaQuery.of(context).size.width;
    final clockSize = (screenW < 500 ? screenW - 40 : 460).toDouble();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kCard,
        title: Text('ವೈದಿಕ ಘಡಿಯಾರ / Vedic Clock',
          style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
        iconTheme: IconThemeData(color: kText), elevation: 0,
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(child: Column(children: [
          // Date/Time Picker
          AppCard(child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _selectedDate,
                  firstDate: DateTime(1800), lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!));
                if (d != null) { setState(() => _selectedDate = d); _calculate(); }
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ದಿನಾಂಕ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: kPurple2), const SizedBox(width: 6),
                  Text(dateStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                ]),
              ]),
            )),
            Container(width: 1, height: 36, color: kBorder), const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: _selectedTime,
                  builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.light(primary: kPurple2)), child: child!));
                if (t != null) { setState(() => _selectedTime = t); _calculate(); }
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ಸಮಯ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time, size: 16, color: kPurple2), const SizedBox(width: 6),
                  Text(timeStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                ]),
              ]),
            )),
          ])),
          // Location
          AppCard(child: Row(children: [
            Icon(Icons.location_on, size: 18, color: kPurple2), const SizedBox(width: 8),
            Text('ಸ್ಥಳ: ', style: TextStyle(fontWeight: FontWeight.w800, color: kPurple2, fontSize: 14)),
            Text(_place, style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(onPressed: () { setState(() { _selectedDate = DateTime.now(); _selectedTime = TimeOfDay.now(); }); _calculate(); },
              child: Text('ಈಗ', style: TextStyle(color: kPurple2, fontSize: 12, fontWeight: FontWeight.w700))),
          ])),

          // CLOCK
          if (_loading)
            Padding(padding: const EdgeInsets.all(48), child: CircularProgressIndicator(color: kPurple2))
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF0F0F1A),
                boxShadow: [BoxShadow(color: const Color(0xFF5B2C6F).withOpacity(0.3), blurRadius: 24, spreadRadius: 2)],
              ),
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: clockSize, height: clockSize,
                child: CustomPaint(painter: _RashiClockPainter(planetLongs: _planetLongs, lagnaLong: _lagnaLong)),
              ),
            ),

          // Planet Legend
          if (!_loading && _planetLongs.isNotEmpty)
            AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ಗ್ರಹ ಸ್ಥಾನಗಳು', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: _buildLegendChips()),
            ])),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  List<Widget> _buildLegendChips() {
    final order = ['ಲಗ್ನ','ರವಿ','ಚಂದ್ರ','ಕುಜ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ','ರಾಹು','ಕೇತು'];
    return order.where((n) => _planetLongs.containsKey(n)).map((name) {
      final deg = _planetLongs[name]!;
      final ri = (deg / 30).floor() % 12;
      final totalGhati = deg / 6.0;
      final gh = totalGhati.floor();
      final vi = ((totalGhati - gh) * 60).round();
      final c = _RashiClockPainter.planetColor(name);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$name ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText)),
          Text('${knRashi[ri]} $gh.${'$vi'.padLeft(2, '0')} ಘ', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ]),
      );
    }).toList();
  }
}

// ============================================================
// PREMIUM RASHI CLOCK PAINTER
// ============================================================

class _RashiClockPainter extends CustomPainter {
  final Map<String, double> planetLongs;
  final double lagnaLong;
  _RashiClockPainter({required this.planetLongs, required this.lagnaLong});

  static const _rashiColors = [
    Color(0xFFE74C3C), Color(0xFF27AE60), Color(0xFF3498DB), Color(0xFF8E44AD),
    Color(0xFFE67E22), Color(0xFF2ECC71), Color(0xFF2980B9), Color(0xFF9B59B6),
    Color(0xFFD35400), Color(0xFF1ABC9C), Color(0xFF2471A3), Color(0xFF7D3C98),
  ];

  static Color planetColor(String name) {
    switch (name) {
      case 'ಲಗ್ನ': return const Color(0xFFE53E3E);
      case 'ರವಿ':  return const Color(0xFFFF8C00);
      case 'ಚಂದ್ರ': return const Color(0xFFB0BEC5);
      case 'ಕುಜ':  return const Color(0xFFC62828);
      case 'ಬುಧ':  return const Color(0xFF43A047);
      case 'ಗುರು': return const Color(0xFFFDD835);
      case 'ಶುಕ್ರ': return const Color(0xFF26A69A);
      case 'ಶನಿ':  return const Color(0xFF5C6BC0);
      case 'ರಾಹು': return const Color(0xFF546E7A);
      case 'ಕೇತು': return const Color(0xFF8D6E63);
      default: return const Color(0xFF95A5A6);
    }
  }

  static String _label(String n) {
    const m = {'ಲಗ್ನ':'ಲ','ರವಿ':'ಸೂ','ಚಂದ್ರ':'ಚಂ','ಕುಜ':'ಕು','ಬುಧ':'ಬು','ಗುರು':'ಗು','ಶುಕ್ರ':'ಶು','ಶನಿ':'ಶ','ರಾಹು':'ರಾ','ಕೇತು':'ಕೇ'};
    return m[n] ?? '';
  }

  static double _d2r(double d) => d * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final center = Offset(cx, cy);
    final R = min(cx, cy) - 4;
    final outerR = R;
    final innerR = R * 0.72;
    final midR = (outerR + innerR) / 2;
    final tickR = innerR - 2;

    // === BACKGROUND ===
    final bg = Paint()..shader = RadialGradient(
      colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: outerR));
    canvas.drawCircle(center, outerR, bg);

    // === RASHI RING ===
    for (int i = 0; i < 12; i++) {
      final sa = _d2r(i * 30.0 - 90);
      const sw = 30 * pi / 180;
      // Segment fill
      final p = Path()
        ..moveTo(cx + innerR * cos(sa), cy + innerR * sin(sa))
        ..arcTo(Rect.fromCircle(center: center, radius: outerR), sa, sw, false)
        ..arcTo(Rect.fromCircle(center: center, radius: innerR), sa + sw, -sw, false)
        ..close();
      canvas.drawPath(p, Paint()..color = _rashiColors[i].withOpacity(0.30));
      canvas.drawPath(p, Paint()..color = _rashiColors[i].withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1);

      // Rashi name
      final la = _d2r(i * 30.0 + 15 - 90);
      _txt(canvas, knRashi[i], cx + midR * cos(la), cy + midR * sin(la),
        Colors.white.withOpacity(0.95), outerR * 0.058, true);
    }

    // === GOLD BORDERS ===
    canvas.drawCircle(center, outerR, Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawCircle(center, innerR, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // === DEGREE TICKS ===
    for (int d = 0; d < 360; d++) {
      final a = _d2r(d.toDouble() - 90);
      final m30 = d % 30 == 0;
      final m10 = d % 10 == 0;
      final m5 = d % 5 == 0;
      if (!m30 && !m10 && !m5) continue;
      final len = m30 ? 10.0 : (m10 ? 6.0 : 3.0);
      final w = m30 ? 2.0 : (m10 ? 1.0 : 0.5);
      final c = m30 ? Colors.white.withOpacity(0.7) : (m10 ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.15));
      canvas.drawLine(
        Offset(cx + (tickR - len) * cos(a), cy + (tickR - len) * sin(a)),
        Offset(cx + tickR * cos(a), cy + tickR * sin(a)),
        Paint()..color = c..strokeWidth = w);
      if (m30) {
        final ghati = d ~/ 6; // 360° / 60 ghati = 6° per ghati
        final label = ghati == 0 ? 'ಉದಯ' : '$ghati ಘ';
        _txt(canvas, label, cx + (tickR - 16) * cos(a), cy + (tickR - 16) * sin(a),
          ghati == 0 ? Colors.amber.withOpacity(0.9) : Colors.white.withOpacity(0.4), outerR * 0.035, ghati == 0);
      }
    }

    // === ARROW HANDS (Lagna only) ===
    final order = ['ಲಗ್ನ'];
    for (final name in order) {
      final deg = planetLongs[name];
      if (deg == null) continue;
      final isL = name == 'ಲಗ್ನ';
      final isM = name == 'ರವಿ' || name == 'ಚಂದ್ರ' || isL;
      final hLen = isL ? tickR * 0.94 : (isM ? tickR * 0.80 : tickR * 0.66);
      final tLen = hLen * 0.12; // tail
      final sW = isL ? 3.0 : (isM ? 2.2 : 1.5);
      final aW = isL ? 12.0 : (isM ? 9.0 : 7.0); // arrowhead width
      final aL = isL ? 18.0 : (isM ? 14.0 : 10.0); // arrowhead length
      final color = planetColor(name);
      final ang = _d2r(deg - 90);

      final tipX = cx + hLen * cos(ang);
      final tipY = cy + hLen * sin(ang);
      final tailX = cx - tLen * cos(ang);
      final tailY = cy - tLen * sin(ang);

      // Glow
      canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY),
        Paint()..color = color.withOpacity(0.25)..strokeWidth = sW + 4..strokeCap = StrokeCap.round);
      // Shaft
      canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY),
        Paint()..color = color..strokeWidth = sW..strokeCap = StrokeCap.round);

      // Arrowhead
      final b1x = tipX - aL * cos(ang) + aW / 2 * cos(ang + pi / 2);
      final b1y = tipY - aL * sin(ang) + aW / 2 * sin(ang + pi / 2);
      final b2x = tipX - aL * cos(ang) - aW / 2 * cos(ang + pi / 2);
      final b2y = tipY - aL * sin(ang) - aW / 2 * sin(ang + pi / 2);
      canvas.drawPath(Path()..moveTo(tipX, tipY)..lineTo(b1x, b1y)..lineTo(b2x, b2y)..close(),
        Paint()..color = color);
      canvas.drawPath(Path()..moveTo(tipX, tipY)..lineTo(b1x, b1y)..lineTo(b2x, b2y)..close(),
        Paint()..color = Colors.white.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 0.8);

      // Ghati-Vighati pill label at tip
      final totalGhati = deg / 6.0; // 360° = 60 ghati, so 1° = 1/6 ghati
      final gh = totalGhati.floor();
      final vi = ((totalGhati - gh) * 60).round();
      final lr = hLen + (isL ? 16 : 14).toDouble();
      final lx = cx + lr * cos(ang);
      final ly = cy + lr * sin(ang);
      final lt = '$gh.${'$vi'.padLeft(2, '0')} ಘ';
      final tp = TextPainter(
        text: TextSpan(text: lt, style: TextStyle(color: Colors.white, fontSize: outerR * 0.032, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr)..layout();
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lx, ly), width: tp.width + 10, height: tp.height + 6), const Radius.circular(4)),
        Paint()..color = color.withOpacity(0.9));
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));

      // Planet symbol dot near center
      final sR = isL ? 10.0 : 7.5;
      final sd = hLen * 0.18;
      final sx = cx + sd * cos(ang);
      final sy = cy + sd * sin(ang);
      canvas.drawCircle(Offset(sx, sy), sR, Paint()..color = color);
      canvas.drawCircle(Offset(sx, sy), sR, Paint()..color = Colors.white.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.2);
      _txt(canvas, _label(name), sx, sy, Colors.white, sR * 1.3, true);
    }

    // === CENTER ===
    canvas.drawCircle(center, 12, Paint()..shader = RadialGradient(
      colors: [const Color(0xFFD4AF37), const Color(0xFF8B6914)],
    ).createShader(Rect.fromCircle(center: center, radius: 12)));
    canvas.drawCircle(center, 12, Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF1A1A2E));
  }

  void _txt(Canvas c, String t, double x, double y, Color col, double fs, bool b) {
    final p = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: col, fontSize: fs, fontWeight: b ? FontWeight.w800 : FontWeight.normal)),
      textDirection: TextDirection.ltr)..layout();
    p.paint(c, Offset(x - p.width / 2, y - p.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RashiClockPainter o) =>
    o.planetLongs != planetLongs || o.lagnaLong != lagnaLong;
}
