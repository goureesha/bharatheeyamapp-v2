import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network_service.dart';

/// Tracks last successful internet connection.
/// If the app hasn't connected to the internet within 24 hours,
/// it should show an "Internet Required" screen.
class InternetCheckService {
  static const String _lastOnlineKey = 'last_online_timestamp';
  static const int _maxOfflineHours = 24;

  static DateTime? _lastOnline;

  /// Last known online time (null if never recorded)
  static DateTime? get lastOnline => _lastOnline;

  /// Whether the 24-hour offline window has expired
  static bool get isExpired {
    if (_lastOnline == null) return true; // Never connected
    final elapsed = DateTime.now().difference(_lastOnline!);
    return elapsed.inHours >= _maxOfflineHours;
  }

  /// Hours remaining before the app locks (0 if expired)
  static int get hoursRemaining {
    if (_lastOnline == null) return 0;
    final elapsed = DateTime.now().difference(_lastOnline!);
    final remaining = _maxOfflineHours - elapsed.inHours;
    return remaining > 0 ? remaining : 0;
  }

  /// Load last online timestamp from storage
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_lastOnlineKey);
    if (ts != null) {
      _lastOnline = DateTime.fromMillisecondsSinceEpoch(ts);
    }
    debugPrint('InternetCheck: last online = $_lastOnline, expired = $isExpired');
  }

  /// Save current time as last online timestamp
  static Future<void> _saveTimestamp() async {
    _lastOnline = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastOnlineKey, _lastOnline!.millisecondsSinceEpoch);
  }

  /// Ping the internet and update timestamp if online.
  /// Returns true if device is online right now.
  static Future<bool> checkAndUpdate() async {
    if (kIsWeb) {
      // Web always considered online
      await _saveTimestamp();
      return true;
    }

    final online = await NetworkService.isActuallyOnline();
    if (online) {
      await _saveTimestamp();
      debugPrint('InternetCheck: Online — timestamp updated');
    } else {
      debugPrint('InternetCheck: Offline — hours remaining: $hoursRemaining');
    }
    return online;
  }

  /// Check if the app should be allowed to run.
  /// Returns true if:
  /// - Currently online (updates timestamp), OR
  /// - Was online within the last 24 hours
  static Future<bool> canProceed() async {
    // Try to connect first
    final online = await checkAndUpdate();
    if (online) return true;
    // Offline — check if within 24-hour window
    return !isExpired;
  }

  // ── Periodic background check ──

  static Timer? _periodicTimer;

  /// Start a periodic check every 15 minutes.
  /// If the device comes online, the timestamp is updated silently.
  static void startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await checkAndUpdate();
    });
    debugPrint('InternetCheck: Periodic check started (every 15 min)');
  }

  /// Stop the periodic check
  static void stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}
