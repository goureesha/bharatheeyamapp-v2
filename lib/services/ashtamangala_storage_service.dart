import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for Ashtamangala Prashne records.
/// Uses a separate SharedPreferences key from the main Profile storage.
class AshtamangalaStorageService {
  static const String _key = 'bharatheeyam_ashta_records_v1';

  static Future<Map<String, AshtamangalaRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) {
      return {};
    }

    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final Map<String, AshtamangalaRecord> records = {};
      for (final entry in map.entries) {
        try {
          records[entry.key] = AshtamangalaRecord.fromJson(entry.key, entry.value as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Failed to load ashtamangala record ${entry.key}: $e');
        }
      }
      return records;
    } catch (e) {
      debugPrint('Complete ashtamangala storage corruption: $e');
      return {};
    }
  }

  static Future<void> save(AshtamangalaRecord record) async {
    final records = await loadAll();
    records[record.name] = record;

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> exportMap = {};
    for (final entry in records.entries) {
      exportMap[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_key, jsonEncode(exportMap));
  }

  static Future<void> delete(String name) async {
    final records = await loadAll();
    records.remove(name);

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> exportMap = {};
    for (final entry in records.entries) {
      exportMap[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_key, jsonEncode(exportMap));
  }
}

class AshtamangalaRecord {
  final String name;               // Prucchaka name
  final String date;               // 'YYYY-MM-DD'
  final int hour;                  // 1-12
  final int minute;                // 0-59
  final String ampm;               // 'AM' or 'PM'
  final double lat;
  final double lon;
  final double tzOffset;
  final String place;
  final String ashtamangalaNumber; // e.g. '444'
  final String tamboolaNumber;     // e.g. '7'
  final int? sprashtangaNum;       // 1-12
  final int? svarnaroodhaRashi;    // 0-11
  final int? prucchakaRashi;       // 0-11
  final int? prucchakaNak;         // 0-26
  final DateTime? savedAt;

  AshtamangalaRecord({
    required this.name,
    required this.date,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.place,
    this.tzOffset = 5.5,
    this.ashtamangalaNumber = '',
    this.tamboolaNumber = '',
    this.sprashtangaNum,
    this.svarnaroodhaRashi,
    this.prucchakaRashi,
    this.prucchakaNak,
    this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'd': date,
    'h': hour,
    'm': minute,
    'ampm': ampm,
    'lat': lat,
    'lon': lon,
    'tz': tzOffset,
    'p': place,
    'ashta': ashtamangalaNumber,
    'tamboola': tamboolaNumber,
    'sprashtanga': sprashtangaNum,
    'svarnaroodha': svarnaroodhaRashi,
    'prucchakaRashi': prucchakaRashi,
    'prucchakaNak': prucchakaNak,
    'savedAt': savedAt?.toIso8601String(),
  };

  factory AshtamangalaRecord.fromJson(String name, Map<String, dynamic> j) => AshtamangalaRecord(
    name: name,
    date: j['d'] ?? j['date'] ?? '2000-01-01',
    hour: j['h'] ?? j['hour'] ?? 12,
    minute: j['m'] ?? j['minute'] ?? 0,
    ampm: j['ampm'] ?? 'PM',
    lat: (j['lat'] ?? 14.98).toDouble(),
    lon: (j['lon'] ?? 74.73).toDouble(),
    tzOffset: (j['tz'] ?? j['tzOffset'] ?? 5.5).toDouble(),
    place: j['p'] ?? j['place'] ?? '',
    ashtamangalaNumber: j['ashta'] ?? j['ashtamangalaNumber'] ?? '',
    tamboolaNumber: j['tamboola'] ?? j['tamboolaNumber'] ?? '',
    sprashtangaNum: j['sprashtanga'] as int?,
    svarnaroodhaRashi: j['svarnaroodha'] as int?,
    prucchakaRashi: j['prucchakaRashi'] as int?,
    prucchakaNak: j['prucchakaNak'] as int?,
    savedAt: j['savedAt'] != null ? DateTime.tryParse(j['savedAt']) : null,
  );
}
