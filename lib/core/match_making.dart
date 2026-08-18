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

  // ── DVADASHA KOOTA: 4 additional kootas ──

  // 9. Mahendra (1 Point)
  // Count nakshatras from bride to groom. If (count-1) % 9 ∈ {0,3,6} → 1 pt
  static double getMahendraScore(int brideNak, int groomNak) {
    final count = ((groomNak - brideNak + 27) % 27);
    final mod = count % 9;
    return (mod == 0 || mod == 3 || mod == 6) ? 1.0 : 0.0;
  }

  // 10. Stree Deergha (1 Point)
  // If groom nakshatra is >= 13 nakshatras away from bride → 1 pt
  static double getStreeDeerghaScore(int brideNak, int groomNak) {
    final diff = ((groomNak - brideNak + 27) % 27);
    return diff >= 13 ? 1.0 : 0.0;
  }

  // 11. Rajju (1 Point)
  // Body part mapping. Same rajju group = 0 (bad), different = 1 (good)
  static double getRajjuScore(int brideNak, int groomNak) {
    // Rajju groups: 0=Paada(feet), 1=Kati(hip), 2=Nabhi(navel), 3=Kantha(neck), 4=Shira(head)
    int getRajju(int nak) {
      const map = [
        4, 3, 2, 1, 0, // Ashwini..Mrigashira (ascending)
        1, 2, 3, 4,     // Ardra..Pushya (descending)
        4, 3, 2, 1, 0, // Ashlesha..Hasta (ascending)
        1, 2, 3, 4,     // Chitra..Anuradha (descending)
        4, 3, 2, 1, 0, // Jyeshtha..Shravana (ascending)
        1, 2, 3, 4,     // Dhanishtha..Revati (descending)
      ];
      return map[nak % 27];
    }
    return getRajju(brideNak) == getRajju(groomNak) ? 0.0 : 1.0;
  }

  // 12. Vedha (1 Point)
  // Specific nakshatra pairs cause vedha. No vedha = 1 pt
  static double getVedhaScore(int brideNak, int groomNak) {
    // Vedha pairs (0-indexed nakshatras)
    const vedhaPairs = <List<int>>[
      [0, 17],  // Ashwini - Jyeshtha
      [1, 16],  // Bharani - Anuradha
      [2, 18],  // Krittika - Moola (based on some texts: Dhanishtha)
      [3, 19],  // Rohini - Shravana → Swati
      [4, 22],  // Mrigashira - Dhanishtha
      [5, 21],  // Ardra - Shravana
      [6, 20],  // Punarvasu - Purvashadha
      [7, 19],  // Pushya - Uttarashadha
      [8, 18],  // Ashlesha - Moola
      [9, 26],  // Magha - Revati
      [10, 25], // P.Phalguni - U.Bhadrapada
      [11, 24], // U.Phalguni - P.Bhadrapada
      [12, 23], // Hasta - Shatabhisha
      [13, 22], // Chitra - Dhanishtha  (duplicate intentional for reverse)
      [14, 21], // Swati - Shravana
      [15, 20], // Vishakha - Purvashadha
    ];
    for (final pair in vedhaPairs) {
      if ((brideNak == pair[0] && groomNak == pair[1]) ||
          (brideNak == pair[1] && groomNak == pair[0])) {
        return 0.0; // Vedha present
      }
    }
    return 1.0; // No vedha
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

  /// Dvadasha Koota: 12 kootas, max 40 points
  static Map<String, dynamic> calculateDvadashaKoota(int bRashi, int bNak, int gRashi, int gNak) {
    double varna = getVarnaScore(bRashi, gRashi);
    double vashya = getVashyaScore(bRashi, gRashi);
    double tara = getTaraScore(bNak, gNak);
    double yoni = getYoniScore(bNak, gNak);
    double graha = getGrahaMaitriScore(bRashi, gRashi);
    double gana = getGanaScore(bNak, gNak);
    double bhakoot = getBhakootScore(bRashi, gRashi);
    double nadi = getNadiScore(bNak, gNak);
    double mahendra = getMahendraScore(bNak, gNak);
    double streeDeergha = getStreeDeerghaScore(bNak, gNak);
    double rajju = getRajjuScore(bNak, gNak);
    double vedha = getVedhaScore(bNak, gNak);

    double total = varna + vashya + tara + yoni + graha + gana + bhakoot + nadi +
        mahendra + streeDeergha + rajju + vedha;

    return {
      'varna': varna,
      'vashya': vashya,
      'tara': tara,
      'yoni': yoni,
      'graha': graha,
      'gana': gana,
      'bhakoot': bhakoot,
      'nadi': nadi,
      'mahendra': mahendra,
      'streeDeergha': streeDeergha,
      'rajju': rajju,
      'vedha': vedha,
      'total': total,
    };
  }

  /// Check Kuja Dosha from a reference point (bhava-based)
  static int _kujaHouseCheck(int bhavaHouse) {
    return const [1, 2, 4, 7, 8, 12].contains(bhavaHouse) ? bhavaHouse : 0;
  }

  /// Calculate Kuja Dosha using proper bhava recalculation for each reference
  /// bhavaFromLagna: planet -> bhava house (1-12) from Lagna
  /// bhavaFromChandra: planet -> bhava house (1-12) from Chandra
  /// bhavaFromShukra: planet -> bhava house (1-12) from Shukra
  static Map<String, dynamic> calculateKujaDosha(
    Map<String, int> bhavaFromLagna, {
    Map<String, int>? bhavaFromChandra,
    Map<String, int>? bhavaFromShukra,
  }) {
    // Kuja's bhava house from Lagna
    final fromLagna = _kujaHouseCheck(bhavaFromLagna['ಕುಜ'] ?? 0);
    // Kuja's bhava house from Chandra (proper bhava recalc)
    final fromChandra = _kujaHouseCheck(
      (bhavaFromChandra ?? bhavaFromLagna)['ಕುಜ'] ?? 0);
    // Kuja's bhava house from Shukra (proper bhava recalc)
    final fromShukra = _kujaHouseCheck(
      (bhavaFromShukra ?? bhavaFromLagna)['ಕುಜ'] ?? 0);

    return {
      'fromLagna': fromLagna,
      'fromChandra': fromChandra,
      'fromShukra': fromShukra,
      'hasDosha': fromLagna > 0 || fromChandra > 0 || fromShukra > 0,
    };
  }

  static const List<String> _papaGrahas = ['ರವಿ', 'ಕುಜ', 'ಶನಿ', 'ರಾಹು', 'ಕೇತು'];

  /// Count papa grahas in dosha houses (1,2,4,7,8,12)
  /// Each papa graha counted individually — 2 papas in same house = count 2
  static int _countPapaInDoshaHouses(Map<String, int> bhavaHouses) {
    int count = 0;
    for (final graha in _papaGrahas) {
      final house = bhavaHouses[graha];
      if (house == null) continue;
      if (const [1, 2, 4, 7, 8, 12].contains(house)) count++;
    }
    return count;
  }

  /// Calculate Papa Dosha using proper bhava recalculation for each reference
  static Map<String, dynamic> calculatePapaDosha(
    Map<String, int> bhavaFromLagna, {
    Map<String, int>? bhavaFromChandra,
    Map<String, int>? bhavaFromShukra,
  }) {
    final fromLagna = _countPapaInDoshaHouses(bhavaFromLagna);
    final fromChandra = _countPapaInDoshaHouses(bhavaFromChandra ?? bhavaFromLagna);
    final fromShukra = _countPapaInDoshaHouses(bhavaFromShukra ?? bhavaFromLagna);
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
    //        Sun  Moon Mars Merc Jup  Ven  Sat
    /* Sun */  [ 0,  1,  1,  0,  1, -1, -1],
    /* Moon */ [ 1,  0,  0,  1,  0,  0,  0],
    /* Mars */ [ 1,  1,  0, -1,  1,  0,  0],
    /* Merc */ [ 1, -1,  0,  0,  0,  1,  0],
    /* Jup */  [ 1,  1,  1, -1,  0, -1,  0],
    /* Ven */  [-1, -1,  0,  1,  0,  0,  1],
    /* Sat */  [-1, -1, -1,  1,  0,  1,  0],
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
    Map<String, int>? brideBhavaHouses,
    Map<String, int>? groomBhavaHouses,
    Map<String, int>? brideBhavaFromChandra,
    Map<String, int>? groomBhavaFromChandra,
    Map<String, int>? brideBhavaFromShukra,
    Map<String, int>? groomBhavaFromShukra,
  }) {
    // Use bhava houses for dosha if available, fallback to rashi-based
    final bBhava = brideBhavaHouses ?? bridePlanetRashis;
    final gBhava = groomBhavaHouses ?? groomPlanetRashis;
    return {
      'ashtaKoota': calculateCompatibility(brideMoonRashi, brideNakIdx, groomMoonRashi, groomNakIdx),
      'dvadashaKoota': calculateDvadashaKoota(brideMoonRashi, brideNakIdx, groomMoonRashi, groomNakIdx),
      'brideKujaDosha': calculateKujaDosha(bBhava,
        bhavaFromChandra: brideBhavaFromChandra, bhavaFromShukra: brideBhavaFromShukra),
      'groomKujaDosha': calculateKujaDosha(gBhava,
        bhavaFromChandra: groomBhavaFromChandra, bhavaFromShukra: groomBhavaFromShukra),
      'bridePapaDosha': calculatePapaDosha(bBhava,
        bhavaFromChandra: brideBhavaFromChandra, bhavaFromShukra: brideBhavaFromShukra),
      'groomPapaDosha': calculatePapaDosha(gBhava,
        bhavaFromChandra: groomBhavaFromChandra, bhavaFromShukra: groomBhavaFromShukra),
      'papaSamya': checkPapaSamya(
        calculatePapaDosha(bBhava,
          bhavaFromChandra: brideBhavaFromChandra, bhavaFromShukra: brideBhavaFromShukra),
        calculatePapaDosha(gBhava,
          bhavaFromChandra: groomBhavaFromChandra, bhavaFromShukra: groomBhavaFromShukra),
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
