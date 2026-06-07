import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import 'pdf_theme.dart';
import '../widgets/common.dart';

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
  /// Select the correct font family based on the user's locale
  static String _fontForLocale() {
    switch (AppLocale.current) {
      case 'hi': return 'NotoSansDevanagari';
      case 'ta': return 'NotoSansTamil';
      case 'te': return 'NotoSansTelugu';
      case 'ml': return 'NotoSansMalayalam';
      default:   return 'NotoSansKannada';
    }
  }

  /// Locale-aware short names for chart cells
  static Map<String, String> get _shortNames {
    return <String, String>{
      'ಲಗ್ನ': AppLocale.l('abbrLagna'),
      'ರವಿ': AppLocale.l('abbrRavi'),
      'ಚಂದ್ರ': AppLocale.l('abbrChandra'),
      'ಕುಜ': AppLocale.l('abbrKuja'),
      'ಬುಧ': AppLocale.l('abbrBudha'),
      'ಗುರು': AppLocale.l('abbrGuru'),
      'ಶುಕ್ರ': AppLocale.l('abbrShukra'),
      'ಶನಿ': AppLocale.l('abbrShani'),
      'ರಾಹು': AppLocale.l('abbrRahu'),
      'ಕೇತು': AppLocale.l('abbrKetu'),
      'ಮಾಂದಿ': AppLocale.l('abbrMandi'),
    };
  }

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
          data: ThemeData(fontFamily: _fontForLocale()),
          child: DefaultTextStyle(
            style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: _fontForLocale()),
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
        _buildHeader(AppLocale.l('jpTitle'), AppLocale.l('jpSubtitle'), t),
        const SizedBox(height: 5),

        _buildSectionTitle(AppLocale.l('jpPersonalDetails'), t),
        _buildDetailBox([
          [AppLocale.l('jpNativeName'), user.name, AppLocale.l('jpBirthPlace'), user.place],
          [AppLocale.l('jpDob'), user.dateStr, AppLocale.l('jpTime'), user.timeStr],
          [AppLocale.l('jpFather'), user.fatherName, AppLocale.l('jpMother'), user.motherName],
          [AppLocale.l('jpGotra'), user.gotra, AppLocale.l('jpLagnaRashi'), trAll(lagnaRashi)],
        ], t),
        const SizedBox(height: 2),

        _buildSectionTitle(AppLocale.l('jpPanchangaDetails'), t),
        _buildDetailBox([
          [AppLocale.l('jpSamvatsara'), trAll(p.samvatsara), AppLocale.l('jpChandraMasa'), trAll(p.chandraMasa)],
          [AppLocale.l('jpSouraMasa'), trAll(p.souraMasa), AppLocale.l('jpRutu'), trAll(p.rutu)],
          [AppLocale.l('jpTithi'), trAll(p.tithi), AppLocale.l('jpVara'), trAll(p.vara)],
          [AppLocale.l('jpNakshatra'), trAll(p.nakshatra), AppLocale.l('jpKarana'), trAll(p.karana)],
          [AppLocale.l('jpYoga'), trAll(p.yoga), AppLocale.l('jpChandraRashi'), trAll(p.chandraRashi)],
          [AppLocale.l('jpUdayadiGhati'), p.udayadiGhati, AppLocale.l('jpGataGhati'), p.gataGhati],
          [AppLocale.l('jpParamaGhati'), p.paramaGhati, AppLocale.l('jpSheshaGhati'), p.shesha],
          [AppLocale.l('jpVishaPraghati'), p.vishaPraghati, AppLocale.l('jpAmrutaPraghati'), p.amrutaPraghati],
          [AppLocale.l('jpSunrise'), p.sunrise, AppLocale.l('jpSunset'), p.sunset],
        ], t),
        const SizedBox(height: 2),

        _buildSectionTitle(AppLocale.l('jpGrahaStithi'), t),
        _buildGrahaTable(result, t),
        const SizedBox(height: 2),

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpRashiKundali'), _rashiChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpNavamshaKundali'), _navamshaChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpBhavaKundali'), _bhavaChart(result), t))),
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
        _buildHeader(AppLocale.l('jpDashaTitle'), '${user.name} — ${user.dateStr}', t),
        const SizedBox(height: 15),

        _buildSectionTitle(AppLocale.l('jpNakDasha'), t),
        _buildDetailBox([
          [AppLocale.l('jpJanmaNak'), trAll(p.nakshatra), AppLocale.l('jpChandraRashi'), trAll(p.chandraRashi)],
          [AppLocale.l('jpNakParama'), p.paramaGhati, AppLocale.l('jpGataGhati'), p.gataGhati],
          [AppLocale.l('jpShishtaDasha'), trAll(p.dashaLord), AppLocale.l('jpShishtaShesha'), p.dashaBalance],
        ], t),
        const SizedBox(height: 15),

        _buildSectionTitle(AppLocale.l('jpMahaDasha'), t),
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
          child: Text('${AppLocale.l('jpShishtaDashe')} ${trAll(p.dashaLord)} — ${AppLocale.l('jpShesha')} ${p.dashaBalance}',
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
              const SizedBox(width: 6),
              Expanded(
                child: Text(AppLocale.l('shriGaneshaya'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: shlokaColor)),
              ),
              Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 42, height: 42),
                ],
              ),
              Expanded(
                child: Text(AppLocale.l('shriGurubhyo'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: shlokaColor)),
              ),
              const SizedBox(width: 6),
              Image.asset('assets/images/shiva.png', width: 48, height: 48),
            ],
          ),
          const SizedBox(height: 3),
          Text(AppLocale.l('janmaShloka'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 9, color: shlokaColor, fontStyle: FontStyle.italic, height: 1.3)),
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
    final headers = [AppLocale.l('hGraha'), AppLocale.l('hRashi'), AppLocale.l('hSphuta'), AppLocale.l('nakshatra'), AppLocale.l('jpPada'), AppLocale.l('pdfVakriAsta')];

    final rows = <List<String>>[];
    for (final planetKey in planetOrder) {
      final info = result.planets[planetKey];
      if (info == null) continue;
      String vakrast = '-';
      if (info.speed < 0) vakrast = AppLocale.l('pdfVakri').substring(0, 1);
      if (info.isCombust) vakrast = vakrast == AppLocale.l('pdfVakri').substring(0, 1) ? '${AppLocale.l('pdfVakri').substring(0, 1)} / ${AppLocale.l('pdfAsta').substring(0, 1)}' : AppLocale.l('pdfAsta').substring(0, 1);

      rows.add([
        trAll(planetKey),
        trAll(info.rashi),
        formatDeg(info.longitude),
        trAll(info.nakshatra),
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
      ],
    );
  }

  static Widget _buildDashaTable(KundaliResult result, PdfThemeConfig t) {
    final headers = [AppLocale.l('jpSlNo'), AppLocale.l('pdfDashaLord'), AppLocale.l('jpYears'), AppLocale.l('jpStartDate'), AppLocale.l('jpEndDate')];

    final rows = <List<String>>[];
    for (int i = 0; i < result.dashas.length; i++) {
      final d = result.dashas[i];
      final startStr = '${d.start.day.toString().padLeft(2,'0')}-${d.start.month.toString().padLeft(2,'0')}-${d.start.year}';
      final endStr = '${d.end.day.toString().padLeft(2,'0')}-${d.end.month.toString().padLeft(2,'0')}-${d.end.year}';
      int years = d.end.year - d.start.year;

      rows.add([
        (i + 1).toString(),
        trAll(d.lord),
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
          Text(AppLocale.l('jpBharatiyam'), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: t.footerText.withOpacity(0.5))),
          Text(jyotishiPhone, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: t.footerText)),
        ],
      ),
    );
  }
}
