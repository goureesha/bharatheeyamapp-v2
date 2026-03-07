import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/calculator.dart';
import 'storage_service.dart';

class PdfService {
  static Future<void> generateAndPrintHoroscope({
    required Profile profile,
    required KundaliResult result,
  }) async {
    final pdf = pw.Document();

    // Load Kannada font on the fly for PDF rendering
    final fontRegular = await PdfGoogleFonts.notoSansKannadaRegular();
    final fontBold = await PdfGoogleFonts.notoSansKannadaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (context) => _buildHeader(fontBold),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) {
          return [
            _buildProfileInfo(profile, fontBold),
            pw.SizedBox(height: 20),
            _buildPanchang(result.panchang, fontBold),
            pw.SizedBox(height: 20),
            _buildPlanetaryDetails(result.planets, fontBold),
            pw.SizedBox(height: 20),
            if (result.shadbala.isNotEmpty) _buildShadbala(result.shadbala, fontBold),
          ];
        },
      ),
    );

    // This triggers the native print/download dialog (Mobile/Web)
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${profile.name}_Horoscope.pdf',
    );
  }

  static pw.Widget _buildHeader(pw.Font boldFont) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        children: [
          pw.Text('ಭಾರತೀಯಮ್ - ವೇದ ಜ್ಯೋತಿಷ್ಯ ವರದಿ', style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.deepPurple800)),
          pw.Text('Bharatheeyam - Vedic Astrology Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          pw.Divider(color: PdfColors.deepPurple300),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font regularFont) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text('ಪುಟ (Page) ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(font: regularFont, color: PdfColors.grey)),
    );
  }

  static pw.Widget _buildProfileInfo(Profile profile, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ಜಾತಕದ ವಿವರಗಳು (Birth Details)', style: pw.TextStyle(font: boldFont, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ಹೆಸರು: ${profile.name}'),
                  pw.Text('ದಿನಾಂಕ: ${profile.date}'),
                  pw.Text('ಸಮಯ: ${profile.hour}:${profile.minute.toString().padLeft(2, '0')} ${profile.ampm}'),
                ]
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ಸ್ಥಳ: ${profile.place}'),
                  pw.Text('ಅಕ್ಷಾಂಶ: ${profile.lat}'),
                  pw.Text('ರೇಖಾಂಶ: ${profile.lon}'),
                ]
              ),
            ]
          )
        ],
      ),
    );
  }

  static pw.Widget _buildPanchang(PanchangData p, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ಪಂಚಾಂಗ (Panchanga)', style: pw.TextStyle(font: boldFont, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            _pRow('ಸೂರ್ಯೋದಯ (Sunrise)', p.sunrise),
            _pRow('ಸೂರ್ಯಾಸ್ತ (Sunset)', p.sunset),
            _pRow('ತಿಥಿ (Tithi)', p.tithi),
            _pRow('ವಾರ (Vara)', p.vara),
            _pRow('ನಕ್ಷತ್ರ (Nakshatra)', p.nakshatra),
            _pRow('ಯೋಗ (Yoga)', p.yoga),
            _pRow('ಕರಣ (Karana)', p.karana),
          ]
        )
      ]
    );
  }

  static pw.TableRow _pRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value)),
      ]
    );
  }

  static pw.Widget _buildPlanetaryDetails(Map<String, PlanetInfo> planets, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ಗ್ರಹ ಸ್ಫುಟ (Planetary Positions)', style: pw.TextStyle(font: boldFont, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ಗ್ರಹ (Planet)', style: pw.TextStyle(font: boldFont))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ಸ್ಫುಟ (Longitude)', style: pw.TextStyle(font: boldFont))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ರಾಶಿ (Sign)', style: pw.TextStyle(font: boldFont))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('ನಕ್ಷತ್ರ-ಪಾದ (Star-Pada)', style: pw.TextStyle(font: boldFont))),
              ]
            ),
            ...planets.entries.map((e) {
              final p = e.value;
              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.key, style: pw.TextStyle(font: boldFont))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.lonString)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.rashi)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${p.nakshatra}-${p.pada}')),
                ]
              );
            }).toList(),
          ]
        )
      ]
    );
  }

  static pw.Widget _buildShadbala(Map<String, Map<String, dynamic>> shadbala, pw.Font boldFont) {
    final pKeysKn = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];
    final pKeysEng = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ಷಡ್ಬಲ (Shadbala)', style: pw.TextStyle(font: boldFont, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಗ್ರಹ', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಸ್ಥಾನ', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ದಿಕ್', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಕಾಲ', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಚೇಷ್ಟಾ', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ನೈಸರ್ಗಿಕ', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ದೃಕ್', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಒಟ್ಟು(T)', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಅರ್ಹತೆ(R)', style: pw.TextStyle(font: boldFont, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('ಸ್ಥಿತಿ(S)', style: pw.TextStyle(font: boldFont, fontSize: 10))),
              ]
            ),
            ...List.generate(pKeysEng.length, (i) {
              final eKey = pKeysEng[i];
              final kKey = pKeysKn[i];
              final data = shadbala[eKey] ?? {};
              
              final isStrong = data['IsStrong'] == true;
              final totalVal = (data['Total'] ?? 0.0) as double;
              final reqVal = (data['Required'] ?? 0.0) as double;

              return pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(kKey, style: pw.TextStyle(font: boldFont, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((data['Sthana'] ?? 0.0) as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((data['Dik'] ?? 0.0) as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((data['Kala'] ?? 0.0) as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((data['Cheshta'] ?? 0.0) as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((data['Naisargika'] ?? 0.0) as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(((data['Drik'] ?? 0.0) as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(totalVal.toStringAsFixed(2), style: pw.TextStyle(font: boldFont, fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(reqVal.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(isStrong ? 'Strong' : 'Weak', style: pw.TextStyle(font: boldFont, fontSize: 10, color: isStrong ? PdfColors.green800 : PdfColors.red800))),
                ]
              );
            }),
          ]
        )
      ]
    );
  }
}
