import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sweph/sweph.dart';
import '../constants/strings.dart';
import 'ephemeris.dart';
import 'shadbala.dart';

// ============================================================
// KUNDALI RESULT DATA MODELS
// ============================================================

class PlanetInfo {
  final String name;
  final double longitude; // sidereal, degrees
  final double speed;
  final String nakshatra;
  final int pada;
  final String rashi;
  final int rashiIndex;
  final String subDrekD1;
  final String subDrekD9;
  final String subDrekD12;
  final String d9OfD9;

  PlanetInfo({
    required this.name,
    required this.longitude,
    required this.speed,
    required this.nakshatra,
    required this.pada,
    required this.rashi,
    required this.rashiIndex,
    required this.subDrekD1,
    required this.subDrekD9,
    required this.subDrekD12,
    required this.d9OfD9,
  });
}

class PanchangData {
  final String vara;
  final String tithi;
  final String nakshatra;
  final String yoga;
  final String karana;
  final String chandraRashi;
  final String udayadiGhati;
  final String gataGhati;
  final String paramaGhati;
  final String shesha;
  final String dashaBalance;
  final String dashaLord;
  final int nakshatraIndex;
  final double nakPercent;
  final String sunrise;
  final String sunset;
  // New Panchanga fields
  final String suryaNakshatra;
  final String suryaPada;
  final String souraMasa;
  final String souraMasaGataDina;
  final String chandraMasa;
  final String samvatsara;
  final String vishaPraghati;
  final String amrutaPraghati;

  PanchangData({
    required this.vara,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.chandraRashi,
    required this.udayadiGhati,
    required this.gataGhati,
    required this.paramaGhati,
    required this.shesha,
    required this.dashaBalance,
    required this.dashaLord,
    required this.nakshatraIndex,
    required this.nakPercent,
    required this.sunrise,
    required this.sunset,
    this.suryaNakshatra = '',
    this.suryaPada = '',
    this.souraMasa = '',
    this.souraMasaGataDina = '',
    this.chandraMasa = '',
    this.samvatsara = '',
    this.vishaPraghati = '',
    this.amrutaPraghati = '',
  });
}

class DashaEntry {
  final String lord;
  final DateTime start;
  final DateTime end;
  final List<DashaEntry> antardashas;

  DashaEntry({
    required this.lord,
    required this.start,
    required this.end,
    this.antardashas = const [],
  });
}

class KundaliResult {
  final Map<String, PlanetInfo> planets; // key = Kannada planet name
  final List<double> bhavas; // 12 house cusps
  final PanchangData panchang;
  final List<DashaEntry> dashas;
  final Map<String, Map<String, double>> shadbala; // 6-fold planetary strength
  final Map<String, double> advSphutas; // 16 upagrahas

  KundaliResult({
    required this.planets,
    required this.bhavas,
    required this.panchang,
    required this.dashas,
    required this.shadbala,
    required this.advSphutas,
  });
}

// ============================================================
// HELPER FORMATTING
// ============================================================

String formatGhati(double decVal) {
  final g = decVal.floor();
  final rem = decVal - g;
  final v = (rem * 60).round();
  final vActual = v == 60 ? 0 : v;
  final gActual = v == 60 ? g + 1 : g;
  return '$gActual.${vActual.toString().padLeft(2, '0')}';
}

String formatDeg(double deg) {
  final rem = deg % 30;
  final tSec = (rem * 3600).round();
  int dg = tSec ~/ 3600;
  int mn = (tSec % 3600) ~/ 60;
  int sc = tSec % 60;
  if (dg == 30) { dg = 29; mn = 59; sc = 59; }
  return '$dg° ${mn.toString().padLeft(2, '0')}\' ${sc.toString().padLeft(2, '0')}"';
}

String formatTimeFromJd(double jd, {double tzOffset = 5.5}) {
  // Add 0.5 because JD starts at noon UT, and add TZ offset
  final localJd = jd + 0.5 + (tzOffset / 24.0);
  final frac = localJd - localJd.floor();
  
  int totalMinutes = (frac * 24 * 60).round();
  int h = totalMinutes ~/ 60;
  int m = totalMinutes % 60;
  
  if (h == 24) h = 0;
  
  String amPm = h >= 12 ? 'PM' : 'AM';
  int hStr = h % 12;
  if (hStr == 0) hStr = 12;
  
  return '${hStr.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $amPm';
}

// ============================================================
// MAIN CALCULATOR  — exact port of Python logic
// ============================================================
class AstroCalculator {
  static const double _nakSize = 13.333333333;

  static String _norm(double d) => ((d % 360) + 360).remainder(360).toStringAsFixed(4);

  static double normDeg(double d) => ((d % 360) + 360) % 360;

  // ─────────────────────────────────────────────
  // Nakshatra info from longitude
  // ─────────────────────────────────────────────
  static (String nak, int pada) nakFromDeg(double deg) {
    final idx = (deg / _nakSize).floor() % 27;
    final pada = ((deg % _nakSize) / (_nakSize / 4)).floor() + 1;
    return (knNak[idx], pada.clamp(1, 4));
  }

  // ─────────────────────────────────────────────
  // MANDI calculation — exact Python port
  // ─────────────────────────────────────────────
  static List<dynamic> calcMandi({
    required double jdBirth,
    required double lat,
    required double lon,
    required DateTime dobObj,
  }) {
    int y = dobObj.year;
    int m = dobObj.month;
    int d = dobObj.day;
    
    List<double> srSs = Ephemeris.findSunriseSetForDate(y, m, d, lat, lon);
    double srCivil = srSs[0];
    double ssCivil = srSs[1];
    
    // Python datetime.weekday() == Monday is 0, Sunday is 6
    // Dart DateTime.weekday == Monday is 1, Sunday is 7
    int pyWeekday = dobObj.weekday - 1;
    int civilWeekdayIdx = (pyWeekday + 1) % 7; 
    
    bool isNight = false;
    if (jdBirth >= srCivil && jdBirth < ssCivil) {
      isNight = false;
    } else {
      isNight = true;
    }
    
    double startBase = 0.0;
    double duration = 0.0;
    int vedicWday = 0;
    double panchSr = 0.0;
    
    if (!isNight) {
      vedicWday = civilWeekdayIdx;
      panchSr = srCivil;
      startBase = srCivil;
      duration = ssCivil - srCivil;
    } else {
      if (jdBirth < srCivil) {
        vedicWday = (civilWeekdayIdx - 1) % 7;
        if (vedicWday < 0) vedicWday += 7;
        DateTime prevD = dobObj.subtract(const Duration(days: 1));
        List<double> pSrSs = Ephemeris.findSunriseSetForDate(prevD.year, prevD.month, prevD.day, lat, lon);
        startBase = pSrSs[1];
        duration = srCivil - pSrSs[1];
        panchSr = pSrSs[0];
      } else {
        vedicWday = civilWeekdayIdx;
        DateTime nextD = dobObj.add(const Duration(days: 1));
        List<double> nSrSs = Ephemeris.findSunriseSetForDate(nextD.year, nextD.month, nextD.day, lat, lon);
        startBase = ssCivil;
        duration = nSrSs[0] - ssCivil;
        panchSr = srCivil;
      }
    }
    
    List<int> factors;
    if (!isNight) {
      factors = [26, 22, 18, 14, 10, 6, 2];
    } else {
      factors = [10, 6, 2, 26, 22, 18, 14];
    }
    
    int factor = factors[vedicWday];
    double mandiJd = startBase + (duration * factor / 30.0);
    
    return [mandiJd, isNight, panchSr, vedicWday, startBase, srCivil, ssCivil];
  }

  static double _getAyanamsa(double jd, String mode) {
    switch (mode) {
      case 'raman': return Ephemeris.ayanamsaRaman(jd);
      case 'kp':    return Ephemeris.ayanamsaKP(jd);
      default:      return Ephemeris.ayanamsaLahiri(jd);
    }
  }

  // ─────────────────────────────────────────────
  // Find nakshatra boundary (binary search) — Python port
  // ─────────────────────────────────────────────
  static double findNakLimit(double jd, double targetDeg, String ayanamsaMode) {
    double low = jd - 1.2, high = jd + 1.2;
    for (int i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      final ayn = _getAyanamsa(mid, ayanamsaMode);
      final planets = Ephemeris.calcAll(mid, ayanamsaMode, true);
      final moonTrop = planets['Moon']![0] + ayn; // back to tropical
      final mDeg = normDeg(moonTrop - ayn);
      final diff = ((mDeg - targetDeg + 180) % 360) - 180;
      if (diff < 0) low = mid; else high = mid;
    }
    return (low + high) / 2;
  }

  // ─────────────────────────────────────────────
  // SHADBALA Logic applied externally
  // ─────────────────────────────────────────────
  }

  // ─────────────────────────────────────────────
  // VIMSHOTTARI DASHA — exact Python port
  // ─────────────────────────────────────────────
  static List<DashaEntry> calcDasha(DateTime birthDate, int nIdx, double perc) {
    final List<DashaEntry> result = [];
    DateTime cur = birthDate;
    final si = nIdx % 9;

    for (int i = 0; i < 9; i++) {
      final im = (si + i) % 9;
      final yMul = (i == 0) ? (1 - perc) : 1.0;
      final mdDays = (dashaYears[im] * yMul * 365.25).round();
      final mdEnd = cur.add(Duration(days: mdDays));

      final List<DashaEntry> antars = [];
      DateTime cad = cur;
      for (int j = 0; j < 9; j++) {
        final ia = (im + j) % 9;
        double adY = dashaYears[im] * dashaYears[ia] / 120.0;
        if (i == 0) adY *= (1 - perc);
        final adDays = (adY * 365.25).round();
        final ae = cad.add(Duration(days: adDays));
        
        final List<DashaEntry> pratyantars = [];
        DateTime cpd = cad;
        for (int k = 0; k < 9; k++) {
          final ip = (ia + k) % 9;
          double pdY = (dashaYears[im] * dashaYears[ia] * dashaYears[ip]) / (120.0 * 120.0);
          if (i == 0) pdY *= (1 - perc);
          final pdDays = (pdY * 365.25).round();
          final pe = cpd.add(Duration(days: pdDays));
          pratyantars.add(DashaEntry(lord: dashaLords[ip], start: cpd, end: pe));
          cpd = pe;
        }

        antars.add(DashaEntry(lord: dashaLords[ia], start: cad, end: ae, antardashas: pratyantars));
        cad = ae;
      }

      result.add(DashaEntry(
        lord: dashaLords[im],
        start: cur,
        end: mdEnd,
        antardashas: antars,
      ));
      cur = mdEnd;
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // FULL CALCULATION — main entry point
  // ─────────────────────────────────────────────
  static Future<KundaliResult?> calculate({
    required int year,
    required int month,
    required int day,
    required double hourUtcOffset, // hours offset from UTC (IST = 5.5)
    required double hour24,        // local time in hours
    required double lat,
    required double lon,
    required String ayanamsaMode,  // 'lahiri','raman','kp'
    required bool trueNode,
  }) async {
    try {
      await Ephemeris.initSweph();
      final jdBirth = Sweph.swe_julday(year, month, day, hour24 - hourUtcOffset, CalendarType.SE_GREG_CAL);
      final dob = DateTime(year, month, day);
      final ayn = _getAyanamsa(jdBirth, ayanamsaMode);

      // Planet positions
      final rawPlanets = Ephemeris.calcAll(jdBirth, ayanamsaMode, trueNode);

      final Map<String, double> positions = {};
      final Map<String, double> speeds = {};
      const engToKn = {
        'Sun': 'ರವಿ', 'Moon': 'ಚಂದ್ರ', 'Mercury': 'ಬುಧ', 'Venus': 'ಶುಕ್ರ',
        'Mars': 'ಕುಜ', 'Jupiter': 'ಗುರು', 'Saturn': 'ಶನಿ',
        'Rahu': 'ರಾಹು', 'Ketu': 'ಕೇತು',
      };

      for (final entry in rawPlanets.entries) {
        final kn = engToKn[entry.key]!;
        positions[kn] = entry.value[0];
        speeds[kn] = entry.value[1];
      }

      // Lagna (Ascendant) and Bhavas using Sripathi/Porphyry (Linear Ecliptic Trisection)
      final housesRes = Ephemeris.placidusHousesFull(jdBirth, lat, lon);
      double ascDeg = 0.0;
      List<double> bhavaSphutas = List.filled(12, 0.0);
      
      if (housesRes != null && housesRes.ascmc.length >= 2) {
        final tropicalAsc = housesRes.ascmc[0];
        final tropicalMC = housesRes.ascmc[1];
        
        // Exact sidereal anchors
        final h1 = normDeg(tropicalAsc - ayn);
        final h10 = normDeg(tropicalMC - ayn);
        
        ascDeg = h1;
        
        // Cardinal houses
        final h4 = normDeg(h10 + 180.0);
        final h7 = normDeg(h1 + 180.0);
        
        // Trisection of Arc 1 (Ascendant to IC) -> Houses 2 and 3
        final dist14 = normDeg(h4 - h1);
        final step14 = dist14 / 3.0;
        final h2 = normDeg(h1 + step14);
        final h3 = normDeg(h1 + 2.0 * step14);
        
        // Trisection of Arc 2 (IC to Descendant) -> Houses 5 and 6
        final dist47 = normDeg(h7 - h4);
        final step47 = dist47 / 3.0;
        final h5 = normDeg(h4 + step47);
        final h6 = normDeg(h4 + 2.0 * step47);
        
        // Opposite houses
        final h8 = normDeg(h2 + 180.0);
        final h9 = normDeg(h3 + 180.0);
        final h11 = normDeg(h5 + 180.0);
        final h12 = normDeg(h6 + 180.0);
        
        // Sripathi Bhava Madhyas (Midpoints)
        bhavaSphutas = [h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12];
      }
      
      positions['ಲಗ್ನ'] = ascDeg;
      speeds['ಲಗ್ನ'] = 0;

      // Mandi
      final mandiRes = calcMandi(jdBirth: jdBirth, lat: lat, lon: lon, dobObj: dob);
      final mandiTimeJd = mandiRes[0] as double;
      final panchSr = mandiRes[2] as double;
      final wIdx = mandiRes[3] as int;
      final srCivil = mandiRes[5] as double;
      final ssCivil = mandiRes[6] as double;
      
      final hMandi = Ephemeris.placidusHousesFull(mandiTimeJd, lat, lon);
      final aMandi = _getAyanamsa(mandiTimeJd, ayanamsaMode);
      double mandiDeg = 0.0;
      if (hMandi != null) {
        mandiDeg = normDeg(hMandi.ascmc[0] - aMandi);
      }
      positions['ಮಾಂದಿ'] = mandiDeg;
      speeds['ಮಾಂದಿ'] = 0;

      // Create PlanetInfo for each
      final Map<String, PlanetInfo> planetInfoMap = {};
      for (final kn in [...positions.keys]) {
        final deg = positions[kn]!;
        final (nak, pada) = nakFromDeg(deg);
        final ri = (deg / 30).floor() % 12;
        final speed = speeds[kn] ?? 0.0;
        final extra = getPlanetDetail(kn, deg, speed, positions['ರವಿ']!);
        
        planetInfoMap[kn] = PlanetInfo(
          name: kn,
          longitude: deg,
          speed: speed,
          nakshatra: nak,
          pada: pada,
          rashi: knRashi[ri],
          rashiIndex: ri,
          subDrekD1: extra['subDrekD1'] as String,
          subDrekD9: extra['subDrekD9'] as String,
          subDrekD12: extra['subDrekD12'] as String,
          d9OfD9: extra['d9OfD9'] as String,
        );
      }

      // Panchang
      final mDeg = positions['ಚಂದ್ರ']!;
      final sDeg = positions['ರವಿ']!;
      final tIdx = (((mDeg - sDeg + 360) % 360) / 12).floor().clamp(0, 29);
      final nIdx  = (mDeg / _nakSize).floor() % 27;
      final yDeg  = (mDeg + sDeg) % 360;
      final yIdx  = (yDeg / _nakSize).floor() % 27;

      final kIdx  = (((mDeg - sDeg + 360) % 360) / 6).floor();
      String kName;
      if (kIdx == 0) kName = 'ಕಿಂಸ್ತುಘ್ನ';
      else if (kIdx == 57) kName = 'ಶಕುನಿ';
      else if (kIdx == 58) kName = 'ಚತುಷ್ಪಾದ';
      else if (kIdx == 59) kName = 'ನಾಗ';
      else {
        const kArr = ['ಬವ', 'ಬಾಲವ', 'ಕೌಲವ', 'ತೈತಿಲ', 'ಗರ', 'ವಣಿಜ', 'ಭದ್ರಾ (ವಿಷ್ಟಿ)'];
        kName = kArr[(kIdx - 1) % 7];
      }

      // Vedic day (Sunrise to Sunrise) calculation for Panchang & Udayadi Ghati
      final udayadiGhati = formatGhati((jdBirth - panchSr) * 60);

      // Nakshatra ghatis
      final js = findNakLimit(jdBirth, nIdx * _nakSize, ayanamsaMode);
      final je = findNakLimit(jdBirth, (nIdx + 1) * _nakSize, ayanamsaMode);
      final gataGhati = formatGhati((jdBirth - js) * 60);
      final paramaGhati = formatGhati((je - js) * 60);
      final sheshaGhati = formatGhati((je - jdBirth) * 60);

      final perc = (mDeg % _nakSize) / _nakSize;
      final bal = dashaYears[nIdx % 9] * (1 - perc);
      final dashaLord = dashaLords[nIdx % 9];

      // === Additional Panchanga Calculations ===
      // Surya Nakshatra & Pada (from Sun longitude)
      final sunDeg = positions['ರವಿ'] ?? 0.0;
      final sunNakIdx = (sunDeg / _nakSize).floor() % 27;
      final sunPada = ((sunDeg % _nakSize) / (_nakSize / 4)).floor() + 1;
      
      // Soura Masa (Solar month = Sun's Rashi)
      final knSouraMasa = ['ಮೇಷ','ವೃಷಭ','ಮಿಥುನ','ಕರ್ಕಾಟಕ','ಸಿಂಹ','ಕನ್ಯಾ','ತುಲಾ','ವೃಶ್ಚಿಕ','ಧನು','ಮಕರ','ಕುಂಭ','ಮೀನ'];
      final sunRashiIdx = (sunDeg / 30).floor() % 12;
      final souraMasa = knSouraMasa[sunRashiIdx];
      final souraMasaGataDina = ((sunDeg % 30)).toStringAsFixed(1);
      
      // Chandra Masa (Amavasyanta system - based on Sun's rashi position)
      // In Amavasyanta: month is named after the rashi the Sun is in at Purnima
      // Sun in Meena = Chaitra, Sun in Mesha = Vaishakha, etc.
      final knChandraMasa = ['ವೈಶಾಖ','ಜ್ಯೇಷ್ಠ','ಆಷಾಢ','ಶ್ರಾವಣ','ಭಾದ್ರಪದ','ಆಶ್ವಿನ','ಕಾರ್ತಿಕ','ಮಾರ್ಗಶಿರ','ಪುಷ್ಯ','ಮಾಘ','ಫಾಲ್ಗುಣ','ಚೈತ್ರ'];
      final chandraMasa = knChandraMasa[sunRashiIdx];
      
      // Samvatsara (Shalivahana Shaka - changes at Ugadi/Chaitra Shukla Pratipada)
      // Shaka year = Gregorian year - 78; before Ugadi (~March/April), use previous year
      final knSamvatsara = [
        'ಪ್ರಭವ','ವಿಭವ','ಶುಕ್ಲ','ಪ್ರಮೋದೂತ','ಪ್ರಜೋತ್ಪತ್ತಿ','ಆಂಗೀರಸ','ಶ್ರೀಮುಖ','ಭಾವ','ಯುವ','ಧಾತೃ',
        'ಈಶ್ವರ','ಬಹುಧಾನ್ಯ','ಪ್ರಮಾಥಿ','ವಿಕ್ರಮ','ವೃಷ','ಚಿತ್ರಭಾನು','ಸುಭಾನು','ತಾರಣ','ಪಾರ್ಥಿವ','ವ್ಯಯ',
        'ಸರ್ವಜಿತ್','ಸರ್ವಧಾರಿ','ವಿರೋಧಿ','ವಿಕೃತಿ','ಖರ','ನಂದನ','ವಿಜಯ','ಜಯ','ಮನ್ಮಥ','ದುರ್ಮುಖಿ',
        'ಹೇವಿಳಂಬಿ','ವಿಳಂಬಿ','ವಿಕಾರಿ','ಶಾರ್ವರಿ','ಪ್ಲವ','ಶುಭಕೃತ್','ಶೋಭಕೃತ್','ಕ್ರೋಧಿ','ವಿಶ್ವಾವಸು','ಪರಾಭವ',
        'ಪ್ಲವಂಗ','ಕೀಲಕ','ಸೌಮ್ಯ','ಸಾಧಾರಣ','ವಿರೋಧಕೃತ್','ಪರಿಧಾವಿ','ಪ್ರಮಾದೀಚ','ಆನಂದ','ರಾಕ್ಷಸ','ಅನಲ',
        'ಪಿಂಗಳ','ಕಾಳಯುಕ್ತಿ','ಸಿದ್ಧಾರ್ಥಿ','ರೌದ್ರಿ','ದುರ್ಮತಿ','ದುಂದುಭಿ','ರುಧಿರೋದ್ಗಾರಿ','ರಕ್ತಾಕ್ಷಿ','ಕ್ರೋಧನ','ಅಕ್ಷಯ',
      ];
      // Shalivahana Shaka year: Ugadi = Chaitra Shukla Pratipada (Moon-based)
      // Ugadi occurs when the first new moon (Amavasya) passes while Sun is in Meena (11)
      // Before this: still in previous samvatsara. After: new samvatsara.
      // Chaitra = Sun in Meena (11). If Sun hasn't reached Meena yet = before Ugadi.
      // If Sun is in Meena AND tithi is in Shukla paksha (0-14) = Chaitra has started = after Ugadi.
      // If Sun is past Meena (in Mesha 0 or later) = definitely after Ugadi.
      int shakaYear = year - 78;
      bool beforeUgadi;
      if (sunRashiIdx == 9 || sunRashiIdx == 10) {
        // Sun in Makara or Kumbha (Jan-Mar before Meena) = before Ugadi
        beforeUgadi = true;
      } else if (sunRashiIdx == 11 && tIdx >= 15) {
        // Sun entered Meena but still in Krishna paksha (before new moon) = before Ugadi
        beforeUgadi = true;
      } else {
        // Sun past Meena or in Meena Shukla paksha = after Ugadi
        beforeUgadi = false;
      }
      if (beforeUgadi) shakaYear -= 1;
      final samvatsaraIdx = ((shakaYear + 11) % 60);
      final samvatsara = '${knSamvatsara[samvatsaraIdx]} (ಶಕ $shakaYear)';
      
      // Visha Praghati & Amruta Praghati (per nakshatra, in ghatis from sunrise)
      final vishaGhatis = [30,28,22,20,18,26,24,10,14,12,8,6,4,2,30,22,20,14,12,10,8,6,4,2,28,26,24,22,20,18];
      final amrutaGhatis = [6,8,10,4,28,26,20,22,12,16,18,14,24,2,6,8,10,4,28,26,20,22,12,16,18,14,24,2,6,8];
      final vishaG = nIdx < vishaGhatis.length ? vishaGhatis[nIdx] : 0;
      final amrutaG = nIdx < amrutaGhatis.length ? amrutaGhatis[nIdx] : 0;

      final panchang = PanchangData(
        vara: knVara[wIdx],
        tithi: knTithi[tIdx],
        nakshatra: knNak[nIdx],
        yoga: knYoga[yIdx],
        karana: kName,
        chandraRashi: knRashi[(mDeg / 30).floor() % 12],
        udayadiGhati: udayadiGhati,
        gataGhati: gataGhati,
        paramaGhati: paramaGhati,
        shesha: sheshaGhati,
        dashaBalance: '${bal.floor()}ವ ${((bal % 1) * 12).floor()}ತಿ',
        dashaLord: dashaLord,
        nakshatraIndex: nIdx,
        nakPercent: perc,
        sunrise: formatTimeFromJd(srCivil),
        sunset: formatTimeFromJd(ssCivil),
        suryaNakshatra: knNak[sunNakIdx],
        suryaPada: '$sunPada',
        souraMasa: souraMasa,
        souraMasaGataDina: '$souraMasaGataDina°',
        chandraMasa: chandraMasa,
        samvatsara: samvatsara,
        vishaPraghati: '$vishaG ಘಟಿ',
        amrutaPraghati: '$amrutaG ಘಟಿ',
      );

      // Dashas
      final dashas = calcDasha(DateTime(year, month, day), nIdx, perc);

      // Shadbala Calculation
      final shadbalaResults = ShadbalaLogic.calculateShadbala(
        {
          'Sun': positions['ರವಿ'] ?? 0.0,
          'Moon': positions['ಚಂದ್ರ'] ?? 0.0,
          'Mars': positions['ಕುಜ'] ?? 0.0,
          'Mercury': positions['ಬುಧ'] ?? 0.0,
          'Jupiter': positions['ಗುರು'] ?? 0.0,
          'Venus': positions['ಶುಕ್ರ'] ?? 0.0,
          'Saturn': positions['ಶನಿ'] ?? 0.0,
        },
        {
          'Sun': speeds['ರವಿ'] ?? 0.0,
          'Moon': speeds['ಚಂದ್ರ'] ?? 0.0,
          'Mars': speeds['ಕುಜ'] ?? 0.0,
          'Mercury': speeds['ಬುಧ'] ?? 0.0,
          'Jupiter': speeds['ಗುರು'] ?? 0.0,
          'Venus': speeds['ಶುಕ್ರ'] ?? 0.0,
          'Saturn': speeds['ಶನಿ'] ?? 0.0,
        },
        positions['ಲಗ್ನ'] ?? 0.0,
        srCivil, // sunRiseJd
        jdBirth, // birthJd
      );

      // Advanced Sphutas (16) — exact Python port
      final S   = positions['ರವಿ']!;
      final M   = positions['ಚಂದ್ರ']!;
      final J   = positions['ಗುರು']!;
      final V   = positions['ಶುಕ್ರ']!;
      final Ma  = positions['ಕುಜ']!;
      final R   = positions['ರಾಹು']!;
      final Asc = positions['ಲಗ್ನ']!;
      final Md  = positions['ಮಾಂದಿ']!;

      final dhooma     = normDeg(S + 133.333333);
      final vyatipata  = normDeg(360 - dhooma);
      final parivesha  = normDeg(vyatipata + 180);
      final indrachapa = normDeg(360 - parivesha);
      final upaketu    = normDeg(indrachapa + 16.666667);
      final bhrigu     = normDeg((M + R) / 2);
      final beeja      = normDeg(S + V + J);
      final kshetra    = normDeg(M + Ma + J);
      final yogi       = normDeg(S + M + 93.333333);
      final trisphuta  = normDeg(Asc + M + Md);
      final chatusphuta  = normDeg(trisphuta + S);
      final panchasphuta = normDeg(chatusphuta + R);
      final prana      = normDeg(Asc * 5 + Md);
      final deha       = normDeg(M * 8 + Md);
      final mrityu     = normDeg(Md * 7 + S);
      final sookshma   = normDeg(prana + deha + mrityu);

      final advSphutas = <String, double>{
        'ಧೂಮ': dhooma, 'ವ್ಯತೀಪಾತ': vyatipata, 'ಪರಿವೇಷ': parivesha,
        'ಇಂದ್ರಚಾಪ': indrachapa, 'ಉಪಕೇತು': upaketu, 'ಭೃಗು ಬಿ.': bhrigu,
        'ಬೀಜ': beeja, 'ಕ್ಷೇತ್ರ': kshetra, 'ಯೋಗಿ': yogi,
        'ತ್ರಿಸ್ಫುಟ': trisphuta, 'ಚತುಃಸ್ಫುಟ': chatusphuta,
        'ಪಂಚಸ್ಫುಟ': panchasphuta, 'ಪ್ರಾಣ': prana, 'ದೇಹ': deha,
        'ಮೃತ್ಯು': mrityu, 'ಸೂಕ್ಷ್ಮ ತ್ರಿ.': sookshma,
      };

      return KundaliResult(
        planets: planetInfoMap,
        bhavas: bhavaSphutas,
        panchang: panchang,
        dashas: dashas,
        shadbala: shadbalaResults,
        advSphutas: advSphutas,
      );
    } catch (e) {
      debugPrint('AstroCalculator error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // Planet popup detail (Vargas) — exact Python port
  // ─────────────────────────────────────────────
  static Map<String, dynamic> getPlanetDetail(String pName, double deg, double speed, double sunDeg) {
    final degFmt = formatDeg(deg);
    bool isAsta = false;
    String gati = 'ಅನ್ವಯಿಸುವುದಿಲ್ಲ';

    if (!['ರವಿ', 'ರಾಹು', 'ಕೇತು', 'ಲಗ್ನ', 'ಮಾಂದಿ'].contains(pName)) {
      double diff = (deg - sunDeg).abs();
      if (diff > 180) diff = 360 - diff;
      const limits = {'ಚಂದ್ರ': 12, 'ಕುಜ': 17, 'ಬುಧ': 14, 'ಗುರು': 11, 'ಶುಕ್ರ': 10, 'ಶನಿ': 15};
      if (diff <= (limits[pName] ?? 0)) isAsta = true;
      gati = (pName == 'ಚಂದ್ರ') ? 'ನೇರ' : (speed < 0 ? 'ವಕ್ರಿ' : 'ನೇರ');
    } else if (['ರಾಹು', 'ಕೇತು'].contains(pName)) {
      gati = 'ವಕ್ರಿ';
    } else if (pName == 'ರವಿ') {
      gati = 'ನೇರ';
    }

    final d1Idx = (deg / 30).floor() % 12;
    final dr = deg % 30;
    final isOdd = (d1Idx % 2 == 0);

    int d2Idx = isOdd ? (dr < 15 ? 4 : 3) : (dr < 15 ? 3 : 4);
    int trueD3Idx = dr < 10 ? d1Idx : (dr < 20 ? (d1Idx + 4) % 12 : (d1Idx + 8) % 12);
    final d9Exact = (deg * 9) % 360;
    final d9Idx   = (d9Exact / 30).floor() % 12;
    final d12Idx  = (d1Idx + (dr / 2.5).floor()) % 12;

    // Sub-Drekkana Parts
    String p1Part = dr < 10 ? '೧' : (dr < 20 ? '೨' : '೩');
    String d3D1Str = '${knRashi[d1Idx]} $p1Part';

    final degInD9 = d9Exact % 30;
    String p9Part = degInD9 < 10 ? '೧' : (degInD9 < 20 ? '೨' : '೩');
    String d3D9Str = '${knRashi[d9Idx]} $p9Part';

    final degInD12 = (deg % 2.5) * 12;
    String p12Part = degInD12 < 10 ? '೧' : (degInD12 < 20 ? '೨' : '೩');
    String d3D12Str = '${knRashi[d12Idx]} $p12Part';

    // Nava Navamsha (D9 of D9)
    final d81Exact = (deg * 81) % 360;
    final d81Idx = (d81Exact / 30).floor() % 12;
    String d9OfD9Str = knRashi[d81Idx];

    int d30Idx;
    if (isOdd) {
      if (dr < 5) d30Idx = 0;
      else if (dr < 10) d30Idx = 10;
      else if (dr < 18) d30Idx = 8;
      else if (dr < 25) d30Idx = 2;
      else d30Idx = 6;
    } else {
      if (dr < 5) d30Idx = 5;
      else if (dr < 12) d30Idx = 2;
      else if (dr < 20) d30Idx = 8;
      else if (dr < 25) d30Idx = 10;
      else d30Idx = 0;
    }

    return {
      'degFmt': degFmt,
      'gati': gati,
      'isAsta': isAsta,
      'd1': knRashi[d1Idx],
      'd2': knRashi[d2Idx],
      'd3': knRashi[trueD3Idx],
      'd9': knRashi[d9Idx],
      'd12': knRashi[d12Idx],
      'd30': knRashi[d30Idx],
      'subDrekD1': d3D1Str,
      'subDrekD9': d3D9Str,
      'subDrekD12': d3D12Str,
      'd9OfD9': d9OfD9Str,
    };
  }
}
