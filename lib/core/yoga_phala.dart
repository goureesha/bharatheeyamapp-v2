/// Yoga Phala — Prashna Yoga evaluation engine
/// Evaluates astrological yogas and returns satisfied shlokas
import 'calculator.dart';
import '../constants/strings.dart';

class YogaResult {
  final String name;
  final String shloka;
  final String chart; // 'ರಾಶಿ', 'ನವಾಂಶ', 'ದ್ವಾದಶಾಂಶ'
  YogaResult({required this.name, required this.shloka, this.chart = 'ರಾಶಿ'});
}

class YogaPhala {
  // ═══════════════════════════════════════════
  // CONSTANTS
  // ═══════════════════════════════════════════
  static const _papaNames = ['ರವಿ', 'ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];
  static const _shubhaNames = ['ಗುರು', 'ಶುಕ್ರ', 'ಬುಧ'];
  static const _mainPlanets = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];

  // Own sign rulership (0-indexed rashi)
  static const _ownSigns = <String, List<int>>{
    'ರವಿ': [4],      // Simha
    'ಚಂದ್ರ': [3],    // Kataka
    'ಕುಜ': [0, 7],   // Mesha, Vrischika
    'ಬುಧ': [2, 5],   // Mithuna, Kanya
    'ಗುರು': [8, 11],  // Dhanu, Meena
    'ಶುಕ್ರ': [1, 6],  // Vrishabha, Tula
    'ಶನಿ': [9, 10],   // Makara, Kumbha
  };

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════
  static int _rashiOf(double lon) => (lon / 30).floor() % 12;

  static int _houseOf(double planetLon, double lagnaLon) {
    final pR = _rashiOf(planetLon);
    final lR = _rashiOf(lagnaLon);
    return ((pR - lR + 12) % 12) + 1;
  }

  static bool _isPapa(String name) => _papaNames.contains(name);
  static bool _isShubha(String name) => _shubhaNames.contains(name);

  /// Get all houses a planet aspects (1-indexed)
  static List<int> _aspectedHouses(String planet, int house) {
    final a = <int>[];
    // All planets aspect 7th from themselves
    a.add(((house - 1 + 6) % 12) + 1);
    if (planet == 'ಕುಜ') {
      a.add(((house - 1 + 3) % 12) + 1); // 4th
      a.add(((house - 1 + 7) % 12) + 1); // 8th
    } else if (planet == 'ಗುರು') {
      a.add(((house - 1 + 4) % 12) + 1); // 5th
      a.add(((house - 1 + 8) % 12) + 1); // 9th
    } else if (planet == 'ಶನಿ') {
      a.add(((house - 1 + 2) % 12) + 1); // 3rd
      a.add(((house - 1 + 9) % 12) + 1); // 10th
    }
    return a;
  }

  /// Does planet at planetHouse aspect targetHouse?
  static bool _aspects(String planet, int planetHouse, int targetHouse) {
    return _aspectedHouses(planet, planetHouse).contains(targetHouse);
  }

  /// Mutual kendra (houses 1,4,7,10 from each other)
  static bool _mutualKendra(int h1, int h2) {
    final d = ((h2 - h1 + 12) % 12);
    return [0, 3, 6, 9].contains(d);
  }

  /// Mutual trikona (houses 1,5,9 from each other)
  static bool _mutualTrikona(int h1, int h2) {
    final d = ((h2 - h1 + 12) % 12);
    return [0, 4, 8].contains(d);
  }

  /// Any papa graha aspects given house?
  static bool _anyPapaAspects(Map<String, int> houses, int targetH) {
    for (final e in houses.entries) {
      if (_isPapa(e.key) && _aspects(e.key, e.value, targetH)) return true;
    }
    return false;
  }

  /// Any shubha graha aspects given house?
  static bool _anyShubhaAspects(Map<String, int> houses, int targetH) {
    for (final e in houses.entries) {
      if (_isShubha(e.key) && _aspects(e.key, e.value, targetH)) return true;
    }
    return false;
  }

  /// Any papa graha in given house?
  static bool _anyPapaInHouse(Map<String, int> houses, int h) {
    return houses.entries.any((e) => _isPapa(e.key) && e.value == h);
  }

  /// Any shubha graha in given house?
  static bool _anyShubhaInHouse(Map<String, int> houses, int h) {
    return houses.entries.any((e) => _isShubha(e.key) && e.value == h);
  }

  /// Specific planet aspects house?
  static bool _planetAspectsHouse(String planet, Map<String, int> houses, int targetH) {
    final h = houses[planet];
    if (h == null) return false;
    return _aspects(planet, h, targetH);
  }

  /// Navamsha rashi (0-indexed)
  static int _navamshaRashi(double longitude) {
    final sign = _rashiOf(longitude);
    final degInSign = longitude % 30;
    final navNum = (degInSign / (30.0 / 9.0)).floor().clamp(0, 8);
    // Starting rashi by element
    final element = sign % 4;
    int startRashi;
    switch (element) {
      case 0: startRashi = 0; break;  // Fire → Aries
      case 1: startRashi = 9; break;  // Earth → Capricorn
      case 2: startRashi = 6; break;  // Air → Libra
      case 3: startRashi = 3; break;  // Water → Cancer
      default: startRashi = 0;
    }
    return (startRashi + navNum) % 12;
  }

  /// Is Chandra waning? (Sun-Moon distance > 180°)
  static bool _isChandraWaning(double moonLon, double sunLon) {
    final diff = (moonLon - sunLon + 360.0) % 360.0;
    return diff > 180.0;
  }

  /// Is Chandra full (purnima)? Near 180° from Sun
  static bool _isFullMoon(double moonLon, double sunLon) {
    final d = (moonLon - sunLon + 360.0) % 360.0;
    return d > 150.0 && d < 210.0;
  }

  // Rashi classifications
  static bool _isChara(int r) => r % 3 == 0;      // 0,3,6,9
  static bool _isSthira(int r) => r % 3 == 1;      // 1,4,7,10
  static bool _isDwiswabhava(int r) => r % 3 == 2;  // 2,5,8,11
  static bool _isChatushpada(int r) => [0, 1, 4, 8].contains(r);
  static bool _isJala(int r) => [3, 7, 11].contains(r);
  static bool _isPapaRashi(int r) => [0, 4, 7, 9, 10].contains(r);

  /// Drekkana rashi (0-indexed)
  static int _drekkanaRashi(double lon) {
    final sign = _rashiOf(lon);
    final deg = lon % 30;
    return (sign + (deg < 10 ? 0 : deg < 20 ? 4 : 8)) % 12;
  }

  /// Is target house between house a and b (shorter arc)?
  static bool _houseBetween(int t, int a, int b) {
    if (a == b || t == a || t == b) return false;
    final fwd = ((b - a + 12) % 12);
    final ft = ((t - a + 12) % 12);
    if (fwd <= 6) return ft > 0 && ft < fwd;
    final bt = ((t - b + 12) % 12);
    return bt > 0 && bt < (12 - fwd);
  }

  /// Rashi → body part mapping (Kannada)
  static const _rashiBodyPart = <int, String>{
    0: 'ಶಿರ (ತಲೆ)', 1: 'ಮುಖ', 2: 'ಎದೆ/ಬಾಹು', 3: 'ಹೃದಯ',
    4: 'ಉದರ', 5: 'ಸೊಂಟ', 6: 'ನಾಭಿ', 7: 'ಗುಹ್ಯ',
    8: 'ತೊಡೆ', 9: 'ಮೊಣಕಾಲು', 10: 'ಕಾಲು (ಮೊಳ)', 11: 'ಪಾದ',
  };

  /// Dvadashamsha rashi (D12, 0-indexed)
  static int _dvadashamshaRashi(double lon) {
    final sign = _rashiOf(lon);
    final deg = lon % 30;
    final part = (deg / 2.5).floor().clamp(0, 11);
    return (sign + part) % 12;
  }

  /// Compute divisional chart house map
  static Map<String, int> _divHouses(KundaliResult r, int Function(double) rashiCalc) {
    final lagnaLon = r.planets['ಲಗ್ನ']?.longitude ?? (r.bhavas.isNotEmpty ? r.bhavas[0] : 0.0);
    final lagnaDiv = rashiCalc(lagnaLon);
    final houses = <String, int>{};
    for (final e in r.planets.entries) {
      if (e.key == 'ಲಗ್ನ' || e.key == 'ಮಾಂದಿ') continue;
      final divR = rashiCalc(e.value.longitude);
      houses[e.key] = ((divR - lagnaDiv + 12) % 12) + 1;
    }
    return houses;
  }

  // ═══════════════════════════════════════════
  // MAIN EVALUATOR
  // ═══════════════════════════════════════════
  static List<YogaResult> evaluate(KundaliResult r, {bool navamsha = false, bool dvadashamsha = false}) {
    final lagnaLon = r.planets['ಲಗ್ನ']?.longitude ?? (r.bhavas.isNotEmpty ? r.bhavas[0] : 0.0);
    final lagnaRashi = _rashiOf(lagnaLon);

    // Compute house positions (1-12)
    final houses = <String, int>{};
    for (final e in r.planets.entries) {
      if (e.key == 'ಲಗ್ನ' || e.key == 'ಮಾಂದಿ') continue;
      houses[e.key] = _houseOf(e.value.longitude, lagnaLon);
    }

    final results = <YogaResult>[];

    // ── Rashi chart yogas ──
    results.addAll(_evaluateAll(r, houses, lagnaRashi, lagnaLon, 'ರಾಶಿ'));

    // ── Navamsha chart yogas ──
    if (navamsha) {
      final navH = _divHouses(r, _navamshaRashi);
      final navLagnaR = _navamshaRashi(lagnaLon);
      results.addAll(_evaluateHouseYogas(navH, navLagnaR, 'ನವಾಂಶ'));
    }

    // ── Dvadashamsha chart yogas ──
    if (dvadashamsha) {
      final dvH = _divHouses(r, _dvadashamshaRashi);
      final dvLagnaR = _dvadashamshaRashi(lagnaLon);
      results.addAll(_evaluateHouseYogas(dvH, dvLagnaR, 'ದ್ವಾದಶಾಂಶ'));
    }

    return results;
  }

  /// Run ALL yogas (rashi chart only — uses longitude data)
  static List<YogaResult> _evaluateAll(KundaliResult r, Map<String, int> houses, int lagnaRashi, double lagnaLon, String chart) {
    final results = <YogaResult>[];
    final y1 = _yoga1(houses);
    if (y1 != null) results.add(y1);

    final y2 = _yoga2(houses);
    if (y2 != null) results.add(y2);

    final y3 = _yoga3(r, houses);
    if (y3 != null) results.add(y3);

    final y4 = _yoga4(houses);
    if (y4 != null) results.add(y4);

    final y5 = _yoga5(houses);
    if (y5 != null) results.add(y5);

    final y6 = _yoga6(houses);
    if (y6 != null) results.add(y6);

    final y7 = _yoga7(houses);
    if (y7 != null) results.add(y7);

    final y9 = _yoga9(r, houses);
    if (y9 != null) results.add(y9);

    final y10 = _yoga10(houses);
    if (y10 != null) results.add(y10);

    results.addAll(_yoga11(r, houses));

    final y17 = _yoga17(r, houses);
    if (y17 != null) results.add(y17);

    final y18 = _yoga18(r, houses, lagnaRashi, lagnaLon);
    if (y18 != null) results.add(y18);

    final y19 = _yoga19(r, houses, lagnaRashi, lagnaLon);
    if (y19 != null) results.add(y19);

    final y20 = _yoga20(r, houses, lagnaRashi);
    if (y20 != null) results.add(y20);

    final y22 = _yoga22(r, houses, lagnaLon);
    if (y22 != null) results.add(y22);

    // ── Janma Kala Lakshanadhyaya (Chapter 5) ──
    results.addAll(_jkl1(r, houses, lagnaRashi));
    final j2 = _jkl2(r, houses, lagnaRashi);
    if (j2 != null) results.add(j2);
    final j3 = _jkl3(r, houses);
    if (j3 != null) results.add(j3);
    final j4 = _jkl4(houses, lagnaRashi);
    if (j4 != null) results.add(j4);
    results.addAll(_jkl6(r, houses));
    final j7 = _jkl7(r, houses, lagnaRashi);
    if (j7 != null) results.add(j7);
    final j8 = _jkl8(r, houses, lagnaRashi);
    if (j8 != null) results.add(j8);
    final j9 = _jkl9(r, houses, lagnaRashi);
    if (j9 != null) results.add(j9);
    results.addAll(_jkl10(r, houses, lagnaRashi));
    results.addAll(_jkl11(houses));
    results.addAll(_jkl12(lagnaLon));
    results.addAll(_jkl13(houses));
    results.addAll(_jkl14(houses));
    final j15 = _jkl15(houses);
    if (j15 != null) results.add(j15);
    final j16 = _jkl16(r, houses, lagnaRashi);
    if (j16 != null) results.add(j16);
    final j17 = _jkl17(houses);
    if (j17 != null) results.add(j17);
    results.addAll(_jkl27(r, houses));
    results.addAll(_jkl28(houses));

    return results;
  }

  /// Run HOUSE-BASED yogas only (for divisional charts — no longitude needed)
  static List<YogaResult> _evaluateHouseYogas(Map<String, int> houses, int lagnaRashi, String chart) {
    final results = <YogaResult>[];

    // Nisheka yogas (house-based)
    final y1 = _yoga1(houses);
    if (y1 != null) results.add(y1);
    final y2 = _yoga2(houses);
    if (y2 != null) results.add(y2);
    final y4 = _yoga4(houses);
    if (y4 != null) results.add(y4);
    final y5 = _yoga5(houses);
    if (y5 != null) results.add(y5);
    final y6 = _yoga6(houses);
    if (y6 != null) results.add(y6);
    final y7 = _yoga7(houses);
    if (y7 != null) results.add(y7);
    final y10 = _yoga10(houses);
    if (y10 != null) results.add(y10);

    // JKL yogas (house-based)
    final j4 = _jkl4(houses, lagnaRashi);
    if (j4 != null) results.add(j4);
    results.addAll(_jkl11(houses));
    results.addAll(_jkl13(houses));
    results.addAll(_jkl14(houses));
    final j15 = _jkl15(houses);
    if (j15 != null) results.add(j15);
    final j17 = _jkl17(houses);
    if (j17 != null) results.add(j17);
    results.addAll(_jkl28(houses));

    // Tag all results with chart name
    return results.map((y) => YogaResult(name: y.name, shloka: y.shloka, chart: chart)).toList();
  }

  // ═══════════════════════════════════════════
  // YOGA 1: Kuja-Chandra mutual kendra/trikona or Kuja drishti on Chandra
  // ═══════════════════════════════════════════
  static YogaResult? _yoga1(Map<String, int> houses) {
    final hKuja = houses['ಕುಜ'];
    final hChandra = houses['ಚಂದ್ರ'];
    if (hKuja == null || hChandra == null) return null;

    final satisfied = _mutualKendra(hKuja, hChandra) ||
        _mutualTrikona(hKuja, hChandra) ||
        _aspects('ಕುಜ', hKuja, hChandra);

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಕುಜ-ಚಂದ್ರ ಯೋಗ',
      shloka: 'ಕುಜೇಂದುಹೇತು ಪ್ರತಿಮಾಸಮಾರ್ತವಂ ಗತೇ ತು ಪೀಡರ್ಕ್ಷಮನುಷ್ಣದೀಧಿತೌ ।\nಅತೋsನ್ಯಥಾಸ್ಥ ಶುಭಪುಂಗ್ರಹೇಕ್ಷಿತೇ ನರೇಣ ಸಂಯೋಗಮುಪೈತಿ ಕಾಮಿನೀ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 2: Shubha & Papa both influence lagna
  // ═══════════════════════════════════════════
  static YogaResult? _yoga2(Map<String, int> houses) {
    final hasShubha = _anyShubhaInHouse(houses, 1) || _anyShubhaAspects(houses, 1);
    final hasPapa = _anyPapaInHouse(houses, 1) || _anyPapaAspects(houses, 1);

    if (!(hasShubha && hasPapa)) return null;
    return YogaResult(
      name: 'ಶುಭ-ಪಾಪ ಮಿಶ್ರ ಯೋಗ',
      shloka: 'ಅಸದ್ಗ್ರಹಾಲೋಕಿತಸಂಯುತೇsಸ್ತೇ ಸರೋಷ ಇಷ್ಟೆ ಸವಿಲಾಸಹಾಸಃ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 3: Ravi/Chandra/Kuja in own sign OR Guru in trikona
  // ═══════════════════════════════════════════
  static YogaResult? _yoga3(KundaliResult r, Map<String, int> houses) {
    bool satisfied = false;

    // Check Ravi, Chandra, Kuja in own sign
    for (final p in ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ']) {
      final info = r.planets[p];
      if (info == null) continue;
      final rashi = _rashiOf(info.longitude);
      if (_ownSigns[p]?.contains(rashi) ?? false) {
        satisfied = true;
        break;
      }
    }

    // Or Guru in trikona (houses 1, 5, 9)
    final hGuru = houses['ಗುರು'];
    if (hGuru != null && [1, 5, 9].contains(hGuru)) {
      satisfied = true;
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಸಂತಾನ ಯೋಗ',
      shloka: 'ರವೀಂದುಶುಕ್ರಾವನಿಜೈಃ ಸ್ವಭಾಗಗೈರ್ಗುರೌ ತ್ರಿಕೋಣೋದಯಧರ್ಮಗೇsಪಿ ವಾ ।\nಭವತ್ಯಪತ್ಯಂ ಹಿ ವಿಬೀಜಿನಾಮಿಮೇ ಕರಾ ಹಿಮಾಂಶೋರ್ವಿದೃಶಾಮಿವಾಫಲಾಃ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 4: Ravi/Chandra in 7th with Kuja/Shani drishti
  //         OR in 12th/2nd with Kuja/Shani drishti
  // ═══════════════════════════════════════════
  static YogaResult? _yoga4(Map<String, int> houses) {
    bool satisfied = false;

    for (final p in ['ರವಿ', 'ಚಂದ್ರ']) {
      final h = houses[p];
      if (h == null) continue;

      if (h == 7) {
        if (_planetAspectsHouse('ಕುಜ', houses, 7) || _planetAspectsHouse('ಶನಿ', houses, 7)) {
          satisfied = true;
        }
      }
      if (h == 12 || h == 2) {
        if (_planetAspectsHouse('ಕುಜ', houses, h) || _planetAspectsHouse('ಶನಿ', houses, h)) {
          satisfied = true;
        }
      }
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಗದ/ಮೃತ್ಯು ಯೋಗ',
      shloka: 'ದಿವಾಕರೇಂದ್ವಃ ಸ್ಮರಗೌ ಕುಜಾರ್ಕಚೌ ಗದಪ್ರದೌ ಪುಂಗಲಯೋಷಿತೋಸ್ತದಾ ।\nವ್ಯಯಸ್ವಗೌ ಮೃತ್ಯುಕರೌ ತಥಾ ಯುತೌ ತದೇಕದೃಷ್ಟಾ ಮರಣಾಯ ಕಲ್ಪಿತೌ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 5: Papa in lagna, no shubha drishti on lagna
  // ═══════════════════════════════════════════
  static YogaResult? _yoga5(Map<String, int> houses) {
    final papaInLagna = _anyPapaInHouse(houses, 1);
    final shubhaSees = _anyShubhaAspects(houses, 1) || _anyShubhaInHouse(houses, 1);

    if (!(papaInLagna && !shubhaSees)) return null;
    return YogaResult(
      name: 'ಪಾಪ ಲಗ್ನ ಯೋಗ',
      shloka: 'ಅಭಿಲಷದ್ಧಿರುದಯರ್ಕ್ಷಮಸದ್ಧಿರ್ಮರಣಮೇತಿ ಶುಭದೃಷ್ಟಿಮಯಾತೇ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 6: Shani in lagna + Chandra & Kuja aspect lagna
  // ═══════════════════════════════════════════
  static YogaResult? _yoga6(Map<String, int> houses) {
    final shaniInLagna = houses['ಶನಿ'] == 1;
    final chandraSees = _planetAspectsHouse('ಚಂದ್ರ', houses, 1);
    final kujaSees = _planetAspectsHouse('ಕುಜ', houses, 1);

    if (!(shaniInLagna && chandraSees && kujaSees)) return null;
    return YogaResult(
      name: 'ಶನಿ-ಚಂದ್ರ-ಕುಜ ಲಗ್ನ ಯೋಗ',
      shloka: 'ಉದಯರಾಶಿಸಹಿತೇ ಚ ಯಮೇ ಸ್ತ್ರೀ ವಿಗಲಿತೋಡುಪತಿಭೂಸುತದೃಷ್ಟೇ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 7: Papakartari — lagna or Chandra between papa grahas
  // ═══════════════════════════════════════════
  static YogaResult? _yoga7(Map<String, int> houses) {
    bool papakartari(int targetH) {
      final prev = ((targetH - 1 - 1 + 12) % 12) + 1; // house before
      final next = ((targetH - 1 + 1) % 12) + 1; // house after
      return _anyPapaInHouse(houses, prev) && _anyPapaInHouse(houses, next);
    }

    // Check lagna
    if (papakartari(1)) {
      return YogaResult(
        name: 'ಪಾಪಕರ್ತರಿ ಯೋಗ',
        shloka: 'ಅಶುಭದ್ವಯಮಧ್ಯಸಂಸ್ಥಿತೌ ಲಗ್ನೆoದೂ ನ ಚ ಸೌಮ್ಯವೀಕ್ಷಿತೌ ।\nಯುಗಪತ್ ಪೃಥಗೇವ ವಾ ವದೇನ್ನಾರೀ ಗರ್ಭಯುತಾ ವಿಪದ್ಯತೇ',
      );
    }
    // Check Chandra
    final hChandra = houses['ಚಂದ್ರ'];
    if (hChandra != null && papakartari(hChandra)) {
      return YogaResult(
        name: 'ಪಾಪಕರ್ತರಿ ಯೋಗ',
        shloka: 'ಅಶುಭದ್ವಯಮಧ್ಯಸಂಸ್ಥಿತೌ ಲಗ್ನೆoದೂ ನ ಚ ಸೌಮ್ಯವೀಕ್ಷಿತೌ ।\nಯುಗಪತ್ ಪೃಥಗೇವ ವಾ ವದೇನ್ನಾರೀ ಗರ್ಭಯುತಾ ವಿಪದ್ಯತೇ',
      );
    }
    return null;
  }

  // ═══════════════════════════════════════════
  // YOGA 9: Kuja in 4th/8th from lagna/Chandra
  //         OR Kuja+Surya in 4th & 12th with waning Chandra
  // ═══════════════════════════════════════════
  static YogaResult? _yoga9(KundaliResult r, Map<String, int> houses) {
    final hKuja = houses['ಕುಜ'];
    final hChandra = houses['ಚಂದ್ರ'];
    if (hKuja == null) return null;
    bool satisfied = false;

    // Kuja in 4th or 8th from lagna
    if (hKuja == 4 || hKuja == 8) satisfied = true;

    // Kuja in 4th or 8th from Chandra
    if (hChandra != null) {
      final fromMoon = ((hKuja - hChandra + 12) % 12) + 1;
      if (fromMoon == 4 || fromMoon == 8) satisfied = true;
    }

    // Kuja+Surya in 4th & 12th with waning Chandra
    final hSurya = houses['ರವಿ'];
    if (hSurya != null && hChandra != null) {
      final moonLon = r.planets['ಚಂದ್ರ']!.longitude;
      final sunLon = r.planets['ರವಿ']!.longitude;
      if (_isChandraWaning(moonLon, sunLon)) {
        if ((hKuja == 4 && hSurya == 12) || (hKuja == 12 && hSurya == 4)) {
          satisfied = true;
        }
      }
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಗರ್ಭ ಪೀಡಾ ಯೋಗ',
      shloka: 'ಶಶಿನಶ್ಚತುರ್ಥಗೇ ಲಗ್ನಾದ್ವಾ ನಿಧನಾಶ್ರಿತೇ ಕುಚೇ ।\nಬಂಧಂತ್ಯಗಯೋ ಕುಜಾರ್ಕಯೋಃ ಕ್ಷೀಣೇಂದೌ ನಿಧನಾಯ ಪೂರ್ವವತ್',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 10: Kuja & Surya in 1st and 7th houses
  // ═══════════════════════════════════════════
  static YogaResult? _yoga10(Map<String, int> houses) {
    final hKuja = houses['ಕುಜ'];
    final hSurya = houses['ರವಿ'];
    if (hKuja == null || hSurya == null) return null;

    final satisfied = (hKuja == 1 && hSurya == 7) || (hKuja == 7 && hSurya == 1);

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಶಸ್ತ್ರ ಮರಣ ಯೋಗ',
      shloka: 'ಉದಯಾಸ್ತಗಯೋಃ ಕುಚಾರ್ಕಯೋರ್ನಿಧನಂ ಶಸ್ತ್ರಕೃತಂ ವದೇತ್ತದಾ ।\nಮಾಸಾಧಿಪತೌ ನಿಪೀಡಿತೇ ತತ್ಕಾಲೇ ಸ್ರವಣಂ ಸಮಾದಿಶೇತ್',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 11: Three SEPARATE conditions (not combined)
  //   11a: Shubha in 5,9,2,4,10 from lagna/Chandra + papa in 3,11
  //   11b: Surya drishti on lagna
  //   11c: Guru drishti on lagna
  // ═══════════════════════════════════════════
  static List<YogaResult> _yoga11(KundaliResult r, Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ಶಶಾಂಕಲಗೋಪಗತೈ: ಶುಭಗ್ರಹೈಸ್ತಿಕೋಣಚಾಯಾರ್ಥಸುಖಾಸ್ಪದಸ್ಥಿತೈಃ ।\nತೃತೀಯಲಾಭರ್ಕ್ಷಗತೈರಶೋಭನೈ: ಸುಖೀ ಚ ಗರ್ಭೋ ರವಿಣಾಭಿವೀಕ್ಷಿತಃ';

    // ── Condition 11a: shubha in 5,9,2,4,10 AND papa in 3,11 ──
    bool shubhaOk = false;
    bool papaOk = false;

    for (final h in [5, 9, 2, 4, 10]) {
      if (_anyShubhaInHouse(houses, h)) { shubhaOk = true; break; }
    }
    for (final h in [3, 11]) {
      if (_anyPapaInHouse(houses, h)) { papaOk = true; break; }
    }

    // Also check from Chandra
    final hChandra = houses['ಚಂದ್ರ'];
    if (hChandra != null) {
      for (final offset in [4, 8, 1, 3, 9]) { // 5,9,2,4,10 from Chandra
        final h = ((hChandra - 1 + offset) % 12) + 1;
        if (_anyShubhaInHouse(houses, h)) { shubhaOk = true; break; }
      }
      for (final offset in [2, 10]) { // 3,11 from Chandra
        final h = ((hChandra - 1 + offset) % 12) + 1;
        if (_anyPapaInHouse(houses, h)) { papaOk = true; break; }
      }
    }

    if (shubhaOk && papaOk) {
      results.add(YogaResult(
        name: 'ಗರ್ಭ ಸುಖ ಯೋಗ',
        shloka: shloka,
      ));
    }

    // ── Condition 11b: Surya drishti on lagna ──
    final suryaSees = _planetAspectsHouse('ರವಿ', houses, 1) || houses['ರವಿ'] == 1;
    if (suryaSees) {
      results.add(YogaResult(
        name: 'ಗರ್ಭ ಸುಖ ಯೋಗ (ಸೂರ್ಯ ದೃಷ್ಟಿ)',
        shloka: '$shloka\nಸೂರ್ಯನ ದೃಷ್ಟಿಯಿದ್ದರೆ ಗರ್ಭವು ಸುಖಕರವಾಗಿರುತ್ತದೆ',
      ));
    }

    // ── Condition 11c: Guru drishti on lagna ──
    final guruSees = _planetAspectsHouse('ಗುರು', houses, 1) || houses['ಗುರು'] == 1;
    if (guruSees) {
      results.add(YogaResult(
        name: 'ಗರ್ಭ ಸುಖ ಯೋಗ (ಗುರು ದೃಷ್ಟಿ)',
        shloka: '$shloka\nಗುರುವಿನ ದೃಷ್ಟಿಯಿದ್ದರೆ ಗರ್ಭವು ಸುಖಕರವಾಗಿರುತ್ತದೆ',
      ));
    }

    return results;
  }

  // ═══════════════════════════════════════════
  // YOGA 17: Weak papa in trikona + Chandra in Vrishabha with papa drishti
  // ═══════════════════════════════════════════
  static YogaResult? _yoga17(KundaliResult r, Map<String, int> houses) {
    // Papa grahas in trikona (1, 5, 9)
    bool papaInTrikona = false;
    for (final e in houses.entries) {
      if (_isPapa(e.key) && [1, 5, 9].contains(e.value)) {
        papaInTrikona = true;
        break;
      }
    }

    // Chandra in Vrishabha (rashi index 1) with papa drishti
    final moonInfo = r.planets['ಚಂದ್ರ'];
    if (moonInfo == null) return null;
    final moonRashi = _rashiOf(moonInfo.longitude);
    final moonInVrishabha = moonRashi == 1;

    final hChandra = houses['ಚಂದ್ರ']!;
    bool papaSeesMoon = false;
    for (final e in houses.entries) {
      if (_isPapa(e.key) && e.key != 'ಚಂದ್ರ' && _aspects(e.key, e.value, hChandra)) {
        papaSeesMoon = true;
        break;
      }
    }

    if (!(papaInTrikona && moonInVrishabha && papaSeesMoon)) return null;
    return YogaResult(
      name: 'ವಾಕ್ ದೋಷ ಯೋಗ',
      shloka: 'ತ್ರಿಕೋಣಗೇ ವಿಬಲೈಸ್ತತೋಽಪರೈರ್ಮುಖಾಂಫ್ರಿಹಸೊರ್ದ್ವಿಗುಣಸ್ತದಾ ಭವೇತ್ ।\nಅವಾಗ್ಗವೀಂದಾವಶುಭೈರ್ಭಸಂಧಿಗೈ: ಶುಭೇಕ್ಷಿತೇ ಚೇತ್ಕುರುತೇ ಗಿರಂ ಚಿರಾತ್',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 18: Various deformity yogas
  // ═══════════════════════════════════════════
  static YogaResult? _yoga18(KundaliResult r, Map<String, int> houses, int lagnaRashi, double lagnaLon) {
    bool satisfied = false;

    // 1. Shani & Kuja in Budha's navamsha (Mithuna=2 or Kanya=5)
    final shaniInfo = r.planets['ಶನಿ'];
    final kujaInfo = r.planets['ಕುಜ'];
    if (shaniInfo != null && kujaInfo != null) {
      final shaniNav = _navamshaRashi(shaniInfo.longitude);
      final kujaNav = _navamshaRashi(kujaInfo.longitude);
      if ([2, 5].contains(shaniNav) && [2, 5].contains(kujaNav)) {
        satisfied = true;
      }
    }

    // 2. Kataka lagna with Chandra + Shani/Kuja drishti
    if (lagnaRashi == 3) { // Kataka
      final moonInLagna = houses['ಚಂದ್ರ'] == 1;
      final shaniSees = _planetAspectsHouse('ಶನಿ', houses, 1) || houses['ಶನಿ'] == 1;
      final kujaSees = _planetAspectsHouse('ಕುಜ', houses, 1) || houses['ಕುಜ'] == 1;
      if (moonInLagna && shaniSees && kujaSees) satisfied = true;
    }

    // 3. Meena lagna with Shani/Chandra/Kuja drishti
    if (lagnaRashi == 11) { // Meena
      final shaniSees = _planetAspectsHouse('ಶನಿ', houses, 1) || houses['ಶನಿ'] == 1;
      final chandraSees = _planetAspectsHouse('ಚಂದ್ರ', houses, 1) || houses['ಚಂದ್ರ'] == 1;
      final kujaSees = _planetAspectsHouse('ಕುಜ', houses, 1) || houses['ಕುಜ'] == 1;
      if (shaniSees && chandraSees && kujaSees) satisfied = true;
    }

    // 4. Chandra + papa in lagna sandhi, no shubha drishti
    if (r.planets['ಚಂದ್ರ'] != null) {
      final moonDeg = r.planets['ಚಂದ್ರ']!.longitude % 30;
      final inSandhi = moonDeg < 1.0 || moonDeg > 29.0;
      final moonInLagna = houses['ಚಂದ್ರ'] == 1;
      final papaInLagna = _anyPapaInHouse(houses, 1);
      final noShubha = !_anyShubhaAspects(houses, 1);
      if (inSandhi && moonInLagna && papaInLagna && noShubha) satisfied = true;
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಅಂಗ ದೋಷ ಯೋಗ',
      shloka: 'ಸೌಮ್ಯರ್ಕ್ಷಾಂಶೇ ರವಿಜರುಧಿರೌ ಚೇತ್ಸದಂತೋsತ್ರ ಜಾತಃ\nಕುಬ್ಬಃ ಸ್ವರ್ಕ್ಷೆ ಶಶಿನಿ ತನುಗೇ ಮಂದಮಾಹೇಯದೃಷ್ಟೇ ।\nಪಂಗುರ್ಮೀನೇ ಯಮಶಶಿಕುಜೈರ್ವೀಕ್ಷಿತೇ ಲಗ್ನಸಂಸ್ಥೆ\nಸಂಧೇ ಪಾಪೇ ಶಶಿನಿ ಚ ಜಡಃ ಸ್ಯಾನ್ನ ಚೇತೌಮ್ಯದೃಷ್ಟಿ:',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 19: Makara end lagna + Shani/Chandra/Surya drishti
  //          OR papa in drekkanas of 1,5,9
  // ═══════════════════════════════════════════
  static YogaResult? _yoga19(KundaliResult r, Map<String, int> houses, int lagnaRashi, double lagnaLon) {
    bool satisfied = false;

    // Makara end as lagna (last 10° of Makara = 3rd drekkana)
    if (lagnaRashi == 9) { // Makara
      final lagDeg = lagnaLon % 30;
      if (lagDeg >= 20.0) {
        final shaniSees = _planetAspectsHouse('ಶನಿ', houses, 1) || houses['ಶನಿ'] == 1;
        final chandraSees = _planetAspectsHouse('ಚಂದ್ರ', houses, 1) || houses['ಚಂದ್ರ'] == 1;
        final suryaSees = _planetAspectsHouse('ರವಿ', houses, 1) || houses['ರವಿ'] == 1;
        if (shaniSees && chandraSees && suryaSees) satisfied = true;
      }
    }

    // Papa in drekkanas of houses 1, 5, 9
    for (final h in [1, 5, 9]) {
      for (final e in houses.entries) {
        if (_isPapa(e.key) && e.value == h) {
          satisfied = true;
          break;
        }
      }
      if (satisfied) break;
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ವಾಮನ/ಅಂಗಹೀನ ಯೋಗ',
      shloka: 'ಸೌರಶಶಾಂಕದಿವಾಕರದೃಷ್ಟೇ ವಾಮನಕೋ ಮಕರಾಂತ್ಯವಿಲಗ್ನ ।\nಧೀನವಮೋದಯಗೈಶ್ಚ ದೃಗಾಣೈ: ಪಾಪಯುತೈರಭುಜಾಂಘಿಶಿರಾಃ ಸ್ಯಾತ್',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 20: Simha lagna with Ravi+Chandra + Kuja/Shani drishti
  //          OR Chandra/Surya in 12th
  // ═══════════════════════════════════════════
  static YogaResult? _yoga20(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    bool satisfied = false;

    // Simha lagna with Ravi+Chandra and Kuja/Shani drishti
    if (lagnaRashi == 4) { // Simha
      final raviInLagna = houses['ರವಿ'] == 1;
      final chandraInLagna = houses['ಚಂದ್ರ'] == 1;
      if (raviInLagna && chandraInLagna) {
        final kujaSees = _planetAspectsHouse('ಕುಜ', houses, 1) || houses['ಕುಜ'] == 1;
        final shaniSees = _planetAspectsHouse('ಶನಿ', houses, 1) || houses['ಶನಿ'] == 1;
        if (kujaSees && shaniSees) satisfied = true;
      }
    }

    // Chandra in 12th or Surya in 12th
    if (houses['ಚಂದ್ರ'] == 12 || houses['ರವಿ'] == 12) {
      satisfied = true;
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ನೇತ್ರ ದೋಷ ಯೋಗ',
      shloka: 'ರವಿಶಶಿಯುತೇ ಸಿಂಹೇ ಲಗ್ನ ಕುಜಾರ್ಕಿನಿರೀಕ್ಷಿತೇ ನಯನರಹಿತಃ\nಸೌಮ್ಯಾಸೌಮ್ಯ: ಸಬುದ್ದುದಲೋಚನಃ ।\nವ್ಯಯಗೃಹಗತಶ್ಚಂದ್ರೋ ವಾಮಂ ಒನಸ್ತ್ರಪರಂ ರವಿ-\nಸ್ವಶುಭಗದಿತಾ ಯೋಗಾ ಯಾಪ್ಯಾ ಭವಂತಿ ಶುಭೇಕ್ಷಿತಾಃ',
    );
  }

  // ═══════════════════════════════════════════
  // YOGA 22: Shani/Chandra navamsha as lagna + in 7th
  // ═══════════════════════════════════════════
  static YogaResult? _yoga22(KundaliResult r, Map<String, int> houses, double lagnaLon) {
    bool satisfied = false;
    final lagnaNav = _navamshaRashi(lagnaLon);

    // Shani's navamsha is lagna + Shani in 7th
    if ([9, 10].contains(lagnaNav) && houses['ಶನಿ'] == 7) {
      satisfied = true;
    }

    // Chandra's navamsha is lagna + Chandra in 7th
    if (lagnaNav == 3 && houses['ಚಂದ್ರ'] == 7) {
      satisfied = true;
    }

    if (!satisfied) return null;
    return YogaResult(
      name: 'ಪ್ರಸವ ಯೋಗ',
      shloka: 'ಉದಯತಿ ಮೃದುಭಾಂಶೇ ಸಪ್ತಮಸೇ ಚ ಮಂದೇ\nಯದಿ ಭವತಿ ನಿಷೇಕಃ ಸೂತಿರಬತ್ರಯೇಣ ।\nಶಶಿನಿ ತು ವಿಧಿರೇವಂ ದ್ವಾದಶಾದ್ದೇ ಪ್ರಕುರ್ಯಾ-\nನ್ನಿಗದಿತಮಿಹ ಚಿಂತ್ಯಂ ಸೂತಿಕಾಲೇsಪಿ ಯುಕ್ತಾ',
    );
  }

  // ╔═══════════════════════════════════════════╗
  // ║  ಜನ್ಮಕಾಲಲಕ್ಷಣಾಧ್ಯಾಯ (Chapter 5)        ║
  // ╚═══════════════════════════════════════════╝

  // ── JKL 1: Father absent at birth ──
  static List<YogaResult> _jkl1(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    final results = <YogaResult>[];
    const shloka = 'ಪಿತುರ್ಜಾತಃ ಪರೋಕ್ಷಸ್ಯ ಲಗ್ನಮಿಂದಾವಪಶ್ಯತಿ ।\nವಿದೇಶಸ್ಥಸ್ಯ ಚರಭೇ ಮಧ್ಯಾದ್ ಭ್ರಷ್ಟೇ ದಿವಾಕರೇ\nಉದಯಸ್ಥsಪಿ ವಾ ಮಂದೇ ಕುಜೇ ವಾಸ್ತಂ ಸಮಾಗತೇ ।\nಸ್ಥಿತೇ ವಾಂತಃ ಕ್ಷಪಾನಾಥೇ ಶಶಾಂಕಸುತಶುಕ್ರಯೋಃ';
    final hC = houses['ಚಂದ್ರ'];
    // Chandra doesn't aspect lagna
    if (hC != null && !_aspects('ಚಂದ್ರ', hC, 1) && hC != 1) {
      String d = 'ಚಂದ್ರನು ಲಗ್ನವನ್ನು ನೋಡುತ್ತಿಲ್ಲ — ತಂದೆ ಪರೋಕ್ಷ';
      if (_isChara(lagnaRashi)) d += '\nಚರ ಲಗ್ನ — ತಂದೆ ವಿದೇಶದಲ್ಲಿ';
      final hS = houses['ರವಿ'];
      if (hS != null && hS >= 8) d += '\nಸೂರ್ಯ ${hS}ನೇ ಮನೆ — ತಂದೆ ಊರಲ್ಲೇ ಬೇರೆಡೆ';
      results.add(YogaResult(name: 'ಪಿತೃ ಪರೋಕ್ಷ ಯೋಗ', shloka: '$shloka\n$d'));
    }
    // Shani in lagna + Kuja in 7th
    if (houses['ಶನಿ'] == 1 && houses['ಕುಜ'] == 7) {
      results.add(YogaResult(name: 'ಪಿತೃ ಪರೋಕ್ಷ ಯೋಗ', shloka: '$shloka\nಶನಿ ಲಗ್ನ + ಕುಜ ೭ — ತಂದೆ ಪರೋಕ್ಷ'));
    }
    // Chandra between Budha and Shukra
    if (hC != null && houses['ಬುಧ'] != null && houses['ಶುಕ್ರ'] != null) {
      if (_houseBetween(hC, houses['ಬುಧ']!, houses['ಶುಕ್ರ']!)) {
        results.add(YogaResult(name: 'ಪಿತೃ ಪರೋಕ್ಷ ಯೋಗ', shloka: '$shloka\nಚಂದ್ರ ಬುಧ-ಶುಕ್ರರ ಮಧ್ಯೆ — ತಂದೆ ಪರೋಕ್ಷ'));
      }
    }
    return results;
  }

  // ── JKL 2: Snake-wrapped birth ──
  static YogaResult? _jkl2(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    const shloka = 'ಶಶಾಂಕೇ ಪಾಪ ಲಗ್ನೇ ವಾ ವೃಶ್ಚಿಕೇಶತ್ರಿಭಾಗಗೇ ।\nಶುಭೈಃ ಸ್ವಾಯಸ್ಥಿತೈರ್ಜಾತಃ ಸರ್ಪಸ್ತದ್ವೇಷ್ಟಿತೋsಪಿ ವಾ';
    // Lagna or Chandra in papa rashi + Vrischika drekkana + shubha in 2/11
    final moonInfo = r.planets['ಚಂದ್ರ'];
    bool inPapaRashi = _isPapaRashi(lagnaRashi);
    if (moonInfo != null) inPapaRashi = inPapaRashi || _isPapaRashi(_rashiOf(moonInfo.longitude));
    if (!inPapaRashi) return null;
    // Check Vrischika drekkana (7) for lagna or moon
    final lagnaLon = r.planets['ಲಗ್ನ']?.longitude ?? (r.bhavas.isNotEmpty ? r.bhavas[0] : 0.0);
    bool vrischikaDrekk = _drekkanaRashi(lagnaLon) == 7;
    if (moonInfo != null) vrischikaDrekk = vrischikaDrekk || _drekkanaRashi(moonInfo.longitude) == 7;
    if (!vrischikaDrekk) return null;
    // Shubha in 2nd or 11th
    if (!(_anyShubhaInHouse(houses, 2) || _anyShubhaInHouse(houses, 11))) return null;
    return YogaResult(name: 'ಸರ್ಪ ವೇಷ್ಟಿತ ಯೋಗ', shloka: shloka);
  }

  // ── JKL 3: Twin birth ──
  static YogaResult? _jkl3(KundaliResult r, Map<String, int> houses) {
    const shloka = 'ಚತುಷ್ಪದಗತೇ ಭಾನೌ ಶೇಷೈರ್ವೀರ್ಯಸಮನ್ವಿತೈಃ ।\nದ್ವಿತನು ಸ್ಥೈ ಶ್ಚ ಯಮಲೌ ಭವತಃ ಕೋಶವೇಷ್ಟಿ ತೌ';
    final sunInfo = r.planets['ರವಿ'];
    if (sunInfo == null) return null;
    if (!_isChatushpada(_rashiOf(sunInfo.longitude))) return null;
    // Check if remaining planets are in dwiswabhava rashis
    int dwiCount = 0;
    for (final e in r.planets.entries) {
      if (e.key == 'ರವಿ' || e.key == 'ಲಗ್ನ' || e.key == 'ಮಾಂದಿ') continue;
      if (_isDwiswabhava(_rashiOf(e.value.longitude))) dwiCount++;
    }
    if (dwiCount < 3) return null; // At least 3 others in dwiswabhava
    return YogaResult(name: 'ಯಮಳ (ಅವಳಿ) ಯೋಗ', shloka: shloka);
  }

  // ── JKL 4: Umbilical cord wrapped ──
  static YogaResult? _jkl4(Map<String, int> houses, int lagnaRashi) {
    const shloka = 'ಛಾಗಸಿಂಹವೃಷೇ ಲಗ್ನೆ ತತ್ಸ್ಥೆ ಸೌರೇಽಥವಾ ಕುಜೇ ।\nರಾಶ್ಯಂಶಸದೃಶೇ ಗಾತ್ರೇ ಜಾಯತೇ ನಾಲವೇಷ್ಟಿತಃ';
    // Mesha(0), Simha(4), Vrishabha(1) lagna + Kuja/Shani in lagna
    if (![0, 4, 1].contains(lagnaRashi)) return null;
    if (houses['ಕುಜ'] != 1 && houses['ಶನಿ'] != 1) return null;
    return YogaResult(name: 'ನಾಲ ವೇಷ್ಟಿತ ಯೋಗ', shloka: shloka);
  }

  // ── JKL 6: Father imprisoned ──
  static List<YogaResult> _jkl6(KundaliResult r, Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ಕ್ರೂರರ್ಕ್ಷಗತಾವಶೋಭನೌ ಸೂರ್ಯಾತ್ ದ್ಯೋನನವಾತ್ಮಜಸ್ಥಿತೌ ।\nಬದ್ಧಸ್ತು ಪಿತಾ ವಿದೇಶಗಃ ಸ್ಟೇ ವಾ ರಾಶಿವಶಾತ್ತಥಾ ಪಥಿ';
    final hSurya = houses['ರವಿ'];
    if (hSurya == null) return results;
    // Papa in 5th, 7th, 9th from Surya
    bool papaIn579 = false;
    for (final offset in [4, 6, 8]) { // 5th=+4, 7th=+6, 9th=+8
      final h = ((hSurya - 1 + offset) % 12) + 1;
      if (_anyPapaInHouse(houses, h)) { papaIn579 = true; break; }
    }
    if (!papaIn579) return results;
    final sunRashi = _rashiOf(r.planets['ರವಿ']!.longitude);
    String detail;
    if (_isChara(sunRashi)) detail = 'ಚರ ರಾಶಿ — ದಾರಿಯಲ್ಲಿ ಬಂಧನ';
    else if (_isSthira(sunRashi)) detail = 'ಸ್ಥಿರ ರಾಶಿ — ಊರಲ್ಲಿ ಬಂಧನ';
    else detail = 'ದ್ವಿಸ್ವಭಾವ ರಾಶಿ — ವಿದೇಶದಲ್ಲಿ ಬಂಧನ';
    results.add(YogaResult(name: 'ಪಿತೃ ಬಂಧನ ಯೋಗ', shloka: '$shloka\n$detail'));
    return results;
  }

  // ── JKL 7: Birth on ship ──
  static YogaResult? _jkl7(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    const shloka = 'ಪೂರ್ಣೇ ಶಶಿನಿ ಸ್ವರಾಶಿಗೇ ಸೌಮ್ಯೇ ಲಗ್ನಗತೇ ಶುಭೇ ಸುಖೇ ।\nಲಗ್ನೆ ಜಲಜೆsಸ್ತಗೇ ಪಿ ವಾ ಚಂದ್ರೇ ಪೋತಗತಾ ಪ್ರಸೂಯತೇ';
    final mI = r.planets['ಚಂದ್ರ'];
    final sI = r.planets['ರವಿ'];
    if (mI == null || sI == null) return null;
    // Full moon in Kataka + Budha in lagna + shubha in 4th
    if (_isFullMoon(mI.longitude, sI.longitude) && _rashiOf(mI.longitude) == 3 &&
        houses['ಬುಧ'] == 1 && _anyShubhaInHouse(houses, 4)) {
      return YogaResult(name: 'ಪೋತ (ಹಡಗು) ಜನನ ಯೋಗ', shloka: shloka);
    }
    // Jala lagna + Chandra in 7th
    if (_isJala(lagnaRashi) && houses['ಚಂದ್ರ'] == 7) {
      return YogaResult(name: 'ಪೋತ (ಹಡಗು) ಜನನ ಯೋಗ', shloka: shloka);
    }
    return null;
  }

  // ── JKL 8: Birth near water ──
  static YogaResult? _jkl8(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    const shloka = 'ಆಪ್ಯೊದಯಮಾಪ್ಯಗಃ ಶಶೀ ಸಂಪೂರ್ಣ: ಸಮವೇಕ್ಷತೇಥವಾ ।\nಮೇಶೂರಣಬಂಧುಲಗ್ನಗಃ ಸ್ಯಾತ್ಸೂತಿಃ ಸಲಿಲೇ ನ ಸಂಶಯಃ';
    final mI = r.planets['ಚಂದ್ರ'];
    final sI = r.planets['ರವಿ'];
    if (mI == null) return null;
    // Jala lagna + Chandra in it
    if (_isJala(lagnaRashi) && houses['ಚಂದ್ರ'] == 1) {
      return YogaResult(name: 'ಜಲ ಸಮೀಪ ಜನನ ಯೋಗ', shloka: shloka);
    }
    // Full Chandra aspects jala lagna
    if (sI != null && _isJala(lagnaRashi) && _isFullMoon(mI.longitude, sI.longitude)) {
      final hC = houses['ಚಂದ್ರ'];
      if (hC != null && (_aspects('ಚಂದ್ರ', hC, 1) || hC == 1)) {
        return YogaResult(name: 'ಜಲ ಸಮೀಪ ಜನನ ಯೋಗ', shloka: shloka);
      }
    }
    // Chandra in 10th, 4th, or 1st
    final hC = houses['ಚಂದ್ರ'];
    if (hC != null && [1, 4, 10].contains(hC)) {
      return YogaResult(name: 'ಜಲ ಸಮೀಪ ಜನನ ಯೋಗ', shloka: shloka);
    }
    return null;
  }

  // ── JKL 9: Birth in secret/pit ──
  static YogaResult? _jkl9(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    const shloka = 'ಉದಯೋಡುಪಯೋರ್ವ್ಯಯಸ್ಥಿತೇ ಗುಪ್ತ್ಯಾಂ ಪಾಪನಿರೀಕ್ಷಿತೇ ಯಮೇ ।\nಅಲಿಕರ್ಕಿಯುತೇ ವಿಲಗ್ನಗೇ ಸೌರೇ ಶೀತಕರೇಕ್ಷಿತೇ ವಟೇ';
    // Shani in 12th from lagna AND Chandra + papa drishti
    final hShani = houses['ಶನಿ'];
    final hC = houses['ಚಂದ್ರ'];
    if (hShani == 12 && hC != null) {
      // 12th from Chandra also has Shani?
      final from_moon_12 = ((hC - 1 + 11) % 12) + 1;
      if (hShani == 12 || hShani == from_moon_12) {
        if (_anyPapaAspects(houses, hShani!)) {
          return YogaResult(name: 'ಗುಪ್ತ ಸ್ಥಳ ಜನನ ಯೋಗ', shloka: '$shloka\nಶನಿ ೧೨ರಲ್ಲಿ + ಪಾಪ ದೃಷ್ಟಿ — ಗುಪ್ತ ಪ್ರದೇಶದಲ್ಲಿ ಜನನ');
        }
      }
    }
    // Vrischika/Kataka lagna + Shani in lagna + Chandra drishti
    if ([7, 3].contains(lagnaRashi) && houses['ಶನಿ'] == 1) {
      if (hC != null && (_aspects('ಚಂದ್ರ', hC, 1) || hC == 1)) {
        return YogaResult(name: 'ಗುಂಡಿ ಜನನ ಯೋಗ', shloka: '$shloka\nವೃಶ್ಚಿಕ/ಕಟಕ ಲಗ್ನ + ಶನಿ + ಚಂದ್ರ ದೃಷ್ಟಿ — ಗುಂಡಿಯಲ್ಲಿ ಜನನ');
      }
    }
    return null;
  }

  // ── JKL 10: Birth place by Shani in jala lagna ──
  static List<YogaResult> _jkl10(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    final results = <YogaResult>[];
    const shloka = 'ಮಂದೇsಬ್ಜಗತೇ ವಿಲಗ್ನಗೇ ಬುಧಸೂರ್ಯೇಂದುನಿರೀಕ್ಷಿತೇ ಕ್ರಮಾತ್ ।\nಕ್ರೀಡಾಭವನೇ ಸುರಾಲಯೇ ಪ್ರಸವಂ ಸೋಷರಭೂಮಿ ಷದ್ದಿಶೇತ್';
    if (!_isJala(lagnaRashi) || houses['ಶನಿ'] != 1) return results;
    if (_planetAspectsHouse('ಬುಧ', houses, 1) || houses['ಬುಧ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಕ್ರೀಡಾಂಗಣ', shloka: '$shloka\nಬುಧ ದೃಷ್ಟಿ — ಆಟದ ಮೈದಾನದಲ್ಲಿ ಜನನ'));
    }
    if (_planetAspectsHouse('ರವಿ', houses, 1) || houses['ರವಿ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ದೇವಾಲಯ', shloka: '$shloka\nಸೂರ್ಯ ದೃಷ್ಟಿ — ದೇವಸ್ಥಾನದಲ್ಲಿ ಜನನ'));
    }
    if (_planetAspectsHouse('ಚಂದ್ರ', houses, 1) || houses['ಚಂದ್ರ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಬಂಜರು ಭೂಮಿ', shloka: '$shloka\nಚಂದ್ರ ದೃಷ್ಟಿ — ಬಂಜರು ಭೂಮಿಯಲ್ಲಿ ಜನನ'));
    }
    return results;
  }

  // ── JKL 11: Birth place by planet aspecting lagna ──
  static List<YogaResult> _jkl11(Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ನೃಲಗ್ನಗಂ ಪ್ರೇಕ್ಷ್ಯ ಕುಜಃ ಸ್ಮಶಾನೇ ರಮ್ಯ ಸಿತೇಂದೂ ಗುರುರಗ್ನಿಹೋತ್ರೇ ।\nರವಿರ್ನರೇಂದ್ರಾಮರಗೋಕುಲೇಷು ಶಿಲ್ಪಾಲಯೇ ಜ್ಞಃ ಪ್ರಸವಂ ಕರೋತಿ';
    if (_planetAspectsHouse('ಕುಜ', houses, 1) || houses['ಕುಜ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಸ್ಮಶಾನ', shloka: '$shloka\nಕುಜ ದೃಷ್ಟಿ — ಸ್ಮಶಾನದಲ್ಲಿ ಜನನ'));
    }
    if (_planetAspectsHouse('ಶುಕ್ರ', houses, 1) || houses['ಶುಕ್ರ'] == 1 ||
        _planetAspectsHouse('ಚಂದ್ರ', houses, 1) || houses['ಚಂದ್ರ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ರಮ್ಯ ಸ್ಥಳ', shloka: '$shloka\nಶುಕ್ರ/ಚಂದ್ರ ದೃಷ್ಟಿ — ರಮ್ಯ ಸ್ಥಳದಲ್ಲಿ ಜನನ'));
    }
    if (_planetAspectsHouse('ಗುರು', houses, 1) || houses['ಗುರು'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಯಾಗಶಾಲೆ', shloka: '$shloka\nಗುರು ದೃಷ್ಟಿ — ಯಾಗಶಾಲೆಯಲ್ಲಿ ಜನನ'));
    }
    if (_planetAspectsHouse('ರವಿ', houses, 1) || houses['ರವಿ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ರಾಜಮಂದಿರ/ಗೋಶಾಲೆ', shloka: '$shloka\nಸೂರ್ಯ ದೃಷ್ಟಿ — ರಾಜಮಂದಿರ/ಗೋಶಾಲೆಯಲ್ಲಿ ಜನನ'));
    }
    if (_planetAspectsHouse('ಬುಧ', houses, 1) || houses['ಬುಧ'] == 1) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಶಿಲ್ಪಾಲಯ', shloka: '$shloka\nಬುಧ ದೃಷ್ಟಿ — ಶಿಲ್ಪಾಲಯದಲ್ಲಿ ಜನನ'));
    }
    return results;
  }

  // ── JKL 12: Birth place by lagna navamsha ──
  static List<YogaResult> _jkl12(double lagnaLon) {
    final results = <YogaResult>[];
    const shloka = 'ರಾಶ್ಯಂಶಸಮಾನಗೋಚರೇ ಮಾರ್ಗೇ ಜನ್ಮ ಚರೇ ಸ್ಥಿರೇ ಗೃಹೇ ।\nಸ್ವರ್ಕ್ಷಾಂಶಗತೇ ಸ್ವಮಂದಿರೇ ಬಲಯೋಗಾತ್ಛಲಮಂಶಕರ್ಕ್ಷಯೋ:';
    final navR = _navamshaRashi(lagnaLon);
    final lagR = _rashiOf(lagnaLon);
    if (_isChara(navR)) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಮಾರ್ಗ', shloka: '$shloka\nಚರ ನವಾಂಶ — ದಾರಿಯಲ್ಲಿ ಜನನ'));
    } else if (_isSthira(navR)) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಮನೆ', shloka: '$shloka\nಸ್ಥಿರ ನವಾಂಶ — ಮನೆಯಲ್ಲಿ ಜನನ'));
    }
    if (navR == lagR) {
      results.add(YogaResult(name: 'ಜನ್ಮಸ್ಥಳ — ಸ್ವಮನೆ', shloka: '$shloka\nಸ್ವರ್ಕ್ಷ ನವಾಂಶ — ಸ್ವಂತ ಮನೆಯಲ್ಲಿ ಜನನ'));
    }
    return results;
  }

  // ── JKL 13: Child abandoned + Guru saves ──
  static List<YogaResult> _jkl13(Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ಆರಾರ್ಕಜಯೋಸ್ತ್ರಿಕೋಣಗೇ ಚಂದ್ರೇsರ್ಕೇ ಚ ವಿಸೃಜ್ಯತೇsಂಬಯಾ ।\nದೃಷ್ಟೇಽಮರರಾಜಮಂತ್ರಿಣಾ ದೀರ್ಘಾಯುಃ ಸುಖಭಾಕ್ಚಸ ಸ್ಮೃತಃ';
    final hSurya = houses['ರವಿ'];
    final hKuja = houses['ಕುಜ'];
    if (hSurya == null || hKuja == null) return results;
    final suryaInTri = [1, 5, 9].contains(hSurya);
    final kujaInTri = [1, 5, 9].contains(hKuja);
    if (suryaInTri && kujaInTri) {
      results.add(YogaResult(name: 'ಮಾತೃ ತ್ಯಾಗ ಯೋಗ', shloka: '$shloka\nಸೂರ್ಯ+ಕುಜ ತ್ರಿಕೋಣದಲ್ಲಿ — ತಾಯಿ ಶಿಶುವನ್ನು ತ್ಯಜಿಸುತ್ತಾಳೆ'));
      // If Guru aspects lagna
      if (_planetAspectsHouse('ಗುರು', houses, 1) || houses['ಗುರು'] == 1) {
        results.add(YogaResult(name: 'ಗುರು ರಕ್ಷಣೆ ಯೋಗ', shloka: '$shloka\nಗುರು ದೃಷ್ಟಿ — ದೀರ್ಘಾಯುಷ್ಯ ಮತ್ತು ಸುಖ'));
      }
    }
    return results;
  }

  // ── JKL 14: Abandoned child's fate ──
  static List<YogaResult> _jkl14(Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ಪಾಪೇಕ್ಷಿತೇ ತುಹಿನಗಾವುದಯೇ ಕುಜೇsಸ್ತೇ ತ್ಯಕ್ತೊ ವಿನಶ್ಯತಿ\nಕುಜಾರ್ಕಜಯೋಸ್ತಥಾಯೇ ।\nಸೌಮ್ಮೇsಭಿಪಶ್ಯತಿ ತಥಾವಿಧಹಸ್ತಮೇತಿ\nಸೌಮ್ಯೇ ತರೇಯುಃ ಪರಹಸ್ತಗತೋsಪ್ಯನಾಯುಃ';
    // Papa drishti on Chandra/lagna + Kuja in 7th
    final papaOnLagna = _anyPapaAspects(houses, 1);
    final hC = houses['ಚಂದ್ರ'];
    final papaOnMoon = hC != null && _anyPapaAspects(houses, hC);
    final kujaIn7 = houses['ಕುಜ'] == 7;
    // Kuja + Shani in lagna
    final kujaShaniLagna = houses['ಕುಜ'] == 1 && houses['ಶನಿ'] == 1;
    if ((papaOnLagna || papaOnMoon) && (kujaIn7 || kujaShaniLagna)) {
      final shubhaSees = _anyShubhaAspects(houses, 1);
      if (shubhaSees) {
        results.add(YogaResult(name: 'ತ್ಯಕ್ತ ಶಿಶು — ಜೀವಿಸುವ', shloka: '$shloka\nಶುಭ ದೃಷ್ಟಿ — ಬೇರೆಯವರ ಕೈಗೆ ಸೇರಿ ಬದುಕುತ್ತದೆ'));
      } else {
        results.add(YogaResult(name: 'ತ್ಯಕ್ತ ಶಿಶು — ನಾಶ', shloka: '$shloka\nಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ — ತ್ಯಜಿಸಲ್ಪಟ್ಟು ನಾಶ'));
      }
    }
    return results;
  }

  // ── JKL 15: Lonely birth ──
  static YogaResult? _jkl15(Map<String, int> houses) {
    const shloka = 'ಯದಿ ನೈಕಗತೈಸ್ತು ವೀಕ್ಷಿತೌ ಲಗ್ನೇಂದೂ ವಿಜನೇ ಪ್ರಸೂಯತೇ';
    // No planet in lagna AND no planet aspects lagna
    bool anyInLagna = houses.values.any((h) => h == 1);
    if (anyInLagna) return null;
    bool anyAspectsLagna = false;
    for (final e in houses.entries) {
      if (_aspects(e.key, e.value, 1)) { anyAspectsLagna = true; break; }
    }
    if (anyAspectsLagna) return null;
    return YogaResult(name: 'ವಿಜನ ಸ್ಥಳ ಜನನ ಯೋಗ', shloka: '$shloka\nಯಾರೂ ಇಲ್ಲದ ಜಾಗದಲ್ಲಿ ಜನನ');
  }

  // ── JKL 16: Birth in darkness on ground ──
  static YogaResult? _jkl16(KundaliResult r, Map<String, int> houses, int lagnaRashi) {
    const shloka = 'ಮಂದರ್ಕ್ಷಾಂಶೇ ಶಶಿನಿ ಹಿಬುಕೇ ಮಂದದೃಷ್ಟೇsಬ್ಜಗೇ ವಾ\nತದ್ಯುಕ್ತೇ ವಾ ತಮಸಿ ಶಯನಂ ನೀಚಸಂಸ್ಥೈಶ್ಚ ಭೂಮೌ ।\nಯದ್ವದ್ರಾಶಿಃ ವ್ರಜತಿ ಹರಿಜಂ ಗರ್ಭಮೋಕ್ಷಸ್ತು ತದ್ವತ್';
    final mI = r.planets['ಚಂದ್ರ'];
    if (mI == null) return null;
    // Chandra in Shani's navamsha + 4th house + Shani drishti
    final moonNav = _navamshaRashi(mI.longitude);
    if ([9, 10].contains(moonNav) && houses['ಚಂದ್ರ'] == 4 &&
        (_planetAspectsHouse('ಶನಿ', houses, 4) || houses['ಶನಿ'] == 4)) {
      return YogaResult(name: 'ತಮಸ್ಸು ಜನನ ಯೋಗ', shloka: '$shloka\nಕತ್ತಲೆಯಲ್ಲಿ ನೆಲದ ಮೇಲೆ ಜನನ');
    }
    // Jala lagna + Shani conjunction
    if (_isJala(lagnaRashi) && houses['ಶನಿ'] == 1) {
      return YogaResult(name: 'ತಮಸ್ಸು ಜನನ ಯೋಗ', shloka: '$shloka\nಜಲ ಲಗ್ನ + ಶನಿ — ಕತ್ತಲೆಯಲ್ಲಿ ಜನನ');
    }
    return null;
  }

  // ── JKL 17: Mother's suffering ──
  static YogaResult? _jkl17(Map<String, int> houses) {
    const shloka = 'ಪಾಪೈಶ್ಚಂದ್ರಸ್ಮರಸುಖಗತೈಃ ಕ್ಲೇಶಮಾಹುರ್ಜನನ್ಯಾ:';
    final hC = houses['ಚಂದ್ರ'];
    // Papa in 7th and 4th from lagna
    bool fromLagna = _anyPapaInHouse(houses, 7) && _anyPapaInHouse(houses, 4);
    // Papa in 7th and 4th from Chandra
    bool fromMoon = false;
    if (hC != null) {
      final m7 = ((hC - 1 + 6) % 12) + 1;
      final m4 = ((hC - 1 + 3) % 12) + 1;
      fromMoon = _anyPapaInHouse(houses, m7) && _anyPapaInHouse(houses, m4);
    }
    if (!(fromLagna || fromMoon)) return null;
    return YogaResult(name: 'ಮಾತೃ ಕ್ಲೇಶ ಯೋಗ', shloka: '$shloka\nಪಾಪಗ್ರಹರು ೪ ಮತ್ತು ೭ರಲ್ಲಿ — ತಾಯಿಗೆ ಕಷ್ಟ');
  }

  // ── JKL 27: Body marks ──
  static List<YogaResult> _jkl27(KundaliResult r, Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ಸಮನುಪತಿತಾ ಯಸ್ಮಿನ್ ಗಾವೋ ತ್ರಯಃ ಸಬುಧಾ ಗ್ರಹಾ\nಭವತಿ ನಿಯಮಾತ್ತಸ್ಯಾವಾಪ್ತಿ: ಶುಭೇಷ್ಟಶುಭೇಷು ವಾ';
    // Budha + 3 other planets in same rashi
    final budhaInfo = r.planets['ಬುಧ'];
    if (budhaInfo == null) return results;
    final budhaRashi = _rashiOf(budhaInfo.longitude);
    int count = 0;
    for (final e in r.planets.entries) {
      if (e.key == 'ಬುಧ' || e.key == 'ಲಗ್ನ' || e.key == 'ಮಾಂದಿ') continue;
      if (_rashiOf(e.value.longitude) == budhaRashi) count++;
    }
    if (count >= 3) {
      final part = _rashiBodyPart[budhaRashi] ?? '';
      final rName = knRashi[budhaRashi];
      results.add(YogaResult(
        name: 'ದೇಹ ಚಿಹ್ನೆ ಯೋಗ',
        shloka: '$shloka\nಬುಧ + ೩ ಗ್ರಹರು $rName ರಾಶಿಯಲ್ಲಿ — $part ಭಾಗದಲ್ಲಿ ಗುರುತು',
      ));
    }
    return results;
  }

  // ── JKL 28: Wound or mole ──
  static List<YogaResult> _jkl28(Map<String, int> houses) {
    final results = <YogaResult>[];
    const shloka = 'ವ್ರಣಕೃದುಶುಭಃ ಷಷ್ಟೇ ಲಗ್ನಾತ್ ತನೌ ಭಸಮಾಶ್ರಿತೇ\nತಿಲಕಮಷಕೃದ್ ದೃಷ್ಟಃ ಸೌಮೈರ್ಯುತಶ್ಚ ಸ ಲಕ್ಷ್ಮವಾನ್';
    // Papa in 6th or lagna
    for (final targetH in [1, 6]) {
      for (final e in houses.entries) {
        if (!_isPapa(e.key) || e.value != targetH) continue;
        // Determine rashi of the house
        // For house 1, it's the lagna rashi; for house 6, rashi of 6th house
        // Use planet's position as proxy
        final shubhaSees = _anyShubhaAspects(houses, targetH) || _anyShubhaInHouse(houses, targetH);
        if (shubhaSees) {
          results.add(YogaResult(
            name: 'ಮಚ್ಚೆ ಯೋಗ',
            shloka: '$shloka\n${e.key} ${targetH}ನೇ ಮನೆಯಲ್ಲಿ + ಶುಭ ದೃಷ್ಟಿ — ಮಚ್ಚೆ ಇರುತ್ತದೆ',
          ));
        } else {
          results.add(YogaResult(
            name: 'ವ್ರಣ (ಗಾಯ) ಯೋಗ',
            shloka: '$shloka\n${e.key} ${targetH}ನೇ ಮನೆಯಲ್ಲಿ — ಗಾಯವಾಗುತ್ತದೆ',
          ));
        }
        break; // One result per house
      }
    }
    return results;
  }
}
