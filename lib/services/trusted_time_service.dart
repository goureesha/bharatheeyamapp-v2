import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Provides a trusted time source using NTP (Network Time Protocol).
///
/// On startup, syncs with NTP servers to detect phone clock manipulation.
/// Falls back to HTTP Date headers, then to device time when offline.
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
      'time.apple.com',
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

    // NTP failed on all servers — try HTTP Date header fallback
    debugPrint('⚠️ NTP failed on all servers — trying HTTP fallback...');
    final httpOk = await _syncWithHttp();
    if (httpOk) return true;

    debugPrint('⚠️ All sync methods failed — using cached offset: ${_offsetMs}ms');
    return false;
  }

  // ════════════════════════════════════════════════
  // NTP QUERY (raw UDP)
  // ════════════════════════════════════════════════

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
      final request = Uint8List(48);
      request[0] = 0x23; // NTP v4, client mode

      // Record local send time
      final t1 = DateTime.now().millisecondsSinceEpoch;

      // Send request
      socket.send(request, addresses.first, 123);

      // Wait for response using Completer with manual timeout
      final completer = Completer<Datagram?>();
      Timer? timer;

      timer = Timer(const Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      late StreamSubscription<RawSocketEvent> sub;
      sub = socket.listen((event) {
        if (event == RawSocketEvent.read && !completer.isCompleted) {
          final datagram = socket?.receive();
          timer?.cancel();
          completer.complete(datagram);
          sub.cancel();
        }
      }, onError: (e) {
        if (!completer.isCompleted) {
          timer?.cancel();
          completer.complete(null);
        }
      });

      final datagram = await completer.future;

      if (datagram == null || datagram.data.length < 48) {
        socket.close();
        return null;
      }

      // Record local receive time
      final t4 = DateTime.now().millisecondsSinceEpoch;

      final data = datagram.data;

      // Extract server transmit timestamp (bytes 40-47)
      // NTP timestamps are 64-bit: 32-bit seconds since 1900 + 32-bit fraction
      // CRITICAL: Use explicit 64-bit arithmetic to avoid overflow
      final int seconds = ((data[40] & 0xFF) << 24) |
                          ((data[41] & 0xFF) << 16) |
                          ((data[42] & 0xFF) << 8)  |
                           (data[43] & 0xFF);
      final int fraction = ((data[44] & 0xFF) << 24) |
                           ((data[45] & 0xFF) << 16) |
                           ((data[46] & 0xFF) << 8)  |
                            (data[47] & 0xFF);

      // NTP epoch is 1900-01-01, Unix epoch is 1970-01-01
      // Difference: 70 years = 2208988800 seconds
      const int ntpEpochOffset = 2208988800;

      // Convert to Unix milliseconds using 64-bit arithmetic
      // seconds is unsigned 32-bit value (0..4294967295)
      // Ensure it's treated as unsigned by masking with 0xFFFFFFFF
      final int unixSeconds = (seconds & 0xFFFFFFFF) - ntpEpochOffset;
      final int fractionMs = ((fraction & 0xFFFFFFFF) * 1000) >> 32;
      final int serverTimeMs = unixSeconds * 1000 + fractionMs;

      // Calculate offset: how much the phone clock is ahead of real time
      // Using NTP formula: offset = ((t2 - t1) + (t3 - t4)) / 2
      // For a simple query, t2 ≈ t3 ≈ serverTime, so:
      // offset ≈ localMidpoint - serverTime
      final int localMidpoint = (t1 + t4) ~/ 2;
      final int offset = localMidpoint - serverTimeMs;

      socket.close();

      // Sanity check: if offset is > 1 year, something is wrong with the parse
      if (offset.abs() > 365 * 24 * 60 * 60 * 1000) {
        debugPrint('⚠️ NTP offset too large (${offset}ms) — discarding');
        return null;
      }

      return offset;
    } catch (e) {
      socket?.close();
      return null;
    }
  }

  // ════════════════════════════════════════════════
  // HTTP DATE HEADER FALLBACK
  // ════════════════════════════════════════════════

  /// Fallback: use HTTP Date response header from Google.
  /// Less accurate than NTP (~100-500ms) but works when UDP port 123 is blocked.
  static Future<bool> _syncWithHttp() async {
    final urls = [
      'https://www.google.com',
      'https://www.cloudflare.com',
    ];

    for (final url in urls) {
      try {
        final t1 = DateTime.now().millisecondsSinceEpoch;
        final response = await http.head(Uri.parse(url))
            .timeout(const Duration(seconds: 5));
        final t4 = DateTime.now().millisecondsSinceEpoch;

        final dateHeader = response.headers['date'];
        if (dateHeader == null) continue;

        // Parse HTTP Date header (RFC 7231 format)
        final serverTime = HttpDate.parse(dateHeader);
        final serverMs = serverTime.millisecondsSinceEpoch;

        final localMidpoint = (t1 + t4) ~/ 2;
        final offset = localMidpoint - serverMs;

        // HTTP Date has 1-second resolution, so accept larger variance
        if (offset.abs() > 365 * 24 * 60 * 60 * 1000) {
          debugPrint('⚠️ HTTP offset too large (${offset}ms) — discarding');
          continue;
        }

        _offsetMs = offset;
        _synced = true;
        _lastSyncTime = DateTime.now();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_offsetKey, _offsetMs);
        await prefs.setInt(_lastSyncKey, _lastSyncTime!.millisecondsSinceEpoch);

        debugPrint('🌐 HTTP time synced via $url — offset: ${_offsetMs}ms '
            '(phone ${_offsetMs > 0 ? "ahead" : "behind"} by ${_offsetMs.abs()}ms)');
        return true;
      } catch (e) {
        debugPrint('HTTP time sync failed for $url: $e');
      }
    }
    return false;
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
