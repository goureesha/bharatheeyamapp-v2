import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';

// App theme purple in PDF space (normalized 0-1)
const _kPurple = PdfColor(0.231, 0.122, 0.549);
const _kPurpleLight = PdfColor(0.231, 0.122, 0.549, 0.12);
const _kGold   = PdfColor(0.85, 0.72, 0.25);
const _kMaroon = PdfColor(0.50, 0.05, 0.10);

// South-Indian 4×4 grid: each value = 0-based rashi offset from Lagna (null = centre)
const _grid = [
  11, 0,    1,    2,
  10, null, null, 3,
   9, null, null, 4,
   8, 7,    6,    5,
];

class PdfService {
  // ─────────────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ─────────────────────────────────────────────────────────────────
  static Future<void> downloadKundaliPdf({
    required BuildContext context,
    required KundaliResult result,
    required String name,
    required String place,
    required DateTime dob,
    required int hour,
    required int minute,
    required String ampm,
    String notes = '',
    Map<String, String> extraInfo = const {},
  }) async {
    // Load fonts & Ganapati image
    final kannadaFont  = await PdfGoogleFonts.notoSansKannadaRegular();
    final kannadaBold  = await PdfGoogleFonts.notoSansKannadaBold();

    pw.MemoryImage? ganapatiImg;
    try {
      final bytes = await rootBundle.load('assets/images/ganapati.png');
      ganapatiImg = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final pdf = pw.Document();

    final dateStr =
        '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';

    // ─── D1 Rashi chart planet map ───────────────────────────────
    final lagnaRashiIdx = (result.bhavas[0] / 30).floor() % 12;
    final d1Map = _buildPlanetMap(result.planets, lagnaRashiIdx, varga: 1);
    final d9Map = _buildPlanetMap(result.planets, lagnaRashiIdx, varga: 9);
    // Bhava: map each planet to its bhava (house number)
    final bhavaMap = _buildBhavaMap(result.planets, result.bhavas);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont(base: kannadaFont, bold: kannadaBold),
      header: (ctx) => _pageHeader(
        ganapatiImg, name, place, dateStr, timeStr, extraInfo,
        kannadaFont, kannadaBold,
      ),
      footer: (ctx) => _pageFooter(ctx, kannadaFont),
      build: (ctx) => [
        // ─── Page 1: Rashi + Navamsha charts ───────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _chartSection('ರಾಶಿ ಕುಂಡಲಿ', d1Map, lagnaRashiIdx, kannadaFont, kannadaBold)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _chartSection('ನವಾಂಶ ಕುಂಡಲಿ', d9Map, lagnaRashiIdx, kannadaFont, kannadaBold)),
          ],
        ),

        pw.SizedBox(height: 14),

        // ─── Bhava Kundali ─────────────────────────────────────────
        _chartSection('ಭಾವ ಕುಂಡಲಿ', bhavaMap, lagnaRashiIdx, kannadaFont, kannadaBold),

        pw.SizedBox(height: 14),

        // ─── Panchanga ──────────────────────────────────────────────
        _sectionTitle('ಪಂಚಾಂಗ', kannadaBold),
        pw.SizedBox(height: 4),
        _twoColTable([
          ['ವಾರ',       result.panchang.vara],
          ['ತಿಥಿ',      result.panchang.tithi],
          ['ನಕ್ಷತ್ರ',   result.panchang.nakshatra],
          ['ಯೋಗ',      result.panchang.yoga],
          ['ಕರಣ',      result.panchang.karana],
          ['ಚಂದ್ರ ರಾಶಿ', result.panchang.chandraRashi],
          ['ಸಂವತ್ಸರ',  result.panchang.samvatsara],
          ['ಚಾಂದ್ರ ಮಾಸ', result.panchang.chandraMasa],
          ['ಸೌರ ಮಾಸ',  result.panchang.souraMasa],
          ['ಸೂರ್ಯ ನಕ್ಷತ್ರ', result.panchang.suryaNakshatra],
          ['ಸೂರ್ಯೋದಯ',  result.panchang.sunrise],
          ['ಸೂರ್ಯಾಸ್ತ',  result.panchang.sunset],
          ['ದಶ ಒಡೆಯ',  result.panchang.dashaLord],
          ['ದಶ ಶೇಷ',   result.panchang.dashaBalance],
        ], kannadaFont, kannadaBold),

        pw.SizedBox(height: 14),

        // ─── Planet Positions ────────────────────────────────────────
        _sectionTitle('ಗ್ರಹ ಸ್ಫುಟ', kannadaBold),
        pw.SizedBox(height: 4),
        _planetTable(result.planets, kannadaFont, kannadaBold),

        pw.SizedBox(height: 14),

        // ─── Bhava cusps table ───────────────────────────────────────
        _sectionTitle('ಭಾವ ಸ್ಫುಟ', kannadaBold),
        pw.SizedBox(height: 4),
        _bhavaCuspTable(result.bhavas, kannadaFont, kannadaBold),

        pw.SizedBox(height: 14),

        // ─── Dasha ──────────────────────────────────────────────────
        _sectionTitle('ವಿಂಶೋತ್ತರಿ ದಶ', kannadaBold),
        pw.SizedBox(height: 4),
        _dashaTable(result.dashas, kannadaFont, kannadaBold),

        // ─── Notes ───────────────────────────────────────────────────
        if (notes.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _sectionTitle('ಟಿಪ್ಪಣಿ', kannadaBold),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(notes, style: pw.TextStyle(font: kannadaFont, fontSize: 9)),
          ),
        ],
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '${name.isEmpty ? 'ಜಾತಕ' : name}_kundali.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PLANET MAP BUILDERS
  // ─────────────────────────────────────────────────────────────────

  /// Returns Map<houseIndex (0-11), List<abbreviation>>
  static Map<int, List<String>> _buildPlanetMap(
      Map<String, PlanetInfo> planets, int lagnaIdx, {required int varga}) {
    final map = <int, List<String>>{};
    for (int i = 0; i < 12; i++) map[i] = [];

    for (final entry in planets.entries) {
      final p = entry.value;
      int rashiIdx;
      if (varga == 1) {
        rashiIdx = (p.longitude / 30).floor() % 12;
      } else {
        // D9 Navamsha
        rashiIdx = _navamshaRashi(p.longitude);
      }
      // house offset from lagna
      final houseIdx = (rashiIdx - lagnaIdx + 12) % 12;
      map[houseIdx]!.add(_planetAbbr(entry.key));
    }
    // Add Lagna marker in house 0
    map[0]!.insert(0, 'ಲ');
    return map;
  }

  /// Map each planet to the bhava (house) it's in.
  static Map<int, List<String>> _buildBhavaMap(
      Map<String, PlanetInfo> planets, List<double> bhavas) {
    final map = <int, List<String>>{};
    for (int i = 0; i < 12; i++) map[i] = [];

    for (final entry in planets.entries) {
      final lon = entry.value.longitude;
      // find which bhava this longitude falls in
      int house = 0;
      for (int i = 0; i < 12; i++) {
        final start = bhavas[i] % 360;
        final end   = bhavas[(i + 1) % 12] % 360;
        if (start < end) {
          if (lon >= start && lon < end) { house = i; break; }
        } else {
          if (lon >= start || lon < end) { house = i; break; }
        }
      }
      map[house]!.add(_planetAbbr(entry.key));
    }
    map[0]!.insert(0, 'ಲ');
    return map;
  }

  static int _navamshaRashi(double lon) {
    final block = (lon / 30).floor() % 4;
    final start = [0, 9, 6, 3][block];
    final steps = ((lon % 30) / 3.33333).floor();
    return (start + steps) % 12;
  }

  static String _planetAbbr(String english) {
    const abbr = {
      'Sun': 'ರ', 'Moon': 'ಚ', 'Mars': 'ಕು', 'Mercury': 'ಬು',
      'Jupiter': 'ಗು', 'Venus': 'ಶು', 'Saturn': 'ಶ',
      'Rahu': 'ರಾ', 'Ketu': 'ಕೇ', 'Mandi': 'ಮಾ', 'Gulika': 'ಗು',
    };
    return abbr[english] ?? english.substring(0, 1);
  }

  // ─────────────────────────────────────────────────────────────────
  // SOUTH-INDIAN CHART WIDGET
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _chartSection(String title,
      Map<int, List<String>> planetMap, int lagnaIdx,
      pw.Font font, pw.Font boldFont) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      _sectionTitle(title, boldFont),
      pw.SizedBox(height: 4),
      pw.AspectRatio(
        aspectRatio: 1,
        child: pw.Table(
          border: pw.TableBorder.all(color: _kPurple, width: 1),
          children: List.generate(4, (row) {
            return pw.TableRow(
              children: List.generate(4, (col) {
                final gridIdx = row * 4 + col;
                final houseOffset = _grid[gridIdx]; // null = centre

                if (houseOffset == null) {
                  // Centre cell
                  return pw.Container(
                    color: _kPurpleLight,
                    child: pw.Center(
                      child: (row == 1 && col == 1)
                          ? pw.Text('ಭಾರತೀಯಮ್',
                              style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 6,
                                  color: _kPurple))
                          : pw.SizedBox(),
                    ),
                  );
                }

                // Rashi index for this cell
                final rashiIdx = (lagnaIdx + houseOffset) % 12;
                final rashiName = knRashi[rashiIdx];
                final planets  = planetMap[houseOffset] ?? [];
                final houseNum = houseOffset + 1;

                return pw.Container(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      // House number + rashi name
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('$houseNum',
                              style: pw.TextStyle(
                                  font: font, fontSize: 5.5,
                                  color: PdfColors.grey600)),
                          pw.Text(rashiName,
                              style: pw.TextStyle(
                                  font: font, fontSize: 5.5,
                                  color: _kPurple)),
                        ],
                      ),
                      // Planets
                      if (planets.isNotEmpty)
                        pw.Wrap(
                          children: planets
                              .map((p) => pw.Text('$p ',
                                  style: pw.TextStyle(
                                      font: boldFont,
                                      fontSize: 7,
                                      color: p == 'ಲ'
                                          ? _kGold
                                          : PdfColors.black)))
                              .toList(),
                        ),
                    ],
                  ),
                );
              }),
            );
          }),
        ),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE HEADER (Ganapati + personal info)
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _pageHeader(
    pw.MemoryImage? ganapatiImg,
    String name,
    String place,
    String date,
    String time,
    Map<String, String> extra,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Column(children: [
      // Ganapati image banner
      if (ganapatiImg != null) ...[
        pw.Center(
          child: pw.Image(ganapatiImg, height: 56, fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(height: 4),
      ],

      // Decorative top line
      pw.Container(height: 2, color: _kMaroon),
      pw.Container(height: 1, color: _kGold,
          margin: const pw.EdgeInsets.only(top: 1, bottom: 4)),

      // Title
      pw.Center(
        child: pw.Text('ಜನ್ಮ ಕುಂಡಲಿ',
            style: pw.TextStyle(
                font: boldFont, fontSize: 14, color: _kMaroon)),
      ),
      pw.SizedBox(height: 6),

      // Personal info grid
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            color: _kPurpleLight,
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(children: [
          _infoRow('ಹೆಸರು', name.isEmpty ? '—' : name,
                   'ಸ್ಥಳ', place, font, boldFont),
          pw.SizedBox(height: 4),
          _infoRow('ಜನ್ಮ ದಿನ', date,
                   'ಜನ್ಮ ಸಮಯ', time, font, boldFont),
          if (extra['gender']!.isNotEmpty || extra['gotra']!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _infoRow('ಲಿಂಗ', extra['gender'] ?? '',
                     'ಗೋತ್ರ', extra['gotra'] ?? '', font, boldFont),
          ],
          if ((extra['father'] ?? '').isNotEmpty || (extra['mother'] ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _infoRow('ತಂದೆ', extra['father'] ?? '',
                     'ತಾಯಿ', extra['mother'] ?? '', font, boldFont),
          ],
        ]),
      ),

      pw.Container(height: 1, color: _kPurple,
          margin: const pw.EdgeInsets.only(top: 6, bottom: 4)),
    ]);
  }

  static pw.Widget _infoRow(
      String k1, String v1, String k2, String v2,
      pw.Font font, pw.Font boldFont) {
    return pw.Row(children: [
      pw.Expanded(child: pw.Row(children: [
        pw.Text('$k1: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: _kPurple)),
        pw.Flexible(child: pw.Text(v1, style: pw.TextStyle(font: font, fontSize: 8))),
      ])),
      pw.SizedBox(width: 8),
      pw.Expanded(child: pw.Row(children: [
        pw.Text('$k2: ', style: pw.TextStyle(font: boldFont, fontSize: 8, color: _kPurple)),
        pw.Flexible(child: pw.Text(v2, style: pw.TextStyle(font: font, fontSize: 8))),
      ])),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE FOOTER
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _pageFooter(pw.Context ctx, pw.Font font) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('ಭಾರತೀಯಮ್ — Vedic Astrology',
            style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey500)),
        pw.Text('ಪುಟ ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 7, color: PdfColors.grey500)),
      ]),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // TABLE HELPERS  (all labels in Kannada)
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(String t, pw.Font boldFont) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        color: _kPurple,
        child: pw.Text(t,
            style: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white)),
      );

  static pw.Widget _twoColTable(
      List<List<String>> rows, pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.asMap().entries.map((e) {
        final isEven = e.key % 2 == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey100 : PdfColors.white),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Text(e.value[0],
                  style: pw.TextStyle(font: boldFont, fontSize: 8.5)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Text(e.value[1],
                  style: pw.TextStyle(font: font, fontSize: 8.5)),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _planetTable(
      Map<String, PlanetInfo> planets, pw.Font font, pw.Font boldFont) {
    final headers = ['ಗ್ರಹ', 'ರಾಶಿ', 'ನಕ್ಷತ್ರ', 'ಪಾದ', 'ಸ್ಫುಟ'];
    final rows = planets.entries.map((e) {
      final p = e.value;
      final knName = planetNames[e.key] ?? e.key;
      return [knName, p.rashi, p.nakshatra, '${p.pada}', formatDeg(p.longitude)];
    }).toList();
    return _dataTable(headers, rows, font, boldFont);
  }

  static pw.Widget _bhavaCuspTable(
      List<double> bhavas, pw.Font font, pw.Font boldFont) {
    final headers = ['ಭಾವ', 'ರಾಶಿ', 'ಸ್ಫುಟ'];
    final rows = bhavas.asMap().entries.map((e) {
      final rashiIdx = (e.value / 30).floor() % 12;
      return ['${e.key + 1}', knRashi[rashiIdx], formatDeg(e.value)];
    }).toList();
    return _dataTable(headers, rows, font, boldFont);
  }

  static pw.Widget _dashaTable(
      List<DashaEntry> dashas, pw.Font font, pw.Font boldFont) {
    final headers = ['ದಶ', 'ಆರಂಭ', 'ಅಂತ'];
    final rows = <List<String>>[];
    for (final d in dashas) {
      final knLord = dashaLords.contains(d.lord)
          ? d.lord
          : (planetNames[d.lord] ?? d.lord);
      rows.add([knLord, _fmtDate(d.start), _fmtDate(d.end)]);
      for (final a in d.antardashas) {
        final knALord = planetNames[a.lord] ?? a.lord;
        rows.add(['  └ $knALord', _fmtDate(a.start), _fmtDate(a.end)]);
      }
    }
    return _dataTable(headers, rows, font, boldFont);
  }

  static pw.Widget _dataTable(List<String> headers, List<List<String>> rows,
      pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kPurple),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 3),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 8.5,
                            color: PdfColors.white)),
                  ))
              .toList(),
        ),
        ...rows.asMap().entries.map((e) {
          final isEven = e.key % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.grey100 : PdfColors.white),
            children: e.value
                .map((cell) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2.5),
                      child: pw.Text(cell,
                          style: pw.TextStyle(font: font, fontSize: 8))))
                .toList(),
          );
        }),
      ],
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
