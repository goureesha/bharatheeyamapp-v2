import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
    'clientId': clientId, 'name': name, 'phone': phone,
    'email': email, 'address': address, 'createdAt': createdAt,
  };

  factory Client.fromJson(Map<String, dynamic> j) => Client(
    clientId: j['clientId'] ?? '', name: j['name'] ?? '',
    phone: j['phone'] ?? '', email: j['email'] ?? '',
    address: j['address'] ?? '', createdAt: j['createdAt'] ?? '',
  );
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

  Map<String, dynamic> toJson() => {
    'clientId': clientId, 'memberName': memberName, 'relation': relation,
    'dob': dob, 'birthTime': birthTime, 'birthPlace': birthPlace,
    'lat': lat, 'lon': lon, 'notes': notes,
  };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
    clientId: j['clientId'] ?? '', memberName: j['memberName'] ?? '',
    relation: j['relation'] ?? '', dob: j['dob'] ?? '',
    birthTime: j['birthTime'] ?? '', birthPlace: j['birthPlace'] ?? '',
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lon: (j['lon'] as num?)?.toDouble() ?? 0,
    notes: j['notes'] ?? '',
  );

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

// ─── Service (Local JSON Storage) ─────────────────────────

class ClientService {
  static const _clientsCacheKey = 'bharatheeyam_clients_cache';
  static const _membersCacheKey = 'bharatheeyam_members_cache';
  static const _nextIdKey = 'bharatheeyam_next_client_id';

  // In-memory cache
  static List<Client> _clients = [];
  static List<FamilyMember> _members = [];
  static bool _isLoaded = false;

  static List<Client> get clients => _clients;
  static List<FamilyMember> get members => _members;
  static bool get isLoaded => _isLoaded;

  // ─── Persistence ────────────────────────────────────────

  static Future<void> _saveToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientsJson = jsonEncode(_clients.map((c) => c.toJson()).toList());
      final membersJson = jsonEncode(_members.map((m) => m.toJson()).toList());
      await prefs.setString(_clientsCacheKey, clientsJson);
      await prefs.setString(_membersCacheKey, membersJson);
    } catch (e) {
      debugPrint('ClientService: save error: $e');
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

  /// Exposed explicitly for isolated Kundali Profile creation
  static Future<String> generateNextClientId() async {
    return await _generateClientId();
  }

  /// Manually add a completely formed Client record
  static Future<bool> addClient(Client client) async {
    try {
      _clients.add(client);
      await _saveToLocal();
      debugPrint('ClientService: forcefully added client ${client.clientId} for ${client.name}');
      return true;
    } catch (e) {
      debugPrint('ClientService: add client error: $e');
      return false;
    }
  }

  // ─── Load All ─────────────────────────────────────────────

  static Future<void> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load clients from local cache
      final clientsStr = prefs.getString(_clientsCacheKey);
      if (clientsStr != null && clientsStr.isNotEmpty) {
        final list = jsonDecode(clientsStr) as List;
        _clients = list.map((j) => Client.fromJson(j as Map<String, dynamic>)).toList();
      }

      // Load members from local cache
      final membersStr = prefs.getString(_membersCacheKey);
      if (membersStr != null && membersStr.isNotEmpty) {
        final list = jsonDecode(membersStr) as List;
        _members = list.map((j) => FamilyMember.fromJson(j as Map<String, dynamic>)).toList();
      }

      _isLoaded = true;
      debugPrint('ClientService: loaded ${_clients.length} clients, ${_members.length} members (local)');
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

    try {
      final clientId = await _generateClientId();
      final now = DateTime.now().toIso8601String().substring(0, 10);
      final client = Client(
        clientId: clientId,
        name: name,
        phone: phone,
        email: email,
        createdAt: now,
      );

      _clients.add(client);
      await _saveToLocal();
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
      _clients = _clients.map((c) => c.clientId == client.clientId ? client : c).toList();
      await _saveToLocal();
      return true;
    } catch (e) {
      debugPrint('ClientService: update client error: $e');
      return false;
    }
  }

  /// Delete client
  static Future<bool> deleteClient(String clientId) async {
    try {
      _clients.removeWhere((c) => c.clientId == clientId);
      _members.removeWhere((m) => m.clientId == clientId);
      await _saveToLocal();
      return true;
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
      _members.add(member);
      await _saveToLocal();
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
      final idx = _members.indexWhere((m) =>
        m.clientId == member.clientId && m.memberName == member.memberName);
      if (idx >= 0) {
        _members[idx] = member;
      } else {
        _members.add(member);
      }
      await _saveToLocal();
      return true;
    } catch (e) {
      debugPrint('ClientService: update member error: $e');
      return false;
    }
  }

  /// Get appointment count for a client (needs appointments from AppointmentService)
  static int getVisitCount(String clientId, List<dynamic> appointments) {
    return appointments.where((a) {
      final client = getClientById(clientId);
      if (client == null) return false;
      // Match by clientId first
      if (a.clientId.isNotEmpty && a.clientId == clientId) return true;
      // Match by phone only if both have phone numbers
      final clientPhone = client.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final apptPhone = a.clientPhone.replaceAll(RegExp(r'[^0-9]'), '');
      return clientPhone.isNotEmpty && apptPhone.isNotEmpty && clientPhone == apptPhone;
    }).length;
  }

  /// Clear cache
  static void clearCache() {
    _clients.clear();
    _members.clear();
    _isLoaded = false;
  }
}
