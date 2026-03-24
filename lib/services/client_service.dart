import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'google_auth_service.dart';

// ─── Data Models ──────────────────────────────────────────

class Client {
  final String clientId;    // BH-2026-0001
  final String name;
  final String phone;
  final String email;
  final String address;
  final String createdAt;

  Client({
    required this.clientId,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    required this.createdAt,
  });

  factory Client.fromRow(List<Object?> row) {
    return Client(
      clientId:  row.isNotEmpty     ? row[0].toString() : '',
      name:      row.length > 1     ? row[1].toString() : '',
      phone:     row.length > 2     ? row[2].toString() : '',
      email:     row.length > 3     ? row[3].toString() : '',
      address:   row.length > 4     ? row[4].toString() : '',
      createdAt: row.length > 5     ? row[5].toString() : '',
    );
  }

  List<Object> toRow() => [clientId, name, phone, email, address, createdAt];
}

class FamilyMember {
  final String clientId;
  final String memberName;
  final String relation;     // Self, Wife, Son, Daughter, Father, Mother, etc.
  final String dob;          // YYYY-MM-DD
  final String birthTime;    // HH:MM AM/PM
  final String birthPlace;
  final double lat;
  final double lon;
  final String notes;

  FamilyMember({
    required this.clientId,
    required this.memberName,
    required this.relation,
    required this.dob,
    required this.birthTime,
    required this.birthPlace,
    required this.lat,
    required this.lon,
    this.notes = '',
  });

  factory FamilyMember.fromRow(List<Object?> row) {
    return FamilyMember(
      clientId:   row.isNotEmpty     ? row[0].toString() : '',
      memberName: row.length > 1     ? row[1].toString() : '',
      relation:   row.length > 2     ? row[2].toString() : '',
      dob:        row.length > 3     ? row[3].toString() : '',
      birthTime:  row.length > 4     ? row[4].toString() : '',
      birthPlace: row.length > 5     ? row[5].toString() : '',
      lat:        row.length > 6     ? double.tryParse(row[6].toString()) ?? 0 : 0,
      lon:        row.length > 7     ? double.tryParse(row[7].toString()) ?? 0 : 0,
      notes:      row.length > 8     ? row[8].toString() : '',
    );
  }

  List<Object> toRow() => [
    clientId, memberName, relation, dob, birthTime,
    birthPlace, lat.toStringAsFixed(4), lon.toStringAsFixed(4), notes,
  ];

  /// Parse DOB into DateTime
  DateTime? get dobDate {
    try {
      final parts = dob.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }

  /// Parse birth time components
  int get hour {
    try {
      final parts = birthTime.split(':');
      final h = int.parse(parts[0]);
      final isPM = birthTime.toUpperCase().contains('PM');
      if (isPM && h != 12) return h + 12;
      if (!isPM && h == 12) return 0;
      return h;
    } catch (_) {
      return 12;
    }
  }

  int get minute {
    try {
      final parts = birthTime.replaceAll(RegExp(r'[APM ]', caseSensitive: false), '').split(':');
      return parts.length > 1 ? int.parse(parts[1]) : 0;
    } catch (_) {
      return 0;
    }
  }

  String get ampm => birthTime.toUpperCase().contains('PM') ? 'PM' : 'AM';

  int get hour12 {
    final h24 = hour;
    if (h24 == 0) return 12;
    if (h24 > 12) return h24 - 12;
    return h24;
  }
}

// ─── Service ──────────────────────────────────────────────

class ClientService {
  // Reuse the same spreadsheet as AppointmentService
  static const _sheetKey = 'bharatheeyam_appt_sheet_id';
  static const _clientsTab = 'Clients';
  static const _membersTab = 'Members';
  static const _nextIdKey = 'bharatheeyam_next_client_id';

  // In-memory cache
  static List<Client> _clients = [];
  static List<FamilyMember> _members = [];
  static bool _isLoaded = false;

  static List<Client> get clients => _clients;
  static List<FamilyMember> get members => _members;
  static bool get isLoaded => _isLoaded;

  // ─── Sheet Setup ─────────────────────────────────────────

  static Future<sheets.SheetsApi?> _getApi() async {
    final client = await GoogleAuthService.getAuthClient();
    if (client == null) return null;
    return sheets.SheetsApi(client);
  }

  static Future<String?> _getSheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sheetKey);
  }

  /// Ensure Clients + Members tabs exist in the appointment spreadsheet
  static Future<bool> _ensureTabs(sheets.SheetsApi api, String sheetId) async {
    try {
      final ss = await api.spreadsheets.get(sheetId);
      final tabNames = ss.sheets?.map((s) => s.properties?.title ?? '').toList() ?? [];

      final requests = <sheets.Request>[];

      if (!tabNames.contains(_clientsTab)) {
        requests.add(sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: _clientsTab),
          ),
        ));
      }
      if (!tabNames.contains(_membersTab)) {
        requests.add(sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(title: _membersTab),
          ),
        ));
      }

      if (requests.isNotEmpty) {
        await api.spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest(requests: requests),
          sheetId,
        );

        // Write headers
        if (!tabNames.contains(_clientsTab)) {
          await api.spreadsheets.values.update(
            sheets.ValueRange(values: [['ClientId', 'Name', 'Phone', 'Email', 'Address', 'CreatedAt']]),
            sheetId, '$_clientsTab!A1:F1',
            valueInputOption: 'RAW',
          );
        }
        if (!tabNames.contains(_membersTab)) {
          await api.spreadsheets.values.update(
            sheets.ValueRange(values: [['ClientId', 'MemberName', 'Relation', 'DOB', 'BirthTime', 'BirthPlace', 'Lat', 'Lon', 'Notes']]),
            sheetId, '$_membersTab!A1:I1',
            valueInputOption: 'RAW',
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint('ClientService: ensureTabs error: $e');
      return false;
    }
  }

  // ─── Client ID Generation ─────────────────────────────────

  static Future<String> _generateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final year = DateTime.now().year;
    int nextNum = prefs.getInt(_nextIdKey) ?? 1;
    final id = 'BH-$year-${nextNum.toString().padLeft(4, '0')}';
    await prefs.setInt(_nextIdKey, nextNum + 1);
    return id;
  }

  // ─── Load All ─────────────────────────────────────────────

  static Future<void> loadAll() async {
    try {
      final api = await _getApi();
      if (api == null) return;
      final sid = await _getSheetId();
      if (sid == null) return;

      await _ensureTabs(api, sid);

      // Load clients
      try {
        final cResp = await api.spreadsheets.values.get(sid, '$_clientsTab!A:F');
        final cRows = cResp.values ?? [];
        _clients = [];
        for (int i = 1; i < cRows.length; i++) {
          if (cRows[i].isNotEmpty && cRows[i][0].toString().isNotEmpty) {
            _clients.add(Client.fromRow(cRows[i]));
          }
        }
      } catch (e) {
        debugPrint('ClientService: clients load error: $e');
      }

      // Load members
      try {
        final mResp = await api.spreadsheets.values.get(sid, '$_membersTab!A:I');
        final mRows = mResp.values ?? [];
        _members = [];
        for (int i = 1; i < mRows.length; i++) {
          if (mRows[i].isNotEmpty && mRows[i][0].toString().isNotEmpty) {
            _members.add(FamilyMember.fromRow(mRows[i]));
          }
        }
      } catch (e) {
        debugPrint('ClientService: members load error: $e');
      }

      _isLoaded = true;
      debugPrint('ClientService: loaded ${_clients.length} clients, ${_members.length} members');
    } catch (e) {
      debugPrint('ClientService: loadAll error: $e');
    }
  }

  // ─── Client CRUD ──────────────────────────────────────────

  /// Find client by phone number (for returning clients)
  static Client? getClientByPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    try {
      return _clients.firstWhere(
        (c) => c.phone.replaceAll(RegExp(r'[^0-9]'), '') == clean,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find client by clientId
  static Client? getClientById(String clientId) {
    try {
      return _clients.firstWhere((c) => c.clientId == clientId);
    } catch (_) {
      return null;
    }
  }

  /// Search clients by name, phone, or ID
  static List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;
    final q = query.toLowerCase();
    return _clients.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.phone.contains(q) ||
      c.clientId.toLowerCase().contains(q)
    ).toList();
  }

  /// Create new client or return existing one (by phone match)
  static Future<Client?> getOrCreateClient({
    required String name,
    required String phone,
    String email = '',
  }) async {
    // Check if client already exists
    final existing = getClientByPhone(phone);
    if (existing != null) return existing;

    // Create new client
    try {
      final api = await _getApi();
      if (api == null) return null;
      final sid = await _getSheetId();
      if (sid == null) return null;

      await _ensureTabs(api, sid);

      final clientId = await _generateClientId();
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final client = Client(
        clientId: clientId,
        name: name,
        phone: phone,
        email: email,
        createdAt: now,
      );

      await api.spreadsheets.values.append(
        sheets.ValueRange(values: [client.toRow()]),
        sid, '$_clientsTab!A:F',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );

      _clients.add(client);
      debugPrint('ClientService: created client $clientId for $name');
      return client;
    } catch (e) {
      debugPrint('ClientService: create client error: $e');
      return null;
    }
  }

  /// Update client info
  static Future<bool> updateClient(Client client) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getSheetId();
      if (sid == null) return false;

      // Find the row
      final scan = await api.spreadsheets.values.get(sid, '$_clientsTab!A:A');
      int? foundRow;
      if (scan.values != null) {
        for (int i = 0; i < scan.values!.length; i++) {
          if (scan.values![i].isNotEmpty && scan.values![i][0].toString() == client.clientId) {
            foundRow = i + 1;
            break;
          }
        }
      }

      if (foundRow != null) {
        await api.spreadsheets.values.update(
          sheets.ValueRange(values: [client.toRow()]),
          sid, '$_clientsTab!A$foundRow:F$foundRow',
          valueInputOption: 'RAW',
        );
        // Update cache
        _clients = _clients.map((c) => c.clientId == client.clientId ? client : c).toList();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ClientService: update client error: $e');
      return false;
    }
  }

  /// Delete client
  static Future<bool> deleteClient(String clientId) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getSheetId();
      if (sid == null) return false;

      // Find the row
      final scan = await api.spreadsheets.values.get(sid, '$_clientsTab!A:A');
      int? foundRow;
      if (scan.values != null) {
        for (int i = 0; i < scan.values!.length; i++) {
          if (scan.values![i].isNotEmpty && scan.values![i][0].toString() == clientId) {
            foundRow = i + 1;
            break;
          }
        }
      }

      if (foundRow != null) {
        // Clear the row
        await api.spreadsheets.values.clear(
          sheets.ClearValuesRequest(),
          sid, '$_clientsTab!A$foundRow:F$foundRow',
        );
        // Update cache
        _clients.removeWhere((c) => c.clientId == clientId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('ClientService: delete client error: $e');
      return false;
    }
  }

  // ─── Family Member CRUD ───────────────────────────────────

  /// Get all family members for a client
  static List<FamilyMember> getMembersForClient(String clientId) {
    return _members.where((m) => m.clientId == clientId).toList();
  }

  /// Add a family member
  static Future<bool> addFamilyMember(FamilyMember member) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getSheetId();
      if (sid == null) return false;

      await _ensureTabs(api, sid);

      await api.spreadsheets.values.append(
        sheets.ValueRange(values: [member.toRow()]),
        sid, '$_membersTab!A:I',
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );

      _members.add(member);
      debugPrint('ClientService: added member ${member.memberName} for ${member.clientId}');
      return true;
    } catch (e) {
      debugPrint('ClientService: add member error: $e');
      return false;
    }
  }

  /// Update a family member (find by clientId + memberName)
  static Future<bool> updateFamilyMember(FamilyMember member) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      final sid = await _getSheetId();
      if (sid == null) return false;

      // Find the row by scanning columns A+B (clientId + memberName)
      final scan = await api.spreadsheets.values.get(sid, '$_membersTab!A:B');
      int? foundRow;
      if (scan.values != null) {
        for (int i = 0; i < scan.values!.length; i++) {
          if (scan.values![i].length >= 2 &&
              scan.values![i][0].toString() == member.clientId &&
              scan.values![i][1].toString() == member.memberName) {
            foundRow = i + 1;
            break;
          }
        }
      }

      if (foundRow != null) {
        await api.spreadsheets.values.update(
          sheets.ValueRange(values: [member.toRow()]),
          sid, '$_membersTab!A$foundRow:I$foundRow',
          valueInputOption: 'RAW',
        );
        // Update cache
        _members = _members.map((m) =>
          (m.clientId == member.clientId && m.memberName == member.memberName) ? member : m
        ).toList();
        return true;
      } else {
        // Not found — append instead
        return addFamilyMember(member);
      }
    } catch (e) {
      debugPrint('ClientService: update member error: $e');
      return false;
    }
  }

  /// Get appointment count for a client (needs appointments from AppointmentService)
  static int getVisitCount(String clientId, List<dynamic> appointments) {
    return appointments.where((a) {
      // Check if appointment has matching clientId or phone
      final client = getClientById(clientId);
      if (client == null) return false;
      return a.clientPhone.replaceAll(RegExp(r'[^0-9]'), '') ==
             client.phone.replaceAll(RegExp(r'[^0-9]'), '');
    }).length;
  }

  /// Clear cache
  static void clearCache() {
    _clients.clear();
    _members.clear();
    _isLoaded = false;
  }
}
