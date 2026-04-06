import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';

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

  static Future<void> generateAndPrint(UserDetails user, KundaliResult result) async {
    final controller = ScreenshotController();

    // A4 Dimensions at standard 72 DPI
    const double pageWidth = 595.0;
    const double pageHeight = 842.0;

    // Build standard offscreen Flutter widgets representing the pages
    final page1Widget = _buildPageWrapper(
      width: pageWidth,
      height: pageHeight,
      child: _buildPage1Content(user, result),
    );

    final page2Widget = _buildPageWrapper(
      width: pageWidth,
      height: pageHeight,
      child: _buildPage2Content(user, result),
    );

    // Capture to high-res images (pixelRatio: 3.0 provides excellent print clarity)
    final Uint8List page1Bytes = await controller.captureFromWidget(page1Widget, pixelRatio: 3.0, delay: const Duration(milliseconds: 100));
    final Uint8List page2Bytes = await controller.captureFromWidget(page2Widget, pixelRatio: 3.0, delay: const Duration(milliseconds: 100));

    // Compile into PDF
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

  static Widget _buildPageWrapper({required double width, required double height, required Widget child}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Theme(
          data: ThemeData(
            // Specify default fonts for flutter widget tree so Kannada renders perfectly
            fontFamily: 'Noto Sans Kannada', // ensure it falls back to system font if unavailable
          ),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.black, fontSize: 10),
            child: Material(
              color: Colors.white,
              child: Container(
                width: width,
                height: height,
                color: const Color(0xFFFFFFF8), // Match old background
                padding: const EdgeInsets.all(30),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPage1Content(UserDetails user, KundaliResult result) {
    final p = result.panchang;
    final lagnaInfo = result.planets['ಲಗ್ನ'];
    final lagnaRashi = lagnaInfo != null ? lagnaInfo.rashi : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('ಜನ್ಮ ಪತ್ರಿಕೆ', 'ಭಾರತೀಯಂ ಜ್ಯೋತಿಷ ಅಪ್ಲಿಕೇಶನ್'),
        const SizedBox(height: 10),
        
        _buildSectionTitle('ವೈಯಕ್ತಿಕ ವಿವರ'),
        _buildDetailBox([
          ['ಜಾತಕರ ಹೆಸರು:', user.name, 'ಜನ್ಮ ಊರು:', user.place],
          ['ಜನನ ದಿನಾಂಕ:', user.dateStr, 'ಜನ್ಮ ಸಮಯ:', user.timeStr],
          ['ತಂದೆ ಹೆಸರು:', user.fatherName, 'ತಾಯಿ ಹೆಸರು:', user.motherName],
          ['ಗೋತ್ರ:', user.gotra, 'ಲಗ್ನ ರಾಶಿ:', lagnaRashi],
        ]),
        const SizedBox(height: 10),

        _buildSectionTitle('ಪಂಚಾಂಗ ವಿವರ'),
        _buildDetailBox([
          ['ಸಂವತ್ಸರ:', p.samvatsara, 'ಚಂದ್ರ ಮಾಸ:', p.chandraMasa],
          ['ರವಿ ಮಾಸ:', p.souraMasa, 'ಋತು:', p.rutu],
          ['ತಿಥಿ:', p.tithi, 'ವಾರ:', p.vara],
          ['ನಕ್ಷತ್ರ:', p.nakshatra, 'ಕರಣ:', p.karana],
          ['ಯೋಗ:', p.yoga, 'ಚಂದ್ರ ರಾಶಿ:', p.chandraRashi],
          ['ಗತ ಘಟಿ:', p.gataGhati, 'ಪರಮ ಘಟಿ:', p.paramaGhati],
          ['ಸೂರ್ಯೋದಯ:', p.sunrise, 'ಸೂರ್ಯಾಸ್ತ:', p.sunset],
        ]),
        const SizedBox(height: 10),

        _buildSectionTitle('ತತ್ಕಾಲ ಗ್ರಹಸ್ಥಿತಿ'),
        _buildGrahaTable(result),
        const SizedBox(height: 10),

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildChartWidget('ರಾಶಿ ಕುಂಡಲಿ', _rashiChart(result))),
              const SizedBox(width: 8),
              Expanded(child: _buildChartWidget('ನವಾಂಶ ಕುಂಡಲಿ', _navamshaChart(result))),
              const SizedBox(width: 8),
              Expanded(child: _buildChartWidget('ಭಾವ ಕುಂಡಲಿ', _bhavaChart(result))),
            ],
          ),
        ),

        _buildFooter(user.jyotishiName, user.jyotishiPhone),
      ],
    );
  }

  static Widget _buildPage2Content(UserDetails user, KundaliResult result) {
    final p = result.panchang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader('ಜನ್ಮ ಪತ್ರಿಕೆ — ದಶಾ ವಿವರ', '${user.name} — ${user.dateStr}'),
        const SizedBox(height: 15),

        _buildSectionTitle('ನಕ್ಷತ್ರ ಮತ್ತು ದಶಾ ವಿವರ'),
        _buildDetailBox([
          ['ಜನ್ಮ ನಕ್ಷತ್ರ:', p.nakshatra, 'ಚಂದ್ರ ರಾಶಿ:', p.chandraRashi],
          ['ನಕ್ಷತ್ರ ಪರಮ ಘಟಿ:', p.paramaGhati, 'ಗತ ಘಟಿ:', p.gataGhati],
          ['ಶಿಷ್ಟ ದಶಾ ನಾಥ:', p.dashaLord, 'ಶಿಷ್ಟ ದಶಾ ಶೇಷ:', p.dashaBalance],
        ]),
        const SizedBox(height: 15),

        _buildSectionTitle('ವಿಂಶೋತ್ತರೀ ಮಹಾ ದಶಾ'),
        Expanded(child: _buildDashaTable(result)),
        const SizedBox(height: 15),

        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            border: Border.all(color: const Color(0xFFFFD54F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('ಶಿಷ್ಟ ದಶೆ: ${p.dashaLord} — ಶೇಷ: ${p.dashaBalance}', 
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFC62828))
          ),
        ),

        const SizedBox(height: 15),
        _buildFooter(user.jyotishiName, user.jyotishiPhone),
      ],
    );
  }

  static Widget _buildHeader(String mainTitle, String subTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        border: Border.all(color: const Color(0xFF2E1A47), width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          const Text('ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ ।। ಶ್ರೀ ಗುರುಭ್ಯೋ ನಮಃ ।।', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFC62828))),
          const SizedBox(height: 4),
          Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF2E1A47))),
          const SizedBox(height: 2),
          Text(subTitle, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Color(0xFF757575))),
        ],
      ),
    );
  }

  static Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE1BEE7), width: 1.5)),
      ),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF6A1B9A))),
    );
  }

  static Widget _buildDetailBox(List<List<String>> rows) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF9FBE7),
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
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: isLabel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                    color: isLabel ? const Color(0xFF37474F) : const Color(0xFF212121),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildGrahaTable(KundaliResult result) {
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
        border: Border.all(color: const Color(0xFFBDBDBD)),
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
            decoration: const BoxDecoration(color: Color(0xFF4A148C), borderRadius: BorderRadius.vertical(top: Radius.circular(5))),
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.all(6),
              child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white)),
            )).toList(),
          ),
          // Data
          ...rows.asMap().entries.map((entry) {
            final isEven = entry.key % 2 == 0;
            return TableRow(
              decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF5F0E8)),
              children: entry.value.map((cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Text(cell, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black)),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildChartWidget(String title, List<List<String>> chart) {
    if (chart.isEmpty) chart = List.generate(12, (_) => []);
    String p(int idx) => chart[idx].join('\n'); // use newlines to separate planets cleanly

    Widget box(String text) {
      return Expanded(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF666666), width: 0.5),
            color: Colors.white,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 9.5, color: Color(0xFF1A1A1A), height: 1.1),
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
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF333333), width: 1.5)),
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
                            border: Border.all(color: const Color(0xFF666666), width: 0.5),
                            color: const Color(0xFFF5F0E8),
                          ),
                          child: Text(
                            title.split(' ')[0], // ರಾಶಿ / ನವಾಂಶ / ಭಾವ
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E1A47)),
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF2E1A47))),
      ],
    );
  }

  static Widget _buildDashaTable(KundaliResult result) {
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
        border: Border.all(color: const Color(0xFFBDBDBD)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Table(
        border: const TableBorder(
          horizontalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          verticalInside: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFF4A148C), borderRadius: BorderRadius.vertical(top: Radius.circular(5))),
            children: headers.map((h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
            )).toList(),
          ),
          ...rows.asMap().entries.map((entry) {
            final isEven = entry.key % 2 == 0;
            return TableRow(
              decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFE8EAF6)),
              children: entry.value.map((cell) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(cell, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black)),
              )).toList(),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildFooter(String jyotishiName, String jyotishiPhone) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFBDBDBD), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(jyotishiName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF2E1A47))),
          const Text('ಭಾರತೀಯಂ', style: TextStyle(fontWeight: FontWeight.normal, fontSize: 10, color: Color(0xFF9E9E9E))),
          Text(jyotishiPhone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF2E1A47))),
        ],
      ),
    );
  }
}
