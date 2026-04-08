import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile: save to temp file and open Share sheet
Future<bool> exportJsonFile(String jsonString, String fileName) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Bharatheeyam App Data Backup',
    );
    return true;
  } catch (e) {
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
