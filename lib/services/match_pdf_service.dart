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
import '../widgets/kundali_chart.dart';

/// Data container for Match Making PDF
class MatchPdfData {
  final String groomName, groomDob, groomTime, groomPlace;
  final String brideName, brideDob, brideTime, bridePlace;
  final KundaliResult groomResult, brideResult;
  final Map<String, dynamic> fullResult;
  final int kootaMode; // 0=Ashta, 1=Dvadasha
  final String invocationText;
  final String astrologerName, astrologerAddress, astrologerPhone;

  MatchPdfData({
    required this.groomName, required this.groomDob, required this.groomTime, required this.groomPlace,
    required this.brideName, required this.brideDob, required this.brideTime, required this.bridePlace,
    required this.groomResult, required this.brideResult,
    required this.fullResult,
    this.kootaMode = 0,
    this.invocationText = 'ಶ್ರೀ ಗಣೇಶಾಯ ನಮಃ',
    this.astrologerName = '', this.astrologerAddress = '', this.astrologerPhone = '',
  });
}

class MatchPdfService {
  static String _fontForLocale() {
    switch (AppLocale.current) {
      case 'hi': return 'NotoSansDevanagari';
      case 'ta': return 'NotoSansTamil';
      case 'te': return 'NotoSansTelugu';
      case 'ml': return 'NotoSansMalayalam';
      default: return 'NotoSansKannada';
    }
  }

  static const double _pw = 793.0;
  static const double _ph = 1122.0;

  static Future<Uint8List> _generatePdfBytes(MatchPdfData d, {PdfThemeConfig? theme}) async {
    theme ??= PdfThemes.traditional;
    final controller = ScreenshotController();
    final targetSize = const Size(_pw, _ph);

    final doc = pw.Document();

    // Page 1: Header + Birth Details + Charts
    final p1 = _wrap(theme, _buildPage1(d, theme));
    final p1b = await controller.captureFromWidget(p1, targetSize: targetSize, pixelRatio: 2.5, delay: const Duration(milliseconds: 10));
    _addPage(doc, p1b);

    // Page 2: Koota Table + Kuja Dosha + Papa Dosha
    final p2 = _wrap(theme, _buildPage2(d, theme));
    final p2b = await controller.captureFromWidget(p2, targetSize: targetSize, pixelRatio: 2.5, delay: const Duration(milliseconds: 10));
    _addPage(doc, p2b);

    // Page 3: Graha Maitri + Dasha Sandhi + Shashta/Dvirdvadasha
    final p3 = _wrap(theme, _buildPage3(d, theme));
    final p3b = await controller.captureFromWidget(p3, targetSize: targetSize, pixelRatio: 2.5, delay: const Duration(milliseconds: 10));
    _addPage(doc, p3b);

    return doc.save();
  }

  static Future<void> generateAndPrint(MatchPdfData d, {PdfThemeConfig? theme}) async {
    final bytes = await _generatePdfBytes(d, theme: theme);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${d.groomName}_${d.brideName}_match',
    );
  }

  static Future<void> generateAndShare(MatchPdfData d, {PdfThemeConfig? theme}) async {
    final bytes = await _generatePdfBytes(d, theme: theme);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${d.groomName}_${d.brideName}_match.pdf',
    );
  }

  static void _addPage(pw.Document doc, Uint8List bytes) {
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (pw.Context c) => pw.FullPage(ignoreMargins: true, child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)),
    ));
  }

  static Widget _wrap(PdfThemeConfig theme, Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(data: const MediaQueryData(), child: Theme(
        data: ThemeData(fontFamily: _fontForLocale()),
        child: DefaultTextStyle(
          style: TextStyle(color: Colors.black, fontSize: 13, fontFamily: _fontForLocale()),
          child: Material(color: Colors.white, child: theme.buildPageBorder(width: _pw, height: _ph, child: child)),
        ),
      )),
    );
  }

  // ═══════════════ PAGE 1: Header + Birth Details + Charts ═══════════════
  static Widget _buildPage1(MatchPdfData d, PdfThemeConfig t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        children: [
          _buildHeader(d, t),
          const SizedBox(height: 10),
          _divider(t),
          const SizedBox(height: 8),
          // Birth details side by side
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _birthCard('${AppLocale.l('groom')} (Groom)', d.groomName, d.groomDob, d.groomTime, d.groomPlace, d.groomResult, t, Colors.blue.shade700)),
              const SizedBox(width: 12),
              Expanded(child: _birthCard('${AppLocale.l('bride')} (Bride)', d.brideName, d.brideDob, d.brideTime, d.bridePlace, d.brideResult, t, Colors.pink.shade700)),
            ],
          ),
          const SizedBox(height: 10),
          _sectionTitle(AppLocale.l('kundaliLabel'), t),
          const SizedBox(height: 6),
          // Charts: 3 columns x 2 rows (groom top, bride bottom)
          Row(
            children: [
              Expanded(child: _chartBox(d.groomResult, 1, false, AppLocale.l('rashi'), t)),
              const SizedBox(width: 6),
              Expanded(child: _chartBox(d.groomResult, 9, false, AppLocale.l('navamsha'), t)),
              const SizedBox(width: 6),
              Expanded(child: _chartBox(d.groomResult, 1, true, AppLocale.l('bhavaLabel'), t)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _chartBox(d.brideResult, 1, false, AppLocale.l('rashi'), t)),
              const SizedBox(width: 6),
              Expanded(child: _chartBox(d.brideResult, 9, false, AppLocale.l('navamsha'), t)),
              const SizedBox(width: 6),
              Expanded(child: _chartBox(d.brideResult, 1, true, AppLocale.l('bhavaLabel'), t)),
            ],
          ),
          const Spacer(),
          _footer(d, t),
        ],
      ),
    );
  }

  // ═══════════════ PAGE 2: Koota + Kuja + Papa ═══════════════
  static Widget _buildPage2(MatchPdfData d, PdfThemeConfig t) {
    final fr = d.fullResult;
    final isAshta = d.kootaMode == 0;
    final koota = isAshta ? fr['ashtaKoota'] as Map<String, dynamic> : fr['dvadashaKoota'] as Map<String, dynamic>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _miniHeader(d, t),
          const SizedBox(height: 8),
          _sectionTitle(isAshta ? '${AppLocale.l('ashtaKoota')} ${AppLocale.l('milan')} (36)' : '${AppLocale.l('dvadashaKoota')} ${AppLocale.l('milan')} (40)', t),
          const SizedBox(height: 6),
          _buildKootaTable(koota, isAshta, t),
          const SizedBox(height: 14),
          _sectionTitle(AppLocale.l('kujaDosha'), t),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildDoshaCard(AppLocale.l('groom'), fr['groomKujaDosha'] as Map<String, dynamic>, t, Colors.blue.shade700)),
              const SizedBox(width: 10),
              Expanded(child: _buildDoshaCard(AppLocale.l('bride'), fr['brideKujaDosha'] as Map<String, dynamic>, t, Colors.pink.shade700)),
            ],
          ),
          const SizedBox(height: 14),
          _sectionTitle(AppLocale.l('papaDosha'), t),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildPapaCard(AppLocale.l('groom'), fr['groomPapaDosha'] as Map<String, dynamic>, t, Colors.blue.shade700)),
              const SizedBox(width: 10),
              Expanded(child: _buildPapaCard(AppLocale.l('bride'), fr['bridePapaDosha'] as Map<String, dynamic>, t, Colors.pink.shade700)),
            ],
          ),
          const SizedBox(height: 8),
          if (fr['papaSamya'] != null) _buildPapaSamya(fr['papaSamya'] as Map<String, dynamic>, t),
          const Spacer(),
          _footer(d, t),
        ],
      ),
    );
  }

  // ═══════════════ PAGE 3: Graha Maitri + Dasha Sandhi + Shashta/Dvird ═══════════════
  static Widget _buildPage3(MatchPdfData d, PdfThemeConfig t) {
    final fr = d.fullResult;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _miniHeader(d, t),
          const SizedBox(height: 8),
          _sectionTitle(AppLocale.l('grahaMaitriAmsha'), t),
          const SizedBox(height: 6),
          if (fr['grahaMaitri'] != null) _buildGrahaMaitriTable(fr['grahaMaitri'] as Map<String, dynamic>, t),
          const SizedBox(height: 14),
          _sectionTitle(AppLocale.l('dashaSandhi'), t),
          const SizedBox(height: 6),
          _buildDashaSandhi(d, t),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(AppLocale.l('shathaAshtaka'), t),
                  const SizedBox(height: 6),
                  if (fr['shathaAshtaka'] != null) _buildRelationCard(fr['shathaAshtaka'] as Map<String, dynamic>, '6/8', t),
                ],
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle(AppLocale.l('dvirdvadasha'), t),
                  const SizedBox(height: 6),
                  if (fr['dvirdvadasha'] != null) _buildRelationCard(fr['dvirdvadasha'] as Map<String, dynamic>, '2/12', t),
                ],
              )),
            ],
          ),
          const Spacer(),
          _footer(d, t),
        ],
      ),
    );
  }

  // ═══════════════ HEADER WIDGETS ═══════════════

  static Widget _buildHeader(MatchPdfData d, PdfThemeConfig t) {
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Astrologer info (left)
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.astrologerName.isNotEmpty) Text(d.astrologerName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.primaryDark)),
              if (d.astrologerAddress.isNotEmpty) Text(d.astrologerAddress, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
              if (d.astrologerPhone.isNotEmpty) Text('📞 ${d.astrologerPhone}', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
            ],
          )),
          // Center: Logo + Invocation + Title
          Expanded(flex: 4, child: Column(children: [
            Image.asset('assets/images/logo.png', width: 48, height: 48),
            const SizedBox(height: 3),
            Text(d.invocationText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.shlokaText)),
            Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: t.primaryDark)),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: t.headerBg.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: t.primaryDark.withOpacity(0.2))),
              child: Text(AppLocale.l('matchTitle'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: t.primaryDark)),
            ),
          ])),
          // Date (right)
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppLocale.l('dinanka'), style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text(_todayStr(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: t.primaryDark)),
            ],
          )),
        ],
      ),
    ]);
  }

  static Widget _miniHeader(MatchPdfData d, PdfThemeConfig t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logo.png', width: 28, height: 28),
        const SizedBox(width: 8),
        Text(AppLocale.l('matchTitle'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: t.primaryDark)),
        const SizedBox(width: 8),
        Text('${d.groomName} ✕ ${d.brideName}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  // ═══════════════ BIRTH CARD ═══════════════

  static Widget _birthCard(String label, String name, String dob, String time, String place, KundaliResult r, PdfThemeConfig t, Color accent) {
    final p = r.panchang;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent)),
          Text('📅 $dob  🕰️ $time', style: const TextStyle(fontSize: 10)),
          Text('📍 $place', style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 4),
          Text('${AppLocale.l('rashi')}: ${trAll(p.chandraRashi)}  |  ${AppLocale.l('nakshatra')}: ${trAll(p.nakshatra)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }

  // ═══════════════ CHART BOX ═══════════════

  static Widget _chartBox(KundaliResult r, int varga, bool isBhava, String label, PdfThemeConfig t) {
    return Column(children: [
      SizedBox(
        width: 220, height: 220,
        child: KundaliChart(result: r, varga: varga, isBhava: isBhava, showSphutas: false, forceShortNames: true),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: t.primaryDark)),
    ]);
  }

  // ═══════════════ KOOTA TABLE ═══════════════

  static Widget _buildKootaTable(Map<String, dynamic> koota, bool isAshta, PdfThemeConfig t) {
    final items = <List<String>>[];
    final maxPts = <double>[];
    if (isAshta) {
      for (final e in [[trAll('ವರ್ಣ'), 'varna', 1], [trAll('ವಶ್ಯ'), 'vashya', 2], [trAll('ತಾರಾ'), 'tara', 3], [trAll('ಯೋನಿ'), 'yoni', 4], [trAll('ಗ್ರಹ ಮೈತ್ರಿ'), 'graha', 5], [trAll('ಗಣ'), 'gana', 6], [trAll('ಭಕೂಟ'), 'bhakoot', 7], [trAll('ನಾಡಿ'), 'nadi', 8]]) {
        final k = e[1] as String;
        final mx = (e[2] as int).toDouble();
        final v = (koota[k] as num?)?.toDouble() ?? 0;
        items.add([e[0] as String, mx.toStringAsFixed(0), v.toStringAsFixed(1)]);
        maxPts.add(mx);
      }
    } else {
      for (final e in [[trAll('ವರ್ಣ'), 'varna', 1], [trAll('ವಶ್ಯ'), 'vashya', 2], [trAll('ತಾರಾ'), 'tara', 3], [trAll('ಯೋನಿ'), 'yoni', 4], [trAll('ಗ್ರಹ ಮೈತ್ರಿ'), 'graha', 5], [trAll('ಗಣ'), 'gana', 6], [trAll('ಭಕೂಟ'), 'bhakoot', 7], [trAll('ನಾಡಿ'), 'nadi', 8], [trAll('ಮಹೇಂದ್ರ'), 'mahendra', 1], [trAll('ಸ್ತ್ರೀ ದೀರ್ಘ'), 'streeDeergha', 1], [trAll('ರಜ್ಜು'), 'rajju', 1], [trAll('ವೇಧ'), 'vedha', 1]]) {
        final k = e[1] as String;
        final mx = (e[2] as int).toDouble();
        final v = (koota[k] as num?)?.toDouble() ?? 0;
        items.add([e[0] as String, mx.toStringAsFixed(0), v.toStringAsFixed(1)]);
        maxPts.add(mx);
      }
    }
    final total = (koota['total'] as num?)?.toDouble() ?? 0;
    final maxTotal = isAshta ? 36.0 : 40.0;

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: t.detailBorder.withOpacity(0.3))),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: t.tableHeaderBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(7))),
          child: Row(children: [
            Expanded(flex: 3, child: Text(AppLocale.l('koota'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.tableHeaderText))),
            Expanded(flex: 2, child: Text(AppLocale.l('garishtha'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.tableHeaderText), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(AppLocale.l('padeda'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.tableHeaderText), textAlign: TextAlign.center)),
          ]),
        ),
        // Rows
        for (int i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: i % 2 == 0 ? Colors.white : t.tableAltRow,
            child: Row(children: [
              Expanded(flex: 3, child: Text(items[i][0], style: const TextStyle(fontSize: 11))),
              Expanded(flex: 2, child: Text(items[i][1], style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text(items[i][2], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: double.parse(items[i][2]) > 0 ? Colors.green.shade700 : Colors.red.shade600), textAlign: TextAlign.center)),
            ]),
          ),
        // Total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: t.headerBg.withOpacity(0.1), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7))),
          child: Row(children: [
            Expanded(flex: 3, child: Text(AppLocale.l('ottu'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: t.primaryDark))),
            Expanded(flex: 2, child: Text(maxTotal.toStringAsFixed(0), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: t.primaryDark), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(total.toStringAsFixed(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: total >= maxTotal * 0.5 ? Colors.green.shade700 : Colors.red.shade600), textAlign: TextAlign.center)),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════ DOSHA CARDS ═══════════════

  static Widget _buildDoshaCard(String label, Map<String, dynamic> dosha, PdfThemeConfig t, Color accent) {
    final hasDosha = dosha['hasDosha'] == true;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasDosha ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasDosha ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(hasDosha ? Icons.warning_amber : Icons.check_circle, size: 16, color: hasDosha ? Colors.red : Colors.green),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
          const Spacer(),
          Text(hasDosha ? AppLocale.l('doshaPresent') : AppLocale.l('doshaAbsent'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: hasDosha ? Colors.red : Colors.green)),
        ]),
        const SizedBox(height: 6),
        _doshaRow(AppLocale.l('fromLagna'), dosha['fromLagna']),
        _doshaRow(AppLocale.l('fromChandra'), dosha['fromChandra']),
        _doshaRow(AppLocale.l('fromShukra'), dosha['fromShukra']),
      ]),
    );
  }

  static Widget _doshaRow(String label, dynamic value) {
    final v = value is int ? value : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const Spacer(),
        Text(v > 0 ? '${AppLocale.l('bhavaLabel')} $v ✗' : '✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: v > 0 ? Colors.red : Colors.green)),
      ]),
    );
  }

  static Widget _buildPapaCard(String label, Map<String, dynamic> papa, PdfThemeConfig t, Color accent) {
    final total = papa['total'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: t.detailBoxBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: t.detailBorder.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent)),
        const SizedBox(height: 4),
        _papaRow(AppLocale.l('fromLagna'), papa['fromLagna']),
        _papaRow(AppLocale.l('fromChandra'), papa['fromChandra']),
        _papaRow(AppLocale.l('fromShukra'), papa['fromShukra']),
        const Divider(height: 8),
        Row(children: [
          Text(AppLocale.l('ottu'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: total > 0 ? Colors.orange.shade800 : Colors.green)),
        ]),
      ]),
    );
  }

  static Widget _papaRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const Spacer(),
        Text('${value ?? 0}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  static Widget _buildPapaSamya(Map<String, dynamic> samya, PdfThemeConfig t) {
    final isSamya = samya['isSamya'] == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSamya ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSamya ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(isSamya ? Icons.check_circle : Icons.info_outline, size: 16, color: isSamya ? Colors.green : Colors.orange),
        const SizedBox(width: 8),
        Text('${AppLocale.l('papaSamya')}: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: t.primaryDark)),
        Text('${AppLocale.l('groom')} ${samya['groomPapaTotal']} | ${AppLocale.l('bride')} ${samya['bridePapaTotal']} | ${AppLocale.l('vyatyasa')} ${samya['difference']}',
            style: TextStyle(fontSize: 11, color: isSamya ? Colors.green.shade700 : Colors.orange.shade700)),
        const Spacer(),
        Text(isSamya ? AppLocale.l('samyaV') : AppLocale.l('asamyaX'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSamya ? Colors.green : Colors.orange)),
      ]),
    );
  }

  // ═══════════════ GRAHA MAITRI TABLE ═══════════════

  static Widget _buildGrahaMaitriTable(Map<String, dynamic> gm, PdfThemeConfig t) {
    final rows = gm['rows'] as List<dynamic>? ?? [];
    if (rows.isEmpty) return Text(AppLocale.l('dataNotAvail'), style: TextStyle(fontSize: 11, color: Colors.grey));

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: t.detailBorder.withOpacity(0.3))),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: t.tableHeaderBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(7))),
          child: Row(children: [
            Expanded(flex: 3, child: Text(AppLocale.l('vivara'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.tableHeaderText))),
            Expanded(flex: 2, child: Text(AppLocale.l('groom'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.tableHeaderText), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(AppLocale.l('bride'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.tableHeaderText), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text(AppLocale.l('sambandha'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: t.tableHeaderText), textAlign: TextAlign.center)),
          ]),
        ),
        for (int i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: i % 2 == 0 ? Colors.white : t.tableAltRow,
            child: Row(children: [
              Expanded(flex: 3, child: Text('${rows[i]['label'] ?? ''}', style: const TextStyle(fontSize: 10))),
              Expanded(flex: 2, child: Text('${rows[i]['groomLordName'] ?? ''}', style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('${rows[i]['brideLordName'] ?? ''}', style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text('${rows[i]['maitri'] ?? ''}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: rows[i]['relation'] == 1 ? Colors.green : rows[i]['relation'] == -1 ? Colors.red : Colors.orange),
                  textAlign: TextAlign.center)),
            ]),
          ),
      ]),
    );
  }

  // ═══════════════ DASHA SANDHI ═══════════════

  static Widget _buildDashaSandhi(MatchPdfData d, PdfThemeConfig t) {
    final br = d.brideResult;
    final gr = d.groomResult;
    final now = DateTime.now();

    // Find Mahadasha sandhi matches
    final bDashas = br.dashas.where((dd) => dd.end.isAfter(now)).toList();
    final gDashas = gr.dashas.where((dd) => dd.end.isAfter(now)).toList();
    final matches = <Map<String, dynamic>>[];

    for (final bd in bDashas) {
      for (final gd in gDashas) {
        final diff = (bd.end.difference(gd.end)).abs();
        if (diff <= const Duration(days: 183)) {
          matches.add({'brideLord': bd.lord, 'brideEnd': bd.end, 'groomLord': gd.lord, 'groomEnd': gd.end});
        }
      }
    }

    if (matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Text(AppLocale.l('dashaSandhiNilV'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green.shade700)),
        ]),
      );
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(7))),
          child: Row(children: [
            Icon(Icons.warning_amber, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(AppLocale.l('dashaSandhiFound'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.orange.shade800)),
          ]),
        ),
        for (int i = 0; i < matches.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: i % 2 == 0 ? Colors.white : Colors.orange.shade50.withOpacity(0.3),
            child: Row(children: [
              Expanded(child: Text('${AppLocale.l('groom')}: ${trAll(matches[i]['groomLord'])} → ${_fmtDate(matches[i]['groomEnd'])}', style: const TextStyle(fontSize: 10))),
              Expanded(child: Text('${AppLocale.l('bride')}: ${trAll(matches[i]['brideLord'])} → ${_fmtDate(matches[i]['brideEnd'])}', style: const TextStyle(fontSize: 10))),
            ]),
          ),
      ]),
    );
  }

  // ═══════════════ SHASHTA-ASHTAKA / DVIRDVADASHA ═══════════════

  static Widget _buildRelationCard(Map<String, dynamic> data, String type, PdfThemeConfig t) {
    final hasDosha = data['hasDosha'] == true;
    final fromChandra = data['fromChandra'] as Map<String, dynamic>?;
    final fromLagna = data['fromLagna'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasDosha ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasDosha ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(hasDosha ? Icons.warning_amber : Icons.check_circle, size: 14, color: hasDosha ? Colors.red : Colors.green),
          const SizedBox(width: 4),
          Text(hasDosha ? '$type ${AppLocale.l('doshaX')}' : '$type ${AppLocale.l('doshaIllaV')}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: hasDosha ? Colors.red : Colors.green)),
        ]),
        if (fromChandra != null && fromChandra['hasDosha'] == true) ...[
          const SizedBox(height: 4),
          Text('${trAll('ಚಂದ್ರ')}: ${AppLocale.l('groom')}→${AppLocale.l('bride')} ${fromChandra['brideFromGroom']} | ${AppLocale.l('bride')}→${AppLocale.l('groom')} ${fromChandra['groomFromBride']}', style: const TextStyle(fontSize: 10)),
        ],
        if (fromLagna != null && fromLagna['hasDosha'] == true) ...[
          const SizedBox(height: 2),
          Text('${trAll('ಲಗ್ನ')}: ${AppLocale.l('groom')}→${AppLocale.l('bride')} ${fromLagna['brideFromGroom']} | ${AppLocale.l('bride')}→${AppLocale.l('groom')} ${fromLagna['groomFromBride']}', style: const TextStyle(fontSize: 10)),
        ],
      ]),
    );
  }

  // ═══════════════ COMMON HELPERS ═══════════════

  static Widget _sectionTitle(String title, PdfThemeConfig t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: t.sectionTitleBg.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border(left: BorderSide(color: t.primaryDark, width: 3))),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: t.sectionTitleText)),
    );
  }

  static Widget _divider(PdfThemeConfig t) {
    return Row(children: [
      Expanded(child: Divider(color: t.primaryDark.withOpacity(0.15))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.auto_awesome, size: 10, color: t.primaryDark.withOpacity(0.3))),
      Expanded(child: Divider(color: t.primaryDark.withOpacity(0.15))),
    ]);
  }

  static Widget _footer(MatchPdfData d, PdfThemeConfig t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: t.primaryDark.withOpacity(0.2)))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        if (d.astrologerName.isNotEmpty) Text(d.astrologerName, style: TextStyle(fontSize: 9, color: t.footerText, fontWeight: FontWeight.w600)),
        Text(trAll(AppLocale.l('appName')), style: TextStyle(fontSize: 9, color: t.footerText)),
        if (d.astrologerPhone.isNotEmpty) Text('📞 ${d.astrologerPhone}', style: TextStyle(fontSize: 9, color: t.footerText)),
      ]),
    );
  }

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}-${n.month.toString().padLeft(2, '0')}-${n.year}';
  }

  static String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
