import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';

class PdfService {
  /// Generates and downloads/prints a full Kundali PDF for [result].
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
  }) async {
    final pdf = pw.Document();

    final dateStr =
        '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
    final panchang = result.panchang;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _buildHeader(name, place, dateStr, timeStr),
      footer: (ctx) => _buildFooter(ctx),
      build: (ctx) => [
        // ─── Panchanga ──────────────────────────────────────────────
        _sectionTitle('ಪಂಚಾಂಗ'),
        pw.SizedBox(height: 6),
        _twoColTable([
          ['ವಾರ', panchang.vara],
          ['ತಿಥಿ', panchang.tithi],
          ['ನಕ್ಷತ್ರ', panchang.nakshatra],
          ['ಯೋಗ', panchang.yoga],
          ['ಕರಣ', panchang.karana],
          ['ಚಂದ್ರ ರಾಶಿ', panchang.chandraRashi],
          ['ಸಂವತ್ಸರ', panchang.samvatsara],
          ['ಚಾಂದ್ರ ಮಾಸ', panchang.chandraMasa],
          ['ಸೌರ ಮಾಸ', panchang.souraMasa],
          ['ಸೂರ್ಯ ನಕ್ಷತ್ರ', panchang.suryaNakshatra],
          ['ಉದಯ', panchang.sunrise],
          ['ಅಸ್ತ', panchang.sunset],
          ['ದಶ ಒಡೆಯ', panchang.dashaLord],
          ['ದಶ ಶೇಷ', panchang.dashaBalance],
        ]),

        pw.SizedBox(height: 16),

        // ─── Planet Positions ────────────────────────────────────────
        _sectionTitle('ಗ್ರಹ ಸ್ಫುಟ'),
        pw.SizedBox(height: 6),
        _planetTable(result.planets),

        pw.SizedBox(height: 16),

        // ─── Bhava Cusps ────────────────────────────────────────────
        _sectionTitle('ಭಾವ ಸ್ಫುಟ'),
        pw.SizedBox(height: 6),
        _bhavaTable(result.bhavas),

        pw.SizedBox(height: 16),

        // ─── Dasha ──────────────────────────────────────────────────
        _sectionTitle('ವಿಂಶೋತ್ತರಿ ದಶ'),
        pw.SizedBox(height: 6),
        _dashaTable(result.dashas),

        // ─── Notes ───────────────────────────────────────────────────
        if (notes.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _sectionTitle('ಟಿಪ್ಪಣಿ'),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(notes,
                style: const pw.TextStyle(fontSize: 10),
                textDirection: pw.TextDirection.ltr),
          ),
        ],
      ],
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '${name.isEmpty ? 'ಜಾತಕ' : name}_kundali.pdf',
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────
  static pw.Widget _sectionTitle(String title) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: const PdfColor.fromInt(0xFF3B1F8C),
        child: pw.Text(title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            )),
      );

  // ─── Page header ─────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
      String name, String place, String date, String time) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ಭಾರತೀಯಮ್',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF3B1F8C),
                  )),
              pw.Text('ಜಾತಕ ವಿವರ',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey600)),
            ]),
        pw.Divider(color: const PdfColor.fromInt(0xFF3B1F8C), thickness: 1.5),
        pw.Row(children: [
          pw.Text('ಹೆಸರು: ',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${name.isEmpty ? '-' : name}   ',
              style: const pw.TextStyle(fontSize: 10)),
          pw.Text('ಸ್ಥಳ: ',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('$place   ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('ದಿನಾಂಕ: ',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('$date   ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('ಸಮಯ: ',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text(time, style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.SizedBox(height: 8),
      ]);

  // ─── Page footer ─────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context ctx) => pw.Column(children: [
        pw.Divider(color: PdfColors.grey300),
        pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ಭಾರತೀಯಮ್ - Vedic Astrology',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey500)),
              pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey500)),
            ]),
      ]);

  // ─── Two-column key-value table ──────────────────────────────────────────
  static pw.Widget _twoColTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
      },
      children: rows.asMap().entries.map((entry) {
        final isEven = entry.key % 2 == 0;
        final row = entry.value;
        return pw.TableRow(
          decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey100 : PdfColors.white),
          children: [
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(row[0],
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(row[1],
                  style: const pw.TextStyle(fontSize: 9)),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── Planet table ────────────────────────────────────────────────────────
  static pw.Widget _planetTable(Map<String, PlanetInfo> planets) {
    final headers = ['ಗ್ರಹ', 'ರಾಶಿ', 'ನಕ್ಷತ್ರ', 'ಪಾದ', 'ಸ್ಫುಟ'];
    final rows = planets.entries.map((e) {
      final p = e.value;
      return [
        e.key,
        p.rashi,
        p.nakshatra,
        p.pada.toString(),
        formatDeg(p.longitude),
      ];
    }).toList();

    return _dataTable(headers, rows);
  }

  // ─── Bhava table ─────────────────────────────────────────────────────────
  static pw.Widget _bhavaTable(List<double> bhavas) {
    final headers = ['ಭಾವ', 'ರಾಶಿ', 'ಸ್ಫುಟ'];
    final rashis = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯ',
                    'ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
    final rows = bhavas.asMap().entries.map((e) {
      final rashi = rashis[(e.value / 30).floor() % 12];
      return [(e.key + 1).toString(), rashi, formatDeg(e.value)];
    }).toList();
    return _dataTable(headers, rows);
  }

  // ─── Dasha table ─────────────────────────────────────────────────────────
  static pw.Widget _dashaTable(List<DashaEntry> dashas) {
    final headers = ['ದಶ', 'ಆರಂಭ', 'ಅಂತ'];
    final rows = <List<String>>[];
    for (final d in dashas) {
      rows.add([
        d.lord,
        '${d.start.day}/${d.start.month}/${d.start.year}',
        '${d.end.day}/${d.end.month}/${d.end.year}',
      ]);
      // Add antardashas indented
      for (final a in d.antardashas) {
        rows.add([
          '  └ ${a.lord}',
          '${a.start.day}/${a.start.month}/${a.start.year}',
          '${a.end.day}/${a.end.month}/${a.end.year}',
        ]);
      }
    }
    return _dataTable(headers, rows);
  }

  // ─── Generic data table ──────────────────────────────────────────────────
  static pw.Widget _dataTable(List<String> headers, List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        // Header
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColor.fromInt(0xFF3B1F8C)),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9)),
                  ))
              .toList(),
        ),
        // Data rows
        ...rows.asMap().entries.map((entry) {
          final isEven = entry.key % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.grey100 : PdfColors.white),
            children: entry.value
                .map((cell) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      child: pw.Text(cell,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }
}
