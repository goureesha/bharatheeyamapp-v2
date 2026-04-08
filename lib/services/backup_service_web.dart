// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Web: trigger a browser file download
Future<bool> exportJsonFile(String jsonString, String fileName) async {
  try {
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    return false;
  }
}

/// Web: open browser file picker and read JSON content
Future<String?> pickJsonFile() async {
  try {
    final input = html.FileUploadInputElement()
      ..accept = '.json'
      ..click();

    await input.onChange.first;
    
    if (input.files == null || input.files!.isEmpty) return null;
    
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    
    return reader.result as String?;
  } catch (e) {
    return null;
  }
}
