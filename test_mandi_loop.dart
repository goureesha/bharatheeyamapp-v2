import 'dart:math';
import 'package:sweph/sweph.dart';

void main() async {
  await Sweph.init(epheAssets: []);
  double lat = 14.96;
  double lon = 74.71;
  double ayn = 24.1; // approx
  
  double sr = 1.25; // UT 6:45 AM
  double ss = 13.08; // UT 6:35 PM
  double duration = ss - sr;
  
  for(int factor in [26, 22, 18, 14, 10, 6, 2]) {
    double mandiJd = sr + (duration * factor / 30.0);
    SweHouses hres = Sweph.swe_houses(mandiJd, lat, lon, Hsys.P);
    double asc = hres.ascmc[0];
    double ascSidereal = (asc - ayn + 360) % 360;
    print('Factor \ gives \');
  }
}
