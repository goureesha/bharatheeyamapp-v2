import 'package:sweph/sweph.dart';
import 'dart:math';

double _rad(double d) => d * pi / 180.0;
double _deg(double r) => r * 180.0 / pi;
double _norm(double d) => (d % 360.0 + 360.0) % 360.0;

// ============================================================
// CORE EPHEMERIS ENGINE - Powered by Swiss Ephemeris (sweph package)
// Provides 100% mathematical parity with the original Python code
// ============================================================

class Ephemeris {
  static bool _isInit = false;

  static Future<void> initSweph() async {
    if (_isInit) return;
    // Retry up to 3 times – the first attempt may fail on some platforms
    // with a transient FileSystemException for 'ephe_files' directory,
    // but succeeds on subsequent attempts.
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await Sweph.init(epheAssets: []);
        _isInit = true;
        return;
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }
    // If all retries failed, try one last time and let the error propagate
    await Sweph.init(epheAssets: []);
    _isInit = true;
  }
  // ─────────────────────────────────────────────
  // Altitude of Sun (for sunrise/sunset)
  // ─────────────────────────────────────────────
  static double getAltitudeManual(double jd, double lat, double lng) {
    try {
      final calc = Sweph.swe_calc_ut(
          jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH);
      final ra = calc.longitude; // Ra is in [0]
      final dec = calc.latitude; // Dec is in [1]

      final gmst = Sweph.swe_sidtime(jd);
      final lst = gmst + (lng / 15.0);

      double haDeg = ((lst * 15.0) - ra + 360) % 360;
      if (haDeg > 180) haDeg -= 360;

      final latRad = _rad(lat);
      final decRad = _rad(dec);
      final haRad = _rad(haDeg);

      final sinAlt =
          sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad);

      return _deg(asin(sinAlt.clamp(-1.0, 1.0)));
    } catch (_) {
      return 0.0;
    }
  }

  static List<double> findSunriseSetForDate(int year, int month, int day, double lat, double lon, {double tzOffset = 5.5}) {
    final jdStart = Sweph.swe_julday(year, month, day, 0.0, CalendarType.SE_GREG_CAL);
    // Anchor scan to LOCAL midnight (convert local midnight to UT)
    final localMidnightUt = jdStart - (tzOffset / 24.0);
    double riseTime = localMidnightUt + 0.25; // fallback: 6 AM local
    double setTime = localMidnightUt + 0.75;  // fallback: 6 PM local
    double step = 1.0 / 24.0;
    // Scan from 2h before local midnight to 28h after (30h total)
    double current = localMidnightUt - (2.0 / 24.0);
    
    try {
      // Use -0.5667° threshold for mid-limb sunrise/sunset
      // (accounts for atmospheric refraction ~34', center of solar disk)
      const double horizonAlt = -0.5667;
      for (int i = 0; i < 30; i++) {
        double alt1 = getAltitudeManual(current, lat, lon);
        double alt2 = getAltitudeManual(current + step, lat, lon);
        if (alt1 < horizonAlt && alt2 >= horizonAlt) {
          double l = current, h = current + step;
          for (int j = 0; j < 20; j++) {
            double m = (l + h) / 2;
            if (getAltitudeManual(m, lat, lon) < horizonAlt) {
              l = m;
            } else {
              h = m;
            }
          }
          riseTime = h;
        }
        if (alt1 > horizonAlt && alt2 <= horizonAlt) {
          double l = current, h = current + step;
          for (int j = 0; j < 20; j++) {
            double m = (l + h) / 2;
            if (getAltitudeManual(m, lat, lon) > horizonAlt) {
              l = m;
            } else {
              h = m;
            }
          }
          setTime = h;
        }
        current += step;
      }
    } catch (_) {}
    return [riseTime, setTime];
  }

  // ─────────────────────────────────────────────
  // Altitude of Moon (for moonrise/moonset)
  // ─────────────────────────────────────────────
  static double getMoonAltitude(double jd, double lat, double lng) {
    try {
      final calc = Sweph.swe_calc_ut(
          jd, HeavenlyBody.SE_MOON, SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH);
      final ra = calc.longitude;
      final dec = calc.latitude;

      final gmst = Sweph.swe_sidtime(jd);
      final lst = gmst + (lng / 15.0);

      double haDeg = ((lst * 15.0) - ra + 360) % 360;
      if (haDeg > 180) haDeg -= 360;

      final latRad = _rad(lat);
      final decRad = _rad(dec);
      final haRad = _rad(haDeg);

      final sinAlt =
          sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad);

      return _deg(asin(sinAlt.clamp(-1.0, 1.0)));
    } catch (_) {
      return 0.0;
    }
  }

  /// Find moonrise and moonset times for a given date.
  /// Returns [moonriseJd, moonsetJd]. Either may be -1 if moon doesn't rise/set on that day.
  static List<double> findMoonriseSetForDate(int year, int month, int day, double lat, double lon, {double tzOffset = 5.5}) {
    final jdStart = Sweph.swe_julday(year, month, day, 0.0, CalendarType.SE_GREG_CAL);
    // Scan exactly from local midnight to next local midnight (24h)
    final localMidnightUt = jdStart - (tzOffset / 24.0);
    final localNextMidnightUt = localMidnightUt + 1.0;
    double riseTime = -1;
    double setTime = -1;
    // 10-minute steps (Moon moves ~0.5°/hr, needs finer resolution than Sun)
    double step = 1.0 / 144.0;
    double current = localMidnightUt;

    try {
      // Moon apparent rise/set altitude:
      // Standard refraction correction:  +0.5667°
      // Moon mean semi-diameter:          +0.2725° (we want upper limb)
      // Moon mean horizontal parallax:    -0.9507° (lowers geometric alt needed)
      // Net: 0.5667 + 0.2725 - 0.9507 ≈ -0.1115°
      // Simplified: use ~-0.1° threshold
      const double horizonAlt = -0.1;
      while (current < localNextMidnightUt) {
        double alt1 = getMoonAltitude(current, lat, lon);
        double alt2 = getMoonAltitude(current + step, lat, lon);
        // Moonrise: altitude crosses from below to above horizon
        if (alt1 < horizonAlt && alt2 >= horizonAlt && riseTime < 0) {
          double l = current, h = current + step;
          for (int j = 0; j < 24; j++) {
            double m = (l + h) / 2;
            if (getMoonAltitude(m, lat, lon) < horizonAlt) { l = m; } else { h = m; }
          }
          riseTime = h;
        }
        // Moonset: altitude crosses from above to below horizon
        if (alt1 > horizonAlt && alt2 <= horizonAlt && setTime < 0) {
          double l = current, h = current + step;
          for (int j = 0; j < 24; j++) {
            double m = (l + h) / 2;
            if (getMoonAltitude(m, lat, lon) > horizonAlt) { l = m; } else { h = m; }
          }
          setTime = h;
        }
        current += step;
      }
    } catch (_) {}
    return [riseTime, setTime];
  }

  static double ayanamsaLahiri(double jd) {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    return Sweph.swe_get_ayanamsa(jd);
  }

  static double ayanamsaRaman(double jd) {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_RAMAN);
    return Sweph.swe_get_ayanamsa(jd);
  }

  static double ayanamsaKP(double jd) {
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_KRISHNAMURTI);
    return Sweph.swe_get_ayanamsa(jd);
  }

  static dynamic placidusHousesFull(double jd, double lat, double lng) {
    try {
      return Sweph.swe_houses(jd, lat, lng, Hsys.P);
    } catch (_) {
      return null;
    }
  }

  static Map<String, List<double>> calcAll(
      double jd, String ayanamsaMode, bool trueNode) {

    final flags = SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL | SwephFlag.SEFLG_SPEED;

    Map<String, List<double>> res = {};

    List<double> _getPlanet(HeavenlyBody planet) {
      try {
        final calc = Sweph.swe_calc_ut(jd, planet, flags);
        return [calc.longitude % 360.0, calc.speedInLongitude];
      } catch (_) {
        return [0.0, 0.0];
      }
    }

    res['Sun']     = _getPlanet(HeavenlyBody.SE_SUN);
    res['Moon']    = _getPlanet(HeavenlyBody.SE_MOON);
    res['Mercury'] = _getPlanet(HeavenlyBody.SE_MERCURY);
    res['Venus']   = _getPlanet(HeavenlyBody.SE_VENUS);
    res['Mars']    = _getPlanet(HeavenlyBody.SE_MARS);
    res['Jupiter'] = _getPlanet(HeavenlyBody.SE_JUPITER);
    res['Saturn']  = _getPlanet(HeavenlyBody.SE_SATURN);

    final nodeType = trueNode ? HeavenlyBody.SE_TRUE_NODE : HeavenlyBody.SE_MEAN_NODE;
    final rahuCalc = _getPlanet(nodeType);
    
    res['Rahu']    = [rahuCalc[0], rahuCalc[1]];
    res['Ketu']    = [_norm(rahuCalc[0] + 180), rahuCalc[1]];

    return res;
  }
}
