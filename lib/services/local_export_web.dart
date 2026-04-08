// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Web: trigger browser downloads for all export files
Future<bool> exportMultipleFiles({
  required String clientsCsv,
  required String appointmentsCsv,
  required String notesTxt,
  required String dateStr,
}) async {
  try {
    // Download clients CSV
    _downloadFile(clientsCsv, 'Bharatheeyam_Clients_$dateStr.csv', 'text/csv');
    
    // Small delay between downloads so browser doesn't block them
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Download appointments CSV
    _downloadFile(appointmentsCsv, 'Bharatheeyam_Appointments_$dateStr.csv', 'text/csv');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Download notes TXT
    _downloadFile(notesTxt, 'Bharatheeyam_Kundali_Notes_$dateStr.txt', 'text/plain');
    
    return true;
  } catch (e) {
    return false;
  }
}

void _downloadFile(String content, String fileName, String mimeType) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  
  html.Url.revokeObjectUrl(url);
}

/// Web: open browser file picker (not used by LocalExportService but needed for the stub)
Future<String?> pickJsonFile() async => null;

/// Stub for backup_service_stub compat
Future<bool> exportJsonFile(String jsonString, String fileName) async {
  try {
    _downloadFile(jsonString, fileName, 'application/json');
    return true;
  } catch (e) {
    return false;
  }
}
