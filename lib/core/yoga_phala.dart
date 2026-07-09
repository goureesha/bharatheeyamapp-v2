/// Yoga Phala — Prashna Yoga evaluation engine
/// Evaluates astrological yogas and returns satisfied shlokas
import 'calculator.dart';
import '../constants/strings.dart';

class YogaResult {
  final String name;
  final String shloka;
  YogaResult({required this.name, required this.shloka});
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

  // ═══════════════════════════════════════════
  // MAIN EVALUATOR
  // ═══════════════════════════════════════════
  static List<YogaResult> evaluate(KundaliResult r) {
    final lagnaLon = r.planets['ಲಗ್ನ']?.longitude ?? (r.bhavas.isNotEmpty ? r.bhavas[0] : 0.0);
    final lagnaRashi = _rashiOf(lagnaLon);

    // Compute house positions (1-12)
    final houses = <String, int>{};
    for (final e in r.planets.entries) {
      if (e.key == 'ಲಗ್ನ' || e.key == 'ಮಾಂದಿ') continue;
      houses[e.key] = _houseOf(e.value.longitude, lagnaLon);
    }

    final results = <YogaResult>[];

    // Evaluate each yoga
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

    final y11 = _yoga11(r, houses);
    if (y11 != null) results.add(y11);

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

    return results;
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
  // YOGA 11: Shubha in 5,9,2,4,10 AND papa in 3,11
  //          with Surya/Guru drishti
  // ═══════════════════════════════════════════
  static YogaResult? _yoga11(KundaliResult r, Map<String, int> houses) {
    const shubhaHouses = [5, 9, 2, 4, 10];
    const papaHouses = [3, 11];

    // Check from lagna
    bool shubhaOk = false;
    bool papaOk = false;

    for (final h in shubhaHouses) {
      if (_anyShubhaInHouse(houses, h)) { shubhaOk = true; break; }
    }
    for (final h in papaHouses) {
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

    // Need Surya or Guru drishti on lagna
    final surya = _planetAspectsHouse('ರವಿ', houses, 1) || houses['ರವಿ'] == 1;
    final guru = _planetAspectsHouse('ಗುರು', houses, 1) || houses['ಗುರು'] == 1;

    if (!(shubhaOk && papaOk && (surya || guru))) return null;

    String extra = '';
    if (surya) extra += '\nಸೂರ್ಯನ ದೃಷ್ಟಿಯಿದ್ದರೆ ಗರ್ಭವು ಸುಖಕರವಾಗಿರುತ್ತದೆ';
    if (guru) extra += '\nಗುರುವಿನ ದೃಷ್ಟಿಯಿದ್ದರೆ ಗರ್ಭವು ಸುಖಕರವಾಗಿರುತ್ತದೆ';

    return YogaResult(
      name: 'ಗರ್ಭ ಸುಖ ಯೋಗ',
      shloka: 'ಶಶಾಂಕಲಗೋಪಗತೈ: ಶುಭಗ್ರಹೈಸ್ತಿಕೋಣಚಾಯಾರ್ಥಸುಖಾಸ್ಪದಸ್ಥಿತೈಃ ।\nತೃತೀಯಲಾಭರ್ಕ್ಷಗತೈರಶೋಭನೈ: ಸುಖೀ ಚ ಗರ್ಭೋ ರವಿಣಾಭಿವೀಕ್ಷಿತಃ$extra',
    );
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
}
