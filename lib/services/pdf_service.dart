import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/calculator.dart';
import '../widgets/common.dart';

/// Generates a professional Kundali PDF with all astrological data
class PdfService {
  /// Generate and show print/share dialog for the Kundali PDF
  static Future<Uint8List> _generatePdfBytes({
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
        _sectionTitle(AppLocale.l('pdfBirthDetails'), headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle,
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F3E5F5')),
          cellAlignment: pw.Alignment.centerLeft,
          data: [
            [AppLocale.l('pdfName'), name],
            [AppLocale.l('pdfDob'), dateStr],
            [AppLocale.l('pdfTime'), timeStr],
            [AppLocale.l('pdfPlace'), place],
            [AppLocale.l('pdfLat'), lat.toStringAsFixed(4)],
            [AppLocale.l('pdfLon'), lon.toStringAsFixed(4)],
          ],
        ),

        pw.SizedBox(height: 16),

        // Panchanga Data
        _sectionTitle(AppLocale.l('pdfPanchanga'), headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle,
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E8F5E9')),
          data: [
            [AppLocale.l('pdfTopic'), AppLocale.l('pdfDetail')],
            [AppLocale.l('samvatsara'), trAll(panchang.samvatsara)],
            [AppLocale.l('drikRutu'), trAll(panchang.rutu)],
            [AppLocale.l('vaidikaRutu'), trAll(panchang.vaidikaRutu)],
            [AppLocale.l('vara'), trAll(panchang.vara)],
            [AppLocale.l('tithiLabel'), trAll(panchang.tithi)],
            [AppLocale.l('nakshatra'), trAll(panchang.nakshatra)],
            [AppLocale.l('yogaLabel'), trAll(panchang.yoga)],
            [AppLocale.l('karanaLabel'), trAll(panchang.karana)],
            [AppLocale.l('chandraRashiLabel'), trAll(panchang.chandraRashi)],
            [AppLocale.l('chandraMasaLabel'), trAll(panchang.chandraMasa)],
            [AppLocale.l('souraMasaLabel'), trAll(panchang.souraMasa)],
            [AppLocale.l('sunriseLabel'), panchang.sunrise],
            [AppLocale.l('sunsetLabel'), panchang.sunset],
            [AppLocale.l('udayadiGhatiLabel'), panchang.udayadiGhati],
            [AppLocale.l('gataGhatiLabel'), panchang.gataGhati],
            [AppLocale.l('paramaGhatiLabel'), panchang.paramaGhati],
            [AppLocale.l('vishaPraghatiLabel'), panchang.vishaPraghati],
            [AppLocale.l('amrutaPraghatiLabel'), panchang.amrutaPraghati],
          ],
        ),

        pw.SizedBox(height: 16),

        // Graha Sputa (Planet Positions)
        _sectionTitle(AppLocale.l('pdfPlanetPos'), headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4A148C')),
          cellPadding: const pw.EdgeInsets.all(4),
          data: [
            [AppLocale.l('hGraha'), AppLocale.l('hRashi'), AppLocale.l('hSphuta'), AppLocale.l('nakshatra'), AppLocale.l('pdfBhava').substring(0,1) + '.', AppLocale.l('pdfVakriAsta')],
            ...planets.entries.map((e) {
              final p = e.value;
              final status = <String>[];
              if (p.speed < 0) status.add(AppLocale.l('pdfVakri'));
              if (p.isCombust) status.add(AppLocale.l('pdfAsta'));
              return [
                trAll(p.name),
                trAll(p.rashi),
                formatDeg(p.longitude),
                trAll(p.nakshatra),
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
        _sectionTitle(AppLocale.l('pdfDasha'), headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1565C0')),
          cellPadding: const pw.EdgeInsets.all(4),
          data: [
            [AppLocale.l('pdfDashaLord'), AppLocale.l('pdfStart'), AppLocale.l('pdfEnd')],
            ...result.dashas.map((d) => [
              trAll(d.lord),
              '${d.start.day.toString().padLeft(2,'0')}-${d.start.month.toString().padLeft(2,'0')}-${d.start.year}',
              '${d.end.day.toString().padLeft(2,'0')}-${d.end.month.toString().padLeft(2,'0')}-${d.end.year}',
            ]),
          ],
        ),

        pw.SizedBox(height: 12),

        // Dasha Sandhi Details
        _sectionTitle(AppLocale.l('pdfDashaSandhi'), headStyle),
        pw.SizedBox(height: 6),
        _buildDashaSandhiTable(result, cellStyle, cellBoldStyle),

        pw.SizedBox(height: 16),

        // Bhava Madhya Sputa
        _sectionTitle(AppLocale.l('pdfBhavaMadhya'), headStyle),
        pw.SizedBox(height: 6),
        pw.Table.fromTextArray(
          headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
          cellStyle: cellStyle,
          headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2E7D32')),
          cellPadding: const pw.EdgeInsets.all(4),
          data: [
            [AppLocale.l('pdfBhava'), AppLocale.l('pdfSphuta')],
            ...result.bhavas.asMap().entries.map((e) => [
              '${AppLocale.l('pdfBhava')} ${e.key + 1}',
              formatDeg(e.value),
            ]),
          ],
        ),

        pw.SizedBox(height: 16),

        // Upagraha Sputa
        if (result.advSphutas.isNotEmpty) ...[
          _sectionTitle(AppLocale.l('pdfUpagraha'), headStyle),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
            cellStyle: cellStyle,
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E65100')),
            cellPadding: const pw.EdgeInsets.all(4),
            data: [
              [AppLocale.l('hUpagraha'), AppLocale.l('pdfSphuta')],
              ...result.advSphutas.entries.map((e) => [
                trAll(e.key),
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
            _sectionTitle(AppLocale.l('pdfShadbala'), headStyle),
            pw.SizedBox(height: 6),
            pw.Table.fromTextArray(
              headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
              cellStyle: cellStyle,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#880E4F')),
              cellPadding: const pw.EdgeInsets.all(4),
              data: [
                [AppLocale.l('hGraha'), AppLocale.l('pdfTotalBala'), AppLocale.l('pdfNeeded'), AppLocale.l('pdfRatio')],
                ...result.shadbala.entries.map((e) {
                  final total = (e.value['total'] ?? 0.0) as double;
                  final needed = (e.value['needed'] ?? 1.0) as double;
                  final ratio = needed > 0 ? total / needed : 0.0;
                  return [
                    trAll(e.key),
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
            _sectionTitle(AppLocale.l('pdfNotes'), headStyle),
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

    return pdf.save();
  }

  /// Generate and show print dialog for the Kundali PDF
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
    final bytes = await _generatePdfBytes(
      name: name, place: place, dob: dob, hour: hour, minute: minute, ampm: ampm, lat: lat, lon: lon, result: result, notes: notes
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Kundali_$name.pdf',
    );
  }

  /// Generate and show share dialog for the Kundali PDF
  static Future<void> generateAndShare({
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
    final bytes = await _generatePdfBytes(
      name: name, place: place, dob: dob, hour: hour, minute: minute, ampm: ampm, lat: lat, lon: lon, result: result, notes: notes
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Kundali_$name.pdf',
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
            pw.Text(AppLocale.l('pdfKundali'), style: titleStyle),
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

  /// Build Dasha Sandhi table showing transition periods between consecutive Mahadashas.
  static pw.Widget _buildDashaSandhiTable(KundaliResult result, pw.TextStyle cellStyle, pw.TextStyle cellBoldStyle) {
    final dashas = result.dashas;
    if (dashas.length < 2) return pw.SizedBox();

    // Vimshottari dasha year durations
    const dashaYears = <String, int>{
      'ಕೇತು': 7, 'ಶುಕ್ರ': 20, 'ರವಿ': 6, 'ಚಂದ್ರ': 10,
      'ಕುಜ': 7, 'ರಾಹು': 18, 'ಗುರು': 16, 'ಶನಿ': 19, 'ಬುಧ': 17,
    };

    String fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

    final rows = <List<String>>[];
    for (int i = 0; i < dashas.length - 1; i++) {
      final ending = dashas[i];
      final starting = dashas[i + 1];
      final transitionDate = ending.end;

      // Sandhi duration = (ending_years + starting_years) / 6 in months
      final endYears = dashaYears[ending.lord] ?? 10;
      final startYears = dashaYears[starting.lord] ?? 10;
      final sandhiMonths = ((endYears + startYears) / 6.0).round().clamp(1, 12);
      final halfSandhi = (sandhiMonths / 2.0).ceil();

      final sandhiStart = DateTime(transitionDate.year, transitionDate.month - halfSandhi, transitionDate.day);
      final sandhiEnd = DateTime(transitionDate.year, transitionDate.month + halfSandhi, transitionDate.day);

      rows.add([
        '${trAll(ending.lord)} → ${trAll(starting.lord)}',
        fmtDate(transitionDate),
        '${fmtDate(sandhiStart)} - ${fmtDate(sandhiEnd)}',
      ]);
    }

    return pw.Table.fromTextArray(
      headerStyle: cellBoldStyle.copyWith(color: PdfColors.white),
      cellStyle: cellStyle.copyWith(fontSize: 8),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#7B1FA2')),
      cellPadding: const pw.EdgeInsets.all(3),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(3.5),
      },
      data: [
        [AppLocale.l('pdfSandhiTransition'), AppLocale.l('pdfEnd'), AppLocale.l('pdfSandhiPeriod')],
        ...rows,
      ],
    );
  }
}
