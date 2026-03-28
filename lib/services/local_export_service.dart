import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'client_service.dart';
import 'appointment_service.dart';
import 'storage_service.dart';

class LocalExportService {
  /// Generates CSV files for clients/appointments and a TXT file for Kundali notes.
  /// Then opens the native Share sheet to let the user save them.
  static Future<bool> exportReadableData() async {
    try {
      final dir = await getTemporaryDirectory();
      final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');

      // 1. Generate Clients CSV
      final clientsFile = File('${dir.path}/Bharatheeyam_Clients_$dateStr.csv');
      final StringBuffer clientCsv = StringBuffer();
      // Write CSV Header (BOM is useful for Excel to recognize UTF-8)
      clientCsv.write('\xEF\xBB\xBF');
      clientCsv.writeln('ID,Name,Phone,Place,Latitude,Longitude,Date,Time,Notes');
      
      for (final c in ClientService.clients) {
        // Escape quotes and wrap in quotes to handle commas inside text
        final cName = c.name.replaceAll('"', '""');
        final cPhone = c.phone.replaceAll('"', '""');
        final cPlace = c.place.replaceAll('"', '""');
        final cNotes = c.notes.replaceAll('"', '""').replaceAll('\n', ' ');
        
        clientCsv.writeln('"${c.clientId}","$cName","$cPhone","$cPlace",${c.lat},${c.lon},"${c.dateStr}","${c.timeStr}","$cNotes"');
      }
      await clientsFile.writeAsString(clientCsv.toString());

      // 2. Generate Appointments CSV
      final apptsFile = File('${dir.path}/Bharatheeyam_Appointments_$dateStr.csv');
      final StringBuffer apptCsv = StringBuffer();
      apptCsv.write('\xEF\xBB\xBF');
      apptCsv.writeln('Date,Start Time,End Time,Client Name,Client Phone,Status,Notes');
      
      for (final a in AppointmentService.appointments) {
        final aName = a.clientName.replaceAll('"', '""');
        final aPhone = a.clientPhone.replaceAll('"', '""');
        final aStatus = a.status.replaceAll('"', '""');
        final aNotes = a.notes.replaceAll('"', '""').replaceAll('\n', ' ');
        
        apptCsv.writeln('"${a.dateStr}","${a.startTime}","${a.endTime}","$aName","$aPhone","$aStatus","$aNotes"');
      }
      await apptsFile.writeAsString(apptCsv.toString());

      // 3. Generate single text file for all Kundali Notes
      final notesFile = File('${dir.path}/Bharatheeyam_Kundali_Notes_$dateStr.txt');
      final StringBuffer notesTxt = StringBuffer();
      notesTxt.writeln('============== BHARATHEEYAM KUNDALI NOTES ==============');
      notesTxt.writeln('Exported on: $dateStr\n');

      final profiles = await StorageService.loadAll();
      bool hasNotes = false;
      
      for (final p in profiles.values) {
        if (p.notes.trim().isNotEmpty) {
          hasNotes = true;
          notesTxt.writeln('--------------------------------------------------------');
          notesTxt.writeln('Profile: ${p.name}');
          notesTxt.writeln('Date: ${p.date}  Time: ${p.hour}:${p.minute.toString().padLeft(2, '0')} ${p.ampm}');
          notesTxt.writeln('--------------------------------------------------------');
          notesTxt.writeln('${p.notes}\n\n');
        }
      }

      if (!hasNotes) {
        notesTxt.writeln('No Kundali notes found in any saved profiles.');
      }

      await notesFile.writeAsString(notesTxt.toString());

      // 4. Share the 3 files
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
      debugPrint('Local Export Service Error: $e');
      return false;
    }
  }
}
