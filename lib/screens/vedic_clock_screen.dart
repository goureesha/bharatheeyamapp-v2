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

  // Calculated values
  double _udayadiGhati = 0; // ghati elapsed since sunrise
  String _sunriseStr = '';
  String _sunsetStr = '';
  Map<String, double> _planetLongs = {};
  double _lagnaLong = 0;

  @override
  void initState() { super.initState(); _calculate(); }

  Future<void> _calculate() async {
    setState(() => _loading = true);
    try {
      final y = _selectedDate.year;
      final m = _selectedDate.month;
      final d = _selectedDate.day;
      final hour24 = _selectedTime.hour + _selectedTime.minute / 60.0;

      // Calculate sunrise/sunset for this date
      final srSs = Ephemeris.findSunriseSetForDate(y, m, d, _lat, _lon);
      final srJd = srSs[0]; // sunrise JD
      final ssJd = srSs[1]; // sunset JD

      // Birth JD
      final jdBirth = Ephemeris.dateToJd(y, m, d, hour24 - 5.5); // IST to UT

      // Udayadi ghati: time from sunrise in ghati (1 day = 60 ghati)
      double udGhati;
      if (jdBirth >= srJd) {
        udGhati = (jdBirth - srJd) * 60.0;
      } else {
        // Before today's sunrise — measure from previous day's sunrise
        final prev = DateTime(y, m, d - 1);
        final prevSrSs = Ephemeris.findSunriseSetForDate(prev.year, prev.month, prev.day, _lat, _lon);
        udGhati = (jdBirth - prevSrSs[0]) * 60.0;
      }

      // Get planet positions
      final result = await AstroCalculator.calculate(
        year: y, month: m, day: d,
        hourUtcOffset: 5.5, hour24: hour24, lat: _lat, lon: _lon,
        ayanamsaMode: 'lahiri', trueNode: true,
      );

      if (mounted) {
        final longs = <String, double>{};
        if (result != null) {
          for (final e in result.planets.entries) longs[e.key] = e.value.longitude;
        }
        setState(() {
          _udayadiGhati = udGhati;
          _sunriseStr = formatTimeFromJd(srJd);
          _sunsetStr = formatTimeFromJd(ssJd);
          _planetLongs = longs;
          _lagnaLong = longs['ಲಗ್ನ'] ?? 0;
          _loading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day.toString().padLeft(2,'0')}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.year}';
    final timeStr = _selectedTime.format(context);
    final screenW = MediaQuery.of(context).size.width;
    final clockSize = (screenW < 500 ? screenW - 40 : 460).toDouble();

    // Display values
    final gh = _udayadiGhati.floor();
    final viTotal = ((_udayadiGhati - gh) * 60);
    final vi = viTotal.floor();
    final av = ((viTotal - vi) * 60).floor();

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
                child: CustomPaint(painter: _GhatiClockPainter(udayadiGhati: _udayadiGhati)),
              ),
            ),

          // Ghati display
          if (!_loading)
            AppCard(child: Column(children: [
              Text('ಉದಯಾದಿ ಘಟಿ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kPurple2)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ghatiDigit('$gh', 'ಘಟಿ', const Color(0xFFE53E3E)),
                Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText)),
                _ghatiDigit('${vi.toString().padLeft(2, '0')}', 'ವಿಘಟಿ', const Color(0xFF2B6CB0)),
                Text(' : ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kText)),
                _ghatiDigit('${av.toString().padLeft(2, '0')}', 'ಅನುವಿಘಟಿ', const Color(0xFF38A169)),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _infoChip(Icons.wb_sunny, 'ಉದಯ', _sunriseStr, Colors.orange),
                _infoChip(Icons.nights_stay, 'ಅಸ್ತ', _sunsetStr, Colors.indigo),
              ]),
            ])),

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

  Widget _ghatiDigit(String val, String label, Color color) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 4),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
    ]);
  }

  List<Widget> _buildLegendChips() {
    final order = ['ಲಗ್ನ','ರವಿ','ಚಂದ್ರ','ಕುಜ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ','ರಾಹು','ಕೇತು'];
    return order.where((n) => _planetLongs.containsKey(n)).map((name) {
      final deg = _planetLongs[name]!;
      final ri = (deg / 30).floor() % 12;
      final dInR = deg % 30;
      final d = dInR.floor();
      final m = ((dInR - d) * 60).floor();
      final s = (((dInR - d) * 60 - m) * 60).floor();
      final c = _GhatiClockPainter.planetColor(name);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$name ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kText)),
          Text('${knRashi[ri]} $d°${m.toString().padLeft(2,'0')}\'${s.toString().padLeft(2,'0')}"', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ]),
      );
    }).toList();
  }
}

// ============================================================
// GHATI CLOCK PAINTER - 3 hands: Ghati, Vighati, Anu-Vighati
// ============================================================

class _GhatiClockPainter extends CustomPainter {
  final double udayadiGhati; // total ghati elapsed since sunrise
  _GhatiClockPainter({required this.udayadiGhati});

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

  static double _d2r(double d) => d * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final center = Offset(cx, cy);
    final R = min(cx, cy) - 4;

    // Extract time components
    final ghati = udayadiGhati; // total ghati
    final ghatiWhole = ghati.floor() % 60;
    final vighatiTotal = (ghati - ghati.floor()) * 60;
    final vighatiWhole = vighatiTotal.floor();
    final anuVighati = ((vighatiTotal - vighatiWhole) * 60);

    // Angles (360° / 60 = 6° per unit, top = 0)
    // Ghati hand: one revolution = 60 ghati
    final ghatiAngle = _d2r((ghati % 60) * 6.0 - 90);
    // Vighati hand: one revolution = 60 vighati (= 1 ghati)
    final vighatiAngle = _d2r(vighatiTotal * 6.0 - 90);
    // Anu-Vighati hand: one revolution = 60 anu-vighati (= 1 vighati)
    final anuAngle = _d2r(anuVighati * 6.0 - 90);

    // === BACKGROUND ===
    final bg = Paint()..shader = RadialGradient(
      colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: R));
    canvas.drawCircle(center, R, bg);

    // === OUTER GOLD RING ===
    canvas.drawCircle(center, R, Paint()..color = const Color(0xFFD4AF37)..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(center, R * 0.92, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1);

    // === GHATI MARKERS (0–59) ===
    for (int i = 0; i < 60; i++) {
      final a = _d2r(i * 6.0 - 90);
      final isMajor = i % 5 == 0; // 0, 5, 10, 15...
      final len = isMajor ? R * 0.08 : R * 0.03;
      final w = isMajor ? 2.5 : 0.8;
      final r1 = R * 0.92;
      final r2 = r1 - len;
      final c = isMajor ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.2);
      canvas.drawLine(
        Offset(cx + r2 * cos(a), cy + r2 * sin(a)),
        Offset(cx + r1 * cos(a), cy + r1 * sin(a)),
        Paint()..color = c..strokeWidth = w);

      // Numbers at major positions
      if (isMajor) {
        final numR = R * 0.78;
        final label = i == 0 ? 'ಉದಯ' : '$i';
        final fontSize = i == 0 ? R * 0.045 : R * 0.042;
        final color = i == 0 ? Colors.amber : Colors.white.withOpacity(0.7);
        final bold = i == 0 || i % 15 == 0;
        _txt(canvas, label, cx + numR * cos(a), cy + numR * sin(a), color, fontSize, bold);
      }
    }

    // === INNER DECORATIVE RING ===
    canvas.drawCircle(center, R * 0.68, Paint()..color = const Color(0xFFD4AF37).withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 0.5);

    // === GHATI HAND (short, thick, red) ===
    _drawHand(canvas, cx, cy, ghatiAngle, R * 0.50, 4.5, const Color(0xFFE53E3E), R * 0.08);

    // === VIGHATI HAND (medium, blue) ===
    _drawHand(canvas, cx, cy, vighatiAngle, R * 0.68, 3.0, const Color(0xFF2B6CB0), R * 0.06);

    // === ANU-VIGHATI HAND (long, thin, green) ===
    _drawHand(canvas, cx, cy, anuAngle, R * 0.82, 1.5, const Color(0xFF38A169), R * 0.04);

    // === CENTER HUB ===
    canvas.drawCircle(center, 14, Paint()..shader = RadialGradient(
      colors: [const Color(0xFFD4AF37), const Color(0xFF8B6914)],
    ).createShader(Rect.fromCircle(center: center, radius: 14)));
    canvas.drawCircle(center, 14, Paint()..color = Colors.white.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF1A1A2E));

    // === LEGEND at bottom inside clock ===
    final legendY = cy + R * 0.35;
    _txt(canvas, '● ಘಟಿ', cx - R * 0.22, legendY, const Color(0xFFE53E3E), R * 0.035, true);
    _txt(canvas, '● ವಿಘಟಿ', cx, legendY, const Color(0xFF2B6CB0), R * 0.035, true);
    _txt(canvas, '● ಅನುವಿಘಟಿ', cx + R * 0.25, legendY, const Color(0xFF38A169), R * 0.035, true);
  }

  void _drawHand(Canvas canvas, double cx, double cy, double angle, double length, double width, Color color, double tailLen) {
    final tipX = cx + length * cos(angle);
    final tipY = cy + length * sin(angle);
    final tailX = cx - tailLen * cos(angle);
    final tailY = cy - tailLen * sin(angle);

    // Glow
    canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY),
      Paint()..color = color.withOpacity(0.2)..strokeWidth = width + 4..strokeCap = StrokeCap.round);
    // Shaft
    canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY),
      Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);

    // Arrowhead
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
  bool shouldRepaint(covariant _GhatiClockPainter o) => o.udayadiGhati != udayadiGhati;
}
