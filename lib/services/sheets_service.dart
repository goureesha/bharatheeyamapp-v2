import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'google_auth_service.dart';
import 'storage_service.dart';

class SheetsService {
  static const _prefKey = 'bharatheeyam_sheet_id';

  /// Sync a profile to the user's "Bharatheeyam Clients" spreadsheet.
  /// Creates the sheet on first use.
  static Future<bool> syncProfile(Profile profile) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return false;

      final api = sheets.SheetsApi(client);
      final sheetId = await _getOrCreateSheet(api);
      if (sheetId == null) return false;

      // Build row data
      final row = [
        profile.name,
        profile.date,
        '${profile.hour}:${profile.minute.toString().padLeft(2, '0')} ${profile.ampm}',
        profile.place,
        profile.lat.toString(),
        profile.lon.toString(),
        profile.notes.length > 200
            ? '${profile.notes.substring(0, 200)}...'
            : profile.notes,
        DateTime.now().toIso8601String(),
      ];

      // Check if row for this name already exists
      final existing = await api.spreadsheets.values.get(sheetId, 'A:A');
      int? existingRow;
      if (existing.values != null) {
        for (int i = 0; i < existing.values!.length; i++) {
          if (existing.values![i].isNotEmpty &&
              existing.values![i][0] == profile.name) {
            existingRow = i + 1; // 1-indexed
            break;
          }
        }
      }

      if (existingRow != null) {
        // Update
        await api.spreadsheets.values.update(
          sheets.ValueRange(values: [row]),
          sheetId,
          'A$existingRow:H$existingRow',
          valueInputOption: 'RAW',
        );
      } else {
        // Append
        await api.spreadsheets.values.append(
          sheets.ValueRange(values: [row]),
          sheetId,
          'A:H',
          valueInputOption: 'RAW',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Sheets sync error: $e');
      return false;
    }
  }

  static Future<String?> _getOrCreateSheet(sheets.SheetsApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefKey);
    if (existing != null) {
      // Verify it still exists
      try {
        await api.spreadsheets.get(existing);
        return existing;
      } catch (_) {
        // Deleted — recreate
      }
    }

    // Create new spreadsheet
    try {
      final created = await api.spreadsheets.create(
        sheets.Spreadsheet(
          properties: sheets.SpreadsheetProperties(
            title: 'ಭಾರತೀಯಮ್ - ಜಾತಕ ದತ್ತಾಂಶ',
          ),
          sheets: [
            sheets.Sheet(
              properties: sheets.SheetProperties(title: 'Clients'),
            ),
          ],
        ),
      );

      final id = created.spreadsheetId!;
      await prefs.setString(_prefKey, id);

      // Add header row
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [
          ['ಹೆಸರು', 'ದಿನಾಂಕ', 'ಸಮಯ', 'ಸ್ಥಳ', 'ಅಕ್ಷಾಂಶ', 'ರೇಖಾಂಶ', 'ಟಿಪ್ಪಣಿ', 'ಕೊನೆಯ ನವೀಕರಣ'],
        ]),
        id,
        'A1:H1',
        valueInputOption: 'RAW',
      );

      return id;
    } catch (e) {
      debugPrint('Sheet creation error: $e');
      return null;
    }
  }
}
