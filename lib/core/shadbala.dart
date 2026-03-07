import 'dart:math';

/// Compiles the 6-fold planetary strength (Shadbala) according to Parashari principles.
/// Returns a map of strengths in Rupas and Virupas.
class ShadbalaLogic {
  static const List<String> planets = [
    'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'
  ];

  static Map<String, Map<String, dynamic>> calculateShadbala({
    required Map<String, double> longitudes,
    required Map<String, double> speeds,
    required double ascendant,
    required double sunRiseJd,
    required double birthJd,
  }) {
    // 1. Naisargika Bala (Natural Strength) - Constant in Virupas
    // Sun=60, Moon=51.43, Venus=42.85, Jup=34.28, Merc=25.70, Mars=17.14, Sat=8.57
    final naisargikaBala = {
      'Sun': 60.0,
      'Moon': 51.43,
      'Venus': 42.85,
      'Jupiter': 34.28,
      'Mercury': 25.70,
      'Mars': 17.14,
      'Saturn': 8.57,
    };

    // 2. Sthana Bala (Positional Strength)
    // Exaltation (Uchcha)
    final uchchaDegrees = {
      'Sun': 10.0, 'Moon': 33.0, 'Mars': 298.0, 
      'Mercury': 165.0, 'Jupiter': 95.0, 'Venus': 357.0, 'Saturn': 200.0,
    };

    Map<String, double> sthanaBala = {};
    for (var p in planets) {
      double pos = longitudes[p] ?? 0.0;
      double uchcha = uchchaDegrees[p] ?? 0.0;
      double dist = (pos - uchcha).abs();
      if (dist > 180) dist = 360 - dist;
      // Uchchabala = (180 - distance) / 3
      double uchchaBala = (180.0 - dist) / 3.0;
      
      // Kendradi Bala (approximation based on distance from Ascendant)
      double houseDist = (pos - ascendant).abs();
      if (houseDist > 180) houseDist = 360 - houseDist;
      double kendradi = 0.0;
      if (houseDist < 30 || (houseDist > 80 && houseDist < 100) || (houseDist > 170 && houseDist < 190) || (houseDist > 260 && houseDist < 280)) {
        kendradi = 60.0; // Kendra 1, 4, 7, 10
      } else if ((houseDist > 30 && houseDist < 60) || (houseDist > 120 && houseDist < 150) || (houseDist > 210 && houseDist < 240) || (houseDist > 300 && houseDist < 330)) {
        kendradi = 30.0; // Panaphara 2, 5, 8, 11
      } else {
        kendradi = 15.0; // Apoklima 3, 6, 9, 12
      }

      // Total Sthana (Uchcha + Kendradi + approx Saptavargaja/Drekkana/Ojayugma)
      sthanaBala[p] = uchchaBala + kendradi + 30.0; // Approximate base of 30 for other vars
    }

    // 3. Dig Bala (Directional Strength)
    final dikCenters = {
      'Sun': (ascendant + 270) % 360,     // 10th house
      'Mars': (ascendant + 270) % 360,
      'Jupiter': ascendant,               // 1st house
      'Mercury': ascendant,
      'Saturn': (ascendant + 180) % 360,  // 7th house
      'Moon': (ascendant + 90) % 360,     // 4th house
      'Venus': (ascendant + 90) % 360,
    };

    Map<String, double> dikBala = {};
    for (var p in planets) {
      double pos = longitudes[p] ?? 0.0;
      double center = dikCenters[p] ?? 0.0;
      double dist = (pos - center).abs();
      if (dist > 180) dist = 360 - dist;
      dikBala[p] = (180.0 - dist) / 3.0; // Max 60 Virupas
    }

    // 4. Kala Bala (Temporal Strength)
    double timeSinceSunrise = birthJd - sunRiseJd;
    bool isDayBirth = timeSinceSunrise >= 0 && timeSinceSunrise <= 0.5;
    
    Map<String, double> kalaBala = {};
    for (var p in planets) {
      double natonnat = 0.0;
      if (p == 'Mercury') {
        natonnat = 60.0; // Always strong
      } else if (p == 'Sun' || p == 'Jupiter' || p == 'Venus') {
        natonnat = isDayBirth ? 60.0 : 0.0;
      } else {
        natonnat = isDayBirth ? 0.0 : 60.0;
      }
      // Add a base of 20 for Paksha, Ayana, Masa, Vara, Hora equivalents
      kalaBala[p] = natonnat + 50.0; 
    }

    // 5. Chesta Bala (Motional Strength)
    Map<String, double> cheshtaBala = {};
    for (var p in planets) {
      if (p == 'Sun' || p == 'Moon') {
        cheshtaBala[p] = 40.0; // Ayana based approx for luminaries
      } else {
        double speed = speeds[p] ?? 0.0;
        if (speed < 0) {
          cheshtaBala[p] = 60.0; // Retrograde
        } else if (speed < 0.5) {
          cheshtaBala[p] = 45.0; // Slow
        } else if (speed > 1.2) {
          cheshtaBala[p] = 15.0; // Fast
        } else {
          cheshtaBala[p] = 30.0; // Normal
        }
      }
    }

    // 6. Drig Bala (Aspect Strength)
    Map<String, double> drikBala = {};
    for (var p in planets) {
      drikBala[p] = 30.0; // Base neutral
      double pPos = longitudes[p] ?? 0.0;
      for (var a in planets) {
        if (p == a) continue;
        double aPos = longitudes[a] ?? 0.0;
        double aspectDist = (pPos - aPos) % 360;
        if (aspectDist < 0) aspectDist += 360;
        
        double aspectValue = 0.0;
        if (aspectDist >= 150 && aspectDist <= 210) {
           aspectValue = 60.0 - (180 - aspectDist).abs() * 2;
           if (aspectValue < 0) aspectValue = 0;
        } else if (aspectDist >= 30 && aspectDist <= 90) {
           aspectValue = (aspectDist - 30);
           if (aspectValue > 15) aspectValue = 15;
        }

        bool isMalefic = (a == 'Saturn' || a == 'Mars' || a == 'Sun');
        if (isMalefic) {
          drikBala[p] = drikBala[p]! - (aspectValue * 0.25);
        } else {
          drikBala[p] = drikBala[p]! + (aspectValue * 0.25);
        }
      }
    }

    // Benchmark Requirements (in Rupas)
    final benchmarks = {
      'Sun': 5.0,
      'Moon': 6.0,
      'Mars': 5.0,
      'Mercury': 7.0,
      'Jupiter': 6.5,
      'Venus': 5.5,
      'Saturn': 5.0,
    };

    // Combine and convert to Rupas
    Map<String, Map<String, dynamic>> finalShadbala = {};
    for (var p in planets) {
      double sthana = sthanaBala[p] ?? 0.0;
      double dik = dikBala[p] ?? 0.0;
      double kala = kalaBala[p] ?? 0.0;
      double cheshta = cheshtaBala[p] ?? 0.0;
      double naisargika = naisargikaBala[p] ?? 0.0;
      double drik = drikBala[p] ?? 0.0;

      double totalVirupas = sthana + dik + kala + cheshta + naisargika + drik;
      double totalRupas = totalVirupas / 60.0;
      
      double req = benchmarks[p] ?? 0.0;
      bool isStrong = totalRupas >= req;

      finalShadbala[p] = {
        'Sthana': sthana / 60.0,
        'Dik': dik / 60.0,
        'Kala': kala / 60.0,
        'Cheshta': cheshta / 60.0,
        'Naisargika': naisargika / 60.0,
        'Drik': drik / 60.0,
        'Total': totalRupas,
        'Required': req,
        'IsStrong': isStrong,
      };
    }

    return finalShadbala;
  }
}
