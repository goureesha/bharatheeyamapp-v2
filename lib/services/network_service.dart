import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NetworkService {
  /// Pure connectivity check — actually pings the internet.
  /// Returns true only if the device can reach the network right now.
  /// Tries multiple endpoints for reliability.
  static Future<bool> isActuallyOnline() async {
    if (kIsWeb) return true;

    // Try multiple endpoints — if ANY succeed, we're online
    final endpoints = [
      'https://www.google.com/generate_204',      // Returns 204, no redirect
      'https://clients3.google.com/generate_204',  // Google connectivity check
      'https://firestore.googleapis.com',           // Firebase (app already uses this)
    ];

    for (final url in endpoints) {
      try {
        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        // Accept any successful status code (200-299) or 204 (No Content)
        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true;
        }
      } catch (_) {
        // Try next endpoint
      }
    }
    return false;
  }
}
