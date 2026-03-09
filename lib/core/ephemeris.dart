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

  static List<double> findSunriseSetForDate(int year, int month, int day, double lat, double lon) {
    final jdStart = Sweph.swe_julday(year, month, day, 0.0, CalendarType.SE_GREG_CAL);
    double riseTime = jdStart + 0.25;
    double setTime = jdStart + 0.75;
    double step = 1.0 / 24.0;
    double current = jdStart - 0.3;
    
    try {
      // Using 0.0 for True Horizon Geocentric Sunrise (center of solar disk)
      // Disabling atmospheric refraction & radius corr per Shuddha Drigganitha
      for (int i = 0; i < 30; i++) {
        double alt1 = getAltitudeManual(current, lat, lon);
        double alt2 = getAltitudeManual(current + step, lat, lon);
        if (alt1 < 0.0 && alt2 >= 0.0) {
          double l = current, h = current + step;
          for (int j = 0; j < 20; j++) {
            double m = (l + h) / 2;
            if (getAltitudeManual(m, lat, lon) < 0.0) {
              l = m;
            } else {
              h = m;
            }
          }
          riseTime = h;
        }
        if (alt1 > 0.0 && alt2 <= 0.0) {
          double l = current, h = current + step;
          for (int j = 0; j < 20; j++) {
            double m = (l + h) / 2;
            if (getAltitudeManual(m, lat, lon) > 0.0) {
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

    double ayn = 0.0;
    switch (ayanamsaMode) {
      case 'raman': ayn = ayanamsaRaman(jd); break;
      case 'kp': ayn = ayanamsaKP(jd); break;
      default: ayn = ayanamsaLahiri(jd); break;
    }

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
