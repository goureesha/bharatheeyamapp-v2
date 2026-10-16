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
  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಗ್ರಹಗಳು (Prashna Marga)
  static const Map<int, String> grahas = {
    1: 'ರವಿ',
    2: 'ಕುಜ',
    3: 'ಗುರು',
    4: 'ಬುಧ',
    5: 'ಶುಕ್ರ',
    6: 'ಶನಿ',
    7: 'ಚಂದ್ರ',
    8: 'ರಾಹು',
  };

  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಯೋನಿಗಳು
  static const Map<int, String> yonis = {
    1: 'ಧ್ವಜ',
    2: 'ಧೂಮ',
    3: 'ಸಿಂಹ',
    4: 'ಶ್ವಾನ',
    5: 'ವೃಷಭ',
    6: 'ಖರ',
    7: 'ಗಜ',
    8: 'ಧ್ವಾಂಕ್ಷ',
  };

  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಜಂತುಗಳು
  static const Map<int, String> jantus = {
    1: 'ಗರುಡ',
    2: 'ಮಾರ್ಜಾರ',
    3: 'ಸಿಂಹ',
    4: 'ಶ್ವಾನ',
    5: 'ಸರ್ಪ',
    6: 'ಮೂಷಿಕ',
    7: 'ಗಜ',
    8: 'ವಾಯಸ',
  };

  // ೧ ರಿಂದ ೮ ಅಷ್ಟಮಂಗಲ ಪಂಚಭೂತಗಳು
  static const Map<int, String> panchabhutas = {
    1: 'ಅಗ್ನಿ',
    2: 'ಅಗ್ನಿ',
    3: 'ಪೃಥ್ವೀ',
    4: 'ವಾಯು',
    5: 'ಜಲ',
    6: 'ವಾಯು',
    7: 'ಜಲ',
    8: 'ಆಕಾಶ',
  };

  // ೧೨ ತಿಥಿಗಳು (ಶುಕ್ಲ/ಕೃಷ್ಣ)
  static const List<String> tithiNames = [
    'ಪಾಡ್ಯಮಿ', 'ದ್ವಿತೀಯಾ', 'ತೃತೀಯಾ', 'ಚತುರ್ಥೀ', 'ಪಂಚಮೀ',
    'ಷಷ್ಠೀ', 'ಸಪ್ತಮೀ', 'ಅಷ್ಟಮೀ', 'ನವಮೀ', 'ದಶಮೀ',
    'ಏಕಾದಶೀ', 'ದ್ವಾದಶೀ', 'ತ್ರಯೋದಶೀ', 'ಚತುರ್ದಶೀ', 'ಹುಣ್ಣಿಮೆ'
  ];

  // ೧೨ ಚಂದ್ರ ಅವಸ್ಥೆಗಳು (Phaladeepika Ch. 4)
  static const List<String> chandraAvasthas = [
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
  static const List<String> chandraVelas = [
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
  static const List<String> chandraKriyas = [
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

  /// Sign-Deg-Min-Sec format: "SS-DD-MM-SS"
  static String formatRasiDMS(double totalDeg) {
    final norm = (totalDeg % 360 + 360) % 360;
    final sign = (norm / 30).floor();
    final remDeg = norm % 30;
    final deg = remDeg.floor();
    final remMin = (remDeg - deg) * 60;
    final min = remMin.floor();
    final sec = ((remMin - min) * 60).round();

    return '${sign.toString().padLeft(2, '0')}-'
           '${deg.toString().padLeft(2, '0')}-'
           '${min.toString().padLeft(2, '0')}-'
           '${sec.toString().padLeft(2, '0')}';
  }

  /// ಪ್ರಧಾನ ಲೆಕ್ಕಾಚಾರ
  static AshtamangalaDetails calculate({
    required KundaliResult result,
    required String ashtamangalaNumber,
    int? svarnaroodhaRashi,
    int? sprashtangaNum,
    int? prucchakaNakshatraIdx,
  }) {
    // ೧. ಅಷ್ಟಮಂಗಲ ಸಂಖ್ಯೆ ವಿಶ್ಲೇಷಣೆ
    final numStr = ashtamangalaNumber.trim();
    int fullNum = int.tryParse(numStr) ?? 327;
    if (fullNum <= 0) fullNum = 327;

    List<int> digits = [];
    for (int i = 0; i < numStr.length; i++) {
      final d = int.tryParse(numStr[i]);
      if (d != null && d >= 1 && d <= 8) {
        digits.add(d);
      }
    }
    while (digits.length < 3) {
      if (digits.isEmpty) {
        digits = [3, 2, 7];
      } else if (digits.length == 1) {
        digits = [digits[0], digits[0], digits[0]];
      } else if (digits.length == 2) {
        digits.add(digits[1]);
      }
    }

    final d1 = digits[0];
    final d2 = digits[1];
    final d3 = digits[2];

    final grahaStr = '${grahas[d1]}-${grahas[d2]}-${grahas[d3]}';
    final yoniStr = '${yonis[d1]}-${yonis[d2]}-${yonis[d3]}';
    final jantuStr = '${jantus[d1]}-${jantus[d2]}-${jantus[d3]}';
    final bhutaStr = '${panchabhutas[d1]}-${panchabhutas[d2]}-${panchabhutas[d3]}';

    // ತಿಥಿ & ಪಕ್ಷ
    int tRem = fullNum % 30;
    if (tRem == 0) tRem = 30;
    final isShukla = tRem <= 15;
    final pakshaStr = isShukla ? 'ಶುಕ್ಲ ಪಕ್ಷ' : 'ಕೃಷ್ಣ ಪಕ್ಷ';
    final tIdx = isShukla ? (tRem - 1) : (tRem - 16);
    final tithiStr = (tIdx >= 0 && tIdx < tithiNames.length)
        ? (!isShukla && tIdx == 14 ? 'ಅಮಾವಾಸ್ಯೆ' : tithiNames[tIdx])
        : 'ದ್ವಾದಶೀ';

    // ನಕ್ಷತ್ರ
    int nakRem = fullNum % 27;
    if (nakRem == 0) nakRem = 27;
    final nakStr = knNak[(nakRem - 1) % 27];

    // ವಾರ
    int vRem = fullNum % 7;
    if (vRem == 0) vRem = 7;
    final varaStr = knVara[(vRem - 1) % 7];

    // ರಾಶಿ
    int rRem = fullNum % 12;
    if (rRem == 0) rRem = 12;
    final rashiStr = knRashi[(rRem - 1) % 12];

    // ೨. ಧೂಮಾದಿ ಪಂಚಸ್ಫುಟ
    final sunLong = result.planets['ರವಿ']?.longitude ?? 0.0;
    final dhoomaDeg = (sunLong + 133.333333) % 360;
    final vyatipataDeg = (360 - dhoomaDeg) % 360;
    final pariveshaDeg = (vyatipataDeg + 180) % 360;
    final indrachapaDeg = (360 - pariveshaDeg) % 360;
    final upaketuDeg = (indrachapaDeg + 16.666667) % 360;

    final dhoomaStr = formatRasiDMS(dhoomaDeg);
    final vyatipataStr = formatRasiDMS(vyatipataDeg);
    final pariveshaStr = formatRasiDMS(pariveshaDeg);
    final indrachapaStr = formatRasiDMS(indrachapaDeg);
    final upaketuStr = formatRasiDMS(upaketuDeg);

    // ೩. ಚಂದ್ರ ಕ್ರಿಯಾ, ಅವಸ್ಥಾ, ವೇಲಾ
    final moonLong = result.planets['ಚಂದ್ರ']?.longitude ?? 0.0;
    final nakSpan = 360.0 / 27.0; // 13.333333 degrees = 800 arcminutes
    final elapsedDegInNak = moonLong % nakSpan;
    final elapsedMins = elapsedDegInNak * 60.0; // 0 to 800

    // ಚಂದ್ರ ಕ್ರಿಯಾ (60)
    int kriyaIdx = (elapsedMins / (800.0 / 60.0)).floor() + 1;
    if (kriyaIdx < 1) kriyaIdx = 1;
    if (kriyaIdx > 60) kriyaIdx = 60;
    final kriyaName = chandraKriyas[kriyaIdx - 1];
    final kriyaStr = '$kriyaIdx. $kriyaName';

    // ಚಂದ್ರ ಅವಸ್ಥಾ (12)
    int avasthaIdx = (elapsedMins / (800.0 / 12.0)).floor() + 1;
    if (avasthaIdx < 1) avasthaIdx = 1;
    if (avasthaIdx > 12) avasthaIdx = 12;
    final avasthaName = chandraAvasthas[avasthaIdx - 1];
    final avasthaStr = '$avasthaIdx. $avasthaName';

    // ಚಂದ್ರ ವೇಲಾ (36)
    int velaIdx = (elapsedMins / (800.0 / 36.0)).floor() + 1;
    if (velaIdx < 1) velaIdx = 1;
    if (velaIdx > 36) velaIdx = 36;
    final velaName = chandraVelas[velaIdx - 1];
    final velaStr = '$velaIdx. $velaName';

    // ೪. ಪಂಚಸೂತ್ರ ಲೆಕ್ಕಾಚಾರ (Prashna Marga Ch. 5/6)
    final lagnaLong = result.planets['ಲಗ್ನ']?.longitude ?? 0.0;
    final lagnaRashi = (lagnaLong / 30).floor() % 12;
    final aroodhaRashi = svarnaroodhaRashi ?? ((rRem - 1) % 12);

    // Modality: 0 = Chara (ಚರ), 1 = Sthira (ಸ್ಥಿರ), 2 = Dwiswabhava (ದ್ವಿಸ್ವಭಾವ)
    int getModality(int r) {
      final rem = r % 3;
      if (rem == 0) return 0; // ಚರ (ಮೇಷ, ಕರ್ಕ, ತುಲಾ, ಮಕರ)
      if (rem == 1) return 1; // ಸ್ಥಿರ (ವೃಷಭ, ಸಿಂಹ, ವೃಶ್ಚಿಕ, ಕುಂಭ)
      return 2; // ದ್ವಿಸ್ವಭಾವ (ಮಿಥುನ, ಕನ್ಯಾ, ಧನು, ಮೀನ)
    }

    String evaluateModalityPair(int m1, int m2) {
      if (m1 == 0 && m2 == 0) return 'ಜೀವ';
      if ((m1 == 1 && m2 == 2) || (m1 == 2 && m2 == 1)) return 'ಜೀವ';
      if (m1 == 1 && m2 == 1) return 'ಮೃತ್ಯು';
      if ((m1 == 0 && m2 == 2) || (m1 == 2 && m2 == 0)) return 'ಮೃತ್ಯು';
      return 'ರೋಗ';
    }

    // A. ಸಾಮಾನ್ಯ ಸೂತ್ರ - ಪೃಥ್ವೀ (Arudha Rashi & Lagna Rashi)
    final samanyaSutraStr = evaluateModalityPair(
      getModality(aroodhaRashi),
      getModality(lagnaRashi),
    );

    // B. ಅಧಿಪ ಸೂತ್ರ - ಜಲ (Lords of Arudha & Lagna)
    const rashiLords = [
      'ಕುಜ', 'ಶುಕ್ರ', 'ಬುಧ', 'ಚಂದ್ರ', 'ರವಿ', 'ಬುಧ',
      'ಶುಕ್ರ', 'ಕುಜ', 'ಗುರು', 'ಶನಿ', 'ಶನಿ', 'ಗುರು'
    ];
    final lordArudha = rashiLords[aroodhaRashi];
    final lordLagna = rashiLords[lagnaRashi];

    String evaluatePlanetaryRelation(String p1, String p2) {
      if (p1 == p2) return 'ಜೀವ';
      const naturalFriends = {
        'ರವಿ': ['ಚಂದ್ರ', 'ಕುಜ', 'ಗುರು'],
        'ಚಂದ್ರ': ['ರವಿ', 'ಬುಧ'],
        'ಕುಜ': ['ರವಿ', 'ಚಂದ್ರ', 'ಗುರು'],
        'ಬುಧ': ['ರವಿ', 'ಶುಕ್ರ'],
        'ಗುರು': ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
        'ಶುಕ್ರ': ['ಬುಧ', 'ಶನಿ'],
        'ಶನಿ': ['ಬುಧ', 'ಶುಕ್ರ'],
      };
      const naturalEnemies = {
        'ರವಿ': ['ಶುಕ್ರ', 'ಶನಿ'],
        'ಚಂದ್ರ': [],
        'ಕುಜ': ['ಬುಧ'],
        'ಬುಧ': ['ಚಂದ್ರ'],
        'ಗುರು': ['ಬುಧ', 'ಶುಕ್ರ'],
        'ಶುಕ್ರ': ['ರವಿ', 'ಚಂದ್ರ'],
        'ಶನಿ': ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
      };
      final isFriend = (naturalFriends[p1]?.contains(p2) ?? false) ||
                       (naturalFriends[p2]?.contains(p1) ?? false);
      final isEnemy = (naturalEnemies[p1]?.contains(p2) ?? false) ||
                      (naturalEnemies[p2]?.contains(p1) ?? false);

      if (isFriend) return 'ಜೀವ';
      if (isEnemy) return 'ಮೃತ್ಯು';
      return 'ರೋಗ';
    }

    final adhipaSutraStr = evaluatePlanetaryRelation(lordArudha, lordLagna);

    // C. ಅಂಶ ಸೂತ್ರ - ಅಗ್ನಿ (Navamsha of Lagna & Arudha)
    final lagnaNavamsha = ((lagnaLong % 360) / (30.0 / 9.0)).floor() % 12;
    final arudhaNavamsha = (aroodhaRashi * 9) % 12;
    final amshaSutraStr = evaluateModalityPair(
      getModality(arudhaNavamsha),
      getModality(lagnaNavamsha),
    );

    // D. ನಕ್ಷತ್ರ ಸೂತ್ರ - ವಾಯು (Count from Lagna Nakshatra to Janma/Prucchaka Nakshatra % 3)
    final lagnaNakIdx = (lagnaLong / nakSpan).floor() % 27;
    final targetNakIdx = prucchakaNakshatraIdx ?? (moonLong / nakSpan).floor() % 27;
    final dist = (targetNakIdx - lagnaNakIdx + 27) % 27 + 1;
    final nakRem3 = dist % 3;
    final nakshatraSutraStr = (nakRem3 == 1) ? 'ಜೀವ' : (nakRem3 == 2 ? 'ರೋಗ' : 'ಮೃತ್ಯು');

    // E. ಮಹಾ ಸೂತ್ರ - ಆಕಾಶ (Arudha Rasi & 10th Rasi from Arudha)
    final tenthFromArudha = (aroodhaRashi + 9) % 12;
    const chandraRasis = [0, 1, 2, 3, 8, 9, 11]; // Mesha, Vrishabha, Mithuna, Karka, Dhanu, Makara, Meena
    final isArudhaChandra = chandraRasis.contains(aroodhaRashi);
    final isTenthChandra = chandraRasis.contains(tenthFromArudha);

    String mahaSutraStr;
    if (isArudhaChandra && isTenthChandra) {
      mahaSutraStr = 'ಜೀವ';
    } else if (!isArudhaChandra && !isTenthChandra) {
      mahaSutraStr = 'ಮೃತ್ಯು';
    } else {
      mahaSutraStr = 'ರೋಗ';
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
