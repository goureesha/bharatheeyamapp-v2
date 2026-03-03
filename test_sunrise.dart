import 'dart:io';
import 'package:sweph/sweph.dart';
import 'dart:math';

double _rad(double d) => d * pi / 180.0;
double _deg(double r) => r * 180.0 / pi;

double getAltitudeManual(double jd, double lat, double lon) {
  try {
    final flags = SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH;
    final res = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, flags);
    final ra = res.longitude;
    final dec = res.latitude;

    final gmst = Sweph.swe_sidtime(jd);
    final lst = gmst + (lon / 15.0);

    var haDeg = ((lst * 15.0) - ra + 360) % 360;
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

List<double> findSunriseSetForDate(int year, int month, int day, double lat, double lon) {
  final jdStart = Sweph.swe_julday(year, month, day, 0.0, CalendarType.SE_GREG_CAL);
  double riseTime = jdStart + 0.25;
  double setTime = jdStart + 0.75;
  double step = 1.0 / 24.0;
  double current = jdStart - 0.3;

  try {
    for (int i = 0; i < 30; i++) {
      double alt1 = getAltitudeManual(current, lat, lon);
      double alt2 = getAltitudeManual(current + step, lat, lon);
      if (alt1 < -0.583 && alt2 >= -0.583) {
        double l = current, h = current + step;
        for (int j = 0; j < 20; j++) {
          double m = (l + h) / 2;
          if (getAltitudeManual(m, lat, lon) < -0.583) {
            l = m;
          } else {
            h = m;
          }
        }
        riseTime = h;
      }
      if (alt1 > -0.583 && alt2 <= -0.583) {
        double l = current, h = current + step;
        for (int j = 0; j < 20; j++) {
          double m = (l + h) / 2;
          if (getAltitudeManual(m, lat, lon) > -0.583) {
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

void main() async {
  await Sweph.init(epheAssets: []);
  final lat = 14.9667;
  final lon = 74.7167;
  final srSs = findSunriseSetForDate(2026, 3, 1, lat, lon);
  print('Dart Sunrise JD: \${srSs[0]}');
  print('Dart Sunset JD: \${srSs[1]}');
}
