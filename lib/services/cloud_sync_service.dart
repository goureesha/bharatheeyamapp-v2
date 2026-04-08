import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'google_auth_service.dart';
import 'client_service.dart';
import 'appointment_service.dart';

/// Cloud sync service — backs up all app data to Firestore once per day.
///
/// Storage path: `user_data/{email}/backup`
/// Data synced: clients, family members, appointments, profiles, slots
class CloudSyncService {
  static const _lastSyncKey = 'bharatheeyam_last_cloud_sync_ms';
  static const _firestoreCollection = 'user_data';
  static const _syncIntervalMs = 24 * 60 * 60 * 1000; // 24 hours

  /// Last sync time (for UI display)
  static DateTime? _lastSyncTime;
  static DateTime? get lastSyncTime => _lastSyncTime;

  /// Whether a sync is currently in progress
  static bool _syncing = false;
  static bool get isSyncing => _syncing;

  /// The keys we back up to cloud
  static const Set<String> _backupKeys = {
    'bharatheeyam_clients_cache',
    'bharatheeyam_members_cache',
    'bharatheeyam_next_client_id',
    'cached_appointments',
    'cached_slots',
    'bharatheeyam_profiles_v1',
  };

  /// Initialize — load last sync time from prefs
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastSyncKey);
    if (lastMs != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastMs);
    }
  }

  /// Auto-sync if 24 hours have passed since last sync.
  /// Called from _deferredInit() — non-blocking, fire-and-forget.
  static Future<void> autoSyncIfNeeded() async {
    if (!GoogleAuthService.isSignedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastSyncKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastMs < _syncIntervalMs) {
      debugPrint('CloudSync: skipping — last sync ${((now - lastMs) / 3600000).toStringAsFixed(1)}h ago');
      return;
    }

    debugPrint('CloudSync: auto-sync triggered (>24h since last sync)');
    await syncToCloud();
  }

  /// Ensure Firebase is ready
  static Future<bool> _ensureFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAkG1hdauVlL9b8nHM5o2B25yPQ6IANci4',
            appId: '1:212430902387:web:149c933fd3d29aa5014606',
            messagingSenderId: '212430902387',
            projectId: 'bharatheeyam-app',
            authDomain: 'bharatheeyam-app.firebaseapp.com',
            storageBucket: 'bharatheeyam-app.firebasestorage.app',
            measurementId: 'G-BNTGY2WSLZ',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      return true;
    } catch (e) {
      debugPrint('CloudSync: Firebase init error: $e');
      return Firebase.apps.isNotEmpty;
    }
  }

  // ════════════════════════════════════════════════
  // UPLOAD TO CLOUD
  // ════════════════════════════════════════════════

  /// Upload all app data to Firestore.
  /// Returns true on success, false on failure.
  static Future<bool> syncToCloud() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return false;
    if (_syncing) return false; // prevent double-sync

    _syncing = true;
    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) {
        _syncing = false;
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Collect all backup data
      final Map<String, dynamic> backupData = {};
      for (final key in _backupKeys) {
        final value = prefs.get(key);
        if (value != null) {
          backupData[key] = value;
        }
      }

      // Add metadata
      backupData['_syncedAt'] = DateTime.now().toIso8601String();
      backupData['_deviceId'] = prefs.getString('bharatheeyam_device_id') ?? '';
      backupData['_version'] = '1.9.8';

      // Count items for metadata
      int clientCount = 0;
      int memberCount = 0;
      int appointmentCount = 0;
      int profileCount = 0;

      try {
        final clientsStr = prefs.getString('bharatheeyam_clients_cache');
        if (clientsStr != null) clientCount = (jsonDecode(clientsStr) as List).length;
        final membersStr = prefs.getString('bharatheeyam_members_cache');
        if (membersStr != null) memberCount = (jsonDecode(membersStr) as List).length;
        final apptsStr = prefs.getString('cached_appointments');
        if (apptsStr != null) appointmentCount = (jsonDecode(apptsStr) as List).length;
        final profilesStr = prefs.getString('bharatheeyam_profiles_v1');
        if (profilesStr != null) profileCount = (jsonDecode(profilesStr) as Map).length;
      } catch (_) {}

      backupData['_summary'] = {
        'clients': clientCount,
        'members': memberCount,
        'appointments': appointmentCount,
        'profiles': profileCount,
      };

      // Upload to Firestore
      // Path: user_data/{email}/backup
      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      await docRef.set(backupData).timeout(const Duration(seconds: 15));

      // Update last sync time
      final now = DateTime.now();
      _lastSyncTime = now;
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);

      _syncing = false;
      debugPrint('CloudSync: ✅ uploaded to cloud — '
          '$clientCount clients, $memberCount members, '
          '$appointmentCount appointments, $profileCount profiles');
      return true;
    } catch (e) {
      _syncing = false;
      debugPrint('CloudSync: ❌ upload failed: $e');
      return false;
    }
  }

  // ════════════════════════════════════════════════
  // DOWNLOAD FROM CLOUD
  // ════════════════════════════════════════════════

  /// Download backup from Firestore and restore to local storage.
  /// Returns true on success, false on failure.
  static Future<bool> syncFromCloud() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return false;
    if (_syncing) return false;

    _syncing = true;
    try {
      final firebaseReady = await _ensureFirebase();
      if (!firebaseReady) {
        _syncing = false;
        return false;
      }

      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      final doc = await docRef.get().timeout(const Duration(seconds: 15));

      if (!doc.exists || doc.data() == null) {
        _syncing = false;
        debugPrint('CloudSync: no cloud backup found for $email');
        return false;
      }

      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      // Restore only valid backup keys
      for (final key in _backupKeys) {
        final value = data[key];
        if (value == null) continue;

        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List) {
          await prefs.setStringList(key, value.map((e) => e.toString()).toList());
        }
      }

      // Reload in-memory caches
      await ClientService.loadAll();
      await AppointmentService.loadAll();

      // Update last sync time
      final now = DateTime.now();
      _lastSyncTime = now;
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);

      _syncing = false;

      final summary = data['_summary'] as Map<String, dynamic>?;
      debugPrint('CloudSync: ✅ restored from cloud — '
          '${summary?['clients'] ?? '?'} clients, '
          '${summary?['members'] ?? '?'} members, '
          '${summary?['appointments'] ?? '?'} appointments, '
          '${summary?['profiles'] ?? '?'} profiles');
      return true;
    } catch (e) {
      _syncing = false;
      debugPrint('CloudSync: ❌ download failed: $e');
      return false;
    }
  }

  /// Human-readable last sync text for UI
  static String get lastSyncText {
    if (_lastSyncTime == null) return 'ಇನ್ನೂ ಸಿಂಕ್ ಆಗಿಲ್ಲ (Never synced)';
    final diff = DateTime.now().difference(_lastSyncTime!);
    if (diff.inMinutes < 1) return 'ಈಗ ಸಿಂಕ್ ಆಗಿದೆ (Just now)';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ನಿಮಿಷಗಳ ಹಿಂದೆ';
    if (diff.inHours < 24) return '${diff.inHours} ಗಂಟೆಗಳ ಹಿಂದೆ';
    return '${diff.inDays} ದಿನಗಳ ಹಿಂದೆ';
  }
}
