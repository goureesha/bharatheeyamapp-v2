import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/calculator.dart';

/// Generates a professional Kundali PDF with all astrological data
class PdfService {
  /// Generate and show print/share dialog for the Kundali PDF
  static Future<void> generateAndPrint({
    required String name,
    required String place,
    required DateTime dob,
    required int hour,
    required int minute,
    required String ampm,
    required double lat,
    required double lon,
    required KundaliResult result,
    required String notes,
  }) async {
    final pdf = pw.Document();
    final panchang = result.panchang;
    final planets = result.planets;

    final dateStr = '${dob.day.toString().padLeft(2,'0')}-${dob.month.toString().padLeft(2,'0')}-${dob.year}';
    final timeStr = '${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')} $ampm';

    // ─── Styles ───
    final titleStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4A148C'));
    final headStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#6A1B9A'));
    final cellStyle = pw.TextStyle(fontSize: 9);
    final cellBoldStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final smallStyle = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);

    // ════════════════════════════════════════════════
    // PAGE 1: Birth Details + Panchanga
    // ════════════════════════════════════════════════
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _pageHeader(name, dateStr, timeStr, place, titleStyle, smallStyle),
      footer: (ctx) => _pageFooter(ctx, smallStyle),
      build: (ctx) => [
        pw.SizedBox(height: 12),

        // Birth Details
        _sectionTitle('ಜನ್ಮ ವಿವರ / Birth Details', headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle,
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3E5F5')),
          cellAlignment: pw.Alignment.centerLeft,
          data: [
            ['ಹೆಸರು / Name', name],
            ['ಜನ್ಮ ದಿನಾಂಕ / DOB', dateStr],
            ['ಜನ್ಮ ಸಮಯ / Time', timeStr],
            ['ಸ್ಥಳ / Place', place],
            ['ಅಕ್ಷಾಂಶ / Lat', lat.toStringAsFixed(4)],
            ['ರೇಖಾಂಶ / Lon', lon.toStringAsFixed(4)],
          ],
        ),

        pw.SizedBox(height: 16),

        // Panchanga Data
        _sectionTitle('ಪಂಚಾಂಗ / Panchanga', headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle,
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
          data: [
            ['ವಿಷಯ', 'ವಿವರ'],
            ['ಸಂವತ್ಸರ', panchang.samvatsara],
            ['ಋತು', panchang.rutu],
            ['ವಾರ', panchang.vara],
            ['ತಿಥಿ', panchang.tithi],
            ['ನಕ್ಷತ್ರ', panchang.nakshatra],
            ['ಯೋಗ', panchang.yoga],
            ['ಕರಣ', panchang.karana],
            ['ಚಂದ್ರ ರಾಶಿ', panchang.chandraRashi],
            ['ಚಂದ್ರ ಮಾಸ', panchang.chandraMasa],
            ['ಸೌರ ಮಾಸ', panchang.souraMasa],
            ['ಸೂರ್ಯೋದಯ', panchang.sunrise],
            ['ಸೂರ್ಯಾಸ್ತ', panchang.sunset],
            ['ಉದಯಾದಿ ಘಟಿ', panchang.udayadiGhati],
            ['ಗತ ಘಟಿ', panchang.gataGhati],
            ['ಪರಮ ಘಟಿ', panchang.paramaGhati],
            ['ವಿಷ ಪ್ರಘಟಿ', panchang.vishaPraghati],
            ['ಅಮೃತ ಪ್ರಘಟಿ', panchang.amrutaPraghati],
          ],
        ),

        pw.SizedBox(height: 16),

        // Graha Sputa (Planet Positions)
        _sectionTitle('ಗ್ರಹ ಸ್ಥಿತಿ / Planet Positions', headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4A148C')),
          cellPadding: const pw.EdgeInsets.all(4),
          data: [
            ['ಗ್ರಹ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ', 'ಪಾದ', 'ವಕ್ರ/ಅಸ್ತ'],
            ...planets.entries.map((e) {
              final p = e.value;
              final status = <String>[];
              if (p.speed < 0) status.add('ವಕ್ರ');
              if (p.isCombust) status.add('ಅಸ್ತ');
              return [
                p.name,
                p.rashi,
                formatDeg(p.longitude),
                p.nakshatra,
                '${p.pada}',
                status.isEmpty ? '-' : status.join(', '),
              ];
            }),
          ],
        ),
      ],
    ));

    // ════════════════════════════════════════════════
    // PAGE 2: Dasha + Bhava + Upagraha
    // ════════════════════════════════════════════════
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => _pageHeader(name, dateStr, timeStr, place, titleStyle, smallStyle),
      footer: (ctx) => _pageFooter(ctx, smallStyle),
      build: (ctx) => [
        pw.SizedBox(height: 12),

        // Vimshottari Dasha
        _sectionTitle('ವಿಂಶೋತ್ತರೀ ದಶಾ / Vimshottari Dasha', headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1565C0')),
          cellPadding: const pw.EdgeInsets.all(4),
          data: [
            ['ದಶಾ ನಾಥ', 'ಆರಂಭ', 'ಅಂತ್ಯ'],
            ...result.dashas.map((d) => [
              d.lord,
              '${d.start.day.toString().padLeft(2,'0')}-${d.start.month.toString().padLeft(2,'0')}-${d.start.year}',
              '${d.end.day.toString().padLeft(2,'0')}-${d.end.month.toString().padLeft(2,'0')}-${d.end.year}',
            ]),
          ],
        ),

        pw.SizedBox(height: 16),

        // Bhava Madhya Sputa
        _sectionTitle('ಭಾವ ಮಧ್ಯ ಸ್ಪುಟ / Bhava Madhya', headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
          cellPadding: const pw.EdgeInsets.all(4),
          data: [
            ['ಭಾವ', 'ಸ್ಪುಟ'],
            ...result.bhavas.asMap().entries.map((e) => [
              'ಭಾವ ${e.key + 1}',
              formatDeg(e.value),
            ]),
          ],
        ),

        pw.SizedBox(height: 16),

        // Upagraha Sputa
        if (result.advSphutas.isNotEmpty) ...[
          _sectionTitle('ಉಪಗ್ರಹ ಸ್ಪುಟ / Upagraha Sputa', headStyle),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
            cellStyle: cellStyle,
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E65100')),
            cellPadding: const pw.EdgeInsets.all(4),
            data: [
              ['ಉಪಗ್ರಹ', 'ಸ್ಪುಟ'],
              ...result.advSphutas.entries.map((e) => [
                e.key,
                formatDeg(e.value),
              ]),
            ],
          ),
        ],
      ],
    ));

    // ════════════════════════════════════════════════
    // PAGE 3: Shadbala + Notes
    // ════════════════════════════════════════════════
    if (result.shadbala.isNotEmpty || notes.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _pageHeader(name, dateStr, timeStr, place, titleStyle, smallStyle),
        footer: (ctx) => _pageFooter(ctx, smallStyle),
        build: (ctx) => [
          pw.SizedBox(height: 12),

          if (result.shadbala.isNotEmpty) ...[
            _sectionTitle('ಷಡ್ಬಲ / Shadbala', headStyle),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
              cellStyle: cellStyle,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#880E4F')),
              cellPadding: const pw.EdgeInsets.all(4),
              data: [
                ['ಗ್ರಹ', 'ಒಟ್ಟು ಬಲ', 'ಅಗತ್ಯ', 'ಅನುಪಾತ'],
                ...result.shadbala.entries.map((e) {
                  final total = (e.value['total'] ?? 0.0) as double;
                  final needed = (e.value['needed'] ?? 1.0) as double;
                  final ratio = needed > 0 ? total / needed : 0.0;
                  return [
                    e.key,
                    total.toStringAsFixed(2),
                    needed.toStringAsFixed(2),
                    ratio.toStringAsFixed(2),
                  ];
                }),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          if (notes.isNotEmpty) ...[
            _sectionTitle('ಟಿಪ್ಪಣಿಗಳು / Notes', headStyle),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(notes, style: cellStyle),
            ),
          ],
        ],
      ));
    }

    // Show print/share dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Kundali_$name.pdf',
    );
  }

  static pw.Widget _pageHeader(String name, String date, String time, String place,
      pw.TextStyle titleStyle, pw.TextStyle smallStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('ಕುಂಡಲಿ / Kundali', style: titleStyle),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text('$date | $time | $place', style: smallStyle),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColor.fromHex('#4A148C'), thickness: 1.5),
      ],
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx, pw.TextStyle smallStyle) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey400),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: smallStyle),
          pw.Text('Generated: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}', style: smallStyle),
        ],
      ),
    ]);
  }

  static pw.Widget _sectionTitle(String text, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F3E5F5'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: style),
    );
  }
}
