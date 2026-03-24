/// Ashtaka Varga calculation engine.
///
/// Computes Bhinnashtaka Varga (BAV) and Sarvashtaka Varga (SAV)
/// for the 7 planets (Sun through Saturn) plus Lagna.

class AshtakaVarga {
  // Planet order for Ashtaka Varga (7 planets + Lagna)
  static const List<String> planets = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];
  static const List<String> planetsWithLagna = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ', 'ಲಗ್ನ'];

  // Benefic positions (houses from each contributing planet/lagna)
  // Key: target planet, Value: map of contributing planet → list of benefic houses
  // Based on Parashari Ashtaka Varga rules

  // Sun's BAV contributions from each planet
  static const Map<String, List<int>> _sunBav = {
    'ರವಿ':   [1, 2, 4, 7, 8, 9, 10, 11],
    'ಚಂದ್ರ': [3, 6, 10, 11],
    'ಕುಜ':   [1, 2, 4, 7, 8, 9, 10, 11],
    'ಬುಧ':   [3, 5, 6, 9, 10, 11, 12],
    'ಗುರು':  [5, 6, 9, 11],
    'ಶುಕ್ರ': [6, 7, 12],
    'ಶನಿ':   [1, 2, 4, 7, 8, 9, 10, 11],
    'ಲಗ್ನ':  [3, 4, 6, 10, 11, 12],
  };

  // Moon's BAV
  static const Map<String, List<int>> _moonBav = {
    'ರವಿ':   [3, 6, 7, 8, 10, 11],
    'ಚಂದ್ರ': [1, 3, 6, 7, 10, 11],
    'ಕುಜ':   [2, 3, 5, 6, 9, 10, 11],
    'ಬುಧ':   [1, 3, 4, 5, 7, 8, 10, 11],
    'ಗುರು':  [1, 4, 7, 8, 10, 11, 12],
    'ಶುಕ್ರ': [3, 4, 5, 7, 9, 10, 11],
    'ಶನಿ':   [3, 5, 6, 11],
    'ಲಗ್ನ':  [3, 6, 10, 11],
  };

  // Mars' BAV
  static const Map<String, List<int>> _marsBav = {
    'ರವಿ':   [3, 5, 6, 10, 11],
    'ಚಂದ್ರ': [3, 6, 11],
    'ಕುಜ':   [1, 2, 4, 7, 8, 10, 11],
    'ಬುಧ':   [3, 5, 6, 11],
    'ಗುರು':  [6, 10, 11, 12],
    'ಶುಕ್ರ': [6, 8, 11, 12],
    'ಶನಿ':   [1, 4, 7, 8, 9, 10, 11],
    'ಲಗ್ನ':  [1, 3, 6, 10, 11],
  };

  // Mercury's BAV
  static const Map<String, List<int>> _mercuryBav = {
    'ರವಿ':   [5, 6, 9, 11, 12],
    'ಚಂದ್ರ': [2, 4, 6, 8, 10, 11],
    'ಕುಜ':   [1, 2, 4, 7, 8, 9, 10, 11],
    'ಬುಧ':   [1, 3, 5, 6, 9, 10, 11, 12],
    'ಗುರು':  [6, 8, 11, 12],
    'ಶುಕ್ರ': [1, 2, 3, 4, 5, 8, 9, 11],
    'ಶನಿ':   [1, 2, 4, 7, 8, 9, 10, 11],
    'ಲಗ್ನ':  [1, 2, 4, 6, 8, 10, 11],
  };

  // Jupiter's BAV
  static const Map<String, List<int>> _jupiterBav = {
    'ರವಿ':   [1, 2, 3, 4, 7, 8, 9, 10, 11],
    'ಚಂದ್ರ': [2, 5, 7, 9, 11],
    'ಕುಜ':   [1, 2, 4, 7, 8, 10, 11],
    'ಬುಧ':   [1, 2, 4, 5, 6, 9, 10, 11],
    'ಗುರು':  [1, 2, 3, 4, 7, 8, 10, 11],
    'ಶುಕ್ರ': [2, 5, 6, 9, 10, 11],
    'ಶನಿ':   [3, 5, 6, 12],
    'ಲಗ್ನ':  [1, 2, 4, 5, 6, 7, 9, 10, 11],
  };

  // Venus' BAV
  static const Map<String, List<int>> _venusBav = {
    'ರವಿ':   [8, 11, 12],
    'ಚಂದ್ರ': [1, 2, 3, 4, 5, 8, 9, 11, 12],
    'ಕುಜ':   [3, 5, 6, 9, 11, 12],
    'ಬುಧ':   [3, 5, 6, 9, 11],
    'ಗುರು':  [5, 8, 9, 10, 11],
    'ಶುಕ್ರ': [1, 2, 3, 4, 5, 8, 9, 10, 11],
    'ಶನಿ':   [3, 4, 5, 8, 9, 10, 11],
    'ಲಗ್ನ':  [1, 2, 3, 4, 5, 8, 9, 11],
  };

  // Saturn's BAV
  static const Map<String, List<int>> _saturnBav = {
    'ರವಿ':   [1, 2, 4, 7, 8, 10, 11],
    'ಚಂದ್ರ': [3, 6, 11],
    'ಕುಜ':   [3, 5, 6, 10, 11, 12],
    'ಬುಧ':   [6, 8, 9, 10, 11, 12],
    'ಗುರು':  [5, 6, 11, 12],
    'ಶುಕ್ರ': [6, 11, 12],
    'ಶನಿ':   [3, 5, 6, 11],
    'ಲಗ್ನ':  [1, 3, 4, 6, 10, 11],
  };

  static const Map<String, Map<String, List<int>>> _allBav = {
    'ರವಿ':    _sunBav,
    'ಚಂದ್ರ':  _moonBav,
    'ಕುಜ':    _marsBav,
    'ಬುಧ':    _mercuryBav,
    'ಗುರು':   _jupiterBav,
    'ಶುಕ್ರ':  _venusBav,
    'ಶನಿ':    _saturnBav,
  };

  /// Compute Bhinnashtaka Varga for a single planet.
  /// Returns a List<int> of 12 values (bindus for each rashi 0-11).
  static List<int> computeBAV(String targetPlanet, Map<String, int> rashiPositions) {
    final bavRules = _allBav[targetPlanet];
    if (bavRules == null) return List.filled(12, 0);

    final bindus = List.filled(12, 0);

    for (final contributor in bavRules.entries) {
      final contribName = contributor.key;
      final beneficHouses = contributor.value;

      // Get the rashi index of the contributing planet/lagna
      final contribRashi = rashiPositions[contribName];
      if (contribRashi == null) continue;

      for (final house in beneficHouses) {
        // house 1 = same rashi as contributor, house 2 = next rashi, etc.
        final targetRashi = (contribRashi + house - 1) % 12;
        bindus[targetRashi]++;
      }
    }

    return bindus;
  }

  /// Compute all BAVs and SAV.
  /// Returns a map: planet name → List<int> of 12 bindus, plus 'SAV' key.
  static Map<String, List<int>> computeAll(Map<String, int> rashiPositions) {
    final result = <String, List<int>>{};
    final sav = List.filled(12, 0);

    for (final planet in planets) {
      final bav = computeBAV(planet, rashiPositions);
      result[planet] = bav;
      for (int i = 0; i < 12; i++) {
        sav[i] += bav[i];
      }
    }

    result['SAV'] = sav;
    return result;
  }
}
