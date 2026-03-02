import 'dart:io';
import 'lib/core/ephemeris.dart';
import 'lib/core/calculator.dart';
import 'package:sweph/sweph.dart';

void main() async {
  await Sweph.init(epheAssets: []);
  final lat = 14.9667;
  final lon = 74.7167;
  final dob = DateTime(2026, 3, 1, 17, 6);
  final jdBirth = Sweph.swe_julday(dob.year, dob.month, dob.day, 17 + 6/60.0 - 5.5, CalendarType.SE_GREG_CAL);
  
  final res = AstroCalculator.calcMandi(
    jdBirth: jdBirth,
    lat: lat,
    lon: lon,
    dobObj: dob,
  );
  
  print('Result: \');
}
