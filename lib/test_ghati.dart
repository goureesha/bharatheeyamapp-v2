void main() {
  // Scenario 1: AstroCalculator Logic
  // Ghati = (jdBirth - panchSr) * 60
  // Which is equivalent to (hoursSinceSunrise) * 2.5
  
  // Scenario 2: vedic_clock_screen Logic
  // srParts = "06:23 AM".split(':') -> srParts[0] = "06", srParts[1] = "23 AM"
  // double.tryParse("23 AM") returns null -> srMin becomes 0!
  
  print("Parsing test:");
  final sunriseStr = "06:23 AM";
  final srParts = sunriseStr.split(':');
  print("Part 0: \${srParts[0]}");
  print("Part 1: \${srParts.length > 1 ? srParts[1] : ''}");
  
  final srHour = double.tryParse(srParts[0]) ?? 6;
  final srMin = double.tryParse(srParts.length > 1 ? srParts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0') ?? 0;
  
  print("Parsed Hour: \$srHour");
  print("Parsed Min: \$srMin");
  
  final srMinBug = double.tryParse(srParts.length > 1 ? srParts[1] : '0') ?? 0;
  print("Buggy Parsed Min: \$srMinBug");
}
