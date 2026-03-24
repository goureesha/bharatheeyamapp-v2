import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's default location for Panchanga & Vedic Clock calculations.
/// Persisted via SharedPreferences; defaults to Yellapur.
class LocationService {
  static double _lat = 14.98;
  static double _lon = 74.73;
  static String _place = 'ಯಲ್ಲಾಪುರ (Yellapur)';

  static double get lat => _lat;
  static double get lon => _lon;
  static String get place => _place;

  /// Call once at app startup.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lat = prefs.getDouble('default_lat') ?? 14.98;
    _lon = prefs.getDouble('default_lon') ?? 74.73;
    _place = prefs.getString('default_place') ?? 'ಯಲ್ಲಾಪುರ (Yellapur)';
  }

  /// Save a new default location.
  static Future<void> setLocation(String name, double lat, double lon) async {
    _place = name;
    _lat = lat;
    _lon = lon;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_lat', lat);
    await prefs.setDouble('default_lon', lon);
    await prefs.setString('default_place', name);
  }
}
