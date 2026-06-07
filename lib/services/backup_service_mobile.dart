import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Mobile: save to Downloads folder directly
Future<bool> exportJsonFile(String jsonString, String fileName) async {
  try {
    // Try to get the Downloads directory
    Directory? downloadsDir;
    if (defaultTargetPlatform == TargetPlatform.android) {
      downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        downloadsDir = await getExternalStorageDirectory();
      }
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    if (downloadsDir == null) {
      downloadsDir = await getTemporaryDirectory();
    }

    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsString(jsonString);
    debugPrint('Backup saved to: ${file.path}');
    return true;
  } catch (e) {
    debugPrint('Backup export error: $e');
    return false;
  }
}

/// Mobile: open system file picker
Future<String?> pickJsonFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    return await file.readAsString();
  } catch (e) {
    return null;
  }
}
