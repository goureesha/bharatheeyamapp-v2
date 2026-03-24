import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/calculator.dart';
import '../core/events.dart';

/// Pre-computes and caches festival events with PERSISTENT local storage.
/// 
/// On first launch: computes events in background, saves to SharedPreferences.
/// On subsequent launches: loads instantly from cache (~50ms).
/// 
/// Call [loadYear] on app startup.
class FestivalCacheService {
  static final Map<DateTime, List<AstroEvent>> _cache = {};
  static bool _isLoading = false;
  static bool _isLoaded = false;
  static int _loadedYear = 0;

  // Default location: Yellapur
  static const double _lat = 14.98;
  static const double _lon = 74.73;
  
  static const String _cachePrefix = 'fc_'; // Short prefix to save space
  static const String _cacheVersionKey = 'fc_ver';
  static const int _cacheVersion = 2; // Bump when event rules change

  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;

  /// Get cached events for a specific date
  static List<AstroEvent> getEventsForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _cache[key] ?? [];
  }

  /// Get all cached events (for calendar green dots)
  static Map<DateTime, List<AstroEvent>> get allEvents => _cache;

  /// Load festival data: tries local storage first, then computes if needed
  static Future<void> loadYear(int year) async {
    if (_isLoading) return;
    if (_isLoaded && _loadedYear == year) return;

    _isLoading = true;
    _loadedYear = year;

    // Try loading from persistent cache first (instant!)
    final loaded = await _loadFromDisk(year);
    if (loaded) {
      _isLoaded = true;
      _isLoading = false;
      debugPrint('FestivalCache: Loaded $year from disk cache (${_cache.length} days)');
      return;
    }

    // Cache miss → compute and save
    debugPrint('FestivalCache: Computing festivals for $year (first time)...');
    await _computeAndSave(year);
    
    _isLoaded = true;
    _isLoading = false;
    debugPrint('FestivalCache: Done. ${_cache.length} festival days for $year');
  }

  /// Load a specific month (for quick partial loading when swiping calendar)
  static Future<void> loadMonth(int year, int month) async {
    // Skip if we're already computing to prevent overlapping work
    if (_isLoading) return;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    // Quick check: if all days already cached, return immediately
    bool allCached = true;
    for (int day = 1; day <= daysInMonth; day++) {
      if (!_cache.containsKey(DateTime(year, month, day))) {
        allCached = false;
        break;
      }
    }
    if (allCached) return;

    _isLoading = true;
    bool anyNew = false;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final dateKey = DateTime(year, month, day);
      if (_cache.containsKey(dateKey)) continue;

      // Yield to UI thread EVERY day to keep animations smooth
      await Future.delayed(Duration.zero);

      try {
        final res = await AstroCalculator.calculate(
          year: year, month: month, day: day,
          hourUtcOffset: 5.5,
          hour24: 6.0,
          lat: _lat, lon: _lon,
          ayanamsaMode: 'lahiri',
          trueNode: true,
        );
        if (res != null) {
          final events = EventCalculator.getEventsForPanchang(res.panchang);
          if (events.isNotEmpty) {
            _cache[dateKey] = events;
            anyNew = true;
          } else {
            // Mark empty days as cached too (empty list) to avoid recomputation
            _cache[dateKey] = [];
          }
        }
      } catch (_) {}
    }
    
    _isLoading = false;

    // Save new data to disk cache
    if (anyNew) {
      _saveToDisk(year);
    }
  }

  /// Compute all 365 days with yield points, then persist
  static Future<void> _computeAndSave(int year) async {
    int count = 0;
    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final dateKey = DateTime(year, month, day);
        if (_cache.containsKey(dateKey)) continue;

        try {
          final res = await AstroCalculator.calculate(
            year: year, month: month, day: day,
            hourUtcOffset: 5.5,
            hour24: 6.0,
            lat: _lat, lon: _lon,
            ayanamsaMode: 'lahiri',
            trueNode: true,
          );
          if (res != null) {
            final events = EventCalculator.getEventsForPanchang(res.panchang);
            if (events.isNotEmpty) {
              _cache[dateKey] = events;
            }
          }
        } catch (e) {
          debugPrint('FestivalCache: Error computing $dateKey: $e');
        }

        // Yield to UI thread every 5 days to prevent jank
        count++;
        if (count % 5 == 0) {
          await Future.delayed(Duration.zero);
        }
      }
    }

    // Persist to disk for next launch
    await _saveToDisk(year);
  }

  // ─── Persistent Storage (SharedPreferences) ────────────────

  /// Save cache to SharedPreferences (split by month to avoid size limits)
  static Future<void> _saveToDisk(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save each month separately to stay within SharedPreferences limits
      for (int month = 1; month <= 12; month++) {
        final monthData = <String, List<Map<String, String>>>{};
        
        _cache.forEach((date, events) {
          if (date.year == year && date.month == month) {
            final key = '${date.day}';
            monthData[key] = events.map((e) => {
              'n': e.name,
              'd': e.description,
              's': e.shloka,
              'm': e.meaning,
              'r': e.source,
            }).toList();
          }
        });
        
        if (monthData.isNotEmpty) {
          await prefs.setString('$_cachePrefix${year}_$month', jsonEncode(monthData));
        }
      }
      
      await prefs.setInt(_cacheVersionKey, _cacheVersion);
      debugPrint('FestivalCache: Saved $year to SharedPreferences');
    } catch (e) {
      debugPrint('FestivalCache: Error saving: $e');
    }
  }

  /// Load cache from SharedPreferences
  static Future<bool> _loadFromDisk(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check cache version
      final savedVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      if (savedVersion != _cacheVersion) {
        debugPrint('FestivalCache: Version mismatch ($savedVersion != $_cacheVersion)');
        return false;
      }

      bool anyLoaded = false;
      
      for (int month = 1; month <= 12; month++) {
        final jsonStr = prefs.getString('$_cachePrefix${year}_$month');
        if (jsonStr == null) continue;

        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        for (final entry in data.entries) {
          final day = int.parse(entry.key);
          final date = DateTime(year, month, day);
          final events = (entry.value as List).map((e) {
            final m = e as Map<String, dynamic>;
            return AstroEvent(
              name: m['n'] ?? '',
              description: m['d'] ?? '',
              shloka: m['s'] ?? '',
              meaning: m['m'] ?? '',
              source: m['r'] ?? '',
            );
          }).toList();
          _cache[date] = events;
          anyLoaded = true;
        }
      }

      return anyLoaded;
    } catch (e) {
      debugPrint('FestivalCache: Error loading from disk: $e');
      return false;
    }
  }

  /// Clear the cache (both memory and disk)
  static Future<void> clear() async {
    _cache.clear();
    _isLoaded = false;
    _loadedYear = 0;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (_) {}
  }
}
