import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    final fontRegular = await PdfGoogleFonts.notoSansKannadaRegular();
    final fontBold = await PdfGoogleFonts.notoSansKannadaBold();

    final doc = pw.Document();

    final p = result.panchang;
    final lagnaInfo = result.planets['ಲಗ್ನ'];
    final lagnaRashi = lagnaInfo != null ? lagnaInfo.rashi : '-';

    // Page 1
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader('ಜನ್ಮ ಪತ್ರಿಕೆ', 'ಭಾರತೀಯಂ ಜ್ಯೋತಿಷ ಅಪ್ಲಿಕೇಶನ್', fontBold, fontRegular),
            pw.SizedBox(height: 10),
            
            _buildSectionTitle('ವೈಯಕ್ತಿಕ ವಿವರ', fontBold),
            _buildDetailBox([
              ['ಜಾತಕರ ಹೆಸರು:', user.name, 'ಜನ್ಮ ಊರು:', user.place],
              ['ಜನನ ದಿನಾಂಕ:', user.dateStr, 'ಜನ್ಮ ಸಮಯ:', user.timeStr],
              ['ತಂದೆ ಹೆಸರು:', user.fatherName, 'ತಾಯಿ ಹೆಸರು:', user.motherName],
              ['ಗೋತ್ರ:', user.gotra, 'ಲಗ್ನ ರಾಶಿ:', lagnaRashi],
            ], fontRegular, fontBold),
            pw.SizedBox(height: 10),

            _buildSectionTitle('ಪಂಚಾಂಗ ವಿವರ', fontBold),
            _buildDetailBox([
              ['ಸಂವತ್ಸರ:', p.samvatsara, 'ಚಂದ್ರ ಮಾಸ:', p.chandraMasa],
              ['ರವಿ ಮಾಸ:', p.souraMasa, 'ಋತು:', p.rutu],
              ['ತಿಥಿ:', p.tithi, 'ವಾರ:', p.vara],
              ['ನಕ್ಷತ್ರ:', p.nakshatra, 'ಕರಣ:', p.karana],
              ['ಯೋಗ:', p.yoga, 'ಚಂದ್ರ ರಾಶಿ:', p.chandraRashi],
              ['ಗತ ಘಟಿ:', p.gataGhati, 'ಪರಮ ಘಟಿ:', p.paramaGhati],
              ['ಸೂರ್ಯೋದಯ:', p.sunrise, 'ಸೂರ್ಯಾಸ್ತ:', p.sunset],
            ], fontRegular, fontBold),
            pw.SizedBox(height: 10),

            _buildSectionTitle('ತತ್ಕಾಲ ಗ್ರಹಸ್ಥಿತಿ', fontBold),
            _buildGrahaTable(result, fontRegular, fontBold),
            pw.SizedBox(height: 10),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: _buildChart('ರಾಶಿ ಕುಂಡಲಿ', _rashiChart(result), fontRegular, fontBold)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildChart('ನವಾಂಶ ಕುಂಡಲಿ', _navamshaChart(result), fontRegular, fontBold)),
                pw.SizedBox(width: 10),
                pw.Expanded(child: _buildChart('ಭಾವ ಕುಂಡಲಿ', _bhavaChart(result), fontRegular, fontBold)),
              ],
            ),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(user.jyotishiName, user.jyotishiPhone, fontRegular, fontBold);
        },
      ),
    );

    // Page 2: Dasha
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return [
            _buildHeader('ಜನ್ಮ ಪತ್ರಿಕೆ — ದಶಾ ವಿವರ', '${user.name} — ${user.dateStr}', fontBold, fontRegular),
            pw.SizedBox(height: 10),

            _buildSectionTitle('ನಕ್ಷತ್ರ ಮತ್ತು ದಶಾ ವಿವರ', fontBold),
            _buildDetailBox([
              ['ಜನ್ಮ ನಕ್ಷತ್ರ:', p.nakshatra, 'ಚಂದ್ರ ರಾಶಿ:', p.chandraRashi],
              ['ನಕ್ಷತ್ರ ಪರಮ ಘಟಿ:', p.paramaGhati, 'ಗತ ಘಟಿ:', p.gataGhati],
              ['ಶಿಷ್ಟ ದಶಾ ನಾಥ:', p.dashaLord, 'ಶಿಷ್ಟ ದಶಾ ಶೇಷ:', p.dashaBalance],
            ], fontRegular, fontBold),
            pw.SizedBox(height: 10),

            _buildSectionTitle('ವಿಂಶೋತ್ತರೀ ಮಹಾ ದಶಾ', fontBold),
            _buildDashaTable(result, fontRegular, fontBold),
            pw.SizedBox(height: 10),

            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF8E1'),
                border: pw.Border.all(color: PdfColor.fromHex('#FFD54F')),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text('ಶಿಷ್ಟ ದಶೆ: ${p.dashaLord} — ಶೇಷ: ${p.dashaBalance}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#C62828'))),
            ),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(user.jyotishiName, user.jyotishiPhone, fontRegular, fontBold);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${user.name}_janmapatrike',
    );
  }

  static pw.Widget _buildHeader(String mainTitle, String subTitle, pw.Font fontBold, pw.Font fontRegular) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F0E8'),
        border: pw.Border.all(color: PdfColor.fromHex('#2E1A47'), width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Text('ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ ।। ಶ್ರೀ ಗುರುಭ್ಯೋ ನಮಃ ।।', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#C62828'))),
          pw.SizedBox(height: 4),
          pw.Text(mainTitle, style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColor.fromHex('#2E1A47'))),
          pw.SizedBox(height: 2),
          pw.Text(subTitle, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColor.fromHex('#757575'))),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font fontBold) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#E1BEE7'), width: 1)),
      ),
      child: pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColor.fromHex('#6A1B9A'))),
    );
  }

  static pw.Widget _buildDetailBox(List<List<String>> rows, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#BDBDBD')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        color: PdfColor.fromHex('#F9FBE7'), // Light tint like panchang-box
      ),
      child: pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1.5),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.5),
        },
        children: rows.map((row) {
          return pw.TableRow(
            children: row.asMap().entries.map((e) {
              final isLabel = e.key % 2 == 0;
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: pw.Text(
                  e.value,
                  style: pw.TextStyle(
                    font: isLabel ? fontBold : fontRegular,
                    fontSize: 9,
                    color: isLabel ? PdfColor.fromHex('#37474F') : PdfColor.fromHex('#212121'),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildGrahaTable(KundaliResult result, pw.Font fontRegular, pw.Font fontBold) {
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

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#BDBDBD')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'), width: 0.5)),
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4A148C')),
        cellStyle: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.black),
        cellAlignment: pw.Alignment.center,
        headerAlignment: pw.Alignment.center,
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      ),
    );
  }

  static pw.Widget _buildChart(String title, List<List<String>> chart, pw.Font fontRegular, pw.Font fontBold) {
    if (chart.isEmpty) chart = List.generate(12, (_) => []);
    String p(int idx) => chart[idx].join(' ');

    const double boxW = 42.0;

    pw.Widget box(String text) {
      return pw.Container(
        width: boxW,
        height: boxW,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex('#666666'), width: 0.5),
        ),
        padding: const pw.EdgeInsets.all(1),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#1A1A1A')),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColor.fromHex('#333333'), width: 1.5)),
          child: pw.Column(
            children: [
              pw.Row(children: [box(p(11)), box(p(0)), box(p(1)), box(p(2))]),
              pw.Row(
                children: [
                  pw.Column(children: [box(p(10)), box(p(9))]),
                  pw.Container(
                    width: boxW * 2,
                    height: boxW * 2,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('#666666'), width: 0.5),
                      color: PdfColor.fromHex('#F5F0E8'),
                    ),
                    child: pw.Text(
                      title.split(' ')[0],
                      style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#2E1A47')),
                    ),
                  ),
                  pw.Column(children: [box(p(3)), box(p(4))]),
                ]
              ),
              pw.Row(children: [box(p(8)), box(p(7)), box(p(6)), box(p(5))]),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('#2E1A47'))),
      ],
    );
  }

  static pw.Widget _buildDashaTable(KundaliResult result, pw.Font fontRegular, pw.Font fontBold) {
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

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#BDBDBD')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'), width: 0.5)),
        headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#4A148C')),
        cellStyle: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.black),
        cellAlignment: pw.Alignment.center,
        headerAlignment: pw.Alignment.center,
        cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      ),
    );
  }

  static pw.Widget _buildFooter(String jyotishiName, String jyotishiPhone, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromHex('#BDBDBD'), width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(jyotishiName, style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#2E1A47'))),
          pw.Text('ಭಾರತೀಯಂ', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColor.fromHex('#9E9E9E'))),
          pw.Text(jyotishiPhone, style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#2E1A47'))),
        ],
      ),
    );
  }
}
