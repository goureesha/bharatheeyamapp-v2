import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> shareCSV({
    required String csvContent,
    required String fileName,
    required String shareText,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv')],
      text: shareText,
    );
  }
}
