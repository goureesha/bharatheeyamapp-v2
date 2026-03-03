import 'lib/core/calculator.dart';

void main() {
    print("Testing calculator parsing...");
    final res = AstroCalculator.getPlanetDetail('???', 45.0, 1.0, 45.0);
    print(res);
}
