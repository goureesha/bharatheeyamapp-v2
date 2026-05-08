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
    final moonWaning = moonLon > sun; // simplified waning check
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
    final jupOdd = _isOddSign(jupHouse == 0 ? _rashiOf(jup) : _rashiOf(jup)); // safe fallback
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
    if (satNavR18 == merNavR18 && marsNavR18 == merNavR18) {
      yogas.add(Yoga(
        shloka: 'ಸೌಮ್ಯರ್ಕ್ಷಾಂಶೇ ರವಿಜರುಧಿರೌ ಚೇತ್ಸದಂತೋsತ್ರ ಜಾತಃ',
        name: 'ಸದಂತ ಜನನ ಯೋಗ (೧೮)',
        description: 'ಶನಿ ಮತ್ತು ಕುಜ ಬುಧನ ನವಾಂಶದಲ್ಲಿ (${_rashiNames[merNavR18]})',
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
    if (lagRashi == 9) {
      final sACap = satR2 == 9 || (satR2 + 6) % 12 == 9;
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
