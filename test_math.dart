import 'package:sweph/sweph.dart';
import 'package:intl/intl.dart';

void main() async {
  await Sweph.init(epheAssets: []);
  double jd = Sweph.swe_julday(2000, 1, 1, 12, CalendarType.SE_GREG_CAL);
  double lat = 12.9716;
  double lon = 77.5946;
  
  SweHouses res = Sweph.swe_houses(jd, lat, lon, Hsys.P);
  print('Cusps length: \');
  print('Cusps: \');
  print('AscMcs: \');
}
