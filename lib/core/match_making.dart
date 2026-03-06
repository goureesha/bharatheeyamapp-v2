class MatchMakingLogic {
  // 1: Varna, 2: Vashya, 3: Tara, 4: Yoni, 5: Graha Maitri, 6: Gana, 7: Bhakoot, 8: Nadi
  
  // Nakshatra Index starts from 0 (Ashwini) to 26 (Revati)
  // Rashi Index starts from 0 (Mesha) to 11 (Meena)

  // 1. Varna (1 Point) based on Rashi
  // Brahmin: Karka, Vrishchika, Meena (3, 7, 11)
  // Kshatriya: Mesha, Simha, Dhanu (0, 4, 8)
  // Vaishya: Vrishabha, Kanya, Makara (1, 5, 9)
  // Shudra: Mithuna, Tula, Kumbha (2, 6, 10)
  static int _getVarna(int rashiIdx) {
    if ([3, 7, 11].contains(rashiIdx)) return 4; // Brahmin highest
    if ([0, 4, 8].contains(rashiIdx)) return 3; // Kshatriya
    if ([1, 5, 9].contains(rashiIdx)) return 2; // Vaishya
    return 1; // Shudra
  }

  static double getVarnaScore(int brideRashi, int groomRashi) {
    int bVarna = _getVarna(brideRashi);
    int gVarna = _getVarna(groomRashi);
    if (gVarna >= bVarna) return 1.0;
    return 0.0;
  }

  // 2. Vashya (2 Points) based on Rashi
  // Chatushpada (0, 1, 8 first half, 9 first half)
  // Manav (2, 5, 6, 8 second half, 10)
  // Jalchar (3, 9 second half, 11)
  // Vanchar (4)
  // Keeta (7)
  // Simplification for app based on standard matching grids
  static double getVashyaScore(int brideRashi, int groomRashi) {
    // Simplified standard score matrix for Vashya (36 combinations approx)
    // 2=Full, 1=Half, 0=Zero 
    if (brideRashi == groomRashi) return 2.0;

    int bTyp = _getVashyaType(brideRashi);
    int gTyp = _getVashyaType(groomRashi);
    
    if (bTyp == gTyp) return 2.0;
    // Human(1) & Quadruped(0) = 1.0 or 0.0 depending on text but generally partial
    if ((bTyp == 1 && gTyp == 0) || (bTyp == 0 && gTyp == 1)) return 1.0;
    // Jalchar(2) & Human(1) = 0.5 (rounded to 1 for simplicity or 0)
    // Using simple mapping:
    return 0.0; // Generally incompatible if not same or specific friendly pairs
  }

  static int _getVashyaType(int r) {
    if ([0, 1, 8].contains(r)) return 0; // Quad
    if ([2, 5, 6, 10].contains(r)) return 1; // Human
    if ([3, 11, 9].contains(r)) return 2; // Water
    if (r == 4) return 3; // Wild
    return 4; // Insect
  }

  // 3. Tara (3 Points)
  static double getTaraScore(int brideNak, int groomNak) {
    int bTara = ((groomNak - brideNak + 27) % 27) % 9;
    int gTara = ((brideNak - groomNak + 27) % 27) % 9;
    
    // 0 is technically 9th Tara which is param mitra usually 
    if (bTara == 0) bTara = 9;
    if (gTara == 0) gTara = 9;

    bool bGood = [1, 2, 4, 6, 8, 9].contains(bTara); // 3,5,7 are bad
    bool gGood = [1, 2, 4, 6, 8, 9].contains(gTara);

    if (bGood && gGood) return 3.0;
    if (bGood || gGood) return 1.5;
    return 0.0;
  }

  // 4. Yoni (4 Points)
  // Animal representation of Nakshatra
  static int _getYoni(int n) {
    // 0: Horse, 1: Elephant, 2: Sheep, 3: Serpent, 4: Dog, 5: Cat, 6: Rat, 7: Cow
    // 8: Buffalo, 9: Tiger, 10: Hare/Deer, 11: Monkey, 12: Mongoose, 13: Lion
    const yoniMap = [
      0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 10, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1
    ];
    return yoniMap[n % 27];
  }

  static double getYoniScore(int brideNak, int groomNak) {
    int bYoni = _getYoni(brideNak);
    int gYoni = _getYoni(groomNak);
    if (bYoni == gYoni) return 4.0;
    
    // Hostile pairs (0 points)
    final enemies = [
      [0, 8], [1, 13], [2, 11], [3, 12], [4, 10], [5, 6], [7, 9]
    ];
    for (var pair in enemies) {
      if ((pair[0] == bYoni && pair[1] == gYoni) || (pair[1] == bYoni && pair[0] == gYoni)) {
        return 0.0; // Enmity
      }
    }
    // Friendly / Neutral / Inimical scaling is usually 3, 2, 1
    // Simplified fallback to average for others to keep implementation compact
    return 2.0; 
  }

  // 5. Graha Maitri (5 Points)
  static double getGrahaMaitriScore(int brideRashi, int groomRashi) {
    // Lords: 
    // Sun(0): 4, Moon(1): 3, Mars(2): 0, 7, Merc(3): 2, 5
    // Jup(4): 8, 11, Ven(5): 1, 6, Sat(6): 9, 10
    List<int> lords = [2, 5, 3, 1, 0, 3, 5, 2, 4, 6, 6, 4];
    int bLord = lords[brideRashi];
    int gLord = lords[groomRashi];

    if (bLord == gLord) return 5.0;

    // Friendly relationships (simplified)
    // Sun friends: Moon, Mars, Jup
    // Moon friends: Sun, Merc
    // Mars friends: Sun, Moon, Jup
    // Merc friends: Sun, Ven
    // Jup friends: Sun, Moon, Mars
    // Ven friends: Merc, Sat
    // Sat friends: Merc, Ven
    const friends = [
      [1, 2, 4], // Sun
      [0, 3],    // Moon
      [0, 1, 4], // Mars
      [0, 5],    // Merc
      [0, 1, 2], // Jup
      [3, 6],    // Ven
      [3, 5]     // Sat
    ];

    bool bFriendToG = friends[bLord].contains(gLord);
    bool gFriendToB = friends[gLord].contains(bLord);

    if (bFriendToG && gFriendToB) return 5.0; // Mutual friends
    if ((bFriendToG && !gFriendToB) || (!bFriendToG && gFriendToB)) return 4.0; // One friend, one neutral
    
    // One neutral, one neutral = 3
    // One friend, one enemy = 1
    // Mutual enemies = 0
    return 1.0; // Defaulting to low score for strictness
  }

  // 6. Gana (6 Points)
  // 0: Deva, 1: Manushya, 2: Rakshasa
  static int _getGana(int n) {
    const ganaList = [
      0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2, 0, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 1, 0
    ];
    return ganaList[n % 27];
  }

  static double getGanaScore(int brideNak, int groomNak) {
    int bGana = _getGana(brideNak);
    int gGana = _getGana(groomNak);
    
    if (bGana == gGana) return 6.0;
    if (gGana == 0 && bGana == 1) return 6.0; // Boy Deva, Girl Manushya is acceptable
    if (gGana == 1 && bGana == 0) return 5.0; // Girl Deva, Boy Manushya
    
    if (gGana == 2 && bGana == 0) return 1.0; 
    if (gGana == 0 && bGana == 2) return 0.0; // Rakshasa girl, Deva boy
    
    if (gGana == 2 && bGana == 1) return 0.0;
    if (gGana == 1 && bGana == 2) return 0.0; 

    return 0.0;
  }

  // 7. Bhakoot (7 Points) based on Rashi distance
  static double getBhakootScore(int brideRashi, int groomRashi) {
    if (brideRashi == groomRashi) return 7.0;
    
    int dist = ((groomRashi - brideRashi + 12) % 12) + 1; // Distance from Bride to Groom
    
    // Auspicious distances: 1/7, 3/11, 4/10
    // Inauspicious: 2/12, 5/9, 6/8
    if ([1, 7, 3, 11, 4, 10].contains(dist)) return 7.0;
    return 0.0; 
  }

  // 8. Nadi (8 Points)
  // 0: Adi (Vata), 1: Madhya (Pitta), 2: Antya (Kapha)
  static int _getNadi(int n) {
    const nadiCycle = [0, 1, 2, 2, 1, 0, 0, 1, 2];
    return nadiCycle[(n % 27) % 9];
  }

  static double getNadiScore(int brideNak, int groomNak) {
    int bNadi = _getNadi(brideNak);
    int gNadi = _getNadi(groomNak);
    
    if (bNadi == gNadi) return 0.0; // Same Nadi is a dosha (0 points)
    return 8.0; // Different Nadi gets full 8 points
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
