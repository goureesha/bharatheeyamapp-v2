import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile: save files to temp and open Share sheet
Future<bool> exportMultipleFiles({
  required String clientsCsv,
  required String appointmentsCsv,
  required String notesTxt,
  required String dateStr,
}) async {
  try {
    final dir = await getTemporaryDirectory();
    
    final clientsFile = File('${dir.path}/Bharatheeyam_Clients_$dateStr.csv');
    await clientsFile.writeAsString(clientsCsv);
    
    final apptsFile = File('${dir.path}/Bharatheeyam_Appointments_$dateStr.csv');
    await apptsFile.writeAsString(appointmentsCsv);
    
    final notesFile = File('${dir.path}/Bharatheeyam_Kundali_Notes_$dateStr.txt');
    await notesFile.writeAsString(notesTxt);
    
    await Share.shareXFiles(
      [
        XFile(clientsFile.path),
        XFile(apptsFile.path),
        XFile(notesFile.path),
      ],
      text: 'Bharatheeyam App Data (Spreadsheets & Notes)',
    );
    
    return true;
  } catch (e) {
    return false;
  }
}

/// Stubs for backup_service_stub compat
Future<bool> exportJsonFile(String jsonString, String fileName) async {
  throw UnsupportedError('Use backup_service_mobile.dart');
}

Future<String?> pickJsonFile() async {
  throw UnsupportedError('Use backup_service_mobile.dart');
}
