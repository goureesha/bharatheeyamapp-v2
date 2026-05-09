import 'calculator.dart';

class ViyoniJanma {
  static const _animalSigns = {0, 1, 3, 4, 7, 9, 11};
  static const _bodyParts = ['ತಲೆ','ಮುಖ/ಕುತ್ತಿಗೆ','ಮುಂಗಾಲು/ಭುಜ','ಬೆನ್ನು','ಎದೆ','ಪಾರ್ಶ್ವ','ಹೊಟ್ಟೆ','ಗುದ','ಹಿಂಗಾಲು','ಶಿಶ್ನ/ವೃಷಣ','ಪೃಷ್ಠ','ಬಾಲ'];
  static const _rashiColors = ['ಕೆಂಪು','ಬಿಳಿ','ಹಸಿರು','ಗುಲಾಬಿ','ಹಳದಿ','ಬಹುವರ್ಣ','ಕಪ್ಪು','ಕೆಂಪು-ಕಂದು','ಹಳದಿ','ಬಹುವರ್ಣ','ಕಂದು','ಬೆಳ್ಳಿ'];
  static const _rashiNames = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
  static const _birdDrekkanas = {(2,1),(4,2),(5,1),(6,2),(10,3),(8,1)};
  static const _charaRashis = {0, 3, 6, 9};

  static int _rashiOf(double lon) => ((lon ~/ 30) % 12).toInt();

  static int _d12Rashi(double lon) {
    final inSign = lon % 30;
    return ((inSign / 2.5).floor() + _rashiOf(lon)) % 12;
  }

  static int _d9Rashi(double lon) {
    final inSign = lon % 30;
    final navPada = (inSign / (30.0 / 9.0)).floor();
    final rashi = _rashiOf(lon);
    final startRashi = (rashi % 4) == 0 ? 0 : (rashi % 4) == 1 ? 9 : (rashi % 4) == 2 ? 6 : 3;
    return (startRashi + navPada) % 12;
  }

  static int _drekkanaNum(double lon) {
    final inSign = lon % 30;
    if (inSign < 10) return 1;
    if (inSign < 20) return 2;
    return 3;
  }

  static bool _isOwnNavamsha(String planet, int d9) {
    const own = {'Sun':[4],'Mars':[0,7],'Saturn':[9,10],'Rahu':[10],'Ketu':[7]};
    const exalt = {'Sun':0,'Mars':9,'Saturn':6,'Rahu':1,'Ketu':7};
    if (own[planet]?.contains(d9) ?? false) return true;
    return exalt[planet] == d9;
  }

  static bool _isEnemyNavamsha(String planet, int d9) {
    const enemies = {'Jupiter':[1,6,9,10],'Venus':[0,3,4,7],'Mercury':[3,7],'Moon':[7,9,10]};
    return enemies[planet]?.contains(d9) ?? false;
  }

  static const _rashiNamesShort = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];

  /// Detect yogas from ALL 12 rashis as virtual lagna.
  /// Each yoga is tagged with [refLagna] indicating which rashi was used as reference.
  static List<Yoga> detectAll(KundaliResult chart) {
    final allYogas = <Yoga>[];
    final seen = <String>{};

    for (int ref = 0; ref < 12; ref++) {
      final yogas = detect(chart, lagnaRashi: ref);
      for (final y in yogas) {
        // Create unique key to avoid exact duplicates
        final key = '${y.name}|${y.rashi}|$ref';
        if (!seen.contains(key)) {
          seen.add(key);
          allYogas.add(Yoga(
            shloka: y.shloka,
            name: y.name,
            description: '⟪${_rashiNamesShort[ref]} ಲಗ್ನ⟫\n${y.description}',
            result: y.result,
            rashi: y.rashi,
            planets: y.planets,
            refLagna: ref,
          ));
        }
      }
    }
    return allYogas;
  }

  /// Detect all active yogas for the given chart.
  /// If [lagnaRashi] is provided, use it as virtual lagna (0-11).
  static List<Yoga> detect(KundaliResult chart, {int? lagnaRashi}) {
    final p = chart.planets;
    final bhavas = chart.bhavas;
    final shadbala = chart.shadbala;
    final lag = bhavas.isNotEmpty ? bhavas[0] : 0.0;
    final lagRashi = lagnaRashi ?? _rashiOf(lag);
    final moonLon = p['ಚಂದ್ರ']?.longitude ?? 0.0;

    final sun = p['ರವಿ']?.longitude ?? 0.0;
    final moon = moonLon;
    final mars = p['ಕುಜ']?.longitude ?? 0.0;
    final mer = p['ಬುಧ']?.longitude ?? 0.0;
    final jup = p['ಗುರು']?.longitude ?? 0.0;
    final ven = p['ಶುಕ್ರ']?.longitude ?? 0.0;
    final sat = p['ಶನಿ']?.longitude ?? 0.0;
    final rahu = p['ರಾಹು']?.longitude ?? 0.0;
    final ketu = p['ಕೇತು']?.longitude ?? 0.0;

    bool isStrong(String eng) => shadbala[eng]?['IsStrong'] == true;
    bool isWeak(String eng) => shadbala[eng]?['IsStrong'] != true;

    final malStrong = isStrong('Sun') && isStrong('Mars') && isStrong('Saturn');
    final benWeak = isWeak('Jupiter') && isWeak('Venus') && isWeak('Mercury') && isWeak('Moon');

    final kendras = [lagRashi, (lagRashi+3)%12, (lagRashi+6)%12, (lagRashi+9)%12];
    final malLons = {'Sun':sun,'Mars':mars,'Saturn':sat,'Rahu':rahu,'Ketu':ketu};
    bool malInKendra = false, malAspKendra = false;
    for (final e in malLons.entries) {
      final r = _rashiOf(e.value);
      if (kendras.contains(r)) malInKendra = true;
      if (kendras.contains((r+6)%12)) malAspKendra = true;
      if (e.key == 'Mars' && (kendras.contains((r+3)%12) || kendras.contains((r+7)%12))) malAspKendra = true;
      if (e.key == 'Saturn' && (kendras.contains((r+2)%12) || kendras.contains((r+9)%12))) malAspKendra = true;
    }

    final yogas = <Yoga>[];

    // Helper: Kannada planet names
    const _knPlanets = {'Sun':'ರವಿ','Mars':'ಕುಜ','Saturn':'ಶನಿ','Rahu':'ರಾಹು','Ketu':'ಕೇತು',
                        'Jupiter':'ಗುರು','Venus':'ಶುಕ್ರ','Mercury':'ಬುಧ','Moon':'ಚಂದ್ರ'};

    // ═══ Shloka 1: Basic Viyoni ═══
    if (malStrong && benWeak && (malInKendra || malAspKendra)) {
      final d12 = _d12Rashi(moonLon);
      // Which malefics are in which kendras
      final malKendraDetail = <String>[];
      for (final e in malLons.entries) {
        final r = _rashiOf(e.value);
        if (kendras.contains(r)) malKendraDetail.add('${_knPlanets[e.key]} → ${_rashiNames[r]} (ಕೇಂದ್ರ)');
      }
      yogas.add(Yoga(
        shloka: 'ಕ್ರೂರಗ್ರಹೈಃ ಸುಬಲಿಭಿರ್ವಿಬಲೈಶ್ಚ ಸೌಮ್ಯಃ ಕ್ಲೀದೇ ಚತುಷ್ಟಯಗತೇ ತದವೇಕ್ಷಣಾದ್ವಾ ।\nಚಂದ್ರೋಪಗದ್ವಿರಸಭಾಗಸಮಾನರೂಪಂ ಸಂ ವದೇದ್ಯದಿ ಭವೇತ್ಸ ವಿಯೋನಿಸಂಜ್ಞ ॥',
        name: 'ವಿಯೋನಿ ಜನ್ಮ ಯೋಗ',
        description: 'ಲಗ್ನ: ${_rashiNames[lagRashi]} | ಪಾಪರು ಬಲಶಾಲಿ (ರವಿ,ಕುಜ,ಶನಿ) | ಶುಭರು ಬಲಹೀನ (ಗುರು,ಶುಕ್ರ,ಬುಧ,ಚಂದ್ರ)\n${malKendraDetail.join('\n')}',
        result: 'ಚಂದ್ರ ದ್ವಾದಶಾಂಶ: ${_rashiNames[d12]} → ಪ್ರಾಣಿ ರೂಪ: ${_bodyParts[d12]}',
        rashi: lagRashi,
        planets: ['ರವಿ','ಕುಜ','ಶನಿ','ರಾಹು','ಕೇತು'],
      ));
    }

    // ═══ Shloka 2: Navamsha-based Viyoni ═══
    bool malOwnNav = true;
    final malNavDetail = <String>[];
    for (final e in malLons.entries) {
      if (e.key == 'Rahu' || e.key == 'Ketu') continue;
      final d9 = _d9Rashi(e.value);
      final own = _isOwnNavamsha(e.key, d9);
      if (!own) malOwnNav = false;
      malNavDetail.add('${_knPlanets[e.key]} ನವಾಂಶ: ${_rashiNames[d9]} ${own ? "✓ ಸ್ವ" : "✗"}');
    }
    final benLons = {'Jupiter':jup,'Venus':ven,'Mercury':mer,'Moon':moon};
    bool benEnemyNav = true;
    final benNavDetail = <String>[];
    for (final e in benLons.entries) {
      final d9 = _d9Rashi(e.value);
      final enemy = _isEnemyNavamsha(e.key, d9);
      if (!enemy) benEnemyNav = false;
      benNavDetail.add('${_knPlanets[e.key]} ನವಾಂಶ: ${_rashiNames[d9]} ${enemy ? "✓ ಶತ್ರು" : "✗"}');
    }
    if (malStrong && malOwnNav && benWeak && benEnemyNav && _animalSigns.contains(lagRashi)) {
      yogas.add(Yoga(
        shloka: 'ಪಾಪಾ ಬಲಿನಃ ಸ್ವಭಾಗಗಾಃ ಪಾರಕ್ಕೇ ವಿಬಲಾಶ್ಚ ಶೋಭನಾಃ ।\nಲಗ್ನಂ ಚ ವಿಯೋನಿಸಂಭವಂ ದೃಷ್ಟಾತಾಪಿ ವಿಯೋನಿಮಾದಿಶೇತ್ ॥',
        name: 'ನವಾಂಶ ವಿಯೋನಿ ಯೋಗ',
        description: 'ಲಗ್ನ: ${_rashiNames[lagRashi]} (ವಿಯೋನಿ ರಾಶಿ)\n${malNavDetail.join(' | ')}\n${benNavDetail.join(' | ')}',
        result: 'ಲಗ್ನ ವಿಯೋನಿ ರಾಶಿ: ${_rashiNames[lagRashi]}',
        rashi: lagRashi,
        planets: ['ರವಿ','ಕುಜ','ಶನಿ','ಗುರು','ಶುಕ್ರ','ಬುಧ','ಚಂದ್ರ'],
      ));
    }

    // ═══ Shloka 3: Body part (always shown if shloka 1 or 2 active) ═══
    if (yogas.isNotEmpty) {
      final moonRashi = _rashiOf(moonLon);
      yogas.add(Yoga(
        shloka: 'ಕ್ರಿಯಃ ಶಿರೋ ವಕ್ತಗಲೇ ದ್ವಿತೀಯಃ...',
        name: 'ಚತುಷ್ಪಾದ ಅಂಗ ನಿರ್ಣಯ',
        description: 'ಚಂದ್ರ ರಾಶಿ: ${_rashiNames[moonRashi]}',
        result: 'ದೇಹ ಭಾಗ: ${_bodyParts[moonRashi]}',
        rashi: moonRashi,
        planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ Shloka 4: Color & markings (if viyoni active) ═══
    if (yogas.isNotEmpty) {
      final lagNav = _d9Rashi(lag);
      final color = _rashiColors[lagNav];
      final allLons = [sun,moon,mars,mer,jup,ven,sat,rahu,ketu];
      final names = ['ರವಿ','ಚಂದ್ರ','ಕುಜ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ','ರಾಹು','ಕೇತು'];
      final aspecting = <String>[];
      for (int i = 0; i < allLons.length; i++) {
        if ((_rashiOf(allLons[i])+6)%12 == lagRashi) aspecting.add(names[i]);
      }
      final h7 = (lagRashi+6)%12;
      final in7 = <String>[];
      for (int i = 0; i < allLons.length; i++) {
        if (_rashiOf(allLons[i]) == h7) in7.add(names[i]);
      }
      yogas.add(Yoga(
        shloka: 'ಲಗ್ನಾಂಶಕಾದ್ ಗ್ರಹಯೋಗೇಕ್ಷಣಾದ್ವಾ...',
        name: 'ವರ್ಣ-ಸಂಖ್ಯಾ-ಚಿಹ್ನೆ ಯೋಗ',
        description: 'ಲಗ್ನ ನವಾಂಶ: ${_rashiNames[lagNav]} | ಲಗ್ನ ದೃಷ್ಟಿ: ${aspecting.isEmpty ? "ಇಲ್ಲ" : aspecting.join(",")}\n7ನೇ ಭಾವ (${_rashiNames[h7]}): ${in7.isEmpty ? "ಖಾಲಿ" : in7.join(",")}',
        result: 'ಬಣ್ಣ: $color | ಸಂಖ್ಯೆ: ${aspecting.length} | ಬೆನ್ನ ಗುರುತು: ${in7.isEmpty ? "ಇಲ್ಲ" : in7.join(",")}',
        rashi: lagRashi,
        planets: [...aspecting, ...in7],
      ));
    }

    // ═══ Shloka 5: Bird birth ═══
    final lagDrek = _drekkanaNum(lag);
    final isBirdDrek = _birdDrekkanas.contains((lagRashi, lagDrek));
    final strongInLagList = <String>[];
    for (final e in malLons.entries) {
      if (_rashiOf(e.value) == lagRashi && isStrong(e.key)) strongInLagList.add(_knPlanets[e.key]!);
    }
    for (final e in benLons.entries) {
      if (_rashiOf(e.value) == lagRashi && isStrong(e.key)) strongInLagList.add(_knPlanets[e.key]!);
    }
    final lagNav = _d9Rashi(lag);
    final isChara = _charaRashis.contains(lagNav);
    final isMerNav = lagNav == 2 || lagNav == 5;

    if ((isBirdDrek && strongInLagList.isNotEmpty) || isChara || isMerNav) {
      final satR = _rashiOf(sat); final moonR = _rashiOf(moon);
      final satMoon = (satR-moonR).abs()%12 == 0 || (satR+6)%12 == moonR;
      String bType = 'ಸಾಮಾನ್ಯ ಪಕ್ಷಿ';
      if (satMoon) {
        final water = {3,7,11};
        bType = (water.contains(moonR) || water.contains(satR)) ? 'ಜಲಪಕ್ಷಿ' : 'ಭೂಚರ ಪಕ್ಷಿ';
      }
      // Build trigger reason
      final triggers = <String>[];
      if (isBirdDrek && strongInLagList.isNotEmpty) triggers.add('ಪಕ್ಷಿ ದ್ರೇಕ್ಕಾಣ (${_rashiNames[lagRashi]}-$lagDrek) + ಬಲಶಾಲಿ: ${strongInLagList.join(",")}');
      if (isChara) triggers.add('ಚರ ನವಾಂಶ ಲಗ್ನ: ${_rashiNames[lagNav]}');
      if (isMerNav) triggers.add('ಬುಧ ನವಾಂಶ ಲಗ್ನ: ${_rashiNames[lagNav]}');

      yogas.add(Yoga(
        shloka: 'ಖಗೇ ದೃಗಾಣೇ ಬಲಸಂಯುತೇನ ವಾ...',
        name: 'ಪಕ್ಷಿ ಜನ್ಮ ಯೋಗ',
        description: 'ಲಗ್ನ: ${_rashiNames[lagRashi]} | ಶನಿ: ${_rashiNames[satR]} | ಚಂದ್ರ: ${_rashiNames[moonR]}\n${triggers.join('\n')}',
        result: 'ಪಕ್ಷಿ ಪ್ರಕಾರ: $bType',
        rashi: lagRashi,
        planets: ['ಶನಿ','ಚಂದ್ರ', ...strongInLagList],
      ));
    }
    // ═══ Shloka 6: Tree birth (Vriksha Janma) ═══
    // Lagna lord, Moon, Jupiter, Sun all weak → tree birth
    const rashiLords = ['Mars','Venus','Mercury','Moon','Sun','Mercury','Venus','Mars','Jupiter','Saturn','Saturn','Jupiter'];
    final lagLord = rashiLords[lagRashi];
    final lagLordWeak = isWeak(lagLord);
    final moonWeak = isWeak('Moon');
    final jupWeak = isWeak('Jupiter');
    final sunWeak = isWeak('Sun');

    if (lagLordWeak && moonWeak && jupWeak && sunWeak) {
      // Water or land based on lagna navamsha
      final lagNavR = _d9Rashi(lag);
      const waterSigns = {3, 7, 11}; // Cancer, Scorpio, Pisces
      final treePlace = waterSigns.contains(lagNavR) ? 'ನೀರಿನಲ್ಲಿ ಬೆಳೆಯುವ ಮರ' : 'ನೆಲದಲ್ಲಿ ಬೆಳೆಯುವ ಮರ';

      // Count: house position of strongest planet from lagna
      final allPlanetLons = {'ರವಿ':sun,'ಚಂದ್ರ':moon,'ಕುಜ':mars,'ಬುಧ':mer,'ಗುರು':jup,'ಶುಕ್ರ':ven,'ಶನಿ':sat};
      final treeCounts = <String>[];
      for (final e in allPlanetLons.entries) {
        final houseFrom = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        treeCounts.add('${e.key}: ${houseFrom}ನೇ ಮನೆ → $houseFrom ಮರ');
      }

      yogas.add(Yoga(
        shloka: 'ಹೋರೇಂದುಸೂರಿರವಿಭಿರ್ವಿಬಲೈಸ್ತರೂಣಾಂ ತೋಯಸ್ಥಲೇ ತರುಭವೋsಂಶಕೃತಃ ಪ್ರಭೇದಃ ।\nಲಗ್ನಾದ್ ಗ್ರಹಃ ಸ್ಥಲಜಲರ್ಕ್ಷಪತಿಸ್ತು ಯಾವಾಂಸ್ತಾವಂತ ಏವ ತರವಃ ಸ್ಥಲತೋಯಜಾತಾಃ',
        name: 'ವೃಕ್ಷ ಜನ್ಮ ಯೋಗ',
        description: 'ಲಗ್ನ: ${_rashiNames[lagRashi]} | ಲಗ್ನೇಶ (${_knPlanets[lagLord]}): ಬಲಹೀನ | ಚಂದ್ರ: ಬಲಹೀನ | ಗುರು: ಬಲಹೀನ | ರವಿ: ಬಲಹೀನ\nನವಾಂಶ: ${_rashiNames[lagNavR]} → $treePlace\n${treeCounts.join('\n')}',
        result: '$treePlace',
        rashi: lagRashi,
        planets: [_knPlanets[lagLord]!, 'ಚಂದ್ರ', 'ಗುರು', 'ರವಿ'],
      ));

      // ═══ Shloka 7: Tree type by planet ═══
      // Sun→hardwood, Saturn→dry, Moon→milky/sap, Mars→thorny, Jupiter→soft
      const treeTypes = {
        'Sun': 'ಒಳಗಡೆ ಗಟ್ಟಿಯಾದ ಮರ (ಅಂತಸ್ಸಾರ)',
        'Saturn': 'ಒಣಗಿದ/ದುರ್ಭಾಗ್ಯ ಮರ',
        'Moon': 'ಹಾಲಿನಂತ ರಸವುಳ್ಳ ಮರ (ಸ್ನಿಗ್ಧ)',
        'Mars': 'ಮುಳ್ಳುಳ್ಳ ಮರ (ಕಂಟಕ)',
        'Jupiter': 'ಹಣ್ಣು/ಹೂ ಮೃದು ಮರ',
      };
      const benefics = {'Jupiter','Venus','Mercury','Moon'};
      const malefics = {'Sun','Mars','Saturn','Rahu','Ketu'};
      // Odd signs = benefic rashis, even = malefic (simplified Vedic grouping)
      const shubhaRashis = {1, 2, 4, 5, 8, 11}; // Taurus, Gemini, Leo, Virgo, Sagittarius, Pisces

      final treeDetails = <String>[];
      final treePlanets = <String>[];
      for (final e in treeTypes.entries) {
        final pLon = allPlanetLons[_knPlanets[e.key]] ?? 0.0;
        final pRashi = _rashiOf(pLon);
        final isBeneficPlanet = benefics.contains(e.key);
        final inShubhaRashi = shubhaRashis.contains(pRashi);

        String quality = '';
        if (isBeneficPlanet && !inShubhaRashi) {
          quality = ' → ಕೆಟ್ಟ ಜಾಗದಲ್ಲಿ ಒಳ್ಳೆಯ ಮರ';
        } else if (!isBeneficPlanet && inShubhaRashi) {
          quality = ' → ಒಳ್ಳೆಯ ಜಾಗದಲ್ಲಿ ಕೆಟ್ಟ ಮರ';
        }

        treeDetails.add('${_knPlanets[e.key]} (${_rashiNames[pRashi]}): ${e.value}$quality');
        treePlanets.add(_knPlanets[e.key]!);
      }

      yogas.add(Yoga(
        shloka: 'ಅಂತಸ್ಸಾರಾನ್ ಜನಯತಿ ರವಿರ್ದುರ್ಭಗಾನ್ ಸೂರ್ಯಸೂನು ಕೀರೋಪೇತಾಂಸುಹಿನಕಿರಣ ಕಂಟಕಾರಾಂಶ ಭೌಮ: ।\nಸ್ನಿಗ್ದಾನಿಂದುಃ ಕಟುಕವಿಟಪಾನ್ ಭೂಮಿಪುತ್ರಶ್ಚ ಭೂಯಃ ಶುಭೋಽಶುಭರ್ಕ್ಷೆ ರುಚಿರಂ ಕುಭೂತಲೇ ಕರೋತಿ ವೃಕ್ಷಂ ವಿಪರೀತಮನ್ಯಥಾ ।',
        name: 'ವೃಕ್ಷ ಪ್ರಕಾರ ಯೋಗ',
        description: '${treeDetails.join('\n')}',
        result: 'ಗ್ರಹ-ಮರ ಸಂಬಂಧ ನಿರ್ಣಯ',
        rashi: lagRashi,
        planets: treePlanets,
      ));

      // ═══ Shloka 8: Tree count by navamsha distance ═══
      final navDistDetails = <String>[];
      final navDistPlanets = <String>[];
      for (final e in allPlanetLons.entries) {
        final engName = _knPlanets.entries.where((kv) => kv.value == e.key).firstOrNull?.key;
        if (engName == null) continue;
        final currentNav = _d9Rashi(e.value);
        // Own navamsha = rashi lord's sign
        final ownNavList = <int>[];
        for (int i = 0; i < 12; i++) {
          if (rashiLords[i] == engName) ownNavList.add(i);
        }
        if (ownNavList.isEmpty) continue;
        final ownNav = ownNavList.first;
        final dist = ((currentNav - ownNav) % 12).abs();
        navDistDetails.add('${e.key}: ನವಾಂಶ ${_rashiNames[currentNav]}, ಸ್ವನವಾಂಶ ${_rashiNames[ownNav]} → $dist ಮರ');
        navDistPlanets.add(e.key);
      }

      yogas.add(Yoga(
        shloka: 'ಪರಾಂಶಕೇ ಯಾವತಿ ವಿಚ್ಯುತಃ ಸ್ವಕಾದ್ಭವಂತಿ ತುಲ್ಯಾಸ್ತರವಸ್ತಥಾವಿಧಾಃ',
        name: 'ನವಾಂಶ ವೃಕ್ಷ ಸಂಖ್ಯೆ',
        description: '${navDistDetails.join('\n')}',
        result: 'ನವಾಂಶ ದೂರದಿಂದ ಮರಗಳ ಸಂಖ್ಯೆ ನಿರ್ಣಯ',
        rashi: lagRashi,
        planets: navDistPlanets,
      ));
    }
    // ══════════════════════════════════════════════════════
    // ನಿಷೇಕಾಧ್ಯಾಯ (Chapter 4) — Conception rules
    // ══════════════════════════════════════════════════════

    // ═══ Nisheka Shloka 1: Menstruation & Union timing ═══
    // Moon in anupachaya (1,2,4,5,7,8) → menstruation
    // Moon in upachaya (3,6,10,11) + benefic/male aspect → union
    final moonHouse = ((_rashiOf(moonLon) - lagRashi) % 12) + 1;
    const upachaya = {3, 6, 10, 11};
    const anupachaya = {1, 2, 4, 5, 7, 8};
    final moonInUpachaya = upachaya.contains(moonHouse);
    final moonInAnupachaya = anupachaya.contains(moonHouse);

    // Check benefic/male planet aspects on Moon
    final moonR = _rashiOf(moonLon);
    final beneficAspMoon = <String>[];
    final malePlanets = {'Sun', 'Mars', 'Jupiter'}; // Male grahas
    for (final e in {'Jupiter':jup,'Venus':ven,'Mercury':mer}.entries) {
      if ((_rashiOf(e.value) + 6) % 12 == moonR) beneficAspMoon.add(_knPlanets[e.key]!);
    }
    final maleAspMoon = <String>[];
    for (final e in {'Sun':sun,'Mars':mars,'Jupiter':jup}.entries) {
      if ((_rashiOf(e.value) + 6) % 12 == moonR) maleAspMoon.add(_knPlanets[e.key]!);
    }

    if (moonInAnupachaya) {
      yogas.add(Yoga(
        shloka: 'ಕುಜೇಂದುಹೇತು ಪ್ರತಿಮಾಸಮಾರ್ತವಂ ಗತೇ ತು ಪೀಡರ್ಕ್ಷಮನುಷ್ಣದೀಧಿತೌ ।\nಅತೋsನ್ಯಥಾಸ್ಥ ಶುಭಪುಂಗ್ರಹೇಕ್ಷಿತೇ ನರೇಣ ಸಂಯೋಗಮುಪೈತಿ ಕಾಮಿನೀ',
        name: 'ಋತುದರ್ಶನ ಯೋಗ',
        description: 'ಚಂದ್ರ ${moonHouse}ನೇ ಮನೆ (ಅನುಪಚಯ) → ಋತುದರ್ಶನ ಸೂಚನೆ',
        result: 'ಚಂದ್ರ ಅನುಪಚಯ ಸ್ಥಾನ: ಋತುಮತಿ ಸಂಭವ',
        rashi: moonR,
        planets: ['ಚಂದ್ರ', 'ಕುಜ'],
      ));
    }
    if (moonInUpachaya && (beneficAspMoon.isNotEmpty || maleAspMoon.isNotEmpty)) {
      yogas.add(Yoga(
        shloka: 'ಕುಜೇಂದುಹೇತು ಪ್ರತಿಮಾಸಮಾರ್ತವಂ ಗತೇ ತು ಪೀಡರ್ಕ್ಷಮನುಷ್ಣದೀಧಿತೌ ।\nಅತೋsನ್ಯಥಾಸ್ಥ ಶುಭಪುಂಗ್ರಹೇಕ್ಷಿತೇ ನರೇಣ ಸಂಯೋಗಮುಪೈತಿ ಕಾಮಿನೀ',
        name: 'ಮಿಲನ ಯೋಗ',
        description: 'ಚಂದ್ರ ${moonHouse}ನೇ ಮನೆ (ಉಪಚಯ)\nಶುಭ ದೃಷ್ಟಿ: ${beneficAspMoon.isEmpty ? "ಇಲ್ಲ" : beneficAspMoon.join(",")}\nಪುರುಷ ಗ್ರಹ ದೃಷ್ಟಿ: ${maleAspMoon.isEmpty ? "ಇಲ್ಲ" : maleAspMoon.join(",")}',
        result: 'ಪುರುಷ ಸಂಯೋಗ ಸಂಭವ',
        rashi: moonR,
        planets: ['ಚಂದ್ರ', ...beneficAspMoon, ...maleAspMoon],
      ));
    }

    // ═══ Nisheka Shloka 2: Nature of union from 7th house ═══
    final h7Rashi = (lagRashi + 6) % 12;
    final malAsp7 = <String>[];
    final benAsp7 = <String>[];
    final malIn7 = <String>[];
    final benIn7 = <String>[];
    final allPLons = {'Sun':sun,'Moon':moon,'Mars':mars,'Mercury':mer,'Jupiter':jup,'Venus':ven,'Saturn':sat,'Rahu':rahu,'Ketu':ketu};
    for (final e in allPLons.entries) {
      final pr = _rashiOf(e.value);
      final isBen = {'Jupiter','Venus','Mercury','Moon'}.contains(e.key);
      if (pr == h7Rashi) {
        (isBen ? benIn7 : malIn7).add(_knPlanets[e.key]!);
      }
      if ((pr + 6) % 12 == h7Rashi) {
        (isBen ? benAsp7 : malAsp7).add(_knPlanets[e.key]!);
      }
    }
    if (malIn7.isNotEmpty || malAsp7.isNotEmpty || benIn7.isNotEmpty || benAsp7.isNotEmpty) {
      String unionType = '';
      if (malIn7.isNotEmpty || malAsp7.isNotEmpty) unionType += 'ಕೋಪದಿಂದ ಕೂಡಿದ ಮಿಲನ';
      if (benIn7.isNotEmpty || benAsp7.isNotEmpty) {
        if (unionType.isNotEmpty) unionType += ' + ';
        unionType += 'ವಿಲಾಸ ಹಾಸ್ಯದಿಂದ ಕೂಡಿದ ಮಿಲನ';
      }
      yogas.add(Yoga(
        shloka: 'ಯಥಾಸ್ತರಾಶಿರ್ಮಿಥುನಂ ಸಮೇತಿ ತಥೈವ ವಾಚ್ಯ ಮಿಥುನ ಪ್ರಯೋಗಃ ।\nಅಸದ್ಗ್ರಹಾಲೋಕಿತಸಂಯುತೇsಸ್ತೇ ಸರೋಷ ಇಷ್ಟೆ ಸವಿಲಾಸಹಾಸಃ',
        name: 'ಮಿಲನ ಸ್ವರೂಪ ಯೋಗ',
        description: '7ನೇ ಮನೆ: ${_rashiNames[h7Rashi]}\nಪಾಪ ಯೋಗ/ದೃಷ್ಟಿ: ${[...malIn7,...malAsp7].isEmpty ? "ಇಲ್ಲ" : [...malIn7,...malAsp7].join(",")}\nಶುಭ ಯೋಗ/ದೃಷ್ಟಿ: ${[...benIn7,...benAsp7].isEmpty ? "ಇಲ್ಲ" : [...benIn7,...benAsp7].join(",")}',
        result: unionType,
        rashi: h7Rashi,
        planets: [...malIn7, ...malAsp7, ...benIn7, ...benAsp7],
      ));
    }

    // ═══ Nisheka Shloka 3: Conception yoga ═══
    // Sun,Moon,Venus,Mars in own navamsha OR Jupiter in 1/5/9
    final sunOwnNav = _isOwnNavamsha('Sun', _d9Rashi(sun));
    final moonOwnNav = _isOwnNavamsha('Moon', _d9Rashi(moon));
    final venOwnNav = _isOwnNavamsha('Venus', _d9Rashi(ven));
    final marsOwnNav = _isOwnNavamsha('Mars', _d9Rashi(mars));
    final allOwnNav = sunOwnNav && moonOwnNav && venOwnNav && marsOwnNav;

    final jupHouse = ((_rashiOf(jup) - lagRashi) % 12) + 1;
    final jupInTrikona = jupHouse == 1 || jupHouse == 5 || jupHouse == 9;

    if (allOwnNav || jupInTrikona) {
      final details = <String>[];
      if (allOwnNav) {
        details.add('ರವಿ ನವಾಂಶ: ${_rashiNames[_d9Rashi(sun)]} ${sunOwnNav ? "✓ ಸ್ವ" : "✗"}');
        details.add('ಚಂದ್ರ ನವಾಂಶ: ${_rashiNames[_d9Rashi(moon)]} ${moonOwnNav ? "✓ ಸ್ವ" : "✗"}');
        details.add('ಶುಕ್ರ ನವಾಂಶ: ${_rashiNames[_d9Rashi(ven)]} ${venOwnNav ? "✓ ಸ್ವ" : "✗"}');
        details.add('ಕುಜ ನವಾಂಶ: ${_rashiNames[_d9Rashi(mars)]} ${marsOwnNav ? "✓ ಸ್ವ" : "✗"}');
      }
      if (jupInTrikona) details.add('ಗುರು ${jupHouse}ನೇ ಮನೆ (ತ್ರಿಕೋಣ)');

      yogas.add(Yoga(
        shloka: 'ರವೀಂದುಶುಕ್ರಾವನಿಜೈಃ ಸ್ವಭಾಗಗೈರ್ಗುರೌ ತ್ರಿಕೋಣೋದಯಧರ್ಮಗೇsಪಿ ವಾ ।\nಭವತ್ಯಪತ್ಯಂ ಹಿ ವಿಬೀಜಿನಾಮಿಮೇ ಕರಾ ಹಿಮಾಂಶೋರ್ವಿದೃಶಾಮಿವಾಫಲಾಃ',
        name: 'ಗರ್ಭಧಾರಣೆ ಯೋಗ',
        description: '${details.join('\n')}',
        result: 'ಗರ್ಭಧಾರಣೆ ಸಂಭವ',
        rashi: lagRashi,
        planets: ['ರವಿ', 'ಚಂದ್ರ', 'ಶುಕ್ರ', 'ಕುಜ', 'ಗುರು'],
      ));
    }

    // ═══ Nisheka Shloka 4: Disease & Death yoga ═══
    final sunHouse = ((_rashiOf(sun) - lagRashi) % 12) + 1;
    final moonHouseN = ((_rashiOf(moonLon) - lagRashi) % 12) + 1;
    final marsR = _rashiOf(mars);
    final satR2 = _rashiOf(sat);

    // Mars/Saturn aspect check on Sun & Moon
    final sunR = _rashiOf(sun);
    final moonR2 = _rashiOf(moonLon);
    bool marsAspSun = (marsR + 6) % 12 == sunR || (marsR + 3) % 12 == sunR || (marsR + 7) % 12 == sunR;
    bool satAspSun = (satR2 + 6) % 12 == sunR || (satR2 + 2) % 12 == sunR || (satR2 + 9) % 12 == sunR;
    bool marsAspMoon = (marsR + 6) % 12 == moonR2 || (marsR + 3) % 12 == moonR2 || (marsR + 7) % 12 == moonR2;
    bool satAspMoon = (satR2 + 6) % 12 == moonR2 || (satR2 + 2) % 12 == moonR2 || (satR2 + 9) % 12 == moonR2;
    final marsSatAsp = (marsAspSun || marsAspMoon) && (satAspSun || satAspMoon);

    // Sun & Moon in 7th → disease
    if (sunHouse == 7 && moonHouseN == 7 && marsSatAsp) {
      yogas.add(Yoga(
        shloka: 'ದಿವಾಕರೇಂದ್ವಃ ಸ್ಮರಗೌ ಕುಜಾರ್ಕಚೌ ಗದಪ್ರದೌ ಪುಂಗಲಯೋಷಿತೋಸ್ತದಾ ।\nವ್ಯಯಸ್ವಗೌ ಮೃತ್ಯುಕರೌ ತಥಾ ಯುತೌ ತದೇಕದೃಷ್ಟಾ ಮರಣಾಯ ಕಲ್ಪಿತೌ',
        name: 'ರೋಗ ಯೋಗ (ನಿಷೇಕ)',
        description: 'ರವಿ+ಚಂದ್ರ 7ನೇ ಮನೆ (${_rashiNames[h7Rashi]})\nಕುಜ (${_rashiNames[marsR]}) ದೃಷ್ಟಿ: ${marsAspSun || marsAspMoon ? "✓" : "✗"}\nಶನಿ (${_rashiNames[satR2]}) ದೃಷ್ಟಿ: ${satAspSun || satAspMoon ? "✓" : "✗"}',
        result: 'ಪುರುಷ ಮತ್ತು ಸ್ತ್ರೀಗೆ ರೋಗ ಸಂಭವ',
        rashi: h7Rashi,
        planets: ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಶನಿ'],
      ));
    }

    // Sun in 12th & Moon in 2nd (or vice versa) + Mars/Saturn aspect → death
    final sunIn12 = sunHouse == 12;
    final moonIn2 = moonHouseN == 2;
    final sunIn2 = sunHouse == 2;
    final moonIn12 = moonHouseN == 12;
    if (((sunIn12 && moonIn2) || (sunIn2 && moonIn12)) && marsSatAsp) {
      yogas.add(Yoga(
        shloka: 'ದಿವಾಕರೇಂದ್ವಃ ಸ್ಮರಗೌ ಕುಜಾರ್ಕಚೌ ಗದಪ್ರದೌ ಪುಂಗಲಯೋಷಿತೋಸ್ತದಾ ।\nವ್ಯಯಸ್ವಗೌ ಮೃತ್ಯುಕರೌ ತಥಾ ಯುತೌ ತದೇಕದೃಷ್ಟಾ ಮರಣಾಯ ಕಲ್ಪಿತೌ',
        name: 'ಮರಣ ಯೋಗ (ನಿಷೇಕ)',
        description: 'ರವಿ ${sunHouse}ನೇ ಮನೆ | ಚಂದ್ರ ${moonHouseN}ನೇ ಮನೆ (12+2 ಸ್ಥಾನ)\nಕುಜ (${_rashiNames[marsR]}) ದೃಷ್ಟಿ: ✓ | ಶನಿ (${_rashiNames[satR2]}) ದೃಷ್ಟಿ: ✓',
        result: 'ಇಬ್ಬರಿಗೂ ಮರಣ ಸಂಭವ',
        rashi: lagRashi,
        planets: ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಶನಿ'],
      ));
    }
    // ═══ Nisheka Shloka 5: Parent karakas (day/night) ═══
    // Determine if birth time is day or night using Sun position
    // Sun above horizon (houses 7-12 from lagna) = day, else night
    final isDay = sunHouse >= 7 && sunHouse <= 12;
    final fatherK = isDay ? 'ರವಿ' : 'ಶನಿ';
    final motherK = isDay ? 'ಶುಕ್ರ' : 'ಚಂದ್ರ';
    final uncleK = isDay ? 'ಶನಿ' : 'ರವಿ';
    final auntK = isDay ? 'ಚಂದ್ರ' : 'ಶುಕ್ರ';

    // Check odd/even rashi for shubha phala
    final fatherLon = isDay ? sun : sat;
    final motherLon = isDay ? ven : moon;
    final fR = _rashiOf(fatherLon);
    final mR = _rashiOf(motherLon);
    final fOdd = fR % 2 == 0; // 0-indexed: Aries=0(even idx=odd sign)
    final mEven = mR % 2 == 1; // odd idx = even sign
    final shubha = fOdd && mEven;

    yogas.add(Yoga(
      shloka: 'ದಿವಾರ್ಕಶುಕ್ರ ಪಿತೃಮಾತೃಸಂಜ್ಜಿ ಶನೈಶ್ಚರೇಂದೂ ನಿಶಿ ತದ್ವಿಪರ್ಯಯಾತ್ ।\nಪಿತೃವ್ಯಮಾತೃಷ್ಟಸೃಸಂಜ್ಜಿತೌ ತು ತಾವಫೌಜಯುಗ್ಧರ್ಕ್ಷಗತೌ ತಯೋಃ ಶುಭೌ',
      name: 'ಪಿತೃ-ಮಾತೃ ಕಾರಕ ಯೋಗ',
      description: '${isDay ? "ಹಗಲು" : "ರಾತ್ರಿ"} ಜನನ\nತಂದೆ ಕಾರಕ: $fatherK (${_rashiNames[fR]}) | ತಾಯಿ ಕಾರಕ: $motherK (${_rashiNames[mR]})\nಚಿಕ್ಕಪ್ಪ: $uncleK | ಚಿಕ್ಕಮ್ಮ: $auntK',
      result: shubha ? 'ಶುಭ ಫಲ (ಬೆಸ/ಸಮ ರಾಶಿ ✓)' : 'ಶುಭ ಫಲ ಅನಿಶ್ಚಿತ',
      rashi: lagRashi,
      planets: [fatherK, motherK, uncleK, auntK],
    ));

    // ═══ Nisheka Shloka 6: Pregnant woman death (malefics in lagna) ═══
    final malInLag = <String>[];
    final benAspLag = <String>[];
    for (final e in allPLons.entries) {
      final pr = _rashiOf(e.value);
      final isBen = {'Jupiter','Venus','Mercury','Moon'}.contains(e.key);
      if (pr == lagRashi && !isBen) malInLag.add(_knPlanets[e.key]!);
      if ((pr + 6) % 12 == lagRashi && isBen) benAspLag.add(_knPlanets[e.key]!);
    }
    if (malInLag.isNotEmpty && benAspLag.isEmpty) {
      yogas.add(Yoga(
        shloka: 'ಅಭಿಲಷದ್ಧಿರುದಯರ್ಕ್ಷಮಸದ್ಧಿರ್ಮರಣಮೇತಿ ಶುಭದೃಷ್ಟಿಮಯಾತೇ',
        name: 'ಗರ್ಭಿಣಿ ಮರಣ ಯೋಗ (೬)',
        description: 'ಲಗ್ನ (${_rashiNames[lagRashi]}) ಪಾಪರು: ${malInLag.join(",")}\nಶುಭ ದೃಷ್ಟಿ: ಇಲ್ಲ',
        result: 'ಗರ್ಭಿಣಿ ಮರಣ ಸಂಭವ',
        rashi: lagRashi,
        planets: malInLag,
      ));
    }

    // ═══ Nisheka Shloka 7: Saturn in lagna + waning Moon & Mars aspect ═══
    final satInLag = _rashiOf(sat) == lagRashi;
    final moonWaneDiff = (moonLon - sun + 360) % 360;
    final moonWaning = moonWaneDiff > 180; // Krishna Paksha = waning
    final marsAspLag = (marsR + 6) % 12 == lagRashi || (marsR + 3) % 12 == lagRashi || (marsR + 7) % 12 == lagRashi;
    final moonAspLag = (moonR2 + 6) % 12 == lagRashi;
    if (satInLag && moonWaning && (marsAspLag || moonAspLag)) {
      yogas.add(Yoga(
        shloka: 'ಉದಯರಾಶಿಸಹಿತೇ ಚ ಯಮೇ ಸ್ತ್ರೀ ಎಗಲಿತೋಡುಪತಿಭೂಸುತದೃಷ್ಟೇ',
        name: 'ಗರ್ಭಿಣಿ ಮರಣ ಯೋಗ (೭)',
        description: 'ಶನಿ ಲಗ್ನದಲ್ಲಿ (${_rashiNames[lagRashi]})\nಕ್ಷೀಣ ಚಂದ್ರ: ${moonWaning ? "✓" : "✗"}\nಕುಜ ದೃಷ್ಟಿ: ${marsAspLag ? "✓" : "✗"}',
        result: 'ಗರ್ಭಿಣಿ ಮರಣ ಸಂಭವ',
        rashi: lagRashi,
        planets: ['ಶನಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
      ));
    }

    // ═══ Nisheka Shloka 8: Papa Kartari on lagna & Moon ═══
    // Check if lagna/Moon hemmed between malefics without benefic aspect
    bool _isPapaKartari(int rashi) {
      final prev = (rashi - 1 + 12) % 12;
      final next = (rashi + 1) % 12;
      bool malPrev = false, malNext = false;
      for (final e in allPLons.entries) {
        if ({'Sun','Mars','Saturn','Rahu','Ketu'}.contains(e.key)) {
          if (_rashiOf(e.value) == prev) malPrev = true;
          if (_rashiOf(e.value) == next) malNext = true;
        }
      }
      return malPrev && malNext;
    }
    bool _hasBenAsp(int rashi) {
      for (final e in allPLons.entries) {
        if ({'Jupiter','Venus','Mercury','Moon'}.contains(e.key)) {
          if ((_rashiOf(e.value) + 6) % 12 == rashi) return true;
        }
      }
      return false;
    }
    final lagPK = _isPapaKartari(lagRashi);
    final moonPK = _isPapaKartari(moonR2);
    final lagNoBen = !_hasBenAsp(lagRashi);
    final moonNoBen = !_hasBenAsp(moonR2);
    if ((lagPK && lagNoBen) || (moonPK && moonNoBen)) {
      yogas.add(Yoga(
        shloka: 'ಅಶುಭದ್ವಯಮಧ್ಯಸಂಸ್ಥಿತೌ ಲಗ್ನಂದೂ ನ ಚ ಸೌಮ್ಯವೀಕ್ಷಿತ್ ।\nಯುಗಪತ್ ಪೃಥಗೇವ ವಾ ವದೇನ್ನಾರೀ ಗರ್ಭಯುತಾ ವಿಪದ್ಯತೇ',
        name: 'ಪಾಪಕರ್ತರಿ ಮರಣ ಯೋಗ (೮)',
        description: 'ಲಗ್ನ ಪಾಪಕರ್ತರಿ: ${lagPK ? "✓" : "✗"} | ಶುಭ ದೃಷ್ಟಿ: ${lagNoBen ? "ಇಲ್ಲ" : "ಇದೆ"}\nಚಂದ್ರ ಪಾಪಕರ್ತರಿ: ${moonPK ? "✓" : "✗"} | ಶುಭ ದೃಷ್ಟಿ: ${moonNoBen ? "ಇಲ್ಲ" : "ಇದೆ"}',
        result: 'ಗರ್ಭಿಣಿ ಮರಣ ಸಂಭವ (ಒಟ್ಟಿಗೆ/ಪ್ರತ್ಯೇಕ)',
        rashi: lagRashi,
        planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ Nisheka Shloka 9: Mars in 4/8 from lagna or Moon ═══
    final marsFromLag = ((marsR - lagRashi) % 12) + 1;
    final marsFromMoon = ((marsR - moonR2) % 12) + 1;
    final marsIn48 = marsFromLag == 4 || marsFromLag == 8 || marsFromMoon == 4 || marsFromMoon == 8;
    // Mars+Sun in 4th and 12th with waning Moon
    final sunFromLag = sunHouse;
    final marsIn4Sun12 = (marsFromLag == 4 && sunFromLag == 12) || (marsFromLag == 12 && sunFromLag == 4);
    if (marsIn48 || (marsIn4Sun12 && moonWaning)) {
      final detail = <String>[];
      if (marsFromLag == 4 || marsFromLag == 8) detail.add('ಕುಜ ಲಗ್ನದಿಂದ ${marsFromLag}ನೇ ಮನೆ');
      if (marsFromMoon == 4 || marsFromMoon == 8) detail.add('ಕುಜ ಚಂದ್ರನಿಂದ ${marsFromMoon}ನೇ ಮನೆ');
      if (marsIn4Sun12 && moonWaning) detail.add('ಕುಜ+ರವಿ 4/12 ಸ್ಥಾನ, ಕ್ಷೀಣ ಚಂದ್ರ');
      yogas.add(Yoga(
        shloka: 'ಶಶಿನಶ್ಚತುರ್ಥಗೇ ಲಗ್ನಾದ್ವಾ ನಿಧನಾಶ್ರಿತೇ ಕುಚೇ ।\nಬಂಧಂತ್ಯಗಯೋ ಕುಜಾರ್ಕಯೋಃ ಕ್ಷೀಣೇಂದೌ ನಿಧನಾಯ ಪೂರ್ವವತ್',
        name: 'ಕುಜ ಸ್ಥಾನ ಮರಣ ಯೋಗ (೯)',
        description: '${detail.join('\n')}',
        result: 'ಗರ್ಭಿಣಿ ಮರಣ ಸಂಭವ',
        rashi: marsR,
        planets: ['ಕುಜ', 'ರವಿ', 'ಚಂದ್ರ'],
      ));
    }

    // ═══ Nisheka Shloka 10: Mars+Sun in 1/7 → weapon death; month lord afflicted → miscarriage ═══
    final marsIn1 = marsFromLag == 1;
    final marsIn7 = marsFromLag == 7;
    final sunIn1 = sunHouse == 1;
    final sunIn7 = sunHouse == 7;
    if ((marsIn1 && sunIn7) || (marsIn7 && sunIn1)) {
      yogas.add(Yoga(
        shloka: 'ಉದಯಾಸ್ತಗಯೋಃ ಕುಚಾರ್ಕಯೋರ್ನಿಧನಂ ಶಸ್ತ್ರಕೃತಂ ವದೇತ್ತದಾ ।\nಮಾಸಾಧಿಪತೌ ನಿಪೀಡಿತೇ ತತ್ಕಾಲೇ ಸ್ರವಣಂ ಸಮಾದಿಶೇತ್',
        name: 'ಶಸ್ತ್ರ ಮರಣ ಯೋಗ (೧೦)',
        description: 'ಕುಜ ${marsFromLag}ನೇ ಮನೆ | ರವಿ ${sunHouse}ನೇ ಮನೆ\nಲಗ್ನ-7 ಅಕ್ಷದಲ್ಲಿ ಕುಜ+ರವಿ',
        result: 'ಶಸ್ತ್ರಾಸ್ತ್ರಗಳಿಂದ ಮರಣ ಸಂಭವ',
        rashi: lagRashi,
        planets: ['ಕುಜ', 'ರವಿ'],
      ));
    }

    // Month lord affliction check (pregnancy months: 1-Sun,2-Moon,3-Mars,4-Mer,5-Jup,6-Ven,7-Sat)
    const monthLords = ['Sun','Moon','Mars','Mercury','Jupiter','Venus','Saturn'];
    const monthLordKn = ['ರವಿ','ಚಂದ್ರ','ಕುಜ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ'];
    final afflictedMonths = <String>[];
    for (int m = 0; m < 7; m++) {
      final mLord = monthLords[m];
      final mLon = allPLons[mLord] ?? 0.0;
      final mRashi = _rashiOf(mLon);
      bool afflicted = false;
      for (final mal in ['Sun','Mars','Saturn','Rahu','Ketu']) {
        if (mal == mLord) continue;
        final malR2 = _rashiOf(allPLons[mal] ?? 0.0);
        if (malR2 == mRashi) afflicted = true; // conjunction
        if ((malR2 + 6) % 12 == mRashi) afflicted = true; // 7th aspect
      }
      if (afflicted) afflictedMonths.add('${m+1}ನೇ ತಿಂಗಳು (${monthLordKn[m]})');
    }
    if (afflictedMonths.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ಮಾಸಾಧಿಪತೌ ನಿಪೀಡಿತೇ ತತ್ಕಾಲೇ ಸ್ರವಣಂ ಸಮಾದಿಶೇತ್',
        name: 'ಗರ್ಭಸ್ರಾವ ಯೋಗ (೧೦)',
        description: 'ಪೀಡಿತ ಮಾಸಾಧಿಪತಿ:\n${afflictedMonths.join('\n')}',
        result: 'ಗರ್ಭಸ್ರಾವ ಸಂಭವ',
        rashi: lagRashi,
        planets: afflictedMonths.map((s) => s.split('(').last.replaceAll(')', '')).toList(),
      ));
    }

    // ═══ Nisheka Shloka 11: Comfortable pregnancy ═══
    // Benefics in lagna, Moon, 5,9,2,4,10 AND malefics in 3,11 AND Sun aspect
    const benHouses = {1, 2, 4, 5, 9, 10};
    const malHousesGood = {3, 11};
    final benInGood = <String>[];
    final malInGoodH = <String>[];
    for (final e in allPLons.entries) {
      final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      final isBen = {'Jupiter','Venus','Mercury','Moon'}.contains(e.key);
      if (isBen && benHouses.contains(h)) benInGood.add('${_knPlanets[e.key]} ${h}ನೇ');
      if (!isBen && malHousesGood.contains(h)) malInGoodH.add('${_knPlanets[e.key]} ${h}ನೇ');
    }
    final sunAspLag = (sunR + 6) % 12 == lagRashi;
    if (benInGood.isNotEmpty && malInGoodH.isNotEmpty && sunAspLag) {
      yogas.add(Yoga(
        shloka: 'ಶಶಾಂಕಲಗೋಪಗತೈ: ಶುಭಗ್ರಹೈಸ್ತಿಕೋಣಚಾಯಾರ್ಥಸುಖಾಸ್ಪದಸ್ಥಿತೈಃ ।\nತೃತೀಯಲಾಭರ್ಕ್ಷಗತೈರಶೋಭನೈ: ಸುಖೀ ಚ ಗರ್ಭೋ ರವಿಣಾಭಿವೀಕ್ಷಿತಃ',
        name: 'ಸುಖ ಗರ್ಭ ಯೋಗ (೧೧)',
        description: 'ಶುಭರು ಶುಭ ಸ್ಥಾನ: ${benInGood.join(", ")}\nಪಾಪರು 3/11: ${malInGoodH.join(", ")}\nರವಿ ದೃಷ್ಟಿ: ${sunAspLag ? "✓" : "✗"}',
        result: 'ಗರ್ಭ ಸುಖಕರ',
        rashi: lagRashi,
        planets: ['ರವಿ', ...benInGood.map((s) => s.split(' ').first), ...malInGoodH.map((s) => s.split(' ').first)],
      ));
    }
    // ═══ Nisheka Shlokas 12 & 13: Gender of child ═══
    bool _isOddSign(int r) => r % 2 == 0; // Aries=0, Gemini=2, Leo=4...
    bool _isEvenSign(int r) => r % 2 == 1; // Taurus=1, Cancer=3...
    bool _isDualSign(int r) => r == 2 || r == 5 || r == 8 || r == 11;

    final sunOdd = _isOddSign(sunR);
    final jupOdd = _isOddSign(_rashiOf(jup));
    final jupR = _rashiOf(jup);
    final moonOdd = _isOddSign(moonR2);
    final lagOdd = _isOddSign(lagRashi);
    
    final sunEven = _isEvenSign(sunR);
    final jupEven = _isEvenSign(jupR);
    final moonEven = _isEvenSign(moonR2);
    final lagEven = _isEvenSign(lagRashi);
    
    final venR = _rashiOf(ven);
    final venEven = _isEvenSign(venR);
    final marsEven = _isEvenSign(marsR);

    final sunNavOdd = _isOddSign(_d9Rashi(sun));
    final jupNavOdd = _isOddSign(_d9Rashi(jup));
    final moonNavOdd = _isOddSign(_d9Rashi(moonLon));
    final lagNavOdd = _isOddSign(_d9Rashi(lag));
    
    final sunNavEven = _isEvenSign(_d9Rashi(sun));
    final jupNavEven = _isEvenSign(_d9Rashi(jup));
    final moonNavEven = _isEvenSign(_d9Rashi(moonLon));
    final lagNavEven = _isEvenSign(_d9Rashi(lag));

    final sunStr = isStrong('Sun');
    final jupStr = isStrong('Jupiter');
    final moonStr = isStrong('Moon');
    final lagLordStr = isStrong(rashiLords[lagRashi]);

    bool boyYoga1 = lagOdd && sunOdd && jupOdd && moonOdd && lagNavOdd && sunNavOdd && jupNavOdd && moonNavOdd && sunStr && jupStr && moonStr && lagLordStr;
    bool girlYoga1 = lagEven && sunEven && jupEven && moonEven && lagNavEven && sunNavEven && jupNavEven && moonNavEven && sunStr && jupStr && moonStr && lagLordStr;
    
    bool boyYoga2 = jupOdd && sunOdd;
    bool girlYoga2 = moonEven && venEven && marsEven;
    
    final merR = _rashiOf(mer);
    // Mercury aspect on Lagna/Moon in dual navamsha
    final lagNavR12 = _d9Rashi(lag);
    bool lagDual = _isDualSign(lagNavR12);
    bool merAspLag = (merR + 6) % 12 == lagRashi;
    bool twinsYoga1 = lagDual && merAspLag; 
    
    // Shloka 13: Saturn in odd sign (except Lagna)
    bool boyYoga3 = _isOddSign(satR2) && satR2 != lagRashi;

    if (boyYoga1 || boyYoga2 || boyYoga3) {
      final reasons = <String>[];
      if (boyYoga1) reasons.add('ಲಗ್ನ, ರವಿ, ಗುರು, ಚಂದ್ರ ಬೆಸ ರಾಶಿ & ನವಾಂಶದಲ್ಲಿ ಬಲಶಾಲಿ');
      if (boyYoga2) reasons.add('ಗುರು, ರವಿ ಬೆಸ ರಾಶಿಯಲ್ಲಿ');
      if (boyYoga3) reasons.add('ಶನಿ ಬೆಸ ರಾಶಿಯಲ್ಲಿ (ಲಗ್ನ ಹೊರತುಪಡಿಸಿ)');
      yogas.add(Yoga(
        shloka: 'ಓಜರ್ಕ್ಷೇ ಪುರುಷಾಂಶಕೇಷು ಬಲಿಭಿರ್ಲಗ್ನಾರ್ಕಗುರ್ವಿಂದುಭಿಃ...\nವಿಹಾಯ ಲಗ್ನಂ ವಿಷಮರ್ಕ್ಷಸಂಸ್ಥಃ ಸೌರೋsಪಿ ಪುಂಜ ಕರೋ ವಿಲಗ್ನಾತ್',
        name: 'ಪುತ್ರ ಜನನ ಯೋಗ (೧೨,೧೩)',
        description: reasons.join('\n'),
        result: 'ಗಂಡು ಮಗುವಿನ ಜನನ',
        rashi: lagRashi,
        planets: ['ರವಿ', 'ಗುರು', 'ಚಂದ್ರ', 'ಶನಿ'],
      ));
    }
    
    if (girlYoga1 || girlYoga2) {
      final reasons = <String>[];
      if (girlYoga1) reasons.add('ಲಗ್ನ, ರವಿ, ಗುರು, ಚಂದ್ರ ಸಮ ರಾಶಿ & ನವಾಂಶದಲ್ಲಿ ಬಲಶಾಲಿ');
      if (girlYoga2) reasons.add('ಚಂದ್ರ, ಶುಕ್ರ, ಕುಜ ಸಮ ರಾಶಿಯಲ್ಲಿ');
      yogas.add(Yoga(
        shloka: 'ಸಮಾಂಶಸಹಿತೈರ್ಯುಕ್ಕೇಷು ತೈರ್ಯೋಷಿತಾಮ್...',
        name: 'ಪುತ್ರಿ ಜನನ ಯೋಗ (೧೨)',
        description: reasons.join('\n'),
        result: 'ಹೆಣ್ಣು ಮಗುವಿನ ಜನನ',
        rashi: lagRashi,
        planets: ['ಚಂದ್ರ', 'ಶುಕ್ರ', 'ಕುಜ'],
      ));
    }

    if (twinsYoga1) {
      yogas.add(Yoga(
        shloka: 'ದ್ವಂಶಸ್ಥಾ ಬುಧವೀಕ್ಷಣಾಚ ಯಮಲಂ ಕುರ್ವಂತಿ ಪಕ್ಷೇ ಸಕೇ',
        name: 'ಅವಳಿ ಜನನ ಯೋಗ (೧೨)',
        description: 'ಲಗ್ನ ನವಾಂಶ ದ್ವಿಸ್ವಭಾವ (${_rashiNames[lagNavR12]}) + ಬುಧನ ದೃಷ್ಟಿ',
        result: 'ಅವಳಿ ಮಕ್ಕಳ ಜನನ',
        rashi: lagRashi,
        planets: ['ಬುಧ'],
      ));
    }

    // ═══ Nisheka Shloka 14: Napumsaka (Eunuch) Yoga ═══
    bool napumsaka1 = (sunR + 6) % 12 == moonR2 || (moonR2 + 6) % 12 == sunR;
    bool napumsaka2 = (satR2 + 6) % 12 == merR || (merR + 6) % 12 == satR2;
    bool marsAspSun14 = (marsR + 6) % 12 == sunR || (marsR + 3) % 12 == sunR || (marsR + 7) % 12 == sunR;
    bool napumsaka3 = sunEven && marsAspSun14 && moonOdd && lagOdd;
    final venNavOdd = _isOddSign(_d9Rashi(ven));
    bool napumsaka4 = moonNavOdd && lagNavOdd && venNavOdd;
    
    if (napumsaka1 || napumsaka2 || napumsaka3 || napumsaka4) {
      final reasons = <String>[];
      if (napumsaka1) reasons.add('ರವಿ ಮತ್ತು ಚಂದ್ರರ ಪರಸ್ಪರ ದೃಷ್ಟಿ');
      if (napumsaka2) reasons.add('ಶನಿ ಮತ್ತು ಬುಧರ ಪರಸ್ಪರ ದೃಷ್ಟಿ');
      if (napumsaka3) reasons.add('ಸಮ ರಾಶಿಯಲ್ಲಿ ರವಿ + ಕುಜನ ದೃಷ್ಟಿ, ಚಂದ್ರ ಮತ್ತು ಲಗ್ನ ಬೆಸ ರಾಶಿಯಲ್ಲಿ');
      if (napumsaka4) reasons.add('ಚಂದ್ರ, ಲಗ್ನ, ಶುಕ್ರ ಪುರುಷ (ಬೆಸ) ನವಾಂಶದಲ್ಲಿ');
      yogas.add(Yoga(
        shloka: 'ಅನ್ನೋ ನ್ಯಂ ಯದಿ ಪಶ್ಯತಃ ಶಶಿರವೀ ಯದ್ವಾರ್ಕಿಸೌಮ್ಯ ತಥಾ...',
        name: 'ಕ್ಲೀಬ (ನಪುಂಸಕ) ಯೋಗ (೧೪)',
        description: reasons.join('\n'),
        result: 'ನಪುಂಸಕ ಜನನ',
        rashi: lagRashi,
        planets: ['ರವಿ', 'ಚಂದ್ರ', 'ಶನಿ', 'ಬುಧ', 'ಕುಜ', 'ಶುಕ್ರ'],
      ));
    }

    // ═══ Nisheka Shloka 15: Twins Yoga 2 ═══
    final merOdd = _isOddSign(merR);
    final marsOdd = _isOddSign(marsR);
    bool twins15a = moonEven && venEven && sunOdd && merOdd && marsOdd && jupOdd && lagOdd;
    
    bool maleAspLagMoon = false;
    for (int r in [lagRashi, moonR2]) {
      if ((sunR + 6) % 12 == r || 
          (marsR + 6) % 12 == r || (marsR + 3) % 12 == r || (marsR + 7) % 12 == r ||
          (jupR + 6) % 12 == r || (jupR + 4) % 12 == r || (jupR + 8) % 12 == r) {
        maleAspLagMoon = true;
      }
    }
    bool twins15b = lagEven && moonEven && maleAspLagMoon;
    
    if (twins15a || twins15b) {
      final reasons = <String>[];
      if (twins15a) reasons.add('ಚಂದ್ರ, ಶುಕ್ರ ಸಮ ರಾಶಿಯಲ್ಲಿ; ರವಿ, ಬುಧ, ಕುಜ, ಗುರು, ಲಗ್ನ ಬೆಸ ರಾಶಿಯಲ್ಲಿ');
      if (twins15b) reasons.add('ಲಗ್ನ ಮತ್ತು ಚಂದ್ರ ಸಮ ರಾಶಿಯಲ್ಲಿ + ಪುರುಷ ಗ್ರಹರ ದೃಷ್ಟಿ');
      yogas.add(Yoga(
        shloka: 'ಯುಗ್ರೇ ಚಂದ್ರಸಿತಾವಫೌಜಭವನೇ ಸುರ್ಜ್ಞಾರಜೀವೋದಯಾ...',
        name: 'ಅವಳಿ ಜನನ ಯೋಗ (೧೫)',
        description: reasons.join('\n'),
        result: 'ಅವಳಿ ಮಕ್ಕಳ ಜನನ',
        rashi: lagRashi,
        planets: ['ಚಂದ್ರ', 'ಶುಕ್ರ', 'ರವಿ', 'ಬುಧ', 'ಕುಜ', 'ಗುರು'],
      ));
    }

    // ═══ Nisheka Shloka 16: Multiple births & Month Lords ═══
    final merAspLag16 = (merR + 6) % 12 == lagRashi;
    final satAspLag16 = (satR2 + 6) % 12 == lagRashi || (satR2 + 2) % 12 == lagRashi || (satR2 + 9) % 12 == lagRashi;
    if (lagRashi == 8 && merAspLag16 && satAspLag16) {
      yogas.add(Yoga(
        shloka: 'ಧನುರ್ಧರಸ್ಯಾಂತ್ಯಗತೇ ವಿಲನ್ನೇ ಗ್ರಹೈಸ್ತದಂಶೋಪಗತೈರ್ಬಲಿಃ...',
        name: 'ಬಹು ಸಂತಾನ ಯೋಗ (೧೬)',
        description: 'ಧನುಸ್ಸು ಲಗ್ನ + ಶನಿ ಮತ್ತು ಬುಧರ ದೃಷ್ಟಿ',
        result: 'ಅನೇಕ ಮಕ್ಕಳ ಜನನ',
        rashi: 8,
        planets: ['ಶನಿ', 'ಬುಧ'],
      ));
    }

    // Month lords logic:
    // 1-Venus, 2-Mars, 3-Jupiter, 4-Sun, 5-Moon, 6-Saturn, 7-Mercury, 8-Lagna Lord, 9-Moon, 10-Sun
    final monthLords16 = [
      'Venus', 'Mars', 'Jupiter', 'Sun', 'Moon', 'Saturn', 'Mercury', rashiLords[lagRashi], 'Moon', 'Sun'
    ];
    final monthLordsKn16 = [
      'ಶುಕ್ರ', 'ಕುಜ', 'ಗುರು', 'ರವಿ', 'ಚಂದ್ರ', 'ಶನಿ', 'ಬುಧ', _knPlanets[rashiLords[lagRashi]]!, 'ಚಂದ್ರ', 'ರವಿ'
    ];
    
    final monthDetails = <String>[];
    for (int m = 0; m < 10; m++) {
      final mLord = monthLords16[m];
      final mLordNameKn = monthLordsKn16[m];
      final mLon = allPLons[mLord] ?? 0.0;
      final mR = _rashiOf(mLon);
      
      bool afflicted = false;
      for (final mal in ['Sun','Mars','Saturn','Rahu','Ketu']) {
        if (mal == mLord) continue;
        final malR2 = _rashiOf(allPLons[mal] ?? 0.0);
        if (malR2 == mR) afflicted = true; // conjunction
        if ((malR2 + 6) % 12 == mR) afflicted = true; // 7th aspect
        if (mal == 'Mars' && ((malR2 + 3) % 12 == mR || (malR2 + 7) % 12 == mR)) afflicted = true;
        if (mal == 'Saturn' && ((malR2 + 2) % 12 == mR || (malR2 + 9) % 12 == mR)) afflicted = true;
      }
      
      bool isGood = !afflicted && isStrong(mLord);
      monthDetails.add('${m+1}ನೇ ತಿಂಗಳು ($mLordNameKn): ${afflicted ? "ಅಶುಭ (ಪೀಡಿತ)" : isGood ? "ಶುಭ (ಬಲಶಾಲಿ)" : "ಸಾಮಾನ್ಯ"}');
    }
    
    yogas.add(Yoga(
      shloka: 'ಕಲಲಘನಾಂಕುರಾಸ್ಥಿಚರ್ಮಾಂಗಜಚೇತನದಾಃ ಸಿತಕುಜಜೀವಸೂರ್ಯಚಂದ್ರಾರ್ಕಿಬುಧಾಃ...',
      name: 'ಗರ್ಭ ಮಾಸಾಧಿಪತಿ ಫಲ (೧೬)',
      description: monthDetails.join('\n'),
      result: 'ಮಾಸಾಧಿಪತಿಗಳ ಬಲಾಬಲದಂತೆ ಗರ್ಭಸ್ಥಿತಿ',
      rashi: lagRashi,
      planets: monthLordsKn16.toSet().toList(),
    ));

    // ═══ Nisheka Shloka 17: Double limbs & Mute child ═══
    final trik1 = (lagRashi + 4) % 12;
    final trik2 = (lagRashi + 8) % 12;
    final weakMalInTrikona = <String>[];
    for (final e in malLons.entries) {
      final r = _rashiOf(e.value);
      if ((r == lagRashi || r == trik1 || r == trik2) && isWeak(e.key)) {
        weakMalInTrikona.add(_knPlanets[e.key]!);
      }
    }
    if (weakMalInTrikona.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ತ್ರಿಕೋಣಗೇ ವಿಬಲೈಸ್ತತೋsಪರೈರ್ಮುಖಾಂಫ್ರಿಹಸೊರ್ದ್ವಿಗುಣಸ್ತದಾ ಭವೇತ್',
        name: 'ದ್ವಿಗುಣ ಅಂಗ ಯೋಗ (೧೭)',
        description: 'ದುರ್ಬಲ ಪಾಪರು ತ್ರಿಕೋಣದಲ್ಲಿ: ${weakMalInTrikona.join(", ")}',
        result: 'ಶಿಶುವಿಗೆ ಎರಡು ಮುಖ/ಕೈ/ಕಾಲು',
        rashi: lagRashi,
        planets: weakMalInTrikona,
      ));
    }
    if (moonR2 == 1) {
      bool malAspM17 = false;
      for (final e in malLons.entries) {
        if ((_rashiOf(e.value) + 6) % 12 == 1) malAspM17 = true;
      }
      bool benAspM17 = false;
      for (final e in allPLons.entries) {
        if ({'Jupiter','Venus','Mercury'}.contains(e.key) && (_rashiOf(e.value) + 6) % 12 == 1) benAspM17 = true;
      }
      if (malAspM17) {
        yogas.add(Yoga(
          shloka: 'ಅವಾಗ್ಗವೀಂದಾವಶುಭೈರ್ಭಸಂಧಿಗೈ: ಶುಭೇಕ್ಷಿತೇ ಚೇತ್ಕುರುತೇ ಗಿರಂ ಚಿರಾತ್',
          name: 'ಮೂಕ/ವಿಳಂಬ ವಾಕ್ ಯೋಗ (೧೭)',
          description: 'ಚಂದ್ರ ವೃಷಭದಲ್ಲಿ + ಪಾಪ ದೃಷ್ಟಿ\nಶುಭ ದೃಷ್ಟಿ: ${benAspM17 ? "ಇದೆ → ತಡವಾಗಿ ಮಾತು" : "ಇಲ್ಲ → ಮೂಗ"}',
          result: benAspM17 ? 'ತಡವಾಗಿ ಮಾತನಾಡುತ್ತಾನೆ' : 'ಮೂಕತ್ವ',
          rashi: 1,
          planets: ['ಚಂದ್ರ'],
        ));
      }
    }

    // ═══ Nisheka Shloka 18: Teeth/Hunchback/Lame/Dull ═══
    final satNavR18 = _d9Rashi(sat);
    final marsNavR18 = _d9Rashi(mars);
    final merNavR18 = _d9Rashi(mer);
    final mercurySigns18 = {2, 5}; // Gemini, Virgo = Mercury-ruled signs
    if (mercurySigns18.contains(satNavR18) && mercurySigns18.contains(marsNavR18)) {
      yogas.add(Yoga(
        shloka: 'ಸೌಮ್ಯರ್ಕ್ಷಾಂಶೇ ರವಿಜರುಧಿರೌ ಚೇತ್ಸದಂತೋsತ್ರ ಜಾತಃ',
        name: 'ಸದಂತ ಜನನ ಯೋಗ (೧೮)',
        description: 'ಶನಿ ನವಾಂಶ: ${_rashiNames[satNavR18]} ಮತ್ತು ಕುಜ ನವಾಂಶ: ${_rashiNames[marsNavR18]} (ಬುಧ ಕ್ಷೇತ್ರ)',
        result: 'ಹಲ್ಲುಗಳೊಂದಿಗೆ ಜನನ',
        rashi: lagRashi,
        planets: ['ಶನಿ', 'ಕುಜ', 'ಬುಧ'],
      ));
    }
    if (lagRashi == 3 && moonR2 == 3) {
      final sAC = (satR2 + 6) % 12 == 3 || (satR2 + 2) % 12 == 3 || (satR2 + 9) % 12 == 3;
      final mAC = (marsR + 6) % 12 == 3 || (marsR + 3) % 12 == 3 || (marsR + 7) % 12 == 3;
      if (sAC && mAC) {
        yogas.add(Yoga(
          shloka: 'ಕುಬ್ಬಃ ಸ್ವರ್ಕ್ಷೆ ಶಶಿನಿ ತನುಗೇ ಮಂದಮಾಹೇಯದೃಷ್ಟೇ',
          name: 'ಕುಬ್ಜ ಯೋಗ (೧೮)',
          description: 'ಕಟಕ ಲಗ್ನ + ಚಂದ್ರ ಲಗ್ನದಲ್ಲಿ + ಶನಿ ಕುಜ ದೃಷ್ಟಿ',
          result: 'ಬೆನ್ನು ಬಗ್ಗಿರುವ ಶಿಶು',
          rashi: 3, planets: ['ಚಂದ್ರ', 'ಶನಿ', 'ಕುಜ'],
        ));
      }
    }
    if (lagRashi == 11) {
      final sAP = (satR2 + 6) % 12 == 11 || (satR2 + 2) % 12 == 11 || (satR2 + 9) % 12 == 11;
      final mAP = (marsR + 6) % 12 == 11 || (marsR + 3) % 12 == 11 || (marsR + 7) % 12 == 11;
      final moAP = (moonR2 + 6) % 12 == 11;
      if (sAP && mAP && moAP) {
        yogas.add(Yoga(
          shloka: 'ಪಂಗುರ್ಮೀನೇ ಯಮಶಶಿಕುಜೈರ್ವೀಕ್ಷಿತೇ ಲಗ್ನಸಂಸ್ಥೆ',
          name: 'ಪಂಗು ಯೋಗ (೧೮)',
          description: 'ಮೀನ ಲಗ್ನ + ಶನಿ, ಚಂದ್ರ, ಕುಜ ದೃಷ್ಟಿ',
          result: 'ಕುಂಟ ಶಿಶು',
          rashi: 11, planets: ['ಶನಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
        ));
      }
    }

    // ═══ Nisheka Shloka 19: Dwarf & Missing limbs ═══
    if (lagRashi == 9 || lagRashi == 10) { // Makara (Capricorn) or Kumbha (Aquarius)
      final sACap = satR2 == 9 || (satR2 + 6) % 12 == 9 || (satR2 + 2) % 12 == 9 || (satR2 + 9) % 12 == 9;
      final moACap = moonR2 == 9 || (moonR2 + 6) % 12 == 9;
      final suACap = sunR == 9 || (sunR + 6) % 12 == 9;
      if (sACap && moACap && suACap) {
        yogas.add(Yoga(
          shloka: 'ಸೌರಶಶಾಂಕದಿವಾಕರದೃಷ್ಟೇ ವಾಮನಕೋ ಮಕರಾಂತ್ಯವಿಲಗ್ನ',
          name: 'ವಾಮನ ಯೋಗ (೧೯)',
          description: 'ಮಕರ ಲಗ್ನ + ಶನಿ, ಚಂದ್ರ, ರವಿ ದೃಷ್ಟಿ/ಸ್ಥಿತಿ',
          result: 'ಕುಳ್ಳ ಶಿಶು',
          rashi: 9, planets: ['ಶನಿ', 'ಚಂದ್ರ', 'ರವಿ'],
        ));
      }
    }
    final malIn159 = <String>[];
    for (final e in malLons.entries) {
      final hFL = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (hFL == 1) malIn159.add('${_knPlanets[e.key]} 1ನೇ (ತಲೆ)');
      if (hFL == 5) malIn159.add('${_knPlanets[e.key]} 5ನೇ (ಕೈಗಳು)');
      if (hFL == 9) malIn159.add('${_knPlanets[e.key]} 9ನೇ (ಕಾಲುಗಳು)');
    }
    if (malIn159.length >= 2) {
      yogas.add(Yoga(
        shloka: 'ಧೀನವಮೋದಯಗೈಶ್ಚ ದೃಗಾಣೈ: ಪಾಪಯುತೈರಭುಜಾಂಘಿಶಿರಾಃ ಸ್ಯಾತ್',
        name: 'ಅಂಗಹೀನ ಯೋಗ (೧೯)',
        description: 'ಪಾಪರು 1/5/9:\n${malIn159.join("\n")}',
        result: 'ಅಂಗಹೀನ ಶಿಶು',
        rashi: lagRashi,
        planets: malIn159.map((s) => s.split(' ').first).toList(),
      ));
    }

    // ═══ Nisheka Shloka 20: Blindness & Eye defects ═══
    if (lagRashi == 4 && sunR == 4 && moonR2 == 4) {
      final mAL = (marsR + 6) % 12 == 4 || (marsR + 3) % 12 == 4 || (marsR + 7) % 12 == 4;
      final sAL = (satR2 + 6) % 12 == 4 || (satR2 + 2) % 12 == 4 || (satR2 + 9) % 12 == 4;
      if (mAL && sAL) {
        yogas.add(Yoga(
          shloka: 'ರವಿಶಶಿಯುತೇ ಸಿಂಹೇ ಲಗ್ನ ಕುಜಾರ್ಕಿನಿರೀಕ್ಷಿತೇ ನಯನರಹಿತಃ',
          name: 'ಅಂಧತ್ವ ಯೋಗ (೨೦)',
          description: 'ಸಿಂಹ ಲಗ್ನ + ರವಿ,ಚಂದ್ರ ಲಗ್ನದಲ್ಲಿ + ಕುಜ,ಶನಿ ದೃಷ್ಟಿ',
          result: 'ಶಿಶು ಕುರುಡ',
          rashi: 4, planets: ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ', 'ಶನಿ'],
        ));
      }
    }
    final moIn12 = ((moonR2 - lagRashi) % 12) + 1 == 12;
    final suIn12 = ((sunR - lagRashi) % 12) + 1 == 12;
    if (moIn12 || suIn12) {
      yogas.add(Yoga(
        shloka: 'ವ್ಯಯಗೃಹಗತಶ್ಚಂದ್ರೋ ವಾಮಂ ಒನಸ್ತ್ರಪರಂ ರವಿ',
        name: 'ನೇತ್ರ ದೋಷ ಯೋಗ (೨೦)',
        description: '${moIn12 ? "ಚಂದ್ರ 12ನೇ → ಎಡಗಣ್ಣು" : ""}${(moIn12 && suIn12) ? "\n" : ""}${suIn12 ? "ರವಿ 12ನೇ → ಬಲಗಣ್ಣು" : ""}',
        result: '${moIn12 ? "ಎಡ" : ""}${(moIn12 && suIn12) ? "/" : ""}${suIn12 ? "ಬಲ" : ""}ಗಣ್ಣು ದೋಷ',
        rashi: lagRashi,
        planets: [if (moIn12) 'ಚಂದ್ರ', if (suIn12) 'ರವಿ'],
      ));
    }

    // ═══ Nisheka Shloka 21: Birth timing from Dwadashamsha ═══
    final moonD12 = ((moonLon % 30) / 2.5).floor();
    final d12Rashi = (moonR2 + moonD12) % 12;
    yogas.add(Yoga(
      shloka: 'ತತ್ಕಾಲ ಇಂದುಸಹಿತೋ ದ್ವಿರಸಾಂಶಕೋ ಯಸ್ತತ್ತುಲ್ಯರಾಶಿಸಹಿತೇ ಪುರತಃ ಶಶಾಂಕೇ',
      name: 'ಜನನ ಕಾಲ ನಿರ್ಣಯ (೨೧)',
      description: 'ಗರ್ಭಧಾರಣೆ ಚಂದ್ರ ದ್ವಾದಶಾಂಶ: ${_rashiNames[d12Rashi]}\nಚಂದ್ರ ಈ ರಾಶಿಗೆ ಬಂದಾಗ ಜನನ',
      result: 'ಜನನ: ಚಂದ್ರ ${_rashiNames[d12Rashi]} ರಾಶಿಯಲ್ಲಿರುವಾಗ',
      rashi: d12Rashi, planets: ['ಚಂದ್ರ'],
    ));

    // ═══ Nisheka Shloka 22: Delayed birth ═══
    final satNav22 = _d9Rashi(sat);
    final satIn7th = ((satR2 - lagRashi) % 12) + 1 == 7;
    if (satNav22 == lagRashi && satIn7th) {
      yogas.add(Yoga(
        shloka: 'ಉದಯತಿ ಮೃದುಭಾಂಶೇ ಸಪ್ತಮಸೇ ಚ ಮಂದೇ ಯದಿ ಭವತಿ ನಿಷೇಕಃ ಸೂತಿರಬತ್ರಯೇಣ',
        name: 'ವಿಳಂಬ ಜನನ ಯೋಗ - ಶನಿ (೨೨)',
        description: 'ಶನಿ ನವಾಂಶ ಲಗ್ನವಾಗಿದ್ದು ಶನಿ 7ನೇ ಮನೆಯಲ್ಲಿ',
        result: 'ಮೂರು ವರ್ಷಗಳ ನಂತರ ಜನನ',
        rashi: lagRashi, planets: ['ಶನಿ'],
      ));
    }
    final moonNav22 = _d9Rashi(moonLon);
    final moonIn7th = ((moonR2 - lagRashi) % 12) + 1 == 7;
    if (moonNav22 == lagRashi && moonIn7th) {
      yogas.add(Yoga(
        shloka: 'ಶಶಿನಿ ತು ವಿಧಿರೇವಂ ದ್ವಾದಶಾದ್ದೇ ಪ್ರಕುರ್ಯಾತ್',
        name: 'ವಿಳಂಬ ಜನನ ಯೋಗ - ಚಂದ್ರ (೨೨)',
        description: 'ಚಂದ್ರ ನವಾಂಶ ಲಗ್ನವಾಗಿದ್ದು ಚಂದ್ರ 7ನೇ ಮನೆಯಲ್ಲಿ',
        result: 'ಹನ್ನೆರಡು ವರ್ಷಗಳ ನಂತರ ಜನನ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══════════════════════════════════════════════════
    // Chapter 5: ಜನ್ಮಕಾಲಲಕ್ಷಣಾಧ್ಯಾಯ (Birth-time indicators)
    // ═══════════════════════════════════════════════════

    // ═══ JK Shloka 1: Father absent at birth ═══
    final jk1MoonAspLag = (moonR2 + 6) % 12 == lagRashi;
    final jk1IsChara = lagRashi == 0 || lagRashi == 3 || lagRashi == 6 || lagRashi == 9;
    final jk1SunH = ((sunR - lagRashi) % 12) + 1;
    final jk1SatInLag = satR2 == lagRashi;
    final jk1MarsIn7 = ((marsR - lagRashi) % 12) + 1 == 7;
    final jk1MerR = _rashiOf(mer);
    final jk1VenR = _rashiOf(ven);
    final jk1MoonBtw = (moonR2 > jk1MerR && moonR2 < jk1VenR) || (moonR2 > jk1VenR && moonR2 < jk1MerR);
    if (!jk1MoonAspLag || (jk1SatInLag && jk1MarsIn7) || jk1MoonBtw) {
      final reasons = <String>[];
      if (!jk1MoonAspLag) reasons.add('ಚಂದ್ರ ಲಗ್ನ ದೃಷ್ಟಿ ಇಲ್ಲ');
      if (jk1IsChara) reasons.add('ಚರ ಲಗ್ನ → ತಂದೆ ವಿದೇಶ');
      if (jk1SunH >= 8 && jk1SunH <= 12) reasons.add('ರವಿ ${jk1SunH}ನೇ ಮನೆ → ತಂದೆ ಊರಿನಲ್ಲಿ ಬೇರೆಡೆ');
      if (jk1SatInLag && jk1MarsIn7) reasons.add('ಶನಿ ಲಗ್ನ + ಕುಜ 7ನೇ');
      if (jk1MoonBtw) reasons.add('ಚಂದ್ರ ಬುಧ-ಶುಕ್ರರ ಮಧ್ಯೆ');
      yogas.add(Yoga(
        shloka: 'ಪಿತುರ್ಜಾತಃ ಪರೋಕ್ಷಸ್ಯ ಲಗ್ನಮಿಂದಾವಪಶ್ಯತಿ',
        name: 'ಪಿತೃ ಪರೋಕ್ಷ ಯೋಗ (ಜಕ ೧)',
        description: reasons.join('\n'),
        result: 'ತಂದೆ ಪರೋಕ್ಷದಲ್ಲಿರುವಾಗ ಜನನ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ', 'ರವಿ'],
      ));
    }

    // ═══ JK Shloka 2: Born with snake ═══
    final jk2ScorpDrek = lagRashi == 7 || moonR2 == 7;
    final jk2BenIn2or11 = <String>[];
    for (final e in allPLons.entries) {
      if ({'Jupiter','Venus','Mercury','Moon'}.contains(e.key)) {
        final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        if (h == 2 || h == 11) jk2BenIn2or11.add(_knPlanets[e.key]!);
      }
    }
    if (jk2ScorpDrek && jk2BenIn2or11.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ಶಶಾಂಕೇ ಪಾಪಲಗ್ನ ವಾ ವೃಶ್ಚಿಕೇಶತ್ರಿಭಾಗಗೇ',
        name: 'ಸರ್ಪ ವೇಷ್ಟಿತ ಯೋಗ (ಜಕ ೨)',
        description: 'ವೃಶ್ಚಿಕ ದ್ರೇಕ್ಕಾಣ + ಶುಭರು 2/11: ${jk2BenIn2or11.join(",")}',
        result: 'ಹಾವಿನೊಂದಿಗೆ ಜನನ',
        rashi: 7, planets: ['ಚಂದ್ರ', ...jk2BenIn2or11],
      ));
    }

    // ═══ JK Shloka 3: Twins in membrane ═══
    final jk3Quad = {0, 1, 4, 9};
    final jk3Dual = {2, 5, 8, 11};
    int jk3StrongDual = 0;
    for (final e in allPLons.entries) {
      if (e.key == 'Sun') continue;
      if (jk3Dual.contains(_rashiOf(e.value)) && isStrong(e.key)) jk3StrongDual++;
    }
    if (jk3Quad.contains(sunR) && jk3StrongDual >= 2) {
      yogas.add(Yoga(
        shloka: 'ಚತುಷ್ಪದಗತೇ ಭಾನೌ ಶೇಪೈರ್ವೀಯ್ರಸಮನ್ವಿತೈಃ',
        name: 'ಪೊರೆ ಅವಳಿ ಯೋಗ (ಜಕ ೩)',
        description: 'ರವಿ ಚತುಷ್ಪಾದ ರಾಶಿ (${_rashiNames[sunR]}) + $jk3StrongDual ಬಲಶಾಲಿರು ದ್ವಿಸ್ವಭಾವದಲ್ಲಿ',
        result: 'ಪೊರೆಯಿಂದ ಸುತ್ತಲ್ಪಟ್ಟ ಅವಳಿ',
        rashi: sunR, planets: ['ರವಿ'],
      ));
    }

    // ═══ JK Shloka 4: Umbilical cord wrapped ═══
    if ({0, 1, 4}.contains(lagRashi)) {
      if (marsR == lagRashi || satR2 == lagRashi) {
        yogas.add(Yoga(
          shloka: 'ಛಾಗಸಿಂಹವೃಷೇ ಲಗ್ನ ತತ್ ಸೌರೇsಥವಾ ಕುಜೇ',
          name: 'ನಾಲ ವೇಷ್ಟಿತ ಯೋಗ (ಜಕ ೪)',
          description: '${_rashiNames[lagRashi]} ಲಗ್ನ + ${marsR == lagRashi ? "ಕುಜ" : "ಶನಿ"} ಲಗ್ನದಲ್ಲಿ',
          result: 'ಕರುಳಬಳ್ಳಿ ಸುತ್ತಿಕೊಂಡ ಶಿಶು',
          rashi: lagRashi, planets: [marsR == lagRashi ? 'ಕುಜ' : 'ಶನಿ'],
        ));
      }
    }

    // ═══ JK Shloka 5: Illegitimate birth ═══
    final jk5JupR = _rashiOf(jup);
    final jk5JupAspL = (jk5JupR + 6) % 12 == lagRashi || (jk5JupR + 4) % 12 == lagRashi || (jk5JupR + 8) % 12 == lagRashi;
    final jk5JupAspM = (jk5JupR + 6) % 12 == moonR2 || (jk5JupR + 4) % 12 == moonR2 || (jk5JupR + 8) % 12 == moonR2;
    final jk5MoonSun = moonR2 == sunR;
    final jk5MalSun = jk5MoonSun && malLons.entries.any((e) => _rashiOf(e.value) == moonR2);
    if ((!jk5JupAspL && !jk5JupAspM) || jk5MalSun) {
      yogas.add(Yoga(
        shloka: 'ನ ಲಗ್ನಮಿಂದುಂ ಚ ಗುರುರ್ನಿರೀಕ್ಷತೇ',
        name: 'ಅನ್ಯಜಾತ ಯೋಗ (ಜಕ ೫)',
        description: '${!jk5JupAspL && !jk5JupAspM ? "ಗುರು ಲಗ್ನ/ಚಂದ್ರ ದೃಷ್ಟಿ ಇಲ್ಲ" : ""}${jk5MalSun ? "\nಚಂದ್ರ+ಪಾಪ+ರವಿ ಒಟ್ಟಿಗೆ" : ""}',
        result: 'ಅನ್ಯ ಪುರುಷನ ಸಂತಾನ',
        rashi: lagRashi, planets: ['ಗುರು', 'ಚಂದ್ರ', 'ರವಿ'],
      ));
    }

    // ═══ JK Shloka 6: Father in bondage ═══
    final jk6Mal579 = <String>[];
    for (final e in malLons.entries) {
      final hFS = ((_rashiOf(e.value) - sunR) % 12) + 1;
      if (hFS == 5 || hFS == 7 || hFS == 9) jk6Mal579.add(_knPlanets[e.key]!);
    }
    if (jk6Mal579.isNotEmpty) {
      final jk6R = _rashiOf(malLons.values.first);
      final jk6Place = (jk6R == 0 || jk6R == 3 || jk6R == 6 || jk6R == 9) ? 'ದಾರಿಯಲ್ಲಿ' : (jk6R == 1 || jk6R == 4 || jk6R == 7 || jk6R == 10) ? 'ತನ್ನ ಊರಿನಲ್ಲಿ' : 'ವಿದೇಶದಲ್ಲಿ';
      yogas.add(Yoga(
        shloka: 'ಕ್ರೂರರ್ಕ್ಷಗತಾವಶೋಭನೌ ಸೂರ್ಯಾದ್ ದ್ಯೋನನವಾತ್ಮಜಸ್ಥಿತೌ',
        name: 'ಪಿತೃ ಬಂಧನ ಯೋಗ (ಜಕ ೬)',
        description: 'ಪಾಪರು ರವಿಯಿಂದ 5/7/9: ${jk6Mal579.join(",")}\nಸ್ಥಳ: $jk6Place',
        result: 'ತಂದೆ $jk6Place ಬಂಧನದಲ್ಲಿ',
        rashi: sunR, planets: ['ರವಿ', ...jk6Mal579],
      ));
    }

    // ═══ JK Shloka 7: Birth on ship ═══
    final jk7Water = {3, 7, 11};
    final jk7Full = (moonLon - sun).abs() > 150;
    final jk7MoonCan = moonR2 == 3;
    final jk7MerLag = jk1MerR == lagRashi;
    final jk7LagW = jk7Water.contains(lagRashi);
    final jk7MoonIn7 = ((moonR2 - lagRashi) % 12) + 1 == 7;
    if ((jk7Full && jk7MoonCan && jk7MerLag) || (jk7LagW && jk7MoonIn7)) {
      yogas.add(Yoga(
        shloka: 'ಪೂರ್ಣೇ ಶಶಿನಿ ಸ್ವರಾಶಿಗೇ ಸೌಮ್ಯ ಲಗ್ನಗತೇ ಶುಭೇ ಸುಖೇ',
        name: 'ಹಡಗು ಜನನ ಯೋಗ (ಜಕ ೭)',
        description: '${jk7Full && jk7MoonCan ? "ಪೂರ್ಣ ಚಂದ್ರ ಕಟಕದಲ್ಲಿ" : "ಜಲ ಲಗ್ನ + ಚಂದ್ರ 7ನೇ"}',
        result: 'ಹಡಗಿನಲ್ಲಿ ಜನನ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ', 'ಬುಧ'],
      ));
    }

    // ═══ JK Shloka 8: Birth near water ═══
    final jk8MoonInLag = moonR2 == lagRashi;
    final jk8MoonH = ((moonR2 - lagRashi) % 12) + 1;
    if ((jk7LagW && jk8MoonInLag) || (jk7Full && jk7LagW) || jk8MoonH == 10 || jk8MoonH == 4 || jk8MoonH == 1) {
      yogas.add(Yoga(
        shloka: 'ಆಪ್ಪೋದಯಮಾನ್ಯಗಃ ಶಶೀ ಸಂಪೂರ್ಣ: ಸಮವೇಕ್ಷತೇಥವಾ',
        name: 'ಜಲ ಸಮೀಪ ಜನನ ಯೋಗ (ಜಕ ೮)',
        description: 'ಚಂದ್ರ ${jk8MoonH}ನೇ ಮನೆ${jk7LagW ? " + ಜಲ ಲಗ್ನ" : ""}',
        result: 'ನೀರಿನ ಸಮೀಪ ಜನನ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ JK Shloka 9: Birth in hidden/pit ═══
    final jk9Sat12L = ((satR2 - lagRashi) % 12) + 1 == 12;
    final jk9Sat12M = ((satR2 - moonR2) % 12) + 1 == 12;
    final jk9SatSC = (lagRashi == 7 || lagRashi == 3) && satR2 == lagRashi;
    if ((jk9Sat12L && jk9Sat12M) || jk9SatSC) {
      yogas.add(Yoga(
        shloka: 'ಉದಯೋಡುಪಯೋರ್ವ್ಯಯಸ್ಥಿತೇ ಗುಪ್ತಾಂ ಪಾಪನಿರೀಕ್ಷಿತೇ ಯಮೇ',
        name: 'ಗುಪ್ತ/ಗುಂಡಿ ಜನನ ಯೋಗ (ಜಕ ೯)',
        description: '${jk9Sat12L ? "ಶನಿ ಲಗ್ನದಿಂದ 12ನೇ" : "ಶನಿ ${_rashiNames[lagRashi]} ಲಗ್ನದಲ್ಲಿ"}',
        result: 'ಗುಪ್ತ ಪ್ರದೇಶ/ಗುಂಡಿಯಲ್ಲಿ ಜನನ',
        rashi: lagRashi, planets: ['ಶನಿ', 'ಚಂದ್ರ'],
      ));
    }

    // ═══ JK Shloka 10: Birth place by aspect on water lagna ═══
    if (jk7LagW && satR2 == lagRashi) {
      final jk10MerAsp = (jk1MerR + 6) % 12 == lagRashi;
      final jk10SunAsp = (sunR + 6) % 12 == lagRashi;
      final jk10MoonAsp = (moonR2 + 6) % 12 == lagRashi;
      final jk10Place = jk10MerAsp ? 'ಆಟದ ಮೈದಾನ' : jk10SunAsp ? 'ದೇವಸ್ಥಾನ' : jk10MoonAsp ? 'ಬಂಜರು ಭೂಮಿ' : '';
      if (jk10Place.isNotEmpty) {
        yogas.add(Yoga(
          shloka: 'ಮಂದೇsಬ್ಬಗತೇ ವಿಲಗ್ನಗೇ ಬುಧಸೂರ್ಯೇಂದುನಿರೀಕ್ಷಿತೇ ಕ್ರಮಾತ್',
          name: 'ಜನನ ಸ್ಥಳ ಯೋಗ (ಜಕ ೧೦)',
          description: 'ಜಲ ಲಗ್ನ + ಶನಿ + ${jk10MerAsp ? "ಬುಧ" : jk10SunAsp ? "ರವಿ" : "ಚಂದ್ರ"} ದೃಷ್ಟಿ',
          result: '$jk10Place ದಲ್ಲಿ ಜನನ',
          rashi: lagRashi, planets: ['ಶನಿ'],
        ));
      }
    }

    // ═══ JK Shloka 11: Birth place by planet aspecting human lagna ═══
    final jk11Human = {2, 5, 6, 8, 11};
    if (jk11Human.contains(lagRashi)) {
      final jk11Asp = <String, String>{};
      if ((marsR + 6) % 12 == lagRashi || (marsR + 3) % 12 == lagRashi || (marsR + 7) % 12 == lagRashi) jk11Asp['ಕುಜ'] = 'ಸ್ಮಶಾನ';
      if ((jk1VenR + 6) % 12 == lagRashi) jk11Asp['ಶುಕ್ರ'] = 'ರಮ್ಯ ಸ್ಥಳ';
      if ((moonR2 + 6) % 12 == lagRashi) jk11Asp['ಚಂದ್ರ'] = 'ರಮ್ಯ ಸ್ಥಳ';
      if ((jk5JupR + 6) % 12 == lagRashi || (jk5JupR + 4) % 12 == lagRashi || (jk5JupR + 8) % 12 == lagRashi) jk11Asp['ಗುರು'] = 'ಯಾಗಶಾಲೆ';
      if ((sunR + 6) % 12 == lagRashi) jk11Asp['ರವಿ'] = 'ರಾಜಮಂದಿರ';
      if ((jk1MerR + 6) % 12 == lagRashi) jk11Asp['ಬುಧ'] = 'ಶಿಲ್ಪಾಲಯ';
      if (jk11Asp.isNotEmpty) {
        yogas.add(Yoga(
          shloka: 'ನೃಲಗ್ನಗಂ ಪ್ರೇಕ್ಷ್ಯ ಕುಜಃ ಸ್ಮಶಾನೇ ರಮ್ಯ ಸಿತೇಂದೂ ಗುರುರಗ್ನಿಹೋತೇ',
          name: 'ಜನನ ಸ್ಥಳ ಯೋಗ (ಜಕ ೧೧)',
          description: jk11Asp.entries.map((e) => '${e.key} → ${e.value}').join('\n'),
          result: '${jk11Asp.values.first}ದಲ್ಲಿ ಜನನ',
          rashi: lagRashi, planets: jk11Asp.keys.toList(),
        ));
      }
    }

    // ═══ JK Shloka 12: Birth place from navamsha ═══
    final jk12Nav = _d9Rashi(lag);
    final jk12Chara = jk12Nav == 0 || jk12Nav == 3 || jk12Nav == 6 || jk12Nav == 9;
    final jk12Sthira = jk12Nav == 1 || jk12Nav == 4 || jk12Nav == 7 || jk12Nav == 10;
    final jk12Own = jk12Nav == lagRashi;
    final jk12Place = jk12Own ? 'ತನ್ನ ಮನೆ' : jk12Chara ? 'ದಾರಿ' : jk12Sthira ? 'ಮನೆ' : 'ಅನ್ಯ ಸ್ಥಳ';
    yogas.add(Yoga(
      shloka: 'ರಾಶ್ಯಂಶಸಮಾನಗೋಚರೇ ಮಾರ್ಗೇ ಜನ್ಮ ಚರೇ ಸ್ಥಿರೇ ಗೃಹೇ',
      name: 'ಜನನ ಸ್ಥಳ ನವಾಂಶ ಯೋಗ (ಜಕ ೧೨)',
      description: 'ಲಗ್ನ ನವಾಂಶ: ${_rashiNames[jk12Nav]} (${jk12Chara ? "ಚರ" : jk12Sthira ? "ಸ್ಥಿರ" : "ದ್ವಿಸ್ವಭಾವ"})',
      result: '${jk12Place}ಯಲ್ಲಿ ಜನನ',
      rashi: lagRashi, planets: [],
    ));

    // ═══ JK Shloka 13: Mother abandons child ═══
    final jk13SunInTri = ((sunR - lagRashi) % 12) + 1;
    final jk13MarsInTri = ((marsR - lagRashi) % 12) + 1;
    final jk13MoonInLag = moonR2 == lagRashi;
    final jk13SunMarsInTrik = (jk13SunInTri == 5 || jk13SunInTri == 9) && (jk13MarsInTri == 5 || jk13MarsInTri == 9);
    if (jk13SunMarsInTrik && jk13MoonInLag) {
      final jk13JupAsp = (jk5JupR + 6) % 12 == lagRashi || (jk5JupR + 4) % 12 == lagRashi || (jk5JupR + 8) % 12 == lagRashi;
      yogas.add(Yoga(
        shloka: 'ಆರಾರ್ಕಜಯೋಸ್ತ್ರಿಕೋಣಗೇ ಚಂದ್ರೇsರ್ಕೇ ಚ ವಿಸೃಜ್ಯತೇsಂಬಯಾ',
        name: 'ಮಾತೃ ತ್ಯಾಗ ಯೋಗ (ಜಕ ೧೩)',
        description: 'ರವಿ,ಕುಜ ತ್ರಿಕೋಣ + ಚಂದ್ರ ಲಗ್ನ${jk13JupAsp ? "\nಗುರು ದೃಷ್ಟಿ → ದೀರ್ಘಾಯು, ಸುಖ" : ""}',
        result: jk13JupAsp ? 'ತಾಯಿ ತ್ಯಜಿಸಿದರೂ ದೀರ್ಘಾಯು' : 'ತಾಯಿ ತ್ಯಜಿಸುತ್ತಾಳೆ',
        rashi: lagRashi, planets: ['ರವಿ', 'ಕುಜ', 'ಚಂದ್ರ'],
      ));
    }

    // ═══ JK Shloka 14: Abandoned & perishes / survives ═══
    final jk14MoonLag = moonR2 == lagRashi;
    final jk14MarsIn7 = ((marsR - lagRashi) % 12) + 1 == 7;
    final jk14MarsSatLag = marsR == lagRashi && satR2 == lagRashi;
    bool jk14MalAsp = false;
    for (final e in malLons.entries) {
      if ((_rashiOf(e.value) + 6) % 12 == lagRashi) jk14MalAsp = true;
    }
    if (jk14MoonLag && jk14MalAsp && (jk14MarsIn7 || jk14MarsSatLag)) {
      bool jk14BenAsp = false;
      for (final e in allPLons.entries) {
        if ({'Jupiter','Venus','Mercury'}.contains(e.key) && (_rashiOf(e.value) + 6) % 12 == lagRashi) jk14BenAsp = true;
      }
      yogas.add(Yoga(
        shloka: 'ಪಾಪೇಕ್ಷಿತೇ ತುಹಿನಗಾವುದಯೇ ಕುಜೇsಸ್ತೇ ತ್ಯಕ್ಕೋ ವಿನಶ್ಯತಿ',
        name: 'ಶಿಶು ತ್ಯಾಗ/ನಾಶ ಯೋಗ (ಜಕ ೧೪)',
        description: 'ಚಂದ್ರ ಲಗ್ನ + ಪಾಪ ದೃಷ್ಟಿ + ${jk14MarsIn7 ? "ಕುಜ 7ನೇ" : "ಕುಜ+ಶನಿ ಲಗ್ನ"}${jk14BenAsp ? "\nಶುಭ ದೃಷ್ಟಿ → ಬೇರೆಯವರ ಕೈ ಸೇರಿ ಬದುಕು" : ""}',
        result: jk14BenAsp ? 'ಬೇರೆಯವರ ಕೈ ಸೇರಿ ಬದುಕು' : 'ತ್ಯಜಿಸಲ್ಪಟ್ಟು ನಾಶ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ', 'ಕುಜ'],
      ));
    }

    // ═══ JK Shloka 15: Birth in deserted place ═══
    bool jk15AnyAspLag = false;
    bool jk15AnyAspMoon = false;
    for (final e in allPLons.entries) {
      if ((_rashiOf(e.value) + 6) % 12 == lagRashi) jk15AnyAspLag = true;
      if ((_rashiOf(e.value) + 6) % 12 == moonR2) jk15AnyAspMoon = true;
    }
    if (!jk15AnyAspLag && !jk15AnyAspMoon) {
      yogas.add(Yoga(
        shloka: 'ಯದಿ ನೈಕಗತೈಸ್ತು ವೀಕ್ಷಿತೌ ಲಗ್ನಂದೂ ವಿಜನೇ ಪ್ರಸೂಯತೇ',
        name: 'ನಿರ್ಜನ ಜನನ ಯೋಗ (ಜಕ ೧೫)',
        description: 'ಲಗ್ನ ಮತ್ತು ಚಂದ್ರರಿಗೆ ಯಾವ ಗ್ರಹದ ದೃಷ್ಟಿಯೂ ಇಲ್ಲ',
        result: 'ನಿರ್ಜನ ಪ್ರದೇಶದಲ್ಲಿ ಜನನ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ JK Shloka 16: Birth in darkness on ground ═══
    final jk16MoonNav = _d9Rashi(moonLon);
    final jk16SatNavRashis = [9, 10]; // Capricorn, Aquarius (Saturn's signs)
    final jk16MoonIn4 = ((moonR2 - lagRashi) % 12) + 1 == 4;
    final jk16SatAspMoon = (satR2 + 6) % 12 == moonR2 || (satR2 + 2) % 12 == moonR2 || (satR2 + 9) % 12 == moonR2;
    final jk16LagWater = jk7Water.contains(lagRashi) && satR2 == lagRashi;
    if ((jk16SatNavRashis.contains(jk16MoonNav) && jk16MoonIn4 && jk16SatAspMoon) || jk16LagWater) {
      yogas.add(Yoga(
        shloka: 'ಮಂದರ್ಕ್ಷಾಂಶೇ ಶಶಿನಿ ಹಿಬುಕೇ ಮಂದದೃಷ್ಟೇsಬ್ಬರೇ ವಾ',
        name: 'ಅಂಧಕಾರ ಜನನ ಯೋಗ (ಜಕ ೧೬)',
        description: '${jk16LagWater ? "ಜಲ ಲಗ್ನ + ಶನಿ" : "ಚಂದ್ರ ಶನಿ ನವಾಂಶ + 4ನೇ ಮನೆ + ಶನಿ ದೃಷ್ಟಿ"}',
        result: 'ಕತ್ತಲೆಯಲ್ಲಿ ನೆಲದ ಮೇಲೆ ಜನನ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ', 'ಶನಿ'],
      ));
    }

    // ═══ JK Shloka 17: Mother's suffering ═══
    final jk17MalIn7 = <String>[];
    final jk17MalIn4 = <String>[];
    for (final e in malLons.entries) {
      final hFM = ((_rashiOf(e.value) - moonR2) % 12) + 1;
      if (hFM == 7) jk17MalIn7.add(_knPlanets[e.key]!);
      if (hFM == 4) jk17MalIn4.add(_knPlanets[e.key]!);
    }
    if (jk17MalIn7.isNotEmpty || jk17MalIn4.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ಪಾಪೈಶ್ಚಂದ್ರಸ್ಮರಸುಖಗತೈಃ ಕೇಶಮಾಹುರ್ಜನನ್ಯಾ:',
        name: 'ಮಾತೃ ಕಷ್ಟ ಯೋಗ (ಜಕ ೧೭)',
        description: '${jk17MalIn7.isNotEmpty ? "ಚಂದ್ರನಿಂದ 7ನೇ: ${jk17MalIn7.join(",")}" : ""}${jk17MalIn4.isNotEmpty ? "\nಚಂದ್ರನಿಂದ 4ನೇ: ${jk17MalIn4.join(",")}" : ""}',
        result: 'ತಾಯಿಗೆ ಹೆರಿಗೆಯಲ್ಲಿ ಕಷ್ಟ',
        rashi: moonR2, planets: ['ಚಂದ್ರ', ...jk17MalIn7, ...jk17MalIn4],
      ));
    }

    // ═══ JK Shloka 18: Lamp & door of delivery room ═══
    final jk18SunRType = (sunR == 0 || sunR == 3 || sunR == 6 || sunR == 9) ? 'ಚರ (ಚಲಿಸುವ)' : (sunR == 1 || sunR == 4 || sunR == 7 || sunR == 10) ? 'ಸ್ಥಿರ' : 'ದ್ವಿಸ್ವಭಾವ';
    final jk18StrongInKendra = <String>[];
    for (final e in allPLons.entries) {
      final hFL = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if ((hFL == 1 || hFL == 4 || hFL == 7 || hFL == 10) && isStrong(e.key)) {
        jk18StrongInKendra.add(_knPlanets[e.key]!);
      }
    }
    yogas.add(Yoga(
      shloka: 'ಸ್ನೇಹಃ ಶಶಾಂಕಾದುದಯಾಚ್ಚ ವರ್ತಿ ದೀಪೋsರ್ಕಯುಕ್ತರ್ಕ್ಷವಶಾಚ್ಚರಾಃ',
      name: 'ಹೆರಿಗೆ ಮನೆ ಲಕ್ಷಣ (ಜಕ ೧೮)',
      description: 'ದೀಪ: $jk18SunRType${jk18StrongInKendra.isNotEmpty ? "\nಬಾಗಿಲು: ${jk18StrongInKendra.join(",")}" : ""}',
      result: 'ದೀಪ $jk18SunRType',
      rashi: lagRashi, planets: [],
    ));

    // ═══ JK Shloka 19: House type from strongest planet ═══
    final jk19HouseMap = <String, String>{
      'Saturn': 'ಹಳೆಯ/ದುರಸ್ತಿ ಮನೆ', 'Mars': 'ಸುಟ್ಟ ಮನೆ', 'Moon': 'ಹೊಸ ಮನೆ',
      'Sun': 'ಮರದ/ಗಟ್ಟಿಯಿಲ್ಲದ ಮನೆ', 'Mercury': 'ಶಿಲ್ಪಕಲೆ ಮನೆ',
      'Venus': 'ಸುಂದರ/ಚಿತ್ರಗಳ ಹೊಸ ಮನೆ', 'Jupiter': 'ಗಟ್ಟಿಯಾದ ಮನೆ',
    };
    String jk19Strongest = 'Jupiter';
    for (final e in allPLons.entries) {
      if (isStrong(e.key)) { jk19Strongest = e.key; break; }
    }
    yogas.add(Yoga(
      shloka: 'ಜೀರ್ಣಂ ಸಂಸ್ಕೃತಮರ್ಕಜೇ ಕ್ಷಿತಿಸುತೇ ದಗ್ಧಂ ನವಂ ಶೀತಗೌ',
      name: 'ಹೆರಿಗೆ ಮನೆ ಸ್ವರೂಪ (ಜಕ ೧೯)',
      description: 'ಬಲಶಾಲಿ: ${_knPlanets[jk19Strongest]} → ${jk19HouseMap[jk19Strongest]}',
      result: '${jk19HouseMap[jk19Strongest]}',
      rashi: lagRashi, planets: [_knPlanets[jk19Strongest]!],
    ));

    // ═══ JK Shloka 20: Direction of delivery room ═══
    final jk20DirMap = <int, String>{
      0: 'ಪೂರ್ವ', 3: 'ಪೂರ್ವ', 6: 'ಪೂರ್ವ', 7: 'ಪೂರ್ವ', 10: 'ಪೂರ್ವ',
      2: 'ಉತ್ತರ', 5: 'ಉತ್ತರ', 8: 'ಉತ್ತರ', 11: 'ಉತ್ತರ',
      1: 'ಪಶ್ಚಿಮ',
      4: 'ದಕ್ಷಿಣ', 9: 'ದಕ್ಷಿಣ',
    };
    yogas.add(Yoga(
      shloka: 'ಮೇಷಕುಲೀರತುಲಾಲಿಘಟೈ: ಪ್ರಾಗುತ್ತರತೋ ಗುರುಸೌಮ್ಯಗೃಹೈಶ್ಚ',
      name: 'ಹೆರಿಗೆ ಕೋಣೆ ದಿಕ್ಕು (ಜಕ ೨೦)',
      description: '${_rashiNames[lagRashi]} ಲಗ್ನ → ${jk20DirMap[lagRashi] ?? "ಪೂರ್ವ"} ದಿಕ್ಕು',
      result: '${jk20DirMap[lagRashi] ?? "ಪೂರ್ವ"} ದಿಕ್ಕಿನಲ್ಲಿ',
      rashi: lagRashi, planets: [],
    ));

    // ═══ JK Shloka 21: Bed direction ═══
    final jk21H6 = ((lagRashi + 5) % 12);
    final jk21H8 = ((lagRashi + 7) % 12);
    final jk21H9 = ((lagRashi + 8) % 12);
    final jk21H12 = ((lagRashi + 11) % 12);
    yogas.add(Yoga(
      shloka: 'ಪ್ರಾಚ್ಯಾದಿಗೃಹೇ ಕ್ರಿಯಾದಯೋ ಕೋಣಗತಾ ದ್ವಿಮೂರ್ತಯಃ',
      name: 'ಹಾಸಿಗೆ ಪಾದ ಯೋಗ (ಜಕ ೨೧)',
      description: 'ಪಾದ ದಿಕ್ಕು: ${_rashiNames[jk21H6]},${_rashiNames[jk21H8]},${_rashiNames[jk21H9]},${_rashiNames[jk21H12]}',
      result: 'ಹಾಸಿಗೆ: ${jk20DirMap[jk21H6] ?? "ಪೂರ್ವ"} ಪಾದ',
      rashi: lagRashi, planets: [],
    ));

    // ═══ JK Shloka 22: Attendants at birth ═══
    int jk22Count = 0;
    final jk22Visible = <String>[];
    final jk22Hidden = <String>[];
    for (final e in allPLons.entries) {
      final eR = _rashiOf(e.value);
      final fromLag = (eR - lagRashi) % 12;
      final fromMoon = (eR - moonR2) % 12;
      if (fromLag > 0 && fromLag < (moonR2 - lagRashi) % 12 || fromMoon > 0 && fromMoon < (lagRashi - moonR2) % 12) {
        jk22Count++;
        final hFL = (eR - lagRashi) % 12;
        if (hFL >= 1 && hFL <= 6) {
          jk22Visible.add(_knPlanets[e.key]!);
        } else {
          jk22Hidden.add(_knPlanets[e.key]!);
        }
      }
    }
    yogas.add(Yoga(
      shloka: 'ಚಂದ್ರಲಗ್ನಾಂತರಗತೈಗ್ರ್ರಹೈಃ ಸ್ಯುರುಪಸೂತಿಕಾಃ',
      name: 'ಉಪಸೂತಿಕಾ ಯೋಗ (ಜಕ ೨೨)',
      description: '$jk22Count ಹೆಂಗಸರು${jk22Visible.isNotEmpty ? "\nಹೊರಗೆ: ${jk22Visible.join(",")}" : ""}${jk22Hidden.isNotEmpty ? "\nಒಳಗೆ: ${jk22Hidden.join(",")}" : ""}',
      result: '$jk22Count ಹೆಂಗಸರು ಹೆರಿಗೆ ಕೋಣೆಯಲ್ಲಿ',
      rashi: lagRashi, planets: [],
    ));

    // ═══ JK Shloka 23: Body & color of child ═══
    final jk23LagNavLord = rashiLords[_d9Rashi(lag)];
    final jk23MoonNavLord = rashiLords[_d9Rashi(moonLon)];
    final jk23ColorMap = <String, String>{
      'Sun': 'ಕೆಂಪು', 'Moon': 'ಬಿಳಿ', 'Mars': 'ಕೆಂಪು', 'Mercury': 'ಹಸಿರು',
      'Jupiter': 'ಹೊಂಬಣ್ಣ', 'Venus': 'ಬಿಳಿ/ಹೊಳೆಯುವ', 'Saturn': 'ಕಪ್ಪು',
    };
    yogas.add(Yoga(
      shloka: 'ಲಗ್ನನವಾಂಶಪತುಲ್ಯತನುಸ್ಸಾದ್ವೀರ್ಯಯುತಗ್ರಹತುಲ್ಯತನುರ್ವಾ',
      name: 'ಶಿಶು ಶರೀರ/ಬಣ್ಣ (ಜಕ ೨೩)',
      description: 'ಶರೀರ: ${_knPlanets[jk23LagNavLord]} ರೀತಿ\nಬಣ್ಣ: ${_knPlanets[jk23MoonNavLord]} → ${jk23ColorMap[jk23MoonNavLord] ?? ""}',
      result: '${jk23ColorMap[jk23MoonNavLord] ?? ""} ಬಣ್ಣದ ಶಿಶು',
      rashi: lagRashi, planets: [_knPlanets[jk23LagNavLord]!, _knPlanets[jk23MoonNavLord]!],
    ));

    // ═══ JK Shloka 24: Body parts mapping (informational) ═══
    yogas.add(Yoga(
      shloka: 'ಕಂ ದೃಕ್ಛೇತ್ರನಸಾಕಪೋಲಹನವೋ ವಸ್ತ್ರಂ ಚ ಹೋರಾದಯ',
      name: 'ದೇಹಾಂಗ ರಾಶಿ ಮ್ಯಾಪ್ (ಜಕ ೨೪)',
      description: '1-ತಲೆ, 2-ಕಣ್ಣು, 3-ಕಿವಿ, 4-ಮೂಗು, 5-ಕೆನ್ನೆ, 6-ದವಡೆ\n7-ಬಾಯಿ, 8-ಕುತ್ತಿಗೆ, 9-ಭುಜ, 10-ತೋಳು, 11-ಪಾರ್ಶ್ವ, 12-ಎದೆ',
      result: 'ದೇಹಾಂಗ ರಾಶಿ ಸಂಬಂಧ',
      rashi: lagRashi, planets: [],
    ));

    // ═══ JK Shloka 25: Wound or mole marks ═══
    for (int drek = 0; drek < 3; drek++) {
      final drekR = (lagRashi + drek * 4) % 12;
      for (final e in allPLons.entries) {
        if (_rashiOf(e.value) == drekR) {
          final isMal = {'Sun','Mars','Saturn','Rahu','Ketu'}.contains(e.key);
          final inOwnNav = _d9Rashi(e.value) == _rashiOf(e.value);
          final isSthira25 = drekR == 1 || drekR == 4 || drekR == 7 || drekR == 10;
          final markType = isMal ? 'ಗಾಯ ಗುರುತು' : 'ಮಚ್ಚೆ';
          final origin = (inOwnNav || isSthira25) ? 'ಹುಟ್ಟಿನಿಂದ' : 'ನಂತರ';
          yogas.add(Yoga(
            shloka: 'ತಸ್ಮಿನ್ ಪಾಪಯುತೇ ವ್ರಣಃ ಶುಭಯುತೇ ದೃಷ್ಟೇ ಲಕ್ಷಾದಿಶೇತ್',
            name: '$markType (ಜಕ ೨೫)',
            description: '${_knPlanets[e.key]} ${_rashiNames[drekR]} ದ್ರೇಕ್ಕಾಣ (${drek + 1}ನೇ)\n$origin ಬಂದ $markType',
            result: '$origin $markType',
            rashi: drekR, planets: [_knPlanets[e.key]!],
          ));
          break;
        }
      }
    }

    // ═══ JK Shloka 26: Cause of wound ═══
    final jk26CauseMap = <String, String>{
      'Saturn': 'ಕಲ್ಲು/ಗಾಳಿ', 'Mars': 'ಬೆಂಕಿ/ಶಸ್ತ್ರ/ವಿಷ', 'Mercury': 'ಮಣ್ಣು',
      'Sun': 'ಕಟ್ಟಿಗೆ/ಪ್ರಾಣಿ', 'Moon': 'ಕೊಂಬು ಪ್ರಾಣಿ/ನೀರು',
    };
    for (final e in malLons.entries) {
      if (jk26CauseMap.containsKey(e.key)) {
        final hFLag = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        if (hFLag == 1 || hFLag == 6) {
          yogas.add(Yoga(
            shloka: 'ಮಂದೇsಸ್ಮಾನಿಲಜೋsಗ್ನಿಶಸ್ತ್ರವಿಷಜೋ ಭೌಮೇ ಬುಧೇ ಭೂಭವಃ',
            name: 'ಗಾಯ ಕಾರಣ (ಜಕ ೨೬)',
            description: '${_knPlanets[e.key]} ${hFLag}ನೇ ಮನೆ → ${jk26CauseMap[e.key]}',
            result: '${jk26CauseMap[e.key]}ದಿಂದ ಗಾಯ',
            rashi: _rashiOf(e.value), planets: [_knPlanets[e.key]!],
          ));
        }
      }
    }

    // ═══ JK Shloka 27: Multiple marks when 3+ planets with Mercury ═══
    final jk27MerR = _rashiOf(mer);
    int jk27WithMer = 0;
    for (final e in allPLons.entries) {
      if (e.key != 'Mercury' && _rashiOf(e.value) == jk27MerR) jk27WithMer++;
    }
    if (jk27WithMer >= 3) {
      yogas.add(Yoga(
        shloka: 'ಸಮನುಪತಿತಾ ಯಸ್ಮಿನ್ ಗಾವೋ ತ್ರಯಃ ಸಬುಧಾ ಗ್ರಹಾ',
        name: 'ಬಹು ಗುರುತು ಯೋಗ (ಜಕ ೨೭)',
        description: '$jk27WithMer ಗ್ರಹರು ಬುಧನೊಂದಿಗೆ ${_rashiNames[jk27MerR]} ರಾಶಿಯಲ್ಲಿ',
        result: 'ದೇಹದಲ್ಲಿ ಖಚಿತ ಗುರುತುಗಳು',
        rashi: jk27MerR, planets: ['ಬುಧ'],
      ));
    }

    // ═══ JK Shloka 28: Wound in 6th house / Mole in lagna ═══
    for (final e in malLons.entries) {
      final hFLag28 = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (hFLag28 == 6) {
        bool jk28BenAsp = false;
        for (final b in allPLons.entries) {
          if ({'Jupiter','Venus','Mercury'}.contains(b.key) && (_rashiOf(b.value) + 6) % 12 == _rashiOf(e.value)) jk28BenAsp = true;
        }
        yogas.add(Yoga(
          shloka: 'ವ್ರಣಕೃದುಶುಭಃ ಷಷ್ಟೇ ಲಗ್ನಾತ್ ತನೌ ಭಸಮಾಶ್ರಿತೇ',
          name: '${jk28BenAsp ? "ಮಚ್ಚೆ" : "ಗಾಯ"} ಯೋಗ (ಜಕ ೨೮)',
          description: '${_knPlanets[e.key]} 6ನೇ ಮನೆ${jk28BenAsp ? " + ಶುಭ ದೃಷ್ಟಿ → ಮಚ್ಚೆ" : " → ಗಾಯ"}',
          result: jk28BenAsp ? 'ಆ ಭಾಗದಲ್ಲಿ ಮಚ್ಚೆ' : 'ಆ ಭಾಗದಲ್ಲಿ ಗಾಯ',
          rashi: _rashiOf(e.value), planets: [_knPlanets[e.key]!],
        ));
        break;
      }
    }

    // ═══════════════════════════════════════════════════
    // Chapter 6: ಅರಿಷ್ಟಾಧ್ಯಾಯ (Arishtadhyaya - Yogas for infant mortality)
    // ═══════════════════════════════════════════════════

    // ═══ AR Shloka 1: Infant mortality in Sandhya & Hora ═══
    final ar1MoonInLag = moonR2 == lagRashi;
    bool ar1MalInKendra = false;
    for (final e in malLons.entries) {
      final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (h == 1 || h == 4 || h == 7 || h == 10) {
        ar1MalInKendra = true;
        break;
      }
    }
    if (ar1MoonInLag && ar1MalInKendra) {
      yogas.add(Yoga(
        shloka: 'ಸಂಧ್ಯಾಯಾಂ ಹಿಮದೀಧಿತಿಹೋರಾ ಪಾಪೈರ್ಭಾಂತಗತೈರ್ನಿಧನಾಯ',
        name: 'ಅರಿಷ್ಟ ಯೋಗ (ಅರಿ ೧)',
        description: 'ಲಗ್ನದಲ್ಲಿ ಚಂದ್ರ + ಕೇಂದ್ರದಲ್ಲಿ ಪಾಪಗ್ರಹರು',
        result: 'ಶಿಶುವಿನ ಮರಣ/ನಾಶ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ AR Shloka 2: Scorpio Lagna & Malefics in East/West ═══
    bool ar2MalIn2 = false, ar2MalIn12 = false, ar2MalIn6 = false, ar2MalIn8 = false;
    for (final e in malLons.entries) {
      final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (h == 2) ar2MalIn2 = true;
      if (h == 12) ar2MalIn12 = true;
      if (h == 6) ar2MalIn6 = true;
      if (h == 8) ar2MalIn8 = true;
    }
    final ar2PapakartariLagna = ar2MalIn2 && ar2MalIn12;
    final ar2Papakartari7 = ar2MalIn6 && ar2MalIn8;
    if (ar2PapakartariLagna && ar2Papakartari7) {
      yogas.add(Yoga(
        shloka: 'ಚಕ್ರಸ್ಯ ಪೂರ್ವೇತರಭಾಗಗೇಷು ಕ್ರೂರೇಷು ಸೌಮ್ಯಷು ಚ ಕೀಟಲನ್ನೇ',
        name: 'ಉಭಯ ಪಾಪಕರ್ತರಿ ಯೋಗ (ಅರಿ ೨)',
        description: 'ಲಗ್ನ (12, 2) ಮತ್ತು 7ನೇ ಮನೆಯ (6, 8) ಎರಡೂ ಕಡೆ ಪಾಪಗ್ರಹರು',
        result: 'ಶೀಘ್ರ ಮರಣ',
        rashi: lagRashi, planets: [],
      ));
    }

    // ═══ AR Shloka 3: Mars in Lagna without benefic aspect + Saturn in 6/8 ═══
    final ar3MarsInLag = marsR == lagRashi;
    bool ar3BenAspLag = false;
    for (final e in allPLons.entries) {
      if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
        if ((_rashiOf(e.value) + 6) % 12 == lagRashi) ar3BenAspLag = true;
      }
    }
    final ar3SatH = ((satR2 - lagRashi) % 12) + 1;
    final ar3SatIn68 = ar3SatH == 6 || ar3SatH == 8;
    if (ar3MarsInLag && !ar3BenAspLag && ar3SatIn68) {
      yogas.add(Yoga(
        shloka: 'ಭೌಮೇ ವಿಲನ್ನೇ ಶುಭದೈರದೃಷ್ಟೇ ಷಷ್ಟೇsಷ್ಟಮೇ ವಾರ್ಕಸುತೇನ ಯುಕ್ತ',
        name: 'ಬಾಲಾರಿಷ್ಟ ಯೋಗ (ಅರಿ ೩)',
        description: 'ಲಗ್ನದಲ್ಲಿ ಕುಜ (ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ) + ಶನಿ 6/8ನೇ ಮನೆಯಲ್ಲಿ',
        result: 'ಮರಣ',
        rashi: lagRashi, planets: ['ಕುಜ', 'ಶನಿ'],
      ));
    }

    // ═══ AR Shloka 4: Malefics in Lagna & 7th, Moon with Malefic & no benefic aspect ═══
    bool ar4MalInLag = false, ar4MalIn7 = false;
    bool ar4MoonWithMal = false;
    for (final e in malLons.entries) {
      final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (h == 1) ar4MalInLag = true;
      if (h == 7) ar4MalIn7 = true;
      if (_rashiOf(e.value) == moonR2) ar4MoonWithMal = true;
    }
    bool ar4BenAspMoon = false;
    for (final e in allPLons.entries) {
      if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
        if ((_rashiOf(e.value) + 6) % 12 == moonR2) ar4BenAspMoon = true;
      }
    }
    if (ar4MalInLag && ar4MalIn7 && ar4MoonWithMal && !ar4BenAspMoon) {
      yogas.add(Yoga(
        shloka: 'ಪಾಪಾವುದಯಾಸ್ತಗತೌ ಕ್ರೂರೇಣ ಯುತಶ್ಚ ಶಶೀ',
        name: 'ಕ್ಷಿಪ್ರ ಮರಣ ಯೋಗ (ಅರಿ ೪)',
        description: 'ಲಗ್ನ, 7ರಲ್ಲಿ ಪಾಪರು + ಪಾಪನೊಂದಿಗೆ ಚಂದ್ರ + ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ',
        result: 'ಶೀಘ್ರ ಮರಣ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ AR Shloka 5: Moon with malefic in 1/7/8/12, no kendra benefic aspect ═══
    final ar5MoonH = ((moonR2 - lagRashi) % 12) + 1;
    final ar5MoonIn17812 = ar5MoonH == 1 || ar5MoonH == 7 || ar5MoonH == 8 || ar5MoonH == 12;
    if (ar5MoonIn17812 && ar4MoonWithMal) {
      bool ar5BenAsp = false;
      for (final e in allPLons.entries) {
        if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
          if ((_rashiOf(e.value) + 6) % 12 == moonR2) ar5BenAsp = true;
        }
      }
      if (!ar5BenAsp) {
        yogas.add(Yoga(
          shloka: 'ಕ್ರೂರಸಂಯುತಃ ಶಶೀ ಸ್ಮರಾಂತ್ಯಮೃತ್ಯುಲಗ್ನಗಃ',
          name: 'ಮೃತ್ಯು ಯೋಗ (ಅರಿ ೫)',
          description: 'ಚಂದ್ರ 1/7/8/12 ರಲ್ಲಿ ಪಾಪನೊಂದಿಗೆ + ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ',
          result: 'ಮರಣ',
          rashi: moonR2, planets: ['ಚಂದ್ರ'],
        ));
      }
    }

    // ═══ AR Shloka 6: Waning Moon in 12, Malefics in 1/8, No benefics in Kendra ═══
    final ar6WaneDiff = (moonLon - sun + 360) % 360;
    final ar6IsWaning = ar6WaneDiff > 180;
    final ar6MoonIn12 = ((moonR2 - lagRashi) % 12) + 1 == 12;
    bool ar6MalIn8 = false;
    for (final e in malLons.entries) {
      if (((_rashiOf(e.value) - lagRashi) % 12) + 1 == 8) ar6MalIn8 = true;
    }
    bool ar6BenInKendra = false;
    for (final e in allPLons.entries) {
      if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
        final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        if (h == 1 || h == 4 || h == 7 || h == 10) ar6BenInKendra = true;
      }
    }
    if (ar6IsWaning && ar6MoonIn12 && ar4MalInLag && ar6MalIn8 && !ar6BenInKendra) {
      yogas.add(Yoga(
        shloka: 'ಕ್ಷೀಣೇ ಹಿಮಗೌ ವ್ಯಯಗೇ ಪಾಪೈರುದಯಾಷ್ಟಮಗೈಃ',
        name: 'ಕ್ಷಿಪ್ರ ಮರಣ ಯೋಗ (ಅರಿ ೬)',
        description: 'ಕ್ಷೀಣ ಚಂದ್ರ 12ರಲ್ಲಿ + ಲಗ್ನ, 8ರಲ್ಲಿ ಪಾಪರು + ಕೇಂದ್ರದಲ್ಲಿ ಶುಭರಿಲ್ಲ',
        result: 'ಶೀಘ್ರ ಮರಣ',
        rashi: moonR2, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ AR Shloka 7: Moon in 6/8 with Malefic aspect ═══
    final ar7MoonIn68 = ar5MoonH == 6 || ar5MoonH == 8;
    if (ar7MoonIn68) {
      bool ar7MalAsp = false, ar7BenAsp = false, ar7StrongMalAsp = false;
      for (final e in allPLons.entries) {
         if ((_rashiOf(e.value) + 6) % 12 == moonR2) {
           if ({'Sun', 'Mars', 'Saturn', 'Rahu', 'Ketu'}.contains(e.key)) {
             ar7MalAsp = true;
             if (isStrong(e.key)) ar7StrongMalAsp = true;
           } else if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
             ar7BenAsp = true;
           }
         }
      }
      if (ar7MalAsp || ar7BenAsp) {
        String ar7Desc = '';
        String ar7Res = '';
        if (ar7StrongMalAsp) {
          ar7Desc = 'ಬಲಶಾಲಿ ಪಾಪಗ್ರಹರ ದೃಷ್ಟಿ';
          ar7Res = '1 ತಿಂಗಳಲ್ಲಿ ಮರಣ';
        } else if (ar7MalAsp && ar7BenAsp) {
          ar7Desc = 'ಪಾಪ ಹಾಗೂ ಶುಭ ದೃಷ್ಟಿ';
          ar7Res = '4 ವರ್ಷಗಳ ನಂತರ ಮರಣ';
        } else if (ar7BenAsp) {
          ar7Desc = 'ಶುಭ ದೃಷ್ಟಿ ಮಾತ್ರ';
          ar7Res = '8 ವರ್ಷಗಳ ನಂತರ ಮರಣ';
        } else if (ar7MalAsp) {
          ar7Desc = 'ಪಾಪಗ್ರಹರ ದೃಷ್ಟಿ';
          ar7Res = 'ಶೀಘ್ರ ಮರಣ';
        }
        yogas.add(Yoga(
          shloka: 'ಶಶಿನ್ಯರಿವಿನಾಶಗೇ ನಿಧನಮಾಶು ಪಾಪೇಕ್ಷಿತೇ',
          name: 'ಚಂದ್ರ ಅರಿಷ್ಟ ಯೋಗ (ಅರಿ ೭)',
          description: 'ಚಂದ್ರ $ar5MoonHನೇ ಮನೆಯಲ್ಲಿ + $ar7Desc',
          result: ar7Res,
          rashi: moonR2, planets: ['ಚಂದ್ರ'],
        ));
      }
    }
    
    final ar7LagLord = rashiLords[lagRashi];
    final ar7LagLordIsBen = {'Jupiter', 'Venus', 'Mercury'}.contains(ar7LagLord);
    final ar7LagLordH = ((_rashiOf(allPLons[ar7LagLord]!) - lagRashi) % 12) + 1;
    bool ar7LagLordDefeated = false;
    for (final e in malLons.entries) {
      if (_rashiOf(e.value) == _rashiOf(allPLons[ar7LagLord]!)) ar7LagLordDefeated = true;
    }
    if (ar7LagLordIsBen && ar7LagLordH == 7 && ar7LagLordDefeated) {
       yogas.add(Yoga(
          shloka: 'ಶಶಿನ್ಯರಿವಿನಾಶಗೇ ನಿಧನಮಾಶು ಪಾಪೇಕ್ಷಿತೇ',
          name: 'ಲಗ್ನಾಧಿಪ ಅರಿಷ್ಟ ಯೋಗ (ಅರಿ ೭)',
          description: 'ಶುಭ ಲಗ್ನಾಧಿಪತಿ 7ರಲ್ಲಿ ಪಾಪಗ್ರಹರೊಂದಿಗೆ',
          result: 'ಮರಣ',
          rashi: lagRashi, planets: [_knPlanets[ar7LagLord]!],
        ));
    }

    // ═══ AR Shloka 8: Waning Moon in Lagna + Malefics in 8 & Kendra ═══
    final ar8WaningMoonLag = ar6IsWaning && moonR2 == lagRashi;
    bool ar8MalInKendra = false;
    for (final e in malLons.entries) {
      final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (h == 1 || h == 4 || h == 7 || h == 10) ar8MalInKendra = true;
    }
    if (ar8WaningMoonLag && ar6MalIn8 && ar8MalInKendra) {
      yogas.add(Yoga(
        shloka: 'ಲಗ್ನ ಕ್ಷೀಣೇ ಶಶಿನಿ ನಿಧನಂ ರಂಧ್ರಕೇಂದ್ರೇಷು ಪಾಪೈ:',
        name: 'ಬಾಲಾರಿಷ್ಟ ಯೋಗ (ಅರಿ ೮)',
        description: 'ಕ್ಷೀಣ ಚಂದ್ರ ಲಗ್ನದಲ್ಲಿ + 8ರಲ್ಲಿ ಮತ್ತು ಕೇಂದ್ರದಲ್ಲಿ ಪಾಪರು',
        result: 'ಮರಣ',
        rashi: lagRashi, planets: ['ಚಂದ್ರ'],
      ));
    }
    
    if (ar5MoonH == 4 || ar5MoonH == 7 || ar5MoonH == 8) {
      bool malBefore = false, malAfter = false;
      for (final e in malLons.entries) {
        if (_rashiOf(e.value) == (moonR2 + 11) % 12) malBefore = true;
        if (_rashiOf(e.value) == (moonR2 + 1) % 12) malAfter = true;
      }
      if (malBefore && malAfter) {
         yogas.add(Yoga(
          shloka: 'ಪಾಪಾಂತಃಸ್ಟೇ ನಿಧನಹಿಬುಕಮ್ಯೂನಯುಕ್ತ ಚ ಚಂದ್ರೇ',
          name: 'ಚಂದ್ರ ಪಾಪಕರ್ತರಿ ಯೋಗ (ಅರಿ ೮)',
          description: 'ಚಂದ್ರ $ar5MoonHನೇ ಮನೆಯಲ್ಲಿ ಪಾಪರ ಮಧ್ಯೆ',
          result: 'ಮರಣ',
          rashi: moonR2, planets: ['ಚಂದ್ರ'],
        ));
      }
    }
    
    if (ar2PapakartariLagna && ar4MalIn7 && ar6MalIn8) {
      bool ar8StrongBenAsp = false;
      for (final e in allPLons.entries) {
        if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key) && isStrong(e.key)) {
           if ((_rashiOf(e.value) + 6) % 12 == lagRashi) ar8StrongBenAsp = true;
        }
      }
      if (!ar8StrongBenAsp) {
         yogas.add(Yoga(
          shloka: 'ಏವಂ ಲಗ್ನ ಭವತಿ ಮದನಚ್ಚಿದ್ರಸಂಸ್ಥೆ ಚ ಪಾಪೇ',
          name: 'ಲಗ್ನ ಪಾಪಕರ್ತರಿ ಅರಿಷ್ಟ ಯೋಗ (ಅರಿ ೮)',
          description: 'ಲಗ್ನ ಪಾಪರ ಮಧ್ಯೆ + 7,8ರಲ್ಲಿ ಪಾಪರು + ಬಲಶಾಲಿ ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ',
          result: 'ಮರಣ',
          rashi: lagRashi, planets: [],
        ));
      }
    }

    // ═══ AR Shloka 9: Moon at end of Rashi without Benefic Aspect + Malefics in Trikona ═══
    final ar9MoonDeg = moonLon % 30;
    final ar9MoonAtEnd = ar9MoonDeg > 29;
    bool ar9MalInTrikona = false;
    for (final e in malLons.entries) {
      final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (h == 5 || h == 9) ar9MalInTrikona = true;
    }
    if (ar9MoonAtEnd && !ar4BenAspMoon && ar9MalInTrikona) {
       yogas.add(Yoga(
          shloka: 'ರಾಶ್ಯಂತಗೇ ಸದ್ಧಿರನೀಕ್ಷಮಾಣೇ ಚಂದ್ರ ತ್ರಿಕೋಣೋಪಗತೈಶ್ಚ ಶೇಪೈಃ',
          name: 'ರಾಶ್ಯಂತ ಚಂದ್ರ ಅರಿಷ್ಟ (ಅರಿ ೯)',
          description: 'ಚಂದ್ರ ರಾಶಿಯ ಕೊನೆಯಲ್ಲಿ (ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ) + ತ್ರಿಕೋಣದಲ್ಲಿ ಪಾಪರು',
          result: 'ಪ್ರಾಣ ವಿಯೋಗ',
          rashi: moonR2, planets: ['ಚಂದ್ರ'],
        ));
    }
    if (ar4MalIn7 && moonR2 == lagRashi) {
      yogas.add(Yoga(
          shloka: 'ಅಸ್ತೇ ಚ ಪಾಪೈಸ್ತುಹಿನಾಂಶುಲಕ್ಷ್ಮೀ',
          name: 'ಚಂದ್ರ ಲಗ್ನ ಪಾಪ ಅರಿಷ್ಟ (ಅರಿ ೯)',
          description: 'ಚಂದ್ರ ಲಗ್ನದಲ್ಲಿ + 7ನೇ ಮನೆಯಲ್ಲಿ ಪಾಪಗ್ರಹರು',
          result: 'ಮರಣ',
          rashi: lagRashi, planets: ['ಚಂದ್ರ'],
        ));
    }

    // ═══ AR Shloka 10: Eclipsed Moon + Malefic + Mars in 8th ═══
    final ar10MoonRahu = moonR2 == _rashiOf(allPLons['Rahu']!) || moonR2 == _rashiOf(allPLons['Ketu']!);
    bool ar10MarsIn8 = ((marsR - lagRashi) % 12) + 1 == 8;
    if (ar10MoonRahu && ar4MoonWithMal && ar10MarsIn8) {
       yogas.add(Yoga(
          shloka: 'ಅಶುಭಸಹಿತೇ ಗ್ರಸ್ತ ಚಂದ್ರ ಕುಜೇ ನಿಧನಾಶ್ರಿತೇ',
          name: 'ಮಾತೃ-ಶಿಶು ಮರಣ ಯೋಗ (ಅರಿ ೧೦)',
          description: 'ಗ್ರಹಣ ಚಂದ್ರ ಪಾಪನೊಂದಿಗೆ + ಕುಜ 8ರಲ್ಲಿ',
          result: 'ತಾಯಿ-ಮಗು ಇಬ್ಬರ ಮರಣ',
          rashi: moonR2, planets: ['ಚಂದ್ರ', 'ಕುಜ'],
        ));
       if (sunR == lagRashi) {
         yogas.add(Yoga(
            shloka: 'ಲಗ್ನ ರದೌ ತು ಸ ಶಸ್ತ್ರಜಃ',
            name: 'ಶಸ್ತ್ರ ಮರಣ ಯೋಗ (ಅರಿ ೧೦)',
            description: 'ಗ್ರಹಣ ಚಂದ್ರ + ಕುಜ 8ರಲ್ಲಿ + ಲಗ್ನದಲ್ಲಿ ರವಿ',
            result: 'ಶಸ್ತ್ರದಿಂದ ಮರಣ',
            rashi: lagRashi, planets: ['ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
          ));
       }
    }
    if (sunR == lagRashi || moonR2 == lagRashi) {
      bool ar10StrongMalInTri = false;
      bool ar10StrongMalIn8 = false;
      for (final e in malLons.entries) {
        if (isStrong(e.key)) {
          final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
          if (h == 5 || h == 9) ar10StrongMalInTri = true;
          if (h == 8) ar10StrongMalIn8 = true;
        }
      }
      if (ar10StrongMalInTri && ar10StrongMalIn8) {
         bool ar10BenAsp = false;
         for (final e in allPLons.entries) {
           if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
             final h = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
             if (h == 1 || (_rashiOf(e.value) + 6) % 12 == lagRashi) ar10BenAsp = true;
           }
         }
         if (!ar10BenAsp) {
           yogas.add(Yoga(
            shloka: 'ಉದಯತಿ ರವೌ ಶೀತಾಂಶೌ ವಾ ತ್ರಿಕೋಣವಿನಾಶಗೈ…',
            name: 'ಲಗ್ನ ರವಿ/ಚಂದ್ರ ಅರಿಷ್ಟ (ಅರಿ ೧೦)',
            description: 'ಲಗ್ನದಲ್ಲಿ ರವಿ/ಚಂದ್ರ + ತ್ರಿಕೋಣ, 8ರಲ್ಲಿ ಬಲಶಾಲಿ ಪಾಪರು + ಶುಭ ದೃಷ್ಟಿ/ಯೋಗ ಇಲ್ಲ',
            result: 'ಮರಣ',
            rashi: lagRashi, planets: ['ರವಿ', 'ಚಂದ್ರ'],
          ));
         }
      }
    }

    // ═══ AR Shloka 11: Saturn, Sun, Moon, Mars in 12, 9, 1, 8 ═══
    final ar11Sat12 = ((satR2 - lagRashi) % 12) + 1 == 12;
    final ar11Sun9 = ((sunR - lagRashi) % 12) + 1 == 9;
    final ar11Moon1 = moonR2 == lagRashi;
    final ar11Mars8 = ((marsR - lagRashi) % 12) + 1 == 8;
    if (ar11Sat12 && ar11Sun9 && ar11Moon1 && ar11Mars8) {
      final ar11JupAsp = (_rashiOf(jup) + 6) % 12 == lagRashi || (_rashiOf(jup) + 4) % 12 == lagRashi || (_rashiOf(jup) + 8) % 12 == lagRashi;
      if (!ar11JupAsp || !isStrong('Jupiter')) {
        yogas.add(Yoga(
            shloka: 'ಅಸಿತರವಿಶಶಾಂಕಭೂಮಿಚೈರ್ವ್ಯಯನವಮೋದಯನೈಧನಾಶ್ರಿತೈ:',
            name: 'ಚತುರ್ಗ್ರಹ ಅರಿಷ್ಟ ಯೋಗ (ಅರಿ ೧೧)',
            description: 'ಶನಿ(12), ರವಿ(9), ಚಂದ್ರ(1), ಕುಜ(8) + ಬಲಶಾಲಿ ಗುರು ದೃಷ್ಟಿ ಇಲ್ಲ',
            result: 'ಶೀಘ್ರ ಮರಣ',
            rashi: lagRashi, planets: ['ಶನಿ', 'ರವಿ', 'ಚಂದ್ರ', 'ಕುಜ'],
          ));
      }
    }

    // ═══ AR Shloka 12: Moon with malefic in 5/7/9/12/1/8 ═══
    final ar12MoonInBad = [5, 7, 9, 12, 1, 8].contains(ar5MoonH);
    if (ar12MoonInBad && ar4MoonWithMal) {
       bool ar12StrongBenAsp = false;
       for (final e in allPLons.entries) {
         if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key) && isStrong(e.key)) {
           if (_rashiOf(e.value) == moonR2 || (_rashiOf(e.value) + 6) % 12 == moonR2) ar12StrongBenAsp = true;
         }
       }
       if (!ar12StrongBenAsp) {
          yogas.add(Yoga(
            shloka: 'ಸುತಮದನವಮಾಂತ್ಯಲಗ್ನರಂಧೇಷ್ಟಶುಭಯುತೋ ಮರಣಾಯ ಶೀತರಃ',
            name: 'ಚಂದ್ರ ಪಾಪ ಯೋಗ (ಅರಿ ೧೨)',
            description: 'ಚಂದ್ರ ಪಾಪನೊಂದಿಗೆ ${ar5MoonH}ನೇ ಮನೆಯಲ್ಲಿ + ಬಲಶಾಲಿ ಶುಕ್ರ/ಬುಧ/ಗುರು ದೃಷ್ಟಿ/ಯೋಗ ಇಲ್ಲ',
            result: 'ಮರಣ',
            rashi: moonR2, planets: ['ಚಂದ್ರ'],
          ));
       }
    }

    // ═══ AR Shloka 13: Strong Moon in own house or Lagna with malefic aspect ═══
    final ar13MoonStrong = isStrong('Moon');
    final ar13MoonInOwn = moonR2 == 3;
    final ar13MoonInLag = moonR2 == lagRashi;
    if (ar13MoonStrong && (ar13MoonInOwn || ar13MoonInLag)) {
       bool ar13MalAsp = false;
       for (final e in malLons.entries) {
         if ((_rashiOf(e.value) + 6) % 12 == moonR2) ar13MalAsp = true;
       }
       if (ar13MalAsp) {
          yogas.add(Yoga(
            shloka: 'ಯೋಗೇ ಸ್ಥಾನಂ ಗತವತಿ ಬಲಿನಶ್ಚಂದ್ರೆ ಸ್ವಂ ವಾ ತನುಗೃಹಮಥವಾ',
            name: 'ಬಲಿಷ್ಠ ಚಂದ್ರ ಅರಿಷ್ಟ (ಅರಿ ೧೩)',
            description: 'ಬಲಶಾಲಿ ಚಂದ್ರ ಸ್ವಕ್ಷೇತ್ರ/ಲಗ್ನದಲ್ಲಿ + ಪಾಪ ದೃಷ್ಟಿ',
            result: 'ಒಂದು ವರ್ಷದೊಳಗೆ ಮರಣ',
            rashi: moonR2, planets: ['ಚಂದ್ರ'],
          ));
       }
    }

    // ═══════════════════════════════════════════════════
    // Chapter 13: ಚಾಂದ್ರಯೋಗಾಧ್ಯಾಯ (Chandrayogadhyaya - Lunar Yogas)
    // ═══════════════════════════════════════════════════

    // ═══ CY Shloka 1: Moon in Kendra/Panaphara/Apoklima from Sun ═══
    final cy1MoonFromSunH = ((moonR2 - sunR) % 12) + 1;
    String cy1Phala = '';
    if (cy1MoonFromSunH == 1 || cy1MoonFromSunH == 4 || cy1MoonFromSunH == 7 || cy1MoonFromSunH == 10) {
      cy1Phala = 'ಅಧಮ';
    } else if (cy1MoonFromSunH == 2 || cy1MoonFromSunH == 5 || cy1MoonFromSunH == 8 || cy1MoonFromSunH == 11) {
      cy1Phala = 'ಸಮ';
    } else {
      cy1Phala = 'ವರಿಷ್ಠ';
    }
    
    // Day birth vs Night birth
    final cy1SunFromLagH = ((sunR - lagRashi) % 12) + 1;
    final cy1IsDay = cy1SunFromLagH >= 7 && cy1SunFromLagH <= 12;
    
    final cy1MoonNavLord = rashiLords[_d9Rashi(moonLon)];
    final cy1MoonNavOwnOrMitra = cy1MoonNavLord == 'Moon' || {'Sun', 'Mercury'}.contains(cy1MoonNavLord); 
    
    bool cy1JupAsp = (_rashiOf(jup) + 6) % 12 == moonR2 || (_rashiOf(jup) + 4) % 12 == moonR2 || (_rashiOf(jup) + 8) % 12 == moonR2;
    bool cy1VenAsp = (_rashiOf(ven) + 6) % 12 == moonR2;
    
    String cy1WealthPhala = '';
    if (cy1IsDay && cy1MoonNavOwnOrMitra && cy1JupAsp) {
      cy1WealthPhala = '\nಹಗಲು ಜನನ + ಗುರು ದೃಷ್ಟಿ → ಧನವಂತ ಮತ್ತು ಸುಖಿ';
    } else if (!cy1IsDay && cy1VenAsp) {
      cy1WealthPhala = '\nರಾತ್ರಿ ಜನನ + ಶುಕ್ರ ದೃಷ್ಟಿ → ಧನವಂತ ಮತ್ತು ಸುಖಿ';
    }

    yogas.add(Yoga(
      shloka: 'ಅಧಮಸಮವರಿಷ್ಠಾನ್ಯರ್ಕಕೇಂದ್ರಾದಿಸಂಸ್ಥೆ ಶಶಿನಿ ವಿನಯವಿತ್ತಜ್ಞಾನಧೀನೈಪುಣಾನಿ',
      name: 'ಚಂದ್ರ-ರವಿ ಯೋಗ (ಚಾ ೧)',
      description: 'ಚಂದ್ರನು ರವಿಯಿಂದ $cy1MoonFromSunHನೇ ಮನೆಯಲ್ಲಿ ($cy1Phala ಸ್ಥಾನ)$cy1WealthPhala',
      result: '$cy1Phala ಫಲ: ವಿನಯ, ವಿತ್ತ, ಜ್ಞಾನ, ನೈಪುಣ್ಯ',
      rashi: moonR2, planets: ['ಚಂದ್ರ', 'ರವಿ'],
    ));

    // ═══ CY Shloka 2: Adhi Yoga (Benefics in 6, 7, 8 from Moon) ═══
    bool cy2BenIn6 = false, cy2BenIn7 = false, cy2BenIn8 = false;
    for (final e in allPLons.entries) {
      if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
        final h = ((_rashiOf(e.value) - moonR2) % 12) + 1;
        if (h == 6) cy2BenIn6 = true;
        if (h == 7) cy2BenIn7 = true;
        if (h == 8) cy2BenIn8 = true;
      }
    }
    if (cy2BenIn6 || cy2BenIn7 || cy2BenIn8) {
       final benHouses = <String>[];
       if (cy2BenIn6) benHouses.add('6');
       if (cy2BenIn7) benHouses.add('7');
       if (cy2BenIn8) benHouses.add('8');
       yogas.add(Yoga(
        shloka: 'ಸೌಮ್ಯ ಸ್ಮರಾರಿನಿಧನೇಷ್ಟಧಿಯೋಗ ಇಂದೋಸ್ತಸ್ಮಿಂಶ್ಚಮೂಪಸಚಿವಕ್ಷಿತಿಪಾಲಜನ್ಮ',
        name: 'ಚಂದ್ರ ಅಧಿಯೋಗ (ಚಾ ೨)',
        description: 'ಚಂದ್ರನಿಂದ ${benHouses.join(',')}ನೇ ಮನೆಯಲ್ಲಿ ಶುಭಗ್ರಹರು',
        result: 'ಸೇನಾಪತಿ/ಮಂತ್ರಿ/ರಾಜ, ದೀರ್ಘಾಯು, ಶತ್ರುನಾಶ',
        rashi: moonR2, planets: ['ಚಂದ್ರ'],
      ));
    }

    // ═══ CY Shloka 3 & 4: Sunapha, Anapha, Durudhura, Kemadruma Yogas ═══
    bool cy3PlanetIn2 = false, cy3PlanetIn12 = false;
    final cy3PlanetsIn2 = <String>[];
    final cy3PlanetsIn12 = <String>[];
    bool cy3PlanetInKendra = false;
    bool cy3PlanetWithMoon = false;
    
    for (final e in allPLons.entries) {
      if (e.key != 'Sun' && e.key != 'Moon' && e.key != 'Rahu' && e.key != 'Ketu') {
        final hFromMoon = ((_rashiOf(e.value) - moonR2) % 12) + 1;
        if (hFromMoon == 2) {
          cy3PlanetIn2 = true;
          cy3PlanetsIn2.add(_knPlanets[e.key]!);
        }
        if (hFromMoon == 12) {
          cy3PlanetIn12 = true;
          cy3PlanetsIn12.add(_knPlanets[e.key]!);
        }
        if (hFromMoon == 1) cy3PlanetWithMoon = true;
        
        final hFromLag = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        if (hFromLag == 1 || hFromLag == 4 || hFromLag == 7 || hFromLag == 10) cy3PlanetInKendra = true;
      }
    }

    bool hasSunapha = cy3PlanetIn2 && !cy3PlanetIn12;
    bool hasAnapha = !cy3PlanetIn2 && cy3PlanetIn12;
    bool hasDurudhura = cy3PlanetIn2 && cy3PlanetIn12;
    bool hasKemadruma = !cy3PlanetIn2 && !cy3PlanetIn12 && !cy3PlanetInKendra && !cy3PlanetWithMoon;
    
    if (hasSunapha) {
      yogas.add(Yoga(
        shloka: 'ಸ್ವಯಮಧಿಗತವಿತ್ತಃ ಪಾರ್ಥಿವಸ್ತತ್ಸಮೋ ವಾ ಭವತಿ ಹಿ ಸುನಭಾಯಾಂ ಧೀಧನಖ್ಯಾತಿಮಾಂಶ್ಚ',
        name: 'ಸುನಫಾ ಯೋಗ (ಚಾ ೩,೪,೫,೭)',
        description: 'ಚಂದ್ರನಿಂದ 2ನೇ ಮನೆಯಲ್ಲಿ: ${cy3PlanetsIn2.join(', ')}',
        result: 'ಸ್ವಂತ ಪರಿಶ್ರಮದಿಂದ ಧನ, ರಾಜನ ಸಮಾನ, ಬುದ್ಧಿವಂತ',
        rashi: moonR2, planets: ['ಚಂದ್ರ'],
      ));
    } else if (hasAnapha) {
      yogas.add(Yoga(
        shloka: 'ಪ್ರಭುರಗದಶರೀರಃ ಶೀಲವಾನ್ ಖ್ಯಾತಕೀರ್ತಿವಿ್ರಷಯಸುಖಸುವೇಷೋ ನಿರ್ವೃತಶ್ಚಾನಭಾಯಾಮ್',
        name: 'ಅನಫಾ ಯೋಗ (ಚಾ ೩,೪,೫,೭)',
        description: 'ಚಂದ್ರನಿಂದ 12ನೇ ಮನೆಯಲ್ಲಿ: ${cy3PlanetsIn12.join(', ')}',
        result: 'ಪ್ರಭು, ರೋಗವಿಲ್ಲದ ಶರೀರ, ಕೀರ್ತಿ, ನೆಮ್ಮದಿ',
        rashi: moonR2, planets: ['ಚಂದ್ರ'],
      ));
    } else if (hasDurudhura) {
      yogas.add(Yoga(
        shloka: 'ಉತ್ಪನ್ನಭೋಗಸುಖಭಾಗ್ ಧನವಾಹನಾಡ್ಯಾಗಾನ್ವಿತೋ ಧುರುಧುರಾಪ್ರಭವಃ ಸುನೃತ್ಯಃ',
        name: 'ದುರುಧುರಾ ಯೋಗ (ಚಾ ೩,೪,೬)',
        description: 'ಚಂದ್ರನಿಂದ 2ರಲ್ಲಿ: ${cy3PlanetsIn2.join(', ')}, 12ರಲ್ಲಿ: ${cy3PlanetsIn12.join(', ')}',
        result: 'ಭೋಗ, ಸುಖ, ವಾಹನ ಸಂಪತ್ತು, ತ್ಯಾಗಗುಣ',
        rashi: moonR2, planets: ['ಚಂದ್ರ'],
      ));
    } else if (hasKemadruma) {
      yogas.add(Yoga(
        shloka: 'ಕೇಮದ್ರುಮೇ ಮಲಿನದುಃಖಿತನೀಚನಿಃಸ್ವಃ ಪ್ರೇಷ್ಯಃ ಖಲಶ್ಚ ನೃಪತೇರಪಿ ವಂಶಜಾತಃ',
        name: 'ಕೇಮದ್ರುಮ ಯೋಗ (ಚಾ ೩,೬)',
        description: 'ಚಂದ್ರನ ಅಕ್ಕಪಕ್ಕ, ಲಗ್ನಕೇಂದ್ರ, ಮತ್ತು ಜೊತೆಯಲ್ಲಿ ಬೇರೆ ಗ್ರಹರಿಲ್ಲ',
        result: 'ಮಲಿನ, ದುಃಖಿತ, ದರಿದ್ರ, ಸೇವಕ',
        rashi: moonR2, planets: ['ಚಂದ್ರ'],
      ));
    }
    
    if (hasSunapha || hasAnapha || hasDurudhura) {
      final combinedPlanets = [...cy3PlanetsIn2, ...cy3PlanetsIn12];
      if (combinedPlanets.contains('ಕುಜ')) {
        yogas.add(Yoga(
          shloka: 'ಉತ್ಸಾಹಶೌರ್ಯಧನಸಾಹಸವಾನ್ಮಹೀಜೇ',
          name: 'ಕುಜ ಸುನಫಾದಿ ಫಲ (ಚಾ ೭)',
          description: 'ಯೋಗ ಕಾರಕ ಮಂಗಳ',
          result: 'ಉತ್ಸಾಹ, ಶೌರ್ಯ, ಧನ, ಸಾಹಸ',
          rashi: moonR2, planets: ['ಕುಜ'],
        ));
      }
      if (combinedPlanets.contains('ಬುಧ')) {
        yogas.add(Yoga(
          shloka: 'ಸೌಮ್ಯ ಪಟುಃ ಸುವಚನೋ ನಿಪುಣಃ ಕಲಾಸು',
          name: 'ಬುಧ ಸುನಫಾದಿ ಫಲ (ಚಾ ೭)',
          description: 'ಯೋಗ ಕಾರಕ ಬುಧ',
          result: 'ಚತುರ, ಒಳ್ಳೆಯ ಮಾತುಗಾರ, ಕಲೆಗಳಲ್ಲಿ ನಿಪುಣ',
          rashi: moonR2, planets: ['ಬುಧ'],
        ));
      }
      if (combinedPlanets.contains('ಗುರು')) {
        yogas.add(Yoga(
          shloka: 'ಜೀವೇsರ್ಥಧರ್ಮಸುಖಭಾಜ್ ನೃಪಪೂಜಿತಶ್ಚ',
          name: 'ಗುರು ಸುನಫಾದಿ ಫಲ (ಚಾ ೭)',
          description: 'ಯೋಗ ಕಾರಕ ಗುರು',
          result: 'ಧನ, ಧರ್ಮ, ರಾಜನಿಂದ ಪೂಜೆ',
          rashi: moonR2, planets: ['ಗುರು'],
        ));
      }
      if (combinedPlanets.contains('ಶುಕ್ರ')) {
        yogas.add(Yoga(
          shloka: 'ಕಾಮೀ ನೃಗೌ ಬಹುಧನೋ ವಿಷಯೋಪಭೋಕ್ತಾ',
          name: 'ಶುಕ್ರ ಸುನಫಾದಿ ಫಲ (ಚಾ ೭)',
          description: 'ಯೋಗ ಕಾರಕ ಶುಕ್ರ',
          result: 'ಬಹು ಧನವಂತ, ವಿಷಯ ಸುಖ',
          rashi: moonR2, planets: ['ಶುಕ್ರ'],
        ));
      }
      if (combinedPlanets.contains('ಶನಿ')) {
        yogas.add(Yoga(
          shloka: 'ಪರವಿಭವಪರಿಚ್ಛದೋಪಭೋಕ್ತಾ ರವಿತನಯೇ ಬಹುಕಾರ್ಯಕೃದ್ಗಣೇಶಃ',
          name: 'ಶನಿ ಸುನಫಾದಿ ಫಲ (ಚಾ ೮)',
          description: 'ಯೋಗ ಕಾರಕ ಶನಿ',
          result: 'ಇತರರ ಸಂಪತ್ತು ಅನುಭವಿಸುವವನು, ಗಣನಾಯಕ',
          rashi: moonR2, planets: ['ಶನಿ'],
        ));
      }
    }

    // ═══ CY Shloka 9: Vasumathi Yoga ═══
    int cy9BenInUpachayaLag = 0;
    int cy9BenInUpachayaMoon = 0;
    for (final e in allPLons.entries) {
      if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
        final hLag = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        if (hLag == 3 || hLag == 6 || hLag == 10 || hLag == 11) cy9BenInUpachayaLag++;
        
        final hMoon = ((_rashiOf(e.value) - moonR2) % 12) + 1;
        if (hMoon == 3 || hMoon == 6 || hMoon == 10 || hMoon == 11) cy9BenInUpachayaMoon++;
      }
    }
    
    if (cy9BenInUpachayaLag > 0 || cy9BenInUpachayaMoon > 0) {
      String cy9Desc = '';
      String cy9Res = '';
      if (cy9BenInUpachayaLag == 3) {
        cy9Desc = 'ಎಲ್ಲಾ (3) ಶುಭಗ್ರಹರು ಲಗ್ನದಿಂದ ಉಪಚಯದಲ್ಲಿ (3,6,10,11)';
        cy9Res = 'ಅತಿಶಯವಾದ ಧನವಂತ (ವಸುಮತೀ ಯೋಗ)';
      } else if (cy9BenInUpachayaLag == 2) {
        cy9Desc = '2 ಶುಭಗ್ರಹರು ಲಗ್ನದಿಂದ ಉಪಚಯದಲ್ಲಿ';
        cy9Res = 'ಮಧ್ಯಮ ಧನವಂತ';
      } else if (cy9BenInUpachayaLag == 1) {
        cy9Desc = '1 ಶುಭಗ್ರಹ ಲಗ್ನದಿಂದ ಉಪಚಯದಲ್ಲಿ';
        cy9Res = 'ಅಲ್ಪ ಧನವಂತ';
      } else if (cy9BenInUpachayaMoon > 0) {
        cy9Desc = '$cy9BenInUpachayaMoon ಶುಭಗ್ರಹರು ಚಂದ್ರನಿಂದ ಉಪಚಯದಲ್ಲಿ';
        cy9Res = 'ಸಾಧಾರಣ ಧನವಂತ';
      }
      
      if (cy9Desc.isNotEmpty) {
        yogas.add(Yoga(
          shloka: 'ಲಗ್ನಾದತೀವ ವಸುಮಾನ್ವಸುಮಾಞ್ಞಶಾಂಕಾತ್ಮ್ಯಗ್ರಹೈರುಪಚಯೋಪಗತೈ: ಸಮಸ್ಯೆ:',
          name: 'ವಸುಮತೀ ಯೋಗ (ಚಾ ೯)',
          description: cy9Desc,
          result: cy9Res,
          rashi: lagRashi, planets: [],
        ));
      }
    }

    // ═══════════════════════════════════════════════════
    // Chapter 14: ದ್ವಿಗ್ರಹಯೋಗಾಧ್ಯಾಯ (Dvigraha Yogadhyaya - Two-planet combinations)
    // ═══════════════════════════════════════════════════

    bool dyAreTogether(String p1, String p2) {
      if (!allPLons.containsKey(p1) || !allPLons.containsKey(p2)) return false;
      return _rashiOf(allPLons[p1]!) == _rashiOf(allPLons[p2]!);
    }
    
    int dyTogetherRashi(String p1, String p2) {
      return _rashiOf(allPLons[p1]!);
    }

    // ═══ DY Shloka 1: Sun combinations ═══
    if (dyAreTogether('Sun', 'Moon')) {
      yogas.add(Yoga(
        shloka: 'ತಿಗ್ಗಾಂಶುರ್ಜನಯತ್ಯಥೇಂದುಸಹಿತೋ ಯಂತ್ರಾಶ್ಚಕಾರಂ ನರಂ',
        name: 'ರವಿ-ಚಂದ್ರ ಯೋಗ (ದ್ವಿ ೧)',
        description: 'ರವಿ ಮತ್ತು ಚಂದ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ಯಂತ್ರ ಮತ್ತು ಕಲ್ಲುಗಳ ಕೆಲಸ ಮಾಡುವವನು',
        rashi: dyTogetherRashi('Sun', 'Moon'), planets: ['ರವಿ', 'ಚಂದ್ರ'],
      ));
    }
    if (dyAreTogether('Sun', 'Mars')) {
      yogas.add(Yoga(
        shloka: 'ಭೌಮೇನಾಘರತಂ',
        name: 'ರವಿ-ಕುಜ ಯೋಗ (ದ್ವಿ ೧)',
        description: 'ರವಿ ಮತ್ತು ಕುಜ ಒಟ್ಟಿಗೆ',
        result: 'ಪಾಪಕಾರ್ಯಗಳಲ್ಲಿ ನಿರತ',
        rashi: dyTogetherRashi('Sun', 'Mars'), planets: ['ರವಿ', 'ಕುಜ'],
      ));
    }
    if (dyAreTogether('Sun', 'Mercury')) {
      yogas.add(Yoga(
        shloka: 'ಬುಧೇನ ನಿಪುಣಂ ಧೀಕೀರ್ತಿಸೌಖ್ಯಾನ್ವಿತಮ್',
        name: 'ರವಿ-ಬುಧ ಯೋಗ (ದ್ವಿ ೧)',
        description: 'ರವಿ ಮತ್ತು ಬುಧ ಒಟ್ಟಿಗೆ',
        result: 'ನಿಪುಣ, ಬುದ್ಧಿವಂತ, ಕೀರ್ತಿವಂತ, ಸುಖಿ',
        rashi: dyTogetherRashi('Sun', 'Mercury'), planets: ['ರವಿ', 'ಬುಧ'],
      ));
    }
    if (dyAreTogether('Sun', 'Jupiter')) {
      yogas.add(Yoga(
        shloka: 'ಕ್ರೂರಂ ವಾಕೃತಿನಾನ್ಯಕಾರ್ಯನಿರತಂ',
        name: 'ರವಿ-ಗುರು ಯೋಗ (ದ್ವಿ ೧)',
        description: 'ರವಿ ಮತ್ತು ಗುರು ಒಟ್ಟಿಗೆ',
        result: 'ಕ್ರೂರ, ಇತರರ ಕೆಲಸ ಮಾಡುವವನು',
        rashi: dyTogetherRashi('Sun', 'Jupiter'), planets: ['ರವಿ', 'ಗುರು'],
      ));
    }
    if (dyAreTogether('Sun', 'Venus')) {
      yogas.add(Yoga(
        shloka: 'ಶುಕ್ರೇಣ ರಂಗಾಯುಧ್ಯೆ ರ್ಲಸ್ವಂ',
        name: 'ರವಿ-ಶುಕ್ರ ಯೋಗ (ದ್ವಿ ೧)',
        description: 'ರವಿ ಮತ್ತು ಶುಕ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ರಂಗಭೂಮಿ/ಆಯುಧಗಳಿಂದ ಹಣ ಗಳಿಸುವವನು',
        rashi: dyTogetherRashi('Sun', 'Venus'), planets: ['ರವಿ', 'ಶುಕ್ರ'],
      ));
    }
    if (dyAreTogether('Sun', 'Saturn')) {
      yogas.add(Yoga(
        shloka: 'ರವಿಜೇನ ಧಾತುಕುಶಲಂ ಭಾಂಡಪ್ರಕಾರೇಷು ವಾ',
        name: 'ರವಿ-ಶನಿ ಯೋಗ (ದ್ವಿ ೧)',
        description: 'ರವಿ ಮತ್ತು ಶನಿ ಒಟ್ಟಿಗೆ',
        result: 'ಲೋಹ ಅಥವಾ ಮಡಿಕೆಗಳ ಕೆಲಸದಲ್ಲಿ ಕುಶಲ',
        rashi: dyTogetherRashi('Sun', 'Saturn'), planets: ['ರವಿ', 'ಶನಿ'],
      ));
    }

    // ═══ DY Shloka 2: Moon combinations ═══
    if (dyAreTogether('Moon', 'Mars')) {
      yogas.add(Yoga(
        shloka: 'ಕೂಟಾಸವಕುಂಭಪಣ್ಯಮಶಿವಂ ಮಾತುಃ ಸವಕ್ರ ಶಶೀ',
        name: 'ಚಂದ್ರ-ಕುಜ ಯೋಗ (ದ್ವಿ ೨)',
        description: 'ಚಂದ್ರ ಮತ್ತು ಕುಜ ಒಟ್ಟಿಗೆ',
        result: 'ಮೋಸಗಾರ, ಮದ್ಯ/ಮಡಿಕೆ ಮಾರುವವನು, ತಾಯಿಗೆ ಅಶುಭ',
        rashi: dyTogetherRashi('Moon', 'Mars'), planets: ['ಚಂದ್ರ', 'ಕುಜ'],
      ));
    }
    if (dyAreTogether('Moon', 'Mercury')) {
      yogas.add(Yoga(
        shloka: 'ಸಜ್ಞ ಪ್ರಶ್ನಿತವಾಕ್ಯಮರ್ಥನಿಪುಣಂ ಸೌಭಾಗ್ಯಕೀರ್ತ್ಯನ್ವಿತಮ್',
        name: 'ಚಂದ್ರ-ಬುಧ ಯೋಗ (ದ್ವಿ ೨)',
        description: 'ಚಂದ್ರ ಮತ್ತು ಬುಧ ಒಟ್ಟಿಗೆ',
        result: 'ವಿನಯದ ಮಾತು, ಹಣಕಾಸಿನಲ್ಲಿ ನಿಪುಣ, ಸೌಭಾಗ್ಯ, ಕೀರ್ತಿವಂತ',
        rashi: dyTogetherRashi('Moon', 'Mercury'), planets: ['ಚಂದ್ರ', 'ಬುಧ'],
      ));
    }
    if (dyAreTogether('Moon', 'Jupiter')) {
      yogas.add(Yoga(
        shloka: 'ವಿಕ್ರಾಂತಂ ಕುಲಮುಖ್ಯಮಸ್ಥಿರಮತಿಂ ವಿತ್ತೇಶ್ವರಂ ಸಾಂಗಿರಾ',
        name: 'ಚಂದ್ರ-ಗುರು ಯೋಗ (ದ್ವಿ ೨)',
        description: 'ಚಂದ್ರ ಮತ್ತು ಗುರು ಒಟ್ಟಿಗೆ',
        result: 'ಪರಾಕ್ರಮಿ, ಕುಲ ಮುಖ್ಯಸ್ಥ, ಚಂಚಲ ಮನಸ್ಸು, ಧನವಂತ',
        rashi: dyTogetherRashi('Moon', 'Jupiter'), planets: ['ಚಂದ್ರ', 'ಗುರು'],
      ));
    }
    if (dyAreTogether('Moon', 'Venus')) {
      yogas.add(Yoga(
        shloka: 'ವಸ್ತ್ರಾಣಾಂ ಸಸಿತಃ ಕ್ರಯಾದಿಕುಶಲಂ',
        name: 'ಚಂದ್ರ-ಶುಕ್ರ ಯೋಗ (ದ್ವಿ ೨)',
        description: 'ಚಂದ್ರ ಮತ್ತು ಶುಕ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ವಸ್ತ್ರಗಳ ವ್ಯಾಪಾರದಲ್ಲಿ ಕುಶಲ',
        rashi: dyTogetherRashi('Moon', 'Venus'), planets: ['ಚಂದ್ರ', 'ಶುಕ್ರ'],
      ));
    }
    if (dyAreTogether('Moon', 'Saturn')) {
      yogas.add(Yoga(
        shloka: 'ಸಾರ್ಕಿ: ಪುನರ್ಭೂಸುತಮ್',
        name: 'ಚಂದ್ರ-ಶನಿ ಯೋಗ (ದ್ವಿ ೨)',
        description: 'ಚಂದ್ರ ಮತ್ತು ಶನಿ ಒಟ್ಟಿಗೆ',
        result: 'ವಿಧವೆಯ ಮಗ',
        rashi: dyTogetherRashi('Moon', 'Saturn'), planets: ['ಚಂದ್ರ', 'ಶನಿ'],
      ));
    }

    // ═══ DY Shloka 3: Mars combinations ═══
    if (dyAreTogether('Mars', 'Mercury')) {
      yogas.add(Yoga(
        shloka: 'ಮೂಲಾದಿಸ್ನೇಹಕೂಟೈರ್ವ್ಯವಹರತಿ ವಣಿಸ್ಟಾಹುಯೋದ್ಧಾ ಸಸೌಮ್ಯ',
        name: 'ಕುಜ-ಬುಧ ಯೋಗ (ದ್ವಿ ೩)',
        description: 'ಕುಜ ಮತ್ತು ಬುಧ ಒಟ್ಟಿಗೆ',
        result: 'ಬೇರು/ಎಣ್ಣೆ ವ್ಯಾಪಾರಿ, ಮಲ್ಲಯುದ್ಧ ಮಾಡುವವನು',
        rashi: dyTogetherRashi('Mars', 'Mercury'), planets: ['ಕುಜ', 'ಬುಧ'],
      ));
    }
    if (dyAreTogether('Mars', 'Jupiter')) {
      yogas.add(Yoga(
        shloka: 'ಪುರ್ಯಧ್ಯಕ್ಷಃ ಸಜೀವೇ ಭವತಿ ನರಪತಿಪ್ರಾಪ್ತವಿತ್ತೋ ದ್ವಿಜೋ ವಾ',
        name: 'ಕುಜ-ಗುರು ಯೋಗ (ದ್ವಿ ೩)',
        description: 'ಕುಜ ಮತ್ತು ಗುರು ಒಟ್ಟಿಗೆ',
        result: 'ನಗರಾಧ್ಯಕ್ಷ / ರಾಜನಿಂದ ಹಣ ಪಡೆಯುವ ಬ್ರಾಹ್ಮಣ',
        rashi: dyTogetherRashi('Mars', 'Jupiter'), planets: ['ಕುಜ', 'ಗುರು'],
      ));
    }
    if (dyAreTogether('Mars', 'Venus')) {
      yogas.add(Yoga(
        shloka: 'ಗೋಪೋ ಮಲ್ಲೋsಥ ದಕ್ಷಃ ಪರಯುವತಿರತೋ ದ್ಯೋತಕೃತ್ ಸಾಸುರೇ',
        name: 'ಕುಜ-ಶುಕ್ರ ಯೋಗ (ದ್ವಿ ೩)',
        description: 'ಕುಜ ಮತ್ತು ಶುಕ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ಗೋಪಾಲಕ, ಮಲ್ಲ, ದಕ್ಷ, ಪರಸ್ತ್ರೀ ರತ, ಜೂಜುಕೋರ',
        rashi: dyTogetherRashi('Mars', 'Venus'), planets: ['ಕುಜ', 'ಶುಕ್ರ'],
      ));
    }
    if (dyAreTogether('Mars', 'Saturn')) {
      yogas.add(Yoga(
        shloka: 'ದುಃಖಾರ್ತೋsಸತ್ಯಸಂಧಃ ಸಸವಿತೃತನಯೇ ಭೂಮಿಜೇ ನಿಂದಿತಶ್ಚ',
        name: 'ಕುಜ-ಶನಿ ಯೋಗ (ದ್ವಿ ೩)',
        description: 'ಕುಜ ಮತ್ತು ಶನಿ ಒಟ್ಟಿಗೆ',
        result: 'ದುಃಖಿ, ಸುಳ್ಳುಗಾರ, ನಿಂದೆಗೆ ಒಳಗಾಗುವವನು',
        rashi: dyTogetherRashi('Mars', 'Saturn'), planets: ['ಕುಜ', 'ಶನಿ'],
      ));
    }

    // ═══ DY Shloka 4: Mercury & Jupiter combinations ═══
    if (dyAreTogether('Mercury', 'Jupiter')) {
      yogas.add(Yoga(
        shloka: 'ಸೌಮ್ಯ ರಂಗಚರೋ ಬೃಹಸ್ಪತಿಯುತೇ ಗೀತಪ್ರಿಯೋ ನೃತ್ಯವಿ',
        name: 'ಬುಧ-ಗುರು ಯೋಗ (ದ್ವಿ ೪)',
        description: 'ಬುಧ ಮತ್ತು ಗುರು ಒಟ್ಟಿಗೆ',
        result: 'ರಂಗಭೂಮಿಯಲ್ಲಿರುವವನು, ಗೀತಪ್ರಿಯ, ನೃತ್ಯ ಬಲ್ಲವನು',
        rashi: dyTogetherRashi('Mercury', 'Jupiter'), planets: ['ಬುಧ', 'ಗುರು'],
      ));
    }
    if (dyAreTogether('Mercury', 'Venus')) {
      yogas.add(Yoga(
        shloka: 'ದ್ವಾಲ್ಮೀ ಭೂಗಣಪಃ ಸಿತೇನ ಮೃದುನಾ',
        name: 'ಬುಧ-ಶುಕ್ರ ಯೋಗ (ದ್ವಿ ೪)',
        description: 'ಬುಧ ಮತ್ತು ಶುಕ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ವಾಕ್ಚಾತುರ್ಯವುಳ್ಳವನು, ಭೂಮಿ/ಜನರ ಒಡೆಯ',
        rashi: dyTogetherRashi('Mercury', 'Venus'), planets: ['ಬುಧ', 'ಶುಕ್ರ'],
      ));
    }
    if (dyAreTogether('Mercury', 'Saturn')) {
      yogas.add(Yoga(
        shloka: 'ಮಾಯಾಪಟುರ್ಲಂಘಕಃ',
        name: 'ಬುಧ-ಶನಿ ಯೋಗ (ದ್ವಿ ೪)',
        description: 'ಬುಧ ಮತ್ತು ಶನಿ ಒಟ್ಟಿಗೆ',
        result: 'ಮಾಯೆಯಲ್ಲಿ ನಿಪುಣ, ಲಂಘಕ',
        rashi: dyTogetherRashi('Mercury', 'Saturn'), planets: ['ಬುಧ', 'ಶನಿ'],
      ));
    }
    if (dyAreTogether('Jupiter', 'Venus')) {
      yogas.add(Yoga(
        shloka: 'ಸದ್ವಿದ್ಯೋ ಧನದಾರವಾನ್ ಬಹುಗುಣಃ ಶುಕ್ರೇಣ ಯುಕ್ತ ಗುರೌ',
        name: 'ಗುರು-ಶುಕ್ರ ಯೋಗ (ದ್ವಿ ೪)',
        description: 'ಗುರು ಮತ್ತು ಶುಕ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ಒಳ್ಳೆಯ ವಿದ್ಯೆ, ಹಣ, ಹೆಂಡತಿ, ಬಹು ಗುಣ',
        rashi: dyTogetherRashi('Jupiter', 'Venus'), planets: ['ಗುರು', 'ಶುಕ್ರ'],
      ));
    }
    if (dyAreTogether('Jupiter', 'Saturn')) {
      yogas.add(Yoga(
        shloka: 'ಸ್ಮಶುಕರೋsಸಿತೇನ ಘಟಕೃದ್ದಾ ತಾನ್ನ ಕಾರೋsಪಿ ವಾ',
        name: 'ಗುರು-ಶನಿ ಯೋಗ (ದ್ವಿ ೪)',
        description: 'ಗುರು ಮತ್ತು ಶನಿ ಒಟ್ಟಿಗೆ',
        result: 'ಕ್ಷೌರಿಕ, ಮಡಿಕೆ ಮಾಡುವವನು / ಅಡುಗೆ ಮಾಡುವವನು',
        rashi: dyTogetherRashi('Jupiter', 'Saturn'), planets: ['ಗುರು', 'ಶನಿ'],
      ));
    }

    // ═══ DY Shloka 5: Saturn and Venus combination ═══
    if (dyAreTogether('Saturn', 'Venus')) {
      yogas.add(Yoga(
        shloka: 'ಅಸಿತಸಿತಸಮಾಗಮೇಽಲ್ಪಚಕ್ಷುರ್ಯುವತಿಜನಾಶ್ರಯಸಂಪ್ರವೃದ್ಧವಿತ್ತಃ । ಭವತಿ ಚ ಲಿಪಿಪುಸ್ತಚಿತ್ರವೇತ್ತಾ',
        name: 'ಶನಿ-ಶುಕ್ರ ಯೋಗ (ದ್ವಿ ೫)',
        description: 'ಶನಿ ಮತ್ತು ಶುಕ್ರ ಒಟ್ಟಿಗೆ',
        result: 'ಸಣ್ಣ ಕಣ್ಣು, ಸ್ತ್ರೀಯರ ಆಶ್ರಯದಿಂದ ಹಣ, ಬರವಣಿಗೆ/ಪುಸ್ತಕ/ಚಿತ್ರಕಲೆ ಬಲ್ಲವನು',
        rashi: dyTogetherRashi('Saturn', 'Venus'), planets: ['ಶನಿ', 'ಶುಕ್ರ'],
      ));
    }

    // ═══════════════════════════════════════════════════
    // Chapter 15: ಪ್ರವ್ರಜ್ಯಾಯೋಗಾಧ್ಯಾಯ (Pravrajya Yogadhyaya - Ascetic Yogas)
    // ═══════════════════════════════════════════════════

    // ═══ PY Shloka 1 & 2: Four or more strong planets in one Rashi ═══
    final pyRashiCounts = <int, List<String>>{};
    for (final e in allPLons.entries) {
      if (e.key == 'Rahu' || e.key == 'Ketu') continue;
      final r = _rashiOf(e.value);
      pyRashiCounts.putIfAbsent(r, () => <String>[]).add(e.key);
    }
    
    for (final entry in pyRashiCounts.entries) {
      if (entry.value.length >= 4) {
        String? strongestPlanet;
        for (final p in entry.value) {
          if (isStrong(p)) {
            strongestPlanet = p;
            break;
          }
        }
        
        if (strongestPlanet != null) {
          final pyDikshaMap = <String, String>{
            'Mars': 'ಶಾಕ್ಯ',
            'Mercury': 'ಆಜೀವಕ',
            'Jupiter': 'ಭಿಕ್ಷು',
            'Moon': 'ವೃದ್ಧ ಶ್ರಾವಕ',
            'Venus': 'ಚರಕ',
            'Sun': 'ವನ್ಯಾಶನ',
            'Saturn': 'ನಿರ್ಗ್ರಂಥ'
          };
          
          final sanyasaType = pyDikshaMap[strongestPlanet] ?? 'ಸನ್ಯಾಸ';
          
          bool pyCombust = false;
          if (strongestPlanet != 'Sun') {
             final pDist = (allPLons[strongestPlanet]! - sun).abs() % 360;
             final shortestDist = pDist > 180 ? 360 - pDist : pDist;
             if (shortestDist < 10) pyCombust = true; 
          }
          
          bool pyDefeated = false;
          if (strongestPlanet != 'Sun' && strongestPlanet != 'Moon') {
            for (final p2 in entry.value) {
               if (p2 != strongestPlanet && p2 != 'Sun' && p2 != 'Moon' && isStrong(p2)) {
                 pyDefeated = true;
               }
            }
          }
          
          bool pyAspected = false;
          for (final pAspect in allPLons.entries) {
            if (!entry.value.contains(pAspect.key)) {
               if ((_rashiOf(pAspect.value) + 6) % 12 == entry.key) pyAspected = true;
            }
          }

          String pyResult = '$sanyasaType ದೀಕ್ಷೆ';
          String pyDesc = '${entry.value.map((e) => _knPlanets[e]).join(', ')} ಒಂದೇ ರಾಶಿಯಲ್ಲಿ. ಬಲಶಾಲಿ ${_knPlanets[strongestPlanet]}ನಿಂದ $sanyasaType ಸನ್ಯಾಸ.';
          
          if (pyCombust) {
            pyResult = 'ಸನ್ಯಾಸಿಗಳ ಮೇಲೆ ಭಕ್ತಿ';
            pyDesc += '\nಗ್ರಹವು ಅಸ್ತಂಗತವಾಗಿರುವುದರಿಂದ, ದೀಕ್ಷೆ ಸಿಗುವುದಿಲ್ಲ, ಭಕ್ತಿ ಮಾತ್ರ.';
          } else if (pyAspected) {
            pyResult = 'ದೀಕ್ಷೆಯನ್ನು ಬೇಡುವವನು';
            pyDesc += '\nಇತರ ಗ್ರಹರ ದೃಷ್ಟಿಯಿರುವುದರಿಂದ ಕೇವಲ ದೀಕ್ಷೆಯನ್ನು ಬೇಡುತ್ತಾನೆ.';
          } else if (pyDefeated) {
            pyResult = 'ದೀಕ್ಷೆ ಪಡೆದು ಬಿಡುವವನು';
            pyDesc += '\nಗ್ರಹಯುದ್ಧದಲ್ಲಿ ಸೋತಿರುವುದರಿಂದ ದೀಕ್ಷೆ ಪಡೆದ ನಂತರ ಸನ್ಯಾಸ ಬಿಡುತ್ತಾನೆ.';
          }

          yogas.add(Yoga(
            shloka: 'ಏಕಸ್ಥೆಶ್ಚತುರಾದಿಭಿರ್ಬಲಯುತೈರ್ಜಾತಾಃ ಪೃಥರ್ಯಗೈ... ರವಿಲುಪ್ತಕರದೀಕ್ಷಿತಾ ಬಲಿಭಿಸ್ತತಭಕ್ತಯೋ',
            name: 'ಪ್ರವ್ರಜ್ಯಾ ಯೋಗ (ಪ್ರ ೧,೨)',
            description: pyDesc,
            result: pyResult,
            rashi: entry.key, planets: entry.value.map((e) => _knPlanets[e]!).toList(),
          ));
        }
      }
    }

    // ═══ PY Shloka 3: Lagna lord aspects Saturn or Saturn aspects weak Lagna lord ═══
    final pyLagLord = rashiLords[lagRashi];
    final pyLagLordR = _rashiOf(allPLons[pyLagLord]!);
    final pySatR = _rashiOf(allPLons['Saturn']!);
    
    bool pyLagLordAspected = false;
    for (final e in allPLons.entries) {
      if (e.key != pyLagLord && e.key != 'Saturn' && (_rashiOf(e.value) + 6) % 12 == pyLagLordR) pyLagLordAspected = true;
    }
    
    bool pyLagLordAspectsSaturn = (pyLagLordR + 6) % 12 == pySatR;
    bool pySatAspectsLagLord = (pySatR + 6) % 12 == pyLagLordR;
    bool pyLagLordWeak = !isStrong(pyLagLord);
    
    if ((!pyLagLordAspected && pyLagLordAspectsSaturn) || (pySatAspectsLagLord && pyLagLordWeak)) {
       yogas.add(Yoga(
          shloka: 'ಜಗ್ಗೇಶೋsನೈರ್ಯದೃಷ್ಟೋರ್ಕಪುತ್ರಂ ಪಶ್ಯತ್ಯಾರ್ಕಿಜ್ರನ್ಮಪಂ ವಾ ಬಲೋನಮ್',
          name: 'ಶನಿ ದೃಷ್ಟಿ ಸನ್ಯಾಸ (ಪ್ರ ೩)',
          description: (!pyLagLordAspected && pyLagLordAspectsSaturn) 
            ? 'ಲಗ್ನಾಧಿಪತಿಯು ಶನಿಯನ್ನು ನೋಡುತ್ತಿದ್ದಾನೆ (ಇತರ ದೃಷ್ಟಿ ಇಲ್ಲ)' 
            : 'ಶನಿಯು ಬಲಹೀನ ಲಗ್ನಾಧಿಪತಿಯನ್ನು ನೋಡುತ್ತಿದ್ದಾನೆ',
          result: 'ಸನ್ಯಾಸ ಯೋಗ',
          rashi: lagRashi, planets: [_knPlanets[pyLagLord]!, 'ಶನಿ'],
        ));
    }
    
    // Moon in Saturn Drekkana, Mars/Saturn Navamsha, aspected by Saturn
    // Drekkana rashi: 1st drek = same sign, 2nd = +4, 3rd = +8
    final pyMoonDrekNum = _drekkanaNum(moonLon);
    final pyMoonDrek = (moonR2 + (pyMoonDrekNum - 1) * 4) % 12;
    final pyMoonNav = _d9Rashi(moonLon);
    final pySatR2 = _rashiOf(allPLons['Saturn']!);
    final pySatAspMoon = (pySatR2 + 6) % 12 == moonR2 || (pySatR2 + 2) % 12 == moonR2 || (pySatR2 + 9) % 12 == moonR2;
    
    if (rashiLords[pyMoonDrek] == 'Saturn' && (rashiLords[pyMoonNav] == 'Mars' || rashiLords[pyMoonNav] == 'Saturn') && pySatAspMoon) {
       yogas.add(Yoga(
          shloka: 'ದೀಕ್ಷಾಂ ಪ್ರಾಪ್ಪೋತ್ಯಾರ್ಕಿದೃಕ್ಕಾಣಸಂಸ್ಥೆ ಭೌಮಾರ್ಕ್ಯಂಶೇ ಸೌರದೃಷ್ಟೇ ಚ ಚಂದ್ರೇ',
          name: 'ಚಂದ್ರ-ಶನಿ ಸನ್ಯಾಸ ಯೋಗ (ಪ್ರ ೩)',
          description: 'ಚಂದ್ರನು ಶನಿಯ ದ್ರೇಕ್ಕಾಣದಲ್ಲಿ, ಕುಜ/ಶನಿಯ ನವಾಂಶದಲ್ಲಿದ್ದು ಶನಿ ದೃಷ್ಟಿ',
          result: 'ಸನ್ಯಾಸ ದೀಕ್ಷೆ',
          rashi: moonR2, planets: ['ಚಂದ್ರ', 'ಶನಿ'],
        ));
    }

    // ═══ PY Shloka 4: Rajayoga combinations for Ascetics/Pilgrimage makers ═══
    bool pySatAspJup = (pySatR2 + 6) % 12 == _rashiOf(allPLons['Jupiter']!) || (pySatR2 + 2) % 12 == _rashiOf(allPLons['Jupiter']!) || (pySatR2 + 9) % 12 == _rashiOf(allPLons['Jupiter']!);
    bool pySatAspMoon2 = pySatAspMoon;
    bool pySatAspLag = (pySatR2 + 6) % 12 == lagRashi || (pySatR2 + 2) % 12 == lagRashi || (pySatR2 + 9) % 12 == lagRashi;
    bool pyJupIn9 = ((_rashiOf(allPLons['Jupiter']!) - lagRashi) % 12) + 1 == 9;
    
    if (pySatAspJup && pySatAspMoon2 && pySatAspLag && pyJupIn9) {
      yogas.add(Yoga(
          shloka: 'ಸುರಗುರುಶಶಿಹೋರಾಸ್ವಾರ್ಕಿದೃಷ್ಟಾಸು ಧರ್ಮೇ ಗುರುರಥ ನೃಪತೀನಾಂ',
          name: 'ತೀರ್ಥಕ್ಷೇತ್ರ ನಿರ್ಮಾಣ ಯೋಗ (ಪ್ರ ೪)',
          description: 'ಗುರು, ಚಂದ್ರ, ಲಗ್ನದ ಮೇಲೆ ಶನಿಯ ದೃಷ್ಟಿ + 9ರಲ್ಲಿ ಗುರು',
          result: 'ತೀರ್ಥಕ್ಷೇತ್ರಗಳನ್ನು ನಿರ್ಮಿಸುವ ಪುಣ್ಯಾತ್ಮ (ರಾಜಯೋಗವಿದ್ದರೆ)',
          rashi: lagRashi, planets: ['ಗುರು', 'ಚಂದ್ರ', 'ಶನಿ'],
        ));
    }
    
    bool pySatIn9 = ((pySatR2 - lagRashi) % 12) + 1 == 9;
    bool pySatUnaspected = true;
    for (final e in allPLons.entries) {
      if (e.key != 'Saturn' && (_rashiOf(e.value) + 6) % 12 == pySatR2) pySatUnaspected = false;
    }
    
    if (pySatIn9 && pySatUnaspected) {
      yogas.add(Yoga(
          shloka: 'ನವಮಭವನಸಂಸ್ಥೆ ಮಂದೇಗೇsನೈರದೃಷ್ಟೇ ಭವತಿ ನರಪಯೋಗೇ ದೀಕ್ಷಿತಃ',
          name: 'ರಾಜ ಸನ್ಯಾಸ ಯೋಗ (ಪ್ರ ೪)',
          description: '9ನೇ ಮನೆಯಲ್ಲಿ ಶನಿ + ಇತರ ಗ್ರಹರ ದೃಷ್ಟಿಯಿಲ್ಲ',
          result: 'ಮಹಾರಾಜನು ಸನ್ಯಾಸ ದೀಕ್ಷೆಯನ್ನು ಪಡೆಯುತ್ತಾನೆ (ರಾಜಯೋಗವಿದ್ದರೆ)',
          rashi: pySatR2, planets: ['ಶನಿ'],
        ));
    }

    return yogas;
  }
}

class Yoga {
  final String shloka;
  final String name;
  final String description;
  final String result;
  final int rashi; // 0-11 index of the rashi this yoga applies to
  final List<String> planets; // planet names involved
  final int refLagna; // 0-11: which reference lagna this yoga was detected from (-1 = actual lagna)
  const Yoga({required this.shloka, required this.name, required this.description, required this.result, this.rashi = -1, this.planets = const [], this.refLagna = -1});
}
