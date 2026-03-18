import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'google_auth_service.dart';

/// Manages one-Gmail-one-device binding.
/// Stores {email → deviceId} in a dedicated Google Sheet.
class DeviceBindingService {
  static const _deviceIdKey = 'bharatheeyam_device_id';
  static const _bindingSheetKey = 'bharatheeyam_binding_sheet_id';
  static const _tabName = 'DeviceBindings';

  static String? _deviceId;
  static bool _isDeviceBound = true;

  static bool get isDeviceBound => _isDeviceBound;
  static String? get deviceId => _deviceId;

  /// Get or generate a unique device ID (persisted locally)
  static Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
      debugPrint('DeviceBinding: new deviceId=$_deviceId');
    }
    return _deviceId!;
  }

  /// Check if current device is bound to the signed-in email.
  /// Returns true if bound (or no binding exists yet → auto-registers).
  static Future<bool> checkBinding() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) { _isDeviceBound = true; return true; }

    try {
      final devId = await getDeviceId();
      final api = await _getApi();
      if (api == null) { _isDeviceBound = true; return true; }
      final sid = await _getOrCreateSheet(api);
      if (sid == null) { _isDeviceBound = true; return true; }

      // Read column A (emails) and B (deviceIds)
      final resp = await api.spreadsheets.values.get(sid, '$_tabName!A:C');
      final rows = resp.values ?? [];

      String? storedId;
      for (final row in rows) {
        if (row.isNotEmpty && row[0].toString().toLowerCase() == email.toLowerCase()) {
          storedId = row.length > 1 ? row[1].toString() : null;
          break;
        }
      }

      if (storedId == null || storedId.isEmpty) {
        // No binding → register this device
        await _register(api, sid, email, devId);
        _isDeviceBound = true;
        return true;
      }

      _isDeviceBound = (storedId == devId);
      debugPrint('DeviceBinding: check email=$email stored=$storedId current=$devId bound=$_isDeviceBound');
      return _isDeviceBound;
    } catch (e) {
      debugPrint('DeviceBinding check error: $e');
      _isDeviceBound = true; // fail-open
      return true;
    }
  }

  /// Migrate: bind current device to the signed-in email (overwrite old device)
  static Future<bool> migrateDevice() async {
    final email = GoogleAuthService.userEmail;
    if (email == null) return false;

    try {
      final devId = await getDeviceId();
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getOrCreateSheet(api);
      if (sid == null) return false;

      final resp = await api.spreadsheets.values.get(sid, '$_tabName!A:C');
      final rows = resp.values ?? [];

      int? rowIdx;
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].isNotEmpty && rows[i][0].toString().toLowerCase() == email.toLowerCase()) {
          rowIdx = i + 1; // 1-indexed
          break;
        }
      }

      final rowData = [email, devId, DateTime.now().toIso8601String()];

      if (rowIdx != null) {
        await api.spreadsheets.values.update(
          sheets.ValueRange(values: [rowData]),
          sid, '$_tabName!A$rowIdx:C$rowIdx',
          valueInputOption: 'RAW',
        );
      } else {
        await _register(api, sid, email, devId);
      }

      _isDeviceBound = true;
      debugPrint('DeviceBinding: migrated $email → $devId');
      return true;
    } catch (e) {
      debugPrint('DeviceBinding migrate error: $e');
      return false;
    }
  }

  // ─── helpers ────────────────────────────────────────────

  static Future<sheets.SheetsApi?> _getApi() async {
    final client = await GoogleAuthService.getAuthClient();
    if (client == null) return null;
    return sheets.SheetsApi(client);
  }

  static Future<void> _register(sheets.SheetsApi api, String sid, String email, String devId) async {
    await api.spreadsheets.values.append(
      sheets.ValueRange(values: [[email, devId, DateTime.now().toIso8601String()]]),
      sid, '$_tabName!A:C',
      valueInputOption: 'RAW',
      insertDataOption: 'INSERT_ROWS',
    );
    debugPrint('DeviceBinding: registered $email → $devId');
  }

  static Future<String?> _getOrCreateSheet(sheets.SheetsApi api) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_bindingSheetKey);
    if (existing != null) {
      try {
        await api.spreadsheets.get(existing);
        return existing;
      } catch (_) {}
    }

    try {
      final created = await api.spreadsheets.create(sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: 'ಭಾರತೀಯಮ್ - Device Bindings'),
        sheets: [sheets.Sheet(properties: sheets.SheetProperties(title: _tabName))],
      ));
      final id = created.spreadsheetId!;
      await prefs.setString(_bindingSheetKey, id);
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: [['Email', 'DeviceId', 'LastUpdated']]),
        id, '$_tabName!A1:C1',
        valueInputOption: 'RAW',
      );
      return id;
    } catch (e) {
      debugPrint('DeviceBinding: sheet creation error: $e');
      return null;
    }
  }
}
