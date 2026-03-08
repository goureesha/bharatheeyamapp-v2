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
}
