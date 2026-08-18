import 'calculator.dart';

// ═══════════════════════════════════════════
// YOGA ENGINE — Evaluates classical Vedic planetary Yogas
// ═══════════════════════════════════════════

class YogaResult {
  final String nameKn;   // Kannada name
  final String nameEn;   // English name
  final String category; // 'raja', 'dhana', 'pancha', 'chandra', 'graha', 'other'
  final String descKn;   // Kannada description/explanation
  final String descEn;   // English description/explanation
  final bool isPositive; // true = Shubha, false = Ashubha

  const YogaResult({
    required this.nameKn,
    required this.nameEn,
    required this.category,
    required this.descKn,
    required this.descEn,
    this.isPositive = true,
  });
}

// ─── Planet Kannada names (matching calculator.dart keys) ───
const _sun = 'ರವಿ';
const _moon = 'ಚಂದ್ರ';
const _mars = 'ಕುಜ';
const _merc = 'ಬುಧ';
const _jup = 'ಗುರು';
const _ven = 'ಶುಕ್ರ';
const _sat = 'ಶನಿ';
const _rahu = 'ರಾಹು';
const _ketu = 'ಕೇತು';
const _lagna = 'ಲಗ್ನ';

// ─── Rashi lordship: rashiIndex → planet key ───
const List<String> _rashiLord = [
  _mars,  // 0  Aries
  _ven,   // 1  Taurus
  _merc,  // 2  Gemini
  _moon,  // 3  Cancer
  _sun,   // 4  Leo
  _merc,  // 5  Virgo
  _ven,   // 6  Libra
  _mars,  // 7  Scorpio
  _jup,   // 8  Sagittarius
  _sat,   // 9  Capricorn
  _sat,   // 10 Aquarius
  _jup,   // 11 Pisces
];

// ─── Exaltation rashi for each planet ───
const Map<String, int> _exaltRashi = {
  _sun: 0, _moon: 1, _mars: 9, _merc: 5,
  _jup: 3, _ven: 11, _sat: 6,
};

// ─── Debilitation rashi ───
const Map<String, int> _debilRashi = {
  _sun: 6, _moon: 7, _mars: 3, _merc: 11,
  _jup: 9, _ven: 5, _sat: 0,
};

// ─── Own signs ───
const Map<String, List<int>> _ownSigns = {
  _sun: [4],
  _moon: [3],
  _mars: [0, 7],
  _merc: [2, 5],
  _jup: [8, 11],
  _ven: [1, 6],
  _sat: [9, 10],
};

// ─── Natural benefics ───
const Set<String> _benefics = {_jup, _ven, _merc, _moon};

// ─── Kendra houses ───
const Set<int> _kendras = {1, 4, 7, 10};

// ─── Trikona houses ───
const Set<int> _trikonas = {1, 5, 9};

// ─── Dusthana houses ───
const Set<int> _dusthanas = {6, 8, 12};

// ─── 7 main planets (exclude Rahu, Ketu, Lagna, Maandi) ───
const List<String> _sevenPlanets = [_sun, _moon, _mars, _merc, _jup, _ven, _sat];

// ─── Planets for Chandra yoga check (exclude Sun, Rahu, Ketu) ───
const List<String> _chandraYogaPlanets = [_mars, _merc, _jup, _ven, _sat];

class YogaEngine {
  /// Evaluate all yogas for a given KundaliResult
  static List<YogaResult> evaluate(KundaliResult result) {
    final planets = result.planets;
    if (planets.isEmpty || !planets.containsKey(_lagna)) return [];

    final lagnaRashi = planets[_lagna]!.rashiIndex;
    final yogas = <YogaResult>[];

    // Helper: get house number (1-12) from lagna
    int houseOf(String planet) {
      final p = planets[planet];
      if (p == null) return 0;
      return (p.rashiIndex - lagnaRashi + 12) % 12 + 1;
    }

    // Helper: get house from Moon
    int houseFromMoon(String planet) {
      final moonRashi = planets[_moon]?.rashiIndex ?? 0;
      final p = planets[planet];
      if (p == null) return 0;
      return (p.rashiIndex - moonRashi + 12) % 12 + 1;
    }

    // Helper: check if planet is in own sign
    bool isInOwnSign(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return _ownSigns[planet]?.contains(p.rashiIndex) ?? false;
    }

    // Helper: check if planet is exalted
    bool isExalted(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return _exaltRashi[planet] == p.rashiIndex;
    }

    // Helper: check if planet is debilitated
    bool isDebilitated(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return _debilRashi[planet] == p.rashiIndex;
    }

    // Helper: check if planet is retrograde
    bool isRetro(String planet) {
      final p = planets[planet];
      if (p == null) return false;
      return p.speed < 0;
    }

    // Helper: check if two planets are in same rashi
    bool conjunct(String a, String b) {
      final pa = planets[a];
      final pb = planets[b];
      if (pa == null || pb == null) return false;
      return pa.rashiIndex == pb.rashiIndex;
    }

    // Helper: get lord of a house (1-12)
    String lordOfHouse(int house) {
      final rashiIdx = (lagnaRashi + house - 1) % 12;
      return _rashiLord[rashiIdx];
    }

    // Helper: check vedic aspect (planet aspects target house from its own house)
    bool aspects(String planet, int targetHouse) {
      final fromHouse = houseOf(planet);
      if (fromHouse == 0) return false;
      final diff = (targetHouse - fromHouse + 12) % 12;
      // All planets aspect 7th
      if (diff == 6) return true;
      // Mars aspects 4th and 8th
      if (planet == _mars && (diff == 3 || diff == 7)) return true;
      // Jupiter aspects 5th and 9th
      if (planet == _jup && (diff == 4 || diff == 8)) return true;
      // Saturn aspects 3rd and 10th
      if (planet == _sat && (diff == 2 || diff == 9)) return true;
      return false;
    }

    // Helper: planets in a given house
    List<String> planetsInHouse(int house) {
      return _sevenPlanets.where((p) => houseOf(p) == house).toList();
    }

    // ═══════════════════════════════════════
    // 1. GAJA KESARI YOGA
    // Jupiter in Kendra (1,4,7,10) from Moon
    // ═══════════════════════════════════════
    {
      final jupFromMoon = houseFromMoon(_jup);
      if (_kendras.contains(jupFromMoon)) {
        yogas.add(const YogaResult(
          nameKn: 'ಗಜಕೇಸರಿ ಯೋಗ',
          nameEn: 'Gaja Kesari Yoga',
          category: 'raja',
          descKn: 'ಗುರು ಚಂದ್ರನಿಂದ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಕೀರ್ತಿ, ಬುದ್ಧಿ ಮತ್ತು ಸಂಪತ್ತು ಲಭಿಸುತ್ತದೆ. ಜನರಲ್ಲಿ ಗೌರವ ಮತ್ತು ಮಾನ-ಸಮ್ಮಾನ ಪ್ರಾಪ್ತಿಯಾಗುತ್ತದೆ. ದೀರ್ಘಾಯುಷ್ಯ ಮತ್ತು ಉತ್ತಮ ಸಂತಾನ ಭಾಗ್ಯವಿರುತ್ತದೆ.',
          descEn: 'Jupiter in Kendra from Moon. Bestows fame, wisdom and wealth. The native earns respect and honour in society. Blessed with longevity and good progeny.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 2. BUDHADITYA YOGA
    // Sun + Mercury in same house
    // ═══════════════════════════════════════
    if (conjunct(_sun, _merc)) {
      final h = houseOf(_sun);
      if (!_dusthanas.contains(h)) {
        yogas.add(const YogaResult(
          nameKn: 'ಬುಧಾದಿತ್ಯ ಯೋಗ',
          nameEn: 'Budhaditya Yoga',
          category: 'graha',
          descKn: 'ರವಿ ಮತ್ತು ಬುಧ ಒಂದೇ ರಾಶಿಯಲ್ಲಿದ್ದರೆ. ಬುದ್ಧಿಶಕ್ತಿ, ವಾಕ್ಚಾತುರ್ಯ ಮತ್ತು ವಿದ್ಯೆಯಲ್ಲಿ ಉನ್ನತಿ. ವ್ಯಾಪಾರ ಮತ್ತು ವೃತ್ತಿಯಲ್ಲಿ ಯಶಸ್ಸು ಪ್ರಾಪ್ತಿಯಾಗುತ್ತದೆ. ಸಮಾಜದಲ್ಲಿ ಉತ್ತಮ ಹೆಸರು ಗಳಿಸುತ್ತಾರೆ.',
          descEn: 'Sun and Mercury conjunct. Intelligence, eloquence and excellence in learning. Success in business and profession. Earns a good name in society.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 3. CHANDRA-MANGAL YOGA
    // Moon + Mars in same house
    // ═══════════════════════════════════════
    if (conjunct(_moon, _mars)) {
      yogas.add(const YogaResult(
        nameKn: 'ಚಂದ್ರ-ಮಂಗಳ ಯೋಗ',
        nameEn: 'Chandra-Mangal Yoga',
        category: 'dhana',
        descKn: 'ಚಂದ್ರ ಮತ್ತು ಕುಜ ಒಂದೇ ರಾಶಿಯಲ್ಲಿದ್ದರೆ. ಧನಪ್ರಾಪ್ತಿ ಮತ್ತು ಸಾಹಸ ಪ್ರವೃತ್ತಿ. ಸ್ವಂತ ಪ್ರಯತ್ನದಿಂದ ಆಸ್ತಿ ಮತ್ತು ಸಂಪತ್ತು ಗಳಿಸುತ್ತಾರೆ. ಉದ್ಯಮಶೀಲತೆ ಮತ್ತು ನಾಯಕತ್ವ ಗುಣ ಇರುತ್ತದೆ.',
        descEn: 'Moon and Mars conjunct. Wealth through courage and enterprise. Earns property and riches through self-effort. Possesses entrepreneurial and leadership qualities.',
      ));
    }

    // ═══════════════════════════════════════
    // 4-8. PANCHA MAHAPURUSHA YOGAS
    // Planet in own/exalted sign in Kendra from Lagna
    // ═══════════════════════════════════════
    final _mahapurushaData = [
      [_mars, 'ರುಚಕ ಯೋಗ', 'Ruchaka Yoga', 'ಕುಜ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಶೌರ್ಯ, ನಾಯಕತ್ವ ಮತ್ತು ಭೂಸಂಪತ್ತು. ಸೇನೆ, ಪೊಲೀಸ್ ಅಥವಾ ಆಡಳಿತ ಕ್ಷೇತ್ರದಲ್ಲಿ ಉನ್ನತ ಸ್ಥಾನ. ದೈಹಿಕ ಬಲ ಮತ್ತು ಆಕರ್ಷಕ ವ್ಯಕ್ತಿತ್ವವಿರುತ್ತದೆ.',
        'Mars in own/exalted sign in Kendra. Valor, leadership and landed property. High position in military, police or administration. Physical strength and attractive personality.'],
      [_merc, 'ಭದ್ರ ಯೋಗ', 'Bhadra Yoga', 'ಬುಧ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ವಿದ್ಯೆ, ವಾಣಿಜ್ಯ ಮತ್ತು ವಾಕ್ಶಕ್ತಿ. ಗಣಿತ, ಜ್ಯೋತಿಷ ಮತ್ತು ವ್ಯಾಪಾರದಲ್ಲಿ ಪ್ರಾವೀಣ್ಯತೆ. ಬಹು ವಿದ್ವಾಂಸ ಮತ್ತು ಜನಪ್ರಿಯ ವ್ಯಕ್ತಿಯಾಗುತ್ತಾರೆ.',
        'Mercury in own/exalted sign in Kendra. Learning, commerce and eloquence. Proficiency in mathematics, astrology and trade. Becomes a great scholar and popular person.'],
      [_jup, 'ಹಂಸ ಯೋಗ', 'Hamsa Yoga', 'ಗುರು ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಧಾರ್ಮಿಕತೆ, ಜ್ಜ್ಞಾನ ಮತ್ತು ಉನ್ನತ ಪದವಿ. ಸಮಾಜದಲ್ಲಿ ಗೌರವಾನ್ವಿತ ಸ್ಥಾನ ಮತ್ತು ಧಾರ್ಮಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಆಸಕ್ತಿ. ಉತ್ತಮ ಶಿಕ್ಷಣ ಮತ್ತು ಅಧ್ಯಾಪನ ಕ್ಷೇತ್ರದಲ್ಲಿ ಯಶಸ್ಸು.',
        'Jupiter in own/exalted sign in Kendra. Spirituality, wisdom and high status. Respectable position in society with interest in religious activities. Success in education and teaching fields.'],
      [_ven, 'ಮಾಲವ್ಯ ಯೋಗ', 'Malavya Yoga', 'ಶುಕ್ರ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಸೌಂದರ್ಯ, ಕಲೆ ಮತ್ತು ಭೋಗಸುಖ. ವಾಹನ, ಆಭರಣ ಮತ್ತು ಐಶ್ವರ್ಯ ಪ್ರಾಪ್ತಿ. ಸಂಗೀತ, ನೃತ್ಯ ಮತ್ತು ಲಲಿತ ಕಲೆಗಳಲ್ಲಿ ಪ್ರಸಿದ್ಧಿ.',
        'Venus in own/exalted sign in Kendra. Beauty, art and luxuries. Gains vehicles, jewellery and wealth. Fame in music, dance and fine arts.'],
      [_sat, 'ಶಶ ಯೋಗ', 'Shasha Yoga', 'ಶನಿ ಸ್ವಕ್ಷೇತ್ರ/ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಅಧಿಕಾರ, ಶಿಸ್ತು ಮತ್ತು ದೀರ್ಘಾಯುಷ್ಯ. ಜನರ ಮೇಲೆ ಅಧಿಕಾರ ಮತ್ತು ನಾಯಕತ್ವ ಸ್ಥಾನ. ಕಠಿಣ ಪರಿಶ್ರಮದಿಂದ ಉನ್ನತ ಸ್ಥಾನಕ್ಕೇರುತ್ತಾರೆ.',
        'Saturn in own/exalted sign in Kendra. Authority, discipline and longevity. Commands authority and leadership over people. Rises to high position through hard work and perseverance.'],
    ];
    for (final data in _mahapurushaData) {
      final planet = data[0] as String;
      final h = houseOf(planet);
      if (_kendras.contains(h) && (isInOwnSign(planet) || isExalted(planet))) {
        yogas.add(YogaResult(
          nameKn: data[1] as String,
          nameEn: data[2] as String,
          category: 'pancha',
          descKn: data[3] as String,
          descEn: data[4] as String,
        ));
      }
    }

    // ═══════════════════════════════════════
    // 9. SUNAPHA YOGA
    // Planets (except Sun, Rahu, Ketu) in 2nd from Moon
    // ═══════════════════════════════════════
    {
      final in2nd = _chandraYogaPlanets.where((p) => houseFromMoon(p) == 2).toList();
      if (in2nd.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ಸುನಫಾ ಯೋಗ',
          nameEn: 'Sunapha Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನಿಂದ ೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ಸ್ವಪ್ರಯತ್ನದಿಂದ ಸಂಪತ್ತು ಮತ್ತು ಅಧಿಕಾರ. ಬುದ್ಧಿವಂತಿಕೆ ಮತ್ತು ವಿವೇಕದಿಂದ ಜೀವನದಲ್ಲಿ ಉನ್ನತಿ ಸಾಧಿಸುತ್ತಾರೆ. ಸ್ವಂತ ಸಂಪಾದನೆಯಿಂದ ಸುಖಿ ಜೀವನ ನಡೆಸುತ್ತಾರೆ.',
          descEn: 'Planet in 2nd from Moon. Self-earned wealth and authority. Achieves success in life through intelligence and wisdom. Leads a comfortable life through own earnings.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 10. ANAPHA YOGA
    // Planets (except Sun, Rahu, Ketu) in 12th from Moon
    // ═══════════════════════════════════════
    {
      final in12th = _chandraYogaPlanets.where((p) => houseFromMoon(p) == 12).toList();
      if (in12th.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ಅನಫಾ ಯೋಗ',
          nameEn: 'Anapha Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನಿಂದ ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ಆಧ್ಯಾತ್ಮಿಕ ಒಲವು ಮತ್ತು ಉದಾರತೆ. ಪರೋಪಕಾರ ಬುದ್ಧಿ ಮತ್ತು ದಾನಶೀಲತೆ ಇರುತ್ತದೆ. ಸಮಾಜಸೇವೆ ಮತ್ತು ಧಾರ್ಮಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಆಸಕ್ತಿ.',
          descEn: 'Planet in 12th from Moon. Spiritual inclination and generosity. Charitable disposition and philanthropic nature. Interest in social service and religious activities.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 11. DURDHURA YOGA
    // Planets in both 2nd and 12th from Moon
    // ═══════════════════════════════════════
    {
      final in2nd = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 2);
      final in12th = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 12);
      if (in2nd && in12th) {
        yogas.add(const YogaResult(
          nameKn: 'ದುರ್ಧುರಾ ಯೋಗ',
          nameEn: 'Durdhura Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹಗಳಿವೆ. ಐಶ್ವರ್ಯ, ವಾಹನ ಮತ್ತು ಸಂಪತ್ತು. ಜೀವನದಲ್ಲಿ ಸುಖ-ಸಂತೋಷ ಮತ್ತು ಭೌತಿಕ ಸೌಕರ್ಯಗಳು ಲಭಿಸುತ್ತವೆ. ಉದಾರ ಮನಸ್ಸು ಮತ್ತು ಉತ್ತಮ ಸ್ನೇಹ ವಲಯ ಇರುತ್ತದೆ.',
          descEn: 'Planets in 2nd and 12th from Moon. Wealth, vehicles and prosperity. Enjoys happiness and material comforts in life. Generous nature with a good social circle.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 12. KEMADRUMA YOGA (Ashubha)
    // No planets in 2nd or 12th from Moon
    // ═══════════════════════════════════════
    {
      final in2nd = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 2);
      final in12th = _chandraYogaPlanets.any((p) => houseFromMoon(p) == 12);
      final inKendraFromMoon = _sevenPlanets.where((p) => p != _moon).any((p) {
        final h = houseFromMoon(p);
        return _kendras.contains(h);
      });
      if (!in2nd && !in12th && !inKendraFromMoon) {
        yogas.add(const YogaResult(
          nameKn: 'ಕೇಮದ್ರುಮ ಯೋಗ',
          nameEn: 'Kemadruma Yoga',
          category: 'chandra',
          descKn: 'ಚಂದ್ರನ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಯಾವ ಗ್ರಹವೂ ಇಲ್ಲ. ಆರ್ಥಿಕ ಕಷ್ಟ ಮತ್ತು ಒಂಟಿತನ. ಮಾನಸಿಕ ಅಶಾಂತಿ ಮತ್ತು ಚಿಂತೆ ಕಾಡಬಹುದು. ಆದರೆ ಕೇಂದ್ರದಲ್ಲಿ ಗ್ರಹಗಳಿದ್ದರೆ ಈ ದೋಷ ಕಡಿಮೆಯಾಗುತ್ತದೆ.',
          descEn: 'No planets in 2nd/12th from Moon or Kendra. Financial hardship and loneliness. May experience mental restlessness and anxiety. However, planets in Kendra can mitigate this defect.',
          isPositive: false,
        ));
      }
    }

    // ═══════════════════════════════════════
    // 13. SHAKATA YOGA (Ashubha)
    // Jupiter in 6, 8, or 12 from Moon
    // ═══════════════════════════════════════
    {
      final jupFromMoon = houseFromMoon(_jup);
      if (_dusthanas.contains(jupFromMoon)) {
        yogas.add(const YogaResult(
          nameKn: 'ಶಕಟ ಯೋಗ',
          nameEn: 'Shakata Yoga',
          category: 'chandra',
          descKn: 'ಗುರು ಚಂದ್ರನಿಂದ ೬/೮/೧೨ನೇ ಮನೆಯಲ್ಲಿದ್ದರೆ. ಅಸ್ಥಿರ ಅದೃಷ್ಟ ಮತ್ತು ಏರಿಳಿತಗಳು. ಜೀವನದಲ್ಲಿ ಸುಖ-ದುಃಖಗಳ ಚಕ್ರ ಇರುತ್ತದೆ. ಕಷ್ಟ ಸಮಯದ ನಂತರ ಉತ್ತಮ ಕಾಲ ಬರುತ್ತದೆ.',
          descEn: 'Jupiter in 6/8/12 from Moon. Fluctuating fortune and ups-downs. Life follows a cycle of joy and sorrow. Good times follow after periods of difficulty.',
          isPositive: false,
        ));
      }
    }

    // ═══════════════════════════════════════
    // 14. AMALA YOGA
    // Natural benefic in 10th from Lagna
    // ═══════════════════════════════════════
    {
      final in10th = _benefics.where((p) => houseOf(p) == 10).toList();
      if (in10th.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ಅಮಲ ಯೋಗ',
          nameEn: 'Amala Yoga',
          category: 'raja',
          descKn: 'ಶುಭ ಗ್ರಹ ೧೦ನೇ ಮನೆಯಲ್ಲಿದೆ. ಶುದ್ಧ ಕೀರ್ತಿ, ಸತ್ಕಾರ್ಯ ಮತ್ತು ಯಶಸ್ಸು. ವೃತ್ತಿ ಜೀವನದಲ್ಲಿ ಉತ್ತಮ ಹೆಸರು ಗಳಿಸುತ್ತಾರೆ. ಧಾರ್ಮಿಕ ಮತ್ತು ಸಾಮಾಜಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ತೊಡಗಿಸಿಕೊಳ್ಳುತ್ತಾರೆ.',
          descEn: 'Benefic in 10th house. Spotless reputation, good deeds and success. Earns an excellent name in professional life. Engages in religious and social welfare activities.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 15. VIPAREETHA RAJA YOGA
    // Lord of 6/8/12 placed in another 6/8/12
    // ═══════════════════════════════════════
    {
      final dusthanaHouses = [6, 8, 12];
      for (final dh in dusthanaHouses) {
        final lord = lordOfHouse(dh);
        final lordH = houseOf(lord);
        if (_dusthanas.contains(lordH) && lordH != dh) {
          yogas.add(YogaResult(
            nameKn: 'ವಿಪರೀತ ರಾಜಯೋಗ',
            nameEn: 'Vipareetha Raja Yoga',
            category: 'raja',
            descKn: '${dh}ನೇ ಮನೆಯ ಅಧಿಪತಿ ${lordH}ನೇ ಮನೆಯಲ್ಲಿದ್ದರೆ. ಕಷ್ಟಗಳ ಮೂಲಕ ಉನ್ನತಿ. ಶತ್ರುಗಳ ನಾಶ ಮತ್ತು ಅನಿರೀಕ್ಷಿತ ಲಾಭ ಪ್ರಾಪ್ತಿ. ಕಠಿಣ ಪರಿಸ್ಥಿತಿಗಳಲ್ಲಿ ಅಚ್ಚರಿಯ ಯಶಸ್ಸು ಲಭಿಸುತ್ತದೆ.',
            descEn: 'Lord of house $dh in house $lordH. Rise through adversity. Destruction of enemies and unexpected gains. Achieves surprising success in difficult situations.',
          ));
          break; // Show only once
        }
      }
    }

    // ═══════════════════════════════════════
    // 16. NEECHABHANGA RAJA YOGA
    // Debilitated planet with cancellation conditions
    // ═══════════════════════════════════════
    for (final planet in _sevenPlanets) {
      if (!isDebilitated(planet)) continue;
      final pInfo = planets[planet]!;
      final debRashi = pInfo.rashiIndex;
      final lordOfDebSign = _rashiLord[debRashi];

      // Cancellation 1: Lord of debilitation sign in Kendra from Lagna/Moon
      final lordH = houseOf(lordOfDebSign);
      final lordHMoon = houseFromMoon(lordOfDebSign);
      // Cancellation 2: Planet is retrograde
      // Cancellation 3: Exaltation lord aspects the debilitated planet
      bool cancelled = false;
      if (_kendras.contains(lordH) || _kendras.contains(lordHMoon)) cancelled = true;
      if (isRetro(planet)) cancelled = true;

      if (cancelled) {
        yogas.add(YogaResult(
          nameKn: 'ನೀಚಭಂಗ ರಾಜಯೋಗ',
          nameEn: 'Neechabhanga Raja Yoga',
          category: 'raja',
          descKn: 'ನೀಚ ಗ್ರಹದ ಭಂಗ. ನೀಚ ಸ್ಥಿತಿ ರದ್ದಾಗಿ ರಾಜಯೋಗ ಫಲ ಲಭಿಸುತ್ತದೆ. ಜೀವನದ ಆರಂಭದ ಕಷ್ಟಗಳ ನಂತರ ಅಭೂತಪೂರ್ವ ಯಶಸ್ಸು. ವಿರೋಧಿಗಳನ್ನು ಮೀರಿ ಉನ್ನತ ಸ್ಥಾನಕ್ಕೇರುತ್ತಾರೆ.',
          descEn: 'Debilitation cancelled. Turns weakness into great strength and rise. After initial struggles, achieves unprecedented success. Rises above opponents to attain high position.',
        ));
        break; // Show only once
      }
    }

    // ═══════════════════════════════════════
    // 17. LAKSHMI YOGA
    // Lord of 9th in Kendra/Trikona and strong
    // ═══════════════════════════════════════
    {
      final lord9 = lordOfHouse(9);
      final lord9H = houseOf(lord9);
      if ((_kendras.contains(lord9H) || _trikonas.contains(lord9H)) &&
          (isInOwnSign(lord9) || isExalted(lord9))) {
        yogas.add(const YogaResult(
          nameKn: 'ಲಕ್ಷ್ಮೀ ಯೋಗ',
          nameEn: 'Lakshmi Yoga',
          category: 'dhana',
          descKn: '೯ನೇ ಅಧಿಪತಿ ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿ ಬಲಿಷ್ಠವಾಗಿದ್ದರೆ. ಮಹಾ ಸಂಪತ್ತು ಮತ್ತು ಸೌಭಾಗ್ಯ. ಧನ, ಆಸ್ತಿ ಮತ್ತು ಐಶ್ವರ್ಯ ಸಮೃದ್ಧಿ ಇರುತ್ತದೆ. ಭಾಗ್ಯಶಾಲಿ ಜೀವನ ಮತ್ತು ಪೂರ್ವಜನ್ಮ ಪುಣ್ಯ ಫಲ ಲಭಿಸುತ್ತದೆ.',
          descEn: 'Lord of 9th strong in Kendra/Trikona. Great wealth and fortune. Abundance of money, property and riches. Lucky life blessed with fruits of past-life merits.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 18. KENDRA-TRIKONA RAJA YOGA
    // Lord of Kendra + Lord of Trikona conjunct/in same house
    // ═══════════════════════════════════════
    {
      final kendraLords = <String>{};
      final trikonaLords = <String>{};
      for (final k in _kendras) {
        final l = lordOfHouse(k);
        if (l != _sun && l != _moon) kendraLords.add(l);
      }
      for (final t in _trikonas) {
        final l = lordOfHouse(t);
        if (l != _sun && l != _moon) trikonaLords.add(l);
      }

      bool found = false;
      for (final kl in kendraLords) {
        for (final tl in trikonaLords) {
          if (kl == tl) continue; // Same planet can't form this yoga
          if (conjunct(kl, tl)) {
            yogas.add(const YogaResult(
              nameKn: 'ಕೇಂದ್ರ-ತ್ರಿಕೋಣ ರಾಜಯೋಗ',
              nameEn: 'Kendra-Trikona Raja Yoga',
              category: 'raja',
              descKn: 'ಕೇಂದ್ರ ಮತ್ತು ತ್ರಿಕೋಣ ಅಧಿಪತಿಗಳ ಸಂಯೋಗ. ಅಧಿಕಾರ, ಯಶಸ್ಸು ಮತ್ತು ಸಾಮಾಜಿಕ ಗೌರವ. ಸರ್ಕಾರ ಅಥವಾ ಸಂಸ್ಥೆಯಲ್ಲಿ ಉನ್ನತ ಹುದ್ದೆ. ಜನರಿಂದ ಮಾನ-ಸಮ್ಮಾನ ಮತ್ತು ಪ್ರಶಸ್ತಿ ಲಭಿಸುತ್ತದೆ.',
              descEn: 'Lords of Kendra and Trikona conjunct. Power, success and social honour. High position in government or organization. Receives respect, recognition and awards from people.',
            ));
            found = true;
            break;
          }
        }
        if (found) break;
      }
    }

    // ═══════════════════════════════════════
    // 19. SARASWATI YOGA
    // Jupiter, Venus, Mercury in Kendra/Trikona/2nd
    // ═══════════════════════════════════════
    {
      final goodHouses = {..._kendras, ..._trikonas, 2};
      final jupH = houseOf(_jup);
      final venH = houseOf(_ven);
      final merH = houseOf(_merc);
      if (goodHouses.contains(jupH) && goodHouses.contains(venH) && goodHouses.contains(merH)) {
        yogas.add(const YogaResult(
          nameKn: 'ಸರಸ್ವತಿ ಯೋಗ',
          nameEn: 'Saraswati Yoga',
          category: 'other',
          descKn: 'ಗುರು, ಶುಕ್ರ, ಬುಧ ಕೇಂದ್ರ/ತ್ರಿಕೋಣ/೨ನೇ ಮನೆಯಲ್ಲಿದ್ದರೆ. ವಿದ್ಯೆ, ಕಲೆ ಮತ್ತು ವಾಗ್ಮಿತ್ವ. ಸಾಹಿತ್ಯ, ಸಂಗೀತ ಮತ್ತು ಶಾಸ್ತ್ರಗಳಲ್ಲಿ ಪಾಂಡಿತ್ಯ. ಉತ್ತಮ ಲೇಖಕ, ಭಾಷಣಕಾರ ಅಥವಾ ಶಿಕ್ಷಕರಾಗುತ್ತಾರೆ.',
          descEn: 'Jupiter, Venus, Mercury in Kendra/Trikona/2nd. Learning, arts and eloquence. Expertise in literature, music and scriptures. Becomes a fine writer, speaker or teacher.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 20. DHANA YOGA
    // Lord of 2nd and Lord of 11th in Kendra/Trikona
    // ═══════════════════════════════════════
    {
      final lord2 = lordOfHouse(2);
      final lord11 = lordOfHouse(11);
      final lord2H = houseOf(lord2);
      final lord11H = houseOf(lord11);
      final good = {..._kendras, ..._trikonas};
      if (good.contains(lord2H) && good.contains(lord11H)) {
        yogas.add(const YogaResult(
          nameKn: 'ಧನ ಯೋಗ',
          nameEn: 'Dhana Yoga',
          category: 'dhana',
          descKn: '೨ ಮತ್ತು ೧೧ನೇ ಅಧಿಪತಿಗಳು ಕೇಂದ್ರ/ತ್ರಿಕೋಣದಲ್ಲಿದ್ದರೆ. ಧನ ಪ್ರಾಪ್ತಿ ಮತ್ತು ಆರ್ಥಿಕ ಸ್ಥಿರತೆ. ಹಲವು ಮೂಲಗಳಿಂದ ಆದಾಯ ಮತ್ತು ಉಳಿತಾಯ. ಕುಟುಂಬದಲ್ಲಿ ಸಂಪತ್ತು ಮತ್ತು ಸಮೃದ್ಧಿ ಬೆಳೆಯುತ್ತದೆ.',
          descEn: 'Lords of 2nd and 11th in Kendra/Trikona. Wealth acquisition and financial stability. Income and savings from multiple sources. Family grows in wealth and prosperity.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 21. ADHI YOGA
    // Benefics in 6th, 7th, 8th from Moon
    // ═══════════════════════════════════════
    {
      final beneficsFrom678 = _benefics.where((p) {
        final h = houseFromMoon(p);
        return h == 6 || h == 7 || h == 8;
      }).toList();
      if (beneficsFrom678.length >= 2) {
        yogas.add(const YogaResult(
          nameKn: 'ಅಧಿ ಯೋಗ',
          nameEn: 'Adhi Yoga',
          category: 'raja',
          descKn: 'ಚಂದ್ರನಿಂದ ೬/೭/೮ನೇ ಮನೆಯಲ್ಲಿ ಶುಭ ಗ್ರಹಗಳಿವೆ. ನಾಯಕತ್ವ, ಅಧಿಕಾರ ಮತ್ತು ಸಮೃದ್ಧಿ. ಸರ್ಕಾರ ಅಥವಾ ರಾಜಕೀಯದಲ್ಲಿ ಉನ್ನತ ಸ್ಥಾನ. ಶತ್ರುಗಳ ಮೇಲೆ ವಿಜಯ ಮತ್ತು ಸಮಾಜದಲ್ಲಿ ಪ್ರಭಾವ.',
          descEn: 'Benefics in 6/7/8 from Moon. Leadership, authority and prosperity. High position in government or politics. Victory over enemies and influence in society.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 22. VOSHI YOGA
    // Planet (not Moon, Rahu, Ketu) in 2nd from Sun
    // ═══════════════════════════════════════
    {
      final sunRashi = planets[_sun]?.rashiIndex ?? 0;
      final in2ndFromSun = [_mars, _merc, _jup, _ven, _sat].where((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 1;
      }).toList();
      if (in2ndFromSun.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ವೋಶಿ ಯೋಗ',
          nameEn: 'Voshi Yoga',
          category: 'graha',
          descKn: 'ರವಿಯಿಂದ ೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ಸ್ಮರಣಶಕ್ತಿ, ಧೈರ್ಯ ಮತ್ತು ಸಾಮರ್ಥ್ಯ. ವಿದ್ಯಾಭ್ಯಾಸ ಮತ್ತು ವೃತ್ತಿಯಲ್ಲಿ ಉತ್ತಮ ಸಾಧನೆ. ಆತ್ಮವಿಶ್ವಾಸ ಮತ್ತು ದೃಢ ನಿರ್ಧಾರ ಶಕ್ತಿ ಇರುತ್ತದೆ.',
          descEn: 'Planet in 2nd from Sun. Good memory, courage and ability. Excellent achievements in education and career. Possesses self-confidence and strong decision-making ability.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 23. VESHI YOGA
    // Planet (not Moon, Rahu, Ketu) in 12th from Sun
    // ═══════════════════════════════════════
    {
      final sunRashi = planets[_sun]?.rashiIndex ?? 0;
      final in12thFromSun = [_mars, _merc, _jup, _ven, _sat].where((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 11;
      }).toList();
      if (in12thFromSun.isNotEmpty) {
        yogas.add(const YogaResult(
          nameKn: 'ವೇಶಿ ಯೋಗ',
          nameEn: 'Veshi Yoga',
          category: 'graha',
          descKn: 'ರವಿಯಿಂದ ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹವಿದೆ. ದಾನಶೀಲತೆ ಮತ್ತು ಸತ್ಯಪ್ರಿಯತೆ. ಪರೋಪಕಾರ ಮತ್ತು ಆಧ್ಯಾತ್ಮಿಕ ಜೀವನದಲ್ಲಿ ಆಸಕ್ತಿ. ಸಜ್ಜನರ ಸಹವಾಸ ಮತ್ತು ಉತ್ತಮ ನೈತಿಕ ಮೌಲ್ಯಗಳು ಇರುತ್ತವೆ.',
          descEn: 'Planet in 12th from Sun. Charitable nature and truthfulness. Interest in philanthropy and spiritual life. Good moral values and association with virtuous people.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 24. UBHAYACHARI YOGA
    // Planets in both 2nd and 12th from Sun
    // ═══════════════════════════════════════
    {
      final sunRashi = planets[_sun]?.rashiIndex ?? 0;
      final in2 = [_mars, _merc, _jup, _ven, _sat].any((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 1;
      });
      final in12 = [_mars, _merc, _jup, _ven, _sat].any((p) {
        final pr = planets[p]?.rashiIndex ?? -1;
        return (pr - sunRashi + 12) % 12 == 11;
      });
      if (in2 && in12) {
        yogas.add(const YogaResult(
          nameKn: 'ಉಭಯಚಾರಿ ಯೋಗ',
          nameEn: 'Ubhayachari Yoga',
          category: 'graha',
          descKn: 'ರವಿಯ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಗ್ರಹಗಳಿವೆ. ಸರ್ವಗುಣ ಸಂಪನ್ನ, ರಾಜ ಸಮಾನ. ಎಲ್ಲಾ ಕ್ಷೇತ್ರಗಳಲ್ಲಿ ಸಮರ್ಥ ಮತ್ತು ಪ್ರಸಿದ್ಧ. ಆರೋಗ್ಯ, ಸಂಪತ್ತು ಮತ್ತು ಸುಖಮಯ ಜೀವನ ನಡೆಸುತ್ತಾರೆ.',
          descEn: 'Planets in 2nd and 12th from Sun. Kingly qualities, all-round ability. Competent and famous in all fields. Leads a life of good health, wealth and happiness.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 25. KAHALA YOGA
    // Lord of 4th and Jupiter in mutual Kendra
    // ═══════════════════════════════════════
    {
      final lord4 = lordOfHouse(4);
      final lord4H = houseOf(lord4);
      final jupH = houseOf(_jup);
      final diff = (jupH - lord4H + 12) % 12;
      if (diff == 0 || diff == 3 || diff == 6 || diff == 9) {
        if (lord4 != _jup && (_kendras.contains(lord4H) || _kendras.contains(jupH))) {
          yogas.add(const YogaResult(
            nameKn: 'ಕಹಳ ಯೋಗ',
            nameEn: 'Kahala Yoga',
            category: 'other',
            descKn: '೪ನೇ ಅಧಿಪತಿ ಮತ್ತು ಗುರು ಪರಸ್ಪರ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಧೈರ್ಯ ಮತ್ತು ಸಾಹಸ. ಕಠಿಣ ಸವಾಲುಗಳನ್ನು ಎದುರಿಸುವ ಶಕ್ತಿ ಇರುತ್ತದೆ. ಸಾಹಸ ಕಾರ್ಯಗಳಲ್ಲಿ ಮತ್ತು ಕ್ರೀಡೆಗಳಲ್ಲಿ ಯಶಸ್ಸು.',
            descEn: 'Lord of 4th and Jupiter in mutual Kendra. Courage and adventurous spirit. Has the strength to face tough challenges. Success in adventurous pursuits and sports.',
          ));
        }
      }
    }

    // ═══════════════════════════════════════
    // 26. DHARMA-KARMADHIPATI YOGA
    // Lords of 9th and 10th conjunct
    // ═══════════════════════════════════════
    {
      final lord9 = lordOfHouse(9);
      final lord10 = lordOfHouse(10);
      if (lord9 != lord10 && conjunct(lord9, lord10)) {
        yogas.add(const YogaResult(
          nameKn: 'ಧರ್ಮ-ಕರ್ಮಾಧಿಪತಿ ಯೋಗ',
          nameEn: 'Dharma-Karmadhipati Yoga',
          category: 'raja',
          descKn: '೯ ಮತ್ತು ೧೦ನೇ ಅಧಿಪತಿಗಳ ಸಂಯೋಗ. ಧರ್ಮ-ಕರ್ಮ ಸಮನ್ವಯ, ಉನ್ನತ ಪದವಿ ಮತ್ತು ಯಶಸ್ಸು. ವೃತ್ತಿಯಲ್ಲಿ ಧಾರ್ಮಿಕ ಮೌಲ್ಯಗಳನ್ನು ಅನುಸರಿಸಿ ಯಶಸ್ಸು ಗಳಿಸುತ್ತಾರೆ. ಸಮಾಜದಲ್ಲಿ ಆದರ್ಶ ವ್ಯಕ್ತಿಯಾಗಿ ಗುರುತಿಸಲ್ಪಡುತ್ತಾರೆ.',
          descEn: 'Lords of 9th and 10th conjunct. Righteous career, high position and success. Achieves success in career by following moral values. Recognized as an ideal person in society.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 27. VASUMATHI YOGA
    // Benefics in upachaya houses (3,6,10,11) from Moon
    // ═══════════════════════════════════════
    {
      final upachayas = {3, 6, 10, 11};
      final count = _benefics.where((p) {
        final h = houseFromMoon(p);
        return upachayas.contains(h);
      }).length;
      if (count >= 3) {
        yogas.add(const YogaResult(
          nameKn: 'ವಸುಮತಿ ಯೋಗ',
          nameEn: 'Vasumathi Yoga',
          category: 'dhana',
          descKn: 'ಚಂದ್ರನಿಂದ ಉಪಚಯ ಸ್ಥಾನಗಳಲ್ಲಿ ಶುಭ ಗ್ರಹಗಳಿದ್ದರೆ. ಅಪಾರ ಸಂಪತ್ತು ಮತ್ತು ಸಮೃದ್ಧಿ. ಜೀವನದುದ್ದಕ್ಕೂ ಆರ್ಥಿಕ ಅಭಿವೃದ್ಧಿ ಮತ್ತು ಸ್ಥಿರತೆ. ಉತ್ತಮ ಜೀವನಮಟ್ಟ ಮತ್ತು ಸಕಲ ಭೌತಿಕ ಸುಖಗಳು ಲಭಿಸುತ್ತವೆ.',
          descEn: 'Benefics in upachaya from Moon. Immense wealth and prosperity. Financial growth and stability throughout life. Enjoys a high standard of living with all material comforts.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 28. SHUBHA KARTARI YOGA
    // Benefics in 2nd and 12th from Lagna
    // ═══════════════════════════════════════
    {
      final in2 = _benefics.any((p) => houseOf(p) == 2);
      final in12 = _benefics.any((p) => houseOf(p) == 12);
      if (in2 && in12) {
        yogas.add(const YogaResult(
          nameKn: 'ಶುಭ ಕರ್ತರಿ ಯೋಗ',
          nameEn: 'Shubha Kartari Yoga',
          category: 'other',
          descKn: 'ಲಗ್ನದ ೨ ಮತ್ತು ೧೨ನೇ ಮನೆಯಲ್ಲಿ ಶುಭ ಗ್ರಹಗಳಿದ್ದರೆ. ಸುಖ, ಆರೋಗ್ಯ ಮತ್ತು ರಕ್ಷಣೆ. ಕೆಟ್ಟ ಪ್ರಭಾವಗಳಿಂದ ಸ್ವಾಭಾವಿಕ ರಕ್ಷಣೆ ಇರುತ್ತದೆ. ಮಾನಸಿಕ ಶಾಂತಿ ಮತ್ತು ದೈಹಿಕ ಆರೋಗ್ಯ ಉತ್ತಮವಾಗಿರುತ್ತದೆ.',
          descEn: 'Benefics hemming the Ascendant. Happiness, health and protection. Natural protection from negative influences. Enjoys mental peace and good physical health.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 29. KALANIDHI YOGA
    // Jupiter in 2nd or 5th with Mercury or Venus
    // ═══════════════════════════════════════
    {
      final jupH = houseOf(_jup);
      if ((jupH == 2 || jupH == 5) && (conjunct(_jup, _merc) || conjunct(_jup, _ven))) {
        yogas.add(const YogaResult(
          nameKn: 'ಕಲಾನಿಧಿ ಯೋಗ',
          nameEn: 'Kalanidhi Yoga',
          category: 'other',
          descKn: 'ಗುರು ೨/೫ನೇ ಮನೆಯಲ್ಲಿ ಬುಧ/ಶುಕ್ರನೊಂದಿಗೆ ಇದ್ದರೆ. ಕಲೆ, ವಿದ್ಯೆ ಮತ್ತು ಸಂಸ್ಕೃತಿಯಲ್ಲಿ ಪ್ರಸಿದ್ಧಿ. ಸಂಗೀತ, ನೃತ್ಯ, ಚಿತ್ರಕಲೆ ಮುಂತಾದ ಕಲೆಗಳಲ್ಲಿ ಪ್ರತಿಭೆ. ರಾಜ ಸಮಾನ ಗೌರವ ಮತ್ತು ಪಂಡಿತರ ಸಮ್ಮಾನ ಪ್ರಾಪ್ತಿ.',
          descEn: 'Jupiter in 2nd/5th with Mercury/Venus. Fame in arts, learning and culture. Talent in music, dance, painting and similar arts. Receives royal respect and scholarly recognition.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 30. PARVATA YOGA
    // Benefics in Kendras and no malefics in 6/8
    // ═══════════════════════════════════════
    {
      final beneficsInKendra = _benefics.any((p) => _kendras.contains(houseOf(p)));
      final malefics = [_sun, _mars, _sat];
      final maleficIn68 = malefics.any((p) => houseOf(p) == 6 || houseOf(p) == 8);
      if (beneficsInKendra && !maleficIn68) {
        yogas.add(const YogaResult(
          nameKn: 'ಪರ್ವತ ಯೋಗ',
          nameEn: 'Parvata Yoga',
          category: 'raja',
          descKn: 'ಕೇಂದ್ರದಲ್ಲಿ ಶುಭಗ್ರಹ ಮತ್ತು ೬/೮ರಲ್ಲಿ ಪಾಪಗ್ರಹ ಇಲ್ಲದಿದ್ದರೆ. ಕೀರ್ತಿ, ಧರ್ಮ ಮತ್ತು ಅಧಿಕಾರ. ಸಮಾಜದಲ್ಲಿ ಗಣ್ಯ ವ್ಯಕ್ತಿಯಾಗಿ ಗೌರವ ಪಡೆಯುತ್ತಾರೆ. ಧಾರ್ಮಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಮತ್ತು ಸಮಾಜ ಸೇವೆಯಲ್ಲಿ ಮುಂಚೂಣಿಯಲ್ಲಿರುತ್ತಾರೆ.',
          descEn: 'Benefics in Kendra, no malefics in 6/8. Fame, virtue and authority. Respected as a distinguished person in society. Leads in religious activities and social service.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 31. PUSHKALA YOGA
    // Lagna lord and Moon's rashi lord in Kendra, aspected by/conjunct a strong planet
    // ═══════════════════════════════════════
    {
      final lagnaLord = lordOfHouse(1);
      final moonRashi = planets[_moon]?.rashiIndex ?? 0;
      final moonLord = _rashiLord[moonRashi];
      final lagnaLordH = houseOf(lagnaLord);
      final moonLordH = houseOf(moonLord);
      if (_kendras.contains(lagnaLordH) && _kendras.contains(moonLordH)) {
        yogas.add(const YogaResult(
          nameKn: 'ಪುಷ್ಕಳ ಯೋಗ',
          nameEn: 'Pushkala Yoga',
          category: 'dhana',
          descKn: 'ಲಗ್ನಾಧಿಪತಿ ಮತ್ತು ಚಂದ್ರ ರಾಶಿ ಅಧಿಪತಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಸಂಪತ್ತು, ಪ್ರಸಿದ್ಧಿ ಮತ್ತು ಸುಖ. ಜನಪ್ರಿಯತೆ ಮತ್ತು ಸಾರ್ವಜನಿಕ ಜೀವನದಲ್ಲಿ ಯಶಸ್ಸು. ಕುಟುಂಬ ಸುಖ ಮತ್ತು ಸಮೃದ್ಧ ಜೀವನ ನಡೆಸುತ್ತಾರೆ.',
          descEn: 'Lagna lord and Moon sign lord in Kendras. Wealth, fame and comfort. Popularity and success in public life. Enjoys family happiness and a prosperous life.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 32. CHAMARA YOGA
    // Lagna lord exalted in Kendra, aspected by Jupiter
    // ═══════════════════════════════════════
    {
      final lagnaLord = lordOfHouse(1);
      final lagnaLordH = houseOf(lagnaLord);
      if (_kendras.contains(lagnaLordH) && isExalted(lagnaLord)) {
        yogas.add(const YogaResult(
          nameKn: 'ಚಾಮರ ಯೋಗ',
          nameEn: 'Chamara Yoga',
          category: 'raja',
          descKn: 'ಲಗ್ನಾಧಿಪತಿ ಉಚ್ಚದಲ್ಲಿ ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ರಾಜ ಗೌರವ, ವಿದ್ಯೆ ಮತ್ತು ವಾಕ್ಶಕ್ತಿ. ಸರ್ಕಾರದಿಂದ ಸಮ್ಮಾನ ಮತ್ತು ಪ್ರಶಸ್ತಿ ಲಭಿಸುತ್ತದೆ. ಉತ್ತಮ ವಾಗ್ಮಿ ಮತ್ತು ವಿದ್ವಾಂಸರಾಗಿ ಪ್ರಸಿದ್ಧಿ ಹೊಂದುತ್ತಾರೆ.',
          descEn: 'Lagna lord exalted in Kendra. Royal honour, learning and eloquence. Receives government honours and awards. Gains fame as an excellent orator and scholar.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 33. SHRINATHA YOGA
    // Lord of 7th exalted in 10th
    // ═══════════════════════════════════════
    {
      final lord7 = lordOfHouse(7);
      if (houseOf(lord7) == 10 && isExalted(lord7)) {
        yogas.add(const YogaResult(
          nameKn: 'ಶ್ರೀನಾಥ ಯೋಗ',
          nameEn: 'Shrinatha Yoga',
          category: 'raja',
          descKn: '೭ನೇ ಅಧಿಪತಿ ಉಚ್ಚದಲ್ಲಿ ೧೦ನೇ ಮನೆಯಲ್ಲಿದ್ದರೆ. ಸಮಾಜದಲ್ಲಿ ಉನ್ನತ ಸ್ಥಾನ ಮತ್ತು ಗೌರವ. ಸಾಂಗತ್ಯ ಮತ್ತು ವ್ಯಾಪಾರ ಸಂಬಂಧಗಳಿಂದ ಉನ್ನತಿ. ಸಮಾಜದಲ್ಲಿ ಪ್ರಭಾವಶಾಲಿ ಮತ್ತು ಜನಪ್ರಿಯ ವ್ಯಕ್ತಿಯಾಗುತ್ತಾರೆ.',
          descEn: 'Lord of 7th exalted in 10th. High status and respect in society. Rise through partnerships and business relationships. Becomes an influential and popular person in society.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 34. BHERI YOGA
    // Lord of 9th strong, Jupiter in Kendra, lord of Lagna with Venus
    // ═══════════════════════════════════════
    {
      final lord9 = lordOfHouse(9);
      final jupH = houseOf(_jup);
      if (_kendras.contains(jupH) && (isInOwnSign(lord9) || isExalted(lord9))) {
        yogas.add(const YogaResult(
          nameKn: 'ಭೇರಿ ಯೋಗ',
          nameEn: 'Bheri Yoga',
          category: 'dhana',
          descKn: '೯ನೇ ಅಧಿಪತಿ ಬಲಿಷ್ಠ, ಗುರು ಕೇಂದ್ರದಲ್ಲಿದ್ದರೆ. ಧನ, ಧರ್ಮ ಮತ್ತು ದೀರ್ಘಾಯುಷ್ಯ. ಪೂರ್ವ ಪುಣ್ಯದ ಫಲವಾಗಿ ಸಮೃದ್ಧ ಜೀವನ. ಧಾರ್ಮಿಕ ಕಾರ್ಯಗಳಲ್ಲಿ ಆಸಕ್ತಿ ಮತ್ತು ಆರೋಗ್ಯಕರ ದೀರ್ಘ ಜೀವನ.',
          descEn: 'Lord of 9th strong, Jupiter in Kendra. Wealth, virtue and longevity. Prosperous life as fruit of past merits. Interest in religious activities and long healthy life.',
        ));
      }
    }

    // ═══════════════════════════════════════
    // 35. CHATURMUKHA YOGA
    // Jupiter in Kendra, Venus in Kendra, Lagna lord strong
    // ═══════════════════════════════════════
    {
      final jupH = houseOf(_jup);
      final venH = houseOf(_ven);
      final lagnaLord = lordOfHouse(1);
      if (_kendras.contains(jupH) && _kendras.contains(venH) &&
          (isInOwnSign(lagnaLord) || isExalted(lagnaLord))) {
        yogas.add(const YogaResult(
          nameKn: 'ಚತುರ್ಮುಖ ಯೋಗ',
          nameEn: 'Chaturmukha Yoga',
          category: 'raja',
          descKn: 'ಗುರು ಮತ್ತು ಶುಕ್ರ ಕೇಂದ್ರದಲ್ಲಿ, ಲಗ್ನಾಧಿಪತಿ ಬಲಿಷ್ಠವಾಗಿದ್ದರೆ. ಸರ್ವ ಸುಖ, ವಿದ್ಯೆ ಮತ್ತು ಪ್ರಸಿದ್ಧಿ. ಎಲ್ಲಾ ಕ್ಷೇತ್ರಗಳಲ್ಲಿ ಯಶಸ್ಸು ಮತ್ತು ಜನರ ಪ್ರೀತಿ. ಬ್ರಹ್ಮನಂತೆ ಸೃಜನಶೀಲ ಮತ್ತು ಬಹುಮುಖ ಪ್ರತಿಭೆ ಉಳ್ಳವರಾಗಿರುತ್ತಾರೆ.',
          descEn: 'Jupiter and Venus in Kendras, Lagna lord strong. All comforts, learning and fame. Success in all fields with people\'s affection. Creative and multi-talented like Lord Brahma.',
        ));
      }
    }


    return yogas;
  }
}
