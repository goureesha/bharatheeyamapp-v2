String formatTimeFromJd(double jd, {double tzOffset = 5.5}) {
  final localJd = jd + 0.5 + (tzOffset / 24.0);
  final frac = localJd - localJd.floor();
  
  int totalMinutes = (frac * 24 * 60).round();
  int h = totalMinutes ~/ 60;
  int m = totalMinutes % 60;
  
  if (h == 24) h = 0;
  
  String amPm = h >= 12 ? 'PM' : 'AM';
  int hStr = h % 12;
  if (hStr == 0) hStr = 12;
  
  return '\:\ \';
}
void main() {
    print(formatTimeFromJd(2461120.598695958)); // Sunrise test
    print(formatTimeFromJd(2461121.094592759)); // Sunset test
}
