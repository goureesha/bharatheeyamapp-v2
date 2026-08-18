import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'google_auth_service.dart';
import 'client_service.dart';
import 'appointment_service.dart';
import '../core/user_muhurta_rules.dart';

/// Google Drive backup service — stores app data in the user's
/// hidden appDataFolder (not visible to the user in Drive UI).
/// Uses raw HTTP calls to the Drive REST API v3.
class DriveBackupService {
  static const String _fileName = 'bharatheeyam_backup.json';
  static const String _mimeType = 'application/json';
  static const String _driveApi = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApi = 'https://www.googleapis.com/upload/drive/v3';

  /// Valid SharedPreferences keys to backup (same as BackupService)
  static const Set<String> _validKeys = {
    'bharatheeyam_clients_cache',
    'bharatheeyam_members_cache',
    'bharatheeyam_next_client_id',
    'cached_appointments',
    'cached_slots',
    'bharatheeyam_profiles_v1',
    // Pooja lists
    'bharatheeyam_pooja_lists_v1',
    // Default Jyotishi (astrologer) details
    'default_jyotishi_name',
    'default_jyotishi_address',
    'default_jyotishi_phone',
    // Muhurta user rules (per event type)
    'user_muhurta_rules_vivaha',
    'user_muhurta_rules_upanayana',
    'user_muhurta_rules_grihaPrevesha',
    'user_muhurta_rules_devaPratishtha',
    'user_muhurta_rules_aksharabhyasa',
    'user_muhurta_rules_yatra',
    'user_muhurta_rules_vyapara',
    'user_muhurta_rules_annaprashana',
    'user_muhurta_rules_namakarana',
    'user_muhurta_rules_seemanta',
    'user_muhurta_rules_chowla',
    'user_muhurta_rules_vastuShilanyas',
    'user_muhurta_rules_aushadha',
    'user_muhurta_rules_krishi',
    'user_muhurta_rules_vahanaKraya',
    'user_muhurta_rules_aasthiKraya',
    'user_muhurta_rules_swarnaKraya',
    'user_muhurta_rules_udyoga',
    'user_muhurta_rules_karnavedha',
  };

  /// Upload app data to Google Drive appDataFolder.
  /// Returns a status message string.
  static Future<String> uploadBackup() async {
    try {
      // 1. Ensure Drive scope is granted (prompts user if needed)
      final scopeOk = await GoogleAuthService.ensureDriveScope();
      if (!scopeOk) {
        return 'ದಯವಿಟ್ಟು Google Drive ಅನುಮತಿ ನೀಡಿ (Please grant Drive permission)';
      }

      // 2. Get auth headers
      final headers = await GoogleAuthService.getAuthHeaders();
      if (headers == null) {
        return 'ದಯವಿಟ್ಟು ಮೊದಲು Google ಸೈನ್ ಇನ್ ಮಾಡಿ (Please sign in first)';
      }

      // 2. Collect backup data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> backupData = {};
      for (final key in prefs.getKeys()) {
        if (_validKeys.contains(key)) {
          backupData[key] = prefs.get(key);
        }
      }
      backupData['_backup_timestamp'] = DateTime.now().toIso8601String();
      backupData['_backup_email'] = GoogleAuthService.userEmail ?? '';

      final jsonString = jsonEncode(backupData);
      final jsonBytes = utf8.encode(jsonString);

      // 3. Check if file already exists in appDataFolder
      final existingFileId = await _findBackupFileId(headers);

      if (existingFileId != null) {
        // Update existing file
        final updateUrl = '$_uploadApi/files/$existingFileId?uploadType=media';
        final response = await http.patch(
          Uri.parse(updateUrl),
          headers: {
            ...headers,
            'Content-Type': _mimeType,
          },
          body: jsonBytes,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return 'success';
        } else {
          debugPrint('Drive update failed: ${response.statusCode} ${response.body}');
          return 'ಬ್ಯಾಕಪ್ ನವೀಕರಣ ವಿಫಲ (Update failed: ${response.statusCode})';
        }
      } else {
        // Create new file in appDataFolder
        final metadata = jsonEncode({
          'name': _fileName,
          'parents': ['appDataFolder'],
        });

        // Use multipart upload
        final boundary = 'bharatheeyam_boundary_${DateTime.now().millisecondsSinceEpoch}';
        final body = '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$metadata\r\n'
            '--$boundary\r\n'
            'Content-Type: $_mimeType\r\n\r\n'
            '$jsonString\r\n'
            '--$boundary--';

        final createUrl = '$_uploadApi/files?uploadType=multipart';
        final response = await http.post(
          Uri.parse(createUrl),
          headers: {
            ...headers,
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: body,
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return 'success';
        } else {
          debugPrint('Drive create failed: ${response.statusCode} ${response.body}');
          return 'ಬ್ಯಾಕಪ್ ರಚನೆ ವಿಫಲ (Create failed: ${response.statusCode})';
        }
      }
    } catch (e) {
      debugPrint('Drive backup upload error: $e');
      return 'ಬ್ಯಾಕಪ್ ವಿಫಲ: $e';
    }
  }

  /// Download and restore app data from Google Drive appDataFolder.
  /// Returns null on success, or an error message string.
  static Future<String?> downloadAndRestore() async {
    try {
      // 1. Ensure Drive scope is granted (prompts user if needed)
      final scopeOk = await GoogleAuthService.ensureDriveScope();
      if (!scopeOk) {
        return 'ದಯವಿಟ್ಟು Google Drive ಅನುಮತಿ ನೀಡಿ (Please grant Drive permission)';
      }

      // 2. Get auth headers
      final headers = await GoogleAuthService.getAuthHeaders();
      if (headers == null) {
        return 'ದಯವಿಟ್ಟು ಮೊದಲು Google ಸೈನ್ ಇನ್ ಮಾಡಿ (Please sign in first)';
      }

      // 2. Find existing backup file
      final fileId = await _findBackupFileId(headers);
      if (fileId == null) {
        return 'Google Drive ನಲ್ಲಿ ಬ್ಯಾಕಪ್ ಕಂಡುಬಂದಿಲ್ಲ (No backup found in Drive)';
      }

      // 3. Download file content
      final downloadUrl = '$_driveApi/files/$fileId?alt=media';
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return 'ಡೌನ್ಲೋಡ್ ವಿಫಲ (Download failed: ${response.statusCode})';
      }

      // 4. Parse JSON
      final Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(response.body);
      } catch (_) {
        return 'ಅಮಾನ್ಯವಾದ ಬ್ಯಾಕಪ್ ಡೇಟಾ (Invalid backup data)';
      }

      // 5. Validate
      if (!backupData.containsKey('bharatheeyam_clients_cache') &&
          !backupData.containsKey('bharatheeyam_profiles_v1')) {
        return 'ಇದು ಸರಿಯಾದ ಬ್ಯಾಕಪ್ ಅಲ್ಲ (Not a valid Bharatheeyam backup)';
      }

      // 6. Restore to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      for (final entry in backupData.entries) {
        final key = entry.key;
        final val = entry.value;

        // Skip metadata keys
        if (key.startsWith('_backup_')) continue;

        if (_validKeys.contains(key)) {
          if (val == null) {
            await prefs.remove(key);
          } else if (val is String) {
            await prefs.setString(key, val);
          } else if (val is int) {
            await prefs.setInt(key, val);
          } else if (val is double) {
            await prefs.setDouble(key, val);
          } else if (val is bool) {
            await prefs.setBool(key, val);
          } else if (val is List) {
            final List<String> strList = val.map((e) => e.toString()).toList();
            await prefs.setStringList(key, strList);
          }
        }
      }

      // 7. Reload in-memory caches
      await ClientService.loadAll();
      await AppointmentService.loadAll();
      await UserRulesManager.instance.loadAll();

      return null; // Success!
    } catch (e) {
      debugPrint('Drive backup restore error: $e');
      return 'ಮರುಸ್ಥಾಪನೆ ವಿಫಲ: $e';
    }
  }

  /// Get info about the last backup (timestamp, email, size).
  /// Returns null if no backup exists or user not signed in.
  static Future<Map<String, String>?> getBackupInfo() async {
    try {
      final headers = await GoogleAuthService.getAuthHeaders();
      if (headers == null) return null;

      final fileId = await _findBackupFileId(headers);
      if (fileId == null) return null;

      // Get file metadata
      final metaUrl = '$_driveApi/files/$fileId?fields=modifiedTime,size';
      final response = await http.get(
        Uri.parse(metaUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final modifiedTime = data['modifiedTime'] ?? '';
        final size = data['size'] ?? '0';

        // Format the timestamp
        String formattedTime = '';
        if (modifiedTime.isNotEmpty) {
          try {
            final dt = DateTime.parse(modifiedTime).toLocal();
            formattedTime = '${dt.day.toString().padLeft(2, '0')}/'
                '${dt.month.toString().padLeft(2, '0')}/'
                '${dt.year} '
                '${dt.hour.toString().padLeft(2, '0')}:'
                '${dt.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            formattedTime = modifiedTime;
          }
        }

        // Format size
        final sizeBytes = int.tryParse(size.toString()) ?? 0;
        String formattedSize;
        if (sizeBytes < 1024) {
          formattedSize = '$sizeBytes B';
        } else if (sizeBytes < 1024 * 1024) {
          formattedSize = '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
        } else {
          formattedSize = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
        }

        return {
          'lastBackup': formattedTime,
          'size': formattedSize,
        };
      }
    } catch (e) {
      debugPrint('Drive backup info error: $e');
    }
    return null;
  }

  /// Find the backup file ID in appDataFolder.
  /// Returns the file ID if found, null otherwise.
  static Future<String?> _findBackupFileId(Map<String, String> headers) async {
    try {
      final searchUrl = '$_driveApi/files'
          '?spaces=appDataFolder'
          '&q=name%3D%27$_fileName%27'
          '&fields=files(id,name)'
          '&pageSize=1';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List;
        if (files.isNotEmpty) {
          return files[0]['id'] as String;
        }
      }
    } catch (e) {
      debugPrint('Drive file search error: $e');
    }
    return null;
  }

  // ── Auto-backup ──────────────────────────────────────────────

  static const String _lastAutoBackupKey = 'bharatheeyam_last_auto_backup';
  static bool _autoBackupInProgress = false;

  /// Silently trigger Google Drive backup in background.
  /// Does nothing if not signed in or if already in progress.
  /// Safe to call from anywhere — never blocks UI, never shows errors.
  static Future<void> triggerAutoBackup() async {
    if (_autoBackupInProgress) return;
    if (!GoogleAuthService.isSignedIn) return;

    _autoBackupInProgress = true;
    try {
      debugPrint('AutoBackup: starting silent backup...');
      final result = await uploadBackup();
      if (result == 'success') {
        // Record the timestamp of successful backup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastAutoBackupKey, DateTime.now().toIso8601String());
        debugPrint('AutoBackup: success');
      } else {
        debugPrint('AutoBackup: failed — $result');
      }
    } catch (e) {
      debugPrint('AutoBackup: error — $e');
    } finally {
      _autoBackupInProgress = false;
    }
  }

  /// Check if daily auto-backup is due. If yes, trigger silently.
  /// Call this on app startup (e.g., in main.dart).
  static Future<void> autoBackupIfDue() async {
    if (!GoogleAuthService.isSignedIn) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupStr = prefs.getString(_lastAutoBackupKey);

      if (lastBackupStr == null) {
        // Never auto-backed up — do it now
        triggerAutoBackup(); // fire-and-forget
        return;
      }

      final lastBackup = DateTime.tryParse(lastBackupStr);
      if (lastBackup == null) {
        triggerAutoBackup();
        return;
      }

      final now = DateTime.now();
      final hoursSinceLastBackup = now.difference(lastBackup).inHours;

      // Auto-backup if more than 12 hours since last backup
      if (hoursSinceLastBackup >= 12) {
        debugPrint('AutoBackup: $hoursSinceLastBackup hours since last backup, triggering...');
        triggerAutoBackup(); // fire-and-forget
      } else {
        debugPrint('AutoBackup: last backup ${hoursSinceLastBackup}h ago, skipping');
      }
    } catch (e) {
      debugPrint('AutoBackup check error: $e');
    }
  }
}
