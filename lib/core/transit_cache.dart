import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'transit_calculator.dart';

/// In-memory + disk cache for planet transit data.
/// Once a year is computed, it loads instantly on next access.
class TransitCache {
  // In-memory cache (keeps up to 12 years for preload)
  static final Map<int, TransitData> _memCache = {};
  static const int _maxMemCache = 12;

  // Currently pre-fetching years (avoid duplicate work)
  static final Set<int> _computing = {};

  /// Get transit data for a year — instant if cached, computes otherwise.
  static Future<TransitData> getYear(int year) async {
    // 1. Check memory cache
    if (_memCache.containsKey(year)) {
      return _memCache[year]!;
    }

    // 2. Check disk cache
    final diskData = await _loadFromDisk(year);
    if (diskData != null) {
      _addToMemCache(year, diskData);
      return diskData;
    }

    // 3. Compute fresh
    final data = await TransitCalculator.calculateAnnualEvents(year);
    _addToMemCache(year, data);
    // Save to disk (fire-and-forget)
    _saveToDisk(year, data);
    return data;
  }

  /// Pre-fetch adjacent years in background (call after loading current year)
  static void prefetchAdjacent(int year) {
    _prefetchYear(year - 1);
    _prefetchYear(year + 1);
  }

  static Future<void> _prefetchYear(int year) async {
    if (_memCache.containsKey(year)) return;
    if (_computing.contains(year)) return;
    _computing.add(year);
    try {
      // Check disk first
      final diskData = await _loadFromDisk(year);
      if (diskData != null) {
        _addToMemCache(year, diskData);
        return;
      }
      // Compute
      final data = await TransitCalculator.calculateAnnualEvents(year);
      _addToMemCache(year, data);
      _saveToDisk(year, data);
    } finally {
      _computing.remove(year);
    }
  }

  static void _addToMemCache(int year, TransitData data) {
    _memCache[year] = data;
    // Evict oldest if over limit
    if (_memCache.length > _maxMemCache) {
      _memCache.remove(_memCache.keys.first);
    }
  }

  /// Clear all caches (e.g. on settings change)
  static void clearAll() {
    _memCache.clear();
  }

  /// Preload a range of years in the background (fire-and-forget).
  /// Loads current year first, then adjacent years sequentially.
  static Future<void> preloadRange({int pastYears = 2, int futureYears = 7}) async {
    final now = DateTime.now().year;
    final years = <int>[now];
    // Add surrounding years: current±1, then expand outward
    for (int i = 1; i <= futureYears || i <= pastYears; i++) {
      if (i <= futureYears) years.add(now + i);
      if (i <= pastYears) years.add(now - i);
    }
    for (final y in years) {
      if (_memCache.containsKey(y)) continue;
      await _prefetchYear(y);
      // Small delay between years to keep UI responsive
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // ─── Disk cache ───

  static Future<Directory> get _cacheDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/transit_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> _saveToDisk(int year, TransitData data) async {
    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/transit_$year.json');
      final json = _transitDataToJson(data);
      await file.writeAsString(jsonEncode(json));
    } catch (_) {
      // Disk save failure is non-fatal
    }
  }

  static Future<TransitData?> _loadFromDisk(int year) async {
    try {
      final dir = await _cacheDir;
      final file = File('${dir.path}/transit_$year.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return _transitDataFromJson(json);
    } catch (_) {
      return null;
    }
  }

  // ─── JSON Serialization ───

  static Map<String, dynamic> _transitDataToJson(TransitData d) => {
    'year': d.year,
    'transits': d.transits.map((t) => {
      'date': t.date.toIso8601String(),
      'time': t.time,
      'planetName': t.planetName,
      'description': t.description,
      'fromRashi': t.fromRashi,
      'toRashi': t.toRashi,
    }).toList(),
    'vakri': d.vakriPeriods.map((v) => {
      'planetName': v.planetName,
      'start': v.startDate.toIso8601String(),
      'end': v.endDate?.toIso8601String(),
    }).toList(),
    'asta': d.astaPeriods.map((a) => {
      'planetName': a.planetName,
      'start': a.startDate.toIso8601String(),
      'end': a.endDate?.toIso8601String(),
    }).toList(),
  };

  static TransitData _transitDataFromJson(Map<String, dynamic> j) {
    return TransitData(
      year: j['year'] as int,
      transits: (j['transits'] as List).map((t) => TransitEvent(
        date: DateTime.parse(t['date']),
        time: t['time'] ?? '',
        planetName: t['planetName'],
        description: t['description'] ?? '',
        fromRashi: t['fromRashi'],
        toRashi: t['toRashi'],
      )).toList(),
      vakriPeriods: (j['vakri'] as List).map((v) => VakriPeriod(
        planetName: v['planetName'],
        startDate: DateTime.parse(v['start']),
        endDate: v['end'] != null ? DateTime.parse(v['end']) : null,
      )).toList(),
      astaPeriods: (j['asta'] as List).map((a) => AstaPeriod(
        planetName: a['planetName'],
        startDate: DateTime.parse(a['start']),
        endDate: a['end'] != null ? DateTime.parse(a['end']) : null,
      )).toList(),
    );
  }
}
