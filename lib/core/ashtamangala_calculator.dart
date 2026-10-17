// Ashtamangala Prashna Calculations based on Prashna Marga & Kerala Astrological Tradition

import '../constants/strings.dart';
import 'calculator.dart';

class AshtamangalaDetails {
  final String ashtamangalaNumber;
  final String graha;
  final String yoni;
  final String jantu;
  final String panchabhuta;
  final String paksha;
  final String tithi;
  final String nakshatra;
  final String vara;
  final String rashi;

  // Dhumadi Panchasphuta (Sign-Deg-Min-Sec)
  final String dhooma;
  final String vyatipata;
  final String parivesha;
  final String indrachapa;
  final String upaketu;

  // Chandra micro-divisions
  final String chandraKriya;
  final String chandraAvastha;
  final String chandraVela;

  // Pancha Sutras
  final String samanyaSutra;
  final String adhipaSutra;
  final String amshaSutra;
  final String nakshatraSutra;
  final String mahaSutra;

  // ═══ NEW: ತ್ರಿಸ್ಫುಟಾದಿ ಗಣಿತ (from advSphutas) ═══
  final String trisphuta;
  final String chatusphuta;
  final String panchasphuta;
  final String pranaSphuta;
  final String dehaSphuta;
  final String mrityuSphuta;
  final String sookshmaTrisphuta;
  final String rudraSphuta;
  final String maheswaraSphuta;
  final String brahmaSphuta;
  final String vishnuSphuta;
  final String yamaghantaSphuta;

  // ═══ NEW: ವಿಶೇಷ ಪ್ರಶ್ನೆ ಸ್ಫುಟಗಳು ═══
  final String bimbaSphuta;
  final String pakshantaraBimbaSphuta;
  final String yamaKantaka;
  final String kalaSphuta;
  final String ardhaPraharaSphuta;
  final String bhutodaya; // Element name text
  final String arudhaSphuta;
  final String vithiSphuta;
  final String chattraSphuta;
  final String lagnaRaviYoga;
  final String sannidhyaSphuta;
  final String chaitanyaSphuta;
  final String chalanaSphuta;
  final String karanaSphuta;
  final String prasadaSphuta;
  final String pakshantaraPrasadaSphuta;
  final String anganaSphuta;
  final String mukhaMandapaSphuta;
  final String deepaSphuta;
  final String acharyaSphuta;
  final String pakshantaraAcharyaSphuta;
  final String devalakaSphuta;
  final String dhvajaSphuta;

  // ═══ NEW: ಪಂಚಸೂತ್ರ ಹೆಚ್ಚುವರಿ ═══
  final String beejaSphutaJeeva;
  final String beejaSphutaKshetra;
  final String dinaSaptaBhaga;
  final String dinaAshtaBhaga;
  final String dinaAshtaBhagaPhala;
  final String tamboolaGraha;
  final String santanaTithiPanchagga;
  final String santanaTithiChandra;
  final String santanaTithiRavindu;

  // ═══ ತ್ರಿಸ್ಫುಟ ದಶಾ ═══
  final List<DashaEntry> trisphutaDashas;
  final String trisphutaNakshatra;
  final String trisphutaDashaBalance;

  AshtamangalaDetails({
    required this.ashtamangalaNumber,
    required this.graha,
    required this.yoni,
    required this.jantu,
    required this.panchabhuta,
    required this.paksha,
    required this.tithi,
    required this.nakshatra,
    required this.vara,
    required this.rashi,
    required this.dhooma,
    required this.vyatipata,
    required this.parivesha,
    required this.indrachapa,
    required this.upaketu,
    required this.chandraKriya,
    required this.chandraAvastha,
    required this.chandraVela,
    required this.samanyaSutra,
    required this.adhipaSutra,
    required this.amshaSutra,
    required this.nakshatraSutra,
    required this.mahaSutra,
    // New fields
    required this.trisphuta,
    required this.chatusphuta,
    required this.panchasphuta,
    required this.pranaSphuta,
    required this.dehaSphuta,
    required this.mrityuSphuta,
    required this.sookshmaTrisphuta,
    required this.rudraSphuta,
    required this.maheswaraSphuta,
    required this.brahmaSphuta,
    required this.vishnuSphuta,
    required this.yamaghantaSphuta,
    required this.bimbaSphuta,
    required this.pakshantaraBimbaSphuta,
    required this.yamaKantaka,
    required this.kalaSphuta,
    required this.ardhaPraharaSphuta,
    required this.bhutodaya,
    required this.arudhaSphuta,
    required this.vithiSphuta,
    required this.chattraSphuta,
    required this.lagnaRaviYoga,
    required this.sannidhyaSphuta,
    required this.chaitanyaSphuta,
    required this.chalanaSphuta,
    required this.karanaSphuta,
    required this.prasadaSphuta,
    required this.pakshantaraPrasadaSphuta,
    required this.anganaSphuta,
    required this.mukhaMandapaSphuta,
    required this.deepaSphuta,
    required this.acharyaSphuta,
    required this.pakshantaraAcharyaSphuta,
    required this.devalakaSphuta,
    required this.dhvajaSphuta,
    required this.beejaSphutaJeeva,
    required this.beejaSphutaKshetra,
    required this.dinaSaptaBhaga,
    required this.dinaAshtaBhaga,
    required this.dinaAshtaBhagaPhala,
    required this.tamboolaGraha,
    required this.santanaTithiPanchagga,
    required this.santanaTithiChandra,
    required this.santanaTithiRavindu,
    required this.trisphutaDashas,
    required this.trisphutaNakshatra,
    required this.trisphutaDashaBalance,
  });
}

class AshtamangalaCalculator {
  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಗ್ರಹಗಳು (Prashna Marga) — index 0..7 → digit 1..8
  static const List<String> _grahas = [
    'ರವಿ', 'ಕುಜ', 'ಗುರು', 'ಬುಧ', 'ಶುಕ್ರ', 'ಶನಿ', 'ಚಂದ್ರ', 'ರಾಹು',
  ];

  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಯೋನಿಗಳು
  static const List<String> _yonis = [
    'ಧ್ವಜ', 'ಧೂಮ', 'ಸಿಂಹ', 'ಶ್ವಾನ', 'ವೃಷಭ', 'ಖರ', 'ಗಜ', 'ಧ್ವಾಂಕ್ಷ',
  ];

  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಜಂತುಗಳು
  static const List<String> _jantus = [
    'ಗರುಡ', 'ಮಾರ್ಜಾರ', 'ಸಿಂಹ', 'ಶ್ವಾನ', 'ಸರ್ಪ', 'ಮೂಷಿಕ', 'ಗಜ', 'ವಾಯಸ',
  ];

  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಪಂಚಭೂತಗಳು
  static const List<String> _panchabhutas = [
    'ಅಗ್ನಿ', 'ಅಗ್ನಿ', 'ಪೃಥ್ವೀ', 'ವಾಯು', 'ಜಲ', 'ವಾಯು', 'ಜಲ', 'ಆಕಾಶ',
  ];

  // ೧೫ ತಿಥಿಗಳು (ಶುಕ್ಲ/ಕೃಷ್ಣ ಎರಡರಲ್ಲೂ ಬಳಕೆ)
  static const List<String> _tithiNames = [
    'ಪಾಡ್ಯಮಿ', 'ದ್ವಿತೀಯಾ', 'ತೃತೀಯಾ', 'ಚತುರ್ಥೀ', 'ಪಂಚಮೀ',
    'ಷಷ್ಠೀ', 'ಸಪ್ತಮೀ', 'ಅಷ್ಟಮೀ', 'ನವಮೀ', 'ದಶಮೀ',
    'ಏಕಾದಶೀ', 'ದ್ವಾದಶೀ', 'ತ್ರಯೋದಶೀ', 'ಚತುರ್ದಶೀ', 'ಹುಣ್ಣಿಮೆ'
  ];

  // ೧೨ ಚಂದ್ರ ಅವಸ್ಥೆಗಳು (Phaladeepika Ch. 4)
  static const List<String> _chandraAvasthas = [
    'ಪ್ರವಾಸ',
    'ರಾಜಸನ್ಮಾನ',
    'ದಾಸತ್ವದಿಂದ ಪ್ರಾಣರಕ್ಷಿಸಿಕೊಂಡವನು',
    'ರಾಜ್ಯಭಾರ ಲಕ್ಷಣ',
    'ಕುಲಾಚಾರ ನಿಷ್ಠ',
    'ರೋಗಪೀಡಿತ',
    'ರಾಜಸಭಾಸ್ಥ',
    'ಭಯ-ಆತಂಕ',
    'ಶರೀರ ಬಾಧೆ',
    'ವಿವಾಹ-ಸಂಯೋಗ',
    'ಸುಖಶಯನ',
    'ಮೃಷ್ಟಾನ್ನ ಭೋಜನ'
  ];

  // ೩೬ ಚಂದ್ರ ವೇಲೆಗಳು (Phaladeepika Ch. 4)
  static const List<String> _chandraVelas = [
    'ಶಿರೋವೇದನೆ',
    'ಆನಂದ-ಪ್ರಮೋದ',
    'ಯಾಗ-ಪೂಜೆ',
    'ಸುಖವಾಸ',
    'ನೇತ್ರರೋಗ',
    'ಸಂತೋಷ',
    'ಸ್ತ್ರೀಕ್ರೀಡಾರತ',
    'ತೀವ್ರ ಜ್ವರ',
    'ಸ್ವರ್ಣಾಭರಣ ಧಾರಣೆ',
    'ಅಶ್ರುಪಾತ',
    'ವಿಷಭಕ್ಷಣ ಭೀತಿ',
    'ಸಂಭೋಗ',
    'ಉದರಶೂಲೆ',
    'ಜಲಕ್ರೀಡೆ',
    'ಹಾಸ್ಯಶೀಲ',
    'ಚಿತ್ರಲೇಖನ-ಕಲೆ',
    'ಮಧುಪಾನ',
    'ಮಿಷ್ಟಾನ್ನ ಭೋಜನ',
    'ರತ್ನಪರೀಕ್ಷೆ',
    'ನಿದ್ರಾ-ವಿಶ್ರಾಂತಿ',
    'ಶಾಸ್ತ್ರಾಧ್ಯಯನ',
    'ವಸ್ತ್ರಲಾಭ',
    'ದ್ಯೂತಕ್ರೀಡೆ',
    'ರಣ-ಯುದ್ಧ',
    'ದೇವತಾರಾಧನೆ',
    'ಔಷಧ ಸೇವನೆ',
    'ಸಂಗೀತ-ನೃತ್ಯ',
    'ವಾಹನಾರೋಹಣ',
    'ದೇಹಕ್ಕೆ ಗಾಯ',
    'ಧನಲಾಭ',
    'ಬಂಧುಸಮಾಗಮ',
    'ದೇಶಾಟನ',
    'ಬಂಧನ ಭೀತಿ',
    'ಕಲಹ',
    'ರಾಜದರ್ಶನ',
    'ಪರಮಾನಂದ-ಉತ್ಸಾಹ'
  ];

  // ೬೦ ಚಂದ್ರ ಕ್ರಿಯೆಗಳು (Phaladeepika Ch. 4 / Prashna Marga)
  static const List<String> _chandraKriyas = [
    'ಸ್ಥಾನಭ್ರಂಶ',
    'ತಪೋವೃತ್ತಿ',
    'ಪರಸ್ತ್ರೀ ರತಿ',
    'ತಸ್ಕರತ್ವ',
    'ಗಜಾರೋಹಣ',
    'ಸಿಂಹಾಸನಸ್ಥಿತಿ',
    'ರಾಜಯೋಗ',
    'ಶತ್ರುಜಯ',
    'ದಂಡನಾಥತ್ವ',
    'ಗುಣವಂತಿಕೆ',
    'ನಿಷ್ಪ್ರಾಣತ್ವ',
    'ತಲೆಗೆ ಗಾಯವಾದವನು',
    'ಕರಚರಣ ಕ್ಷತಿ',
    'ಬಂಧನ ಸ್ಥಿತಿ',
    'ವಿನಾಶ',
    'ರಾಜತ್ವ',
    'ವೇದಾಧ್ಯಯನ',
    'ನಿದ್ರಾ',
    'ಸುಚರಿತ ಸ್ಮರಣೆ',
    'ಧರ್ಮ ಕರ್ತೃತ್ವ',
    'ಸದ್ವಂಶತ್ವ',
    'ನಿಧಿ ಲಬ್ಧಿ',
    'ತೋಲನ ಪ್ರವೃತ್ತಿ',
    'ವ್ಯಾಖ್ಯಾನ ವೃತ್ತಿ',
    'ಶತ್ರು ಹನನ',
    'ರೋಗ',
    'ಶತ್ರು ಪರಾಜಯ',
    'ಪ್ರವಾಸ',
    'ದಾಸ್ಯ (ಸೇವಕ ವೃತ್ತಿ)',
    'ಅರ್ಥನಾಶ',
    'ಆಸ್ಥಾನ ಸ್ಥಿತಿ',
    'ಸ್ವಮಂತ್ರಿತ್ವ',
    'ಅನ್ಯಭೂಮಿ ಸಂಚಾರ',
    'ಸಭಾರ್ಯತ್ವ',
    'ಗಜಭಯ',
    'ಯುದ್ಧಭಯ',
    'ಅತಿಭಯ',
    'ಲೀನತ್ವ',
    'ಅನ್ನದಾತೃತ್ವ',
    'ಅಗ್ನಿ ಸಂಗಮ',
    'ಕ್ಷುತ್ಪೀಡಿತ',
    'ಭಕ್ಷಣ',
    'ಸಂಚಾರ',
    'ಮಾಂಸ ಭೋಜನ',
    'ಶಸ್ತ್ರಕ್ಷತಿ',
    'ವಿವಾಹ ಯೋಗ',
    'ಕಂದುಕ ಕ್ರೀಡೆ',
    'ದ್ಯೂತ ಕ್ರೀಡೆ',
    'ರಾಜತ್ವ',
    'ದುಃಖಿತತ್ವ',
    'ಶಯನ ಸ್ಥಿತಿ',
    'ಶತ್ರು ಸೇವಿತತ್ವ',
    'ಬಂಧು ಯೋಗ',
    'ಧ್ಯಾನ',
    'ಸಭಾರ್ಯತ್ವ',
    'ಮೃಷ್ಟಾನ್ನ ಭೋಜನ',
    'ಕ್ಷೀರಪಾನ',
    'ಸುಕೃತ ಕರ್ಮ',
    'ಸ್ವಸ್ಥತೆ',
    'ಸುಖ ಸ್ಥಿತಿ'
  ];

  // ರಾಶಿ ಅಧಿಪತಿಗಳು (0=ಮೇಷ .. 11=ಮೀನ)
  static const List<String> _rashiLords = [
    'ಕುಜ', 'ಶುಕ್ರ', 'ಬುಧ', 'ಚಂದ್ರ', 'ರವಿ', 'ಬುಧ',
    'ಶುಕ್ರ', 'ಕುಜ', 'ಗುರು', 'ಶನಿ', 'ಶನಿ', 'ಗುರು'
  ];

  // ನೈಸರ್ಗಿಕ ಮಿತ್ರರು (class-level for performance)
  static const Map<String, List<String>> _naturalFriends = {
    'ರವಿ': ['ಚಂದ್ರ', 'ಕುಜ', 'ಗುರು'],
    'ಚಂದ್ರ': ['ರವಿ', 'ಬುಧ'],
    'ಕುಜ': ['ರವಿ', 'ಚಂದ್ರ', 'ಗುರು'],
    'ಬುಧ': ['ರವಿ', 'ಶುಕ್ರ'],
    'ಗುರು': ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
    'ಶುಕ್ರ': ['ಬುಧ', 'ಶನಿ'],
    'ಶನಿ': ['ಬುಧ', 'ಶುಕ್ರ'],
  };

  // ನೈಸರ್ಗಿಕ ಶತ್ರುಗಳು
  static const Map<String, List<String>> _naturalEnemies = {
    'ರವಿ': ['ಶುಕ್ರ', 'ಶನಿ'],
    'ಚಂದ್ರ': [],
    'ಕುಜ': ['ಬುಧ'],
    'ಬುಧ': ['ಚಂದ್ರ'],
    'ಗುರು': ['ಬುಧ', 'ಶುಕ್ರ'],
    'ಶುಕ್ರ': ['ರವಿ', 'ಚಂದ್ರ'],
    'ಶನಿ': ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
  };

  // ದಿನ ಸಪ್ತ ಭಾಗ ಫಲಗಳು (7 segments of the day)
  static const List<String> _saptaBhagaPhala = [
    'ಸೌಖ್ಯ', 'ಲಾಭ', 'ಹಾನಿ', 'ಕಲಹ', 'ಶುಭ', 'ರೋಗ', 'ಮೃತ್ಯು'
  ];

  // ದಿನಾಷ್ಟ ಭಾಗ ಫಲಗಳು (8 segments of the day, mapped to planets)
  static const List<String> _ashtaBhagaPlanets = [
    'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು'
  ];

  // ದಿನಾಷ್ಟ ಭಾಗ ಫಲ (result for each planet)
  static const List<String> _ashtaBhagaPhala = [
    'ಉತ್ತರುಂ', 'ಸೌಖ್ಯ', 'ರೋಗ', 'ಲಾಭ', 'ಶುಭ', 'ಸುಖ', 'ಹಾನಿ', 'ಮೃತ್ಯು'
  ];

  /// Sign-Deg-Min-Sec format: "SS-DD-MM-SS"
  /// Fixed: seconds now properly cascade instead of overflowing to 60
  static String formatRasiDMS(double totalDeg) {
    final norm = (totalDeg % 360 + 360) % 360;
    final sign = (norm / 30).floor();
    final remDeg = norm - sign * 30;
    int deg = remDeg.floor();
    double fracMin = (remDeg - deg) * 60;
    int min = fracMin.floor();
    int sec = ((fracMin - min) * 60).round();

    // Cascade overflow: 60 sec → +1 min, 60 min → +1 deg
    if (sec >= 60) {
      sec -= 60;
      min++;
    }
    if (min >= 60) {
      min -= 60;
      deg++;
    }

    return '${sign.toString().padLeft(2, '0')}-'
           '${deg.toString().padLeft(2, '0')}-'
           '${min.toString().padLeft(2, '0')}-'
           '${sec.toString().padLeft(2, '0')}';
  }

  /// Normalize degrees to 0..360
  static double _norm(double d) => ((d % 360) + 360) % 360;

  /// Map any digit to 1-8 range (0→8, 9→1, per cyclic Ashtamangala tradition)
  static int _normalizeDigit(int d) {
    if (d == 0) return 8; // 0 maps to ರಾಹು (8)
    if (d == 9) return 1; // 9 maps to ರವಿ (1)
    return d;             // 1-8 as-is
  }

  /// Modality: 0 = Chara (ಚರ), 1 = Sthira (ಸ್ಥಿರ), 2 = Dwiswabhava (ದ್ವಿಸ್ವಭಾವ)
  /// ಮೇಷ(0)=ಚರ, ವೃಷಭ(1)=ಸ್ಥಿರ, ಮಿಥುನ(2)=ದ್ವಿ, ಕರ್ಕ(3)=ಚರ, ...
  static int _getModality(int rashiIdx) => rashiIdx % 3;

  /// Evaluate modality pair → ಜೀವ / ರೋಗ / ಮೃತ್ಯು (Prashna Marga)
  static String _evaluateModalityPair(int m1, int m2) {
    // Sort so we only need to check unique unordered pairs
    final a = m1 <= m2 ? m1 : m2;
    final b = m1 <= m2 ? m2 : m1;

    // (a, b) unordered pairs:
    // (0,0) Chara+Chara = ಜೀವ
    // (1,2) Sthira+Dwi  = ಜೀವ
    if ((a == 0 && b == 0) || (a == 1 && b == 2)) return 'ಜೀವ';

    // (1,1) Sthira+Sthira = ಮೃತ್ಯು
    // (0,2) Chara+Dwi     = ಮೃತ್ಯು
    if ((a == 1 && b == 1) || (a == 0 && b == 2)) return 'ಮೃತ್ಯು';

    // (0,1) Chara+Sthira  = ರೋಗ
    // (2,2) Dwi+Dwi       = ರೋಗ
    return 'ರೋಗ';
  }

  /// Evaluate planetary friendship → ಜೀವ / ರೋಗ / ಮೃತ್ಯು
  static String _evaluatePlanetaryRelation(String p1, String p2) {
    if (p1 == p2) return 'ಜೀವ'; // Same lord = best friends

    final isFriend = (_naturalFriends[p1]?.contains(p2) ?? false) ||
                     (_naturalFriends[p2]?.contains(p1) ?? false);
    if (isFriend) return 'ಜೀವ';

    final isEnemy = (_naturalEnemies[p1]?.contains(p2) ?? false) ||
                    (_naturalEnemies[p2]?.contains(p1) ?? false);
    if (isEnemy) return 'ಮೃತ್ಯು';

    return 'ರೋಗ'; // Neutral
  }

  /// ಭೂತೋದಯ: Determine the rising element based on Lagna rashi
  static String _getBhutodaya(int lagnaRashi) {
    // Fire signs: Mesha(0), Simha(4), Dhanu(8) → ಅಗ್ನಿ
    // Earth signs: Vrishabha(1), Kanya(5), Makara(9) → ಪೃಥ್ವಿ
    // Air signs: Mithuna(2), Tula(6), Kumbha(10) → ವಾಯು
    // Water signs: Karka(3), Vrischika(7), Meena(11) → ಜಲ
    const elements = ['ಅಗ್ನಿ', 'ಪೃಥ್ವಿ', 'ವಾಯು', 'ಜಲ'];
    return elements[lagnaRashi % 4];
  }

  /// ಪ್ರಧಾನ ಲೆಕ್ಕಾಚಾರ
  static AshtamangalaDetails calculate({
    required KundaliResult result,
    required String ashtamangalaNumber,
    required DateTime queryDateTime,
    int? svarnaroodhaRashi,
    int? sprashtangaNum,
    int? prucchakaNakshatraIdx,
  }) {
    // ═══ ೧. ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ ವಿಶ್ಲೇಷಣೆ ═══
    final numStr = ashtamangalaNumber.trim();
    int fullNum = int.tryParse(numStr) ?? 327;
    if (fullNum <= 0) fullNum = 327;

    // Extract and normalize digits (handles 0 and 9 gracefully)
    final allDigits = <int>[];
    for (int i = 0; i < numStr.length; i++) {
      final d = int.tryParse(numStr[i]);
      if (d != null) {
        allDigits.add(_normalizeDigit(d));
      }
    }

    // Ensure at least 3 digits
    List<int> digits;
    if (allDigits.isEmpty) {
      digits = [3, 2, 7];
    } else if (allDigits.length == 1) {
      digits = [allDigits[0], allDigits[0], allDigits[0]];
    } else if (allDigits.length == 2) {
      digits = [allDigits[0], allDigits[1], allDigits[1]];
    } else {
      digits = allDigits.sublist(0, 3);
    }

    final d1 = digits[0];
    final d2 = digits[1];
    final d3 = digits[2];

    // Digit-based lookups (index = digit - 1)
    final grahaStr = '${_grahas[d1 - 1]}-${_grahas[d2 - 1]}-${_grahas[d3 - 1]}';
    final yoniStr = '${_yonis[d1 - 1]}-${_yonis[d2 - 1]}-${_yonis[d3 - 1]}';
    final jantuStr = '${_jantus[d1 - 1]}-${_jantus[d2 - 1]}-${_jantus[d3 - 1]}';
    final bhutaStr = '${_panchabhutas[d1 - 1]}-${_panchabhutas[d2 - 1]}-${_panchabhutas[d3 - 1]}';

    // ತಿಥಿ & ಪಕ್ಷ
    int tRem = fullNum % 30;
    if (tRem == 0) tRem = 30;
    final isShukla = tRem <= 15;
    final pakshaStr = isShukla ? 'ಶುಕ್ಲ ಪಕ್ಷ' : 'ಕೃಷ್ಣ ಪಕ್ಷ';
    final tIdx = isShukla ? (tRem - 1) : (tRem - 16);
    final tithiStr = (tIdx >= 0 && tIdx < _tithiNames.length)
        ? (!isShukla && tIdx == 14 ? 'ಅಮಾವಾಸ್ಯೆ' : _tithiNames[tIdx])
        : 'ಪಾಡ್ಯಮಿ';

    // ನಕ್ಷತ್ರ
    int nakRem = fullNum % 27;
    if (nakRem == 0) nakRem = 27;
    final nakStr = knNak[nakRem - 1];

    // ವಾರ
    int vRem = fullNum % 7;
    if (vRem == 0) vRem = 7;
    final varaStr = knVara[vRem - 1];

    // ರಾಶಿ
    int rRem = fullNum % 12;
    if (rRem == 0) rRem = 12;
    final rashiStr = knRashi[rRem - 1];

    // ═══ ೨. ಧೂಮಾದಿ ಪಂಚಸ್ಫುಟ ═══
    final sunLong = result.planets['ರವಿ']?.longitude ?? 0.0;
    final dhoomaDeg = _norm(sunLong + 133.333333);
    final vyatipataDeg = _norm(360 - dhoomaDeg);
    final pariveshaDeg = _norm(vyatipataDeg + 180);
    final indrachapaDeg = _norm(360 - pariveshaDeg);
    final upaketuDeg = _norm(indrachapaDeg + 16.666667);

    final dhoomaStr = formatRasiDMS(dhoomaDeg);
    final vyatipataStr = formatRasiDMS(vyatipataDeg);
    final pariveshaStr = formatRasiDMS(pariveshaDeg);
    final indrachapaStr = formatRasiDMS(indrachapaDeg);
    final upaketuStr = formatRasiDMS(upaketuDeg);

    // ═══ ೩. ಚಂದ್ರ ಕ್ರಿಯಾ, ಅವಸ್ಥಾ, ವೇಲಾ ═══
    final moonLong = result.planets['ಚಂದ್ರ']?.longitude ?? 0.0;
    final nakSpan = 360.0 / 27.0; // 13.333... degrees = 800 arcminutes
    final elapsedDegInNak = moonLong % nakSpan;
    final elapsedMins = elapsedDegInNak * 60.0; // 0 to ~800

    // ಚಂದ್ರ ಕ್ರಿಯಾ (60 divisions of 800 arcmin)
    final kriyaIdx = (elapsedMins / (800.0 / 60.0)).floor().clamp(0, 59);
    final kriyaStr = '${kriyaIdx + 1}. ${_chandraKriyas[kriyaIdx]}';

    // ಚಂದ್ರ ಅವಸ್ಥಾ (12 divisions of 800 arcmin)
    final avasthaIdx = (elapsedMins / (800.0 / 12.0)).floor().clamp(0, 11);
    final avasthaStr = '${avasthaIdx + 1}. ${_chandraAvasthas[avasthaIdx]}';

    // ಚಂದ್ರ ವೇಲಾ (36 divisions of 800 arcmin)
    final velaIdx = (elapsedMins / (800.0 / 36.0)).floor().clamp(0, 35);
    final velaStr = '${velaIdx + 1}. ${_chandraVelas[velaIdx]}';

    // ═══ ೪. ಪಂಚಸೂತ್ರ ಲೆಕ್ಕಾಚಾರ (Prashna Marga) ═══
    final lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0.0;
    final lagnaRashi = (lagnaLong / 30).floor() % 12;
    final aroodhaRashi = svarnaroodhaRashi ?? ((rRem - 1) % 12);

    // A. ಸಾಮಾನ್ಯ ಸೂತ್ರ - ಪೃಥ್ವೀ (Arudha & Lagna rashi modality)
    final samanyaSutraStr = _evaluateModalityPair(
      _getModality(aroodhaRashi),
      _getModality(lagnaRashi),
    );

    // B. ಅಧಿಪ ಸೂತ್ರ - ಜಲ (Lords of Arudha & Lagna)
    final lordArudha = _rashiLords[aroodhaRashi];
    final lordLagna = _rashiLords[lagnaRashi];
    final adhipaSutraStr = _evaluatePlanetaryRelation(lordArudha, lordLagna);

    // C. ಅಂಶ ಸೂತ್ರ - ಅಗ್ನಿ (Navamsha of Lagna & Arudha)
    // Lagna navamsha: from actual lagna longitude
    final lagnaNavamsha = ((lagnaLong % 360) / (360.0 / 108.0)).floor() % 12;
    // Arudha navamsha: use arudha rashi start + lagna's degree-within-sign as proxy
    final arudhaDeg = aroodhaRashi * 30.0 + (lagnaLong % 30.0);
    final arudhaNavamsha = ((arudhaDeg % 360) / (360.0 / 108.0)).floor() % 12;
    final amshaSutraStr = _evaluateModalityPair(
      _getModality(arudhaNavamsha),
      _getModality(lagnaNavamsha),
    );

    // D. ನಕ್ಷತ್ರ ಸೂತ್ರ - ವಾಯು (Count from Lagna Nakshatra to target Nakshatra % 3)
    final lagnaNakIdx = (lagnaLong / nakSpan).floor() % 27;
    final targetNakIdx = prucchakaNakshatraIdx ?? (moonLong / nakSpan).floor() % 27;
    final dist = (targetNakIdx - lagnaNakIdx + 27) % 27 + 1;
    final nakRem3 = dist % 3;
    final nakshatraSutraStr = (nakRem3 == 1) ? 'ಜೀವ' : (nakRem3 == 2 ? 'ರೋಗ' : 'ಮೃತ್ಯು');

    // E. ಮಹಾ ಸೂತ್ರ - ಆಕಾಶ (Arudha Rashi & 10th from Arudha: Oja/Yugma classification)
    final tenthFromArudha = (aroodhaRashi + 9) % 12;
    final isArudhaChandra = (aroodhaRashi % 2 == 1);
    final isTenthChandra = (tenthFromArudha % 2 == 1);

    String mahaSutraStr;
    if (isArudhaChandra && isTenthChandra) {
      mahaSutraStr = 'ಜೀವ';
    } else if (!isArudhaChandra && !isTenthChandra) {
      mahaSutraStr = 'ಮೃತ್ಯು';
    } else {
      mahaSutraStr = 'ರೋಗ';
    }

    // ═══ ೫. ತ್ರಿಸ್ಫುಟಾದಿ ಗಣಿತ (from advSphutas, already computed in calculator.dart) ═══
    final advS = result.advSphutas;
    final trisphutatStr = formatRasiDMS(advS['ತ್ರಿಸ್ಫುಟ'] ?? 0);
    final chatusphutatStr = formatRasiDMS(advS['ಚತುಃಸ್ಫುಟ'] ?? 0);
    final panchasphutatStr = formatRasiDMS(advS['ಪಂಚಸ್ಫುಟ'] ?? 0);
    final pranaStr = formatRasiDMS(advS['ಪ್ರಾಣ'] ?? 0);
    final dehaStr = formatRasiDMS(advS['ದೇಹ'] ?? 0);
    final mrityuStr = formatRasiDMS(advS['ಮೃತ್ಯು'] ?? 0);
    final sookshmaTriStr = formatRasiDMS(advS['ಸೂಕ್ಷ್ಮ ತ್ರಿ.'] ?? 0);
    final rudraStr = formatRasiDMS(advS['ರುದ್ರ'] ?? 0);
    final maheswaraStr = formatRasiDMS(advS['ಮಹೇಶ್ವರ'] ?? 0);
    final brahmaStr = formatRasiDMS(advS['ಬ್ರಹ್ಮ'] ?? 0);
    final vishnuStr = formatRasiDMS(advS['ವಿಷ್ಣು'] ?? 0);
    final yamaghantaStr = formatRasiDMS(advS['ಯಮಘಂಟ'] ?? 0);

    // ═══ ೬. ವಿಶೇಷ ಪ್ರಶ್ನೆ ಸ್ಫುಟಗಳು (Devaprasna / Prashna Marga) ═══
    final S = sunLong;
    final M = moonLong;
    final L = lagnaLong;
    final J = result.planets['ಗುರು']?.longitude ?? 0.0;
    final V = result.planets['ಶುಕ್ರ']?.longitude ?? 0.0;
    final Ma = result.planets['ಕುಜ']?.longitude ?? 0.0;
    final Sa = result.planets['ಶನಿ']?.longitude ?? 0.0;
    final Md = result.planets['ಮಾಂದಿ']?.longitude ?? 0.0;

    // Bhava cusps (0-indexed: bhavas[0]=1st house, bhavas[3]=4th, etc.)
    final bhavas = result.bhavas;
    final bhava4 = bhavas.length > 3 ? bhavas[3] : L; // 4th cusp
    final bhava7 = bhavas.length > 6 ? bhavas[6] : _norm(L + 180); // 7th cusp
    final bhava9 = bhavas.length > 8 ? bhavas[8] : _norm(L + 240); // 9th cusp
    final bhava10 = bhavas.length > 9 ? bhavas[9] : _norm(L + 270); // 10th cusp

    // ಬಿಂಬ ಸ್ಫುಟ = Trisphuta = L + M + Md (represents the idol)
    final bimbaDeg = _norm(L + M + Md);
    final bimbaSphutaStr = formatRasiDMS(bimbaDeg);

    // ಪಕ್ಷಾಂತರ ಬಿಂಬ ಸ್ಫುಟ (Paksha correction)
    final pakshantaraBimbaDeg = isShukla ? _norm(bimbaDeg + S) : _norm(bimbaDeg + M);
    final pakshantaraBimbaSphutaStr = formatRasiDMS(pakshantaraBimbaDeg);

    // ಯಮ ಕಂಟಕ = L + J (Jupiter's segment point)
    final yamaKantakaStr = formatRasiDMS(_norm(L + J));

    // ಕಾಲ ಸ್ಫುಟ = L + S + Md (Time destruction point)
    final kalaSphutaStr = formatRasiDMS(_norm(L + S + Md));

    // ಅರ್ಧ ಪ್ರಹಾರ ಸ್ಫುಟ = L + Ma + Md (Half-prahara, Mercury's segment)
    final ardhaPraharaStr = formatRasiDMS(_norm(L + Ma + Md));

    // ಭೂತೋದಯ = element based on Lagna rashi triplicity
    final bhutodayaStr = _getBhutodaya(lagnaRashi);

    // ಆರೂಢ ಸ್ಫುಟ = Arudha rashi + Lagna's degree-within-sign
    final arudhaSphutaDeg = _norm(aroodhaRashi * 30.0 + (L % 30.0));
    final arudhaSphutaStr = formatRasiDMS(arudhaSphutaDeg);

    // ವೀಥಿ ಸ್ಫುಟ = M + Md (Path point)
    final vithiSphutaStr = formatRasiDMS(_norm(M + Md));

    // ಛತ್ರ ಸ್ಫುಟ = Chatusphuta = L + M + Md + S (Canopy)
    final chattraSphutaStr = formatRasiDMS(_norm(L + M + Md + S));

    // ಲಗ್ನ ರವಿ ಯೋಗ = L + S
    final lagnaRaviYogaStr = formatRasiDMS(_norm(L + S));

    // ಸಾನ್ನಿಧ್ಯ ಸ್ಫುಟ = L + J + S (Divine presence)
    final sannidhyaStr = formatRasiDMS(_norm(L + J + S));

    // ಚೈತನ್ಯ ಸ್ಫುಟ = L + S + M + J (Consciousness)
    final chaitanyaStr = formatRasiDMS(_norm(L + S + M + J));

    // ಚಲನ ಸ್ಫುಟ = L + Ma + S (Motion)
    final chalanaStr = formatRasiDMS(_norm(L + Ma + S));

    // ಕಾರಣ ಸ್ಫುಟ = L + Sa + Md (Cause)
    final karanaStr = formatRasiDMS(_norm(L + Sa + Md));

    // ಪ್ರಾಸಾದ ಸ್ಫುಟ = L + Ma + Sa (Temple structure)
    final prasadaDeg = _norm(L + Ma + Sa);
    final prasadaStr = formatRasiDMS(prasadaDeg);

    // ಪಕ್ಷಾಂತರ ಪ್ರಾಸಾದ ಸ್ಫುಟ
    final pakshantaraPrasadaDeg = isShukla ? _norm(prasadaDeg + S) : _norm(prasadaDeg + M);
    final pakshantaraPrasadaStr = formatRasiDMS(pakshantaraPrasadaDeg);

    // ಆಂಗಣ ಸ್ಫುಟ = L + 4th cusp + Md (Courtyard)
    final anganaStr = formatRasiDMS(_norm(L + bhava4 + Md));

    // ಮುಖ ಮಂಡಪ ಸ್ಫುಟ = L + 7th cusp + M (Front hall)
    final mukhaMandapaStr = formatRasiDMS(_norm(L + bhava7 + M));

    // ದೀಪ ಸ್ಫುಟ = L + S + Md (Lamp = light)
    final deepaStr = formatRasiDMS(_norm(L + S + Md));

    // ಆಚಾರ್ಯ ಸ್ಫುಟ = L + J + 9th cusp (Priest/Guru)
    final acharyaDeg = _norm(L + J + bhava9);
    final acharyaStr = formatRasiDMS(acharyaDeg);

    // ಪಕ್ಷಾಂತರ ಆಚಾರ್ಯ ಸ್ಫುಟ
    final pakshantaraAcharyaDeg = isShukla ? _norm(acharyaDeg + S) : _norm(acharyaDeg + M);
    final pakshantaraAcharyaStr = formatRasiDMS(pakshantaraAcharyaDeg);

    // ದೇವಲಕ ಸ್ಫುಟ = L + Sa + M (Temple attendant)
    final devalakaStr = formatRasiDMS(_norm(L + Sa + M));

    // ಧ್ವಜ ಸ್ಫುಟ = L + 10th cusp + Ma (Flagstaff)
    final dhvajaStr = formatRasiDMS(_norm(L + bhava10 + Ma));

    // ═══ ೭. ಪಂಚಸೂತ್ರ ಹೆಚ್ಚುವರಿ ═══

    // ಬೀಜ ಸ್ಫುಟ:ಜೀವಾಧಿಷ್ಠಿತ = S + V + J (Beeja/Seed)
    final beejaSphutaJeevaStr = formatRasiDMS(advS['ಬೀಜ'] ?? _norm(S + V + J));

    // ಬೀಜ ಸ್ಫುಟ:ಜೀವೇಂದು ಕ್ಷಿತಿಜ = M + Ma + J (Kshetra/Field)
    final beejaSphutaKshetraStr = formatRasiDMS(advS['ಕ್ಷೇತ್ರ'] ?? _norm(M + Ma + J));

    // ದಿನ ಸಪ್ತ ಭಾಗ: Day divided into 7 parts based on Vara
    final varaIdx = (vRem - 1) % 7; // 0-based
    final dinaSaptaStr = _saptaBhagaPhala[varaIdx];

    // ದಿನ ಅಷ್ಟ ಭಾಗ: Day divided into 8 parts, planet of current segment
    final ashtaIdx = (vRem - 1) % 8; // Use vara-based rotation
    final dinaAshtaStr = _ashtaBhagaPlanets[ashtaIdx];

    // ದಿನಾಷ್ಟ ಭಾಗ ಫಲ: Result for the ashta bhaga planet
    final dinaAshtaPhalaStr = _ashtaBhagaPhala[ashtaIdx];

    // ತಾಂಬೂಲ ಗ್ರಹ: Based on sprashtanga number or ashtamangala digit
    final tamboolaIdx = ((sprashtangaNum ?? d1) - 1).clamp(0, 7);
    final tamboolaStr = _grahas[tamboolaIdx];

    // ಸಂತಾನ ತಿಥಿಸ್ಫುಟ: three variants
    // a. ಪಂಚಾಗ್ಗಶಿನ = (M - S) × 5 mod 360
    final santanaPanchagga = formatRasiDMS(_norm((M - S) * 5));
    // b. ಚಂದ್ರಸ್ಪತ್ಯಾ = M + V + J
    final santanaChandra = formatRasiDMS(_norm(M + V + J));
    // c. ರವೀಂದುಶುಕ್ರ = S + M + V
    final santanaRavindu = formatRasiDMS(_norm(S + M + V));

    // ═══ ೮. ತ್ರಿಸ್ಫುಟ ದಶಾ (Vimshottari scaled to 365-day cycle) ═══
    // In Prashna, Trisphuta Dasha compresses 120-year Vimshottari into 365 days.
    // Scale: 1 Vimshottari-year = 365/120 ≈ 3.0417 days
    final trisphutatDeg = advS['ತ್ರಿಸ್ಫುಟ'] ?? 0.0;
    final triNakIdx = (trisphutatDeg / nakSpan).floor() % 27;
    final triNakPerc = (trisphutatDeg % nakSpan) / nakSpan; // fraction elapsed
    final triNakStr = knNak[triNakIdx];

    // Compute 365-day Trisphuta Dasha
    final trisphutaDashaList = _calcTrisphutaDasha(
      queryDateTime, triNakIdx, triNakPerc,
    );

    // Balance string: dasha lord + remaining days-hours-minutes
    final triDashaLordIdx = triNakIdx % 9;
    final triTotalDays = dashaYears[triDashaLordIdx] * 365.0 / 120.0;
    final triRemainingDays = triTotalDays * (1 - triNakPerc);
    final triBalD = triRemainingDays.floor();
    final triBalHFrac = (triRemainingDays - triBalD) * 24;
    final triBalH = triBalHFrac.floor();
    final triBalMin = ((triBalHFrac - triBalH) * 60).round();
    final triBalStr =
        '${dashaLords[triDashaLordIdx]} ${triBalD}ದಿ ${triBalH}ಗಂ ${triBalMin}ನಿ';

    return AshtamangalaDetails(
      ashtamangalaNumber: fullNum.toString(),
      graha: grahaStr,
      yoni: yoniStr,
      jantu: jantuStr,
      panchabhuta: bhutaStr,
      paksha: pakshaStr,
      tithi: tithiStr,
      nakshatra: nakStr,
      vara: varaStr,
      rashi: rashiStr,
      dhooma: dhoomaStr,
      vyatipata: vyatipataStr,
      parivesha: pariveshaStr,
      indrachapa: indrachapaStr,
      upaketu: upaketuStr,
      chandraKriya: kriyaStr,
      chandraAvastha: avasthaStr,
      chandraVela: velaStr,
      samanyaSutra: samanyaSutraStr,
      adhipaSutra: adhipaSutraStr,
      amshaSutra: amshaSutraStr,
      nakshatraSutra: nakshatraSutraStr,
      mahaSutra: mahaSutraStr,
      // New: Trisphutadi
      trisphuta: trisphutatStr,
      chatusphuta: chatusphutatStr,
      panchasphuta: panchasphutatStr,
      pranaSphuta: pranaStr,
      dehaSphuta: dehaStr,
      mrityuSphuta: mrityuStr,
      sookshmaTrisphuta: sookshmaTriStr,
      rudraSphuta: rudraStr,
      maheswaraSphuta: maheswaraStr,
      brahmaSphuta: brahmaStr,
      vishnuSphuta: vishnuStr,
      yamaghantaSphuta: yamaghantaStr,
      // New: Vishesha Prashne Sphutas
      bimbaSphuta: bimbaSphutaStr,
      pakshantaraBimbaSphuta: pakshantaraBimbaSphutaStr,
      yamaKantaka: yamaKantakaStr,
      kalaSphuta: kalaSphutaStr,
      ardhaPraharaSphuta: ardhaPraharaStr,
      bhutodaya: bhutodayaStr,
      arudhaSphuta: arudhaSphutaStr,
      vithiSphuta: vithiSphutaStr,
      chattraSphuta: chattraSphutaStr,
      lagnaRaviYoga: lagnaRaviYogaStr,
      sannidhyaSphuta: sannidhyaStr,
      chaitanyaSphuta: chaitanyaStr,
      chalanaSphuta: chalanaStr,
      karanaSphuta: karanaStr,
      prasadaSphuta: prasadaStr,
      pakshantaraPrasadaSphuta: pakshantaraPrasadaStr,
      anganaSphuta: anganaStr,
      mukhaMandapaSphuta: mukhaMandapaStr,
      deepaSphuta: deepaStr,
      acharyaSphuta: acharyaStr,
      pakshantaraAcharyaSphuta: pakshantaraAcharyaStr,
      devalakaSphuta: devalakaStr,
      dhvajaSphuta: dhvajaStr,
      // New: Panchasutra additions
      beejaSphutaJeeva: beejaSphutaJeevaStr,
      beejaSphutaKshetra: beejaSphutaKshetraStr,
      dinaSaptaBhaga: dinaSaptaStr,
      dinaAshtaBhaga: dinaAshtaStr,
      dinaAshtaBhagaPhala: dinaAshtaPhalaStr,
      tamboolaGraha: tamboolaStr,
      santanaTithiPanchagga: santanaPanchagga,
      santanaTithiChandra: santanaChandra,
      santanaTithiRavindu: santanaRavindu,
      // ತ್ರಿಸ್ಫುಟ ದಶಾ
      trisphutaDashas: trisphutaDashaList,
      trisphutaNakshatra: triNakStr,
      trisphutaDashaBalance: triBalStr,
    );
  }

  /// Trisphuta Dasha: Vimshottari compressed into a 365-day cycle.
  /// 1 Vim-year = 365/120 ≈ 3.0417 days. Uses minute-precision Duration.
  static List<DashaEntry> _calcTrisphutaDasha(
    DateTime queryDate, int nIdx, double perc,
  ) {
    const double scale = 365.0 / 120.0; // days per Vimshottari-year
    final List<DashaEntry> result = [];
    DateTime cur = queryDate;
    final si = nIdx % 9;

    for (int i = 0; i < 9; i++) {
      final im = (si + i) % 9;
      final yMul = (i == 0) ? (1 - perc) : 1.0;
      final mdMinutes = (dashaYears[im] * yMul * scale * 24 * 60).round();
      final mdEnd = cur.add(Duration(minutes: mdMinutes));

      final List<DashaEntry> antars = [];
      DateTime cad = cur;
      final totalMdY = dashaYears[im].toDouble();

      if (i == 0) {
        // First mahadasha — find which bhukti the query falls into
        final elapsedY = totalMdY * perc;
        double cumY = 0;

        for (int j = 0; j < 9; j++) {
          final ia = (im + j) % 9;
          final fullAdY = totalMdY * dashaYears[ia] / 120.0;
          final nextCum = cumY + fullAdY;

          if (nextCum <= elapsedY) {
            cumY = nextCum;
            continue; // This bhukti fully elapsed — skip
          }

          double adY;
          if (cumY < elapsedY) {
            // Partially elapsed
            adY = fullAdY * (1 - (elapsedY - cumY) / fullAdY);
          } else {
            adY = fullAdY;
          }
          cumY = nextCum;

          final adMin = (adY * scale * 24 * 60).round();
          if (adMin <= 0) continue;
          final ae = cad.add(Duration(minutes: adMin));

          // Pratyantara dashas
          final prats = _buildPratyantara(cad, ae, im, ia, scale);

          antars.add(DashaEntry(
            lord: dashaLords[ia], start: cad, end: ae,
            antardashas: prats,
          ));
          cad = ae;
        }
      } else {
        // Full mahadasha — all antardashas complete
        for (int j = 0; j < 9; j++) {
          final ia = (im + j) % 9;
          final adY = totalMdY * dashaYears[ia] / 120.0;
          final adMin = (adY * scale * 24 * 60).round();
          if (adMin <= 0) continue;
          final ae = cad.add(Duration(minutes: adMin));

          final prats = _buildPratyantara(cad, ae, im, ia, scale);

          antars.add(DashaEntry(
            lord: dashaLords[ia], start: cad, end: ae,
            antardashas: prats,
          ));
          cad = ae;
        }
      }

      result.add(DashaEntry(
        lord: dashaLords[im], start: cur, end: mdEnd,
        antardashas: antars,
      ));
      cur = mdEnd;
    }
    return result;
  }

  /// Build pratyantara (sub-sub) dashas within an antardasha.
  static List<DashaEntry> _buildPratyantara(
    DateTime adStart, DateTime adEnd, int mdIdx, int adIdx, double scale,
  ) {
    final List<DashaEntry> prats = [];
    DateTime cpd = adStart;
    final totalMdY = dashaYears[mdIdx].toDouble();

    for (int k = 0; k < 9; k++) {
      final ip = (adIdx + k) % 9;
      final pdY = (totalMdY * dashaYears[adIdx] * dashaYears[ip]) /
          (120.0 * 120.0);
      final pdMin = (pdY * scale * 24 * 60).round();
      if (pdMin <= 0) continue;
      final pe = cpd.add(Duration(minutes: pdMin));
      prats.add(DashaEntry(lord: dashaLords[ip], start: cpd, end: pe));
      cpd = pe;
    }
    return prats;
  }
}
