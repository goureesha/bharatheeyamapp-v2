import 'calculator.dart';
import 'saravali_phala.dart';
import 'drekkana_phala.dart';

/// Graha Phala — per-planet results based on Rashi, Navamsha, Dvadashamsha, Drekkana.
/// Based on Brihat Jataka Chapter 18 (Graha Bhava Phala) and related texts.
class GrahaPhala {
  final String planet;
  final String rashiPhala;
  final String rashiShloka;
  final String saravaliRashiPhala;
  final String navamshaPhala;
  final String navamshaShloka;
  final String saravaliNavamshaPhala;
  final String dvadashamshaPhala;
  final String dvadamshaShloka;
  final String saravaliDvadashamshaPhala;
  final String drekkanaPhala;
  final String d9DrekkanaPhala;
  final String d12DrekkanaPhala;
  final String rashi;
  final String navamshaRashi;
  final String dvadamshaRashi;
  final String drekkanaRashi;
  final String d9DrekkanaRashi;
  final String d12DrekkanaRashi;

  const GrahaPhala({
    required this.planet,
    required this.rashiPhala,
    this.rashiShloka = '',
    this.saravaliRashiPhala = '',
    required this.navamshaPhala,
    this.navamshaShloka = '',
    this.saravaliNavamshaPhala = '',
    required this.dvadashamshaPhala,
    this.dvadamshaShloka = '',
    this.saravaliDvadashamshaPhala = '',
    required this.drekkanaPhala,
    this.d9DrekkanaPhala = '',
    this.d12DrekkanaPhala = '',
    required this.rashi,
    required this.navamshaRashi,
    required this.dvadamshaRashi,
    required this.drekkanaRashi,
    this.d9DrekkanaRashi = '',
    this.d12DrekkanaRashi = '',
  });

  static const _rashiNames = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
  static const _rashiLords = ['Mars','Venus','Mercury','Moon','Sun','Mercury','Venus','Mars','Jupiter','Saturn','Saturn','Jupiter'];

  static int _rashiOf(double lon) => ((lon ~/ 30) % 12).toInt();
  static int _d9Rashi(double lon) {
    // Same formula as calculator.dart — multiply by 9, mod 360
    return (((lon * 9) % 360) / 30).floor() % 12;
  }
  static int _d12Rashi(double lon) {
    final inSign = lon % 30;
    return ((_rashiOf(lon)) + (inSign / 2.5).floor()) % 12;
  }
  static int _d3Rashi(double lon) {
    final dr = lon % 30;
    final d1 = _rashiOf(lon);
    if (dr < 10) return d1;
    if (dr < 20) return (d1 + 4) % 12;
    return (d1 + 8) % 12;
  }

  // ═══════════════════════════════════════
  // RASHI PHALA — Planet in Sign results
  // Brihat Jataka Ch.18 (Rashishiladhyaya)
  // ═══════════════════════════════════════

  // BJ 18.1-4: Sun in signs
  static const _sunShloka = {
    0: 'ಪ್ರಥಿತಶ್ಚತುರೋಽಟನೋಽಲ್ಪವಿತ್ತಃ ಕ್ರಿಯಗೇ ತ್ವಾಯುಧಭೃದ್ವಿತುಂಗಭಾಗೇ ।',
    1: 'ಗವಿ ವಸ್ತ್ರಸುಗಂಧಪಣ್ಯಜೀವೀ ವನಿತಾದ್ವಿಟ್ ಕುಶಲಶ್ಚ ಗೇಯವಾದ್ಯೇ',
    2: 'ವಿದ್ಯಾಜ್ಯೋತಿಷವಿತ್ತವಾನ್ ಮಿಥುನಗೇ ಭಾನೌ',
    3: 'ಕುಳೀರೇ ಸ್ಥಿತೇ ತೀಕ್ಷ್ಣೋಽಸ್ವಃ ಪರಕಾರ್ಯಕೃಚ್ಛ್ರಮಪಥಕ್ಲೇಶೈಶ್ಚ ಸಂಯುಜ್ಯತೇ ।',
    4: 'ಸಿಂಹಸ್ಥೇ ವನಶೈಲಗೋಕುಲರತಿರ್ವೀರ್ಯಾನ್ವಿತೋಽಜ್ಞಃ ಪುಮಾನ್',
    5: 'ಕನ್ಯಾಸ್ಥೇ ಲಿಪಿಲೇಖ್ಯಕಾವ್ಯಗಣಿತಜ್ಞಾನಾನ್ವಿತಃ ಸ್ತ್ರೀವಪುಃ',
    6: 'ಜಾತಸ್ತೌಲಿನಿ ಶೌಂಡಿಕೋಽಧ್ವನಿರತೋ ಹೈರಣ್ಯಕೋ ನೀಚಕೃತ್',
    7: 'ಕ್ರೂರಃ ಸಾಹಸಿಕೋ ವಿಷಾರ್ಜಿತಧನಃ ಶಸ್ತ್ರಾಂತಗೋಽಳೇ ಸ್ಥಿತೇ',
    8: 'ಸತ್ಪೂಜ್ಯೋ ಧನವಾನ್ ಧನುರ್ಧರಗತೇ ತೀಕ್ಷ್ಣೋಽಭಿಷಕ್ಕಾರುಕೋ',
    9: 'ನೀಚೋಽಜ್ಞಃ ಕುಮಣಿರ್ಮೃಗೇಽಲ್ಪಧನವಾನ್ ಲುಬ್ಧೋಽನ್ಯಭಾಗ್ಯೈರತಃ',
    10: 'ನೀಚೋ ಘಟೇ ತನಯಭಾಗ್ಯಪರಿಚ್ಯುತೋಽಸ್ವಃ',
    11: 'ತೋಯೋತ್ಥಪಣ್ಯವಿಭವೋ ವನಿತಾದ್ಧ್ರತೋತ್ಯೇ ।',
  };

  // BJ 18.5-8: Moon in signs
  static const _moonShloka = {
    0: 'ಅಲ್ಪಧನೋ ವಿಕಲಶ್ಚಪಲೋ ಮೇಷೇ ಶಶಿನಿ',
    1: 'ಸುಭಗೋ ಧನವಾನ್ ಭೋಗೀ ವೃಷಭೇ ಶಶಿನಿ',
    2: 'ವಿದ್ವಾನ್ ಕಲಾಪ್ರಿಯೋ ರಸಿಕೋ ಮಿಥುನೇ ಚಂದ್ರೇ',
    3: 'ಸ್ಥಿರಮನಾಃ ಗೃಹಸುಖೀ ಜಲಪ್ರೀತಿಃ ಕರ್ಕಟೇ ಚಂದ್ರೇ',
    4: 'ಉದಾರಃ ಕ್ರೋಧೀ ವನಪ್ರಿಯಃ ಸಿಂಹೇ ಶಶಿನಿ',
    5: 'ವಿನಯೀ ಪರಸೇವಕಃ ಕನ್ಯಾಯಾಂ ಚಂದ್ರೇ',
    6: 'ಕಾಮುಕೋ ರೂಪವಾನ್ ವಣಿಕ್ ತುಲಾಯಾಂ ಚಂದ್ರೇ',
    7: 'ಈರ್ಷ್ಯಾಲುಃ ಕಲಹಪ್ರಿಯೋ ವೃಶ್ಚಿಕೇ ಶಶಿನಿ',
    8: 'ಸಾಹಸೀ ಧೀರೋ ಯಾತ್ರಾಪ್ರಿಯೋ ಧನುಷಿ ಚಂದ್ರೇ',
    9: 'ಕಷ್ಟಶೀಲೋ ಕೃಷಿಕಾರೋ ಮಕರೇ ಶಶಿನಿ',
    10: 'ಪಾಪೀ ಮದ್ಯಪೋ ಸ್ತ್ರೀಲೋಲಃ ಕುಂಭೇ ಚಂದ್ರೇ',
    11: 'ರೂಪವಾನ್ ಧಾರ್ಮಿಕೋ ವಿದ್ವಾನ್ ಸುಖೀ ಮೀನೇ ಶಶಿನಿ',
  };

  // BJ 18.9-12: Mars in signs
  static const _marsShloka = {
    0: 'ನರಪತಿಸತ್ಕೃತೋಽಟನಶ್ಚಮೂಪವಣಿಕ್ ಸಧನಃ ಕ್ಷತತನುಶ್ಚೌರಭೂರಿವಿಷಯಾಂಶಶ್ಚ ಕುಜಃ ಸ್ವಗೃಹೇ',
    1: 'ಯುವತಿಜಿತಾನ್ ಸುಹೃತ್ಸ್ವವಿಷಮಾನ್ ಪರದಾರರತಾನ್ ಕುಹಕಸುವೇಷಭೀರುಪರುಷಾನ್ ಸಿತಭೇ ಜನಯೇತ್',
    2: 'ಬೌಧೇಽಸಹಸ್ತನಯವಾನ್ ವಿಸುಹೃತ್ ಕೃತಘ್ನೋ ಗಾಂಧರ್ವಯುದ್ಧಕುಶಲಃ ಕೃಪಣೋಽಭಯೋಽರ್ಥೀ ।',
    3: 'ಚಾಂದ್ರೇಽರ್ಥವಾನ್ ಸಲಿಲಯಾನಸಮಾರ್ಜಿತಸ್ವಃ ಪ್ರಾಜ್ಞಶ್ಚ ಭೂಮಿತನಯೇ ವಿಕಲಃ ಖಲಶ್ಚ',
    4: 'ನಿಸ್ವಃ ಕ್ಲೇಶಸಹೋ ವನಾಂತರಚರಃ ಸಿಂಹೇಽಲ್ಪದಾರಾತ್ಮಜೋ',
    5: 'ಬೌಧೇಽಸಹಸ್ತನಯವಾನ್ ವಿಸುಹೃತ್ ಕೃತಘ್ನೋ ಗಾಂಧರ್ವಯುದ್ಧಕುಶಲಃ ಕೃಪಣೋಽಭಯೋಽರ್ಥೀ',
    6: 'ಯುವತಿಜಿತಾನ್ ಸುಹೃತ್ಸ್ವವಿಷಮಾನ್ ಪರದಾರರತಾನ್ ಕುಹಕಸುವೇಷಭೀರುಪರುಷಾನ್ ಸಿತಭೇ ಜನಯೇತ್',
    7: 'ನರಪತಿಸತ್ಕೃತೋಽಟನಶ್ಚಮೂಪವಣಿಕ್ ಸಧನಃ ಕ್ಷತತನುಶ್ಚೌರಭೂರಿವಿಷಯಾಂಶಶ್ಚ ಕುಜಃ ಸ್ವಗೃಹೇ',
    8: 'ಜೈವೇ ನೈಕರಿಪುರ್ನರೇಂದ್ರಸಚಿವಃ ಖ್ಯಾತೋಽಭಯಾಲ್ಪಾತ್ಮಜಃ',
    9: 'ಭೌಮೇ ಭೂರಿಧನಾತ್ಮಜೋ ಮೃಗಗತೇ ಭೂಪೋಽಥವಾ ತತ್ಸಮಃ',
    10: 'ದುಃಖಾರ್ತೋ ವಿಧನೋಽಟನೋಽನೃತರಣಸ್ತೀಕ್ಷ್ಣಶ್ಚ ಕುಂಭಸ್ಥಿತೇ',
    11: 'ಜೈವೇ ನೈಕರಿಪುರ್ನರೇಂದ್ರಸಚಿವಃ ಖ್ಯಾತೋಽಭಯಾಲ್ಪಾತ್ಮಜಃ',
  };

  // BJ 18.13-15: Mercury in signs
  static const _mercuryShloka = {
    0: 'ದ್ಯೂತಋಣಪಾನರತನಾಸ್ತಿಕಚೌರನಿಸ್ವಃ ಕುಸ್ತ್ರೀಕಕೂಟಕೃದಸತ್ಯರತಾಃ ಕುಜರ್ಕ್ಷೇ ।',
    1: 'ಆಚಾರ್ಯಭೂರಿಸುತದಾರಧನಾರ್ಜನೇಷ್ಟಾಃ ಶೌಕ್ರೇ ವದಾನ್ಯಗುರುಭಕ್ತಿರತಾಶ್ಚ ಸೌಮ್ಯೇ',
    2: 'ವಿಕತ್ಥನಃ ಶಾಸ್ತ್ರಕಲಾವಿದಗ್ಧಃ ಪ್ರಿಯಂವದಃ ಸೌಖ್ಯರತಸ್ತೃತೀಯೇ',
    3: 'ಜಲಾರ್ಜಿತಸ್ವಃ ಸ್ವಜನಸ್ಯ ಶತ್ರುಃ ಶಶಾಂಕಜೇ ಶೀತಕರರ್ಕ್ಷಯುಕ್ತೇ',
    4: 'ಸ್ತ್ರೀದ್ವೇಷ್ಯೋ ವಿಧನಸುಖಾತ್ಮಜೋಽಟನೋಽಜ್ಞಃ ಸ್ತ್ರೀಲೋಲಃ ಸ್ವಪರಿಭವೋಽರ್ಕರಾಶಿಗೇ ಜ್ಞೇ ।',
    5: 'ತ್ಯಾಗೀ ಜ್ಞಃ ಪ್ರಚುರಗುಣಃ ಸುಖೀ ಕ್ಷಮಾವಾನ್ ಯುಕ್ತಿಜ್ಞೋ ವಿಗತಭಯಶ್ಚ ಷಷ್ಠರಾಶೌ',
    6: 'ಆಚಾರ್ಯಭೂರಿಸುತದಾರಧನಾರ್ಜನೇಷ್ಟಾಃ ಶೌಕ್ರೇ ವದಾನ್ಯಗುರುಭಕ್ತಿರತಾಶ್ಚ ಸೌಮ್ಯೇ',
    7: 'ದ್ಯೂತಋಣಪಾನರತನಾಸ್ತಿಕಚೌರನಿಸ್ವಃ ಕುಸ್ತ್ರೀಕಕೂಟಕೃದಸತ್ಯರತಾಃ ಕುಜರ್ಕ್ಷೇ ।',
    8: 'ನೃಪಸತ್ಕೃತಪಂಡಿತಾಪ್ತವಾಕ್ಯೋ ನವಮೇ',
    9: 'ಪರಕರ್ಮಕೃದಸ್ವಶಿಲ್ಪಬುದ್ಧಿರ್ಋಣವಾನ್ ವಿಷ್ಟಿಕರೋ ಬುಧೇಽರ್ಕಜರ್ಕ್ಷೇ ।',
    10: 'ಪರಕರ್ಮಕೃದಸ್ವಶಿಲ್ಪಬುದ್ಧಿರ್ಋಣವಾನ್ ವಿಷ್ಟಿಕರೋ ಬುಧೇಽರ್ಕಜರ್ಕ್ಷೇ ।',
    11: 'ಅಂತ್ಯೇ ಜಿತಸೇವಕಾನ್ತ್ಯಶಿಲ್ಪಃ',
  };

  // BJ 18.16-18: Jupiter in signs
  static const _jupiterShloka = {
    0: 'ಸೇನಾನೀರ್ಬಹುವಿತ್ತದಾರತನಯೋ ದಾತಾ ಸುಭೃತ್ಯಃ ಕ್ಷಮೀ ತೇಜೋದಾರಗುಣಾನ್ವಿತಃ ಸುರಗುರೌ ಖ್ಯಾತಃ ಪುಮಾನ್ ಕೌಜಭೇ ।',
    1: 'ಕಲ್ಯಾಂಗಃ ಸಧನಾರ್ಥಮಿತ್ರತನಯಸ್ತ್ಯಾಗೀ ಪ್ರಿಯಃ ಶೌಕ್ರಭೇ',
    2: 'ಬೌಧೇ ಭೂರಿಪರಿಚ್ಛದಾತ್ಮಜಸುಹೃತ್ಸಾಚಿಚ್ಯಯುಕ್ತಃ ಸುಖೀ',
    3: 'ಚಾಂದ್ರೇ ರತ್ನಸುತಸ್ವದಾರವಿಭವಪ್ರಜ್ಞಾಸುಖೈರನ್ವಿತಃ',
    4: 'ಸಿಂಹೇ ಸ್ಯಾದ್ಬಲನಾಯಕಃ ಸುರಗುರೌ ಪ್ರೋಕ್ತಂ ಚ ಯಚ್ಚಾನ್ಯಭೇ ।',
    5: 'ಬೌಧೇ ಭೂರಿಪರಿಚ್ಛದಾತ್ಮಜಸುಹೃತ್ಸಾಚಿಚ್ಯಯುಕ್ತಃ ಸುಖೀ',
    6: 'ಕಲ್ಯಾಂಗಃ ಸಧನಾರ್ಥಮಿತ್ರತನಯಸ್ತ್ಯಾಗೀ ಪ್ರಿಯಃ ಶೌಕ್ರಭೇ',
    7: 'ಸೇನಾನೀರ್ಬಹುವಿತ್ತದಾರತನಯೋ ದಾತಾ ಸುಭೃತ್ಯಃ ಕ್ಷಮೀ ತೇಜೋದಾರಗುಣಾನ್ವಿತಃ ಸುರಗುರೌ ಖ್ಯಾತಃ ಪುಮಾನ್ ಕೌಜಭೇ ।',
    8: 'ಸ್ವರ್ಕ್ಷೇ ಮಾಂಡಲಿಕೋ ನರೇಂದ್ರಸಚಿವಃ ಸೇನಾಪತಿರ್ವರ್ಧನೇ',
    9: 'ಮಕರೇ ನೀಚೋಽಲ್ಪವಿತ್ತೋಽಸುಖೀ',
    10: 'ಕುಂಭೇ ಕರ್ಕಟವತ್ ಫಲಾನಿ',
    11: 'ಸ್ವರ್ಕ್ಷೇ ಮಾಂಡಲಿಕೋ ನರೇಂದ್ರಸಚಿವಃ ಸೇನಾಪತಿರ್ವರ್ಧನೇ',
  };

  // BJ 18.19-21: Venus in signs
  static const _venusShloka = {
    0: 'ಪರಯುವತಿರತಸ್ತದರ್ಥವಾದೈರ್ಹೃತವಿಭವಃ ಕುಲಪಾಂಸನಃ ಕುಜರ್ಕ್ಷೇ ।',
    1: 'ಸ್ವಬಲಮತಿಧನೋ ನರೇಂದ್ರಪೂಜ್ಯಃ ಸ್ವಜನವಿಭುಃ ಪ್ರಥಿತೋಽಭಯಃ ಸಿತೇ ಸ್ವೇ',
    2: 'ನೃಪಕೃತ್ಯಕರೋಽರ್ಥವಾನ್ ಕಲಾವಿನ್ಮಿಥುನೇ ಷಷ್ಠಗತೇಽತಿನೀಚಕರ್ಮಾ ।',
    3: 'ದ್ವಿಭಾರ್ಯೋಽರ್ಥವಾನ್ ಭೀರುಃ ಪ್ರಬಲಮದಶೋಕಶ್ಚ ಶಶಿಭೇ',
    4: 'ಹರೌ ಯೋಷಾಪ್ಯರ್ಥಃ ಪ್ರವರಯುವತಿರ್ಮಂದತನಯಃ ।',
    5: 'ಷಷ್ಠಗತೇಽತಿನೀಚಕರ್ಮಾ',
    6: 'ಸ್ವಬಲಮತಿಧನೋ ನರೇಂದ್ರಪೂಜ್ಯಃ ಸ್ವಜನವಿಭುಃ ಪ್ರಥಿತೋಽಭಯಃ ಸಿತೇ ಸ್ವೇ',
    7: 'ಪರಯುವತಿರತಸ್ತದರ್ಥವಾದೈರ್ಹೃತವಿಭವಃ ಕುಲಪಾಂಸನಃ ಕುಜರ್ಕ್ಷೇ ।',
    8: 'ಗುಣೈಃ ಪೂಜ್ಯಃ ಸಸ್ವಸ್ತುರಗಸಹಿತೇ ದಾನವಗುರೌ',
    9: 'ರವಿಜರ್ಕ್ಷಗತೇಽಮರಾರಿಪೂಜ್ಯೇ ಸುಭಗಃ ಸ್ತ್ರೀವಿಜಿತೋ ರತಃ ಕುನಾರ್ಯಾಮ್',
    10: 'ರವಿಜರ್ಕ್ಷಗತೇಽಮರಾರಿಪೂಜ್ಯೇ ಸುಭಗಃ ಸ್ತ್ರೀವಿಜಿತೋ ರತಃ ಕುನಾರ್ಯಾಮ್',
    11: 'ಝಷೇ ವಿದ್ವಾನಾಢ್ಯೋ ನೃಪಜನಿತಪೂಜೋಽತಿಸುಭಗಃ',
  };

  // BJ 18.22-24: Saturn in signs
  static const _saturnShloka = {
    0: 'ಮೂರ್ಖೋಽಟನಃ ಕಪಟವಾನ್ ವಿಸುಹೃದ್ಯಮೇಽಜೇ',
    1: 'ವರ್ಜ್ಯಃ ಸ್ತ್ರೀಣಾಂ ನ ಬಹುವಿಭವೋ ಭೂರಿಭಾರ್ಯೋ ವೃಷಸ್ಥೇ',
    2: 'ನಿರ್ಹ್ರೀಸುಖಾರ್ಥತನಯಃ ಸ್ಖಲಿತಶ್ಚ ಲೇಖ್ಯೇ',
    3: 'ಕರ್ಕಿಣ್ಯಸ್ವೋ ವಿಕಲದಶನೋ ಮಾತೃಹೀನೋಽಸುತೋಽಜ್ಞಃ',
    4: 'ಸಿಂಹೇಽನಾರ್ಯೋ ವಿಸುಖತನಯೋ ವಿಷ್ಟಿಕೃತ್ ಸೂರ್ಯಪುತ್ರೇ',
    5: 'ರಕ್ಷಾಪತಿರ್ಭವತಿ ಮುಖ್ಯಪತಿಶ್ಚ ಬೌಧೇ',
    6: 'ಖ್ಯಾತಃ ಸ್ವೇಚ್ಛೇ ಗಣಪುರಬಲಗ್ರಾಮಪೂಜ್ಯೋಽರ್ಥವಾಂಶ್ಚ',
    7: 'ಕೀಟೇ ತು ಬಂಧವಧಭಾಕ್ ಚಪಲೋಽಘೃಣಶ್ಚ ।',
    8: 'ಸ್ವಾಂತಃ ಪ್ರತ್ಯಯಿತೋ ನರೇಂದ್ರಭವನೇ ಸತ್ಪುತ್ರಜಾಯಾಧನೋ ಜೀವಕ್ಷೇತ್ರಗತೇಽರ್ಕಜೇ ಪುರಬಲಗ್ರಾಮಾಗ್ರನೇತಾಥವಾ ।',
    9: 'ಅನ್ಯಸ್ತ್ರೀಧನಸಂವೃತಃ ಪುರಬಲಗ್ರಾಮಾಗ್ರಣೀರ್ಮಂದದೃಕ್ ಸ್ವಕ್ಷೇತ್ರೇ ಮಲಿನಃ ಸ್ಥಿರಾರ್ಥವಿಭವೋ ಭೋಕ್ತಾ ಚ ಜಾತಃ ಪುಮಾನ್',
    10: 'ಅನ್ಯಸ್ತ್ರೀಧನಸಂವೃತಃ ಪುರಬಲಗ್ರಾಮಾಗ್ರಣೀರ್ಮಂದದೃಕ್ ಸ್ವಕ್ಷೇತ್ರೇ ಮಲಿನಃ ಸ್ಥಿರಾರ್ಥವಿಭವೋ ಭೋಕ್ತಾ ಚ ಜಾತಃ ಪುಮಾನ್',
    11: 'ಸ್ವಾಂತಃ ಪ್ರತ್ಯಯಿತೋ ನರೇಂದ್ರಭವನೇ ಸತ್ಪುತ್ರಜಾಯಾಧನೋ ಜೀವಕ್ಷೇತ್ರಗತೇಽರ್ಕಜೇ ಪುರಬಲಗ್ರಾಮಾಗ್ರನೇತಾಥವಾ ।',
  };

  static const _sunInSign = {
    0: 'ಕ್ರೂರ ಕೃತ್ಯ, ಧೈರ್ಯ, ಅಸ್ಥಿರ ಸಂಪತ್ತು', // Mesha
    1: 'ಸಂಗೀತ ಪ್ರಿಯ, ಆಲಸ್ಯ, ಸ್ವಲ್ಪ ಧನ',
    2: 'ವಿದ್ವಾಂಸ, ಜ್ಯೋತಿಷ ಜ್ಞಾನ, ವಾಗ್ಮಿ',
    3: 'ಸೇವಕ ವೃತ್ತಿ, ದರಿದ್ರ, ಕ್ರೂರ',
    4: 'ರಾಜಸೇವೆ, ಪರಾಕ್ರಮ, ಅರಣ್ಯವಾಸ',
    5: 'ಸ್ತ್ರೀ ಸ್ವಭಾವ, ಯಂತ್ರ ಜ್ಞಾನ, ವಿಷ ಭಯ',
    6: 'ಮದ್ಯಪಾನ, ವ್ಯಾಪಾರ, ಪರಸ್ತ್ರೀ ಸಂಗ',
    7: 'ದುಃಖ, ಅಪಮಾನ, ಬಂಧನ',
    8: 'ಧನವಂತ, ಮಂತ್ರವಿದ್ಯೆ, ಸಂತಾನ ಸುಖ',
    9: 'ಧನ ನಷ್ಟ, ಪಿತೃ ವಿಯೋಗ',
    10: 'ಬುದ್ಧಿವಂತ, ಲೋಭಿ, ಅನ್ಯರ ಸೇವೆ',
    11: 'ರೋಗಿ, ದುಃಖಿ, ನೀಚ ಸಂಗ',
  };

  static const _moonInSign = {
    0: 'ಚಂಚಲ, ಸ್ವಲ್ಪ ಧನ, ರಕ್ತ ಸಮಸ್ಯೆ',
    1: 'ಸುಂದರ, ಧನವಂತ, ಭೋಗಿ, ವಿಶಾಲ ಹೃದಯ',
    2: 'ವಿದ್ಯಾವಂತ, ಕಲಾ ಪ್ರಿಯ, ರಸಿಕ',
    3: 'ಸ್ಥಿರ ಮನ, ಗೃಹ ಸುಖ, ಜಲ ಪ್ರೀತಿ',
    4: 'ಉದಾರ, ಕ್ರೋಧಿ, ಅರಣ್ಯ ಪ್ರೀತಿ',
    5: 'ನಮ್ರ, ಪರಸೇವಕ, ದುರ್ಬಲ ದೇಹ',
    6: 'ಕಾಮುಕ, ಸುಂದರ, ವ್ಯಾಪಾರಿ',
    7: 'ಅಸೂಯೆ, ಕಲಹ, ಬಾಧೆ',
    8: 'ಸಾಹಸಿ, ಧೈರ್ಯ, ಪ್ರವಾಸ',
    9: 'ಕಷ್ಟಪಡುವವನು, ವ್ಯವಸಾಯ, ಸ್ವಲ್ಪ ಧನ',
    10: 'ಪಾಪಿ, ಮದ್ಯಪಾನ, ಸ್ತ್ರೀ ಲೋಲ',
    11: 'ಸುಂದರ, ಧಾರ್ಮಿಕ, ವಿದ್ಯಾವಂತ, ಸುಖಿ',
  };

  static const _marsInSign = {
    0: 'ಸೇನಾಧಿಪ, ಧೈರ್ಯ, ಗಾಯ ಚಿಹ್ನೆ',
    1: 'ಹೆಂಡತಿ ಪ್ರೀತಿ, ಕೃಷಿ, ಸ್ಥಿರ',
    2: 'ಕ್ರೂರ, ಬುದ್ಧಿವಂತ, ಶಾಸ್ತ್ರಜ್ಞ',
    3: 'ಗೃಹದಲ್ಲಿ ಕಲಹ, ಧನ ನಷ್ಟ',
    4: 'ಶತ್ರು ಜಯ, ಅರಣ್ಯ ವಾಸ',
    5: 'ಶತ್ರು ಭಯ, ರೋಗ, ಚಿಂತೆ',
    6: 'ಕಾಮುಕ, ರೋಗ, ಶಸ್ತ್ರ ಭಯ',
    7: 'ರೋಗಿ, ಪರಸ್ತ್ರೀ ಸಂಗ',
    8: 'ಸೇನಾಧಿಪ, ಧನ, ಯಶ',
    9: 'ಧರ್ಮನಿಷ್ಠ, ಕಾರ್ಯಸಿದ್ಧಿ',
    10: 'ಕ್ರೂರ, ಧನ ನಷ್ಟ, ಚೋರ ಭಯ',
    11: 'ಜಲ ಭಯ, ರೋಗ, ದುಃಖ',
  };

  static const _mercuryInSign = {
    0: 'ಜೂಜು ಪ್ರಿಯ, ಸುಳ್ಳು, ಚಂಚಲ',
    1: 'ವಿದ್ಯಾವಂತ, ಕಲಾಕಾರ, ಧನವಂತ',
    2: 'ಶಾಸ್ತ್ರಜ್ಞ, ವಾಗ್ಮಿ, ಜ್ಞಾನಿ',
    3: 'ಸಂಗೀತ, ನೃತ್ಯ ಪ್ರಿಯ, ಸುಖಿ',
    4: 'ಮಂತ್ರವಿದ, ಯಂತ್ರಜ್ಞ',
    5: 'ಶಾಸ್ತ್ರ ಪಾರಂಗತ, ಗಣಿತ ಜ್ಞಾನ',
    6: 'ವ್ಯಾಪಾರ ಕುಶಲ, ಸಂಗೀತ',
    7: 'ವಿದ್ಯೆ, ಕೀರ್ತಿ, ಯಶ',
    8: 'ಕಾರ್ಯ ಸಿದ್ಧಿ, ಪರಾಕ್ರಮ',
    9: 'ಶಿಲ್ಪಿ, ಲೇಖಕ, ಕವಿ',
    10: 'ಬುದ್ಧಿವಂತ, ಧೈರ್ಯ, ಸಂಘಟಕ',
    11: 'ವೇದಾಂತಿ, ಧಾರ್ಮಿಕ, ಸುಖಿ',
  };

  static const _jupiterInSign = {
    0: 'ವಿದ್ವಾಂಸ, ಧನವಂತ, ಯಶಸ್ವಿ',
    1: 'ಸುಂದರ, ಧನ, ಭೂಮಿ, ವಾಹನ',
    2: 'ವಾಗ್ಮಿ, ಬಹುಶ್ರುತ, ರಾಜ ಸನ್ಮಾನ',
    3: 'ಧನವಂತ, ಬುದ್ಧಿವಂತ, ಮಂತ್ರಿ',
    4: 'ಅಲ್ಪ ಸಂತಾನ, ಶತ್ರು ಭಯ',
    5: 'ಸೇವಕ, ಶತ್ರು, ದುಃಖ',
    6: 'ವಾಗ್ಮಿ, ವಿದ್ಯಾವಂತ, ಸುಖಿ',
    7: 'ನೀಚ ಸಂಗ, ಅಪಮಾನ',
    8: 'ಧನ, ಪುತ್ರ, ರಾಜ ಮರ್ಯಾದೆ',
    9: 'ರಾಜಸೇವೆ, ಧನ, ಯಶ',
    10: 'ಬಡತನ, ದುಃಖ, ಅವಮಾನ',
    11: 'ವಿದ್ಯಾ, ಧನ, ಸುಖ, ಮೋಕ್ಷ',
  };

  static const _venusInSign = {
    0: 'ಕಾಮುಕ, ಸ್ತ್ರೀ ವಶ, ಧನ ನಷ್ಟ',
    1: 'ಸುಖಿ, ಧನವಂತ, ಸುಂದರ ಪತ್ನಿ',
    2: 'ಕಲಾಕಾರ, ವಿದ್ಯಾವಂತ',
    3: 'ಗೃಹ ಸುಖ, ವಾಹನ, ಮಿತ್ರ',
    4: 'ಶತ್ರು, ಅಪಮಾನ, ಕೆಟ್ಟ ಸ್ತ್ರೀ ಸಂಗ',
    5: 'ಶತ್ರು ಜಯ, ಧನ ಲಾಭ',
    6: 'ಸುಖಿ, ರಾಜ ಸನ್ಮಾನ, ಕಲಾ',
    7: 'ಅಪಮಾನ, ರೋಗ, ಕಲಹ',
    8: 'ಧನ, ಸ್ತ್ರೀ ಸುಖ, ವಾಹನ',
    9: 'ಧನ ನಷ್ಟ, ಸ್ತ್ರೀ ಕಷ್ಟ',
    10: 'ಕಾಮುಕ, ಪರಸ್ತ್ರೀ ಸಂಗ',
    11: 'ಧನ, ಸುಖ, ಸಂಗೀತ ಪ್ರೀತಿ',
  };

  static const _saturnInSign = {
    0: 'ಅಲೆಮಾರಿ, ಕ್ರೂರ, ರೋಗಿ',
    1: 'ಕೃಷಿ, ಸೇವಕ, ಆಲಸ್ಯ',
    2: 'ಬುದ್ಧಿವಂತ, ಕೆಟ್ಟ ಸ್ನೇಹ',
    3: 'ದರಿದ್ರ, ದುಃಖಿ, ಚಿಂತೆ',
    4: 'ಶತ್ರು, ಅರಣ್ಯವಾಸ, ಕ್ರೂರ',
    5: 'ರೋಗಿ, ಅಲೆಮಾರಿ, ಸೇವಕ',
    6: 'ಧನ, ವಿದ್ಯೆ, ವ್ಯಾಪಾರ',
    7: 'ಬಂಧನ, ಅಪಮಾನ, ರೋಗ',
    8: 'ಧೈರ್ಯ, ಸಾಹಸ, ಪ್ರವಾಸ',
    9: 'ಧರ್ಮನಿಷ್ಠ, ಕಾರ್ಯಸಿದ್ಧಿ',
    10: 'ನೀಚ ಕಾರ್ಯ, ಕಳ್ಳತನ, ಸುಳ್ಳು',
    11: 'ಸೇವಕ, ಕಷ್ಟ, ರೋಗ',
  };

  // ═══════════════════════════════════════
  // DREKKANA PHALA — Planet in Drekkana
  // 1st drek: same sign, 2nd: +4, 3rd: +8
  // ═══════════════════════════════════════

  static const _drekPhala = {
    0: 'ಧೈರ್ಯ, ಪರಾಕ್ರಮ, ನಾಯಕತ್ವ', // Mesha
    1: 'ಭೋಗ, ಸುಖ, ಸ್ಥಿರತೆ',
    2: 'ವಿದ್ಯೆ, ಬುದ್ಧಿ, ಸಂವಹನ',
    3: 'ಭಾವುಕತೆ, ಗೃಹ ಪ್ರೀತಿ',
    4: 'ಅಧಿಕಾರ, ಯಶ, ಪ್ರತಿಷ್ಠೆ',
    5: 'ವಿಶ್ಲೇಷಣೆ, ಸೇವೆ, ಆರೋಗ್ಯ',
    6: 'ಸಮತೋಲನ, ಕಲೆ, ನ್ಯಾಯ',
    7: 'ರಹಸ್ಯ, ತೀಕ್ಷ್ಣತೆ, ಪರಿವರ್ತನೆ',
    8: 'ಧರ್ಮ, ಜ್ಞಾನ, ಭಾಗ್ಯ',
    9: 'ಕರ್ತವ್ಯ, ಶ್ರಮ, ಫಲ',
    10: 'ಸ್ವಾತಂತ್ರ್ಯ, ನವೀನತೆ',
    11: 'ಅಧ್ಯಾತ್ಮ, ಕಲ್ಪನೆ, ಮೋಕ್ಷ',
  };

  // ═══════════════════════════════════════
  // NAVAMSHA PHALA — Planet dignity in D9
  // ═══════════════════════════════════════

  static String _navamshaPhalaFor(String pEng, int navR) {
    final lord = _rashiLords[navR];
    final ownSigns = {
      'Sun': {4}, 'Moon': {3}, 'Mars': {0,7}, 'Mercury': {2,5},
      'Jupiter': {8,11}, 'Venus': {1,6}, 'Saturn': {9,10},
    };
    final exalted = {'Sun':0,'Moon':1,'Mars':9,'Mercury':5,'Jupiter':3,'Venus':11,'Saturn':6};
    final debilitated = {'Sun':6,'Moon':7,'Mars':3,'Mercury':11,'Jupiter':9,'Venus':5,'Saturn':0};

    if (exalted[pEng] == navR) return 'ನವಾಂಶ ಉಚ್ಚ — ಅತ್ಯಂತ ಶುಭ ಫಲ, ಬಲಿಷ್ಠ';
    if (debilitated[pEng] == navR) return 'ನವಾಂಶ ನೀಚ — ದುರ್ಬಲ, ಕಷ್ಟ';
    if (ownSigns[pEng]?.contains(navR) == true) return 'ಸ್ವ ನವಾಂಶ — ಸ್ವಬಲ, ಸ್ಥಿರ ಫಲ';
    // Friendly/enemy
    const friends = {
      'Sun': {'Moon','Mars','Jupiter'}, 'Moon': {'Sun','Mercury'},
      'Mars': {'Sun','Moon','Jupiter'}, 'Mercury': {'Sun','Venus'},
      'Jupiter': {'Sun','Moon','Mars'}, 'Venus': {'Mercury','Saturn'},
      'Saturn': {'Mercury','Venus'},
    };
    if (friends[pEng]?.contains(lord) == true) return 'ಮಿತ್ರ ನವಾಂಶ — ಮಧ್ಯಮ ಶುಭ';
    return 'ಶತ್ರು ನವಾಂಶ — ಅಶುಭ ಫಲ, ಅಡಚಣೆ';
  }

  // ═══════════════════════════════════════
  // DVADASHAMSHA PHALA — D12 position
  // Parents, lineage, ancestral karma
  // ═══════════════════════════════════════

  static String _dvadamshaPhalaFor(String pEng, int d12R) {
    final lord = _rashiLords[d12R];
    final ownSigns = {
      'Sun': {4}, 'Moon': {3}, 'Mars': {0,7}, 'Mercury': {2,5},
      'Jupiter': {8,11}, 'Venus': {1,6}, 'Saturn': {9,10},
    };
    if (ownSigns[pEng]?.contains(d12R) == true) return 'ಸ್ವ ದ್ವಾದಶಾಂಶ — ಪಿತೃ/ಮಾತೃ ಸುಖ, ವಂಶ ಗೌರವ';
    const friends = {
      'Sun': {'Moon','Mars','Jupiter'}, 'Moon': {'Sun','Mercury'},
      'Mars': {'Sun','Moon','Jupiter'}, 'Mercury': {'Sun','Venus'},
      'Jupiter': {'Sun','Moon','Mars'}, 'Venus': {'Mercury','Saturn'},
      'Saturn': {'Mercury','Venus'},
    };
    if (friends[pEng]?.contains(lord) == true) return 'ಮಿತ್ರ ದ್ವಾದಶಾಂಶ — ಮಧ್ಯಮ ಪಿತೃ ಸುಖ';
    return 'ಶತ್ರು ದ್ವಾದಶಾಂಶ — ಪಿತೃ ಕಷ್ಟ, ವಂಶ ಸಮಸ್ಯೆ';
  }

  /// Generate GrahaPhala for all 7 planets.
  static List<GrahaPhala> generate(KundaliResult chart) {
    const planetMap = {
      'Sun': 'ರವಿ', 'Moon': 'ಚಂದ್ರ', 'Mars': 'ಕುಜ',
      'Mercury': 'ಬುಧ', 'Jupiter': 'ಗುರು', 'Venus': 'ಶುಕ್ರ', 'Saturn': 'ಶನಿ',
    };
    const signPhalas = {
      'Sun': _sunInSign, 'Moon': _moonInSign, 'Mars': _marsInSign,
      'Mercury': _mercuryInSign, 'Jupiter': _jupiterInSign,
      'Venus': _venusInSign, 'Saturn': _saturnInSign,
    };

    final results = <GrahaPhala>[];
    for (final entry in planetMap.entries) {
      final pEng = entry.key;
      final pKn = entry.value;
      final info = chart.planets[pKn];
      if (info == null) continue;

      final lon = info.longitude;
      final r = _rashiOf(lon);
      final d9r = _d9Rashi(lon);
      final d12r = _d12Rashi(lon);
      final d3r = _d3Rashi(lon);

      // Drekkana number (1,2,3) for D1, D9, D12
      final d1Drek = DrekkanaPhala.drekkanaNumber(lon);
      final d9Lon = (lon * 9) % 360;
      final d9Drek = DrekkanaPhala.drekkanaNumber(d9Lon);
      final d9DrekRashi = _rashiOf(d9Lon);
      final d12Lon = (lon * 12) % 360;
      final d12Drek = DrekkanaPhala.drekkanaNumber(d12Lon);
      final d12DrekRashi = _rashiOf(d12Lon);

      const shlokaMap = {
        'Sun': _sunShloka, 'Moon': _moonShloka, 'Mars': _marsShloka,
        'Mercury': _mercuryShloka, 'Jupiter': _jupiterShloka,
        'Venus': _venusShloka, 'Saturn': _saturnShloka,
      };
      results.add(GrahaPhala(
        planet: pKn,
        rashi: _rashiNames[r],
        navamshaRashi: _rashiNames[d9r],
        dvadamshaRashi: _rashiNames[d12r],
        drekkanaRashi: '${_rashiNames[r]} ${d1Drek}ನೇ',
        d9DrekkanaRashi: '${_rashiNames[d9DrekRashi]} ${d9Drek}ನೇ',
        d12DrekkanaRashi: '${_rashiNames[d12DrekRashi]} ${d12Drek}ನೇ',
        rashiPhala: signPhalas[pEng]?[r] ?? '',
        rashiShloka: shlokaMap[pEng]?[r] ?? '',
        saravaliRashiPhala: SaravaliPhala.getPhala(pEng, r),
        navamshaPhala: signPhalas[pEng]?[d9r] ?? '',
        navamshaShloka: shlokaMap[pEng]?[d9r] ?? '',
        saravaliNavamshaPhala: SaravaliPhala.getPhala(pEng, d9r),
        dvadashamshaPhala: signPhalas[pEng]?[d12r] ?? '',
        dvadamshaShloka: shlokaMap[pEng]?[d12r] ?? '',
        saravaliDvadashamshaPhala: SaravaliPhala.getPhala(pEng, d12r),
        drekkanaPhala: DrekkanaPhala.getPhala(r, d1Drek),
        d9DrekkanaPhala: DrekkanaPhala.getPhala(d9DrekRashi, d9Drek),
        d12DrekkanaPhala: DrekkanaPhala.getPhala(d12DrekRashi, d12Drek),
      ));
    }
    return results;
  }
}
