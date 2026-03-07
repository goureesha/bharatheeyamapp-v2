import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_service.dart';
import 'storage_service.dart';
import '../core/calculator.dart';
import '../core/shadbala.dart';
import '../core/ephemeris.dart';

class SheetsExportService {
  static const String _spreadsheetTitle = 'Bharatheeyam_User_Data';

  static Future<String?> exportToSheets() async {
    final client = await GoogleAuthService.getClient();
    if (client == null) return null;

    try {
      final sheetsApi = sheets.SheetsApi(client);
      final driveApi = drive.DriveApi(client);

      // 1. Find existing sheet
      final fileList = await driveApi.files.list(
        q: "name = '$_spreadsheetTitle' and mimeType = 'application/vnd.google-apps.spreadsheet' and trashed = false",
      );

      String spreadsheetId;

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        spreadsheetId = fileList.files!.first.id!;
      } else {
        // Create new spreadsheet
        final newSheet = sheets.Spreadsheet()
          ..properties = (sheets.SpreadsheetProperties()..title = _spreadsheetTitle);
        final created = await sheetsApi.spreadsheets.create(newSheet);
        spreadsheetId = created.spreadsheetId!;
        
        // Setup Headers
        final headers = [
          'Name (ಹೆಸರು)', 
          'Date of Birth (ಹುಟ್ಟಿದ ದಿನಾಂಕ)', 
          'Time of Birth (ಹುಟ್ಟಿದ ಸಮಯ)', 
          'Place of Birth (ಹುಟ್ಟಿದ ಸ್ಥಳ)', 
          'Latitude/Longitude', 
          'Total Shadbala Score (Rupas)', 
          'Key Planets (Strongest/Weakest)'
        ];

        final vr = sheets.ValueRange()..values = [headers];
        await sheetsApi.spreadsheets.values.update(
          vr,
          spreadsheetId,
          'Sheet1!A1:G1',
          valueInputOption: 'USER_ENTERED',
        );
      }

      // 2. Fetch Local Profiles
      final allProfiles = await StorageService.loadAll();
      final List<List<String>> rows = [];

      for (var entry in allProfiles.entries) {
        final p = entry.value;

        // Perform minimal calculation to fetch Shadbala total
         double jdBirth = Ephemeris.gregorianToJd(
          int.parse(p.date.split('-')[0]),
          int.parse(p.date.split('-')[1]),
          int.parse(p.date.split('-')[2]),
          p.hour,
          p.minute,
          0,
          5.5, // assuming IST
        );

        final planets = Ephemeris.calcAll(jdBirth, 'lahiri', true);
        final speeds = Ephemeris.calcAllSpeeds(jdBirth);
        final pan = Ephemeris.calcPanchang(jdBirth, p.lat, p.lon);

        final shadbala = ShadbalaLogic.calculateShadbala(
          longitudes: {
            'Sun': planets['Sun']![0], 'Moon': planets['Moon']![0], 'Mars': planets['Mars']![0],
            'Mercury': planets['Mercury']![0], 'Jupiter': planets['Jupiter']![0], 
            'Venus': planets['Venus']![0], 'Saturn': planets['Saturn']![0],
          },
          speeds: {
            'Sun': speeds['Sun']!, 'Moon': speeds['Moon']!, 'Mars': speeds['Mars']!,
            'Mercury': speeds['Mercury']!, 'Jupiter': speeds['Jupiter']!, 
            'Venus': speeds['Venus']!, 'Saturn': speeds['Saturn']!,
          },
          ascendant: planets['Asc']![0],
          sunRiseJd: pan['sunrise_jd'],
          birthJd: jdBirth,
        );

        double totalScore = 0.0;
        String strongest = '';
        double maxScore = -1.0;
        String weakest = '';
        double minScore = 999.0;

        shadbala.forEach((key, value) {
          double score = value['Total'] ?? 0.0;
          totalScore += score;
          if (score > maxScore) { maxScore = score; strongest = key; }
          if (score < minScore) { minScore = score; weakest = key; }
        });

        rows.add([
          p.name,
          p.date,
          '${p.hour}:${p.minute.toString().padLeft(2, '0')} ${p.ampm}',
          p.place,
          '${p.lat}, ${p.lon}',
          totalScore.toStringAsFixed(2),
          'Strongest: $strongest, Weakest: $weakest'
        ]);
      }

      // 3. Append Rows
      if (rows.isNotEmpty) {
        final vr = sheets.ValueRange()..values = rows;
        await sheetsApi.spreadsheets.values.append(
          vr,
          spreadsheetId,
          'Sheet1!A:G',
          valueInputOption: 'USER_ENTERED',
        );
      }

      return 'https://docs.google.com/spreadsheets/d/$spreadsheetId';
    } catch (e) {
      print('Sheets Export failed: $e');
      return null;
    }
  }
}
