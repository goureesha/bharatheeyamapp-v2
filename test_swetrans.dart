import 'dart:io';
import 'package:sweph/sweph.dart';
import 'dart:math';

void main() async {
  await Sweph.init(epheAssets: []);
  final lat = 14.9667;
  final lon = 74.7167;
  final jdStart = Sweph.swe_julday(2026, 3, 1, 0.0, CalendarType.SE_GREG_CAL);
  
  // SE_CALC_RISE = 1
  // SE_BIT_DISC_CENTER = 256
  // SE_BIT_NO_REFRACT = 512
  
  // geometric mid limb
  final trRise = Sweph.swe_rise_trans(
    jdStart - 0.5,
    HeavenlyBody.SE_SUN,
    '',
    SwephFlag.SEFLG_SWIEPH,
    1 | 256,
    [lon, lat, 0.0],
    1013.25,
    15.0
  );
  
  final trSet = Sweph.swe_rise_trans(
    trRise.tret[0] + 0.1,
    HeavenlyBody.SE_SUN,
    '',
    SwephFlag.SEFLG_SWIEPH,
    2 | 256, // SE_CALC_SET = 2
    [lon, lat, 0.0],
    1013.25,
    15.0
  );

  print('Sweph Sunrise JD: \${trRise.tret[0]}');
  print('Sweph Sunset JD: \${trSet.tret[0]}');
}
