import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';

// ─────────────────────────────────────── colors
const _kPurple = PdfColor(0.231, 0.122, 0.549);
const _kGold   = PdfColor(0.72, 0.56, 0.10);
const _kMaroon = PdfColor(0.45, 0.05, 0.08);
const _kLightBg = PdfColor(0.97, 0.95, 0.99);
const _kBorder  = PdfColor(0.80, 0.75, 0.88);

// ─────────────────────────────────────── rashi codes (2-letter)
const _rashiCode = [
  'Me','Vr','Mi','Ka','Si','Kn',
  'Tu','Vs','Dh','Mk','Km','Pi'
];

// ─────────────────────────────────────── planet abbreviations
const _planetCode = {
  'Sun':'Su', 'Moon':'Mo', 'Mars':'Ma', 'Mercury':'Me',
  'Jupiter':'Ju', 'Venus':'Ve', 'Saturn':'Sa',
  'Rahu':'Ra', 'Ketu':'Ke', 'Mandi':'Mn', 'Gulika':'Gu',
};

// South-Indian 4×4 grid: each value = 0-based rashi offset from Lagna (null=centre)
const _grid = <int?>[
  11, 0,    1,    2,
  10, null, null, 3,
   9, null, null, 4,
   8, 7,    6,    5,
];

class PdfService {

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
    // ── Fonts ────────────────────────────────────────────────────
    pw.Font baseFont  = pw.Font.helvetica();
    pw.Font boldFont  = pw.Font.helveticaBold();

    // Try to load Kannada font for value text
    pw.Font? knFont;
    pw.Font? knBold;
    try {
      knFont = await PdfGoogleFonts.notoSansKannadaRegular();
      knBold = await PdfGoogleFonts.notoSansKannadaBold();
    } catch (_) {}

    // Use Kannada fonts if loaded, else fall back to Helvetica
    final vFont  = knFont  ?? baseFont;
    final vBold  = knBold  ?? boldFont;

    // ── Ganapati image ───────────────────────────────────────────
    pw.MemoryImage? ganImg;
    try {
      final bytes = await rootBundle.load('assets/images/ganapati.png');
      ganImg = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    // ── Derived data ─────────────────────────────────────────────
    final dateStr =
        '${dob.day.toString().padLeft(2,'0')}/'
        '${dob.month.toString().padLeft(2,'0')}/'
        '${dob.year}';
    final timeStr =
        '${hour.toString().padLeft(2,'0')}:'
        '${minute.toString().padLeft(2,'0')} $ampm';

    final lagnaIdx = (result.bhavas[0] / 30).floor() % 12;
    final d1Map    = _buildMap(result.planets, lagnaIdx, 1);
    final d9Map    = _buildMap(result.planets, lagnaIdx, 9);
    final bhvMap   = _buildBhavaMap(result.planets, result.bhavas);

    // ── Build PDF ────────────────────────────────────────────────
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
      header: (ctx) => _header(
          ganImg, name, place, dateStr, timeStr, extraInfo,
          baseFont, boldFont, vFont, vBold, ctx),
      footer: (ctx) => _footer(ctx, baseFont),
      build: (ctx) => [

        // ── Row: D1 chart + D9 chart side-by-side ────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _chartBlock(
              'Rashi Kundali (D1)', d1Map, lagnaIdx,
              boldFont, vFont, vBold)),
            pw.SizedBox(width: 10),
            pw.Expanded(child: _chartBlock(
              'Navamsha Kundali (D9)', d9Map, lagnaIdx,
              boldFont, vFont, vBold)),
          ],
        ),

        pw.SizedBox(height: 12),

        // ── Bhava Kundali full width ──────────────────────────────
        _chartBlock(
          'Bhava Kundali', bhvMap, lagnaIdx,
          boldFont, vFont, vBold, fullWidth: true),

        pw.SizedBox(height: 14),

        // ── Panchanga ─────────────────────────────────────────────
        _sectionBar('Panchanga', boldFont),
        pw.SizedBox(height: 4),
        _kvTable([
          ['Vara (Day)',    result.panchang.vara],
          ['Tithi',        result.panchang.tithi],
          ['Nakshatra',    result.panchang.nakshatra],
          ['Yoga',         result.panchang.yoga],
          ['Karana',       result.panchang.karana],
          ['Chandra Rashi', result.panchang.chandraRashi],
          ['Samvatsara',   result.panchang.samvatsara],
          ['Chandra Masa', result.panchang.chandraMasa],
          ['Soura Masa',   result.panchang.souraMasa],
          ['Surya Nakshatra', result.panchang.suryaNakshatra],
          ['Sunrise',      result.panchang.sunrise],
          ['Sunset',       result.panchang.sunset],
          ['Dasha Lord',   result.panchang.dashaLord],
          ['Dasha Balance', result.panchang.dashaBalance],
        ], baseFont, boldFont, vFont),

        pw.SizedBox(height: 14),

        // ── Planet positions ──────────────────────────────────────
        _sectionBar('Graha Sphuta (Planet Positions)', boldFont),
        pw.SizedBox(height: 4),
        _planetTable(result.planets, baseFont, boldFont, vFont),

        pw.SizedBox(height: 14),

        // ── Bhava cusps ───────────────────────────────────────────
        _sectionBar('Bhava Sphuta (House Cusps)', boldFont),
        pw.SizedBox(height: 4),
        _bhavaTable(result.bhavas, baseFont, boldFont, vFont),

        pw.SizedBox(height: 14),

        // ── Dasha ─────────────────────────────────────────────────
        _sectionBar('Vimshottari Dasha', boldFont),
        pw.SizedBox(height: 4),
        _dashaTable(result.dashas, baseFont, boldFont, vFont),

        if (notes.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          _sectionBar('Notes', boldFont),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kBorder),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(notes,
                style: pw.TextStyle(font: vFont, fontSize: 9)),
          ),
        ],
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '${name.isEmpty ? 'Kundali' : name.replaceAll(' ', '_')}.pdf',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // CHART GRID
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _chartBlock(
    String title,
    Map<int, List<String>> planetMap,
    int lagnaIdx,
    pw.Font boldFont,
    pw.Font vFont,
    pw.Font vBold, {
    bool fullWidth = false,
  }) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
      // Title bar
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        color: _kMaroon,
        child: pw.Text(title,
            style: pw.TextStyle(
                font: boldFont, fontSize: 9.5, color: PdfColors.white)),
      ),
      // 4×4 South Indian chart grid
      pw.AspectRatio(
        aspectRatio: 1.0,
        child: pw.Table(
          border: pw.TableBorder.all(color: _kPurple, width: 0.8),
          children: List.generate(4, (row) {
            return pw.TableRow(
              children: List.generate(4, (col) {
                final idx = row * 4 + col;
                final slot = _grid[idx];
                if (slot == null) {
                  return _centerCell(row, col, boldFont);
                }
                final rashi = (lagnaIdx + slot) % 12;
                final planets = planetMap[slot] ?? [];
                return _gridCell(slot + 1, rashi, planets, vFont, vBold);
              }),
            );
          }),
        ),
      ),
    ]);
  }

  static pw.Widget _centerCell(int row, int col, pw.Font boldFont) {
    final showLabel = row == 1 && col == 1;
    return pw.Container(
      color: _kLightBg,
      child: showLabel
          ? pw.Center(
              child: pw.Text('Bharatheeyam',
                  style: pw.TextStyle(
                      font: boldFont, fontSize: 5.5, color: _kPurple)))
          : pw.SizedBox(),
    );
  }

  static pw.Widget _gridCell(
    int houseNum,
    int rashiIdx,
    List<String> planets,
    pw.Font vFont,
    pw.Font vBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2.5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // House number + rashi code
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('$houseNum',
                  style: pw.TextStyle(
                      font: vFont, fontSize: 6, color: PdfColors.grey700)),
              pw.Text(_rashiCode[rashiIdx],
                  style: pw.TextStyle(
                      font: vBold, fontSize: 6, color: _kMaroon)),
            ],
          ),
          // Planets
          if (planets.isNotEmpty)
            pw.Wrap(
              children: planets.map((p) {
                final isLagna = p == 'L';
                return pw.Text('$p ',
                    style: pw.TextStyle(
                        font: vBold,
                        fontSize: isLagna ? 8.5 : 7.5,
                        color: isLagna ? _kGold : PdfColors.black));
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PLANET / BHAVA MAPS
  // ─────────────────────────────────────────────────────────────────

  static Map<int, List<String>> _buildMap(
      Map<String, PlanetInfo> planets, int lagnaIdx, int varga) {
    final map = <int, List<String>>{};
    for (int i = 0; i < 12; i++) map[i] = [];

    for (final e in planets.entries) {
      final lon = e.value.longitude;
      final rashiIdx = varga == 9 ? _d9Rashi(lon) : (lon / 30).floor() % 12;
      final house = (rashiIdx - lagnaIdx + 12) % 12;
      map[house]!.add(_planetCode[e.key] ?? e.key.substring(0, 2));
    }
    map[0]!.insert(0, 'L'); // Lagna marker
    return map;
  }

  static Map<int, List<String>> _buildBhavaMap(
      Map<String, PlanetInfo> planets, List<double> bhavas) {
    final map = <int, List<String>>{};
    for (int i = 0; i < 12; i++) map[i] = [];

    for (final e in planets.entries) {
      final lon = e.value.longitude;
      int house = 11;
      for (int i = 0; i < 12; i++) {
        final s = bhavas[i] % 360;
        final en = bhavas[(i + 1) % 12] % 360;
        if (s < en) {
          if (lon >= s && lon < en) { house = i; break; }
        } else {
          if (lon >= s || lon < en) { house = i; break; }
        }
      }
      map[house]!.add(_planetCode[e.key] ?? e.key.substring(0, 2));
    }
    map[0]!.insert(0, 'L');
    return map;
  }

  static int _d9Rashi(double lon) {
    final block = (lon / 30).floor() % 4;
    final start = [0, 9, 6, 3][block];
    return (start + ((lon % 30) / 3.33333).floor()) % 12;
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE HEADER
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _header(
    pw.MemoryImage? ganImg,
    String name,
    String place,
    String date,
    String time,
    Map<String, String> extra,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font vFont,
    pw.Font vBold,
    pw.Context ctx,
  ) {
    if (ctx.pageNumber > 1) {
      // Compact header for subsequent pages
      return pw.Column(children: [
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bharatheeyam — Kundali',
                  style: pw.TextStyle(font: boldFont, fontSize: 9, color: _kPurple)),
              pw.Text(name.isEmpty ? '' : name,
                  style: pw.TextStyle(font: boldFont, fontSize: 9, color: _kMaroon)),
            ]),
        pw.Divider(color: _kPurple, thickness: 0.8),
        pw.SizedBox(height: 4),
      ]);
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
      // Ganapati
      if (ganImg != null) ...[
        pw.Center(child: pw.Image(ganImg, height: 60, fit: pw.BoxFit.contain)),
        pw.SizedBox(height: 6),
      ],

      // Gold top rule
      pw.Container(height: 2.5, color: _kGold),
      pw.SizedBox(height: 2),
      pw.Container(height: 1, color: _kMaroon),
      pw.SizedBox(height: 6),

      // Title
      pw.Text('JANMA KUNDALI',
          style: pw.TextStyle(
              font: boldFont, fontSize: 16,
              letterSpacing: 3, color: _kMaroon)),
      pw.SizedBox(height: 2),
      pw.Text('Bharatheeyam — Vedic Astrology',
          style: pw.TextStyle(font: baseFont, fontSize: 9, color: _kPurple)),
      pw.SizedBox(height: 8),

      // Info box
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
            color: _kLightBg,
            border: pw.Border.all(color: _kBorder),
            borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(children: [
          _infoRow2('Name', name.isEmpty ? '—' : name, 'Place', place,
              baseFont, boldFont, vFont, vBold),
          pw.SizedBox(height: 5),
          _infoRow2('Date of Birth', date, 'Time', time,
              baseFont, boldFont, vFont, vBold),
          if ((extra['gender'] ?? '').isNotEmpty || (extra['gotra'] ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _infoRow2('Gender', extra['gender'] ?? '', 'Gotra', extra['gotra'] ?? '',
                baseFont, boldFont, vFont, vBold),
          ],
          if ((extra['father'] ?? '').isNotEmpty || (extra['mother'] ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 5),
            _infoRow2("Father's Name", extra['father'] ?? '',
                "Mother's Name", extra['mother'] ?? '',
                baseFont, boldFont, vFont, vBold),
          ],
        ]),
      ),

      pw.SizedBox(height: 4),
      pw.Container(height: 1.5, color: _kPurple),
      pw.SizedBox(height: 8),
    ]);
  }

  static pw.Widget _infoRow2(
    String k1, String v1, String k2, String v2,
    pw.Font baseFont, pw.Font boldFont, pw.Font vFont, pw.Font vBold,
  ) {
    return pw.Row(children: [
      pw.Expanded(child: _kvItem(k1, v1, baseFont, boldFont, vFont)),
      pw.SizedBox(width: 16),
      pw.Expanded(child: _kvItem(k2, v2, baseFont, boldFont, vFont)),
    ]);
  }

  static pw.Widget _kvItem(
      String k, String v, pw.Font baseFont, pw.Font boldFont, pw.Font vFont) {
    return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('$k: ',
          style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: _kPurple)),
      pw.Flexible(
        child: pw.Text(v,
            style: pw.TextStyle(font: vFont, fontSize: 8.5, color: PdfColors.black)),
      ),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _footer(pw.Context ctx, pw.Font baseFont) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300, thickness: 0.5),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Bharatheeyam — Vedic Astrology App',
            style: pw.TextStyle(
                font: baseFont, fontSize: 7, color: PdfColors.grey500)),
        pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(
                font: baseFont, fontSize: 7, color: PdfColors.grey500)),
      ]),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────
  // SECTION BAR
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _sectionBar(String title, pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const pw.BoxDecoration(color: _kPurple),
      child: pw.Text(title,
          style: pw.TextStyle(
              font: boldFont, fontSize: 10, color: PdfColors.white)),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TABLES
  // ─────────────────────────────────────────────────────────────────

  static pw.Widget _kvTable(
    List<List<String>> rows,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font vFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.asMap().entries.map((e) {
        final even = e.key % 2 == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
              color: even ? const PdfColor(0.97, 0.96, 1.0) : PdfColors.white),
          children: [
            _cell(e.value[0], boldFont, 9),
            _cell(e.value[1], vFont, 9),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _planetTable(
    Map<String, PlanetInfo> planets,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font vFont,
  ) {
    final headers = ['Planet', 'Rashi', 'Nakshatra', 'Pada', 'Longitude'];
    final rows = planets.entries.map((e) {
      final p = e.value;
      final knName = planetNames[e.key] ?? e.key;
      return [knName, p.rashi, p.nakshatra, '${p.pada}', formatDeg(p.longitude)];
    }).toList();
    return _dataTable(headers, rows, baseFont, boldFont, vFont);
  }

  static pw.Widget _bhavaTable(
    List<double> bhavas,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font vFont,
  ) {
    final headers = ['Bhava', 'Rashi', 'Longitude'];
    final rows = bhavas.asMap().entries.map((e) {
      final rIdx = (e.value / 30).floor() % 12;
      return ['${e.key + 1}', knRashi[rIdx], formatDeg(e.value)];
    }).toList();
    return _dataTable(headers, rows, baseFont, boldFont, vFont);
  }

  static pw.Widget _dashaTable(
    List<DashaEntry> dashas,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font vFont,
  ) {
    final headers = ['Dasha Lord', 'Start', 'End'];
    final rows = <List<String>>[];
    for (final d in dashas) {
      final lord = planetNames[d.lord] ?? d.lord;
      rows.add([lord, _fmt(d.start), _fmt(d.end)]);
      for (final a in d.antardashas) {
        rows.add(['  ↳ ${planetNames[a.lord] ?? a.lord}', _fmt(a.start), _fmt(a.end)]);
      }
    }
    return _dataTable(headers, rows, baseFont, boldFont, vFont);
  }

  static pw.Widget _dataTable(
    List<String> headers,
    List<List<String>> rows,
    pw.Font baseFont,
    pw.Font boldFont,
    pw.Font vFont,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _kBorder, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kPurple),
          children: headers
              .map((h) => _cell(h, boldFont, 9, color: PdfColors.white))
              .toList(),
        ),
        ...rows.asMap().entries.map((e) {
          final even = e.key % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: even
                    ? const PdfColor(0.97, 0.96, 1.0)
                    : PdfColors.white),
            children: e.value
                .map((v) => _cell(v, vFont, 8.5))
                .toList(),
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font font,
    double size, {
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: size, color: color)),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/'
      '${d.month.toString().padLeft(2,'0')}/'
      '${d.year}';
}
