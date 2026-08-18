class MatchMakingLogic {
  static const Map<int, List<int>> _rashiNakMap = {
    0: [0, 1, 2],       // Mesha
    1: [2, 3, 4],       // Vrishabha
    2: [4, 5, 6],       // Mithuna
    3: [6, 7, 8],       // Karka
    4: [9, 10, 11],     // Simha
    5: [11, 12, 13],    // Kanya
    6: [13, 14, 15],    // Tula
    7: [15, 16, 17],    // Vrischika
    8: [18, 19, 20],    // Dhanu
    9: [20, 21, 22],    // Makara
    10: [22, 23, 24],   // Kumbha
    11: [24, 25, 26],   // Meena
  };

  // 1. Varna (1 Point) Based on Moon Sign
  static double getVarnaScore(int brideRashi, int groomRashi) {
    int getVarna(int rashi) {
      if ([3, 7, 11].contains(rashi)) return 0; // Brahmin
      if ([0, 4, 8].contains(rashi)) return 1;  // Kshatriya
      if ([1, 5, 9].contains(rashi)) return 2;  // Vaishya
      return 3; // Shudra
    }
    const points = [
      [1.0, 0.0, 0.0, 0.0],
      [1.0, 1.0, 0.0, 0.0],
      [1.0, 1.0, 1.0, 0.0],
      [1.0, 1.0, 1.0, 1.0],
    ];
    return points[getVarna(brideRashi)][getVarna(groomRashi)];
  }

  // 2. Vashya (2 Points)
  static double getVashyaScore(int brideRashi, int groomRashi) {
    int getGroup(int rashi) {
      if ([2, 5, 6, 8, 10].contains(rashi)) return 0; // Manav
      if (rashi == 4) return 1; // Vanchar
      if ([0, 1, 9].contains(rashi)) return 2; // Chatushpad
      if ([3, 9, 11].contains(rashi)) return 3; // Jalchar
      return 4; // Keet
    }
    const points = [
      [2.0, 0.5, 1.0, 0.0, 2.0],
      [0.5, 2.0, 0.0, 0.0, 0.0],
      [1.0, 0.0, 2.0, 2.0, 2.0],
      [0.0, 0.0, 2.0, 2.0, 0.0],
      [1.0, 0.0, 1.0, 0.0, 2.0],
    ];
    return points[getGroup(brideRashi)][getGroup(groomRashi)];
  }

  // 3. Tara (3 Points)
  static double getTaraScore(int brideNak, int groomNak) {
    int getTaraGroup(int nak) => nak % 9;
    const points = [
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [1.5, 1.5, 0.0, 1.5, 0.0, 1.5, 0.0, 1.5, 1.5],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [1.5, 1.5, 0.0, 1.5, 0.0, 1.5, 0.0, 1.5, 1.5],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [1.5, 1.5, 0.0, 1.5, 0.0, 1.5, 0.0, 1.0, 1.0],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
      [3.0, 3.0, 1.5, 3.0, 1.5, 3.0, 1.5, 3.0, 3.0],
    ];
    return points[getTaraGroup(brideNak)][getTaraGroup(groomNak)];
  }

  // 4. Yoni (4 Points)
  static double getYoniScore(int brideNak, int groomNak) {
    const animalMap = [0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 11, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1];
    const points = [
      [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 1, 3, 2, 1],
      [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
      [2, 3, 4, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
      [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2],
      [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1],
      [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1],
      [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2],
      [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1],
      [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 2],
      [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1],
      [1, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1],
      [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2],
      [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2],
      [1, 0, 1, 2, 1, 1, 2, 1, 2, 1, 1, 2, 2, 4]
    ];
    return points[animalMap[brideNak]][animalMap[groomNak]].toDouble();
  }

  // 5. Graha Maitri (5 Points)
  static double getGrahaMaitriScore(int brideRashi, int groomRashi) {
    int getLord(int rashi) {
      if (rashi == 4) return 0; // Sun
      if (rashi == 3) return 1; // Moon
      if (rashi == 0 || rashi == 7) return 2; // Mars
      if (rashi == 2 || rashi == 5) return 3; // Merc
      if (rashi == 8 || rashi == 11) return 4; // Jup
      if (rashi == 1 || rashi == 6) return 5; // Ven
      return 6; // Sat
    }
    const points = [
      [5.0, 5.0, 5.0, 4.0, 5.0, 0.0, 0.0],
      [5.0, 5.0, 4.0, 1.0, 4.0, 0.5, 0.5],
      [5.0, 4.0, 5.0, 0.5, 5.0, 3.0, 0.5],
      [4.0, 1.0, 0.5, 5.0, 0.5, 5.0, 4.0],
      [5.0, 4.0, 5.0, 0.5, 5.0, 0.5, 4.0],
      [0.0, 0.5, 3.0, 5.0, 0.5, 5.0, 5.0],
      [0.0, 0.5, 0.5, 4.0, 4.0, 5.0, 5.0]
    ];
    return points[getLord(brideRashi)][getLord(groomRashi)];
  }

  // 6. Gana (6 Points)
  static double getGanaScore(int brideNak, int groomNak) {
    int getTemperament(int nak) {
      if ([0, 4, 6, 7, 12, 14, 16, 21, 26].contains(nak)) return 0; // Deva
      if ([1, 3, 5, 10, 11, 19, 20, 24, 25].contains(nak)) return 1; // Manushya
      return 2; // Rakshasa
    }
    const points = [
      [6.0, 3.0, 1.0],
      [5.0, 6.0, 3.0],
      [0.0, 0.0, 6.0],
    ];
    return points[getTemperament(brideNak)][getTemperament(groomNak)];
  }

  // 7. Bhakoot (7 Points) 12x12 Precise Matrix
  static double getBhakootScore(int brideRashi, int groomRashi) {
    const points = [
      [7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0],
      [0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0],
      [7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0],
      [7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0],
      [0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0],
      [0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0],
      [7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0],
      [0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0, 0.0],
      [0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0, 7.0],
      [7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0, 7.0],
      [7.0, 7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0, 0.0],
      [0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0, 7.0],
    ];
    return points[brideRashi][groomRashi];
  }

  // 8. Nadi (8 Points)
  static double getNadiScore(int brideNak, int groomNak) {
    int getNadi(int nak) {
      if ([0, 5, 6, 11, 12, 17, 18, 23, 24].contains(nak)) return 0; // Adi
      if ([1, 4, 7, 10, 13, 16, 19, 22, 25].contains(nak)) return 1; // Madhya
      return 2; // Antya
    }
    const points = [
      [0.0, 8.0, 8.0],
      [8.0, 0.0, 8.0],
      [8.0, 8.0, 0.0],
    ];
    return points[getNadi(brideNak)][getNadi(groomNak)];
  }

  static Map<String, dynamic> calculateCompatibility(int bRashi, int bNak, int gRashi, int gNak) {
    double varna = getVarnaScore(bRashi, gRashi);
    double vashya = getVashyaScore(bRashi, gRashi);
    double tara = getTaraScore(bNak, gNak);
    double yoni = getYoniScore(bNak, gNak);
    double graha = getGrahaMaitriScore(bRashi, gRashi);
    double gana = getGanaScore(bNak, gNak);
    double bhakoot = getBhakootScore(bRashi, gRashi);
    double nadi = getNadiScore(bNak, gNak);

    double total = varna + vashya + tara + yoni + graha + gana + bhakoot + nadi;

    return {
      'varna': varna,
      'vashya': vashya,
      'tara': tara,
      'yoni': yoni,
      'graha': graha,
      'gana': gana,
      'bhakoot': bhakoot,
      'nadi': nadi,
      'total': total,
    };
  }

  /// Check Kuja Dosha from a reference point
  /// Returns house number if Kuja is in dosha house, else 0
  static int _kujaHouseFrom(int kujaRashi, int refRashi) {
    final house = ((kujaRashi - refRashi + 12) % 12) + 1;
    return const [1, 2, 4, 7, 8, 12].contains(house) ? house : 0;
  }

  /// Calculate Kuja Dosha for a person
  /// planetRashis: map of Kannada planet name -> rashi index (0-11)
  /// Returns: {fromLagna: int (house or 0), fromChandra: int, fromShukra: int, hasDosha: bool}
  static Map<String, dynamic> calculateKujaDosha(Map<String, int> planetRashis, int lagnaRashi) {
    final kujaRashi = planetRashis['ಕುಜ'] ?? 0;
    final chandraRashi = planetRashis['ಚಂದ್ರ'] ?? 0;
    final shukraRashi = planetRashis['ಶುಕ್ರ'] ?? 0;
    final fromLagna = _kujaHouseFrom(kujaRashi, lagnaRashi);
    final fromChandra = _kujaHouseFrom(kujaRashi, chandraRashi);
    final fromShukra = _kujaHouseFrom(kujaRashi, shukraRashi);
    return {
      'fromLagna': fromLagna,
      'fromChandra': fromChandra,
      'fromShukra': fromShukra,
      'hasDosha': fromLagna > 0 || fromChandra > 0 || fromShukra > 0,
    };
  }

  static const List<String> _papaGrahas = ['ರವಿ', 'ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];

  /// Count papa grahas in dosha houses from a reference rashi
  static int _countPapaInDoshaHouses(Map<String, int> planetRashis, int refRashi) {
    int count = 0;
    for (final graha in _papaGrahas) {
      final gRashi = planetRashis[graha];
      if (gRashi == null) continue;
      final house = ((gRashi - refRashi + 12) % 12) + 1;
      if (const [1, 2, 4, 7, 8, 12].contains(house)) count++;
    }
    return count;
  }

  /// Calculate Papa Dosha for a person
  static Map<String, dynamic> calculatePapaDosha(Map<String, int> planetRashis, int lagnaRashi) {
    final chandraRashi = planetRashis['ಚಂದ್ರ'] ?? 0;
    final shukraRashi = planetRashis['ಶುಕ್ರ'] ?? 0;
    final fromLagna = _countPapaInDoshaHouses(planetRashis, lagnaRashi);
    final fromChandra = _countPapaInDoshaHouses(planetRashis, chandraRashi);
    final fromShukra = _countPapaInDoshaHouses(planetRashis, shukraRashi);
    return {
      'fromLagna': fromLagna,
      'fromChandra': fromChandra,
      'fromShukra': fromShukra,
      'total': fromLagna + fromChandra + fromShukra,
    };
  }

  /// Check Papa Samya (balance) between bride and groom
  static Map<String, dynamic> checkPapaSamya(
    Map<String, dynamic> bridePapa,
    Map<String, dynamic> groomPapa,
  ) {
    final bTotal = bridePapa['total'] as int;
    final gTotal = groomPapa['total'] as int;
    final diff = (bTotal - gTotal).abs();
    return {
      'bridePapaTotal': bTotal,
      'groomPapaTotal': gTotal,
      'difference': diff,
      'isSamya': diff <= 1,
    };
  }

  /// Naisargika (Natural) Maitri table per Brihad Jataka
  /// 0=Sun, 1=Moon, 2=Mars, 3=Mercury, 4=Jupiter, 5=Venus, 6=Saturn
  /// Values: 1=Mitra, 0=Sama, -1=Shatru
  static const List<List<int>> _naisargikaMaitri = [
    // Sun
    [ 0,  1,  1, -1,  1, -1, -1],
    // Moon
    [ 1,  0, -1,  1,  1, -1, -1],
    // Mars
    [ 1,  1,  0, -1,  1, -1, -1],
    // Mercury
    [ 1, -1, -1,  0, -1,  1,  1],
    // Jupiter
    [ 1,  1,  1, -1,  0, -1, -1],
    // Venus
    [-1, -1,  0,  1, -1,  0,  1],
    // Saturn
    [-1, -1, -1,  1, -1,  1,  0],
  ];

  /// Get planet lord index (0-6) for a rashi (0-11)
  static int getRashiLord(int rashi) {
    const lords = [2, 5, 3, 1, 0, 3, 5, 2, 4, 6, 6, 4];
    return lords[rashi];
  }

  /// Planet names for lord indices
  static const List<String> lordNames = ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'];

  /// Get Naisargika Maitri relationship string
  static String getNaisargikaMaitriLabel(int planet1Lord, int planet2Lord) {
    final val = _naisargikaMaitri[planet1Lord][planet2Lord];
    if (val == 1) return 'ಮಿತ್ರ';
    if (val == -1) return 'ಶತ್ರು';
    return 'ಸಮ';
  }

  /// Calculate Graha Maitri (Natural only) for Lagna/Chandra from Rashi and Navamsha
  static Map<String, dynamic> calculateGrahaMaitriComparison({
    required int brideLagnaRashi,
    required int brideMoonRashi,
    required int brideNavLagnaRashi,
    required int brideNavMoonRashi,
    required int groomLagnaRashi,
    required int groomMoonRashi,
    required int groomNavLagnaRashi,
    required int groomNavMoonRashi,
  }) {
    Map<String, dynamic> _check(String label, int bRashi, int gRashi) {
      final bLord = getRashiLord(bRashi);
      final gLord = getRashiLord(gRashi);
      final relation = _naisargikaMaitri[bLord][gLord];
      String maitri;
      if (relation == 1) maitri = 'ಮಿತ್ರ';
      else if (relation == -1) maitri = 'ಶತ್ರು';
      else maitri = 'ಸಮ';
      return {
        'label': label,
        'brideLord': bLord,
        'groomLord': gLord,
        'brideLordName': lordNames[bLord],
        'groomLordName': lordNames[gLord],
        'relation': relation,
        'maitri': maitri,
      };
    }

    return {
      'rows': [
        _check('ಲಗ್ನಾಧಿಪತಿ', brideLagnaRashi, groomLagnaRashi),
        _check('ಚಂದ್ರ ರಾಶ್ಯಾಧಿಪತಿ', brideMoonRashi, groomMoonRashi),
        _check('ನವಾಂಶ ಲಗ್ನಾಧಿಪತಿ', brideNavLagnaRashi, groomNavLagnaRashi),
        _check('ನವಾಂಶ ಚಂದ್ರಾಧಿಪತಿ', brideNavMoonRashi, groomNavMoonRashi),
      ],
    };
  }

  /// Compute Navamsha rashi index from sidereal longitude
  static int navamshaRashi(double deg) {
    final block = (deg / 30).floor() % 4;
    final start = [0, 9, 6, 3][block];
    final steps = ((deg % 30) / 3.33333).floor();
    return (start + steps) % 12;
  }

  /// Helper: check if two rashis are in a given house relationship
  static Map<String, dynamic> _checkHouseRelation(int brideRashi, int groomRashi, List<int> doshaHouses) {
    final brideFromGroom = ((brideRashi - groomRashi + 12) % 12) + 1;
    final groomFromBride = ((groomRashi - brideRashi + 12) % 12) + 1;
    final hasDosha = doshaHouses.contains(brideFromGroom) || doshaHouses.contains(groomFromBride);
    return {
      'hasDosha': hasDosha,
      'brideFromGroom': brideFromGroom,
      'groomFromBride': groomFromBride,
    };
  }

  /// Check Shatha Ashtaka Dosha (6/8 relationship) from Chandra and Lagna
  static Map<String, dynamic> checkShathaAshtaka(int brideMoonRashi, int groomMoonRashi, int brideLagnaRashi, int groomLagnaRashi) {
    final fromChandra = _checkHouseRelation(brideMoonRashi, groomMoonRashi, const [6, 8]);
    final fromLagna = _checkHouseRelation(brideLagnaRashi, groomLagnaRashi, const [6, 8]);
    return {
      'fromChandra': fromChandra,
      'fromLagna': fromLagna,
      'hasDosha': fromChandra['hasDosha'] || fromLagna['hasDosha'],
    };
  }

  /// Check Dvirdvadasha Dosha (2/12 relationship) from Chandra and Lagna
  static Map<String, dynamic> checkDvirdvadasha(int brideMoonRashi, int groomMoonRashi, int brideLagnaRashi, int groomLagnaRashi) {
    final fromChandra = _checkHouseRelation(brideMoonRashi, groomMoonRashi, const [2, 12]);
    final fromLagna = _checkHouseRelation(brideLagnaRashi, groomLagnaRashi, const [2, 12]);
    return {
      'fromChandra': fromChandra,
      'fromLagna': fromLagna,
      'hasDosha': fromChandra['hasDosha'] || fromLagna['hasDosha'],
    };
  }

  /// Full compatibility analysis using KundaliResult data
  static Map<String, dynamic> calculateFullCompatibility({
    required int brideNakIdx,
    required int brideMoonRashi,
    required int brideLagnaRashi,
    required Map<String, int> bridePlanetRashis,
    required int brideNavLagnaRashi,
    required int brideNavMoonRashi,
    required int groomNakIdx,
    required int groomMoonRashi,
    required int groomLagnaRashi,
    required Map<String, int> groomPlanetRashis,
    required int groomNavLagnaRashi,
    required int groomNavMoonRashi,
  }) {
    return {
      'ashtaKoota': calculateCompatibility(brideMoonRashi, brideNakIdx, groomMoonRashi, groomNakIdx),
      'brideKujaDosha': calculateKujaDosha(bridePlanetRashis, brideLagnaRashi),
      'groomKujaDosha': calculateKujaDosha(groomPlanetRashis, groomLagnaRashi),
      'bridePapaDosha': calculatePapaDosha(bridePlanetRashis, brideLagnaRashi),
      'groomPapaDosha': calculatePapaDosha(groomPlanetRashis, groomLagnaRashi),
      'papaSamya': checkPapaSamya(
        calculatePapaDosha(bridePlanetRashis, brideLagnaRashi),
        calculatePapaDosha(groomPlanetRashis, groomLagnaRashi),
      ),
      'grahaMaitri': calculateGrahaMaitriComparison(
        brideLagnaRashi: brideLagnaRashi, brideMoonRashi: brideMoonRashi,
        brideNavLagnaRashi: brideNavLagnaRashi, brideNavMoonRashi: brideNavMoonRashi,
        groomLagnaRashi: groomLagnaRashi, groomMoonRashi: groomMoonRashi,
        groomNavLagnaRashi: groomNavLagnaRashi, groomNavMoonRashi: groomNavMoonRashi,
      ),
      'shathaAshtaka': checkShathaAshtaka(brideMoonRashi, groomMoonRashi, brideLagnaRashi, groomLagnaRashi),
      'dvirdvadasha': checkDvirdvadasha(brideMoonRashi, groomMoonRashi, brideLagnaRashi, groomLagnaRashi),
    };
  }
}
