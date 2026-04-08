import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// A recent-calculations history (FIFO, max 100 entries).
/// Every kundali calculation is auto-saved here, even if the user
/// does not explicitly save it. Users can later browse and promote
/// entries to permanent saved profiles.
class HistoryService {
  static const String _key = 'bharatheeyam_history_v1';
  static const int _maxEntries = 100;

  /// In-memory cache
  static List<HistoryEntry> _entries = [];

  /// Read-only access
  static List<HistoryEntry> get entries => List.unmodifiable(_entries);

  /// Load history from SharedPreferences
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) {
      _entries = [];
      return;
    }
    try {
      final list = jsonDecode(jsonStr) as List;
      _entries = list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('History load error: $e');
      _entries = [];
    }
  }

  /// Add a new entry to the front. If count exceeds 100,
  /// the oldest entry (last in list) is removed.
  static Future<void> add(HistoryEntry entry) async {
    // Remove duplicate if same name+date+time already exists
    _entries.removeWhere((e) =>
        e.name == entry.name &&
        e.date == entry.date &&
        e.hour == entry.hour &&
        e.minute == entry.minute &&
        e.ampm == entry.ampm);

    // Insert at the front (newest first)
    _entries.insert(0, entry);

    // Trim to max size — remove oldest
    while (_entries.length > _maxEntries) {
      _entries.removeLast();
    }

    await _persist();
  }

  /// Remove a single entry by index
  static Future<void> removeAt(int index) async {
    if (index >= 0 && index < _entries.length) {
      _entries.removeAt(index);
      await _persist();
    }
  }

  /// Clear all history
  static Future<void> clearAll() async {
    _entries.clear();
    await _persist();
  }

  /// Convert a history entry to a permanent Profile and save it
  static Future<Profile> promoteToProfile(HistoryEntry entry) async {
    final profile = Profile(
      name: entry.name,
      date: entry.date,
      hour: entry.hour,
      minute: entry.minute,
      ampm: entry.ampm,
      lat: entry.lat,
      lon: entry.lon,
      tzOffset: entry.tzOffset,
      place: entry.place,
    );
    await StorageService.save(profile);
    return profile;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _entries.map((e) => e.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }
}

/// A lightweight record of a past calculation.
class HistoryEntry {
  final String name;
  final String date;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final double tzOffset;
  final String place;
  final String timestamp; // ISO-8601 when the calculation was done

  HistoryEntry({
    required this.name,
    required this.date,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.tzOffset,
    required this.place,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
    'hour': hour,
    'minute': minute,
    'ampm': ampm,
    'lat': lat,
    'lon': lon,
    'tz': tzOffset,
    'place': place,
    'ts': timestamp,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    name: j['name'] ?? '',
    date: j['date'] ?? '2000-01-01',
    hour: j['hour'] ?? 12,
    minute: j['minute'] ?? 0,
    ampm: j['ampm'] ?? 'PM',
    lat: (j['lat'] ?? 14.98).toDouble(),
    lon: (j['lon'] ?? 74.73).toDouble(),
    tzOffset: (j['tz'] ?? 5.5).toDouble(),
    place: j['place'] ?? '',
    timestamp: j['ts'] ?? DateTime.now().toIso8601String(),
  );
}
