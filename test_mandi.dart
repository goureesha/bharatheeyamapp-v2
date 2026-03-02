import 'dart:math';
import 'package:sweph/sweph.dart';

double _rad(double d) => d * pi / 180.0;
double _deg(double r) => r * 180.0 / pi;
double _norm(double d) => (d % 360.0 + 360.0) % 360.0;

double getAltitudeManual(double jd, double lat, double lng) {
  try {
    final calc = Sweph.swe_calc_ut(
        jd, HeavenlyBody.SE_SUN, SwephFlag.SEFLG_EQUATORIAL | SwephFlag.SEFLG_SWIEPH);
    final ra = calc.longitude;
    final dec = calc.latitude;
    final gmst = Sweph.swe_sidtime(jd);
    final lst = gmst + (lng / 15.0);
    double haDeg = ((lst * 15.0) - ra + 360) % 360;
    if (haDeg > 180) haDeg -= 360;
    final sinAlt = sin(_rad(lat)) * sin(_rad(dec)) + cos(_rad(lat)) * cos(_rad(dec)) * cos(_rad(haDeg));
    return _deg(asin(sinAlt.clamp(-1.0, 1.0)));
  } catch (_) { return 0.0; }
}

double findCrossing(int year, int month, int day, double lat, double lng, bool rising) {
  final jd0 = Sweph.swe_julday(year, month, day, 0.0, CalendarType.SE_GREG_CAL);
  double low = jd0 - 0.2;
  double high = jd0 + 1.0;
  double step = 1.0 / 24.0;
  double cur = jd0 - 0.25;
  double bestJd = jd0 + (rising ? 0.25 : 0.75);
  final threshold = -0.583;
  
  for (int i = 0; i < 32; i++) {
    final a1 = getAltitudeManual(cur, lat, lng);
    final a2 = getAltitudeManual(cur + step, lat, lng);
    
    if (rising && a1 < threshold && a2 >= threshold) {
      low = cur; high = cur + step;
      for (int j = 0; j < 20; j++) {
        final mid = (low + high) / 2;
        if (getAltitudeManual(mid, lat, lng) < threshold) low = mid;
        else high = mid;
      }
      return (low + high) / 2;
    } else if (!rising && a1 > threshold && a2 <= threshold) {
      low = cur; high = cur + step;
      for (int j = 0; j < 20; j++) {
        final mid = (low + high) / 2;
        if (getAltitudeManual(mid, lat, lng) > threshold) low = mid;
        else high = mid;
      }
      return (low + high) / 2;
    }
    cur += step;
  }
  return bestJd;
}

void main() async {
  await Sweph.init(epheAssets: []);
  double lat = 14.96;
  double lon = 74.71;
  double jdBirth = Sweph.swe_julday(2026, 3, 1, 11.6, CalendarType.SE_GREG_CAL);
  
  double sr = findCrossing(2026, 3, 1, lat, lon, true);
  double ss = findCrossing(2026, 3, 1, lat, lon, false);
  
  print('jdBirth UT: \');
  print('Sunrise UT: \');
  print('Sunset UT: \');
  
  bool isNight = jdBirth >= ss;
  print('Is Night: \');
  
  double startBase = sr;
  double duration = ss - sr;
  print('Duration (days): \');
  
  int vedicWday = 0; // Sunday
  List<int> dayFactors = [26, 22, 18, 14, 10, 6, 2];
  int factor = dayFactors[vedicWday];
  
  double mandiJd = startBase + (duration * factor / 30.0);
  print('Mandi JD UT: \');
  
  Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
  double ayn = Sweph.swe_get_ayanamsa(mandiJd);
  
  SweHouses hres = Sweph.swe_houses(mandiJd, lat, lon, Hsys.P);
  double asc = hres.ascmc[0];
  double ascSidereal = (asc - ayn + 360) % 360;
  
  print('Ayanamsa: \');
  print('Tropical Ascendant at Mandi JD: \');
  print('Sidereal Ascendant at Mandi JD: \');
}
