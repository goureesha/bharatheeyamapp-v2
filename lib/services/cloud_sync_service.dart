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

  /// Last error message (for debugging)
  static String? _lastError;
  static String? get lastError => _lastError;

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

  /// Check if Firebase is ready (should already be initialized by FirebaseService.init())
  static bool _isFirebaseReady() {
    return Firebase.apps.isNotEmpty;
  }

  // ════════════════════════════════════════════════
  // UPLOAD TO CLOUD
  // ════════════════════════════════════════════════

  /// Upload all app data to Firestore.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> syncToCloud() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) {
      _lastError = 'Google ಸೈನ್ ಇನ್ ಆಗಿಲ್ಲ (Not signed in)';
      return _lastError;
    }
    if (_syncing) {
      _lastError = 'ಈಗಾಗಲೇ ಸಿಂಕ್ ಆಗುತ್ತಿದೆ... (Sync in progress)';
      return _lastError;
    }

    _syncing = true;
    try {
      if (!_isFirebaseReady()) {
        _syncing = false;
        _lastError = 'Firebase ಪ್ರಾರಂಭಿಸಲು ವಿಫಲ (Firebase not initialized)';
        debugPrint('CloudSync: ❌ Firebase not initialized');
        return _lastError;
      }

      final prefs = await SharedPreferences.getInstance();

      // Collect all backup data — convert everything to JSON-safe types
      final Map<String, dynamic> backupData = {};
      for (final key in _backupKeys) {
        final value = prefs.get(key);
        if (value == null) continue;

        // Firestore only accepts: String, int, double, bool, Map, List, Timestamp, GeoPoint, Blob, null
        // SharedPreferences can return: String, int, double, bool, List<String>
        if (value is String) {
          backupData[key] = value;
        } else if (value is int) {
          backupData[key] = value;
        } else if (value is double) {
          backupData[key] = value;
        } else if (value is bool) {
          backupData[key] = value;
        } else if (value is List) {
          // Convert List<String> to a JSON string for safe Firestore storage
          backupData[key] = jsonEncode(value);
        } else {
          // Unknown type — convert to string
          debugPrint('CloudSync: warning — key $key has unexpected type ${value.runtimeType}, converting to string');
          backupData[key] = value.toString();
        }
      }

      // Add metadata
      backupData['_syncedAt'] = DateTime.now().toIso8601String();
      backupData['_deviceId'] = prefs.getString('bharatheeyam_device_id') ?? '';
      backupData['_version'] = '1.9.11';

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

      // Estimate data size (Firestore 1MB limit per document)
      final dataStr = jsonEncode(backupData);
      final dataSizeKB = (dataStr.length / 1024).round();
      debugPrint('CloudSync: data size ≈ ${dataSizeKB}KB');

      if (dataStr.length > 900000) {
        // Data too big for a single Firestore document — try chunked upload
        debugPrint('CloudSync: data too large (${dataSizeKB}KB), attempting chunked upload...');
        return await _chunkedUpload(email, backupData, prefs);
      }

      // Upload to Firestore
      // Path: user_data/{email}
      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      debugPrint('CloudSync: uploading to ${_firestoreCollection}/${email.toLowerCase()}...');

      // Retry up to 2 times on failure
      String? uploadError;
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          await docRef.set(backupData).timeout(const Duration(seconds: 30));
          uploadError = null;
          break; // success
        } catch (e) {
          uploadError = e.toString();
          debugPrint('CloudSync: attempt $attempt failed: $e');
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      if (uploadError != null) {
        _syncing = false;
        _lastError = 'ಅಪ್‌ಲೋಡ್ ವಿಫಲ: $uploadError';
        debugPrint('CloudSync: ❌ upload failed after retries: $uploadError');
        return _lastError;
      }

      // Update last sync time
      final now = DateTime.now();
      _lastSyncTime = now;
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);

      _syncing = false;
      _lastError = null;
      debugPrint('CloudSync: ✅ uploaded to cloud — '
          '$clientCount clients, $memberCount members, '
          '$appointmentCount appointments, $profileCount profiles');
      return null; // success
    } catch (e, stack) {
      _syncing = false;
      _lastError = e.toString();
      debugPrint('CloudSync: ❌ upload error: $e');
      debugPrint('CloudSync: stack: $stack');
      return _lastError;
    }
  }

  /// Chunked upload for data > 900KB
  /// Splits backup into multiple sub-documents under user_data/{email}/chunks/
  static Future<String?> _chunkedUpload(
    String email,
    Map<String, dynamic> backupData,
    SharedPreferences prefs,
  ) async {
    try {
      final basePath = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      // Upload metadata + summary to main doc
      final metadata = <String, dynamic>{
        '_syncedAt': backupData['_syncedAt'],
        '_deviceId': backupData['_deviceId'],
        '_version': backupData['_version'],
        '_summary': backupData['_summary'],
        '_chunked': true,
        '_chunkKeys': <String>[],
      };

      final chunkKeys = <String>[];

      // Upload each backup key as a separate sub-document
      for (final key in _backupKeys) {
        final value = backupData[key];
        if (value == null) continue;

        try {
          await basePath.collection('chunks').doc(key).set({
            'data': value,
            'updatedAt': DateTime.now().toIso8601String(),
          }).timeout(const Duration(seconds: 20));
          chunkKeys.add(key);
          debugPrint('CloudSync: chunk uploaded: $key');
        } catch (e) {
          debugPrint('CloudSync: chunk upload failed for $key: $e');
        }
      }

      metadata['_chunkKeys'] = chunkKeys;

      await basePath.set(metadata).timeout(const Duration(seconds: 15));

      // Update last sync time
      final now = DateTime.now();
      _lastSyncTime = now;
      await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);

      _syncing = false;
      _lastError = null;
      debugPrint('CloudSync: ✅ chunked upload complete — ${chunkKeys.length} chunks');
      return null;
    } catch (e) {
      _syncing = false;
      _lastError = 'Chunked upload ವಿಫಲ: $e';
      debugPrint('CloudSync: ❌ chunked upload error: $e');
      return _lastError;
    }
  }

  // ════════════════════════════════════════════════
  // DOWNLOAD FROM CLOUD
  // ════════════════════════════════════════════════

  /// Download backup from Firestore and restore to local storage.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> syncFromCloud() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) {
      _lastError = 'Google ಸೈನ್ ಇನ್ ಆಗಿಲ್ಲ (Not signed in)';
      return _lastError;
    }
    if (_syncing) {
      _lastError = 'ಈಗಾಗಲೇ ಸಿಂಕ್ ಆಗುತ್ತಿದೆ... (Sync in progress)';
      return _lastError;
    }

    _syncing = true;
    try {
      if (!_isFirebaseReady()) {
        _syncing = false;
        _lastError = 'Firebase ಪ್ರಾರಂಭಿಸಲು ವಿಫಲ (Firebase not initialized)';
        return _lastError;
      }

      final docRef = FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(email.toLowerCase());

      debugPrint('CloudSync: downloading from ${_firestoreCollection}/${email.toLowerCase()}...');
      final doc = await docRef.get().timeout(const Duration(seconds: 30));

      if (!doc.exists || doc.data() == null) {
        _syncing = false;
        _lastError = 'ಕ್ಲೌಡ್‌ನಲ್ಲಿ ಬ್ಯಾಕಪ್ ಕಂಡುಬಂದಿಲ್ಲ (No backup found)';
        debugPrint('CloudSync: no cloud backup found for $email');
        return _lastError;
      }

      final data = Map<String, dynamic>.from(doc.data()!);
      final prefs = await SharedPreferences.getInstance();

      // Check if data was uploaded in chunked mode
      final isChunked = data['_chunked'] == true;

      if (isChunked) {
        debugPrint('CloudSync: detected chunked backup, downloading chunks...');
        final chunkKeys = (data['_chunkKeys'] as List?)?.cast<String>() ?? [];
        for (final key in chunkKeys) {
          try {
            final chunkDoc = await docRef.collection('chunks').doc(key).get()
                .timeout(const Duration(seconds: 15));
            if (chunkDoc.exists && chunkDoc.data() != null) {
              final chunkData = chunkDoc.data()!['data'];
              if (chunkData != null) {
                data[key] = chunkData;
              }
            }
          } catch (e) {
            debugPrint('CloudSync: failed to download chunk $key: $e');
          }
        }
      }

      // Restore only valid backup keys
      int restoredCount = 0;
      for (final key in _backupKeys) {
        final value = data[key];
        if (value == null) continue;

        if (value is String) {
          await prefs.setString(key, value);
          restoredCount++;
        } else if (value is int) {
          await prefs.setInt(key, value);
          restoredCount++;
        } else if (value is double) {
          await prefs.setDouble(key, value);
          restoredCount++;
        } else if (value is bool) {
          await prefs.setBool(key, value);
          restoredCount++;
        } else if (value is List) {
          await prefs.setStringList(key, value.map((e) => e.toString()).toList());
          restoredCount++;
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
      _lastError = null;

      final summary = data['_summary'] as Map<String, dynamic>?;
      debugPrint('CloudSync: ✅ restored from cloud ($restoredCount keys) — '
          '${summary?['clients'] ?? '?'} clients, '
          '${summary?['members'] ?? '?'} members, '
          '${summary?['appointments'] ?? '?'} appointments, '
          '${summary?['profiles'] ?? '?'} profiles');
      return null; // success
    } catch (e, stack) {
      _syncing = false;
      _lastError = e.toString();
      debugPrint('CloudSync: ❌ download failed: $e');
      debugPrint('CloudSync: stack: $stack');
      return _lastError;
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
