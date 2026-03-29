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
// App Language / Locale (kn / hi)
// ─────────────────────────────────────────────
class AppLocale {
  static final ValueNotifier<String> langNotifier = ValueNotifier('kn');
  static String get current => langNotifier.value;
  static bool get isHindi => langNotifier.value == 'hi';

  static void setLang(String lang) {
    if (lang != 'kn' && lang != 'hi') return;
    langNotifier.value = lang;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('app_lang', lang));
  }

  static Future<void> loadLang() async {
    final prefs = await SharedPreferences.getInstance();
    langNotifier.value = prefs.getString('app_lang') ?? 'kn';
  }

  /// Get localized string by key
  static String l(String key) {
    final map = _strings[langNotifier.value] ?? _strings['kn']!;
    return map[key] ?? _strings['kn']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'kn': {
      'appName': 'ಭಾರತೀಯಮ್',
      'home': 'ಮನೆ', 'kundali': 'ಕುಂಡಲಿ', 'panchanga': 'ಪಂಚಾಂಗ',
      'planets': 'ಗ್ರಹಗಳು', 'appointment': 'ಅಪಾಯಿಂಟ್\u200cಮೆಂಟ್',
      'vedicClock': 'ವೈದಿಕ ಗಡಿಯಾರ', 'settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್',
      'aboutUs': 'ನಮ್ಮ ಬಗ್ಗೆ / About Us',
      'themeSettings': 'ಥೀಮ್ ಸೆಟ್ಟಿಂಗ್ಸ್',
      'chartStyle': 'ಕುಂಡಲಿ ಶೈಲಿ / Chart Style',
      'language': 'ಭಾಷೆ / Language',
      'southIndian': 'ದಕ್ಷಿಣ ಭಾರತ', 'northIndian': 'ಉತ್ತರ ಭಾರತ',
      'googleAccount': 'Google ಖಾತೆ', 'premium': 'ಪ್ರೀಮಿಯಂ ಚಂದಾದಾರಿಕೆ',
      'privacyPolicy': 'ಗೌಪ್ಯತಾ ನೀತಿ / Privacy Policy',
      'name': 'ಹೆಸರು', 'dob': 'ಜನ್ಮ ದಿನಾಂಕ', 'time': 'ಜನ್ಮ ಸಮಯ',
      'place': 'ಜನ್ಮ ಸ್ಥಳ', 'calculate': 'ಲೆಕ್ಕ ಹಾಕಿ',
      'selectDate': 'ದಿನಾಂಕ ಆಯ್ಕೆ', 'selectTime': 'ಸಮಯ ಆಯ್ಕೆ',
      'chart': 'ಕುಂಡಲಿ', 'sphuta': 'ಸ್ಫುಟ', 'bhava': 'ಭಾವ',
      'varga': 'ವರ್ಗ', 'dasha': 'ದಶಾ', 'aroodha': 'ಆರೂಢ',
      'ashtakavarga': 'ಅಷ್ಟಕವರ್ಗ', 'taranukoola': 'ತಾರಾನುಕೂಲ',
      'matchMaking': 'ಗುಣಮಿಲಾನ', 'notes': 'ಟಿಪ್ಪಣಿ',
      'tithi': 'ತಿಥಿ', 'nakshatra': 'ನಕ್ಷತ್ರ', 'yoga': 'ಯೋಗ',
      'karana': 'ಕರಣ', 'vara': 'ವಾರ',
      'sunrise': 'ಸೂರ್ಯೋದಯ', 'sunset': 'ಸೂರ್ಯಾಸ್ತ',
      'rahuKala': 'ರಾಹು ಕಾಲ', 'gulikaKala': 'ಗುಳಿಕ ಕಾಲ',
      'yamaghantaKala': 'ಯಮಘಂಟ ಕಾಲ',
      'transits': 'ಗ್ರಹ ಸಂಚಾರ', 'vakri': 'ವಕ್ರಿ', 'asta': 'ಅಸ್ತ',
      'direct': 'ನೇರ', 'retrograde': 'ವಕ್ರಿ', 'combust': 'ಅಸ್ತ',
      'yes': 'ಹೌದು', 'no': 'ಇಲ್ಲ', 'notApplicable': 'ಅನ್ವಯಿಸುವುದಿಲ್ಲ',
      'booked': 'ಬುಕ್ ಆಗಿದೆ', 'cancelled': 'ರದ್ದು', 'completed': 'ಪೂರ್ಣ',
      'addNote': 'ಹೊಸ ಟಿಪ್ಪಣಿ ಸೇರಿಸಿ...', 'noteHistory': 'ಟಿಪ್ಪಣಿ ಇತಿಹಾಸ',
      'noNotes': 'ಇನ್ನೂ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ',
      'share': 'ಹಂಚಿಕೊಳ್ಳಿ', 'delete': 'ಅಳಿಸಿ',
      'save': 'ಉಳಿಸಿ', 'cancel': 'ರದ್ದು', 'confirm': 'ದೃಢಪಡಿಸಿ',
      'clientId': 'ಗ್ರಾಹಕ ID', 'phone': 'ಫೋನ್',
      // Kundali Input Screen
      'selectPlace': 'ಸ್ಥಳ ಆಯ್ಕೆಮಾಡಿ',
      'multiPlacesFound': 'ಒಂದೇ ಹೆಸರಿನ ಹಲವು ಸ್ಥಳಗಳು ಕಂಡುಬಂದಿವೆ:',
      'placeNotFound': 'ಸ್ಥಳ ಕಂಡುಬಂದಿಲ್ಲ.',
      'networkError': 'ಸ್ಥಳ ಹುಡುಕ ಸಾಧ್ಯವಿಲ್ಲ. ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ/ಸ್ಥಳದ ಹೆಸರನ್ನು ಪರೀಕ್ಷಿಸಿ.',
      'lahiri': 'ಲಾಹಿರಿ', 'raman': 'ರಾಮನ್', 'kp': 'ಕೆ.ಪಿ',
      'trueRahu': 'ನಿಜ ರಾಹು', 'meanRahu': 'ಮಧ್ಯಮ ರಾಹು',
      'unknown': 'ಅಪರಿಚಿತ ಹೆಸರು (Unknown)',
      'errorLabel': 'ದೋಷ',
      'date': 'ದಿನಾಂಕ', 'timeLabel': 'ಸಮಯ',
      'searchPlace': 'ಊರು ಹುಡುಕಿ',
      'lat': 'ಅಕ್ಷಾಂಶ (Lat)', 'lon': 'ರೇಖಾಂಶ (Lon)', 'tzOffset': 'ಸಮಯ ವಲಯ',
      'advancedSettings': 'ಈ ಆಯ್ಕೆಗಳು ಬದಲಾಯಿಸಬೇಡಿ',
      'ayanamsa': 'ಅಯನಾಂಶ', 'nodeType': 'ನೋಡ್',
      'openSaved': 'ತೆರೆಯಿರಿ', 'currentTime': 'ಪ್ರಸ್ತುತ', 'generate': 'ರಚಿಸಿ',
      'savedKundali': 'ಉಳಿಸಿದ ಕುಂಡಲಿ (Appointments Merged)',
      'searchHint': 'ಹೆಸರು, ಸ್ಥಳ, Client ID ಅಥವಾ ದಿನ ಹುಡುಕಿ...',
      'noSavedKundali': 'ಯಾವುದೇ ಜಾತಕ ಉಳಿಸಿಲ್ಲ.',
      'noResults': 'ಯಾವುದೇ ಫಲಿತಾಂಶ ಕಂಡುಬಂದಿಲ್ಲ.',
      'deleteConfirm': 'ಅಳಿಸಬೇಕೇ?',
      'deleteMsg': 'ಜಾತಕವನ್ನು ಅಳಿಸಬೇಕೇ?',
      'noBtn': 'ಬೇಡ',
      'kundaliTitle': 'ಕುಂಡಲಿ',
      'webBlockedTitle': 'ಇಂಟರ್ನೆಟ್ ಅಗತ್ಯ ಸಂಪರ್ಕ ಇಲ್ಲ',
      'webBlockedMsg': 'ದಯವಿಟ್ಟು ಇಂಟರ್ನೆಟ್ನಲ್ಲಿ ಸಂಪರ್ಕ ಹೊಂದಿರಿ ಈ ಅಪ್ಲಿಕೇಶನ್ನನ್ನು ಬಳಸಲು ಇಂಟರ್ನೆಟ್ ಬೇಕು.',
      'retryBtn': 'ಪುನಃಪ್ರಯತ್ನಿಸಿ',
    },
    'hi': {
      'appName': 'भारतीयम्',
      'home': 'होम', 'kundali': 'कुंडली', 'panchanga': 'पंचांग',
      'planets': 'ग्रह', 'appointment': 'अपॉइंटमेंट',
      'vedicClock': 'वैदिक घड़ी', 'settings': 'सेटिंग्स',
      'aboutUs': 'हमारे बारे में / About Us',
      'themeSettings': 'थीम सेटिंग्स',
      'chartStyle': 'कुंडली शैली / Chart Style',
      'language': 'भाषा / Language',
      'southIndian': 'दक्षिण भारत', 'northIndian': 'उत्तर भारत',
      'googleAccount': 'Google खाता', 'premium': 'प्रीमियम सदस्यता',
      'privacyPolicy': 'गोपनीयता नीति / Privacy Policy',
      'name': 'नाम', 'dob': 'जन्म तिथि', 'time': 'जन्म समय',
      'place': 'जन्म स्थान', 'calculate': 'गणना करें',
      'selectDate': 'तिथि चुनें', 'selectTime': 'समय चुनें',
      'chart': 'कुंडली', 'sphuta': 'स्फुट', 'bhava': 'भाव',
      'varga': 'वर्ग', 'dasha': 'दशा', 'aroodha': 'आरूढ',
      'ashtakavarga': 'अष्टकवर्ग', 'taranukoola': 'तारानुकूल',
      'matchMaking': 'गुणमिलान', 'notes': 'टिप्पणी',
      'tithi': 'तिथि', 'nakshatra': 'नक्षत्र', 'yoga': 'योग',
      'karana': 'करण', 'vara': 'वार',
      'sunrise': 'सूर्योदय', 'sunset': 'सूर्यास्त',
      'rahuKala': 'राहु काल', 'gulikaKala': 'गुलिक काल',
      'yamaghantaKala': 'यमघंट काल',
      'transits': 'ग्रह संचार', 'vakri': 'वक्री', 'asta': 'अस्त',
      'direct': 'मार्गी', 'retrograde': 'वक्री', 'combust': 'अस्त',
      'yes': 'हाँ', 'no': 'नहीं', 'notApplicable': 'लागू नहीं',
      'booked': 'बुक हुआ', 'cancelled': 'रद्द', 'completed': 'पूर्ण',
      'addNote': 'नई टिप्पणी जोड़ें...', 'noteHistory': 'टिप्पणी इतिहास',
      'noNotes': 'अभी तक कोई टिप्पणी नहीं',
      'share': 'साझा करें', 'delete': 'हटाएं',
      'save': 'सहेजें', 'cancel': 'रद्द करें', 'confirm': 'पुष्टि करें',
      'clientId': 'ग्राहक ID', 'phone': 'फ़ोन',
      // Kundali Input Screen
      'selectPlace': 'स्थान चुनें',
      'multiPlacesFound': 'एक ही नाम के कई स्थान मिले:',
      'placeNotFound': 'स्थान नहीं मिला.',
      'networkError': 'स्थान खोजना संभव नहीं। इंटरनेट कनेक्शन / स्थान का नाम जांचें।',
      'lahiri': 'लाहिरी', 'raman': 'रमण', 'kp': 'के.पी',
      'trueRahu': 'सही राहु', 'meanRahu': 'मध्यम राहु',
      'unknown': 'अज्ञात नाम (Unknown)',
      'errorLabel': 'त्रुटि',
      'date': 'तिथि', 'timeLabel': 'समय',
      'searchPlace': 'स्थान खोजें',
      'lat': 'अक्षांश (Lat)', 'lon': 'देशांतर (Lon)', 'tzOffset': 'समय क्षेत्र',
      'advancedSettings': 'इन विकल्पों को न बदलें',
      'ayanamsa': 'अयनांश', 'nodeType': 'नोड',
      'openSaved': 'खोलें', 'currentTime': 'वर्तमान', 'generate': 'बनाएं',
      'savedKundali': 'सहेजी गई कुंडली (Appointments Merged)',
      'searchHint': 'नाम, स्थान, Client ID या तिथि खोजें...',
      'noSavedKundali': 'कोई कुंडली सहेजी नहीं गई.',
      'noResults': 'कोई परिणाम नहीं मिला.',
      'deleteConfirm': 'हटाना है?',
      'deleteMsg': 'कुंडली हटानी है?',
      'noBtn': 'नहीं',
      'kundaliTitle': 'कुंडली',
      'webBlockedTitle': 'इंटरनेट कनेक्शन आवश्यक',
      'webBlockedMsg': 'कृपया इंटरनेट से कनेक्ट करें। इस ऐप को उपयोग करने के लिए इंटरनेट आवश्यक है।',
      'retryBtn': 'पुनः प्रयास करें',
    },
  };
}

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
