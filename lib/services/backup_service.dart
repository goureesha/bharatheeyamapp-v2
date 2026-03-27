import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'client_service.dart';
import 'appointment_service.dart';

class BackupService {
  
  /// Exports all relevant app data to a JSON file and opens the native Share sheet.
  /// Returns [true] if successfully triggered, [false] if failed.
  static Future<bool> exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> backupData = {};

      // We need to backup:
      // 1. "bharatheeyam_clients_cache"
      // 2. "bharatheeyam_members_cache"
      // 3. "bharatheeyam_next_client_id"
      // 4. "cached_appointments"
      // 5. "cached_slots"
      // 6. "bharatheeyam_profiles_v1" (from StorageService)
      
      final Set<String> validKeys = {
        'bharatheeyam_clients_cache',
        'bharatheeyam_members_cache',
        'bharatheeyam_next_client_id',
        'cached_appointments',
        'cached_slots',
        'bharatheeyam_profiles_v1',
      };

      final keys = prefs.getKeys();
      for (final key in keys) {
        if (validKeys.contains(key)) {
          // Some keys are string lists, some are ints, some are strings. Handle them dynamically.
          backupData[key] = prefs.get(key);
        }
      }

      final jsonString = jsonEncode(backupData);

      // Save to a temporary file
      final dir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
      final file = File('${dir.path}/bharatheeyam_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      // Trigger standard system share to let the user save it to Drive/Files
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Bharatheeyam App Data Backup ($dateStr)',
      );

      return true;
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return false;
    }
  }

  /// Prompts the user to pick a backup JSON file, reads it, and restores the data.
  /// Returns [null] on success, or an error message string on failure.
  static Future<String?> importData() async {
    try {
      // 1. Pick the file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return 'ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ (Cancelled)';
      }

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // 2. Parse and validate
      final Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(jsonString);
      } catch (_) {
        return 'ಅಮಾನ್ಯವಾದ ಬ್ಯಾಕಪ್ ಫೈಲ್ (Invalid JSON file)';
      }

      if (!backupData.containsKey('bharatheeyam_clients_cache') && !backupData.containsKey('bharatheeyam_profiles_v1')) {
         return 'ಇದು ಸರಿಯಾದ ಬ್ಯಾಕಪ್ ಫೈಲ್ ಅಲ್ಲ (Not a valid Bharatheeyam backup)';
      }

      // 3. Restore to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      final Set<String> validKeys = {
        'bharatheeyam_clients_cache',
        'bharatheeyam_members_cache',
        'bharatheeyam_next_client_id',
        'cached_appointments',
        'cached_slots',
        'bharatheeyam_profiles_v1',
      };
      
      for (final entry in backupData.entries) {
        final key = entry.key;
        final val = entry.value;

        // Ensure we only restore app data keys to avoid breaking device bindings
        if (validKeys.contains(key)) {
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

      // 4. Reload in-memory cache for our UI
      await ClientService.loadAll();
      await AppointmentService.loadAll();

      return null; // Success!

    } catch (e) {
      debugPrint('Backup import failed: $e');
      return 'ಮರುಸ್ಥಾಪನೆ ವಿಫಲವಾಗಿದೆ (Restore failed): $e';
    }
  }
}
