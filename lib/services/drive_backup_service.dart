import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_service.dart';

class DriveBackupService {
  static const String _backupFileName = 'user_data_bharatheeyam.json';

  /// Backup local profiles to Google Drive AppData folder
  static Future<bool> backupData() async {
    final client = await GoogleAuthService.getClient();
    if (client == null) return false;

    try {
      final driveApi = drive.DriveApi(client);
      
      // Get all local profiles
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('bharatheeyam_profiles_v1') ?? '{}';
      
      // Check if backup already exists
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
      );

      final byteData = utf8.encode(localData);
      final media = drive.Media(
        Stream.value(byteData),
        byteData.length,
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final fileId = fileList.files!.first.id!;
        final driveFile = drive.File();
        await driveApi.files.update(driveFile, fileId, uploadMedia: media);
      } else {
        // Create new file
        final driveFile = drive.File()
          ..name = _backupFileName
          ..parents = ['appDataFolder'];
        await driveApi.files.create(driveFile, uploadMedia: media);
      }
      return true;
    } catch (e) {
      print('Backup failed: $e');
      return false;
    }
  }

  /// Restore profiles from Google Drive AppData folder
  static Future<bool> restoreData() async {
    final client = await GoogleAuthService.getClient();
    if (client == null) return false;

    try {
      final driveApi = drive.DriveApi(client);
      
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return false; // No backup found
      }

      final fileId = fileList.files!.first.id!;
      final response = await driveApi.files.get(
        fileId, 
        downloadOptions: drive.DownloadOptions.fullMedia
      ) as drive.Media;
      
      final List<int> dataStore = [];
      await for (var data in response.stream) {
        dataStore.addAll(data);
      }
      
      final jsonStr = utf8.decode(dataStore);
      
      // Unpack and force overwrite
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bharatheeyam_profiles_v1', jsonStr);
      
      return true;
    } catch (e) {
      print('Restore failed: $e');
      return false;
    }
  }
}
