import 'dart:convert';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'google_auth_service.dart';
import 'storage_service.dart';

class SheetsService {
  static const _sheetIdKey = 'bharatheeyam_sheet_id';
  static const _rowMapKey  = 'bharatheeyam_sheet_rows'; // {name->rowNum}

  static const _headers = [
    'ಹೆಸರು', 'ದಿನಾಂಕ', 'ಸಮಯ', 'ಸ್ಥಳ', 'ಅಕ್ಷಾಂಶ', 'ರೇಖಾಂಶ',
    'ಆರೂಢ', 'ಟಿಪ್ಪಣಿ', 'ಕೊನೆಯ ನವೀಕರಣ',
  ];

  /// Sync a profile to "ಭಾರತೀಯಮ್ - ಜಾತಕ ದತ್ತಾಂಶ" spreadsheet.
  ///
  /// [isNew] = true  → first-time save, append a new row
  /// [isNew] = false → update profile is already saved, update in-place
  static Future<bool> syncProfile(Profile profile, {bool isNew = false}) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return false;

      final api = sheets.SheetsApi(client);
      final sheetId = await _getOrCreateSheet(api);
      if (sheetId == null) return false;

      final row = _buildRow(profile);

      if (isNew) {
        // Append a brand-new row
        final result = await api.spreadsheets.values.append(
          sheets.ValueRange(values: [row]),
          sheetId,
          'A:I',
          valueInputOption: 'RAW',
          insertDataOption: 'INSERT_ROWS',
        );
        // Remember which row was used so future updates are in-place
        final range = result.updates?.updatedRange ?? '';
        final rowNum = _rowFromRange(range);
        if (rowNum != null) await _saveRow(profile.name, rowNum);
        debugPrint('Sheets: appended row $rowNum for ${profile.name}');
      } else {
        // Try stored row first
        final storedRow = await _loadRow(profile.name);
        if (storedRow != null) {
          await api.spreadsheets.values.update(
            sheets.ValueRange(values: [row]),
            sheetId,
            'A$storedRow:I$storedRow',
            valueInputOption: 'RAW',
          );
          debugPrint('Sheets: updated stored row $storedRow for ${profile.name}');
        } else {
          // Scan column A to locate the row
          final scan = await api.spreadsheets.values.get(sheetId, 'A:A');
          int? foundRow;
          if (scan.values != null) {
            for (int i = 0; i < scan.values!.length; i++) {
              if (scan.values![i].isNotEmpty &&
                  scan.values![i][0].toString() == profile.name) {
                foundRow = i + 1;
                break;
              }
            }
          }
          if (foundRow != null) {
            await api.spreadsheets.values.update(
              sheets.ValueRange(values: [row]),
              sheetId,
              'A$foundRow:I$foundRow',
              valueInputOption: 'RAW',
            );
            await _saveRow(profile.name, foundRow);
          } else {
            // Not in sheet yet — append once
            final result = await api.spreadsheets.values.append(
              sheets.ValueRange(values: [row]),
              sheetId,
              'A:I',
              valueInputOption: 'RAW',
              insertDataOption: 'INSERT_ROWS',
            );
            final rowNum = _rowFromRange(result.updates?.updatedRange ?? '');
            if (rowNum != null) await _saveRow(profile.name, rowNum);
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('Sheets sync error: $e');
      return false;
    }
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  static List<Object?> _buildRow(Profile profile) {
    final aroodha = profile.aroodhas.entries
        .where((e) => e.value != 0)
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final notes = profile.notes.length > 200
        ? '${profile.notes.substring(0, 200)}...'
        : profile.notes;
    return [
      profile.name,
      profile.date,
      '${profile.hour}:${profile.minute.toString().padLeft(2, '0')} ${profile.ampm}',
      profile.place,
      profile.lat.toStringAsFixed(4),
      profile.lon.toStringAsFixed(4),
      aroodha,
      notes,
      DateTime.now().toIso8601String(),
    ];
  }

  static int? _rowFromRange(String range) {
    // Range: "Clients!A5:I5" → 5
    final m = RegExp(r'[A-Z](\d+):').firstMatch(range);
    return m != null ? int.tryParse(m.group(1)!) : null;
  }

  static Future<void> _saveRow(String name, int row) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rowMapKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[name] = row;
    await prefs.setString(_rowMapKey, jsonEncode(map));
  }

  static Future<int?> _loadRow(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rowMapKey) ?? '{}';
    final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final v = map[name];
    return v is int ? v : (v is num ? v.toInt() : null);
  }

  static Future<String?> _getOrCreateSheet(sheets.SheetsApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_sheetIdKey);
    if (existing != null) {
      try {
        await api.spreadsheets.get(existing);
        return existing;
      } catch (_) {}
    }

    try {
      final created = await api.spreadsheets.create(sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: 'ಭಾರತೀಯಮ್ - ಜಾತಕ ದತ್ತಾಂಶ'),
        sheets: [sheets.Sheet(properties: sheets.SheetProperties(title: 'Clients'))],
      ));
      final id = created.spreadsheetId!;
      await prefs.setString(_sheetIdKey, id);
      // Header row
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [_headers]),
        id, 'A1:I1',
        valueInputOption: 'RAW',
      );
      return id;
    } catch (e) {
      debugPrint('Sheet creation error: $e');
      return null;
    }
  }
}
