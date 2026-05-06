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

    // ═══ Shloka 1: Basic Viyoni ═══
    if (malStrong && benWeak && (malInKendra || malAspKendra)) {
      final d12 = _d12Rashi(moonLon);
      yogas.add(Yoga(
        shloka: 'ಕ್ರೂರಗ್ರಹೈಃ ಸುಬಲಿಭಿರ್ವಿಬಲೈಶ್ಚ ಸೌಮ್ಯಃ ಕ್ಲೀದೇ ಚತುಷ್ಟಯಗತೇ ತದವೇಕ್ಷಣಾದ್ವಾ ।\nಚಂದ್ರೋಪಗದ್ವಿರಸಭಾಗಸಮಾನರೂಪಂ ಸಂ ವದೇದ್ಯದಿ ಭವೇತ್ಸ ವಿಯೋನಿಸಂಜ್ಞ ॥',
        name: 'ವಿಯೋನಿ ಜನ್ಮ ಯೋಗ',
        description: 'ಪಾಪಗ್ರಹರು ಬಲಶಾಲಿ, ಶುಭಗ್ರಹರು ಬಲಹೀನ, ಪಾಪರು ಕೇಂದ್ರದಲ್ಲಿ/ಕೇಂದ್ರ ದೃಷ್ಟಿ',
        result: 'ಪ್ರಾಣಿ ರೂಪ: ${_rashiNames[d12]} → ${_bodyParts[d12]}',
      ));
    }

    // ═══ Shloka 2: Navamsha-based Viyoni ═══
    bool malOwnNav = true;
    for (final e in malLons.entries) {
      if (e.key == 'Rahu' || e.key == 'Ketu') continue;
      if (!_isOwnNavamsha(e.key, _d9Rashi(e.value))) malOwnNav = false;
    }
    final benLons = {'Jupiter':jup,'Venus':ven,'Mercury':mer,'Moon':moon};
    bool benEnemyNav = true;
    for (final e in benLons.entries) {
      if (!_isEnemyNavamsha(e.key, _d9Rashi(e.value))) benEnemyNav = false;
    }
    if (malStrong && malOwnNav && benWeak && benEnemyNav && _animalSigns.contains(lagRashi)) {
      yogas.add(Yoga(
        shloka: 'ಪಾಪಾ ಬಲಿನಃ ಸ್ವಭಾಗಗಾಃ ಪಾರಕ್ಕೇ ವಿಬಲಾಶ್ಚ ಶೋಭನಾಃ ।\nಲಗ್ನಂ ಚ ವಿಯೋನಿಸಂಭವಂ ದೃಷ್ಟಾತಾಪಿ ವಿಯೋನಿಮಾದಿಶೇತ್ ॥',
        name: 'ನವಾಂಶ ವಿಯೋನಿ ಯೋಗ',
        description: 'ಪಾಪರು ಬಲಶಾಲಿ+ಸ್ವನವಾಂಶ, ಶುಭರು ಬಲಹೀನ+ಶತ್ರುನವಾಂಶ, ಲಗ್ನ ವಿಯೋನಿ ರಾಶಿ',
        result: 'ಲಗ್ನ ರಾಶಿ: ${_rashiNames[lagRashi]}',
      ));
    }

    // ═══ Shloka 3: Body part (always shown if shloka 1 or 2 active) ═══
    if (yogas.isNotEmpty) {
      final moonRashi = _rashiOf(moonLon);
      yogas.add(Yoga(
        shloka: 'ಕ್ರಿಯಃ ಶಿರೋ ವಕ್ತಗಲೇ ದ್ವಿತೀಯಃ...',
        name: 'ಚತುಷ್ಪಾದ ಅಂಗ ನಿರ್ಣಯ',
        description: 'ಚಂದ್ರನ ರಾಶಿಯಿಂದ ಪ್ರಾಣಿಯ ದೇಹ ಭಾಗ ನಿರ್ಣಯ',
        result: 'ಚಂದ್ರ ${_rashiNames[moonRashi]} → ${_bodyParts[moonRashi]}',
      ));
    }

    // ═══ Shloka 4: Color & markings (if viyoni active) ═══
    if (yogas.isNotEmpty) {
      final lagNav = _d9Rashi(lag);
      final color = _rashiColors[lagNav];
      final allLons = [sun,moon,mars,mer,jup,ven,sat,rahu,ketu];
      int aspCount = 0;
      for (final l in allLons) {
        if ((_rashiOf(l)+6)%12 == lagRashi) aspCount++;
      }
      final h7 = (lagRashi+6)%12;
      final names = ['ರವಿ','ಚಂದ್ರ','ಕುಜ','ಬುಧ','ಗುರು','ಶುಕ್ರ','ಶನಿ','ರಾಹು','ಕೇತು'];
      final in7 = <String>[];
      for (int i = 0; i < allLons.length; i++) {
        if (_rashiOf(allLons[i]) == h7) in7.add(names[i]);
      }
      yogas.add(Yoga(
        shloka: 'ಲಗ್ನಾಂಶಕಾದ್ ಗ್ರಹಯೋಗೇಕ್ಷಣಾದ್ವಾ...',
        name: 'ವರ್ಣ-ಸಂಖ್ಯಾ-ಚಿಹ್ನೆ ಯೋಗ',
        description: 'ಬಣ್ಣ/ಪ್ರಾಣಿ ಸಂಖ್ಯೆ/ಬೆನ್ನ ಗುರುತು',
        result: 'ಬಣ್ಣ: $color, ಸಂಖ್ಯೆ: $aspCount, ಗುರುತು: ${in7.isEmpty ? "ಇಲ್ಲ" : in7.join(",")}',
      ));
    }

    // ═══ Shloka 5: Bird birth ═══
    final lagDrek = _drekkanaNum(lag);
    final isBirdDrek = _birdDrekkanas.contains((lagRashi, lagDrek));
    bool strongInLag = false;
    for (final e in malLons.entries) {
      if (_rashiOf(e.value) == lagRashi && isStrong(e.key)) strongInLag = true;
    }
    for (final e in benLons.entries) {
      if (_rashiOf(e.value) == lagRashi && isStrong(e.key)) strongInLag = true;
    }
    final lagNav = _d9Rashi(lag);
    final isChara = _charaRashis.contains(lagNav);
    final isMerNav = lagNav == 2 || lagNav == 5;

    if ((isBirdDrek && strongInLag) || isChara || isMerNav) {
      final satR = _rashiOf(sat); final moonR = _rashiOf(moon);
      final satMoon = (satR-moonR).abs()%12 == 0 || (satR+6)%12 == moonR;
      String bType = 'ಸಾಮಾನ್ಯ ಪಕ್ಷಿ';
      if (satMoon) {
        final water = {3,7,11};
        bType = (water.contains(moonR) || water.contains(satR)) ? 'ಜಲಪಕ್ಷಿ' : 'ಭೂಚರ ಪಕ್ಷಿ';
      }
      yogas.add(Yoga(
        shloka: 'ಖಗೇ ದೃಗಾಣೇ ಬಲಸಂಯುತೇನ ವಾ...',
        name: 'ಪಕ್ಷಿ ಜನ್ಮ ಯೋಗ',
        description: 'ಪಕ್ಷಿ ದ್ರೇಕ್ಕಾಣ/ಚರ ನವಾಂಶ/ಬುಧ ನವಾಂಶ ಲಗ್ನ',
        result: 'ಪಕ್ಷಿ ಪ್ರಕಾರ: $bType',
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
  const Yoga({required this.shloka, required this.name, required this.description, required this.result});
}
