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

  const AshtamangalaDetails({
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

  /// ಪ್ರಧಾನ ಲೆಕ್ಕಾಚಾರ
  static AshtamangalaDetails calculate({
    required KundaliResult result,
    required String ashtamangalaNumber,
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
    final dhoomaDeg = (sunLong + 133.333333) % 360;
    final vyatipataDeg = (360 - dhoomaDeg + 360) % 360;
    final pariveshaDeg = (vyatipataDeg + 180) % 360;
    final indrachapaDeg = (360 - pariveshaDeg + 360) % 360;
    final upaketuDeg = (indrachapaDeg + 16.666667) % 360;

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
    // Oja (odd signs, 0-indexed even): ಮೇಷ(0), ಮಿಥುನ(2), ಸಿಂಹ(4), ತುಲಾ(6), ಧನು(8), ಕುಂಭ(10) → Surya
    // Yugma (even signs, 0-indexed odd): ವೃಷಭ(1), ಕರ್ಕ(3), ಕನ್ಯಾ(5), ವೃಶ್ಚಿಕ(7), ಮಕರ(9), ಮೀನ(11) → Chandra
    final tenthFromArudha = (aroodhaRashi + 9) % 12;
    final isArudhaChandra = (aroodhaRashi % 2 == 1);      // Yugma = Chandra
    final isTenthChandra = (tenthFromArudha % 2 == 1);     // Yugma = Chandra

    String mahaSutraStr;
    if (isArudhaChandra && isTenthChandra) {
      mahaSutraStr = 'ಜೀವ';  // Both Chandra → ಜೀವ
    } else if (!isArudhaChandra && !isTenthChandra) {
      mahaSutraStr = 'ಮೃತ್ಯು';  // Both Surya → ಮೃತ್ಯು
    } else {
      mahaSutraStr = 'ರೋಗ';  // Mixed → ರೋಗ
    }

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
    );
  }
}
