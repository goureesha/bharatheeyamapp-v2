import 'package:flutter/foundation.dart';

import 'client_service.dart';
import 'appointment_service.dart';
import 'storage_service.dart';

// Conditional imports
import 'backup_service_stub.dart'
    if (dart.library.html) 'local_export_web.dart'
    if (dart.library.io) 'local_export_mobile.dart' as platform;

class LocalExportService {
  /// Generates CSV files for clients/appointments and a TXT file for Kundali notes.
  /// On mobile: opens Share sheet. On web: triggers browser download.
  static Future<bool> exportReadableData() async {
    try {
      final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');

      // 1. Generate Clients CSV
      final StringBuffer clientCsv = StringBuffer();
      clientCsv.write('\xEF\xBB\xBF');
      clientCsv.writeln('ID,Name,Phone,Place,Latitude,Longitude,Date,Time,Notes');
      
      for (final c in ClientService.clients) {
        final cName = c.name.replaceAll('"', '""');
        final cPhone = c.phone.replaceAll('"', '""');
        final cPlace = c.address.replaceAll('"', '""');
        final cCreatedAt = c.createdAt.replaceAll('"', '""');
        clientCsv.writeln('"${c.clientId}","$cName","$cPhone","$cPlace",0.0,0.0,"$cCreatedAt","",""');
      }

      // 2. Generate Appointments CSV
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

      // 3. Generate Kundali Notes
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
          if (p.clientId != null && p.clientId!.trim().isNotEmpty) {
            notesTxt.writeln('Client ID: ${p.clientId}');
          }
          notesTxt.writeln('Date: ${p.date}  Time: ${p.hour}:${p.minute.toString().padLeft(2, '0')} ${p.ampm}');
          notesTxt.writeln('--------------------------------------------------------');
          notesTxt.writeln('${p.notes}\n\n');
        }
      }

      if (!hasNotes) {
        notesTxt.writeln('No Kundali notes found in any saved profiles.');
      }

      // Export using platform-specific implementation
      return await platform.exportMultipleFiles(
        clientsCsv: clientCsv.toString(),
        appointmentsCsv: apptCsv.toString(),
        notesTxt: notesTxt.toString(),
        dateStr: dateStr,
      );
    } catch (e) {
      debugPrint('Local Export Service Error: $e');
      return false;
    }
  }
}
