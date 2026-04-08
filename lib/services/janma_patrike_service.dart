import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'pdf_theme.dart';

class UserDetails {
  final String name;
  final String dateStr;
  final String timeStr;
  final String place;
  final String fatherName;
  final String motherName;
  final String gotra;
  final String jyotishiName;
  final String jyotishiPhone;

  UserDetails({
    required this.name,
    required this.dateStr,
    required this.timeStr,
    required this.place,
    required this.fatherName,
    required this.motherName,
    required this.gotra,
    required this.jyotishiName,
    required this.jyotishiPhone,
  });
}

class JanmaPatrikeService {
  static const _shortNames = <String, String>{
    'ಲಗ್ನ': 'ಲ', 'ರವಿ': 'ರ', 'ಚಂದ್ರ': 'ಚಂ', 'ಕುಜ': 'ಕು', 'ಬುಧ': 'ಬು',
    'ಗುರು': 'ಗು', 'ಶುಕ್ರ': 'ಶು', 'ಶನಿ': 'ಶ', 'ರಾಹು': 'ರಾ', 'ಕೇತು': 'ಕೇ', 'ಮಾಂದಿ': 'ಮಾ',
  };

  static List<List<String>> _computeChart(KundaliResult result, int Function(double deg) rashiResolver) {
    final List<List<String>> chart = List.generate(12, (_) => []);
    for (final pName in planetOrder) {
      final info = result.planets[pName];
      if (info == null) continue;
      final ri = rashiResolver(info.longitude);
      if (ri >= 0 && ri < 12) {
        chart[ri].add(_shortNames[pName] ?? pName);
      }
    }
    return chart;
  }

  static List<List<String>> _rashiChart(KundaliResult result) {
    return _computeChart(result, (deg) => (deg / 30).floor() % 12);
  }

  static List<List<String>> _navamshaChart(KundaliResult result) {
    return _computeChart(result, (deg) {
      final block = (deg / 30).floor() % 4;
      final start = [0, 9, 6, 3][block];
      final steps = ((deg % 30) / 3.33333).floor();
      return (start + steps) % 12;
    });
  }

  static List<List<String>> _bhavaChart(KundaliResult result) {
    final lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0;
    final lagnaIdx = (lagnaLong / 30).floor() % 12;
    final madhyas = result.bhavas;

    List<double> boundaries = List.filled(12, 0.0);
    for (int i = 0; i < 12; i++) {
      final m1 = madhyas[i];
      final m2 = madhyas[(i + 1) % 12];
      double diff = (m2 - m1 + 360.0) % 360.0;
      boundaries[i] = (m1 + (diff / 2.0)) % 360.0;
    }

    final List<List<String>> chart = List.generate(12, (_) => []);
    for (final pName in planetOrder) {
      final info = result.planets[pName];
      if (info == null) continue;
      final d = info.longitude;

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

      final ri = (lagnaIdx + bhavaIdx) % 12;
      if (ri >= 0 && ri < 12) {
        chart[ri].add(_shortNames[pName] ?? pName);
      }
    }
    return chart;
  }

  static Future<void> generateAndPrint(UserDetails user, KundaliResult result, {PdfThemeConfig? theme}) async {
    theme ??= PdfThemes.traditional;
    final controller = ScreenshotController();

    // A4 Dimensions at 96 DPI
    const double pageWidth = 793.0;
    const double pageHeight = 1122.0;

    // Build themed pages
    final page1Widget = _buildPageWrapper(
      width: pageWidth,
      height: pageHeight,
      theme: theme,
      child: _buildPage1Content(user, result, theme),
    );

    final page2Widget = _buildPageWrapper(
      width: pageWidth,
      height: pageHeight,
      theme: theme,
      child: _buildPage2Content(user, result, theme),
    );

    final targetSize = const Size(pageWidth, pageHeight);

    final Uint8List page1Bytes = await controller.captureFromWidget(
      page1Widget,
      targetSize: targetSize,
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 100)
    );
    final Uint8List page2Bytes = await controller.captureFromWidget(
      page2Widget,
      targetSize: targetSize,
      pixelRatio: 3.0,
      delay: const Duration(milliseconds: 100)
    );

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(ignoreMargins: true, child: pw.Image(pw.MemoryImage(page1Bytes), fit: pw.BoxFit.contain));
        },
      ),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.FullPage(ignoreMargins: true, child: pw.Image(pw.MemoryImage(page2Bytes), fit: pw.BoxFit.contain));
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${user.name}_janmapatrike',
    );
  }

  static Widget _buildPageWrapper({
    required double width,
    required double height,
    required PdfThemeConfig theme,
    required Widget child,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Theme(
          data: ThemeData(fontFamily: 'Noto Sans Kannada'),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontSize: 13),
            child: Material(
              color: Colors.white,
              child: theme.buildPageBorder(
                width: width,
                height: height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // PAGE 1: Birth Details + Panchanga + Charts
  // ════════════════════════════════════════════════════════
  static Widget _buildPage1Content(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final p = result.panchang;
    final lagnaInfo = result.planets['ಲಗ್ನ'];
    final lagnaRashi = lagnaInfo != null ? lagnaInfo.rashi : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('ಜನ್ಮ ಪತ್ರಿಕೆ', 'ಭಾರತೀಯಂ ಜ್ಯೋತಿಷ ಅಪ್ಲಿಕೇಶನ್', t),
        const SizedBox(height: 5),

        _buildSectionTitle('ವೈಯಕ್ತಿಕ ವಿವರ', t),
        _buildDetailBox([
          ['ಜಾತಕರ ಹೆಸರು:', user.name, 'ಜನ್ಮ ಊರು:', user.place],
          ['ಜನನ ದಿನಾಂಕ:', user.dateStr, 'ಜನ್ಮ ಸಮಯ:', user.timeStr],
          ['ತಂದೆ ಹೆಸರು:', user.fatherName, 'ತಾಯಿ ಹೆಸರು:', user.motherName],
          ['ಗೋತ್ರ:', user.gotra, 'ಲಗ್ನ ರಾಶಿ:', lagnaRashi],
        ], t),
        const SizedBox(height: 2),

        _buildSectionTitle('ಪಂಚಾಂಗ ವಿವರ', t),
        _buildDetailBox([
          ['ಸಂವತ್ಸರ:', p.samvatsara, 'ಚಂದ್ರ ಮಾಸ:', p.chandraMasa],
          ['ರವಿ ಮಾಸ:', p.souraMasa, 'ಋತು:', p.rutu],
          ['ತಿಥಿ:', p.tithi, 'ವಾರ:', p.vara],
          ['ನಕ್ಷತ್ರ:', p.nakshatra, 'ಕರಣ:', p.karana],
          ['ಯೋಗ:', p.yoga, 'ಚಂದ್ರ ರಾಶಿ:', p.chandraRashi],
          ['ಉದಯಾದಿ ಘಟಿ:', p.udayadiGhati, 'ಗತ ಘಟಿ:', p.gataGhati],
          ['ಪರಮ ಘಟಿ:', p.paramaGhati, 'ಶೇಷ ಘಟಿ:', p.shesha],
          ['ವಿಷ ಪ್ರಘಟಿ:', p.vishaPraghati, 'ಅಮೃತ ಪ್ರಘಟಿ:', p.amrutaPraghati],
          ['ಸೂರ್ಯೋದಯ:', p.sunrise, 'ಸೂರ್ಯಾಸ್ತ:', p.sunset],
        ], t),
        const SizedBox(height: 2),

        _buildSectionTitle('ತತ್ಕಾಲ ಗ್ರಹಸ್ಥಿತಿ', t),
        _buildGrahaTable(result, t),
        const SizedBox(height: 2),

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget('ರಾಶಿ ಕುಂಡಲಿ', _rashiChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget('ನವಾಂಶ ಕುಂಡಲಿ', _navamshaChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget('ಭಾವ ಕುಂಡಲಿ', _bhavaChart(result), t))),
            ],
          ),
        ),

        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // PAGE 2: Dasha Details
  // ════════════════════════════════════════════════════════
  static Widget _buildPage2Content(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final p = result.panchang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('ಜನ್ಮ ಪತ್ರಿಕೆ — ದಶಾ ವಿವರ', '${user.name} — ${user.dateStr}', t),
        const SizedBox(height: 15),

        _buildSectionTitle('ನಕ್ಷತ್ರ ಮತ್ತು ದಶಾ ವಿವರ', t),
        _buildDetailBox([
          ['ಜನ್ಮ ನಕ್ಷತ್ರ:', p.nakshatra, 'ಚಂದ್ರ ರಾಶಿ:', p.chandraRashi],
          ['ನಕ್ಷತ್ರ ಪರಮ ಘಟಿ:', p.paramaGhati, 'ಗತ ಘಟಿ:', p.gataGhati],
          ['ಶಿಷ್ಟ ದಶಾ ನಾಥ:', p.dashaLord, 'ಶಿಷ್ಟ ದಶಾ ಶೇಷ:', p.dashaBalance],
        ], t),
        const SizedBox(height: 15),

        _buildSectionTitle('ವಿಂಶೋತ್ತರೀ ಮಹಾ ದಶಾ', t),
        _buildDashaTable(result, t),
        const SizedBox(height: 15),

        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: t.dashaHighlight,
            border: Border.all(color: t.dashaHighlightBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('ಶಿಷ್ಟ ದಶೆ: ${p.dashaLord} — ಶೇಷ: ${p.dashaBalance}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: t.dashaHighlightText)
          ),
        ),

        const SizedBox(height: 15),
        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // THEMED WIDGETS
  // ════════════════════════════════════════════════════════

  static Widget _buildHeader(String mainTitle, String subTitle, PdfThemeConfig t) {
    // For Black & Gold theme, use white text on dark bg
    final bool isDarkHeader = t.id == 'black_gold';
    final subtitleColor = isDarkHeader ? const Color(0xFFBBBBBB) : const Color(0xFF757575);
    final shlokaColor = isDarkHeader ? const Color(0xFFFF6B6B) : t.shlokaText;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: t.headerBg,
        border: Border.all(color: t.primaryDark, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/ganapati.png', width: 48, height: 48),
              const Spacer(),
              Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 42, height: 42),
                  const SizedBox(height: 3),
                  Text('ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ ।। ಶ್ರೀ ಗುರುಭ್ಯೋ ನಮಃ ।।',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: shlokaColor)),
                ],
              ),
              const Spacer(),
              Image.asset('assets/images/shiva.png', width: 48, height: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text(mainTitle, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: t.headerText)),
          const SizedBox(height: 2),
          Text(subTitle, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: subtitleColor)),
        ],
      ),
    );
  }

  static Widget _buildSectionTitle(String title, PdfThemeConfig t) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.sectionTitleBg, width: 1.5)),
      ),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: t.sectionTitleText)),
    );
  }

  static Widget _buildDetailBox(List<List<String>> rows, PdfThemeConfig t) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: t.detailBorder),
        borderRadius: BorderRadius.circular(6),
        color: t.detailBoxBg,
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1.5),
        },
        children: rows.map((row) {
          return TableRow(
            children: row.asMap().entries.map((e) {
              final isLabel = e.key % 2 == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 2),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: isLabel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 10,
                    color: isLabel ? t.primaryDark : const Color(0xFF212121),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildGrahaTable(KundaliResult result, PdfThemeConfig t) {
    final headers = ['ಗ್ರಹ', 'ರಾಶಿ', 'ಅಂಶ', 'ನಕ್ಷತ್ರ', 'ಪಾದ', 'ವಕ್ರ/ಅಸ್ತ'];

    final rows = <List<String>>[];
    for (final planetKey in planetOrder) {
      final info = result.planets[planetKey];
      if (info == null) continue;
      String vakrast = '-';
      if (info.speed < 0) vakrast = 'ವ';
      if (info.isCombust) vakrast = vakrast == 'ವ' ? 'ವ / ಅ' : 'ಅ';

      rows.add([
        planetKey,
        info.rashi,
        formatDeg(info.longitude),
        info.nakshatra,
        info.pada.toString(),
        vakrast,
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.detailBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          verticalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: t.tableHeaderBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.all(2),
              child: Text(h, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: t.tableHeaderText)),
            )).toList(),
          ),
          // Data
          ...rows.asMap().entries.map((entry) {
            final isEven = entry.key % 2 == 0;
            return TableRow(
              decoration: BoxDecoration(color: isEven ? Colors.white : t.tableAltRow),
              children: entry.value.map((cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 2),
                child: Text(cell, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Colors.black)),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildChartWidget(String title, List<List<String>> chart, PdfThemeConfig t) {
    if (chart.isEmpty) chart = List.generate(12, (_) => []);
    String p(int idx) => chart[idx].join('\n');

    Widget box(String text) {
      return Expanded(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: t.chartBorder, width: 0.5),
            color: Colors.white,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: const Color(0xFF1A1A1A), height: 1.1),
          ),
        ),
      );
    }

    Widget rowBoxes(List<int> idxs) {
      return Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: idxs.map((i) => box(p(i))).toList(),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: t.primaryDark, width: 1.5)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                rowBoxes([11, 0, 1, 2]),
                Expanded(
                  flex: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          box(p(10)),
                          box(p(9)),
                        ]),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: t.chartBorder, width: 0.5),
                            color: t.chartCenterBg,
                          ),
                          child: Text(
                            title.split(' ')[0],
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t.chartCenterText),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          box(p(3)),
                          box(p(4)),
                        ]),
                      ),
                    ],
                  ),
                ),
                rowBoxes([8, 7, 6, 5]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: t.primaryDark)),
      ],
    );
  }

  static Widget _buildDashaTable(KundaliResult result, PdfThemeConfig t) {
    final headers = ['ಕ್ರ.', 'ದಶಾ ನಾಥ', 'ವರ್ಷ', 'ಆರಂಭ ದಿನಾಂಕ', 'ಅಂತ್ಯ ದಿನಾಂಕ'];

    final rows = <List<String>>[];
    for (int i = 0; i < result.dashas.length; i++) {
      final d = result.dashas[i];
      final startStr = '${d.start.day.toString().padLeft(2,'0')}-${d.start.month.toString().padLeft(2,'0')}-${d.start.year}';
      final endStr = '${d.end.day.toString().padLeft(2,'0')}-${d.end.month.toString().padLeft(2,'0')}-${d.end.year}';
      int years = d.end.year - d.start.year;

      rows.add([
        (i + 1).toString(),
        d.lord,
        years.toString(),
        startStr,
        endStr,
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: t.detailBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          verticalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: t.tableHeaderBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(h, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t.tableHeaderText)),
            )).toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final isEven = entry.key % 2 == 0;
            return TableRow(
              decoration: BoxDecoration(color: isEven ? Colors.white : t.dashaAltRow),
              children: entry.value.map((cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(cell, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black)),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildFooter(String jyotishiName, String jyotishiPhone, PdfThemeConfig t) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.detailBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(jyotishiName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.footerText)),
          Text('ಭಾರತೀಯಂ', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: t.footerText.withOpacity(0.5))),
          Text(jyotishiPhone, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.footerText)),
        ],
      ),
    );
  }
}
