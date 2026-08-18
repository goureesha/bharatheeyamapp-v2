import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'client_service.dart';
import 'appointment_service.dart';
import '../core/user_muhurta_rules.dart';

// Conditional imports for platform-specific file operations
import 'backup_service_stub.dart'
    if (dart.library.html) 'backup_service_web.dart'
    if (dart.library.io) 'backup_service_mobile.dart' as platform;

class BackupService {

  static const Set<String> validKeys = {
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

  /// Exports all relevant app data to a JSON file.
  /// On mobile: opens Share sheet. On web: triggers browser download.
  static Future<bool> exportData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> backupData = {};

      final keys = prefs.getKeys();
      for (final key in keys) {
        if (validKeys.contains(key)) {
          backupData[key] = prefs.get(key);
        }
      }

      final jsonString = jsonEncode(backupData);
      final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
      final fileName = 'bharatheeyam_backup_$dateStr.json';

      return await platform.exportJsonFile(jsonString, fileName);
    } catch (e) {
      debugPrint('Backup export failed: $e');
      return false;
    }
  }

  /// Imports app data from a JSON file.
  /// On mobile: opens file picker. On web: opens browser file dialog.
  static Future<String?> importData() async {
    try {
      final jsonString = await platform.pickJsonFile();
      if (jsonString == null) {
        return 'ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ (Cancelled)';
      }

      // Parse and validate
      final Map<String, dynamic> backupData;
      try {
        backupData = jsonDecode(jsonString);
      } catch (_) {
        return 'ಅಮಾನ್ಯವಾದ ಬ್ಯಾಕಪ್ ಫೈಲ್ (Invalid JSON file)';
      }

      if (!backupData.containsKey('bharatheeyam_clients_cache') &&
          !backupData.containsKey('bharatheeyam_profiles_v1')) {
        return 'ಇದು ಸರಿಯಾದ ಬ್ಯಾಕಪ್ ಫೈಲ್ ಅಲ್ಲ (Not a valid Bharatheeyam backup)';
      }

      // Restore to SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      for (final entry in backupData.entries) {
        final key = entry.key;
        final val = entry.value;

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

      // Reload in-memory cache
      await ClientService.loadAll();
      await AppointmentService.loadAll();
      await UserRulesManager.instance.loadAll();

      return null; // Success!
    } catch (e) {
      debugPrint('Backup import failed: $e');
      return 'ಮರುಸ್ಥಾಪನೆ ವಿಫಲವಾಗಿದೆ (Restore failed): $e';
    }
  }
}
