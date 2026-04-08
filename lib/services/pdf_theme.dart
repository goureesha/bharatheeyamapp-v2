import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme configuration for Janma Patrike PDF generation
class PdfThemeConfig {
  final String id;
  final String nameKn;   // Kannada name
  final String nameEn;   // English name
  final IconData icon;

  // Core colors
  final Color primaryDark;     // Header bg, chart outline
  final Color primaryLight;    // Section title text, accents
  final Color headerBg;        // Header container background
  final Color headerText;      // Main title text
  final Color sectionTitleBg;  // Section title underline
  final Color sectionTitleText;
  final Color tableHeaderBg;   // Table header row
  final Color tableHeaderText;
  final Color tableAltRow;     // Alternate row color
  final Color pageBg;          // Page background
  final Color detailBoxBg;     // Detail box background
  final Color detailBorder;
  final Color shlokaText;      // Shloka/invocation text
  final Color footerText;
  final Color chartCenterBg;   // Chart center box
  final Color chartCenterText;
  final Color chartBorder;     // Chart grid lines
  final Color dashaHighlight;  // Shishta dasha highlight box bg
  final Color dashaHighlightBorder;
  final Color dashaHighlightText;
  final Color dashaAltRow;     // Dasha table alternate row

  // Border configuration
  final Color borderColor1;    // Outer border
  final Color borderColor2;    // Inner border / accent
  final double borderWidth1;
  final double borderWidth2;
  final double borderInset;    // Gap between outer and inner border
  final bool hasCornerOrnaments;
  final Color cornerColor;

  const PdfThemeConfig({
    required this.id,
    required this.nameKn,
    required this.nameEn,
    required this.icon,
    required this.primaryDark,
    required this.primaryLight,
    required this.headerBg,
    required this.headerText,
    required this.sectionTitleBg,
    required this.sectionTitleText,
    required this.tableHeaderBg,
    required this.tableHeaderText,
    required this.tableAltRow,
    required this.pageBg,
    required this.detailBoxBg,
    required this.detailBorder,
    required this.shlokaText,
    required this.footerText,
    required this.chartCenterBg,
    required this.chartCenterText,
    required this.chartBorder,
    required this.dashaHighlight,
    required this.dashaHighlightBorder,
    required this.dashaHighlightText,
    required this.dashaAltRow,
    required this.borderColor1,
    required this.borderColor2,
    required this.borderWidth1,
    required this.borderWidth2,
    required this.borderInset,
    required this.hasCornerOrnaments,
    required this.cornerColor,
  });

  /// Build the decorative page border widget
  Widget buildPageBorder({required double width, required double height, required Widget child}) {
    return Container(
      width: width,
      height: height,
      color: pageBg,
      child: Stack(
        children: [
          // Outer border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor1, width: borderWidth1),
              ),
            ),
          ),
          // Inner border
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(8 + borderInset),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor2, width: borderWidth2),
              ),
            ),
          ),
          // Corner ornaments
          if (hasCornerOrnaments) ...[
            _cornerOrnament(Alignment.topLeft),
            _cornerOrnament(Alignment.topRight),
            _cornerOrnament(Alignment.bottomLeft),
            _cornerOrnament(Alignment.bottomRight),
          ],
          // Content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8 + borderInset + borderWidth2 + 14,
                horizontal: 8 + borderInset + borderWidth2 + 18,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerOrnament(Alignment align) {
    final double left = align == Alignment.topLeft || align == Alignment.bottomLeft ? 4 : double.nan;
    final double right = align == Alignment.topRight || align == Alignment.bottomRight ? 4 : double.nan;
    final double top = align == Alignment.topLeft || align == Alignment.topRight ? 4 : double.nan;
    final double bottom = align == Alignment.bottomLeft || align == Alignment.bottomRight ? 4 : double.nan;

    return Positioned(
      left: left.isNaN ? null : left,
      right: right.isNaN ? null : right,
      top: top.isNaN ? null : top,
      bottom: bottom.isNaN ? null : bottom,
      child: CustomPaint(
        size: const Size(28, 28),
        painter: _CornerPainter(color: cornerColor, alignment: align),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;

  _CornerPainter({required this.color, required this.alignment});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final s = size.width;

    if (alignment == Alignment.topLeft) {
      // Decorative L-shape with small diamond
      path.moveTo(0, 0);
      path.lineTo(s, 0);
      path.lineTo(s, s * 0.25);
      path.lineTo(s * 0.25, s * 0.25);
      path.lineTo(s * 0.25, s);
      path.lineTo(0, s);
      path.close();
      // Small diamond
      canvas.drawPath(path, paint);
      final diamond = Path();
      diamond.moveTo(s * 0.55, s * 0.55);
      diamond.lineTo(s * 0.7, s * 0.4);
      diamond.lineTo(s * 0.85, s * 0.55);
      diamond.lineTo(s * 0.7, s * 0.7);
      diamond.close();
      canvas.drawPath(diamond, paint);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(s, 0);
      path.lineTo(0, 0);
      path.lineTo(0, s * 0.25);
      path.lineTo(s * 0.75, s * 0.25);
      path.lineTo(s * 0.75, s);
      path.lineTo(s, s);
      path.close();
      canvas.drawPath(path, paint);
      final diamond = Path();
      diamond.moveTo(s * 0.45, s * 0.55);
      diamond.lineTo(s * 0.3, s * 0.4);
      diamond.lineTo(s * 0.15, s * 0.55);
      diamond.lineTo(s * 0.3, s * 0.7);
      diamond.close();
      canvas.drawPath(diamond, paint);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, s);
      path.lineTo(s, s);
      path.lineTo(s, s * 0.75);
      path.lineTo(s * 0.25, s * 0.75);
      path.lineTo(s * 0.25, 0);
      path.lineTo(0, 0);
      path.close();
      canvas.drawPath(path, paint);
      final diamond = Path();
      diamond.moveTo(s * 0.55, s * 0.45);
      diamond.lineTo(s * 0.7, s * 0.3);
      diamond.lineTo(s * 0.85, s * 0.45);
      diamond.lineTo(s * 0.7, s * 0.6);
      diamond.close();
      canvas.drawPath(diamond, paint);
    } else if (alignment == Alignment.bottomRight) {
      path.moveTo(s, s);
      path.lineTo(0, s);
      path.lineTo(0, s * 0.75);
      path.lineTo(s * 0.75, s * 0.75);
      path.lineTo(s * 0.75, 0);
      path.lineTo(s, 0);
      path.close();
      canvas.drawPath(path, paint);
      final diamond = Path();
      diamond.moveTo(s * 0.45, s * 0.45);
      diamond.lineTo(s * 0.3, s * 0.3);
      diamond.lineTo(s * 0.15, s * 0.45);
      diamond.lineTo(s * 0.3, s * 0.6);
      diamond.close();
      canvas.drawPath(diamond, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ════════════════════════════════════════════════════════════
// PREDEFINED THEMES
// ════════════════════════════════════════════════════════════

class PdfThemes {
  static const String _prefKey = 'pdf_theme_id';

  /// 1. ಸಾಂಪ್ರದಾಯಿಕ — Traditional (current default)
  static const traditional = PdfThemeConfig(
    id: 'traditional',
    nameKn: 'ಸಾಂಪ್ರದಾಯಿಕ',
    nameEn: 'Traditional',
    icon: Icons.temple_hindu,
    primaryDark: Color(0xFF2E1A47),
    primaryLight: Color(0xFF6A1B9A),
    headerBg: Color(0xFFF5F0E8),
    headerText: Color(0xFF2E1A47),
    sectionTitleBg: Color(0xFFE1BEE7),
    sectionTitleText: Color(0xFF6A1B9A),
    tableHeaderBg: Color(0xFF4A148C),
    tableHeaderText: Colors.white,
    tableAltRow: Color(0xFFF5F0E8),
    pageBg: Color(0xFFFFFFF8),
    detailBoxBg: Color(0xFFF9FBE7),
    detailBorder: Color(0xFFBDBDBD),
    shlokaText: Color(0xFFC62828),
    footerText: Color(0xFF2E1A47),
    chartCenterBg: Color(0xFFF5F0E8),
    chartCenterText: Color(0xFF2E1A47),
    chartBorder: Color(0xFF666666),
    dashaHighlight: Color(0xFFFFF8E1),
    dashaHighlightBorder: Color(0xFFFFD54F),
    dashaHighlightText: Color(0xFFC62828),
    dashaAltRow: Color(0xFFE8EAF6),
    borderColor1: Color(0xFF2E1A47),
    borderColor2: Color(0xFFD4A574),
    borderWidth1: 3.0,
    borderWidth2: 1.5,
    borderInset: 4.0,
    hasCornerOrnaments: true,
    cornerColor: Color(0xFF2E1A47),
  );

  /// 2. ಕೇಸರಿ — Saffron
  static const saffron = PdfThemeConfig(
    id: 'saffron',
    nameKn: 'ಕೇಸರಿ',
    nameEn: 'Saffron',
    icon: Icons.local_fire_department,
    primaryDark: Color(0xFF8B2500),
    primaryLight: Color(0xFFE65100),
    headerBg: Color(0xFFFFF3E0),
    headerText: Color(0xFF8B2500),
    sectionTitleBg: Color(0xFFFFCC80),
    sectionTitleText: Color(0xFFBF360C),
    tableHeaderBg: Color(0xFFE65100),
    tableHeaderText: Colors.white,
    tableAltRow: Color(0xFFFFF8E1),
    pageBg: Color(0xFFFFFDE7),
    detailBoxBg: Color(0xFFFFF3E0),
    detailBorder: Color(0xFFFFCC80),
    shlokaText: Color(0xFF8B2500),
    footerText: Color(0xFF8B2500),
    chartCenterBg: Color(0xFFFFF3E0),
    chartCenterText: Color(0xFF8B2500),
    chartBorder: Color(0xFFBF8040),
    dashaHighlight: Color(0xFFFFF8E1),
    dashaHighlightBorder: Color(0xFFFFB74D),
    dashaHighlightText: Color(0xFF8B2500),
    dashaAltRow: Color(0xFFFFF3E0),
    borderColor1: Color(0xFFE65100),
    borderColor2: Color(0xFFFFB74D),
    borderWidth1: 3.0,
    borderWidth2: 1.5,
    borderInset: 5.0,
    hasCornerOrnaments: true,
    cornerColor: Color(0xFFE65100),
  );

  /// 3. ನೀಲ — Royal Blue
  static const royalBlue = PdfThemeConfig(
    id: 'royal_blue',
    nameKn: 'ನೀಲ',
    nameEn: 'Royal Blue',
    icon: Icons.diamond,
    primaryDark: Color(0xFF0D1B3E),
    primaryLight: Color(0xFF1565C0),
    headerBg: Color(0xFFE8EAF6),
    headerText: Color(0xFF0D1B3E),
    sectionTitleBg: Color(0xFF90CAF9),
    sectionTitleText: Color(0xFF1565C0),
    tableHeaderBg: Color(0xFF1565C0),
    tableHeaderText: Colors.white,
    tableAltRow: Color(0xFFE3F2FD),
    pageBg: Color(0xFFF8F9FF),
    detailBoxBg: Color(0xFFE8EAF6),
    detailBorder: Color(0xFF90CAF9),
    shlokaText: Color(0xFFC62828),
    footerText: Color(0xFF0D1B3E),
    chartCenterBg: Color(0xFFE8EAF6),
    chartCenterText: Color(0xFF0D1B3E),
    chartBorder: Color(0xFF5C6BC0),
    dashaHighlight: Color(0xFFE3F2FD),
    dashaHighlightBorder: Color(0xFF64B5F6),
    dashaHighlightText: Color(0xFF0D47A1),
    dashaAltRow: Color(0xFFE8EAF6),
    borderColor1: Color(0xFF0D1B3E),
    borderColor2: Color(0xFF64B5F6),
    borderWidth1: 2.5,
    borderWidth2: 1.0,
    borderInset: 5.0,
    hasCornerOrnaments: true,
    cornerColor: Color(0xFF1565C0),
  );

  /// 4. ಹಸಿರು — Emerald
  static const emerald = PdfThemeConfig(
    id: 'emerald',
    nameKn: 'ಹಸಿರು',
    nameEn: 'Emerald',
    icon: Icons.eco,
    primaryDark: Color(0xFF1B3A20),
    primaryLight: Color(0xFF2E7D32),
    headerBg: Color(0xFFE8F5E9),
    headerText: Color(0xFF1B3A20),
    sectionTitleBg: Color(0xFFA5D6A7),
    sectionTitleText: Color(0xFF2E7D32),
    tableHeaderBg: Color(0xFF2E7D32),
    tableHeaderText: Colors.white,
    tableAltRow: Color(0xFFF1F8E9),
    pageBg: Color(0xFFF9FFF8),
    detailBoxBg: Color(0xFFE8F5E9),
    detailBorder: Color(0xFFA5D6A7),
    shlokaText: Color(0xFFC62828),
    footerText: Color(0xFF1B3A20),
    chartCenterBg: Color(0xFFE8F5E9),
    chartCenterText: Color(0xFF1B3A20),
    chartBorder: Color(0xFF4CAF50),
    dashaHighlight: Color(0xFFF1F8E9),
    dashaHighlightBorder: Color(0xFF81C784),
    dashaHighlightText: Color(0xFF1B5E20),
    dashaAltRow: Color(0xFFE8F5E9),
    borderColor1: Color(0xFF1B3A20),
    borderColor2: Color(0xFFC5A355),
    borderWidth1: 2.5,
    borderWidth2: 1.5,
    borderInset: 4.0,
    hasCornerOrnaments: true,
    cornerColor: Color(0xFF2E7D32),
  );

  /// 5. ಕಪ್ಪು-ಚಿನ್ನ — Black & Gold
  static const blackGold = PdfThemeConfig(
    id: 'black_gold',
    nameKn: 'ಕಪ್ಪು-ಚಿನ್ನ',
    nameEn: 'Black & Gold',
    icon: Icons.star,
    primaryDark: Color(0xFF1A1A1A),
    primaryLight: Color(0xFFD4A017),
    headerBg: Color(0xFF2A2A2A),
    headerText: Color(0xFFD4A017),
    sectionTitleBg: Color(0xFFD4A017),
    sectionTitleText: Color(0xFF1A1A1A),
    tableHeaderBg: Color(0xFF1A1A1A),
    tableHeaderText: Color(0xFFD4A017),
    tableAltRow: Color(0xFFF5F0E0),
    pageBg: Color(0xFFFFFFF0),
    detailBoxBg: Color(0xFFF5F0E0),
    detailBorder: Color(0xFFD4A017),
    shlokaText: Color(0xFFB71C1C),
    footerText: Color(0xFF1A1A1A),
    chartCenterBg: Color(0xFFF5F0E0),
    chartCenterText: Color(0xFF1A1A1A),
    chartBorder: Color(0xFF555555),
    dashaHighlight: Color(0xFFFFF8E1),
    dashaHighlightBorder: Color(0xFFD4A017),
    dashaHighlightText: Color(0xFF1A1A1A),
    dashaAltRow: Color(0xFFF5F0E0),
    borderColor1: Color(0xFF1A1A1A),
    borderColor2: Color(0xFFD4A017),
    borderWidth1: 3.5,
    borderWidth2: 2.0,
    borderInset: 5.0,
    hasCornerOrnaments: true,
    cornerColor: Color(0xFFD4A017),
  );

  /// 6. ಸರಳ — Minimal
  static const minimal = PdfThemeConfig(
    id: 'minimal',
    nameKn: 'ಸರಳ',
    nameEn: 'Minimal',
    icon: Icons.crop_square,
    primaryDark: Color(0xFF37474F),
    primaryLight: Color(0xFF607D8B),
    headerBg: Color(0xFFF5F5F5),
    headerText: Color(0xFF37474F),
    sectionTitleBg: Color(0xFFCFD8DC),
    sectionTitleText: Color(0xFF455A64),
    tableHeaderBg: Color(0xFF546E7A),
    tableHeaderText: Colors.white,
    tableAltRow: Color(0xFFF5F5F5),
    pageBg: Colors.white,
    detailBoxBg: Color(0xFFFAFAFA),
    detailBorder: Color(0xFFE0E0E0),
    shlokaText: Color(0xFF37474F),
    footerText: Color(0xFF757575),
    chartCenterBg: Color(0xFFF5F5F5),
    chartCenterText: Color(0xFF37474F),
    chartBorder: Color(0xFF9E9E9E),
    dashaHighlight: Color(0xFFF5F5F5),
    dashaHighlightBorder: Color(0xFFE0E0E0),
    dashaHighlightText: Color(0xFF37474F),
    dashaAltRow: Color(0xFFF5F5F5),
    borderColor1: Color(0xFF9E9E9E),
    borderColor2: Color(0xFFBDBDBD),
    borderWidth1: 1.5,
    borderWidth2: 0.5,
    borderInset: 3.0,
    hasCornerOrnaments: false,
    cornerColor: Colors.transparent,
  );

  /// All available themes
  static const List<PdfThemeConfig> all = [
    traditional,
    saffron,
    royalBlue,
    emerald,
    blackGold,
    minimal,
  ];

  /// Get theme by ID (defaults to traditional)
  static PdfThemeConfig getById(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => traditional);
  }

  /// Load saved theme preference
  static Future<PdfThemeConfig> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_prefKey) ?? 'traditional';
    return getById(id);
  }

  /// Save theme preference
  static Future<void> save(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, themeId);
  }
}
