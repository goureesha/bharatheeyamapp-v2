import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'ad_service.dart';

class NetworkService {
  static const String _timeKey = 'last_online_time';
  
  static Future<bool> checkAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    bool isConnected = false;
    try {
      if (kIsWeb) {
        isConnected = true;
      } else {
        final response = await http.get(Uri.parse('https://google.com')).timeout(const Duration(seconds: 3));
        isConnected = response.statusCode == 200;
      }
    } catch (_) {
      isConnected = false;
    }

    if (isConnected) {
      await prefs.setString(_timeKey, DateTime.now().toIso8601String());
      // Initialize ads in background - don't block app startup
      AdService.initialize();
      return true;
    } else {
      final lastOnlineStr = prefs.getString(_timeKey);
      if (lastOnlineStr == null) {
        await prefs.setString(_timeKey, DateTime.now().toIso8601String());
        return true;
      }
      
      final lastOnline = DateTime.tryParse(lastOnlineStr);
      if (lastOnline == null) return true;
      
      final diff = DateTime.now().difference(lastOnline);
      if (diff.inHours >= 48) {
        return false;
      }
      return true;
    }
  }
}
