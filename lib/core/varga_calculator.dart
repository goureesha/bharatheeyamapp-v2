import 'calculator.dart';

class VargaCalculator {
  /// Returns the Navamsha (D9) Rashi Index (0-11) for a given sidereal longitude.
  /// A Navamsha is 3° 20' (200 minutes).
  /// Rule: For Fiery signs (0,4,8), counting starts from Aries (0).
  /// Earthy signs (1,5,9) -> starts from Capricorn (9).
  /// Airy signs (2,6,10) -> starts from Libra (6).
  /// Watery signs (3,7,11) -> starts from Cancer (3).
  static int getD9Sign(double longitude) {
    final block = (longitude / 30).floor() % 4; // 0=Fire, 1=Earth, 2=Air, 3=Water
    final start = [0, 9, 6, 3][block];
    final steps = ((longitude % 30) / 3.333333333).floor();
    return (start + steps) % 12;
  }

  /// Returns the Dvadashamsha (D12) Rashi Index (0-11) for a given sidereal longitude.
  /// A Dvadashamsha is 2° 30' (150 minutes).
  /// Rule: The 1st part starts in the sign itself, and the rest follow in continuous zodiacal order.
  static int getD12Sign(double longitude) {
    final rashiIndex = (longitude / 30).floor() % 12;
    final steps = ((longitude % 30) / 2.5).floor();
    return (rashiIndex + steps) % 12;
  }

  /// Determines if a planet is Vargottama (in the same sign in D1 and D9).
  /// This is an extremely powerful planetary dignity in Jyotisha.
  static bool isVargottama(double longitude) {
    final d1 = (longitude / 30).floor() % 12;
    final d9 = getD9Sign(longitude);
    return d1 == d9;
  }

  /// Generates a Varga Chart mapped by Rashi Index (0-11) containing the names of the planets residing there.
  static Map<int, List<String>> generateVargaChart(Map<String, PlanetInfo> originalPlanets, int vargaDiv) {
    Map<int, List<String>> chart = {for (int i = 0; i < 12; i++) i: []};

    for (var entry in originalPlanets.entries) {
      final name = entry.key;
      final lon = entry.value.longitude;

      int rashiIdx = 0;
      if (vargaDiv == 1) {
        rashiIdx = (lon / 30).floor() % 12;
      } else if (vargaDiv == 9) {
        rashiIdx = getD9Sign(lon);
      } else if (vargaDiv == 12) {
        rashiIdx = getD12Sign(lon);
      }

      chart[rashiIdx]!.add(name);
    }
    return chart;
  }
}
