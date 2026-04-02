import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ─────────────────────────────────────────────
// Shared app-wide decorators / constants
// ─────────────────────────────────────────────

class AppThemes {
  static final ValueNotifier<int> themeNotifier = ValueNotifier(0);

  static const List<Map<String, Color>> palettes = [
    { // Standard Light
      'purple1': Color(0xFF8E2DE2),
      'purple2': Color(0xFF4A00E0),
      'bg': Color(0xFFFFFDF7),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF2D3748),
      'border': Color(0xFFE2E8F0),
      'muted': Color(0xFF718096),
    },
    { // Dark Night
      'purple1': Color(0xFF9F7AEA),
      'purple2': Color(0xFF805AD5),
      'bg': Color(0xFF1A202C),
      'card': Color(0xFF2D3748),
      'text': Color(0xFFF7FAFC),
      'border': Color(0xFF4A5568),
      'muted': Color(0xFFA0AEC0),
    },
    { // Golden Sepia
      'purple1': Color(0xFFDD6B20),
      'purple2': Color(0xFFC05621),
      'bg': Color(0xFFFFFBEB),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF451A03),
      'border': Color(0xFFFCD34D),
      'muted': Color(0xFF92400E),
    },
    { // Royal Ocean
      'purple1': Color(0xFF2563EB),
      'purple2': Color(0xFF1D4ED8),
      'bg': Color(0xFFF0F9FF),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF0F172A),
      'border': Color(0xFFBAE6FD),
      'muted': Color(0xFF475569),
    },
    { // Emerald Forest
      'purple1': Color(0xFF059669),
      'purple2': Color(0xFF047857),
      'bg': Color(0xFFF0FDF4),
      'card': Color(0xFFFFFFFF),
      'text': Color(0xFF064E3B),
      'border': Color(0xFFBBF7D0),
      'muted': Color(0xFF166534),
    }
  ];

  static void setTheme(int i) {
    if (i < 0 || i >= palettes.length) return;
    final p = palettes[i];
    kPurple1 = p['purple1']!;
    kPurple2 = p['purple2']!;
    kBg = p['bg']!;
    kCard = p['card']!;
    kText = p['text']!;
    kBorder = p['border']!;
    kMuted = p['muted']!;
    themeNotifier.value = i;
    // Persist theme choice
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('app_theme', i));
  }

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('app_theme') ?? 0;
    setTheme(idx);
  }
}

// ─────────────────────────────────────────────
// Kundali chart style (South / North Indian)
// ─────────────────────────────────────────────
class ChartStyle {
  static final ValueNotifier<String> styleNotifier = ValueNotifier('south');

  static String get current => styleNotifier.value;
  static bool get isNorth => styleNotifier.value == 'north';

  static void setStyle(String style) {
    if (style != 'south' && style != 'north') return;
    styleNotifier.value = style;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('chart_style', style));
  }

  static Future<void> loadStyle() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('chart_style') ?? 'south';
    styleNotifier.value = s;
  }
}

// ─────────────────────────────────────────────
// App Language / Locale (Kannada only)
// ─────────────────────────────────────────────
class AppLocale {
  static final ValueNotifier<String> langNotifier = ValueNotifier('kn');
  static String get current => 'kn';
  static bool get isHindi => false;

  static void setLang(String lang) {
    langNotifier.value = 'kn';
  }

  static Future<void> loadLang() async {
    langNotifier.value = 'kn';
  }

  /// Get localized string by key (Kannada only)
  static String l(String key) {
    return _strings[key] ?? key;
  }

  static const Map<String, String> _strings = {
    'appName': '\u0cad\u0cbe\u0cb0\u0ca4\u0cc0\u0caf\u0cae\u0ccd',
    'home': '\u0cae\u0ca8\u0cc6', 'kundali': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf', 'panchanga': '\u0caa\u0c82\u0c9a\u0cbe\u0c82\u0c97',
    'planets': '\u0c97\u0ccd\u0cb0\u0cb9\u0c97\u0cb3\u0cc1', 'appointment': '\u0c85\u0caa\u0cbe\u0caf\u0cbf\u0c82\u0c9f\u0ccd\u200c\u0cae\u0cc6\u0c82\u0c9f\u0ccd',
    'vedicClock': '\u0cb5\u0cc8\u0ca6\u0cbf\u0c95 \u0c97\u0ca1\u0cbf\u0caf\u0cbe\u0cb0', 'settings': '\u0cb8\u0cc6\u0c9f\u0ccd\u0c9f\u0cbf\u0c82\u0c97\u0ccd\u0cb8\u0ccd',
    'aboutUs': '\u0ca8\u0cae\u0ccd\u0cae \u0cac\u0c97\u0ccd\u0c97\u0cc6 / About Us',
    'themeSettings': '\u0ca5\u0cc0\u0cae\u0ccd \u0cb8\u0cc6\u0c9f\u0ccd\u0c9f\u0cbf\u0c82\u0c97\u0ccd\u0cb8\u0ccd',
    'chartStyle': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf \u0cb6\u0cc8\u0cb2\u0cbf / Chart Style',
    'language': '\u0cad\u0cbe\u0cb7\u0cc6 / Language',
    'southIndian': '\u0ca6\u0c95\u0ccd\u0cb7\u0cbf\u0ca3 \u0cad\u0cbe\u0cb0\u0ca4', 'northIndian': '\u0c89\u0ca4\u0ccd\u0ca4\u0cb0 \u0cad\u0cbe\u0cb0\u0ca4',
    'googleAccount': 'Google \u0c96\u0cbe\u0ca4\u0cc6', 'premium': '\u0caa\u0ccd\u0cb0\u0cc0\u0cae\u0cbf\u0caf\u0c82 \u0c9a\u0c82\u0ca6\u0cbe\u0ca6\u0cbe\u0cb0\u0cbf\u0c95\u0cc6',
    'privacyPolicy': '\u0c97\u0ccc\u0caa\u0ccd\u0caf\u0ca4\u0cbe \u0ca8\u0cc0\u0ca4\u0cbf / Privacy Policy',
    'name': '\u0cb9\u0cc6\u0cb8\u0cb0\u0cc1', 'dob': '\u0c9c\u0ca8\u0ccd\u0cae \u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', 'time': '\u0c9c\u0ca8\u0ccd\u0cae \u0cb8\u0cae\u0caf',
    'place': '\u0c9c\u0ca8\u0ccd\u0cae \u0cb8\u0ccd\u0ca5\u0cb3', 'calculate': '\u0cb2\u0cc6\u0c95\u0ccd\u0c95 \u0cb9\u0cbe\u0c95\u0cbf',
    'selectDate': '\u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95 \u0c86\u0caf\u0ccd\u0c95\u0cc6', 'selectTime': '\u0cb8\u0cae\u0caf \u0c86\u0caf\u0ccd\u0c95\u0cc6',
    'chart': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf', 'sphuta': '\u0cb8\u0ccd\u0cab\u0cc1\u0c9f', 'bhava': '\u0cad\u0cbe\u0cb5',
    'varga': '\u0cb5\u0cb0\u0ccd\u0c97', 'dasha': '\u0ca6\u0cb6\u0cbe', 'aroodha': '\u0c86\u0cb0\u0cc2\u0ca2',
    'ashtakavarga': '\u0c85\u0cb7\u0ccd\u0c9f\u0c95\u0cb5\u0cb0\u0ccd\u0c97', 'taranukoola': '\u0ca4\u0cbe\u0cb0\u0cbe\u0ca8\u0cc1\u0c95\u0cc2\u0cb2',
    'matchMaking': '\u0c97\u0cc1\u0ca3 \u0cae\u0cbf\u0cb2\u0ca8', 'notes': '\u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf',
    'tithi': '\u0ca4\u0cbf\u0ca5\u0cbf', 'nakshatra': '\u0ca8\u0c95\u0ccd\u0cb7\u0ca4\u0ccd\u0cb0', 'yoga': '\u0caf\u0ccb\u0c97',
    'karana': '\u0c95\u0cb0\u0ca3', 'vara': '\u0cb5\u0cbe\u0cb0',
    'sunrise': '\u0cb8\u0cc2\u0cb0\u0ccd\u0caf\u0ccb\u0ca6\u0caf', 'sunset': '\u0cb8\u0cc2\u0cb0\u0ccd\u0caf\u0cbe\u0cb8\u0ccd\u0ca4',
    'rahuKala': '\u0cb0\u0cbe\u0cb9\u0cc1 \u0c95\u0cbe\u0cb2', 'gulikaKala': '\u0c97\u0cc1\u0cb3\u0cbf\u0c95 \u0c95\u0cbe\u0cb2',
    'yamaghantaKala': '\u0caf\u0cae\u0c98\u0c82\u0c9f \u0c95\u0cbe\u0cb2',
    'transits': '\u0c97\u0ccd\u0cb0\u0cb9 \u0cb8\u0c82\u0c9a\u0cbe\u0cb0', 'vakri': '\u0cb5\u0c95\u0ccd\u0cb0\u0cbf', 'asta': '\u0c85\u0cb8\u0ccd\u0ca4',
    'direct': '\u0ca8\u0cc7\u0cb0', 'retrograde': '\u0cb5\u0c95\u0ccd\u0cb0\u0cbf', 'combust': '\u0c85\u0cb8\u0ccd\u0ca4',
    'yes': '\u0cb9\u0ccc\u0ca6\u0cc1', 'no': '\u0c87\u0cb2\u0ccd\u0cb2', 'notApplicable': '\u0c85\u0ca8\u0ccd\u0cb5\u0caf\u0cbf\u0cb8\u0cc1\u0cb5\u0cc1\u0ca6\u0cbf\u0cb2\u0ccd\u0cb2',
    'booked': '\u0cac\u0cc1\u0c95\u0ccd \u0c86\u0c97\u0cbf\u0ca6\u0cc6', 'cancelled': '\u0cb0\u0ca6\u0ccd\u0ca6\u0cc1', 'completed': '\u0caa\u0cc2\u0cb0\u0ccd\u0ca3',
    'addNote': '\u0cb9\u0cca\u0cb8 \u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf \u0cb8\u0cc7\u0cb0\u0cbf\u0cb8\u0cbf...', 'noteHistory': '\u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf \u0c87\u0ca4\u0cbf\u0cb9\u0cbe\u0cb8',
    'noNotes': '\u0c87\u0ca8\u0ccd\u0ca8\u0cc2 \u0c9f\u0cbf\u0caa\u0ccd\u0caa\u0ca3\u0cbf\u0c97\u0cb3\u0cbf\u0cb2\u0ccd\u0cb2',
    'share': '\u0cb9\u0c82\u0c9a\u0cbf\u0c95\u0cca\u0cb3\u0ccd\u0cb3\u0cbf', 'delete': '\u0c85\u0cb3\u0cbf\u0cb8\u0cbf',
    'save': '\u0c89\u0cb3\u0cbf\u0cb8\u0cbf', 'cancel': '\u0cb0\u0ca6\u0ccd\u0ca6\u0cc1', 'confirm': '\u0ca6\u0cc3\u0ca2\u0caa\u0ca1\u0cbf\u0cb8\u0cbf',
    'clientId': '\u0c97\u0ccd\u0cb0\u0cbe\u0cb9\u0c95 ID', 'phone': '\u0cab\u0ccb\u0ca8\u0ccd',
    'selectPlace': '\u0cb8\u0ccd\u0ca5\u0cb3 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0cae\u0cbe\u0ca1\u0cbf',
    'multiPlacesFound': '\u0c92\u0c82\u0ca6\u0cc7 \u0cb9\u0cc6\u0cb8\u0cb0\u0cbf\u0ca8 \u0cb9\u0cb2\u0cb5\u0cc1 \u0cb8\u0ccd\u0ca5\u0cb3\u0c97\u0cb3\u0cc1 \u0c95\u0c82\u0ca1\u0cc1\u0cac\u0c82\u0ca6\u0cbf\u0cb5\u0cc6:',
    'placeNotFound': '\u0cb8\u0ccd\u0ca5\u0cb3 \u0c95\u0c82\u0ca1\u0cc1\u0cac\u0c82\u0ca6\u0cbf\u0cb2\u0ccd\u0cb2.',
    'networkError': '\u0cb8\u0ccd\u0ca5\u0cb3 \u0cb9\u0cc1\u0ca1\u0cc1\u0c95 \u0cb8\u0cbe\u0ca7\u0ccd\u0caf\u0cb5\u0cbf\u0cb2\u0ccd\u0cb2. \u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95/\u0cb8\u0ccd\u0ca5\u0cb3\u0ca6 \u0cb9\u0cc6\u0cb8\u0cb0\u0ca8\u0ccd\u0ca8\u0cc1 \u0caa\u0cb0\u0cc0\u0c95\u0ccd\u0cb7\u0cbf\u0cb8\u0cbf.',
    'lahiri': '\u0cb2\u0cbe\u0cb9\u0cbf\u0cb0\u0cbf', 'raman': '\u0cb0\u0cbe\u0cae\u0ca8\u0ccd', 'kp': '\u0c95\u0cc6.\u0caa\u0cbf',
    'trueRahu': '\u0ca8\u0cbf\u0c9c \u0cb0\u0cbe\u0cb9\u0cc1', 'meanRahu': '\u0cae\u0ca7\u0ccd\u0caf\u0cae \u0cb0\u0cbe\u0cb9\u0cc1',
    'unknown': '\u0c85\u0caa\u0cb0\u0cbf\u0c9a\u0cbf\u0ca4 \u0cb9\u0cc6\u0cb8\u0cb0\u0cc1 (Unknown)',
    'errorLabel': '\u0ca6\u0ccb\u0cb7',
    'date': '\u0ca6\u0cbf\u0ca8\u0cbe\u0c82\u0c95', 'timeLabel': '\u0cb8\u0cae\u0caf',
    'searchPlace': '\u0c8a\u0cb0\u0cc1 \u0cb9\u0cc1\u0ca1\u0cc1\u0c95\u0cbf',
    'lat': '\u0c85\u0c95\u0ccd\u0cb7\u0cbe\u0c82\u0cb6 (Lat)', 'lon': '\u0cb0\u0cc7\u0c96\u0cbe\u0c82\u0cb6 (Lon)', 'tzOffset': '\u0cb8\u0cae\u0caf \u0cb5\u0cb2\u0caf',
    'advancedSettings': '\u0c88 \u0c86\u0caf\u0ccd\u0c95\u0cc6\u0c97\u0cb3\u0cc1 \u0cac\u0ca6\u0cb2\u0cbe\u0caf\u0cbf\u0cb8\u0cac\u0cc7\u0ca1\u0cbf',
    'ayanamsa': '\u0c85\u0caf\u0ca8\u0cbe\u0c82\u0cb6', 'nodeType': '\u0ca8\u0ccb\u0ca1\u0ccd',
    'openSaved': '\u0ca4\u0cc6\u0cb0\u0cc6\u0caf\u0cbf\u0cb0\u0cbf', 'currentTime': '\u0caa\u0ccd\u0cb0\u0cb8\u0ccd\u0ca4\u0cc1\u0ca4', 'generate': '\u0cb0\u0c9a\u0cbf\u0cb8\u0cbf',
    'savedKundali': '\u0c89\u0cb3\u0cbf\u0cb8\u0cbf\u0ca6 \u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf (Appointments Merged)',
    'searchHint': '\u0cb9\u0cc6\u0cb8\u0cb0\u0cc1, \u0cb8\u0ccd\u0ca5\u0cb3, Client ID \u0c85\u0ca5\u0cb5\u0cbe \u0ca6\u0cbf\u0ca8 \u0cb9\u0cc1\u0ca1\u0cc1\u0c95\u0cbf...',
    'noSavedKundali': '\u0caf\u0cbe\u0cb5\u0cc1\u0ca6\u0cc7 \u0c9c\u0cbe\u0ca4\u0c95 \u0c89\u0cb3\u0cbf\u0cb8\u0cbf\u0cb2\u0ccd\u0cb2.',
    'noResults': '\u0caf\u0cbe\u0cb5\u0cc1\u0ca6\u0cc7 \u0cab\u0cb2\u0cbf\u0ca4\u0cbe\u0c82\u0cb6 \u0c95\u0c82\u0ca1\u0cc1\u0cac\u0c82\u0ca6\u0cbf\u0cb2\u0ccd\u0cb2.',
    'deleteConfirm': '\u0c85\u0cb3\u0cbf\u0cb8\u0cac\u0cc7\u0c95\u0cc7?',
    'deleteMsg': '\u0c9c\u0cbe\u0ca4\u0c95\u0cb5\u0ca8\u0ccd\u0ca8\u0cc1 \u0c85\u0cb3\u0cbf\u0cb8\u0cac\u0cc7\u0c95\u0cc7?',
    'noBtn': '\u0cac\u0cc7\u0ca1',
    'kundaliTitle': '\u0c95\u0cc1\u0c82\u0ca1\u0cb2\u0cbf',
    'webBlockedTitle': '\u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd \u0c85\u0c97\u0ca4\u0ccd\u0caf \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95 \u0c87\u0cb2\u0ccd\u0cb2',
    'webBlockedMsg': '\u0ca6\u0caf\u0cb5\u0cbf\u0c9f\u0ccd\u0c9f\u0cc1 \u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd\u0ca8\u0cb2\u0ccd\u0cb2\u0cbf \u0cb8\u0c82\u0caa\u0cb0\u0ccd\u0c95 \u0cb9\u0cca\u0c82\u0ca6\u0cbf\u0cb0\u0cbf \u0c88 \u0c85\u0caa\u0ccd\u0cb2\u0cbf\u0c95\u0cc7\u0cb6\u0ca8\u0ccd\u0ca8\u0ca8\u0ccd\u0ca8\u0cc1 \u0cac\u0cb3\u0cb8\u0cb2\u0cc1 \u0c87\u0c82\u0c9f\u0cb0\u0ccd\u0ca8\u0cc6\u0c9f\u0ccd \u0cac\u0cc7\u0c95\u0cc1.',
    'retryBtn': '\u0caa\u0cc1\u0ca8\u0c83\u0caa\u0ccd\u0cb0\u0caf\u0ca4\u0ccd\u0ca8\u0cbf\u0cb8\u0cbf',
  };

  /// Pass-through -- no translation
  static String tr(String text) => text;
}

/// Shorthand global function -- just returns text as-is
String tr(String text) => text;

Color kPurple1 = AppThemes.palettes[0]['purple1']!;
Color kPurple2 = AppThemes.palettes[0]['purple2']!;
Color kOrange  = const Color(0xFFDD6B20);
Color kOrange2 = const Color(0xFFC05621);
Color kTeal    = const Color(0xFF319795);
Color kGreen   = const Color(0xFF047857);
Color kBg      = AppThemes.palettes[0]['bg']!;
Color kCard    = AppThemes.palettes[0]['card']!;
Color kBorder  = AppThemes.palettes[0]['border']!;
Color kText    = AppThemes.palettes[0]['text']!;
Color kMuted   = AppThemes.palettes[0]['muted']!;

// ─────────────────────────────────────────────
// Responsive helpers
// ─────────────────────────────────────────────
bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600;

/// Wraps content with a max-width constraint on tablets.
/// On mobile, renders child full-width. On tablets, centers
/// child with maxWidth (default 600px).
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 600});

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}


// ─────────────────────────────────────────────
// Header widget (purple gradient banner)
// ─────────────────────────────────────────────
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPurple1, kPurple2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPurple2.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
        border: const Border(bottom: BorderSide(color: Color(0xFFF6D365), width: 4)),
      ),
      child: Center(
        child: Text(
          'ಭಾರತೀಯಮ್',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Card wrapper
// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const AppCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String text;
  final Color? color;
  SectionTitle(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color ?? kPurple2,
        ),
      ),
    );
  }
}
