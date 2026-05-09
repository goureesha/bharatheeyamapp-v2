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
  static List<Yoga> detectAll(KundaliResult chart, {bool includeNavamsha = false}) {
    final allYogas = <Yoga>[];
    final seen = <String>{};

    for (int ref = 0; ref < 12; ref++) {
      final yogas = detect(chart, lagnaRashi: ref);
      for (final y in yogas) {
        // Cross-lagna dedup: same name+result+rashi = duplicate
        final key = '${y.name}|${y.result}|${y.rashi}';
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

    // ── ಛಾಯಾ (Navamsha) pass ──
    if (includeNavamsha) {
      final navChart = _toNavamshaChart(chart);
      final navSeen = <String>{};
      for (int ref = 0; ref < 12; ref++) {
        final yogas = detect(navChart, lagnaRashi: ref);
        for (final y in yogas) {
          final rashiKey = '${y.name}|${y.result}|${y.rashi}';
          if (seen.contains(rashiKey)) continue;
          final key = 'CHAYA|${y.name}|${y.result}|${y.rashi}';
          if (!navSeen.contains(key)) {
            navSeen.add(key);
            allYogas.add(Yoga(
              shloka: y.shloka,
              name: '\u0c9b\u0cbe\u0caf\u0cbe: ${y.name}',
              description: '\u27ea${_rashiNamesShort[ref]} \u0cb2\u0c97\u0ccd\u0ca8 \u2014 \u0ca8\u0cb5\u0cbe\u0c82\u0cb6 \u0c86\u0ca7\u0cbe\u0cb0\u27eb\n${y.description}',
              result: '${y.result} (\u0c9b\u0cbe\u0caf\u0cbe)',
              rashi: y.rashi,
              planets: y.planets,
              refLagna: ref,
            ));
          }
        }
      }
    }

    return allYogas;
  }


  /// Convert a chart to navamsha-equivalent longitudes.
  static KundaliResult _toNavamshaChart(KundaliResult chart) {
    final navPlanets = <String, PlanetInfo>{};
    for (final e in chart.planets.entries) {
      final navR = _d9Rashi(e.value.longitude);
      final navLon = navR * 30.0 + 15.0;
      navPlanets[e.key] = PlanetInfo(
        name: e.value.name,
        longitude: navLon,
        speed: e.value.speed,
        nakshatra: e.value.nakshatra,
        pada: e.value.pada,
        rashi: _rashiNames[navR],
        rashiIndex: navR,
        subDrekD1: e.value.subDrekD1,
        subDrekD9: e.value.subDrekD9,
        subDrekD12: e.value.subDrekD12,
        d9OfD9: e.value.d9OfD9,
        isCombust: e.value.isCombust,
      );
    }
    final lagLon = chart.bhavas.isNotEmpty ? chart.bhavas[0] : 0.0;
    final navLagR = _d9Rashi(lagLon);
    final navBhavas = List<double>.generate(12, (i) => ((navLagR + i) * 30.0 + 15.0) % 360);
    return KundaliResult(
      planets: navPlanets,
      bhavas: navBhavas,
      shadbala: chart.shadbala,
      panchang: chart.panchang,
      dashas: chart.dashas,
      advSphutas: chart.advSphutas,
    );
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
    }
    
    if (girlYoga1 || girlYoga2) {
      final reasons = <String>[];
      if (girlYoga1) reasons.add('ಲಗ್ನ, ರವಿ, ಗುರು, ಚಂದ್ರ ಸಮ ರಾಶಿ & ನವಾಂಶದಲ್ಲಿ ಬಲಶಾಲಿ');
      if (girlYoga2) reasons.add('ಚಂದ್ರ, ಶುಕ್ರ, ಕುಜ ಸಮ ರಾಶಿಯಲ್ಲಿ');
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
    final jk17MalIn7L = <String>[]; // from lagna
    final jk17MalIn4L = <String>[]; // from lagna
    for (final e in malLons.entries) {
      final hFM = ((_rashiOf(e.value) - moonR2) % 12) + 1;
      if (hFM == 7) jk17MalIn7.add(_knPlanets[e.key]!);
      if (hFM == 4) jk17MalIn4.add(_knPlanets[e.key]!);
      final hFL = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
      if (hFL == 7) jk17MalIn7L.add(_knPlanets[e.key]!);
      if (hFL == 4) jk17MalIn4L.add(_knPlanets[e.key]!);
    }
    if (jk17MalIn7.isNotEmpty || jk17MalIn4.isNotEmpty || jk17MalIn7L.isNotEmpty || jk17MalIn4L.isNotEmpty) {
      final details = <String>[];
      if (jk17MalIn7.isNotEmpty) details.add('ಚಂದ್ರನಿಂದ 7ನೇ: ${jk17MalIn7.join(",")}');
      if (jk17MalIn4.isNotEmpty) details.add('ಚಂದ್ರನಿಂದ 4ನೇ: ${jk17MalIn4.join(",")}');
      if (jk17MalIn7L.isNotEmpty) details.add('ಲಗ್ನದಿಂದ 7ನೇ: ${jk17MalIn7L.join(",")}');
      if (jk17MalIn4L.isNotEmpty) details.add('ಲಗ್ನದಿಂದ 4ನೇ: ${jk17MalIn4L.join(",")}');
      yogas.add(Yoga(
        shloka: 'ಪಾಪೈಶ್ಚಂದ್ರಸ್ಮರಸುಖಗತೈಃ ಕೇಶಮಾಹುರ್ಜನನ್ಯಾ:',
        name: 'ಮಾತೃ ಕಷ್ಟ ಯೋಗ (ಜಕ ೧೭)',
        description: details.join('\n'),
        result: 'ತಾಯಿಗೆ ಹೆರಿಗೆಯಲ್ಲಿ ಕಷ್ಟ',
        rashi: moonR2, planets: ['ಚಂದ್ರ', ...jk17MalIn7, ...jk17MalIn4, ...jk17MalIn7L, ...jk17MalIn4L],
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

    // ═══ JK Shloka 20: Direction of delivery room ═══
    final jk20DirMap = <int, String>{
      0: 'ಪೂರ್ವ', 3: 'ಪೂರ್ವ', 6: 'ಪೂರ್ವ', 7: 'ಪೂರ್ವ', 10: 'ಪೂರ್ವ',
      2: 'ಉತ್ತರ', 5: 'ಉತ್ತರ', 8: 'ಉತ್ತರ', 11: 'ಉತ್ತರ',
      1: 'ಪಶ್ಚಿಮ',
      4: 'ದಕ್ಷಿಣ', 9: 'ದಕ್ಷಿಣ',
    };

    // ═══ JK Shloka 21: Bed direction ═══
    final jk21H6 = ((lagRashi + 5) % 12);
    final jk21H8 = ((lagRashi + 7) % 12);
    final jk21H9 = ((lagRashi + 8) % 12);
    final jk21H12 = ((lagRashi + 11) % 12);

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

    // ═══ JK Shloka 23: Body & color of child ═══
    final jk23LagNavLord = rashiLords[_d9Rashi(lag)];
    final jk23MoonNavLord = rashiLords[_d9Rashi(moonLon)];
    final jk23ColorMap = <String, String>{
      'Sun': 'ಕೆಂಪು', 'Moon': 'ಬಿಳಿ', 'Mars': 'ಕೆಂಪು', 'Mercury': 'ಹಸಿರು',
      'Jupiter': 'ಹೊಂಬಣ್ಣ', 'Venus': 'ಬಿಳಿ/ಹೊಳೆಯುವ', 'Saturn': 'ಕಪ್ಪು',
    };

    // ═══ JK Shloka 24: Body parts mapping (informational) ═══

    // ═══ JK Shloka 25: Wound or mole marks ═══
    for (final e in allPLons.entries) {
      final pRashi = _rashiOf(e.value);
      final pDrekNum = _drekkanaNum(e.value); // 1, 2, or 3 based on degree
      final pDrekRashi = (pRashi + (pDrekNum - 1) * 4) % 12;
      // Check if this drekkana falls within lagna's 3 drekkanas
      for (int drek = 0; drek < 3; drek++) {
        final lagDrekR = (lagRashi + drek * 4) % 12;
        if (pDrekRashi == lagDrekR) {
          final isMal = {'Sun','Mars','Saturn','Rahu','Ketu'}.contains(e.key);
          final inOwnNav = _d9Rashi(e.value) == pRashi;
          final isSthira25 = pDrekRashi == 1 || pDrekRashi == 4 || pDrekRashi == 7 || pDrekRashi == 10;
          final markType = isMal ? 'ಗಾಯ ಗುರುತು' : 'ಮಚ್ಚೆ';
          final origin = (inOwnNav || isSthira25) ? 'ಹುಟ್ಟಿನಿಂದ' : 'ನಂತರ';
          yogas.add(Yoga(
            shloka: 'ತಸ್ಮಿನ್ ಪಾಪಯುತೇ ವ್ರಣಃ ಶುಭಯುತೇ ದೃಷ್ಟೇ ಲಕ್ಷಾದಿಶೇತ್',
            name: '$markType (ಜಕ ೨೫)',
            description: '${_knPlanets[e.key]} ${_rashiNames[pRashi]} ${pDrekNum}ನೇ ದ್ರೇಕ್ಕಾಣ (${_rashiNames[pDrekRashi]})\n$origin ಬಂದ $markType',
            result: '$origin $markType',
            rashi: pDrekRashi, planets: [_knPlanets[e.key]!],
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

    // ═══ CY Shloka 2: Adhi Yoga (Benefics in 6, 7, 8 from Moon AND Lagna) ═══
    bool cy2BenIn6M = false, cy2BenIn7M = false, cy2BenIn8M = false;
    bool cy2BenIn6L = false, cy2BenIn7L = false, cy2BenIn8L = false;
    for (final e in allPLons.entries) {
      if ({'Jupiter', 'Venus', 'Mercury'}.contains(e.key)) {
        final hM = ((_rashiOf(e.value) - moonR2) % 12) + 1;
        if (hM == 6) cy2BenIn6M = true;
        if (hM == 7) cy2BenIn7M = true;
        if (hM == 8) cy2BenIn8M = true;
        final hL = ((_rashiOf(e.value) - lagRashi) % 12) + 1;
        if (hL == 6) cy2BenIn6L = true;
        if (hL == 7) cy2BenIn7L = true;
        if (hL == 8) cy2BenIn8L = true;
      }
    }
    if (cy2BenIn6M || cy2BenIn7M || cy2BenIn8M || cy2BenIn6L || cy2BenIn7L || cy2BenIn8L) {
       final details = <String>[];
       if (cy2BenIn6M || cy2BenIn7M || cy2BenIn8M) {
         final mH = <String>[];
         if (cy2BenIn6M) mH.add('6');
         if (cy2BenIn7M) mH.add('7');
         if (cy2BenIn8M) mH.add('8');
         details.add('ಚಂದ್ರನಿಂದ ${mH.join(",")}ನೇ ಮನೆಯಲ್ಲಿ ಶುಭಗ್ರಹರು');
       }
       if (cy2BenIn6L || cy2BenIn7L || cy2BenIn8L) {
         final lH = <String>[];
         if (cy2BenIn6L) lH.add('6');
         if (cy2BenIn7L) lH.add('7');
         if (cy2BenIn8L) lH.add('8');
         details.add('ಲಗ್ನದಿಂದ ${lH.join(",")}ನೇ ಮನೆಯಲ್ಲಿ ಶುಭಗ್ರಹರು');
       }
       yogas.add(Yoga(
        shloka: 'ಸೌಮ್ಯ ಸ್ಮರಾರಿನಿಧನೇಷ್ಟಧಿಯೋಗ ಇಂದೋಸ್ತಸ್ಮಿಂಶ್ಚಮೂಪಸಚಿವಕ್ಷಿತಿಪಾಲಜನ್ಮ',
        name: 'ಅಧಿಯೋಗ (ಚಾ ೨)',
        description: details.join('\n'),
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
    // Also from lagna
    bool cy3PlanetIn2L = false, cy3PlanetIn12L = false;
    final cy3PlanetsIn2L = <String>[];
    final cy3PlanetsIn12L = <String>[];
    
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
        if (hFromLag == 2) {
          cy3PlanetIn2L = true;
          cy3PlanetsIn2L.add(_knPlanets[e.key]!);
        }
        if (hFromLag == 12) {
          cy3PlanetIn12L = true;
          cy3PlanetsIn12L.add(_knPlanets[e.key]!);
        }
      }
    }

    bool hasSunapha = cy3PlanetIn2 && !cy3PlanetIn12;
    bool hasAnapha = !cy3PlanetIn2 && cy3PlanetIn12;
    bool hasDurudhura = cy3PlanetIn2 && cy3PlanetIn12;
    bool hasKemadruma = !cy3PlanetIn2 && !cy3PlanetIn12 && !cy3PlanetInKendra && !cy3PlanetWithMoon;
    // Lagna-based variants
    bool hasSunaphaL = cy3PlanetIn2L && !cy3PlanetIn12L;
    bool hasAnaphaL = !cy3PlanetIn2L && cy3PlanetIn12L;
    bool hasDurudhuraL = cy3PlanetIn2L && cy3PlanetIn12L;
    
    if (hasSunapha) {
      yogas.add(Yoga(
        shloka: 'ಸ್ವಯಮಧಿಗತವಿತ್ತಃ ಪಾರ್ಥಿವಸ್ತತ್ಸಮೋ ವಾ ಭವತಿ ಹಿ ಸುನಭಾಯಾಂ ಧೀಧನಖ್ಯಾತಿಮಾಂಶ್ಚ',
        name: 'ಸುನಫಾ ಯೋಗ (ಚಾ ೩,೪,೫,೭)',
        description: 'ಚಂದ್ರನಿಂದ 2ನೇ ಮನೆ: ${cy3PlanetsIn2.join(', ')}${cy3PlanetsIn2L.isNotEmpty ? '\nಲಗ್ನದಿಂದ 2ನೇ ಮನೆ: ${cy3PlanetsIn2L.join(', ')}' : ''}',
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
      return lagRashi;
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


    // ═══════════════════════════════════════════════════
    // Chapter 17: ದೃಷ್ಟಿಫಲಾಧ್ಯಾಯ (Drishtiphaladhyaya - Results of Aspects)
    // ═══════════════════════════════════════════════════

    // Helper: does planet aspect targetRashi? (includes special aspects)
    bool ch17Aspects(String aspectingPlanet, int targetRashi) {
      if (!allPLons.containsKey(aspectingPlanet)) return false;
      final aR = _rashiOf(allPLons[aspectingPlanet]!);
      final dist = ((targetRashi - aR) % 12) + 1;
      if (dist == 7) return true;
      if (aspectingPlanet == 'Mars' && (dist == 4 || dist == 8)) return true;
      if (aspectingPlanet == 'Jupiter' && (dist == 5 || dist == 9)) return true;
      if (aspectingPlanet == 'Saturn' && (dist == 3 || dist == 10)) return true;
      return false;
    }

    // Shloka 1-3: Moon in rashi aspected by planets → results
    // Order: Mars, Mercury, Jupiter, Venus, Saturn, Sun (per Niyama 1 "ಕ್ರಮವಾಗಿ")
    final ch17RashiResults = <int, Map<String,String>>{
      0: {'Mars':'ರಾಜ','Mercury':'ಪಂಡಿತ','Jupiter':'ರಾಜನ ಗುಣಗಳುಳ್ಳವನು','Venus':'ಕಳ್ಳ','Saturn':'ದರಿದ್ರ','Sun':'ಸೇವಕ'},
      1: {'Mars':'ದರಿದ್ರ','Mercury':'ಕಳ್ಳ','Jupiter':'ರಾಜಮಾನ್ಯ','Venus':'ರಾಜ','Saturn':'ಧನವಂತ','Sun':'ಸೇವಕ'},
      2: {'Mars':'ಕಬ್ಬಿಣದ ವ್ಯಾಪಾರಿ','Mercury':'ರಾಜ','Jupiter':'ಪಂಡಿತ','Venus':'ನಿರ್ಭೀತ','Saturn':'ನೇಕಾರ','Sun':'ದರಿದ್ರ'},
      3: {'Mars':'ಯೋಧ','Mercury':'ಜ್ಞಾನಿ','Jupiter':'ರಾಜ','Venus':'ಕಬ್ಬಿಣದ ವ್ಯಾಪಾರಿ','Saturn':'ಕಣ್ಣಿನ ರೋಗಿ','Sun':'ದರಿದ್ರ'},
      4: {'Mars':'ಜ್ಯೋತಿಷಿ','Mercury':'ಧನವಂತ','Jupiter':'ರಾಜ','Venus':'ಕ್ಷೌರಿಕ','Saturn':'ರಾಜ','Sun':'ಭೂಮಾಲೀಕ'},
      5: {'Mars':'ಜ್ಯೋತಿಷಿ','Mercury':'ಧನವಂತ','Jupiter':'ರಾಜ','Venus':'ಕ್ಷೌರಿಕ','Saturn':'ರಾಜ','Sun':'ಭೂಮಾಲೀಕ'}, // same as Simha
      6: {'Mars':'ರಾಜ','Mercury':'ಅಕ್ಕಸಾಲಿಗ','Jupiter':'ವ್ಯಾಪಾರಿ','Venus':'ನೀಚ/ದುಷ್ಟ','Saturn':'ನೀಚ/ದುಷ್ಟ','Sun':'ನೀಚ/ದುಷ್ಟ'},
      7: {'Mars':'ರಾಜ','Mercury':'ಅಗಸ','Jupiter':'ಅಂಗವಿಕಲ','Venus':'ದರಿದ್ರ','Saturn':'ರಾಜ','Sun':'ರಾಜ'},
      8: {'Mars':'ದಂಭಿ ಮತ್ತು ಶಠ','Mercury':'ಆಶ್ರಯ ಪಡೆಯುವವನು','Jupiter':'ಆಶ್ರಯ ಪಡೆಯುವವನು','Venus':'ಆಶ್ರಯ ಪಡೆಯುವವನು','Saturn':'ದಂಭಿ ಮತ್ತು ಶಠ','Sun':'ದಂಭಿ ಮತ್ತು ಶಠ'},
      9: {'Mars':'ಬಹುದೊಡ್ಡ ರಾಜ','Mercury':'ರಾಜ','Jupiter':'ಪಂಡಿತ','Venus':'ಧನವಂತ','Saturn':'ದರಿದ್ರ','Sun':'ರಾಜ'},
      10:{'Mars':'ರಾಜ','Mercury':'ರಾಜನಿಗೆ ಸಮಾನ','Jupiter':'ಪರಸ್ತ್ರೀ ನಿರತ','Venus':'ಪಾಪಫಲ','Saturn':'ಪಾಪಫಲ','Sun':'ಪಾಪಫಲ'},
      11:{'Mars':'ಪಾಪಕಾರ್ಯ','Mercury':'ಹಾಸ್ಯಗಾರ','Jupiter':'ರಾಜ','Venus':'ಪಂಡಿತ','Saturn':'ಪಾಪಕಾರ್ಯ','Sun':'ಪಾಪಕಾರ್ಯ'},
    };

    // Check from Moon AND Lagna
    for (final refR in [moonR2, lagRashi]) {
      final refName = refR == moonR2 ? 'ಚಂದ್ರ' : 'ಲಗ್ನ';
      final rashiMap = ch17RashiResults[refR];
      if (rashiMap != null) {
        for (final aspector in ['Sun','Mars','Mercury','Jupiter','Venus','Saturn']) {
          if (aspector == 'Moon') continue;
          if (ch17Aspects(aspector, refR)) {
            final res = rashiMap[aspector];
            if (res != null) {
              yogas.add(Yoga(
                shloka: 'ಚಂದ್ರೇ ಭೂಪಬುಧೇ ನೃಪೋ... (ದೃಷ್ಟಿಫಲಾಧ್ಯಾಯ ೧-೩)',
                name: '$refName ದೃಷ್ಟಿ ಯೋಗ (ದೃ ೧-೩)',
                description: '${_rashiNames[refR]}ದಲ್ಲಿರುವ $refNameನಿಗೆ ${_knPlanets[aspector]} ದೃಷ್ಟಿ',
                result: res,
                rashi: refR, planets: [refName, _knPlanets[aspector]!],
              ));
            }
          }
        }
      }
    }

    // Shloka 4-8: Navamsha-based aspect results
    // Planet order per navamsha lord: Mars, Mercury, Jupiter, Venus, Saturn, Sun → 6 results
    final ch17NavResults = <String, List<String>>{
      'Mars':    ['ರಕ್ಷಕ','ಹಿಂಸೆಯಲ್ಲಿ ಆಸಕ್ತ','ಯುದ್ಧದಲ್ಲಿ ಕುಶಲ','ರಾಜ','ಧನವಂತ','ಜಗಳಗಂಟ'],
      'Venus':   ['ಮೂರ್ಖ','ಪರಸ್ತ್ರೀರತ','ಕಾವ್ಯಜ್ಞ','ಉತ್ತಮ ಕಾವ್ಯ ರಚಿಸುವವನು','ಸುಖಾಪೇಕ್ಷಿ','ಪರರ ಹೆಂಡತಿಯೊಂದಿಗೆ ಸೇರುವವನು'],
      'Mercury': ['ರಂಗಭೂಮಿಯ ಕಲಾವಿದ','ಕಳ್ಳ','ಶ್ರೇಷ್ಠ ಕವಿ','ಮಂತ್ರಿ','ಸಂಗೀತಗಾರ','ಶಿಲ್ಪಕಲೆಯಲ್ಲಿ ನಿಪುಣ'],
      'Moon':    ['ಸಣ್ಣ ಶರೀರದವನು','ಹಣದ ಆಸೆ ಉಳ್ಳವನು','ತಪಸ್ವಿ','ಪ್ರಮುಖ ವ್ಯಕ್ತಿ','ಸ್ತ್ರೀಯರನ್ನು ಪೋಷಿಸುವವನು','ಕಾರ್ಯನಿರತ'],
      'Sun':     ['ಕೋಪಿಷ್ಟ','ರಾಜನಿಗೆ ಪ್ರಿಯವಾದವನು','ನಿಧಿಗೆ ಒಡೆಯ','ಪ್ರಭು','ಮಕ್ಕಳಿಲ್ಲದವನು','ಅತಿ ಹಿಂಸಾತ್ಮಕ ಕೆಲಸ ಮಾಡುವವನು'],
      'Jupiter': ['ಪ್ರಸಿದ್ಧ ಬಲಶಾಲಿ','ಯುದ್ಧದಲ್ಲಿ ಸಲಹೆ ನೀಡುವವನು','ಹಾಸ್ಯ ಬಲ್ಲವನು','ಮಂತ್ರಿ','ಕಾಮರಹಿತ','ವೃದ್ಧರಂತಹ ಗುಣವುಳ್ಳವನು'],
      'Saturn':  ['ಕಡಿಮೆ ಸಂತಾನವುಳ್ಳವನು','ಸಂಪತ್ತಿದ್ದರೂ ದುಃಖಿಸುವವನು','ಮಾನ ಸನ್ಮಾನಗಳಲ್ಲಿ ಆಸಕ್ತ','ತನ್ನ ಕೆಲಸದಲ್ಲಿ ನಿರತ','ದುಷ್ಟ ಸ್ತ್ರೀಯರನ್ನು ಇಷ್ಟಪಡುವವನು','ಜಿಪುಣ'],
    };

    void evaluateCh17Nav(String targetPlanet, double targetLon) {
      final navRashi = _d9Rashi(targetLon);
      final navLord = rashiLords[navRashi];
      final targetKn = _knPlanets[targetPlanet]!;
      final tRashi = _rashiOf(targetLon);

      final aspectors = targetPlanet == 'Moon'
          ? ['Mars','Mercury','Jupiter','Venus','Saturn','Sun']
          : ['Mars','Mercury','Jupiter','Venus','Saturn','Moon'];

      final results = ch17NavResults[navLord];
      if (results != null) {
        for (int i = 0; i < 6; i++) {
          final aspector = aspectors[i];
          if (ch17Aspects(aspector, tRashi) || (aspector == 'Moon' && _rashiOf(moonLon) == tRashi)) {
            yogas.add(Yoga(
              shloka: 'ಆರಕ್ಷಕೋ ವಧರುಚಿಃ... (ದೃಷ್ಟಿಫಲಾಧ್ಯಾಯ ೪-೮)',
              name: 'ನವಾಂಶ ದೃಷ್ಟಿ ಯೋಗ (ದೃ ೪-೮)',
              description: '${_knPlanets[navLord]} ನವಾಂಶದಲ್ಲಿರುವ $targetKnನಿಗೆ ${_knPlanets[aspector]} ದೃಷ್ಟಿ',
              result: results[i],
              rashi: tRashi, planets: [targetKn, _knPlanets[aspector]!],
            ));
          }
        }
      }
    }

    // Shloka 4-8: Navamsha aspects for Moon and Sun (Shloka 8: ಚಂದ್ರೇ ಭಾನೌ ತದ್ವದ್)
    evaluateCh17Nav('Moon', moonLon);
    evaluateCh17Nav('Sun', sun);


    // ═══════════════════════════════════════════════════
    // Chapter 18: ಭಾವಫಲಾಧ್ಯಾಯ (Bhavaphaladhyaya - Results of Planets in Houses)
    // ═══════════════════════════════════════════════════

    int getBhava(int pRashi, int lagR) => ((pRashi - lagR) % 12) + 1;

    // --- Shloka 1-3: Sun in houses ---
    final ch18SunR = _rashiOf(sun);
    final ch18SunH = getBhava(ch18SunR, lagRashi);
    String sunRes = '';
    if (ch18SunH == 1) {
      if (ch18SunR == 0) sunRes = 'ಧನವಂತ ಮತ್ತು ದೃಷ್ಟಿದೋಷವುಳ್ಳವನು';
      else if (ch18SunR == 4) sunRes = 'ರಾತ್ರಿಯಲ್ಲಿ ಕಣ್ಣು ಕಾಣಿಸದವನು';
      else if (ch18SunR == 3) sunRes = 'ಗುಳ್ಳೆಗಳಂತಹ ಕಣ್ಣುಳ್ಳವನು';
      else sunRes = 'ಶೂರ, ಜಡಸ್ವಭಾವದವನು, ದೃಷ್ಟಿದೋಷವುಳ್ಳವನು, ಕರುಣೆಯಿಲ್ಲದವನು';
    } else if (ch18SunH == 2) sunRes = 'ಬಹಳ ಸಂಪತ್ತುಳ್ಳವನು, ರಾಜನಿಂದ ಧನ ನಷ್ಟ, ಮುಖದ ರೋಗ';
    else if (ch18SunH == 3) sunRes = 'ಬುದ್ಧಿವಂತ ಮತ್ತು ಪರಾಕ್ರಮಿ';
    else if (ch18SunH == 4) sunRes = 'ಸುಖವಿಲ್ಲದವನು, ಮಾನಸಿಕ ಪೀಡೆ';
    else if (ch18SunH == 5) sunRes = 'ಮಕ್ಕಳಿಲ್ಲದವನು ಮತ್ತು ಧನಹೀನ';
    else if (ch18SunH == 6) sunRes = 'ಬಲಶಾಲಿ, ಶತ್ರುಗಳನ್ನು ಸೋಲಿಸುವವನು';
    else if (ch18SunH == 7) sunRes = 'ಸ್ತ್ರೀಯರಿಂದ ಅವಮಾನ';
    else if (ch18SunH == 8) sunRes = 'ಕಡಿಮೆ ಮಕ್ಕಳು, ದೃಷ್ಟಿದೋಷ';
    else if (ch18SunH == 9) sunRes = 'ಮಕ್ಕಳು, ಹಣ ಮತ್ತು ಸುಖ';
    else if (ch18SunH == 10) sunRes = 'ಶಾಸ್ತ್ರಜ್ಞಾನ ಮತ್ತು ಶೌರ್ಯ';
    else if (ch18SunH == 11) sunRes = 'ಬಹಳ ಧನವಂತ';
    else if (ch18SunH == 12) sunRes = 'ಪತಿತನಾಗುತ್ತಾನೆ';
    if (sunRes.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ಶೂರಃ ಸ್ತಬ್ಧ ವಿಕಲನಯನೋ... (ಭಾವಫಲಾಧ್ಯಾಯ ೧-೩)',
        name: 'ಸೂರ್ಯ ಭಾವ ಫಲ (${ch18SunH}ನೇ ಮನೆ)',
        description: '${ch18SunH}ನೇ ಮನೆಯಲ್ಲಿ ಸೂರ್ಯ (${_rashiNames[ch18SunR]})',
        result: sunRes, rashi: ch18SunR, planets: ['ರವಿ'],
      ));
    }

    // --- Shloka 4-5: Moon in houses ---
    final ch18MoonR = _rashiOf(moonLon);
    final ch18MoonH = getBhava(ch18MoonR, lagRashi);
    // Moon's own rashi = Cancer(3), exalted = Taurus(1)
    String moonRes = '';
    if (ch18MoonH == 1) {
      if (ch18MoonR == 3 || ch18MoonR == 1) moonRes = 'ಧನವಂತ ಮತ್ತು ಬಹಳ ಮಕ್ಕಳುಳ್ಳವನು';
      else moonRes = 'ಮೂಗ, ಹುಚ್ಚ, ಜಡಬುದ್ಧಿ, ಕುರುಡ, ನೀಚ, ಕಿವುಡ, ಸೇವಕ';
    } else if (ch18MoonH == 2) moonRes = 'ಧನವಂತ, ದೊಡ್ಡ ಕುಟುಂಬ';
    else if (ch18MoonH == 3) moonRes = 'ಹಿಂಸಕನಾಗುತ್ತಾನೆ';
    else if (ch18MoonH == 4 || ch18MoonH == 5) moonRes = 'ಆಯಾ ಭಾವಗಳಿಗೆ ಸಂಬಂಧಿಸಿದ ಉತ್ತಮ ಫಲಗಳು';
    else if (ch18MoonH == 6) moonRes = 'ಅನೇಕ ಶತ್ರುಗಳು, ಮೃದು ಶರೀರ, ಕಾಮಾತುರ, ಆಲಸಿ';
    else if (ch18MoonH == 7) moonRes = 'ಅಸೂಯೆ ಪಡುವವನು, ಸ್ತ್ರೀಯರಲ್ಲಿ ಆಸಕ್ತ';
    else if (ch18MoonH == 8) moonRes = 'ಬುದ್ಧಿವಂತ, ರೋಗದಿಂದ ಪೀಡಿತ';
    else if (ch18MoonH == 9) moonRes = 'ಸೌಭಾಗ್ಯ, ಮಕ್ಕಳು, ಮಿತ್ರರು, ಬಂಧುಗಳು, ಧನ';
    else if (ch18MoonH == 10) moonRes = 'ಧರ್ಮ, ಧನ, ಬುದ್ಧಿ, ಶೌರ್ಯ, ಕಾರ್ಯಸಿದ್ಧಿ';
    else if (ch18MoonH == 11) moonRes = 'ಪ್ರಸಿದ್ಧ, ೧೧ನೇ ಭಾವದ ಗುಣಗಳು';
    else if (ch18MoonH == 12) moonRes = 'ನೀಚ ಮತ್ತು ಅಂಗಹೀನ';
    if (moonRes.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ಮೂಕೋನ್ಮತ್ತಜಡಾಂಧನೀಚ... (ಭಾವಫಲಾಧ್ಯಾಯ ೪-೫)',
        name: 'ಚಂದ್ರ ಭಾವ ಫಲ (${ch18MoonH}ನೇ ಮನೆ)',
        description: '${ch18MoonH}ನೇ ಮನೆಯಲ್ಲಿ ಚಂದ್ರ (${_rashiNames[ch18MoonR]})',
        result: moonRes, rashi: ch18MoonR, planets: ['ಚಂದ್ರ'],
      ));
    }

    // --- Shloka 6: Mars in houses ---
    final ch18MarsR = _rashiOf(mars);
    final ch18MarsH = getBhava(ch18MarsR, lagRashi);
    String marsRes = '';
    if (ch18MarsH == 1) marsRes = 'ಗಾಯಗೊಂಡ ಶರೀರವುಳ್ಳವನು';
    else if (ch18MarsH == 2) marsRes = 'ಕೆಟ್ಟ ಅನ್ನವನ್ನು ತಿನ್ನುವವನು';
    else if (ch18MarsH == 9) marsRes = 'ಪಾಪಕಾರ್ಯ ಮಾಡುವವನು';
    else marsRes = 'ಸೂರ್ಯನಂತೆಯೇ ಫಲ: $sunRes';
    if (marsRes.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ಲಗ್ನ ಕುಜೇ ಕ್ಷತತನುರ್ಧನಗೇ... (ಭಾವಫಲಾಧ್ಯಾಯ ೬)',
        name: 'ಕುಜ ಭಾವ ಫಲ (${ch18MarsH}ನೇ ಮನೆ)',
        description: '${ch18MarsH}ನೇ ಮನೆಯಲ್ಲಿ ಕುಜ (${_rashiNames[ch18MarsR]})',
        result: marsRes, rashi: ch18MarsR, planets: ['ಕುಜ'],
      ));
    }

    // --- Shloka 6: Mercury in houses ---
    final ch18MercR = _rashiOf(mer);
    final ch18MercH = getBhava(ch18MercR, lagRashi);
    final mercResults = <int,String>{1:'ವಿದ್ವಾಂಸ',2:'ಧನವಂತ',3:'ಪ್ರಬಲ',4:'ಪಂಡಿತ',5:'ಮಂತ್ರಿ',6:'ಶತ್ರುವಿಲ್ಲದವನು',7:'ಹಾಸ್ಯ ಬಲ್ಲವನು'};
    String mercRes = '';
    if (ch18MercH == 8) mercRes = 'ಸೂರ್ಯನಂತೆಯೇ ಫಲ: $sunRes';
    else mercRes = mercResults[ch18MercH] ?? 'ಪ್ರಸಿದ್ಧ ಗುಣವುಳ್ಳವನು';
    yogas.add(Yoga(
      shloka: 'ವಿದ್ವಾನ್ ಧನೀ ಪ್ರಬಲಪಂಡಿತಮಂತ್ರ್ಯ... (ಭಾವಫಲಾಧ್ಯಾಯ ೬)',
      name: 'ಬುಧ ಭಾವ ಫಲ (${ch18MercH}ನೇ ಮನೆ)',
      description: '${ch18MercH}ನೇ ಮನೆಯಲ್ಲಿ ಬುಧ (${_rashiNames[ch18MercR]})',
      result: mercRes, rashi: ch18MercR, planets: ['ಬುಧ'],
    ));

    // --- Shloka 7: Jupiter in houses ---
    final ch18JupR = _rashiOf(jup);
    final ch18JupH = getBhava(ch18JupR, lagRashi);
    final jupResults = <int,String>{
      1:'ವಿದ್ವಾಂಸ',2:'ಒಳ್ಳೆಯ ಮಾತುಗಾರ',3:'ಜಿಪುಣ',4:'ಸುಖಿ',5:'ಬುದ್ಧಿವಂತ',
      6:'ಶತ್ರುವಿಲ್ಲದವನು',7:'ತಂದೆಗಿಂತ ಶ್ರೇಷ್ಠ',8:'ನೀಚ',9:'ತಪಸ್ವಿ',
      10:'ಧನವಂತ',11:'ಲಾಭವುಳ್ಳವನು',12:'ದುಷ್ಟ'
    };
    final jupRes = jupResults[ch18JupH] ?? '';
    if (jupRes.isNotEmpty) {
      yogas.add(Yoga(
        shloka: 'ವಿದ್ವಾನ್ ಸುವಾಕ್ಯಃ ಕೃಪಣಃ... (ಭಾವಫಲಾಧ್ಯಾಯ ೭)',
        name: 'ಗುರು ಭಾವ ಫಲ (${ch18JupH}ನೇ ಮನೆ)',
        description: '${ch18JupH}ನೇ ಮನೆಯಲ್ಲಿ ಗುರು (${_rashiNames[ch18JupR]})',
        result: jupRes, rashi: ch18JupR, planets: ['ಗುರು'],
      ));
    }

    // --- Shloka 8: Venus in houses ---
    final ch18VenR = _rashiOf(ven);
    final ch18VenH = getBhava(ch18VenR, lagRashi);
    String venRes = '';
    if (ch18VenH == 1) venRes = 'ಕಾಮಕಾರ್ಯದಲ್ಲಿ ನಿಪುಣ, ಸುಖಿ';
    else if (ch18VenH == 5) venRes = 'ಸುಖಿ';
    else if (ch18VenH == 7) venRes = 'ಜಗಳಗಂಟ, ರತಿಕ್ರೀಡೆಯಲ್ಲಿ ಆಸಕ್ತ';
    else venRes = '${jupResults[ch18VenH] ?? 'ಗುರುವಿನಂತೆ ಫಲ'}, ಧನವಂತ';
    yogas.add(Yoga(
      shloka: 'ಸ್ಮರನಿಪುಣ: ಸುಖವಾಂಶ್ಚ... (ಭಾವಫಲಾಧ್ಯಾಯ ೮)',
      name: 'ಶುಕ್ರ ಭಾವ ಫಲ (${ch18VenH}ನೇ ಮನೆ)',
      description: '${ch18VenH}ನೇ ಮನೆಯಲ್ಲಿ ಶುಕ್ರ (${_rashiNames[ch18VenR]})',
      result: venRes, rashi: ch18VenR, planets: ['ಶುಕ್ರ'],
    ));

    // --- Shloka 9: Saturn in houses ---
    final ch18SatR = _rashiOf(sat);
    final ch18SatH = getBhava(ch18SatR, lagRashi);
    // Saturn own: Capricorn(9), Aquarius(10). Exalted: Libra(6). Jupiter's: Sagittarius(8), Pisces(11)
    String satRes = '';
    if (ch18SatH == 1) {
      final satInGoodSign = {6,8,9,10,11}.contains(ch18SatR); // own/exalted/Jupiter's
      if (satInGoodSign) {
        satRes = 'ರಾಜನಿಗೆ ಸಮಾನ, ಗ್ರಾಮ/ನಗರ ಒಡೆಯ, ವಿದ್ವಾಂಸ, ಸುಂದರ ಶರೀರ';
      } else {
        satRes = 'ದರಿದ್ರ, ರೋಗಿ, ಕಾಮಾತುರ, ಮಲಿನ, ಬಾಲ್ಯ ರೋಗ, ಆಲಸ ಮಾತು';
      }
    } else {
      satRes = 'ಸೂರ್ಯನಂತೆಯೇ ಫಲ: $sunRes';
    }
    yogas.add(Yoga(
      shloka: 'ಅದೃಷ್ಟಾರ್ಥೋ ರೋಗೀ ಮದನವಶಗೋ... (ಭಾವಫಲಾಧ್ಯಾಯ ೯)',
      name: 'ಶನಿ ಭಾವ ಫಲ (${ch18SatH}ನೇ ಮನೆ)',
      description: '${ch18SatH}ನೇ ಮನೆಯಲ್ಲಿ ಶನಿ (${_rashiNames[ch18SatR]})',
      result: satRes, rashi: ch18SatR, planets: ['ಶನಿ'],
    ));


    // ═══════════════════════════════════════════════════
    // Chapter 21: ಅನಿಷ್ಟಯೋಗಾಧ್ಯಾಯ
    // ═══════════════════════════════════════════════════
    final ch21Ven = _rashiOf(ven);
    final ch21Sun = _rashiOf(sun);
    final ch21Moon = _rashiOf(moonLon);
    final ch21Mars = _rashiOf(mars);
    final ch21Sat = _rashiOf(sat);
    final ch21Jup = _rashiOf(jup);
    final ch21Mer = _rashiOf(mer);
    final ch21Rahu = _rashiOf(rahu);
    final ch21Ketu = _rashiOf(ketu);

    // Shloka 1: 5th/7th shubha check
    for (final refName in ['ಲಗ್ನ', 'ಚಂದ್ರ']) {
      final refR = refName == 'ಲಗ್ನ' ? lagRashi : ch21Moon;
      final h5 = (refR + 4) % 12;
      final h7 = (refR + 6) % 12;
      final shIn5 = ch21Jup == h5 || ch21Ven == h5 || ch21Mer == h5;
      final shIn7 = ch21Jup == h7 || ch21Ven == h7 || ch21Mer == h7;
      if (shIn5 || shIn7) {
        yogas.add(Yoga(
          shloka: 'ಲಗ್ನಾತ್ಪುತ್ರಕಲತ್ರಭೇ... (ಅನಿಷ್ಟಯೋಗಾ ೧)',
          name: 'ಪುತ್ರ-ಕಲತ್ರ ಸುಖ ಯೋಗ (ಅ ೧)',
          description: '${refName}ದಿಂದ ${shIn5 ? "5ನೇ" : "7ನೇ"} ಮನೆಯಲ್ಲಿ ಶುಭಗ್ರಹ',
          result: 'ಮಕ್ಕಳು ಮತ್ತು ಹೆಂಡತಿಯಿಂದ ಸುಖ',
          rashi: refR, planets: [refName],
        ));
      }
    }
    if (lagRashi == 5 && ch21Sun == 5 && ch21Sat == 11) {
      yogas.add(Yoga(shloka: 'ಪಾರ್ಥೋನೋದಯಗೇ ರವೌ... (ಅನಿಷ್ಟಯೋಗಾ ೧)', name: 'ದಾರ ಹಾನಿ ಯೋಗ (ಅ ೧)', description: 'ಕನ್ಯಾ ಲಗ್ನ+ರವಿ, ಮೀನದಲ್ಲಿ ಶನಿ', result: 'ಹೆಂಡತಿಯ ಮರಣ', rashi: lagRashi, planets: ['ರವಿ','ಶನಿ']));
    }
    if (getBhava(ch21Mars, lagRashi) == 5) {
      yogas.add(Yoga(shloka: 'ಪುತ್ರಸ್ಥಾನಗತಶ್ಚ... (ಅನಿಷ್ಟಯೋಗಾ ೧)', name: 'ಪುತ್ರ ಹಾನಿ ಯೋಗ (ಅ ೧)', description: 'ಕುಜ 5ನೇ ಮನೆಯಲ್ಲಿ', result: 'ಮಕ್ಕಳ ಮರಣ/ಕಷ್ಟ', rashi: ch21Mars, planets: ['ಕುಜ']));
    }
    // Shloka 2: Venus hemmed
    final ch21VenH = getBhava(ch21Ven, lagRashi);
    final v4 = (ch21Ven+3)%12; final v8 = (ch21Ven+7)%12;
    final p4 = ch21Sun==v4||ch21Mars==v4||ch21Sat==v4||ch21Rahu==v4||ch21Ketu==v4;
    final p8 = ch21Sun==v8||ch21Mars==v8||ch21Sat==v8||ch21Rahu==v8||ch21Ketu==v8;
    final vn=(ch21Ven+1)%12; final vp=(ch21Ven+11)%12;
    final hm=(ch21Sun==vn||ch21Mars==vn||ch21Sat==vn)&&(ch21Sun==vp||ch21Mars==vp||ch21Sat==vp);
    final sv = ch21Jup==ch21Ven||ch21Mer==ch21Ven;
    if ((p4&&p8||hm)&&!sv) {
      yogas.add(Yoga(shloka: 'ಉಗ್ರಗ್ರಹೈ:... (ಅನಿಷ್ಟಯೋಗಾ ೨)', name: 'ಜಾಯಾ ವಧ ಯೋಗ (ಅ ೨)', description: 'ಶುಕ್ರನಿಂದ 4/8ರಲ್ಲಿ ಪಾಪ, ಶುಭದೃಷ್ಟಿ ಇಲ್ಲ', result: 'ಹೆಂಡತಿಗೆ ಅಪಾಯ', rashi: ch21Ven, planets: ['ಶುಕ್ರ']));
    }
    // Shloka 3
    final ch21SunH = getBhava(ch21Sun, lagRashi); final ch21MoonH = getBhava(ch21Moon, lagRashi);
    if ((ch21SunH==12&&ch21MoonH==6)||(ch21SunH==6&&ch21MoonH==12)) {
      yogas.add(Yoga(shloka: 'ಲಗ್ನಾದ್ ವ್ಯಯಾರಿಗತಯೋಃ... (ಅನಿಷ್ಟಯೋಗಾ ೩)', name: 'ದೃಷ್ಟಿ ದೋಷ ಯೋಗ (ಅ ೩)', description: 'ಸೂರ್ಯ+ಚಂದ್ರ 12/6ರಲ್ಲಿ', result: 'ದೃಷ್ಟಿದೋಷ', rashi: ch21Sun, planets: ['ರವಿ','ಚಂದ್ರ']));
    }
    if (ch21Ven==ch21Sun) { final cH=getBhava(ch21Sun,lagRashi); if(cH==7||cH==5||cH==9) {
      yogas.add(Yoga(shloka: 'ಶುಕ್ರಾರ್ಕಯೋರ್ವಿಕಲ... (ಅನಿಷ್ಟಯೋಗಾ ೩)', name: 'ವಿಕಲ ದಾರ ಯೋಗ (ಅ ೩)', description: 'ಸೂರ್ಯ+ಶುಕ್ರ ${cH}ನೇ ಮನೆಯಲ್ಲಿ', result: 'ವಿಕಲಾಂಗ ಹೆಂಡತಿ', rashi: ch21Sun, planets: ['ರವಿ','ಶುಕ್ರ']));
    }}
    // Shloka 4
    if ((lagRashi==9||lagRashi==10||lagRashi==0||lagRashi==7)&&ch21VenH==7) {
      final h5R=(lagRashi+4)%12; if(ch21Jup!=h5R&&ch21Mer!=h5R) {
        yogas.add(Yoga(shloka: 'ಕೋಣೋದಯೇ... (ಅನಿಷ್ಟಯೋಗಾ ೪)', name: 'ವಂಧ್ಯಾ ಯೋಗ (ಅ ೪)', description: 'ಶನಿ/ಕುಜ ಲಗ್ನ+ಶುಕ್ರ 7+5ರಲ್ಲಿ ಶುಭ ಇಲ್ಲ', result: 'ಬಂಜೆ ಹೆಂಡತಿ', rashi: ch21Ven, planets: ['ಶುಕ್ರ']));
    }}
    // Shloka 5
    if (ch21VenH==7&&ch21MoonH==7) {
      final shA=ch21Jup==(lagRashi+6)%12||ch21Mer==(lagRashi+6)%12;
      yogas.add(Yoga(shloka: 'ನೃಗುಜಶಶಿನೋರಸ್ತೇ... (ಅನಿಷ್ಟಯೋಗಾ ೫)', name: shA?'ವಿಳಂಬ ವಿವಾಹ (ಅ ೫)':'ಅಭಾರ್ಯ ಯೋಗ (ಅ ೫)', description: 'ಶುಕ್ರ+ಚಂದ್ರ 7ರಲ್ಲಿ', result: shA?'ವೃದ್ಧಾಪ್ಯದಲ್ಲಿ ಹೆಂಡತಿ':'ಹೆಂಡತಿ/ಮಕ್ಕಳಿಲ್ಲ', rashi: ch21Ven, planets: ['ಶುಕ್ರ','ಚಂದ್ರ']));
    }

    // --- Shloka 6 (Anishtayoga Part2): Vamshoccheda ---
    // Moon in 10th, Venus in 7th, papa in 4th → vamsha destroyer
    if (ch21MoonH==10 && ch21VenH==7) {
      final h4=(lagRashi+3)%12;
      if (ch21Sun==h4||ch21Mars==h4||ch21Sat==h4) {
        yogas.add(Yoga(shloka: 'ವಂಶೋಚ್ಛೇತ್ತಾ... (ಅನಿಷ್ಟಯೋಗಾ ೬)', name: 'ವಂಶೋಚ್ಛೇದ ಯೋಗ (ಅ ೬)', description: 'ಚಂದ್ರ 10, ಶುಕ್ರ 7, ಪಾಪ 4ರಲ್ಲಿ', result: 'ವಂಶನಾಶಕ', rashi: lagRashi, planets: ['ಚಂದ್ರ','ಶುಕ್ರ']));
      }
    }
    // Venus in 12th in Saturn navamsha → born to dasi
    if (ch21VenH==12) {
      final ch21VenNav = _d9Rashi(ven);
      final ch21VenNavLord = rashiLords[ch21VenNav];
      if (ch21VenNavLord=='Saturn') {
        yogas.add(Yoga(shloka: 'ದಾಸ್ಯಾಂ ಜಾತೋ... (ಅನಿಷ್ಟಯೋಗಾ ೬)', name: 'ದಾಸೀಪುತ್ರ ಯೋಗ (ಅ ೬)', description: 'ಶುಕ್ರ 12ರಲ್ಲಿ ಶನಿ ನವಾಂಶದಲ್ಲಿ', result: 'ದಾಸಿಗೆ ಹುಟ್ಟಿದವನು', rashi: ch21Ven, planets: ['ಶುಕ್ರ']));
      }
    }
    // Sun+Moon in 7th aspected by Saturn → neecha
    if (ch21SunH==7 && ch21MoonH==7) {
      final satAsp7 = ch21Sat==(lagRashi+6)%12;
      if (satAsp7) {
        yogas.add(Yoga(shloka: 'ನೀಚೋsರ್ಕೇಂದ್ಯೋರ್ಮದನಗತಯೋಃ... (ಅನಿಷ್ಟಯೋಗಾ ೬)', name: 'ನೀಚ ಯೋಗ (ಅ ೬)', description: 'ಸೂರ್ಯ+ಚಂದ್ರ 7ರಲ್ಲಿ + ಶನಿ ದೃಷ್ಟಿ', result: 'ನೀಚನಾಗುತ್ತಾನೆ', rashi: ch21Sun, planets: ['ರವಿ','ಚಂದ್ರ','ಶನಿ']));
      }
    }

    // --- Shloka 7: Venus+Mars in 7th + papa drishti → vataroga ---
    if (ch21VenH==7 && getBhava(ch21Mars,lagRashi)==7) {
      final papAsp = ch21Sun==(lagRashi+6)%12||ch21Sat==(lagRashi+6)%12;
      if (papAsp) {
        yogas.add(Yoga(shloka: 'ಪಾಪಾಲೋಕಿತಯೋಃ ಸಿತಾವನಿಜಯೋಃ... (ಅನಿಷ್ಟಯೋಗಾ ೭)', name: 'ವಾತರೋಗ ಯೋಗ (ಅ ೭)', description: 'ಶುಕ್ರ+ಕುಜ 7ರಲ್ಲಿ + ಪಾಪ ದೃಷ್ಟಿ', result: 'ವಾತರೋಗ', rashi: ch21Ven, planets: ['ಶುಕ್ರ','ಕುಜ']));
      }
    }
    // Moon in Karkata/Vrischika navamsha + papa → guhyaroga
    final ch21MoonNav = _d9Rashi(moonLon);
    if ((ch21MoonNav==3||ch21MoonNav==7) && (ch21Sun==ch21Moon||ch21Mars==ch21Moon||ch21Sat==ch21Moon)) {
      yogas.add(Yoga(shloka: 'ಚಂದ್ರೇ ಕರ್ಕಟವೃಶ್ಚಿಕಾಂಶಕಗತೇ... (ಅನಿಷ್ಟಯೋಗಾ ೭)', name: 'ಗುಹ್ಯರೋಗ ಯೋಗ (ಅ ೭)', description: 'ಚಂದ್ರ ಕರ್ಕಟ/ವೃಶ್ಚಿಕ ನವಾಂಶ + ಪಾಪ ಯುತ', result: 'ಗುಹ್ಯರೋಗ', rashi: ch21Moon, planets: ['ಚಂದ್ರ']));
    }
    // Sun+Moon in same rashi or mutual exchange → kshaya/krusha
    final ch21SunNav = _d9Rashi(sun);
    if (ch21Sun==ch21Moon) {
      yogas.add(Yoga(shloka: 'ಶೋಷೀ ಪರಸ್ಪರಗೃಹಾಂಶಗಯೋ... (ಅನಿಷ್ಟಯೋಗಾ ೭)', name: 'ಕೃಶ ಶರೀರ ಯೋಗ (ಅ ೭)', description: 'ಸೂರ್ಯ+ಚಂದ್ರ ಒಂದೇ ರಾಶಿ', result: 'ಕೃಶ ಶರೀರ', rashi: ch21Sun, planets: ['ರವಿ','ಚಂದ್ರ']));
    } else if ((ch21Sun==3&&ch21Moon==4)||(ch21Sun==4&&ch21Moon==3)||(ch21SunNav==3&&ch21MoonNav==4)||(ch21SunNav==4&&ch21MoonNav==3)) {
      yogas.add(Yoga(shloka: 'ಶೋಷೀ ಪರಸ್ಪರಗೃಹಾಂಶಗಯೋ... (ಅನಿಷ್ಟಯೋಗಾ ೭)', name: 'ಕ್ಷಯರೋಗ ಯೋಗ (ಅ ೭)', description: 'ಸೂರ್ಯ-ಚಂದ್ರ ಪರಸ್ಪರ ರಾಶಿ/ನವಾಂಶ', result: 'ಕ್ಷಯರೋಗ', rashi: ch21Sun, planets: ['ರವಿ','ಚಂದ್ರ']));
    }

    // --- Shloka 8: Papa in 12&2, Moon lagna, Sun 7th → vikala ---
    if (ch21MoonH==1 && ch21SunH==7) {
      final p12=(lagRashi+11)%12; final p2=(lagRashi+1)%12;
      final papIn12=ch21Mars==p12||ch21Sat==p12||ch21Rahu==p12;
      final papIn2=ch21Mars==p2||ch21Sat==p2||ch21Rahu==p2;
      if (papIn12&&papIn2) {
        yogas.add(Yoga(shloka: 'ರಿಫಧನಸ್ಥಯೋರಶುಭಯೋಃ... (ಅನಿಷ್ಟಯೋಗಾ ೮)', name: 'ವಿಕಲ ಯೋಗ (ಅ ೮)', description: 'ಪಾಪ 12/2 + ಚಂದ್ರ ಲಗ್ನ + ಸೂರ್ಯ 7', result: 'ವಿಕಲಾಂಗ', rashi: lagRashi, planets: ['ಚಂದ್ರ','ರವಿ']));
      }
    }

    // --- Shloka 9: Moon hemmed by papa + Sun in 7th → shvasa/kshaya ---
    final ch21MnPrev=(ch21Moon+11)%12; final ch21MnNext=(ch21Moon+1)%12;
    final moonHemmed=(ch21Sun==ch21MnPrev||ch21Mars==ch21MnPrev||ch21Sat==ch21MnPrev)&&(ch21Sun==ch21MnNext||ch21Mars==ch21MnNext||ch21Sat==ch21MnNext);
    if (moonHemmed && ch21SunH==7) {
      yogas.add(Yoga(shloka: 'ಅಂತಃ ಶಶಿನ್ಯಶುಭಯೋಃ... (ಅನಿಷ್ಟಯೋಗಾ ೯)', name: 'ಶ್ವಾಸ-ಗುಲ್ಮ ರೋಗ ಯೋಗ (ಅ ೯)', description: 'ಚಂದ್ರ ಪಾಪಮಧ್ಯ + ಸೂರ್ಯ 7ರಲ್ಲಿ', result: 'ಶ್ವಾಸ, ಕ್ಷಯ, ಪ್ಲೀಹ, ಗುಲ್ಮ ರೋಗ', rashi: ch21Moon, planets: ['ಚಂದ್ರ','ರವಿ']));
    }

    // --- Shloka 10: Moon in Mesha/Karkata/Makara/Meena navamsha + Sat+Mars → kushtha ---
    if ((ch21MoonNav==0||ch21MoonNav==3||ch21MoonNav==9||ch21MoonNav==11)&&(ch21Sat==ch21Moon||ch21Mars==ch21Moon)) {
      yogas.add(Yoga(shloka: 'ಚಂದ್ರೇsಶ್ಚಿಮಧ್ಯಝಷಕರ್ಕಿ... (ಅನಿಷ್ಟಯೋಗಾ ೧೦)', name: 'ಕುಷ್ಠರೋಗ ಯೋಗ (ಅ ೧೦)', description: 'ಚಂದ್ರ ಮೇಷ/ಕರ್ಕ/ಮಕರ/ಮೀನ ನವಾಂಶ + ಶನಿ/ಕುಜ ಯುತ', result: 'ಕುಷ್ಠರೋಗ', rashi: ch21Moon, planets: ['ಚಂದ್ರ']));
    }

    // --- Shloka 11: Sun/Moon/Mars/Sat in 8/6/2/12 → blindness ---
    if (ch21SunH==8 && ch21MoonH==6 && getBhava(ch21Mars,lagRashi)==2 && getBhava(ch21Sat,lagRashi)==12) {
      yogas.add(Yoga(shloka: 'ನಿಧನಾರಿಧನವ್ಯಯಸ್ಥಿತಾ... (ಅನಿಷ್ಟಯೋಗಾ ೧೧)', name: 'ಅಂಧತ್ವ ಯೋಗ (ಅ ೧೧)', description: 'ಸೂರ್ಯ 8, ಚಂದ್ರ 6, ಕುಜ 2, ಶನಿ 12', result: 'ಅಂಧತ್ವ', rashi: lagRashi, planets: ['ರವಿ','ಚಂದ್ರ','ಕುಜ','ಶನಿ']));
    }

    // --- Shloka 12: Papa in 9/11/3/5 without shubha drishti → deafness ---
    final ch21H9=(lagRashi+8)%12; final ch21H11=(lagRashi+10)%12; final ch21H3=(lagRashi+2)%12; final ch21H5=(lagRashi+4)%12;
    final papIn9=ch21Sun==ch21H9||ch21Mars==ch21H9||ch21Sat==ch21H9;
    final papIn11=ch21Sun==ch21H11||ch21Mars==ch21H11||ch21Sat==ch21H11;
    final papIn3=ch21Sun==ch21H3||ch21Mars==ch21H3||ch21Sat==ch21H3;
    final papIn5=ch21Sun==ch21H5||ch21Mars==ch21H5||ch21Sat==ch21H5;
    if (papIn9&&papIn11&&papIn3&&papIn5) {
      final shubAsp=ch21Jup==ch21H9||ch21Jup==ch21H11||ch21Jup==ch21H3||ch21Jup==ch21H5||ch21Mer==ch21H9||ch21Mer==ch21H11;
      if (!shubAsp) {
        yogas.add(Yoga(shloka: 'ನವಮಾಯತೃತೀಯಧೀಯುತಾ... (ಅನಿಷ್ಟಯೋಗಾ ೧೨)', name: 'ಬಧಿರತ್ವ ಯೋಗ (ಅ ೧೨)', description: 'ಪಾಪ 9/11/3/5ರಲ್ಲಿ, ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ', result: 'ಕಿವುಡತನ', rashi: lagRashi, planets: ['ಪಾಪ']));
      }
    }

    // --- Shloka 13: Moon+Rahu in lagna + papa in trikona → pishacha ---
    final ch21RahuH = getBhava(ch21Rahu, lagRashi);
    if (ch21MoonH==1 && ch21RahuH==1) {
      final trik5=ch21Sun==ch21H5||ch21Mars==ch21H5||ch21Sat==ch21H5;
      final trik9=ch21Sun==ch21H9||ch21Mars==ch21H9||ch21Sat==ch21H9;
      if (trik5||trik9) {
        yogas.add(Yoga(shloka: 'ಉದಯತ್ಯುಡುಪೇsಸುರಾಸ್ಯಗೇ... (ಅನಿಷ್ಟಯೋಗಾ ೧೩)', name: 'ಪಿಶಾಚ ಬಾಧೆ ಯೋಗ (ಅ ೧೩)', description: 'ಚಂದ್ರ+ರಾಹು ಲಗ್ನ + ಪಾಪ ತ್ರಿಕೋಣ', result: 'ಪಿಶಾಚಿ ಬಾಧೆ', rashi: lagRashi, planets: ['ಚಂದ್ರ','ರಾಹು']));
      }
    }

    // --- Shloka 14: Saturn 7th+Jupiter lagna → unmada ---
    final ch21SatH = getBhava(ch21Sat, lagRashi);
    final ch21JupH = getBhava(ch21Jup, lagRashi);
    final ch21MarsH = getBhava(ch21Mars, lagRashi);
    if (ch21SatH==7 && ch21JupH==1) {
      yogas.add(Yoga(shloka: 'ಸಂಭ್ರಷ್ಟ ಪವನೇನ... (ಅನಿಷ್ಟಯೋಗಾ ೧೪)', name: 'ಉನ್ಮಾದ ಯೋಗ (ಅ ೧೪)', description: 'ಶನಿ 7 + ಗುರು ಲಗ್ನ', result: 'ವಾತಕೋಪ ಉನ್ಮಾದ', rashi: lagRashi, planets: ['ಶನಿ','ಗುರು']));
    }
    if (ch21MarsH==7 && ch21JupH==1) {
      yogas.add(Yoga(shloka: 'ಸೋನ್ಮಾದೋsವನಿಸೂನುನಾ... (ಅನಿಷ್ಟಯೋಗಾ ೧೪)', name: 'ಉನ್ಮಾದ ಯೋಗ-೨ (ಅ ೧೪)', description: 'ಕುಜ 7 + ಗುರು ಲಗ್ನ', result: 'ಉನ್ಮಾದ', rashi: lagRashi, planets: ['ಕುಜ','ಗುರು']));
    }
    if (ch21SatH==1 && (ch21MarsH==9||ch21MarsH==5||ch21MarsH==7)) {
      yogas.add(Yoga(shloka: 'ತದ್ವಚ್ಚಾಹ ಯಮೋದಯೇ... (ಅನಿಷ್ಟಯೋಗಾ ೧೪)', name: 'ಉನ್ಮಾದ ಯೋಗ-೩ (ಅ ೧೪)', description: 'ಶನಿ ಲಗ್ನ + ಕುಜ ${ch21MarsH}ನೇ ಮನೆ', result: 'ಉನ್ಮಾದ', rashi: lagRashi, planets: ['ಶನಿ','ಕುಜ']));
    }

    // --- Shloka 18: Sun/Sat/Mars in 10th without shubha drishti → parricide ---
    if (ch21SunH==10 || ch21SatH==10 || ch21MarsH==10) {
      final inH10 = <String>[];
      if (ch21SunH==10) inH10.add('ರವಿ');
      if (ch21SatH==10) inH10.add('ಶನಿ');
      if (ch21MarsH==10) inH10.add('ಕುಜ');
      final h10R=(lagRashi+9)%12;
      final shubH10=ch21Jup==h10R||ch21Mer==h10R||ch21Ven==h10R;
      if (!shubH10) {
        yogas.add(Yoga(shloka: 'ರವಿಯಮಕುಜೈಃ... (ಅನಿಷ್ಟಯೋಗಾ ೧೮)', name: 'ಧೃತಕ ಯೋಗ (ಅ ೧೮)', description: '${inH10.join("+")} 10ನೇ ಮನೆ, ಶುಭದೃಷ್ಟಿ ಇಲ್ಲ', result: 'ಪಿತೃ/ಮಾತೃ ಹಾನಿಕಾರಕ', rashi: h10R, planets: inH10));
      }
    }

    // ═══════════════════════════════════════════════════
    // Chapter 22: ಸ್ತ್ರೀಜಾತಕಾಧ್ಯಾಯ (Streejaatakadhyaya)
    // ═══════════════════════════════════════════════════
    final ch22LagNav = _d9Rashi(lag);
    final ch22MoonNav2 = _d9Rashi(moonLon);
    final ch22LagLord = rashiLords[lagRashi];
    final ch22H7 = (lagRashi+6)%12;
    final ch22H7Lord = rashiLords[ch22H7];
    final ch22H8 = (lagRashi+7)%12;
    final ch22H8Lord = rashiLords[ch22H8];
    final ch22VenNav = _d9Rashi(ven);
    final ch22SatNav = _d9Rashi(sat);
    final ch22MarsNav = _d9Rashi(mars);

    // Shloka 2: Lagna+Moon in even rashi → feminine; odd → masculine traits
    final ch22LagEven = _isEvenSign(lagRashi);
    final ch22MoonEven = _isEvenSign(ch21Moon);
    if (ch22LagEven && ch22MoonEven) {
      yogas.add(Yoga(shloka: 'ಯುಕ್ಕೇಷು ಲಗ್ನಶಶಿನೋಃ... (ಸ್ತ್ರೀಜಾತಕ ೨)', name: 'ಸ್ತ್ರೀ ಸಹಜ ಗುಣ (ಸ್ತ್ರೀ ೨)', description: 'ಲಗ್ನ+ಚಂದ್ರ ಸಮ ರಾಶಿ', result: 'ಸ್ತ್ರೀಸಹಜ ಗುಣ, ಆಭರಣಪ್ರಿಯಳು', rashi: lagRashi, planets: ['ಲಗ್ನ','ಚಂದ್ರ']));
    } else if (!ch22LagEven && !ch22MoonEven) {
      yogas.add(Yoga(shloka: 'ಓಜಸ್ಥಯೋಸ್ತು ಪುರುಷಾಕೃತಿ... (ಸ್ತ್ರೀಜಾತಕ ೨)', name: 'ಪುರುಷಾಕೃತಿ ಸ್ತ್ರೀ (ಸ್ತ್ರೀ ೨)', description: 'ಲಗ್ನ+ಚಂದ್ರ ಬೆಸ ರಾಶಿ', result: 'ಪುರುಷನಂತಹ ಆಕಾರ/ಗುಣ', rashi: lagRashi, planets: ['ಲಗ್ನ','ಚಂದ್ರ']));
    }

    // Shloka 3: Mars rashi lagna/Moon + navamsha lord → character
    final ch22LagInMars = ch22LagLord == 'Mars';
    if (ch22LagInMars) {
      final navLord = rashiLords[ch22LagNav];
      if (navLord=='Mars') yogas.add(Yoga(shloka: 'ಕನೈವ ದುಷ್ಟಾ... (ಸ್ತ್ರೀಜಾತಕ ೩)', name: 'ಕನ್ಯಾ ದುಷ್ಟ (ಸ್ತ್ರೀ ೩)', description: 'ಕುಜ ರಾಶಿ+ಕುಜ ನವಾಂಶ', result: 'ಕನ್ಯೆಯಿರುವಾಗಲೇ ದುಷ್ಟಳು', rashi: lagRashi, planets: ['ಲಗ್ನ']));
      if (navLord=='Saturn') yogas.add(Yoga(shloka: 'ವಜತೀಹ ದಾಸ್ಯಂ... (ಸ್ತ್ರೀಜಾತಕ ೩)', name: 'ದಾಸಿ ಯೋಗ (ಸ್ತ್ರೀ ೩)', description: 'ಕುಜ ರಾಶಿ+ಶನಿ ನವಾಂಶ', result: 'ದಾಸಿಯಾಗುತ್ತಾಳೆ', rashi: lagRashi, planets: ['ಲಗ್ನ']));
      if (navLord=='Jupiter') yogas.add(Yoga(shloka: 'ಸಾಧೀ... (ಸ್ತ್ರೀಜಾತಕ ೩)', name: 'ಸಾಧ್ವಿ ಯೋಗ (ಸ್ತ್ರೀ ೩)', description: 'ಕುಜ ರಾಶಿ+ಗುರು ನವಾಂಶ', result: 'ಸಾಧ್ವಿಯಾಗುತ್ತಾಳೆ', rashi: lagRashi, planets: ['ಲಗ್ನ']));
      if (navLord=='Mercury') yogas.add(Yoga(shloka: 'ಸಮಾಯಾ... (ಸ್ತ್ರೀಜಾತಕ ೩)', name: 'ಮಾಯಾವಿ (ಸ್ತ್ರೀ ೩)', description: 'ಕುಜ ರಾಶಿ+ಬುಧ ನವಾಂಶ', result: 'ಮಾಯಾವಿಯಾಗುತ್ತಾಳೆ', rashi: lagRashi, planets: ['ಲಗ್ನ']));
      if (navLord=='Venus') yogas.add(Yoga(shloka: 'ಕುಚರಿತ್ರಯುಕ್ತಾ... (ಸ್ತ್ರೀಜಾತಕ ೩)', name: 'ಕುಚರಿತ್ರ (ಸ್ತ್ರೀ ೩)', description: 'ಕುಜ ರಾಶಿ+ಶುಕ್ರ ನವಾಂಶ', result: 'ಕೆಟ್ಟ ಚಾರಿತ್ರ್ಯ', rashi: lagRashi, planets: ['ಲಗ್ನ']));
    }

    // Shloka 7: Saturn+Venus mutual navamsha exchange
    final ch22SatNavLord = rashiLords[ch22SatNav];
    final ch22VenNavLord = rashiLords[ch22VenNav];
    if (ch22SatNavLord=='Venus' && ch22VenNavLord=='Saturn') {
      yogas.add(Yoga(shloka: 'ವೃಕ್ಷಂಸ್ಥಾವಸಿತಸಿತೌ ಪರಸ್ಪರಾಂಶೇ... (ಸ್ತ್ರೀಜಾತಕ ೭)', name: 'ಶನಿ-ಶುಕ್ರ ಪರಿವರ್ತನೆ (ಸ್ತ್ರೀ ೭)', description: 'ಶನಿ ಶುಕ್ರ ನವಾಂಶ + ಶುಕ್ರ ಶನಿ ನವಾಂಶ', result: 'ಅಸಾಮಾನ್ಯ ಕಾಮವೃತ್ತಿ', rashi: ch21Ven, planets: ['ಶುಕ್ರ','ಶನಿ']));
    }

    // Shloka 8: 7th house analysis for husband
    final ch22H7Nav = _d9Rashi(lag + (ch22H7 * 30.0)); // approximate
    final ch22H7NavLord = rashiLords[ch22H7Nav];
    // Mercury+Saturn in 7th → impotent husband
    if (ch21Mer == ch22H7 && ch21Sat == ch22H7) {
      yogas.add(Yoga(shloka: 'ಕ್ಲೀಬೋsಸ್ತೇ ಬುಧಮಂದಯೋಃ... (ಸ್ತ್ರೀಜಾತಕ ೮)', name: 'ನಪುಂಸಕ ಪತಿ (ಸ್ತ್ರೀ ೮)', description: 'ಬುಧ+ಶನಿ 7ನೇ ಮನೆಯಲ್ಲಿ', result: 'ನಪುಂಸಕ ಗಂಡ', rashi: ch22H7, planets: ['ಬುಧ','ಶನಿ']));
    }
    // Sun in 7th → abandoned by husband
    if (ch21SunH == 7) {
      yogas.add(Yoga(shloka: 'ಉತ್ಕೃಷ್ಟಾ ತರಣೇ... (ಸ್ತ್ರೀಜಾತಕ ೮)', name: 'ಪತಿ ತ್ಯಾಗ (ಸ್ತ್ರೀ ೮)', description: 'ಸೂರ್ಯ 7ರಲ್ಲಿ', result: 'ಗಂಡನಿಂದ ತ್ಯಜಿಸಲ್ಪಡುತ್ತಾಳೆ', rashi: ch22H7, planets: ['ರವಿ']));
    }
    // Mars in 7th → early widowhood
    if (ch21MarsH == 7) {
      yogas.add(Yoga(shloka: 'ಕುಜೇ ತು ವಿಧವಾ... (ಸ್ತ್ರೀಜಾತಕ ೮)', name: 'ಬಾಲ ವೈಧವ್ಯ (ಸ್ತ್ರೀ ೮)', description: 'ಕುಜ 7ರಲ್ಲಿ', result: 'ಬಾಲ್ಯದಲ್ಲಿ ವಿಧವೆ', rashi: ch22H7, planets: ['ಕುಜ']));
    }

    // Shloka 9: Papa in 7th → widowhood; mixed → remarriage
    final papaIn7th = ch21Sun==ch22H7||ch21Mars==ch22H7||ch21Sat==ch22H7||ch21Rahu==ch22H7;
    final shubIn7th = ch21Jup==ch22H7||ch21Ven==ch22H7||ch21Mer==ch22H7;
    if (papaIn7th && !shubIn7th) {
      yogas.add(Yoga(shloka: 'ಆಗ್ನಯ್ಕೇರ್ವಿಧವಾ... (ಸ್ತ್ರೀಜಾತಕ ೯)', name: 'ವೈಧವ್ಯ ಯೋಗ (ಸ್ತ್ರೀ ೯)', description: 'ಪಾಪ 7ರಲ್ಲಿ ಶುಭ ಇಲ್ಲ', result: 'ವಿಧವೆ', rashi: ch22H7, planets: ['ಪಾಪ']));
    } else if (papaIn7th && shubIn7th) {
      yogas.add(Yoga(shloka: 'ಮಿಶ್ನೆ ಪುನರ್ಭೂ... (ಸ್ತ್ರೀಜಾತಕ ೯)', name: 'ಪುನರ್ವಿವಾಹ (ಸ್ತ್ರೀ ೯)', description: 'ಪಾಪ+ಶುಭ 7ರಲ್ಲಿ', result: 'ಪುನರ್ವಿವಾಹ', rashi: ch22H7, planets: ['ಮಿಶ್ರ']));
    }
    // Venus+Mars mutual navamsha → vyabhicharini
    final ch22MarsNavLord = rashiLords[ch22MarsNav];
    if (ch22VenNavLord=='Mars' && ch22MarsNavLord=='Venus') {
      yogas.add(Yoga(shloka: 'ಅನ್ನೋನ್ಯಾಂಶಗಯೋಃ ಸಿತಾವನಿಜಯೋಃ... (ಸ್ತ್ರೀಜಾತಕ ೯)', name: 'ವ್ಯಭಿಚಾರ ಯೋಗ (ಸ್ತ್ರೀ ೯)', description: 'ಶುಕ್ರ-ಕುಜ ಪರಸ್ಪರ ನವಾಂಶ', result: 'ವ್ಯಭಿಚಾರಿಣಿ', rashi: ch21Ven, planets: ['ಶುಕ್ರ','ಕುಜ']));
    }

    // Shloka 11-12: 7th house lord → husband quality
    final ch22H7RashiLord = rashiLords[ch22H7];
    final ch22Res11 = <String,String>{
      'Saturn': 'ವೃದ್ಧ ಮತ್ತು ಮೂರ್ಖ ಗಂಡ', 'Mars': 'ಸ್ತ್ರೀಲೋಲ ಕೋಪಿಷ್ಟ ಗಂಡ',
      'Venus': 'ಸುಂದರ ಸೌಭಾಗ್ಯವಂತ ಗಂಡ', 'Mercury': 'ವಿದ್ವಾಂಸ ನಿಪುಣ ಗಂಡ',
      'Moon': 'ಕಾಮಾತುರ ಮೃದು ಗಂಡ', 'Jupiter': 'ಗುಣವಂತ ಜಿತೇಂದ್ರಿಯ ಗಂಡ',
      'Sun': 'ಅತಿ ಮೃದು ಕರ್ಮಠ ಗಂಡ',
    };
    final ch22H7Res = ch22Res11[ch22H7RashiLord];
    if (ch22H7Res != null) {
      yogas.add(Yoga(shloka: 'ವೃದ್ಧೋ ಮೂರ್ಖ... (ಸ್ತ್ರೀಜಾತಕ ೧೧-೧೨)', name: 'ಪತಿ ಗುಣ (ಸ್ತ್ರೀ ೧೧)', description: '7ನೇ ಮನೆ ${_rashiNames[ch22H7]} (${ch22H7RashiLord})', result: ch22H7Res, rashi: ch22H7, planets: ['7ನೇ ಮನೆ']));
    }

    // Shloka 13: Venus+Moon in lagna
    if (ch21Ven==lagRashi && ch21Moon==lagRashi) {
      yogas.add(Yoga(shloka: 'ಈರ್ಷ್ಯಾನ್ವಿತಾ ಸುಖಪರಾ... (ಸ್ತ್ರೀಜಾತಕ ೧೩)', name: 'ಶುಕ್ರ-ಚಂದ್ರ ಲಗ್ನ (ಸ್ತ್ರೀ ೧೩)', description: 'ಶುಕ್ರ+ಚಂದ್ರ ಲಗ್ನದಲ್ಲಿ', result: 'ಅಸೂಯಾಪರಳು, ಸುಖಾಪೇಕ್ಷಿ', rashi: lagRashi, planets: ['ಶುಕ್ರ','ಚಂದ್ರ']));
    }
    // Mercury+Moon in lagna
    if (ch21Mer==lagRashi && ch21Moon==lagRashi) {
      yogas.add(Yoga(shloka: 'ಕಲಾಸು ನಿಪುಣಾ... (ಸ್ತ್ರೀಜಾತಕ ೧೩)', name: 'ಕಲಾ ನಿಪುಣ (ಸ್ತ್ರೀ ೧೩)', description: 'ಬುಧ+ಚಂದ್ರ ಲಗ್ನದಲ್ಲಿ', result: 'ಕಲೆಗಳಲ್ಲಿ ನಿಪುಣಳು, ಸುಖಿ, ಗುಣವಂತಳು', rashi: lagRashi, planets: ['ಬುಧ','ಚಂದ್ರ']));
    }
    // Venus+Mercury in lagna
    if (ch21Ven==lagRashi && ch21Mer==lagRashi) {
      yogas.add(Yoga(shloka: 'ಶುಕಷ್ಣಯೋಸ್ತು ಸುಭಗಾ... (ಸ್ತ್ರೀಜಾತಕ ೧೩)', name: 'ಸುಭಗ ಕಲಾಜ್ಞ (ಸ್ತ್ರೀ ೧೩)', description: 'ಶುಕ್ರ+ಬುಧ ಲಗ್ನದಲ್ಲಿ', result: 'ಸುಭಗ, ಕಾಂತಿಯುತಳು, ಕಲಾಪ್ರವೀಣಳು', rashi: lagRashi, planets: ['ಶುಕ್ರ','ಬುಧ']));
    }

    // Shloka 14: Papa in 8th → widowhood
    final papaIn8 = ch21Sun==ch22H8||ch21Mars==ch22H8||ch21Sat==ch22H8||ch21Rahu==ch22H8;
    if (papaIn8) {
      yogas.add(Yoga(shloka: 'ಕ್ರೂರೇ ಷ್ಣಮೇ ವಿಧವತಾ... (ಸ್ತ್ರೀಜಾತಕ ೧೪)', name: 'ವೈಧವ್ಯ ಯೋಗ-೨ (ಸ್ತ್ರೀ ೧೪)', description: 'ಪಾಪಗ್ರಹ 8ನೇ ಮನೆಯಲ್ಲಿ', result: 'ವಿಧವೆಯಾಗುತ್ತಾಳೆ', rashi: ch22H8, planets: ['ಪಾಪ']));
    }
    // Shubha in 8th → she dies first
    final shubIn8 = ch21Jup==ch22H8||ch21Ven==ch22H8||ch21Mer==ch22H8;
    if (shubIn8) {
      yogas.add(Yoga(shloka: 'ಸತ್ತ್ವರ್ಥಗೇಷು ಮರಣಂ ಸ್ವಯಮೇವ... (ಸ್ತ್ರೀಜಾತಕ ೧೪)', name: 'ಸ್ವಮರಣ ಮೊದಲು (ಸ್ತ್ರೀ ೧೪)', description: 'ಶುಭಗ್ರಹ 8ನೇ ಮನೆಯಲ್ಲಿ', result: 'ಗಂಡನ ಮೊದಲೇ ಮರಣ', rashi: ch22H8, planets: ['ಶುಭ']));
    }

    // Shloka 14: Moon in Kanya/Vrischika/Vrishabha/Simha → few children
    if (ch21Moon==5||ch21Moon==7||ch21Moon==1||ch21Moon==4) {
      yogas.add(Yoga(shloka: 'ಕಾಲಿಗೋಹರಿಸು ಅಲ್ಪಸುತ... (ಸ್ತ್ರೀಜಾತಕ ೧೪)', name: 'ಅಲ್ಪ ಸಂತಾನ (ಸ್ತ್ರೀ ೧೪)', description: 'ಚಂದ್ರ ${_rashiNames[ch21Moon]}ದಲ್ಲಿ', result: 'ಕಡಿಮೆ ಮಕ್ಕಳು', rashi: ch21Moon, planets: ['ಚಂದ್ರ']));
    }

    // ═══════════════════════════════════════════════════
    // Chapter 23: ನೈರ್ಯಾಣಿಕಾಧ್ಯಾಯ (Nairyanikadhyaya)
    // ═══════════════════════════════════════════════════
    final ch23H8 = (lagRashi+7)%12;
    final ch23H8Lord = rashiLords[ch23H8];
    final ch23SunH = getBhava(_rashiOf(sun), lagRashi);
    final ch23MoonH = getBhava(_rashiOf(moonLon), lagRashi);
    final ch23MarsH = getBhava(_rashiOf(mars), lagRashi);
    final ch23SatH = getBhava(_rashiOf(sat), lagRashi);
    final ch23JupH = getBhava(_rashiOf(jup), lagRashi);
    final ch23SunR = _rashiOf(sun);
    final ch23MoonR = _rashiOf(moonLon);
    final ch23MarsR = _rashiOf(mars);
    final ch23SatR = _rashiOf(sat);

    // Shloka 1: Planet in 8th → death cause
    final ch23DeathCause = <String,String>{
      'Sun': 'ಬೆಂಕಿಯಿಂದ ಮರಣ', 'Moon': 'ನೀರಿನಿಂದ ಮರಣ',
      'Mars': 'ಆಯುಧದಿಂದ ಮರಣ', 'Mercury': 'ಜ್ವರದಿಂದ ಮರಣ',
      'Jupiter': 'ರೋಗದಿಂದ ಮರಣ', 'Venus': 'ಬಾಯಾರಿಕೆಯಿಂದ ಮರಣ',
      'Saturn': 'ಹಸಿವಿನಿಂದ ಮರಣ',
    };
    for (final pName in ['Sun','Moon','Mars','Mercury','Jupiter','Venus','Saturn']) {
      final pLon = pName=='Sun'?sun:pName=='Moon'?moonLon:pName=='Mars'?mars:pName=='Mercury'?mer:pName=='Jupiter'?jup:pName=='Venus'?ven:sat;
      if (_rashiOf(pLon)==ch23H8) {
        final cause = ch23DeathCause[pName] ?? '';
        yogas.add(Yoga(shloka: 'ಮೃತ್ಯುರ್ಮೃತ್ಯುಗೃಹೇಕ್ಷಣೇನ... (ನೈರ್ಯಾಣಿಕ ೧)', name: 'ಮೃತ್ಯು ಕಾರಣ (ನೈ ೧)', description: '$pName 8ನೇ ಮನೆಯಲ್ಲಿ', result: cause, rashi: ch23H8, planets: [pName]));
        break;
      }
    }

    // Shloka 1: 8th house rashi type → death location
    final ch23H8Type = ch23H8 % 3; // 0=chara,1=sthira,2=dvi
    final ch23Loc = ch23H8Type==0?'ಪರದೇಶದಲ್ಲಿ ಮರಣ':ch23H8Type==1?'ಸ್ವದೇಶದಲ್ಲಿ ಮರಣ':'ದಾರಿಯಲ್ಲಿ ಮರಣ';
    yogas.add(Yoga(shloka: 'ಚರಾದಿಷು ಪರಸ್ವಾಧ್ವ... (ನೈರ್ಯಾಣಿಕ ೧)', name: 'ಮೃತ್ಯು ಸ್ಥಳ (ನೈ ೧)', description: '8ನೇ ಮನೆ ${_rashiNames[ch23H8]}', result: ch23Loc, rashi: ch23H8, planets: ['8ನೇ ಮನೆ']));

    // Shloka 2: Sun+Mars in 10&4 → fall from hill
    if ((ch23SunH==10&&ch23MarsH==4)||(ch23SunH==4&&ch23MarsH==10)) {
      yogas.add(Yoga(shloka: 'ಶೈಲಾಗ್ರಾಭಿಹತಸ್ಯ... (ನೈರ್ಯಾಣಿಕ ೨)', name: 'ಶೈಲಪತನ ಮೃತ್ಯು (ನೈ ೨)', description: 'ಸೂರ್ಯ+ಕುಜ 10/4ರಲ್ಲಿ', result: 'ಬೆಟ್ಟದಿಂದ ಬಿದ್ದು ಮರಣ', rashi: ch23H8, planets: ['ರವಿ','ಕುಜ']));
    }
    // Sat+Moon+Mars in 1,4,10 → well death
    if ((ch23SatH==1||ch23SatH==4||ch23SatH==10)&&(ch23MoonH==1||ch23MoonH==4||ch23MoonH==10)&&(ch23MarsH==1||ch23MarsH==4||ch23MarsH==10)&&ch23SatH!=ch23MoonH&&ch23MoonH!=ch23MarsH&&ch23SatH!=ch23MarsH) {
      yogas.add(Yoga(shloka: 'ಕೂಪೇ ಮಂದಶಶಾಂಕ... (ನೈರ್ಯಾಣಿಕ ೨)', name: 'ಕೂಪ ಮೃತ್ಯು (ನೈ ೨)', description: 'ಶನಿ+ಚಂದ್ರ+ಕುಜ 1/4/10', result: 'ಬಾವಿಗೆ ಬಿದ್ದು ಮರಣ', rashi: ch23H8, planets: ['ಶನಿ','ಚಂದ್ರ','ಕುಜ']));
    }
    // Sun+Moon in 1&7 → drowning
    if ((ch23SunH==1&&ch23MoonH==7)||(ch23SunH==7&&ch23MoonH==1)) {
      yogas.add(Yoga(shloka: 'ಉಭಯೋದಯೇsರ್ಕಶಶಿನೌ ತೋಯೇ... (ನೈರ್ಯಾಣಿಕ ೨)', name: 'ಜಲಮರಣ (ನೈ ೨)', description: 'ಸೂರ್ಯ+ಚಂದ್ರ 1/7ರಲ್ಲಿ', result: 'ನೀರಿನಲ್ಲಿ ಮುಳುಗಿ ಮರಣ', rashi: ch23H8, planets: ['ರವಿ','ಚಂದ್ರ']));
    }

    // Shloka 3: Saturn in Karkata → jalodhara death
    if (ch23SatR==3) {
      yogas.add(Yoga(shloka: 'ಮಂದೇ ಕರ್ಕಟಕೇ ಜಲೋದರ... (ನೈರ್ಯಾಣಿಕ ೩)', name: 'ಜಲೋದರ ಮೃತ್ಯು (ನೈ ೩)', description: 'ಶನಿ ಕರ್ಕಟದಲ್ಲಿ', result: 'ಜಲೋದರ ರೋಗದಿಂದ ಮರಣ', rashi: 3, planets: ['ಶನಿ']));
    }
    // Moon in Makara → shastra/agni death
    if (ch23MoonR==9) {
      yogas.add(Yoga(shloka: 'ಮೃಗಾಂಕೇ ಮೃಗೇ... (ನೈರ್ಯಾಣಿಕ ೩)', name: 'ಶಸ್ತ್ರಾಗ್ನಿ ಮೃತ್ಯು (ನೈ ೩)', description: 'ಚಂದ್ರ ಮಕರದಲ್ಲಿ', result: 'ಬೆಂಕಿ/ಶಸ್ತ್ರದಿಂದ ಮರಣ', rashi: 9, planets: ['ಚಂದ್ರ']));
    }

    // Shloka 4: Papa in lagna+9th without shubha → bondage death
    final ch23H9 = (lagRashi+8)%12;
    final papLag = ch23SunR==lagRashi||ch23MarsR==lagRashi||ch23SatR==lagRashi;
    final papH9 = ch23SunR==ch23H9||ch23MarsR==ch23H9||ch23SatR==ch23H9;
    if (papLag && papH9) {
      final shubLag = _rashiOf(jup)==lagRashi||_rashiOf(ven)==lagRashi||_rashiOf(mer)==lagRashi;
      final shubH9 = _rashiOf(jup)==ch23H9||_rashiOf(ven)==ch23H9||_rashiOf(mer)==ch23H9;
      if (!shubLag && !shubH9) {
        yogas.add(Yoga(shloka: 'ಲಗ್ನಾಧೀನವಮಸ್ಥಯೋಃ... (ನೈರ್ಯಾಣಿಕ ೪)', name: 'ಬಂಧನ ಮೃತ್ಯು (ನೈ ೪)', description: 'ಪಾಪ ಲಗ್ನ+9, ಶುಭ ದೃಷ್ಟಿ ಇಲ್ಲ', result: 'ಬಂಧನದಿಂದ ಮರಣ', rashi: lagRashi, planets: ['ಪಾಪ']));
      }
    }

    // Shloka 5: Mars 4th+Sun 10th+Sat lagna → trishula death
    if (ch23MarsH==4 && ch23SunH==10 && ch23SatH==1) {
      yogas.add(Yoga(shloka: 'ಶೂಲೋದ್ಧಿನ್ನತನುಃ... (ನೈರ್ಯಾಣಿಕ ೫)', name: 'ಶೂಲ ಮೃತ್ಯು (ನೈ ೫)', description: 'ಕುಜ 4+ಸೂರ್ಯ 10+ಶನಿ ಲಗ್ನ', result: 'ತ್ರಿಶೂಲದಿಂದ ಮರಣ', rashi: ch23H8, planets: ['ಕುಜ','ರವಿ','ಶನಿ']));
    }
    // Sun 4th+Mars 10th+waning Moon+Sat aspect → wood beating death
    if (ch23SunH==4 && ch23MarsH==10) {
      final ch23MoonWane = moonLon > sun ? (moonLon-sun) : (360+moonLon-sun);
      if (ch23MoonWane > 180) {
        yogas.add(Yoga(shloka: 'ಕಾಷ್ಟೇನಾಭಿಹತಃ... (ನೈರ್ಯಾಣಿಕ ೫)', name: 'ಕಾಷ್ಠ ಪ್ರಹಾರ ಮೃತ್ಯು (ನೈ ೫)', description: 'ಸೂರ್ಯ 4+ಕುಜ 10+ಕ್ಷೀಣ ಚಂದ್ರ', result: 'ಕಟ್ಟಿಗೆಯಿಂದ ಮರಣ', rashi: ch23H8, planets: ['ರವಿ','ಕುಜ']));
      }
    }

    // Shloka 7: Mars+Sun+Sat in 4,7,10 → weapon/fire/king death
    if ((ch23MarsH==4||ch23MarsH==7||ch23MarsH==10)&&(ch23SunH==4||ch23SunH==7||ch23SunH==10)&&(ch23SatH==4||ch23SatH==7||ch23SatH==10)) {
      if (ch23MarsH!=ch23SunH&&ch23SunH!=ch23SatH&&ch23MarsH!=ch23SatH) {
        yogas.add(Yoga(shloka: 'ಬಂಧಸ್ತಕರ್ಮಸಹಿತೈ... (ನೈರ್ಯಾಣಿಕ ೭)', name: 'ಆಯುಧ/ಅಗ್ನಿ ಮೃತ್ಯು (ನೈ ೭)', description: 'ಕುಜ+ಸೂರ್ಯ+ಶನಿ 4/7/10', result: 'ಆಯುಧ/ಬೆಂಕಿ/ರಾಜಕೋಪ', rashi: ch23H8, planets: ['ಕುಜ','ರವಿ','ಶನಿ']));
      }
    }

    // Shloka 8: Sun 10th+Mars 4th → vehicle death
    if (ch23SunH==10 && ch23MarsH==4) {
      yogas.add(Yoga(shloka: 'ಖಸ್ಟೇsರ್ಕೇ ಯಾನಪ್ರಪಾತಾತ್... (ನೈರ್ಯಾಣಿಕ ೮)', name: 'ವಾಹನ ಮೃತ್ಯು (ನೈ ೮)', description: 'ಸೂರ್ಯ 10+ಕುಜ 4', result: 'ವಾಹನದಿಂದ ಬಿದ್ದು ಮರಣ', rashi: ch23H8, planets: ['ರವಿ','ಕುಜ']));
    }

    // Shloka 9: Sat in 8th aspected by strong Mars + waning Moon → guhya roga death
    if (ch23SatH==8 && ch23MarsR==ch23H8) {
      yogas.add(Yoga(shloka: 'ನಿಧನಸ್ಥಿತೇsರ್ಕಜೇ... (ನೈರ್ಯಾಣಿಕ ೯)', name: 'ಗುಹ್ಯರೋಗ ಮೃತ್ಯು (ನೈ ೯)', description: 'ಶನಿ 8+ಕುಜ ದೃಷ್ಟಿ', result: 'ಗುಹ್ಯ ರೋಗದಿಂದ ಮರಣ', rashi: ch23H8, planets: ['ಶನಿ','ಕುಜ']));
    }

    // Shloka 10: 22nd drekkana lord → death nature
    final ch23Drek22R = ((lagRashi * 30 + 210 + (lag % 30)) % 360);
    final ch23Drek22Rashi = _rashiOf(ch23Drek22R);
    final ch23Drek22Lord = rashiLords[ch23Drek22Rashi];
    final ch23D22Cause = ch23DeathCause[ch23Drek22Lord] ?? 'ಅಜ್ಞಾತ ಕಾರಣ';
    yogas.add(Yoga(shloka: 'ದ್ವಾವಿಂಶಃ ಕಥಿತಸ್ತು... (ನೈರ್ಯಾಣಿಕ ೧೦)', name: '22ನೇ ದ್ರೇಕ್ಕಾಣ (ನೈ ೧೦)', description: '22ನೇ ದ್ರೇಕ್ಕಾಣ: ${_rashiNames[ch23Drek22Rashi]} ($ch23Drek22Lord)', result: ch23D22Cause, rashi: ch23Drek22Rashi, planets: [ch23Drek22Lord ?? '']));

    // Shloka 13: Afterlife destiny from planet strength
    final ch23JupStr = ch23JupH==1||ch23JupH==4||ch23JupH==7||ch23JupH==10;
    final ch23MoonStr = ch23MoonH==1||ch23MoonH==4||ch23MoonH==7||ch23MoonH==10;
    final ch23SatStr = ch23SatH==1||ch23SatH==4||ch23SatH==7||ch23SatH==10;
    if (ch23JupStr) {
      yogas.add(Yoga(shloka: 'ಗುರುರುಡುಪತಿಶುಕ್ರೌ... (ನೈರ್ಯಾಣಿಕ ೧೩)', name: 'ಸ್ವರ್ಗ ಪ್ರಾಪ್ತಿ (ನೈ ೧೩)', description: 'ಗುರು ಕೇಂದ್ರದಲ್ಲಿ ಬಲಶಾಲಿ', result: 'ಸ್ವರ್ಗ ಪ್ರಾಪ್ತಿ', rashi: _rashiOf(jup), planets: ['ಗುರು']));
    } else if (ch23MoonStr) {
      yogas.add(Yoga(shloka: 'ಗುರುರುಡುಪತಿಶುಕ್ರೌ... (ನೈರ್ಯಾಣಿಕ ೧೩)', name: 'ಪಿತೃಲೋಕ (ನೈ ೧೩)', description: 'ಚಂದ್ರ ಕೇಂದ್ರದಲ್ಲಿ', result: 'ಪಿತೃಲೋಕ ಪ್ರಾಪ್ತಿ', rashi: ch23MoonR, planets: ['ಚಂದ್ರ']));
    } else if (ch23SatStr) {
      yogas.add(Yoga(shloka: 'ಗುರುರುಡುಪತಿಶುಕ್ರೌ... (ನೈರ್ಯಾಣಿಕ ೧೩)', name: 'ನರಕ ಸೂಚನೆ (ನೈ ೧೩)', description: 'ಶನಿ ಕೇಂದ್ರದಲ್ಲಿ ಗುರು ದುರ್ಬಲ', result: 'ನರಕ ಭೀತಿ', rashi: ch23SatR, planets: ['ಶನಿ']));
    }

    // Shloka 14: Jupiter in 6/kendra/8 exalted → moksha
    if ((ch23JupH==6||ch23JupH==1||ch23JupH==4||ch23JupH==7||ch23JupH==10||ch23JupH==8)&&_rashiOf(jup)==3) {
      yogas.add(Yoga(shloka: 'ಗುರುರಥ ರಿಪುಕೇಂದ್ರ... (ನೈರ್ಯಾಣಿಕ ೧೪)', name: 'ಮೋಕ್ಷ ಯೋಗ (ನೈ ೧೪)', description: 'ಗುರು ಉಚ್ಚ + ಕೇಂದ್ರ/6/8', result: 'ಮೋಕ್ಷ ಪ್ರಾಪ್ತಿ', rashi: _rashiOf(jup), planets: ['ಗುರು']));
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
