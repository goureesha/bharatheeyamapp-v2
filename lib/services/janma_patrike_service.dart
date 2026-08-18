import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../core/calculator.dart';
import '../core/ashtakavarga.dart';
import '../constants/strings.dart';
import 'pdf_theme.dart';
import '../widgets/common.dart';

class UserDetails {
  final String name;
  final String dateStr;
  final String timeStr;
  final String place;
  final double lat;
  final double lon;
  final double tz;
  final String fatherName;
  final String motherName;
  final String gotra;
  final String jyotishiName;
  final String jyotishiPhone;
  final String jyotishiAddress;
  final String gender; // 'male' or 'female'

  UserDetails({
    required this.name,
    required this.dateStr,
    required this.timeStr,
    required this.place,
    this.lat = 0,
    this.lon = 0,
    this.tz = 5.5,
    required this.fatherName,
    required this.motherName,
    required this.gotra,
    required this.jyotishiName,
    required this.jyotishiPhone,
    this.jyotishiAddress = '',
    this.gender = 'male',
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

  static List<List<String>> _horaChart(KundaliResult result) {
    return _computeChart(result, (deg) {
      final sign = (deg / 30).floor();
      final isOdd = sign % 2 != 0;
      final degInSign = deg % 30;
      if (isOdd) {
        return degInSign < 15.0 ? 4 : 3;
      } else {
        return degInSign < 15.0 ? 3 : 4;
      }
    });
  }

  static List<List<String>> _drekkanaChart(KundaliResult result) {
    return _computeChart(result, (deg) {
      final sign = (deg / 30).floor();
      final part = ((deg % 30) / 10).floor();
      return (sign + part * 4) % 12;
    });
  }

  static List<List<String>> _dvadashamshaChart(KundaliResult result) {
    return _computeChart(result, (deg) {
      final sign = (deg / 30).floor();
      final part = ((deg % 30) / 2.5).floor();
      return (sign + part) % 12;
    });
  }

  static List<List<String>> _trimshamshaChart(KundaliResult result) {
    return _computeChart(result, (deg) {
      final sign = (deg / 30).floor();
      final isOdd = sign % 2 != 0;
      final degInSign = deg % 30;
      if (isOdd) {
        if (degInSign < 5.0) return 0;
        if (degInSign < 10.0) return 10;
        if (degInSign < 18.0) return 8;
        if (degInSign < 25.0) return 2;
        return 6;
      } else {
        if (degInSign < 5.0) return 1;
        if (degInSign < 12.0) return 5;
        if (degInSign < 20.0) return 11;
        if (degInSign < 25.0) return 9;
        return 3;
      }
    });
  }

  static Future<Uint8List> _generatePdfBytes(UserDetails user, KundaliResult result, {PdfThemeConfig? theme, List<bool>? selectedPages}) async {
    theme ??= PdfThemes.traditional;
    final pages = selectedPages ?? [true, true, true, true, true, true];
    final controller = ScreenshotController();

    // A4 Dimensions at 96 DPI
    const double pageWidth = 793.0;
    const double pageHeight = 1122.0;
    final targetSize = const Size(pageWidth, pageHeight);

    Uint8List? page1Bytes;
    if (pages[0]) {
      final page1Widget = _buildPageWrapper(
        width: pageWidth,
        height: pageHeight,
        theme: theme,
        child: _buildPage1Content(user, result, theme),
      );
      page1Bytes = await controller.captureFromWidget(
        page1Widget,
        targetSize: targetSize,
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 10),
      );
    }

    Uint8List? page2Bytes;
    if (pages[1]) {
      final page2Widget = _buildPageWrapper(
        width: pageWidth,
        height: pageHeight,
        theme: theme,
        child: _buildPage2Content(user, result, theme),
      );
      page2Bytes = await controller.captureFromWidget(
        page2Widget,
        targetSize: targetSize,
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 10),
      );
    }

    Uint8List? page3Bytes;
    if (pages[2]) {
      final page3Widget = _buildPageWrapper(
        width: pageWidth,
        height: pageHeight,
        theme: theme,
        child: _buildPage3Content(user, result, theme),
      );
      page3Bytes = await controller.captureFromWidget(
        page3Widget,
        targetSize: targetSize,
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 10),
      );
    }

    Uint8List? page4Bytes;
    if (pages[3]) {
      final page4Widget = _buildPageWrapper(
        width: pageWidth,
        height: pageHeight,
        theme: theme,
        child: _buildPage4Content(user, result, theme),
      );
      page4Bytes = await controller.captureFromWidget(
        page4Widget,
        targetSize: targetSize,
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 10),
      );
    }

    Uint8List? page5Bytes;
    if (pages[4]) {
      final page5Widget = _buildPageWrapper(
        width: pageWidth,
        height: pageHeight,
        theme: theme,
        child: _buildPage5Content(user, result, theme),
      );
      page5Bytes = await controller.captureFromWidget(
        page5Widget,
        targetSize: targetSize,
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 10),
      );
    }

    Uint8List? page6Bytes;
    if (pages[5]) {
      final page6Widget = _buildPageWrapper(
        width: pageWidth,
        height: pageHeight,
        theme: theme,
        child: _buildPage6Content(user, result, theme),
      );
      page6Bytes = await controller.captureFromWidget(
        page6Widget,
        targetSize: targetSize,
        pixelRatio: 2.5,
        delay: const Duration(milliseconds: 10),
      );
    }

    final doc = pw.Document();

    for (final bytes in [page1Bytes, page2Bytes, page3Bytes, page4Bytes, page5Bytes, page6Bytes]) {
      if (bytes != null) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }

    return doc.save();
  }

  static Future<void> generateAndPrint(UserDetails user, KundaliResult result, {PdfThemeConfig? theme, List<bool>? selectedPages}) async {
    final bytes = await _generatePdfBytes(user, result, theme: theme, selectedPages: selectedPages);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${user.name}_janmapatrike',
    );
  }

  static Future<void> generateAndShare(UserDetails user, KundaliResult result, {PdfThemeConfig? theme, List<bool>? selectedPages}) async {
    final bytes = await _generatePdfBytes(user, result, theme: theme, selectedPages: selectedPages);
    await Printing.sharePdf(bytes: bytes, filename: '${user.name}_janmapatrike.pdf');
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
          [AppLocale.l('jpLatLon'), '${user.lat.toStringAsFixed(4)}°, ${user.lon.toStringAsFixed(4)}°', AppLocale.l('jpTimezone'), '${user.tz >= 0 ? "+" : ""}${user.tz}'],
          [AppLocale.l('jpFather'), user.fatherName, AppLocale.l('jpMother'), user.motherName],
          [AppLocale.l('jpGotra'), user.gotra, AppLocale.l('jpGender'), user.gender == 'female' ? AppLocale.l('jpFemale') : AppLocale.l('jpMale')],
          ['', '', AppLocale.l('jpLagnaRashi'), trAll(lagnaRashi)],
        ], t),
        const SizedBox(height: 2),

        _buildSectionTitle(AppLocale.l('jpPanchangaDetails'), t),
        _buildDetailBox([
          [AppLocale.l('jpSamvatsara'), trAll(p.samvatsara), AppLocale.l('jpChandraMasa'), trAll(p.chandraMasa)],
          [AppLocale.l('jpSouraMasa'), trAll(p.souraMasa), AppLocale.l('jpDrikRutu'), trAll(p.rutu)],
          [AppLocale.l('jpVaidikaRutu'), trAll(p.vaidikaRutu), AppLocale.l('jpVara'), trAll(p.vara)],
          [AppLocale.l('jpTithi'), trAll(p.tithi), AppLocale.l('jpKarana'), trAll(p.karana)],
          [AppLocale.l('jpNakshatra'), trAll(p.nakshatra), AppLocale.l('jpYoga'), trAll(p.yoga)],
          [AppLocale.l('jpChandraRashi'), trAll(p.chandraRashi), '', ''],
          [AppLocale.l('jpUdayadiGhati'), p.udayadiGhati, AppLocale.l('jpGataGhati'), p.gataGhati],
          [AppLocale.l('jpParamaGhati'), p.paramaGhati, AppLocale.l('jpSheshaGhati'), p.shesha],
          [AppLocale.l('jpVishaPraghati'), p.vishaPraghati, AppLocale.l('jpAmrutaPraghati'), p.amrutaPraghati],
          [AppLocale.l('jpSunrise'), p.sunrise, AppLocale.l('jpSunset'), p.sunset],
        ], t),
        const SizedBox(height: 2),

        _buildSectionTitle(AppLocale.l('jpGrahaStithi'), t),
        _buildGrahaTable(result, t),
        const SizedBox(height: 1),

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

        // Astrologer Details section
        if (user.jyotishiName.isNotEmpty || user.jyotishiAddress.isNotEmpty || user.jyotishiPhone.isNotEmpty)
          _buildAstrologerSection(user, t),

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
        const SizedBox(height: 8),

        _buildSectionTitle(AppLocale.l('jpNakDasha'), t),
        _buildDetailBox([
          [AppLocale.l('jpJanmaNak'), trAll(p.nakshatra), AppLocale.l('jpChandraRashi'), trAll(p.chandraRashi)],
          [AppLocale.l('jpNakParama'), p.paramaGhati, AppLocale.l('jpGataGhati'), p.gataGhati],
          [AppLocale.l('jpShishtaDasha'), trAll(p.dashaLord), AppLocale.l('jpShishtaShesha'), p.dashaBalance],
        ], t),
        const SizedBox(height: 8),

        _buildSectionTitle(AppLocale.l('jpMahaDasha'), t),
        _buildDashaTable(result, t),
        const SizedBox(height: 6),

        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: t.dashaHighlight,
            border: Border.all(color: t.dashaHighlightBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${AppLocale.l('jpShishtaDashe')} ${trAll(p.dashaLord)} — ${AppLocale.l('jpShesha')} ${p.dashaBalance}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: t.dashaHighlightText)
          ),
        ),
        const SizedBox(height: 8),

        _buildSectionTitle(AppLocale.l('jpDashaSandhi'), t),
        const SizedBox(height: 3),
        _buildDashaSandhiTable(result, t),

        const Spacer(),
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
    Widget box(int idx) {
      final items = chart[idx];
      final count = items.length;
      // Group planet names into rows of 3 to prevent tiny text when many planets in one rashi
      String text;
      if (count <= 3) {
        text = items.join('\n');
      } else {
        final rows = <String>[];
        for (int i = 0; i < count; i += 3) {
          final end = (i + 3 > count) ? count : i + 3;
          rows.add(items.sublist(i, end).join(' '));
        }
        text = rows.join('\n');
      }
      // Dynamic font size: scale down for crowded rashis
      double fontSize;
      double lineHeight;
      if (count <= 3) {
        fontSize = 11.5;
        lineHeight = 1.1;
      } else if (count <= 5) {
        fontSize = 9.5;
        lineHeight = 1.05;
      } else {
        fontSize = 8.0;
        lineHeight = 1.0;
      }
      return Expanded(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            border: Border.all(color: t.chartBorder, width: 0.5),
            color: Colors.white,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize, color: const Color(0xFF1A1A1A), height: lineHeight),
            ),
          ),
        ),
      );
    }

    Widget rowBoxes(List<int> idxs) {
      return Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: idxs.map((i) => box(i)).toList(),
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
                          box(10),
                          box(9),
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
                          box(3),
                          box(4),
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

  static Widget _buildDashaSandhiTable(KundaliResult result, PdfThemeConfig t) {
    final dashas = result.dashas;
    if (dashas.length < 2) return const SizedBox();

    // Only these 3 specific sandhi pairs
    const targetPairs = [
      ['ಕುಜ', 'ರಾಹು'],
      ['ರಾಹು', 'ಗುರು'],
      ['ಶುಕ್ರ', 'ರವಿ'],
    ];




    // Alternate names for display: ಗುರು→ಬೃಹಸ್ಪತಿ, ರವಿ→ಆದಿತ್ಯ
    String altName(String lord) {
      if (lord == 'ಗುರು') return AppLocale.l('altGuru');
      if (lord == 'ರವಿ') return AppLocale.l('altRavi');
      return trAll(lord);
    }

    String fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    List<Widget> cards = [];

    for (int i = 0; i < dashas.length - 1; i++) {
      final ending = dashas[i];
      final starting = dashas[i + 1];

      // Check if this pair is one of the 3 targets
      bool isTarget = targetPairs.any((p) => p[0] == ending.lord && p[1] == starting.lord);
      if (!isTarget) continue;

      final transitionDate = ending.end;
      const sandhiMonths = 6;

      final lord1 = altName(ending.lord);
      final lord2 = altName(starting.lord);

      final title = AppLocale.l('jpSandhiCardTitle').replaceAll('{0}', lord1).replaceAll('{1}', lord2);
      final dateLine = '${AppLocale.l('jpSandhiCardDate').replaceAll('{0}', lord1)} ${fmtDate(transitionDate)}';
      final desc = AppLocale.l('jpSandhiCardDesc')
          .replaceAll('{0}', lord1)
          .replaceAll('{1}', lord2)
          .replaceAll('{2}', sandhiMonths.toString());

      cards.add(SizedBox(
        height: 50,
        child: Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: t.detailBorder),
            borderRadius: BorderRadius.circular(6),
            color: t.dashaAltRow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title  —  $dateLine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: t.primaryDark)),
              const SizedBox(height: 1),
              Expanded(child: Text(desc, style: const TextStyle(fontSize: 8, color: Colors.black87))),
            ],
          ),
        ),
      ));
    }

    if (cards.isEmpty) return const SizedBox();
    return Column(children: cards);
  }

  static Widget _buildAstrologerSection(UserDetails user, PdfThemeConfig t) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: t.tableHeaderBg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: t.detailBorder.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (user.jyotishiName.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user.jyotishiName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: t.footerText)),
                if (user.jyotishiAddress.isNotEmpty)
                  Text(user.jyotishiAddress, style: TextStyle(fontSize: 9, color: t.footerText.withOpacity(0.7))),
              ],
            ),
          if (user.jyotishiPhone.isNotEmpty)
            Text('📞 ${user.jyotishiPhone}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: t.footerText)),
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
      child: Center(
        child: Text(AppLocale.l('jpBharatiyam'), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: t.footerText.withOpacity(0.5))),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // PAGE 3: Antardasha Details
  // ════════════════════════════════════════════════════════
  static Widget _buildPage3Content(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final title = AppLocale.l('jpAntardashaTitle');

    List<Widget> tables = [];
    for (final md in result.dashas) {
      List<TableRow> rows = [
        TableRow(
          decoration: BoxDecoration(color: t.tableHeaderBg),
          children: [
            Padding(padding: const EdgeInsets.all(2), child: Text(AppLocale.l('jpAntardasha'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: t.tableHeaderText))),
            Padding(padding: const EdgeInsets.all(2), child: Text(AppLocale.l('jpStart'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: t.tableHeaderText))),
            Padding(padding: const EdgeInsets.all(2), child: Text(AppLocale.l('jpEnd'), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: t.tableHeaderText))),
          ],
        )
      ];
      
      int i = 0;
      for (final ad in md.antardashas) {
        final isEven = (i++) % 2 == 0;
        final startStr = '${ad.start.day.toString().padLeft(2,'0')}-${ad.start.month.toString().padLeft(2,'0')}-${ad.start.year}';
        final endStr = '${ad.end.day.toString().padLeft(2,'0')}-${ad.end.month.toString().padLeft(2,'0')}-${ad.end.year}';
        
        rows.add(
          TableRow(
            decoration: BoxDecoration(color: isEven ? Colors.white : t.tableAltRow),
            children: [
              Padding(padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: Text(trAll(ad.lord), textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.black))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: Text(startStr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.black))),
              Padding(padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2), child: Text(endStr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.black))),
            ],
          )
        );
      }
      
      tables.add(
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(border: Border.all(color: t.detailBorder), borderRadius: BorderRadius.circular(4)),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: t.sectionTitleBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                  child: Text('${trAll(md.lord)} ${AppLocale.l('jpMahaDasha')}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: t.sectionTitleText)),
                ),
                Expanded(
                  child: Table(
                    border: const TableBorder(
                      horizontalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                      verticalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
                    ),
                    children: rows,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Group into rows of 3
    List<Widget> gridRows = [];
    for (int i = 0; i < tables.length; i += 3) {
      gridRows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tables.sublist(i, (i + 3 > tables.length) ? tables.length : i + 3),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(title, '${user.name} — ${user.dateStr}', t),
        const SizedBox(height: 5),
        Expanded(child: Column(children: gridRows)),
        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // PAGE 4: Varga Kundalis
  // ════════════════════════════════════════════════════════
  static Widget _buildPage4Content(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final title = AppLocale.l('jpVargaKundaliTitle');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(title, '${user.name} — ${user.dateStr}', t),
        const SizedBox(height: 5),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpD1Rashi'), _rashiChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpD2Hora'), _horaChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpD3Drekkana'), _drekkanaChart(result), t))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpD9Navamsha'), _navamshaChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpD12Dvadasha'), _dvadashamshaChart(result), t))),
              const SizedBox(width: 8),
              Expanded(child: AspectRatio(aspectRatio: 1.0, child: _buildChartWidget(AppLocale.l('jpD30Trimsha'), _trimshamshaChart(result), t))),
            ],
          ),
        ),
        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // PAGE 5: Ashtakavarga
  // ════════════════════════════════════════════════════════
  static Widget _buildPage5Content(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final title = AppLocale.l('jpAshtakavargaTitle');

    final Map<String, int> rashiPositions = {};
    for (final p in AshtakaVarga.planetsWithLagna) {
      final info = result.planets[p];
      if (info != null) {
        rashiPositions[p] = (info.longitude / 30).floor() % 12;
      }
    }
    
    final avResult = AshtakaVarga.computeAll(rashiPositions);
    
    List<String> colNames = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
    List<Widget> headerCells = [
      Padding(padding: const EdgeInsets.all(4), child: Text(AppLocale.l('hGraha') != 'hGraha' ? AppLocale.l('hGraha') : 'ಗ್ರಹ', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: t.tableHeaderText)))
    ];
    for (String cn in colNames) {
      headerCells.add(Padding(padding: const EdgeInsets.all(4), child: Text(trAll(cn), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: t.tableHeaderText))));
    }
    headerCells.add(Padding(padding: const EdgeInsets.all(4), child: Text(AppLocale.l('jpTotal') != 'jpTotal' ? AppLocale.l('jpTotal') : 'ಒಟ್ಟು', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: t.tableHeaderText))));

    List<TableRow> rows = [
      TableRow(decoration: BoxDecoration(color: t.tableHeaderBg), children: headerCells)
    ];

    int rowIndex = 0;
    for (String p in AshtakaVarga.planets) {
      final bindus = avResult[p]!;
      int total = bindus.fold(0, (sum, val) => sum + val);
      final isEven = (rowIndex++) % 2 == 0;
      
      List<Widget> cells = [
        Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(trAll(p), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)))
      ];
      for (int b in bindus) {
        cells.add(Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(b.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black))));
      }
      cells.add(Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: Text(total.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black))));
      
      rows.add(TableRow(decoration: BoxDecoration(color: isEven ? Colors.white : t.tableAltRow), children: cells));
    }
    
    final sav = avResult['SAV']!;
    int savTotal = sav.fold(0, (sum, val) => sum + val);
    
    List<Widget> savCells = [
      Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(AppLocale.l('jpSarvashtaka') != 'jpSarvashtaka' ? AppLocale.l('jpSarvashtaka') : 'ಸರ್ವಾಷ್ಟಕ', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black)))
    ];
    for (int b in sav) {
      savCells.add(Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(b.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black))));
    }
    savCells.add(Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: Text(savTotal.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black))));
    
    rows.add(TableRow(decoration: BoxDecoration(color: t.tableAltRow.withOpacity(0.5)), children: savCells));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(title, '${user.name} — ${user.dateStr}', t),
        const SizedBox(height: 20),
        _buildSectionTitle(AppLocale.l('jpAshtakavargaSection') != 'jpAshtakavargaSection' ? AppLocale.l('jpAshtakavargaSection') : 'ಭಿನ್ನಾಷ್ಟಕ ಮತ್ತು ಸರ್ವಾಷ್ಟಕ ವರ್ಗ', t),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(border: Border.all(color: t.detailBorder), borderRadius: BorderRadius.circular(6)),
          child: Table(
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
              verticalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
            ),
            children: rows,
          ),
        ),
        const Spacer(),
        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // PAGE 6: Shadbala
  // ════════════════════════════════════════════════════════
  static Widget _buildPage6Content(UserDetails user, KundaliResult result, PdfThemeConfig t) {
    final title = AppLocale.l('jpShadbalaTitle');

    List<String> headers = [AppLocale.l('sbGraha'), AppLocale.l('sbSthana'), AppLocale.l('sbDik'), AppLocale.l('sbKala'), AppLocale.l('sbCheshta'), AppLocale.l('sbNaisargika'), AppLocale.l('sbDrik'), AppLocale.l('sbTotal'), AppLocale.l('sbRequired'), AppLocale.l('sbStatus')];
    List<TableRow> rows = [
      TableRow(
        decoration: BoxDecoration(color: t.tableHeaderBg),
        children: headers.map((h) => Padding(padding: const EdgeInsets.all(4), child: Text(trAll(h), textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: t.tableHeaderText)))).toList(),
      )
    ];

    List<String> pNames = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'];
    
    int rowIndex = 0;
    for (String engName in pNames) {
      final sb = result.shadbala[engName];
      if (sb == null) continue;
      
      final isEven = (rowIndex++) % 2 == 0;
      bool isStrong = sb['IsStrong'] ?? false;
      Color statusColor = isStrong ? Colors.green.shade100 : Colors.red.shade100;
      String statusStr = isStrong ? AppLocale.l('sbStrong') : AppLocale.l('sbWeak');
      
      List<String> cells = [
        trAll(appPlanetNames[engName] ?? engName),
        (sb['Sthana'] as double).toStringAsFixed(2),
        (sb['Dik'] as double).toStringAsFixed(2),
        (sb['Kala'] as double).toStringAsFixed(2),
        (sb['Cheshta'] as double).toStringAsFixed(2),
        (sb['Naisargika'] as double).toStringAsFixed(2),
        (sb['Drik'] as double).toStringAsFixed(2),
        (sb['Total'] as double).toStringAsFixed(2),
        (sb['Required'] as double).toStringAsFixed(2),
        trAll(statusStr),
      ];
      
      rows.add(
        TableRow(
          decoration: BoxDecoration(color: isEven ? Colors.white : t.tableAltRow),
          children: cells.asMap().entries.map((e) {
            Widget cellText = Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: e.key == 0 ? FontWeight.bold : FontWeight.normal));
            if (e.key == 9) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                color: statusColor,
                child: cellText,
              );
            }
            return Padding(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4), child: cellText);
          }).toList(),
        )
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(title, '${user.name} — ${user.dateStr}', t),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(border: Border.all(color: t.detailBorder), borderRadius: BorderRadius.circular(6)),
          child: Table(
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
              verticalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
            ),
            children: rows,
          ),
        ),
        const Spacer(),
        _buildFooter(user.jyotishiName, user.jyotishiPhone, t),
      ],
    );
  }
}

