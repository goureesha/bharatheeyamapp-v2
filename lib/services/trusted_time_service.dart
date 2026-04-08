import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides a trusted time source using NTP (Network Time Protocol).
/// 
/// On startup, syncs with NTP servers to detect phone clock manipulation.
/// Falls back to device time when offline, but records the offset for later use.
class TrustedTimeService {
  static const String _offsetKey = 'ntp_offset_ms';
  static const String _lastSyncKey = 'ntp_last_sync_ms';

  /// The offset between phone clock and real NTP time (in milliseconds).
  /// Positive = phone is ahead, Negative = phone is behind.
  static int _offsetMs = 0;

  /// Whether NTP sync was successful at least once this session.
  static bool _synced = false;

  /// Last successful sync timestamp (device time at point of sync).
  static DateTime? _lastSyncTime;

  /// Whether we have a valid offset (either fresh or cached).
  static bool get hasTrustedTime => _synced || _offsetMs != 0;

  /// Returns the current trusted time.
  /// If NTP offset is known, returns corrected time.
  /// Otherwise falls back to device time.
  static DateTime now() {
    return DateTime.now().subtract(Duration(milliseconds: _offsetMs));
  }

  /// Initialize: load cached offset and attempt NTP sync.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached offset from last successful sync
    _offsetMs = prefs.getInt(_offsetKey) ?? 0;
    final lastSyncMs = prefs.getInt(_lastSyncKey);
    if (lastSyncMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
    }

    if (kIsWeb) return;

    // Try to sync with NTP
    await syncWithNtp();
  }

  /// Attempt NTP sync. Can be called anytime (e.g., on connectivity change).
  static Future<bool> syncWithNtp() async {
    if (kIsWeb) return false;

    // Try multiple NTP servers for reliability
    final servers = [
      'time.google.com',
      'pool.ntp.org',
      'time.cloudflare.com',
    ];

    for (final server in servers) {
      try {
        final offset = await _queryNtpOffset(server);
        if (offset != null) {
          _offsetMs = offset;
          _synced = true;
          _lastSyncTime = DateTime.now();

          // Persist for offline use
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_offsetKey, _offsetMs);
          await prefs.setInt(_lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);

          debugPrint('🕐 NTP synced with $server — offset: ${_offsetMs}ms '
              '(phone ${_offsetMs > 0 ? "ahead" : "behind"} by ${_offsetMs.abs()}ms)');
          return true;
        }
      } catch (e) {
        debugPrint('NTP sync failed for $server: $e');
      }
    }

    debugPrint('⚠️ NTP sync failed for all servers — using cached offset: ${_offsetMs}ms');
    return false;
  }

  /// Raw NTP query using UDP sockets.
  /// Returns the offset in milliseconds (phone_time - real_time).
  static Future<int?> _queryNtpOffset(String server) async {
    RawDatagramSocket? socket;
    try {
      // Resolve NTP server
      final addresses = await InternetAddress.lookup(server)
          .timeout(const Duration(seconds: 3));
      if (addresses.isEmpty) return null;

      // Create UDP socket
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
          .timeout(const Duration(seconds: 3));

      // Build NTP request packet (48 bytes)
      // Byte 0: LI=0, VN=4, Mode=3 (client) → 0x23
      final request = List<int>.filled(48, 0);
      request[0] = 0x23; // NTP v4, client mode

      // Record local send time
      final t1 = DateTime.now().millisecondsSinceEpoch;

      // Encode t1 into transmit timestamp (bytes 40-47) for reference
      final ntpEpochOffset = 2208988800; // seconds from 1900 to 1970
      final t1Seconds = (t1 ~/ 1000) + ntpEpochOffset;
      request[40] = (t1Seconds >> 24) & 0xFF;
      request[41] = (t1Seconds >> 16) & 0xFF;
      request[42] = (t1Seconds >> 8) & 0xFF;
      request[43] = t1Seconds & 0xFF;

      // Send request
      socket.send(request, addresses.first, 123);

      // Wait for response with timeout
      final response = await socket.timeout(const Duration(seconds: 4)).firstWhere(
        (event) => event == RawSocketEvent.read,
      );

      if (response != RawSocketEvent.read) return null;

      final datagram = socket.receive();
      if (datagram == null || datagram.data.length < 48) return null;

      // Record local receive time
      final t4 = DateTime.now().millisecondsSinceEpoch;

      final data = datagram.data;

      // Extract server transmit timestamp (bytes 40-47)
      // This is the most reliable timestamp in the response
      final seconds = (data[40] << 24) | (data[41] << 16) | (data[42] << 8) | data[43];
      final fraction = (data[44] << 24) | (data[45] << 16) | (data[46] << 8) | data[47];

      // Convert NTP timestamp to Unix milliseconds
      final serverTimeMs = ((seconds - ntpEpochOffset) * 1000) +
          ((fraction * 1000) >> 32);

      // Calculate offset: how much the phone clock is ahead of real time
      // offset = ((t2 - t1) + (t3 - t4)) / 2
      // Simplified: offset ≈ localMidpoint - serverTime
      final localMidpoint = (t1 + t4) ~/ 2;
      final offset = localMidpoint - serverTimeMs;

      socket.close();
      return offset;
    } catch (e) {
      socket?.close();
      return null;
    }
  }

  /// Get human-readable status for debugging/UI.
  static String get statusText {
    if (!hasTrustedTime) {
      return 'NTP ಸಿಂಕ್ ಆಗಿಲ್ಲ (Not synced)';
    }
    final absOffset = _offsetMs.abs();
    if (absOffset < 2000) {
      return 'ಸಮಯ ನಿಖರ ✓ (${absOffset}ms)';
    }
    final seconds = absOffset ~/ 1000;
    if (seconds < 60) {
      return 'ಫೋನ್ ಗಡಿಯಾರ ${_offsetMs > 0 ? "ಮುಂದೆ" : "ಹಿಂದೆ"} ${seconds}s';
    }
    final minutes = seconds ~/ 60;
    if (minutes < 60) {
      return '⚠️ ಫೋನ್ ಗಡಿಯಾರ ${_offsetMs > 0 ? "ಮುಂದೆ" : "ಹಿಂದೆ"} ${minutes}m';
    }
    final hours = minutes ~/ 60;
    return '🚨 ಫೋನ್ ಗಡಿಯಾರ ${_offsetMs > 0 ? "ಮುಂದೆ" : "ಹಿಂದೆ"} ${hours}h ${minutes % 60}m';
  }

  /// True if phone clock appears tampered (offset > 5 minutes).
  static bool get isClockTampered => _offsetMs.abs() > 5 * 60 * 1000;
}
