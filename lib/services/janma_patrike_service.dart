import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../core/calculator.dart';
import '../constants/strings.dart';
import '../constants/places.dart';

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
  static Future<void> generateAndPrint(UserDetails user, KundaliResult result) async {
    String html = _htmlTemplate;

    // 1. Setup Basic Info
    html = html.replaceAll('{{JATAKAR_NAME}}', _escapeHtml(user.name));
    html = html.replaceAll('{{JANMA_OORU}}', _escapeHtml(user.place));
    html = html.replaceAll('{{JANMA_DATE}}', _escapeHtml(user.dateStr));
    html = html.replaceAll('{{JANMA_TIME}}', _escapeHtml(user.timeStr));
    html = html.replaceAll('{{FATHER_NAME}}', _escapeHtml(user.fatherName));
    html = html.replaceAll('{{MOTHER_NAME}}', _escapeHtml(user.motherName));
    html = html.replaceAll('{{GOTRA}}', _escapeHtml(user.gotra));
    html = html.replaceAll('{{JYOTISHI_NAME}}', _escapeHtml(user.jyotishiName));
    html = html.replaceAll('{{JYOTISHI_PHONE}}', _escapeHtml(user.jyotishiPhone));

    // 2. Setup Panchanga
    final p = result.panchang;
    html = html.replaceAll('{{SAMVATSARA}}', _escapeHtml(tr(p.samvatsara)));
    html = html.replaceAll('{{CHANDRA_MASA}}', _escapeHtml(tr(p.chandraMasa)));
    html = html.replaceAll('{{RAVI_MASA}}', _escapeHtml(tr(p.souraMasa)));
    html = html.replaceAll('{{TITHI}}', _escapeHtml(tr(p.tithi)));
    html = html.replaceAll('{{VARA}}', _escapeHtml(tr(p.vara)));
    html = html.replaceAll('{{NAKSHATRA}}', _escapeHtml(tr(p.nakshatra)));
    html = html.replaceAll('{{KARANA}}', _escapeHtml(tr(p.karana)));
    html = html.replaceAll('{{YOGA}}', _escapeHtml(tr(p.yoga)));
    html = html.replaceAll('{{RUTU}}', _escapeHtml(tr(p.rutu)));
    html = html.replaceAll('{{CHANDRA_RASHI}}', _escapeHtml(tr(p.chandraRashi)));
    html = html.replaceAll('{{SUNRISE}}', _escapeHtml(p.sunrise));
    html = html.replaceAll('{{SUNSET}}', _escapeHtml(p.sunset));
    
    // Ghati conversion helpers (simplified)
    html = html.replaceAll('{{GATA_GHATI}}', _escapeHtml(p.gataGhati));
    html = html.replaceAll('{{PARAMA_GHATI}}', _escapeHtml(p.paramaGhati));
    
    // Remaining dasha
    html = html.replaceAll('{{REMAINING_DASHA_LORD}}', _escapeHtml(tr(p.dashaLord)));
    html = html.replaceAll('{{REMAINING_DASHA_GOTS}}', _escapeHtml(p.dashaBalance));
    
    // Lagna
    final lagnaInfo = result.planets['Lagna'];
    html = html.replaceAll('{{LAGNA_RASHI}}', _escapeHtml(lagnaInfo != null ? tr(lagnaInfo.rashi) : '-'));

    // 3. Build Graha Sthiti Table
    final StringBuffer grahaRows = StringBuffer();
    for (final planetKey in planetOrder) {
      final info = result.planets[planetKey];
      if (info == null) continue;
      String vakrast = '-';
      if (info.speed < 0) vakrast = 'ವ';
      if (info.isCombust) vakrast = vakrast == 'ವ' ? 'ವ / ಅ' : 'ಅ';
      
      grahaRows.writeln('<tr>');
      grahaRows.writeln('  <td>${_escapeHtml(tr(planetKey))}</td>');
      grahaRows.writeln('  <td>${_escapeHtml(tr(info.rashi))}</td>');
      grahaRows.writeln('  <td>${_escapeHtml(formatDeg(info.longitude))}</td>');
      grahaRows.writeln('  <td>${_escapeHtml(tr(info.nakshatra))}</td>');
      grahaRows.writeln('  <td>${info.pada}</td>');
      grahaRows.writeln('  <td>$vakrast</td>');
      grahaRows.writeln('</tr>');
    }
    html = html.replaceAll('{{GRAHA_ROWS}}', grahaRows.toString());

    // 4. Build Charts
    html = html.replaceAll('{{RASHI_GRID}}', _buildGrid(result.rashiChart));
    html = html.replaceAll('{{NAVAMSHA_GRID}}', _buildGrid(result.navamshaChart));
    html = html.replaceAll('{{BHAVA_GRID}}', _buildGrid(result.bhavaChart ?? result.rashiChart));

    // 5. Build Dasha Table
    final StringBuffer dashaRows = StringBuffer();
    for (int i = 0; i < result.dashas.length; i++) {
      final d = result.dashas[i];
      final startStr = '${d.start.day.toString().padLeft(2,'0')}-${d.start.month.toString().padLeft(2,'0')}-${d.start.year}';
      final endStr = '${d.end.day.toString().padLeft(2,'0')}-${d.end.month.toString().padLeft(2,'0')}-${d.end.year}';
      int years = d.end.year - d.start.year;
      
      dashaRows.writeln('<tr>');
      dashaRows.writeln('  <td>${i + 1}</td>');
      dashaRows.writeln('  <td>${_escapeHtml(tr(d.lord))}</td>');
      dashaRows.writeln('  <td>$years</td>');
      dashaRows.writeln('  <td>$startStr</td>');
      dashaRows.writeln('  <td>$endStr</td>');
      dashaRows.writeln('</tr>');
    }
    html = html.replaceAll('{{DASHA_ROWS}}', dashaRows.toString());

    // Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await Printing.convertHtml(
          format: PdfPageFormat.a4,
          html: html,
        );
      },
      name: '${user.name}_janmapatrike',
    );
  }

  static String _buildGrid(List<List<String>> chart) {
    if (chart.isEmpty) return '';
    return '''
      <tr>
        <td class="shri">ಶ್ರೀ:</td>
        <td>${_p(chart[11])}</td>
        <td>${_p(chart[0])}</td>
        <td>${_p(chart[1])}</td>
      </tr>
      <tr>
        <td class="shri">ಶ್ರೀ:</td>
        <td colspan="2" rowspan="2" class="center">{{CHART_NAME}}</td>
        <td>${_p(chart[2])}</td>
      </tr>
      <tr>
        <td>${_p(chart[10])}</td>
        <td class="shri">ಶ್ರೀ:</td>
      </tr>
      <tr>
        <td class="shri">ಶ್ರೀ:</td>
        <td class="shri">ಶ್ರೀ:</td>
        <td>${_p(chart[9])}</td>
        <td class="shri">ಶ್ರೀ:</td>
      </tr>
    ''';
  }

  static String _p(List<String> planets) {
    return _escapeHtml(planets.map((p) => shortPlanetNames[p] ?? tr(p).substring(0, 2)).join(' '));
  }

  static String _escapeHtml(String text) {
    return text.replaceAll('&', '&amp;')
               .replaceAll('<', '&lt;')
               .replaceAll('>', '&gt;')
               .replaceAll('"', '&quot;')
               .replaceAll("'", '&#39;');
  }

  static const String _htmlTemplate = r'''
<!DOCTYPE html>
<html lang="kn">
<head>
<meta charset="UTF-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Noto+Sans+Kannada:wght@400;600;700;900&display=swap');

  @page {
    size: A4;
    margin: 10mm 14mm 10mm 14mm;
  }

  * { margin: 0; padding: 0; box-sizing: border-box; }

  body {
    font-family: 'Noto Sans Kannada', sans-serif;
    font-size: 9pt;
    color: #212121;
    background: #FFFFF8;
    line-height: 1.35;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  /* ═══════════ HEADER ═══════════ */
  .header {
    background: linear-gradient(135deg, #F5F0E8 0%, #EDE7D9 100%);
    border: 2pt solid #2E1A47;
    border-radius: 4pt;
    padding: 6pt 10pt 4pt;
    text-align: center;
    margin-bottom: 4pt;
  }
  .invocation {
    font-size: 9pt;
    font-weight: 700;
    color: #C62828;
    letter-spacing: 0.5pt;
  }
  .main-title {
    font-size: 16pt;
    font-weight: 900;
    color: #2E1A47;
    margin: 2pt 0 1pt;
  }
  .branding {
    font-size: 7pt;
    color: #757575;
    font-weight: 400;
  }

  /* ═══════════ SECTION TITLES ═══════════ */
  .section-title {
    font-size: 9pt;
    font-weight: 700;
    color: #6A1B9A;
    text-align: center;
    margin: 3pt 0 2pt;
    padding-bottom: 1pt;
    border-bottom: 1pt solid #E1BEE7;
  }

  /* ═══════════ DETAIL BOXES ═══════════ */
  .detail-box {
    border: 1pt solid #BDBDBD;
    border-radius: 3pt;
    padding: 3pt 8pt;
    margin-bottom: 3pt;
  }
  .detail-table {
    width: 100%;
    border-collapse: collapse;
  }
  .detail-table td {
    padding: 1.5pt 3pt;
    font-size: 7.5pt;
    vertical-align: top;
  }
  .detail-table .lbl {
    font-weight: 700;
    color: #37474F;
    white-space: nowrap;
    width: 20%;
  }
  .detail-table .val {
    color: #212121;
    width: 30%;
  }

  /* ═══════════ PANCHANGA BOX ═══════════ */
  .panchang-box {
    border: 1pt solid #A5D6A7;
    border-radius: 3pt;
    padding: 3pt 8pt;
    margin-bottom: 3pt;
    background: #F1F8E9;
  }

  /* ═══════════ PLANET TABLE ═══════════ */
  .graha-table {
    width: 100%;
    border-collapse: collapse;
    border: 1pt solid #BDBDBD;
    border-radius: 3pt;
    overflow: hidden;
    margin-bottom: 3pt;
  }
  .graha-table thead th {
    background: #4A148C;
    color: #FFFFFF;
    font-size: 7pt;
    font-weight: 700;
    padding: 3pt 3pt;
    text-align: center;
    border-right: 1pt solid #6A1B9A;
  }
  .graha-table thead th:last-child { border-right: none; }
  .graha-table tbody td {
    font-size: 7pt;
    padding: 2pt 3pt;
    text-align: center;
    border-bottom: 0.5pt solid #E0E0E0;
  }
  .graha-table tbody tr:nth-child(even) { background: #F5F0E8; }
  .graha-table tbody tr:nth-child(odd) { background: #FFFFFF; }
  .graha-table tbody td:first-child {
    font-weight: 700;
    text-align: left;
    padding-left: 8pt;
    color: #2E1A47;
  }

  /* ═══════════ KUNDALI CHARTS ═══════════ */
  .charts-container {
    display: flex;
    justify-content: space-between;
    gap: 4pt;
    margin-top: 3pt;
  }
  .chart-block {
    flex: 1;
    text-align: center;
  }
  .chart-label {
    font-size: 7pt;
    font-weight: 700;
    color: #2E1A47;
    margin-top: 1pt;
  }
  .kundali-grid {
    width: 100%;
    border-collapse: collapse;
    border: 1.5pt solid #333;
  }
  .kundali-grid td {
    border: 0.7pt solid #666;
    width: 25%;
    height: 38pt;
    font-size: 7pt;
    font-weight: 700;
    color: #1A1A1A;
    text-align: center;
    vertical-align: middle;
    padding: 1pt;
  }
  .kundali-grid .center {
    background: #F5F0E8;
    font-size: 10pt;
    font-weight: 900;
    color: #2E1A47;
    border: 1pt solid #444;
  }
  .shri {
    color: #C62828;
    font-weight: 700;
    font-size: 6.5pt;
  }

  /* ═══════════ DASHA TABLES ═══════════ */
  .dasha-table {
    width: 100%;
    border-collapse: collapse;
    border: 1pt solid #BDBDBD;
    margin-bottom: 5pt;
  }
  .dasha-table thead th {
    background: #4A148C;
    color: #FFFFFF;
    font-size: 8pt;
    font-weight: 700;
    padding: 5pt 4pt;
    text-align: center;
    border-right: 1pt solid #6A1B9A;
  }
  .dasha-table thead th:last-child { border-right: none; }
  .dasha-table tbody td {
    font-size: 8pt;
    padding: 4pt;
    text-align: center;
    border-bottom: 0.5pt solid #E0E0E0;
  }
  .dasha-table tbody tr:nth-child(even) { background: #E8EAF6; }
  .dasha-table tbody tr:nth-child(odd) { background: #FFFFFF; }
  .dasha-table tbody td:nth-child(2) { font-weight: 700; color: #2E1A47; }

  .dasha-balance {
    text-align: center;
    font-size: 9pt;
    font-weight: 700;
    color: #C62828;
    margin: 5pt 0;
    padding: 3pt;
    background: #FFF8E1;
    border: 1pt solid #FFD54F;
    border-radius: 3pt;
  }

  /* ═══════════ FOOTER ═══════════ */
  .footer {
    border-top: 1pt solid #BDBDBD;
    padding-top: 3pt;
    margin-top: 4pt;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    font-size: 7.5pt;
  }
  .footer-left { text-align: left; }
  .footer-center { text-align: center; color: #9E9E9E; flex: 1; }
  .footer-right { text-align: right; }
  .footer-bold { font-weight: 700; color: #2E1A47; }
  .footer-sub { font-size: 6.5pt; color: #9E9E9E; }

  .page-break { page-break-before: always; }
  .header-p2 .main-title { font-size: 16pt; }
  .person-info {
    font-size: 9pt;
    font-weight: 700;
    color: #37474F;
    margin-top: 2pt;
  }
</style>
</head>
<body>

<div class="header">
  <div class="invocation">ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ ।। ಶ್ರೀ ಗುರುಭ್ಯೋ ನಮಃ ।।</div>
  <div class="main-title">ಜನ್ಮ ಪತ್ರಿಕೆ</div>
  <div class="branding">ಭಾರತೀಯಂ ಜ್ಯೋತಿಷ ಅಪ್ಲಿಕೇಶನ್</div>
</div>

<div class="detail-box">
  <table class="detail-table">
    <tr>
      <td class="lbl">ಜಾತಕರ ಹೆಸರು:</td><td class="val">{{JATAKAR_NAME}}</td>
      <td class="lbl">ಜನ್ಮ ಊರು:</td><td class="val">{{JANMA_OORU}}</td>
    </tr>
    <tr>
      <td class="lbl">ಜನನ ದಿನಾಂಕ:</td><td class="val">{{JANMA_DATE}}</td>
      <td class="lbl">ಜನ್ಮ ಸಮಯ:</td><td class="val">{{JANMA_TIME}}</td>
    </tr>
    <tr>
      <td class="lbl">ತಂದೆ ಹೆಸರು:</td><td class="val">{{FATHER_NAME}}</td>
      <td class="lbl">ತಾಯಿ ಹೆಸರು:</td><td class="val">{{MOTHER_NAME}}</td>
    </tr>
    <tr>
      <td class="lbl">ಗೋತ್ರ:</td><td class="val">{{GOTRA}}</td>
      <td class="lbl">ಲಗ್ನ ರಾಶಿ:</td><td class="val">{{LAGNA_RASHI}}</td>
    </tr>
  </table>
</div>

<div class="section-title">ಪಂಚಾಂಗ ವಿವರ</div>
<div class="panchang-box">
  <table class="detail-table">
    <tr>
      <td class="lbl">ಸಂವತ್ಸರ:</td><td class="val">{{SAMVATSARA}}</td>
      <td class="lbl">ಚಂದ್ರ ಮಾಸ:</td><td class="val">{{CHANDRA_MASA}}</td>
    </tr>
    <tr>
      <td class="lbl">ರವಿ ಮಾಸ:</td><td class="val">{{RAVI_MASA}}</td>
      <td class="lbl">ಋತು:</td><td class="val">{{RUTU}}</td>
    </tr>
    <tr>
      <td class="lbl">ತಿಥಿ:</td><td class="val">{{TITHI}}</td>
      <td class="lbl">ವಾರ:</td><td class="val">{{VARA}}</td>
    </tr>
    <tr>
      <td class="lbl">ನಕ್ಷತ್ರ:</td><td class="val">{{NAKSHATRA}}</td>
      <td class="lbl">ಕರಣ:</td><td class="val">{{KARANA}}</td>
    </tr>
    <tr>
      <td class="lbl">ಯೋಗ:</td><td class="val">{{YOGA}}</td>
      <td class="lbl">ಚಂದ್ರ ರಾಶಿ:</td><td class="val">{{CHANDRA_RASHI}}</td>
    </tr>
    <tr>
      <td class="lbl">ಗತ ಘಟಿ:</td><td class="val">{{GATA_GHATI}}</td>
      <td class="lbl">ಪರಮ ಘಟಿ:</td><td class="val">{{PARAMA_GHATI}}</td>
    </tr>
    <tr>
      <td class="lbl">ಸೂರ್ಯೋದಯ:</td><td class="val">{{SUNRISE}}</td>
      <td class="lbl">ಸೂರ್ಯಾಸ್ತ:</td><td class="val">{{SUNSET}}</td>
    </tr>
  </table>
</div>

<div class="section-title">ತತ್ಕಾಲ ಗ್ರಹಸ್ಥಿತಿ</div>
<table class="graha-table">
  <thead>
    <tr>
      <th>ಗ್ರಹ</th><th>ರಾಶಿ</th><th>ಅಂಶ</th>
      <th>ನಕ್ಷತ್ರ</th><th>ಪಾದ</th><th>ವಕ್ರ/ಅಸ್ತ</th>
    </tr>
  </thead>
  <tbody>
    {{GRAHA_ROWS}}
  </tbody>
</table>

<div class="charts-container">
  <div class="chart-block">
    <table class="kundali-grid">
      {{RASHI_GRID}}
    </table>
    <div class="chart-label">ರಾಶಿ ಕುಂಡಲಿ</div>
  </div>
  <div class="chart-block">
    <table class="kundali-grid">
      {{NAVAMSHA_GRID}}
    </table>
    <div class="chart-label">ನವಾಂಶ ಕುಂಡಲಿ</div>
  </div>
  <div class="chart-block">
    <table class="kundali-grid">
      {{BHAVA_GRID}}
    </table>
    <div class="chart-label">ಭಾವ ಕುಂಡಲಿ</div>
  </div>
</div>

<div class="footer">
  <div class="footer-left">
    <div class="footer-bold">{{JYOTISHI_NAME}}</div>
  </div>
  <div class="footer-center">ಭಾರತೀಯಂ</div>
  <div class="footer-right">
    <div class="footer-bold">{{JYOTISHI_PHONE}}</div>
  </div>
</div>


<div class="page-break"></div>

<div class="header header-p2">
  <div class="invocation">ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ ।। ಶ್ರೀ ಗುರುಭ್ಯೋ ನಮಃ ।।</div>
  <div class="main-title">ಜನ್ಮ ಪತ್ರಿಕೆ — ದಶಾ ವಿವರ</div>
  <div class="person-info">{{JATAKAR_NAME}} — {{JANMA_DATE}}</div>
</div>

<div class="section-title">ನಕ್ಷತ್ರ ಮತ್ತು ದಶಾ ವಿವರ</div>
<div class="detail-box">
  <table class="detail-table">
    <tr>
      <td class="lbl">ಜನ್ಮ ನಕ್ಷತ್ರ:</td><td class="val">{{NAKSHATRA}}</td>
      <td class="lbl">ಚಂದ್ರ ರಾಶಿ:</td><td class="val">{{CHANDRA_RASHI}}</td>
    </tr>
    <tr>
      <td class="lbl">ನಕ್ಷತ್ರ ಪರಮ ಘಟಿ:</td><td class="val">{{PARAMA_GHATI}}</td>
      <td class="lbl">ಗತ ಘಟಿ:</td><td class="val">{{GATA_GHATI}}</td>
    </tr>
    <tr>
      <td class="lbl">ಶಿಷ್ಟ ದಶಾ ನಾಥ:</td><td class="val">{{REMAINING_DASHA_LORD}}</td>
      <td class="lbl">ಶಿಷ್ಟ ದಶಾ ಶೇಷ:</td><td class="val">{{REMAINING_DASHA_GOTS}}</td>
    </tr>
  </table>
</div>

<div class="section-title">ವಿಂಶೋತ್ತರೀ ಮಹಾ ದಶಾ</div>
<table class="dasha-table">
  <thead>
    <tr>
      <th>ಕ್ರ.</th>
      <th>ದಶಾ ನಾಥ</th>
      <th>ವರ್ಷ</th>
      <th>ಆರಂಭ ದಿನಾಂಕ</th>
      <th>ಅಂತ್ಯ ದಿನಾಂಕ</th>
    </tr>
  </thead>
  <tbody>
    {{DASHA_ROWS}}
  </tbody>
</table>

<div class="dasha-balance">ಶಿಷ್ಟ ದಶೆ: {{REMAINING_DASHA_LORD}} — ಶೇಷ: {{REMAINING_DASHA_GOTS}}</div>

<div class="footer">
  <div class="footer-left">
    <div class="footer-bold">{{JYOTISHI_NAME}}</div>
  </div>
  <div class="footer-center">ಭಾರತೀಯಂ</div>
  <div class="footer-right">
    <div class="footer-bold">{{JYOTISHI_PHONE}}</div>
  </div>
</div>

<script>
  // Simple script to inject actual chart names when dynamically parsing the HTML 
  // since `{{CHART_NAME}}` inside {{RASHI_GRID}} is generated.
  document.body.innerHTML = document.body.innerHTML.replace('{{CHART_NAME}}', 'ರಾಶಿ').replace('{{CHART_NAME}}', 'ನವಾಂಶ').replace('{{CHART_NAME}}', 'ಭಾವ');
</script>

</body>
</html>
''';
}
