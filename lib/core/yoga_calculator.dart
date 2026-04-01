import 'calculator.dart';
import 'varga_calculator.dart';

class KundaliYoga {
  final String name;
  final String rule;
  final String effect;
  final bool isAuspicious;
  final List<String> contributingPlanets;
  final String chartReference; // e.g. "D1 Rashi", "D9 Navamsha"

  KundaliYoga({
    required this.name,
    required this.rule,
    required this.effect,
    required this.isAuspicious,
    required this.contributingPlanets,
    required this.chartReference,
  });
}

class YogaCalculator {
  static List<KundaliYoga> scanYogas(KundaliResult chartData) {
    List<KundaliYoga> foundYogas = [];

    // Pre-calculate Varga positions for fast rule checking
    final d1Positions = VargaCalculator.generateVargaChart(chartData.planets, 1);
    final d9Positions = VargaCalculator.generateVargaChart(chartData.planets, 9);
    final d12Positions = VargaCalculator.generateVargaChart(chartData.planets, 12);

    final lagnaLon = chartData.planets['ಲಗ್ನ']?.longitude ?? 0;
    final lagnaRashi = (lagnaLon / 30).floor() % 12;
    
    final moonLon = chartData.planets['ಚಂದ್ರ']?.longitude ?? 0;
    final moonRashi = (moonLon / 30).floor() % 12;

    // RULE 1: Gaja Kesari Yoga (Brihat Jataka)
    // Jupiter in a Kendra (1, 4, 7, 10) from Moon
    if (chartData.planets.containsKey('ಗುರು') && chartData.planets.containsKey('ಚಂದ್ರ')) {
      final jupRashi = (chartData.planets['ಗುರು']!.longitude / 30).floor() % 12;
      final distFromMoon = (jupRashi - moonRashi + 12) % 12 + 1; // 1-based house from Moon
      
      if (distFromMoon == 1 || distFromMoon == 4 || distFromMoon == 7 || distFromMoon == 10) {
        foundYogas.add(KundaliYoga(
          name: 'ಗಜಕೇಸರಿ ಯೋಗ (Gajakesari Yoga)',
          rule: 'Jupiter is in a Kendra (${distFromMoon}th house) from the Moon.',
          effect: 'Destroys enemies, speaks eloquently, and lives a long, wealthy life.',
          isAuspicious: true,
          contributingPlanets: ['ಗುರು', 'ಚಂದ್ರ'],
          chartReference: 'D1 Rashi',
        ));
      }
    }

    // RULE 2: Vargottama Yogas (Prashna Marga)
    // Planets occupying the exact same sign in D1 and D9
    for (var planet in chartData.planets.entries) {
      if (planet.key == 'ಲಗ್ನ' || planet.key == 'ಮಾಂದಿ') continue;
      
      if (VargaCalculator.isVargottama(planet.value.longitude)) {
        foundYogas.add(KundaliYoga(
          name: 'ವರ್ಗೋತ್ತಮ ಗ್ರಹ (Vargottama Planet)',
          rule: '${planet.key} occupies the same Rashi in both the D1 and D9 charts.',
          effect: 'The planet gains massive strength, acting as if it were in its own sign or exalted.',
          isAuspicious: true,
          contributingPlanets: [planet.key],
          chartReference: 'D1 & D9 Navamsha',
        ));
      }
    }

    // RULE 3: Subsurface House Strengths (Prashna Marga)
    // Checking if empty D1 houses receive support from D9/D12 occupants in the same sign
    for (int i = 0; i < 12; i++) {
      final houseSign = (lagnaRashi + i) % 12;
      
      // If house is empty in D1...
      if (d1Positions[houseSign]!.isEmpty) {
        // But occupied by benefics in D9...
        final d9Occupants = d9Positions[houseSign]!;
        if (d9Occupants.contains('ಗುರು') || d9Occupants.contains('ಶುಕ್ರ') || d9Occupants.contains('ಬುಧ') || d9Occupants.contains('ಚಂದ್ರ')) {
          foundYogas.add(KundaliYoga(
            name: 'ನಾವಾಂಶ ಬಲ (${i+1}ನೇ ಭಾವ)',
            rule: 'The ${i+1}th house is empty in D1, but benefic planets occupy its Rashi in the D9 Navamsha.',
            effect: 'The ${i+1}th house gains subtle internal strength and prosperity over time.',
            isAuspicious: true,
            contributingPlanets: d9Occupants,
            chartReference: 'D9 Navamsha',
          ));
        }

        // Or occupied by benefics in D12...
        final d12Occupants = d12Positions[houseSign]!;
        if (d12Occupants.contains('ಗುರು') || d12Occupants.contains('ಶುಕ್ರ')) {
          foundYogas.add(KundaliYoga(
            name: 'ದ್ವಾದಶಾಂಶ ಬಲ (${i+1}ನೇ ಭಾವ)',
            rule: 'The ${i+1}th house is empty in D1, but benefic planets occupy its Rashi in the D12 Dvadashamsha.',
            effect: 'Karmic and ancestral blessings strengthen the matters of the ${i+1}th house.',
            isAuspicious: true,
            contributingPlanets: d12Occupants,
            chartReference: 'D12 Dvadashamsha',
          ));
        }
      }
    }

    // RULE 4: Kemadruma Yoga (Brihat Jataka)
    // No planets in 2nd and 12th from Moon (excluding Sun).
    if (chartData.planets.containsKey('ಚಂದ್ರ')) {
      final house12FromMoon = (moonRashi + 11) % 12;
      final house2FromMoon = (moonRashi + 1) % 12;

      final p12 = List.from(d1Positions[house12FromMoon]!)..removeWhere((p) => p == 'ರವಿ' || p == 'ರಾಹು' || p == 'ಕೇತು' || p == 'ಮಾಂದಿ');
      final p2 = List.from(d1Positions[house2FromMoon]!)..removeWhere((p) => p == 'ರವಿ' || p == 'ರಾಹು' || p == 'ಕೇತು' || p == 'ಮಾಂದಿ');
      
      if (p12.isEmpty && p2.isEmpty) {
        // Check cancellation (Kendra from lagna/moon)
        bool hasCancellation = false;
        for (var p in chartData.planets.values) {
           if (p.name == 'ಚಂದ್ರ' || p.name == 'ರವಿ' || p.name == 'ರಾಹು' || p.name == 'ಕೇತು' || p.name == 'ಮಾಂದಿ' || p.name == 'ಲಗ್ನ') continue;
           final pRashi = (p.longitude / 30).floor() % 12;
           final dL = (pRashi - lagnaRashi + 12) % 12 + 1;
           final dM = (pRashi - moonRashi + 12) % 12 + 1;
           if ([1,4,7,10].contains(dL) || [1,4,7,10].contains(dM)) {
             hasCancellation = true;
             break;
           }
        }
        
        if (!hasCancellation) {
          foundYogas.add(KundaliYoga(
            name: 'ಕೇಮದ್ರುಮ ಯೋಗ (Kemadruma Yoga)',
            rule: 'No planets in the 2nd or 12th house from the Moon (excluding Sun/Nodes).',
            effect: 'Struggles with wealth, sorrow, and mental isolation.',
            isAuspicious: false,
            contributingPlanets: ['ಚಂದ್ರ'],
            chartReference: 'D1 Rashi',
          ));
        }
      } else if (p12.isNotEmpty && p2.isNotEmpty) {
        // Durdhura Yoga
         foundYogas.add(KundaliYoga(
          name: 'ದುರ್ಧುರಾ ಯೋಗ (Durdhura Yoga)',
          rule: 'Planets exist in both the 2nd and 12th house from the Moon (excluding Sun).',
          effect: 'Wealth, comforts, and leadership qualities.',
          isAuspicious: true,
          contributingPlanets: ['ಚಂದ್ರ', ...p12, ...p2],
          chartReference: 'D1 Rashi',
        ));
      }
    }

    return foundYogas;
  }
}
