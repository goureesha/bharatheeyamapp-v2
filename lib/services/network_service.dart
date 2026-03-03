import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'subscription_service.dart';
import 'ad_service.dart';

class NetworkService {
  static const String _timeKey = 'last_online_time';
  
  static Future<bool> checkAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    bool isConnected = false;
    try {
      if (kIsWeb) {
        isConnected = true; // Web browser handles connectivity dynamically
      } else {
        final response = await http.get(Uri.parse('https://google.com')).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          isConnected = true;
        }
      }
    } catch (_) {
      isConnected = false;
    }

    if (isConnected) {
      // Save current time
      final nowStr = DateTime.now().toIso8601String();
      await prefs.setString(_timeKey, nowStr);
      
      // Initialize dependent services that need internet
      await SubscriptionService.initialize();
      await AdService.initialize();
      
      return true; // Allowed
    } else {
      // Offline, check age
      final lastOnlineStr = prefs.getString(_timeKey);
      if (lastOnlineStr == null) {
        // First run offline? Allow temporarily, save now
        await prefs.setString(_timeKey, DateTime.now().toIso8601String());
        return true;
      }
      
      final lastOnline = DateTime.tryParse(lastOnlineStr);
      if (lastOnline == null) return true; // Malformed data fallback
      
      final diff = DateTime.now().difference(lastOnline);
      if (diff.inHours >= 48) {
        return false; // Blocked!
      }
      return true; // Allowed (within 48 hours offline window)
    }
  }
}
