class MatchMakingLogic {
  static const Map<int, List<int>> _rashiNakMap = {
    0: [0, 1, 2],       // Mesha: Ashwini, Bharani, Krittika
    1: [2, 3, 4],       // Vrishabha: Krittika, Rohini, Mrigashira
    2: [4, 5, 6],       // Mithuna: Mrigashira, Ardra, Punarvasu
    3: [6, 7, 8],       // Karka: Punarvasu, Pushya, Ashlesha
    4: [9, 10, 11],     // Simha: Magha, Purva Phalguni, Uttara Phalguni
    5: [11, 12, 13],    // Kanya: Uttara Phalguni, Hasta, Chitra
    6: [13, 14, 15],    // Tula: Chitra, Swati, Vishakha
    7: [15, 16, 17],    // Vrischika: Vishakha, Anuradha, Jyeshtha
    8: [18, 19, 20],    // Dhanu: Mula, Purva Ashadha, Uttara Ashadha
    9: [20, 21, 22],    // Makara: Uttara Ashadha, Shravana, Dhanishta
    10: [22, 23, 24],   // Kumbha: Dhanishta, Shatabhisha, Purva Bhadrapada
    11: [24, 25, 26],   // Meena: Purva Bhadrapada, Uttara Bhadrapada, Revati
  };

  // 1. Varna (1 Point) Based on Rashi
  // Brahmin: 3, 7, 11
  // Kshatriya: 0, 4, 8
  // Vaishya: 1, 5, 9
  // Shudra: 2, 6, 10
  static double getVarnaScore(int brideRashi, int groomRashi) {
    int getVarna(int rashi) {
      if ([3, 7, 11].contains(rashi)) return 4;
      if ([0, 4, 8].contains(rashi)) return 3;
      if ([1, 5, 9].contains(rashi)) return 2;
      return 1;
    }
    int bVarna = getVarna(brideRashi);
    int gVarna = getVarna(groomRashi);
    return (gVarna >= bVarna) ? 1.0 : 0.0;
  }

  // 2. Vashya (2 Points) Based on Rashi Type
  static double getVashyaScore(int brideRashi, int groomRashi) {
    int getType(int r) {
      if ([0, 1, 8].contains(r)) return 0; // Quadruped
      if ([2, 5, 6, 10].contains(r)) return 1; // Human
      if ([3, 9, 11].contains(r)) return 2; // Water
      if (r == 4) return 3; // Wild
      if (r == 7) return 4; // Insect
      return 0;
    }
    int bTyp = getType(brideRashi);
    int gTyp = getType(groomRashi);
    
    const vashyaMatrix = [
      // B=Q, B=H, B=Wa, B=Wi, B=I
      [2.0, 1.0, 1.0, 0.5, 1.0], // G=Q
      [1.0, 2.0, 0.5, 0.0, 1.0], // G=H
      [1.0, 1.0, 2.0, 1.0, 1.0], // G=Wa
      [0.0, 0.0, 0.0, 2.0, 0.0], // G=Wi
      [1.0, 1.0, 1.0, 0.0, 2.0], // G=I
    ];
    return vashyaMatrix[gTyp][bTyp];
  }

  // 3. Tara (3 Points) Based on Nakshatra distance
  static double getTaraScore(int brideNak, int groomNak) {
    int bTara = ((groomNak - brideNak + 27) % 27) % 9 + 1;
    int gTara = ((brideNak - groomNak + 27) % 27) % 9 + 1;

    bool bGood = [2, 4, 6, 8, 9].contains(bTara);
    bool gGood = [2, 4, 6, 8, 9].contains(gTara);

    if (bGood && gGood) return 3.0;
    if (bGood || gGood) return 1.5;
    return 0.0;
  }

  // 4. Yoni (4 Points)
  static double getYoniScore(int brideNak, int groomNak) {
    const yoniMap = [0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 10, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1];
    int bYoni = yoniMap[brideNak % 27];
    int gYoni = yoniMap[groomNak % 27];
    
    // Exact 14x14 Vedic Yoni Score Matrix
    const matrix = [
      // 0:Horse, 1:Elephant, 2:Sheep, 3:Snake, 4:Dog, 5:Cat, 6:Rat, 7:Cow, 8:Buffalo, 9:Tiger, 10:Deer, 11:Monkey, 12:Mongoose, 13:Lion
      [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 3, 2, 2, 1], // 0 Horse
      [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0], // 1 Elephant
      [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1], // 2 Sheep
      [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2], // 3 Snake
      [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1], // 4 Dog
      [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1], // 5 Cat
      [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2], // 6 Rat
      [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1], // 7 Cow
      [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1], // 8 Buffalo
      [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1], // 9 Tiger
      [3, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1], // 10 Deer
      [2, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2], // 11 Monkey
      [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2], // 12 Mongoose
      [1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4], // 13 Lion
    ];
    return matrix[gYoni][bYoni].toDouble();
  }

  // 5. Graha Maitri (5 Points)
  static double getGrahaMaitriScore(int brideRashi, int groomRashi) {
    const lords = [2, 5, 3, 1, 0, 3, 5, 2, 4, 6, 6, 4];
    int bLord = lords[brideRashi];
    int gLord = lords[groomRashi];
    
    // Relation Matrix: 2=Friend, 1=Neutral, 0=Enemy
    // Sun(0), Moon(1), Mars(2), Merc(3), Jup(4), Ven(5), Sat(6)
    const rel = [
      [1, 2, 2, 1, 2, 0, 0], // Sun
      [2, 1, 1, 2, 1, 1, 1], // Moon
      [2, 2, 1, 0, 2, 1, 1], // Mars
      [2, 0, 1, 1, 1, 2, 1], // Merc
      [2, 2, 2, 0, 1, 0, 1], // Jup
      [0, 0, 1, 2, 1, 1, 2], // Ven
      [0, 0, 0, 2, 1, 2, 1], // Sat
    ];
    
    int gRelToB = rel[gLord][bLord];
    int bRelToG = rel[bLord][gLord];
    
    if (gRelToB == 2 && bRelToG == 2) return 5.0; // Friend-Friend
    if ((gRelToB == 2 && bRelToG == 1) || (gRelToB == 1 && bRelToG == 2)) return 4.0; // Friend-Neutral
    if (gRelToB == 1 && bRelToG == 1) return 3.0; // Neutral-Neutral
    if ((gRelToB == 2 && bRelToG == 0) || (gRelToB == 0 && bRelToG == 2)) return 1.0; // Friend-Enemy
    if ((gRelToB == 1 && bRelToG == 0) || (gRelToB == 0 && bRelToG == 1)) return 0.5; // Neutral-Enemy
    return 0.0; // Enemy-Enemy
  }

  // 6. Gana (6 Points)
  static double getGanaScore(int brideNak, int groomNak) {
    const ganaList = [0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2, 0, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 1, 0];
    int bGana = ganaList[brideNak % 27];
    int gGana = ganaList[groomNak % 27];
    
    const ganaMatrix = [
      // Bride Deva(0), Manushya(1), Rakshasa(2)
      [6.0, 5.0, 1.0], // Groom Deva
      [6.0, 6.0, 0.0], // Groom Manushya
      [0.0, 0.0, 0.0], // Groom Rakshasa
    ];
    return ganaMatrix[gGana][bGana];
  }

  // 7. Bhakoot (7 Points)
  static double getBhakootScore(int brideRashi, int groomRashi) {
    int dist = ((groomRashi - brideRashi + 12) % 12);
    const bhakootScores = [7.0, 0.0, 7.0, 7.0, 0.0, 0.0, 7.0, 0.0, 0.0, 7.0, 7.0, 0.0];
    return bhakootScores[dist];
  }

  // 8. Nadi (8 Points)
  static double getNadiScore(int brideNak, int groomNak) {
    const nadiCycle = [0, 1, 2, 2, 1, 0, 0, 1, 2];
    int bNadi = nadiCycle[(brideNak % 27) % 9];
    int gNadi = nadiCycle[(groomNak % 27) % 9];
    return (bNadi == gNadi) ? 0.0 : 8.0;
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
