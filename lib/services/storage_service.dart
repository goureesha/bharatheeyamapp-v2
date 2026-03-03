import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _key = 'bharatheeyam_profiles_v1';

  static Future<Map<String, Profile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) {
      // Return default sample if strictly empty
      return {
        'ಮಾದರಿ ಜಾತಕ (Sample)': Profile(
          name: 'ಮಾದರಿ ಜಾತಕ (Sample)',
          date: '1990-01-01',
          hour: 12,
          minute: 0,
          ampm: 'PM',
          lat: 14.98,
          lon: 74.73,
          place: 'Yellapur',
        ),
      };
    }

    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      final Map<String, Profile> profiles = {};
      for (final entry in map.entries) {
        profiles[entry.key] = Profile.fromJson(entry.key, entry.value as Map<String, dynamic>);
      }
      return profiles;
    } catch (e) {
      return {};
    }
  }

  static Future<void> save(Profile profile) async {
    final profiles = await loadAll();
    profiles[profile.name] = profile;
    
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> exportMap = {};
    for (final entry in profiles.entries) {
      exportMap[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_key, jsonEncode(exportMap));
  }

  static Future<void> delete(String name) async {
    final profiles = await loadAll();
    profiles.remove(name);

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> exportMap = {};
    for (final entry in profiles.entries) {
      exportMap[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_key, jsonEncode(exportMap));
  }
}

class Profile {
  final String name;
  final String date;
  final int hour;
  final int minute;
  final String ampm;
  final double lat;
  final double lon;
  final String place;

  Profile({
    required this.name,
    required this.date,
    required this.hour,
    required this.minute,
    required this.ampm,
    required this.lat,
    required this.lon,
    required this.place,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'd': date, 'h': hour, 'm': minute,
    'ampm': ampm, 'lat': lat, 'lon': lon, 'p': place,
  };

  factory Profile.fromJson(String name, Map<String, dynamic> j) => Profile(
    name: name,
    date: j['d'] ?? '',
    hour: j['h'] ?? 12,
    minute: j['m'] ?? 0,
    ampm: j['ampm'] ?? 'AM',
    lat: (j['lat'] ?? 14.98).toDouble(),
    lon: (j['lon'] ?? 74.73).toDouble(),
    place: j['p'] ?? '',
  );
}
