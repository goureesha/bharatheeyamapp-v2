import 'package:sweph/sweph.dart';
import 'ephemeris.dart';
import '../constants/strings.dart';

class TransitEvent {
  final DateTime date;
  final String planetName;
  final String description;
  final String fromRashi;
  final String toRashi;
  
  TransitEvent({
    required this.date,
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
      'Sun': 'ರವಿ', 
      'Mars': 'ಕುಜ', 
      'Mercury': 'ಬುಧ', 
      'Jupiter': 'ಗುರು', 
      'Venus': 'ಶುಕ್ರ', 
      'Saturn': 'ಶನಿ',
      'Rahu': 'ರಾಹು', 
      'Ketu': 'ಕೇತು'
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
            case 'Mercury': orb = (speed < 0) ? 12.0 : 14.0; break;
            case 'Jupiter': orb = 11.0; break;
            case 'Venus': orb = (speed < 0) ? 8.0 : 10.0; break;
            case 'Saturn': orb = 15.0; break;
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
    
    for (int d = 1; d <= daysInYear; d++) {
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
             
             // Check if it's a retrograde move or normal move
             // If a planet goes from Aries (0) to Pisces (11), it's Vakri
             // Or if it's Rahu/Ketu, they normally go backwards.
             
             transits.add(TransitEvent(
                date: currentDate,
                planetName: knName,
                description: '$prevName ರಾಶಿಯಿಂದ $nextName ರಾಶಿಗೆ ಪ್ರವೇಶ',
                fromRashi: prevName,
                toRashi: nextName,
             ));
             prevRashi[p] = rIdx;
          }
          
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
                case 'Mercury': orb = isVakri ? 12.0 : 14.0; break;
                case 'Jupiter': orb = 11.0; break;
                case 'Venus': orb = isVakri ? 8.0 : 10.0; break;
                case 'Saturn': orb = 15.0; break;
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
