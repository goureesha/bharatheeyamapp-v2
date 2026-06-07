import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/calculator.dart';
import '../core/ephemeris.dart';
import '../core/events.dart';
import 'location_service.dart';

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

  // Default location from settings
  static double get _lat => LocationService.lat;
  static double get _lon => LocationService.lon;
  static double get _tzOffset => LocationService.tzOffset;

  static const String _cachePrefix = 'fc_'; // Short prefix to save space
  static const String _cacheVersionKey = 'fc_ver';
  static const int _cacheVersion = 4; // Bumped: now persists empty-event days with '_' marker

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

  // Cancellation: bumped each time loadMonth is called so stale computations abort
  static int _loadMonthToken = 0;

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
    final myToken = ++_loadMonthToken; // Cancel stale computations
    bool anyComputed = false;
    
    // Try loading just this month from disk first
    final diskLoaded = await _loadMonthFromDisk(year, month);
    if (diskLoaded) {
      // Re-check if all days now cached after disk load
      bool nowCached = true;
      for (int day = 1; day <= daysInMonth; day++) {
        if (!_cache.containsKey(DateTime(year, month, day))) {
          nowCached = false;
          break;
        }
      }
      if (nowCached) {
        _isLoading = false;
        return;
      }
    }

    // Initialize ephemeris ONCE before the loop
    try {
      await Ephemeris.initSweph();
    } catch (_) {
      _isLoading = false;
      return;
    }

    for (int day = 1; day <= daysInMonth; day++) {
      // Abort if a newer loadMonth was called (user swiped again)
      if (myToken != _loadMonthToken) {
        _isLoading = false;
        return;
      }

      final dateKey = DateTime(year, month, day);
      if (_cache.containsKey(dateKey)) continue;

      // Yield to UI thread every 3 days to keep animations smooth
      if (day % 3 == 0) {
        await Future.delayed(const Duration(milliseconds: 1));
      }

      try {
        final srSs = Ephemeris.findSunriseSetForDate(year, month, day, _lat, _lon, tzOffset: _tzOffset);
        final srFrac = ((srSs[0] + 0.5 + (_tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
        final h24 = (srFrac * 24.0) + (5.0 / 60.0);

        final res = await AstroCalculator.calculate(
          year: year, month: month, day: day,
          hourUtcOffset: _tzOffset,
          hour24: h24,
          lat: _lat, lon: _lon,
          ayanamsaMode: 'lahiri',
          trueNode: true,
        );
        if (res != null) {
          final events = EventCalculator.getEventsForPanchang(res.panchang);
          _cache[dateKey] = events; // Cache even empty lists to avoid recomputation
          anyComputed = true;
        }
      } catch (_) {}
    }
    
    _isLoading = false;

    // Always save to disk after computing new days (even if all events empty)
    if (anyComputed) {
      _saveMonthToDisk(year, month);
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
          // Compute sunrise + 5 minutes for correct Vedic day
          await Ephemeris.initSweph();
          final srSs2 = Ephemeris.findSunriseSetForDate(year, month, day, _lat, _lon, tzOffset: _tzOffset);
          final srFrac2 = ((srSs2[0] + 0.5 + (_tzOffset / 24.0)) % 1.0 + 1.0) % 1.0;
          final h24v = (srFrac2 * 24.0) + (5.0 / 60.0);

          final res = await AstroCalculator.calculate(
            year: year, month: month, day: day,
            hourUtcOffset: _tzOffset,
            hour24: h24v,
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
        await _writeMonthToPrefs(prefs, year, month);
      }
      
      await prefs.setInt(_cacheVersionKey, _cacheVersion);
      debugPrint('FestivalCache: Saved $year to SharedPreferences');
    } catch (e) {
      debugPrint('FestivalCache: Error saving: $e');
    }
  }

  /// Save a single month to SharedPreferences
  static Future<void> _saveMonthToDisk(int year, int month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _writeMonthToPrefs(prefs, year, month);
      await prefs.setInt(_cacheVersionKey, _cacheVersion);
      debugPrint('FestivalCache: Saved $year-$month to SharedPreferences');
    } catch (e) {
      debugPrint('FestivalCache: Error saving month: $e');
    }
  }

  /// Write one month's data to prefs (includes empty-event days as "_" marker)
  static Future<void> _writeMonthToPrefs(SharedPreferences prefs, int year, int month) async {
    final monthData = <String, dynamic>{};
    
    _cache.forEach((date, events) {
      if (date.year == year && date.month == month) {
        final key = '${date.day}';
        if (events.isEmpty) {
          // Store empty-event days with a marker so they persist
          monthData[key] = '_';
        } else {
          monthData[key] = events.map((e) => {
            'n': e.name,
            'd': e.description,
            's': e.shloka,
            'm': e.meaning,
            'r': e.source,
          }).toList();
        }
      }
    });
    
    if (monthData.isNotEmpty) {
      await prefs.setString('$_cachePrefix${year}_$month', jsonEncode(monthData));
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
        if (_parseMonthJson(prefs, year, month)) {
          anyLoaded = true;
        }
      }

      return anyLoaded;
    } catch (e) {
      debugPrint('FestivalCache: Error loading from disk: $e');
      return false;
    }
  }

  /// Load a single month from SharedPreferences (used by loadMonth for quick disk check)
  static Future<bool> _loadMonthFromDisk(int year, int month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getInt(_cacheVersionKey) ?? 0;
      if (savedVersion != _cacheVersion) return false;
      return _parseMonthJson(prefs, year, month);
    } catch (_) {
      return false;
    }
  }

  /// Parse a single month's JSON from prefs into _cache. Handles '_' empty marker.
  static bool _parseMonthJson(SharedPreferences prefs, int year, int month) {
    final jsonStr = prefs.getString('$_cachePrefix${year}_$month');
    if (jsonStr == null) return false;

    bool loaded = false;
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    for (final entry in data.entries) {
      final day = int.parse(entry.key);
      final date = DateTime(year, month, day);
      if (entry.value == '_') {
        // Empty-event day marker — cache as empty list
        _cache[date] = [];
      } else {
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
      }
      loaded = true;
    }
    return loaded;
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
