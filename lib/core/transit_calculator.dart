import 'package:sweph/sweph.dart';
import 'ephemeris.dart';
import '../constants/strings.dart';

class TransitEvent {
  final DateTime date;
  final String time; // HH:MM AM/PM format
  final String planetName;
  final String description;
  final String fromRashi;
  final String toRashi;
  
  TransitEvent({
    required this.date,
    this.time = '',
    required this.planetName,
    required this.description,
    required this.fromRashi,
    required this.toRashi,
  });
}

class VakriPeriod {
  final String planetName;
  final DateTime startDate;
  DateTime? endDate; // null if continues into next year
  
  VakriPeriod({required this.planetName, required this.startDate, this.endDate});
}

class AstaPeriod {
  final String planetName;
  final DateTime startDate;
  DateTime? endDate; // null if continues into next year
  
  AstaPeriod({required this.planetName, required this.startDate, this.endDate});
}

class TransitData {
  final int year;
  final List<TransitEvent> transits;
  final List<VakriPeriod> vakriPeriods;
  final List<AstaPeriod> astaPeriods;
  
  TransitData({
    required this.year,
    required this.transits,
    required this.vakriPeriods,
    required this.astaPeriods,
  });
}

class TransitCalculator {
  /// Binary search to find exact JD when planet changes rashi.
  /// prevJd: JD where planet was in prevRashi, curJd: JD where planet is in newRashi.
  /// Returns the JD of the exact rashi boundary crossing.
  static double _findExactTransitJd(String engPlanet, double prevJd, double curJd, int prevRashiIdx) {
    double low = prevJd;
    double high = curJd;
    for (int i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      final pos = Ephemeris.calcAll(mid, 'lahiri', true);
      if (!pos.containsKey(engPlanet)) break;
      final lng = pos[engPlanet]![0];
      final rIdx = (lng / 30).floor() % 12;
      if (rIdx == prevRashiIdx) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  /// Convert a JD to local time string (HH:MM AM/PM) for IST (tzOffset=5.5)
  static String _jdToLocalTime(double jd, {double tzOffset = 5.5}) {
    final localJd = jd + 0.5 + (tzOffset / 24.0);
    double frac = localJd - localJd.floor();
    frac = ((frac % 1.0) + 1.0) % 1.0;
    int totalMinutes = (frac * 24 * 60).round();
    if (totalMinutes >= 1440) totalMinutes -= 1440;
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    String amPm = h >= 12 ? 'PM' : 'AM';
    int h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $amPm';
  }

  /// Convert a JD to a DateTime in local timezone
  static DateTime _jdToLocalDate(double jd, {double tzOffset = 5.5}) {
    final localJd = jd + (tzOffset / 24.0);
    // swe_revjul gives calendar date from JD
    final y = Sweph.swe_revjul(localJd, CalendarType.SE_GREG_CAL);
    return DateTime(y.year, y.month, y.day);
  }

  static Future<TransitData> calculateAnnualEvents(int year) async {
    await Ephemeris.initSweph();
    
    Map<String, int> prevRashi = {};
    Map<String, bool> prevVakri = {};
    Map<String, bool> prevAsta = {};
    
    List<TransitEvent> transits = [];
    List<VakriPeriod> activeVakri = [];
    List<VakriPeriod> completedVakri = [];
    List<AstaPeriod> activeAsta = [];
    List<AstaPeriod> completedAsta = [];
    
    // Pre-fill state for Dec 31 (year-1) 12:00 PM UTC
    final jdStartBase = Sweph.swe_julday(year - 1, 12, 31, 12.0, CalendarType.SE_GREG_CAL);
    final basePos = Ephemeris.calcAll(jdStartBase, 'lahiri', true);
    final baseSunLng = basePos['Sun']![0];
    
    final planetsToCheck = {
      'Sun': 'sun', 
      'Moon': 'moon',
      'Mars': 'mars', 
      'Mercury': 'mercury', 
      'Jupiter': 'jupiter', 
      'Venus': 'venus', 
      'Saturn': 'saturn',
      'Rahu': 'rahu', 
      'Ketu': 'ketu'
    };
    
    // Initialize base state
    for (final p in planetsToCheck.keys) {
      if (!basePos.containsKey(p)) continue;
      final lng = basePos[p]![0];
      final speed = basePos[p]![1];
      
      final rIdx = (lng / 30).floor() % 12;
      prevRashi[p] = rIdx;
      
      if (['Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'].contains(p)) {
         prevVakri[p] = speed < 0;
         double distSun = (lng - baseSunLng).abs();
         if (distSun > 180) distSun = 360 - distSun;
         
         double orb = 0.0;
         switch(p) {
            case 'Mars': orb = 17.0; break;
            case 'Mercury': orb = 11.0; break;
            case 'Jupiter': orb = 9.0; break;
            case 'Venus': orb = 6.6; break;
            case 'Saturn': orb = 13.0; break;
         }
         prevAsta[p] = distSun <= orb;
      }
    }
    
    for (var p in prevVakri.keys) {
       if (prevVakri[p] == true) {
          activeVakri.add(VakriPeriod(planetName: planetsToCheck[p]!, startDate: DateTime(year-1, 12, 31)));
       }
       if (prevAsta[p] == true) {
          activeAsta.add(AstaPeriod(planetName: planetsToCheck[p]!, startDate: DateTime(year-1, 12, 31)));
       }
    }

    // Now loop through the year
    int daysInYear = DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
    
    // Store previous JDs for binary search
    Map<String, double> prevJd = {};
    for (final p in planetsToCheck.keys) {
      prevJd[p] = jdStartBase;
    }
    
    for (int d = 1; d <= daysInYear; d++) {
       // Yield to UI thread every 30 days to keep spinner animating
       if (d % 30 == 0) await Future.delayed(Duration.zero);

       final currentDate = DateTime(year, 1, 1).add(Duration(days: d - 1));
       
       // Calculate at 12:00 PM UTC (~5:30 PM IST) to represent the day
       final jd = Sweph.swe_julday(currentDate.year, currentDate.month, currentDate.day, 12.0, CalendarType.SE_GREG_CAL);
       final pos = Ephemeris.calcAll(jd, 'lahiri', true);
       final sunLng = pos['Sun']![0];
       
       for (final p in planetsToCheck.keys) {
          if (!pos.containsKey(p)) continue;
          final knName = planetsToCheck[p]!;
          final lng = pos[p]![0];
          final speed = pos[p]![1];
          final rIdx = (lng / 30).floor() % 12;
          
          // 1. TRANSITS
          if (prevRashi[p] != rIdx) {
             final prevName = knRashi[prevRashi[p]!];
             final nextName = knRashi[rIdx];
             
             // Binary search for exact transit time
             final exactJd = _findExactTransitJd(p, prevJd[p]!, jd, prevRashi[p]!);
             final transitTime = _jdToLocalTime(exactJd);
             final transitDate = _jdToLocalDate(exactJd);
             
             transits.add(TransitEvent(
                date: transitDate,
                time: transitTime,
                planetName: knName,
                description: '${prevRashi[p]} -> $rIdx',
                fromRashi: prevName,
                toRashi: nextName,
             ));
             prevRashi[p] = rIdx;
          }
          prevJd[p] = jd;
          
          // 2. VAKRI / ASTA
          if (['Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'].contains(p)) {
             final isVakri = speed < 0;
             if (isVakri != prevVakri[p]) {
                if (isVakri) {
                   activeVakri.add(VakriPeriod(planetName: knName, startDate: currentDate));
                } else {
                   final openPeriod = activeVakri.lastWhere((vp) => vp.planetName == knName, orElse: () => VakriPeriod(planetName: knName, startDate: DateTime(year, 1, 1)));
                   openPeriod.endDate = currentDate;
                   completedVakri.add(openPeriod);
                   activeVakri.remove(openPeriod);
                }
                prevVakri[p] = isVakri;
             }
             
             double distSun = (lng - sunLng).abs();
             if (distSun > 180) distSun = 360 - distSun;
             double orb = 0.0;
             switch(p) {
                case 'Mars': orb = 17.0; break;
                case 'Mercury': orb = 11.0; break;
                case 'Jupiter': orb = 9.0; break;
                case 'Venus': orb = 6.6; break;
                case 'Saturn': orb = 13.0; break;
             }
             final isAsta = distSun <= orb;
             
             if (isAsta != prevAsta[p]) {
                if (isAsta) {
                   activeAsta.add(AstaPeriod(planetName: knName, startDate: currentDate));
                } else {
                   final openPeriod = activeAsta.lastWhere((ap) => ap.planetName == knName, orElse: () => AstaPeriod(planetName: knName, startDate: DateTime(year, 1, 1)));
                   openPeriod.endDate = currentDate;
                   completedAsta.add(openPeriod);
                   activeAsta.remove(openPeriod);
                }
                prevAsta[p] = isAsta;
             }
          }
       }
    }
    
    // Close any active periods at end of year
    for (var vp in activeVakri) {
       completedVakri.add(vp); // endDate remains null
    }
    for (var ap in activeAsta) {
       completedAsta.add(ap);
    }
    
    // Sort completed lists by start date
    completedVakri.sort((a,b) => a.startDate.compareTo(b.startDate));
    completedAsta.sort((a,b) => a.startDate.compareTo(b.startDate));
    // Sort transits by date
    transits.sort((a,b) => a.date.compareTo(b.date));
    
    return TransitData(
       year: year,
       transits: transits,
       vakriPeriods: completedVakri,
       astaPeriods: completedAsta,
    );
  }
}
