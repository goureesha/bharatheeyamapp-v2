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
    final startRashi = (rashi % 4) == 0 ? 0 : (rashi % 4) == 1 ? 3 : (rashi % 4) == 2 ? 6 : 9;
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
  const Yoga({required this.shloka, required this.name, required this.description, required this.result, this.rashi = -1, this.planets = const []});
}
