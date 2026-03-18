import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  print('Generating PDF...');

  final pdf = pw.Document();

  // Load the Kannada font
  final fontFile = File('assets/TiroKannada-Regular.ttf');
  final fontBytes = fontFile.readAsBytesSync();
  final ttf = pw.Font.ttf(fontBytes.buffer.asByteData());

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ಭಾರತೀಯಂ ಜ್ಯೋತಿಷ್ಯ', style: pw.TextStyle(font: ttf, fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple)),
                  pw.Text('ಜಾತಕ ವರದಿ', style: pw.TextStyle(font: ttf, fontSize: 22, color: PdfColors.grey700)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blueGrey, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ಬಳಕೆದಾರರ ವಿವರಗಳು', style: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ಹೆಸರು: ಗೌರೀಶ', style: pw.TextStyle(font: ttf, fontSize: 18)),
                      pw.Text('ಹುಟ್ಟಿದ ದಿನಾಂಕ: 01-Jan-2000', style: pw.TextStyle(font: ttf, fontSize: 18)),
                    ]
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('ಸ್ಥಳ: ಬೆಂಗಳೂರು', style: pw.TextStyle(font: ttf, fontSize: 18)),
                      pw.Text('ಸಮಯ: 10:30 AM', style: pw.TextStyle(font: ttf, fontSize: 18)),
                    ]
                  ),
                ]
              )
            ),
            pw.SizedBox(height: 30),
            pw.Text('ಪಂಚಾಂಗ ವಿವರಗಳು', style: pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 15),
            pw.TableHelper.fromTextArray(
              context: context,
              cellStyle: pw.TextStyle(font: ttf, fontSize: 18),
              data: const <List<String>>[
                <String>['ವಿವರ', 'ಫಲಿತಾಂಶ'],
                <String>['ತಿಥಿ', 'ಶುಕ್ಲ ಪಕ್ಷ ದಶಮಿ'],
                <String>['ನಕ್ಷತ್ರ', 'ರೋಹಿಣಿ'],
                <String>['ಯೋಗ', 'ಶಿವ'],
                <String>['ಕರಣ', 'ತೈತಿಲ'],
                <String>['ಋತು', 'ವಸಂತ'],
              ],
              headerStyle: pw.TextStyle(font: ttf, fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.Spacer(),
            pw.Center(child: pw.Text('ಭಾರತೀಯಂ ಅಪ್ಲಿಕೇಶನ್‌ನಿಂದ ರಚಿಸಲಾಗಿದೆ', style: pw.TextStyle(font: ttf, fontSize: 14, color: PdfColors.grey))),
          ],
        );
      },
    ),
  );

  final file = File('test_kundali.pdf');
  await file.writeAsBytes(await pdf.save());
  print('Saved sandbox PDF with Kannada to \${file.absolute.path}');
}
