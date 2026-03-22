import 'package:flutter/foundation.dart';
import '../core/calculator.dart';
import '../core/events.dart';

/// Pre-computes and caches festival events for fast calendar access.
/// Call [loadYear] once on app startup to pre-compute all events.
class FestivalCacheService {
  static final Map<DateTime, List<AstroEvent>> _cache = {};
  static bool _isLoading = false;
  static bool _isLoaded = false;
  static int _loadedYear = 0;

  // Default location: Yellapur
  static const double _lat = 14.98;
  static const double _lon = 74.73;

  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;

  /// Get cached events for a specific date
  static List<AstroEvent> getEventsForDate(DateTime date) {
    final key = DateTime(date.year, date.month, date.day);
    return _cache[key] ?? [];
  }

  /// Get all cached events (for calendar green dots)
  static Map<DateTime, List<AstroEvent>> get allEvents => _cache;

  /// Pre-compute festivals for an entire year
  static Future<void> loadYear(int year) async {
    if (_isLoading) return;
    if (_isLoaded && _loadedYear == year) return;

    _isLoading = true;
    _loadedYear = year;

    debugPrint('FestivalCache: Loading festivals for year $year...');

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
            hour24: 6.0, // Sunrise time
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

    _isLoaded = true;
    _isLoading = false;
    debugPrint('FestivalCache: Loaded ${_cache.length} festival days for $year');
  }

  /// Load a specific month (for quick partial loading)
  static Future<void> loadMonth(int year, int month) async {
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
      } catch (_) {}
    }
  }

  /// Clear the cache
  static void clear() {
    _cache.clear();
    _isLoaded = false;
    _loadedYear = 0;
  }
}
