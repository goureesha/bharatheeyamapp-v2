import 'dart:io';
import 'lib/core/calculator.dart';
import 'lib/core/ephemeris.dart';
import 'package:sweph/sweph.dart';

void main() async {
  await Sweph.init(epheAssets: []);
  final res = await AstroCalculator.calculate(
    year: 2026, month: 3, day: 1,
    hourUtcOffset: 5.5,
    hour24: 17.1,
    lat: 14.9667, lon: 74.7167,
    ayanamsaMode: 'lahiri',
    trueNode: true,
  );
  print('Mandi: \');
  print('Lagna: \');
}
