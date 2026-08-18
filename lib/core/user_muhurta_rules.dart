import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'muhurta_rules.dart';

/// ──────────────────────────────────────────────────────────────
/// User-editable muhurta rules overlay
/// Sits on top of default MuhurtaEventRules, user can toggle each filter
/// ──────────────────────────────────────────────────────────────
class UserMuhurtaRules {
  // Panchanga filters
  List<int>? allowedTithis;        // null = use default
  List<int>? allowedNakshatras;    // null = use default
  List<int>? allowedVaras;         // null = use default
  List<int>? blockedYogas;         // null = use default blockedYogaIndices
  bool avoidVishti;
  bool requireShukla;
  bool requireUttarayana;
  bool blockDagdhaYoga;            // true = block dagdha yoga days
  bool considerAbhijit;            // true = always compute abhijit muhurta

  // Lagna filters
  List<int>? allowedLagnas;        // null = use default
  Set<ShuddhiType> requiredShuddhis;

  // Time filter
  bool fullDayScan;  // true = sunrise to sunset, false = sunrise to ~1PM

  // Bala filters
  bool requireTaraBala;
  List<int> allowedTaras; // which of the 9 taras (0-8) are considered good
  bool requireGuruBala;
  bool requireGuruAnukoolaForLagna;
  bool blockGuruAsta;               // true = block days when Jupiter is combust
  bool blockShukraAsta;             // true = block days when Venus is combust
  bool useBhavaShuddhi;             // true = use Bhava cusp fallback when Rashi shuddhi fails

  UserMuhurtaRules({
    this.allowedTithis,
    this.allowedNakshatras,
    this.allowedVaras,
    this.blockedYogas,
    this.avoidVishti = true,
    this.requireShukla = false,
    this.requireUttarayana = false,
    this.blockDagdhaYoga = false,
    this.considerAbhijit = true,
    this.allowedLagnas,
    this.requiredShuddhis = const {ShuddhiType.lagna},
    this.fullDayScan = false,
    this.requireTaraBala = true,
    this.allowedTaras = const [1, 3, 5, 7, 8],
    this.requireGuruBala = true,
    this.requireGuruAnukoolaForLagna = true,
    this.blockGuruAsta = false,
    this.blockShukraAsta = false,
    this.useBhavaShuddhi = false,
  });

  /// Create from default MuhurtaEventRules for a given event
  factory UserMuhurtaRules.fromDefaults(MuhurtaEvent event) {
    final defaults = muhurtaRules[event];
    if (defaults == null) return UserMuhurtaRules();
    return UserMuhurtaRules(
      allowedTithis: defaults.allowedTithis != null ? List<int>.from(defaults.allowedTithis!) : null,
      allowedNakshatras: defaults.allowedNakshatras != null ? List<int>.from(defaults.allowedNakshatras!) : null,
      allowedVaras: defaults.allowedVaras != null ? List<int>.from(defaults.allowedVaras!) : null,
      blockedYogas: List<int>.from(blockedYogaIndices),
      avoidVishti: defaults.avoidVishti,
      requireShukla: defaults.requireShukla,
      requireUttarayana: defaults.requireUttarayana,
      blockDagdhaYoga: false,
      considerAbhijit: true,
      allowedLagnas: defaults.allowedLagnas != null ? List<int>.from(defaults.allowedLagnas!) : null,
      requiredShuddhis: Set<ShuddhiType>.from(defaults.requiredShuddhis),
      fullDayScan: event == MuhurtaEvent.grihaPrevesha,
      requireTaraBala: true,
      allowedTaras: const [1, 3, 5, 7, 8],
      requireGuruBala: true,
      requireGuruAnukoolaForLagna: true,
      blockGuruAsta: false,
      blockShukraAsta: false,
      useBhavaShuddhi: false,
    );
  }

  /// Serialize to JSON map
  Map<String, dynamic> toJson() => {
    'tithis': allowedTithis,
    'naks': allowedNakshatras,
    'varas': allowedVaras,
    'blockedYogas': blockedYogas,
    'avoidVishti': avoidVishti,
    'reqShukla': requireShukla,
    'reqUttarayana': requireUttarayana,
    'blockDagdha': blockDagdhaYoga,
    'abhijit': considerAbhijit,
    'lagnas': allowedLagnas,
    'shuddhis': requiredShuddhis.map((s) => s.index).toList(),
    'fullDay': fullDayScan,
    'reqTara': requireTaraBala,
    'allowedTaras': allowedTaras,
    'reqGuru': requireGuruBala,
    'reqGuruLagna': requireGuruAnukoolaForLagna,
    'blockGuruAsta': blockGuruAsta,
    'blockShukraAsta': blockShukraAsta,
    'bhavaShuddhi': useBhavaShuddhi,
  };

  /// Deserialize from JSON map
  factory UserMuhurtaRules.fromJson(Map<String, dynamic> json) {
    return UserMuhurtaRules(
      allowedTithis: json['tithis'] != null ? List<int>.from(json['tithis']) : null,
      allowedNakshatras: json['naks'] != null ? List<int>.from(json['naks']) : null,
      allowedVaras: json['varas'] != null ? List<int>.from(json['varas']) : null,
      blockedYogas: json['blockedYogas'] != null ? List<int>.from(json['blockedYogas']) : null,
      avoidVishti: json['avoidVishti'] ?? true,
      requireShukla: json['reqShukla'] ?? false,
      requireUttarayana: json['reqUttarayana'] ?? false,
      blockDagdhaYoga: json['blockDagdha'] ?? false,
      considerAbhijit: json['abhijit'] ?? true,
      allowedLagnas: json['lagnas'] != null ? List<int>.from(json['lagnas']) : null,
      requiredShuddhis: json['shuddhis'] != null
          ? (json['shuddhis'] as List).map((i) => ShuddhiType.values[i as int]).toSet()
          : const {ShuddhiType.lagna},
      fullDayScan: json['fullDay'] ?? false,
      requireTaraBala: json['reqTara'] ?? true,
      allowedTaras: json['allowedTaras'] != null ? List<int>.from(json['allowedTaras']) : const [1, 3, 5, 7, 8],
      requireGuruBala: json['reqGuru'] ?? true,
      requireGuruAnukoolaForLagna: json['reqGuruLagna'] ?? true,
      blockGuruAsta: json['blockGuruAsta'] ?? false,
      blockShukraAsta: json['blockShukraAsta'] ?? false,
      useBhavaShuddhi: json['bhavaShuddhi'] ?? false,
    );
  }

  /// Deep copy
  UserMuhurtaRules copy() => UserMuhurtaRules.fromJson(toJson());
}

/// ──────────────────────────────────────────────────────────────
/// Persistence manager for user rules (per event type)
/// ──────────────────────────────────────────────────────────────
class UserRulesManager {
  UserRulesManager._();
  static final instance = UserRulesManager._();

  final Map<MuhurtaEvent, UserMuhurtaRules> _rules = {};

  /// Get rules for an event (loads from defaults if not yet customized)
  UserMuhurtaRules getRules(MuhurtaEvent event) {
    return _rules[event] ?? UserMuhurtaRules.fromDefaults(event);
  }

  /// Save rules for an event
  Future<void> saveRules(MuhurtaEvent event, UserMuhurtaRules rules) async {
    _rules[event] = rules;
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_muhurta_rules_${event.name}';
    await prefs.setString(key, jsonEncode(rules.toJson()));
  }

  /// Reset rules for an event to defaults
  Future<void> resetToDefaults(MuhurtaEvent event) async {
    _rules[event] = UserMuhurtaRules.fromDefaults(event);
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_muhurta_rules_${event.name}';
    await prefs.remove(key);
  }

  /// Load all saved rules from storage
  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final event in MuhurtaEvent.values) {
      final key = 'user_muhurta_rules_${event.name}';
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          _rules[event] = UserMuhurtaRules.fromJson(jsonDecode(raw));
        } catch (_) {}
      }
    }
  }

  /// Export all rules as JSON string (for backup)
  String exportAll() {
    final map = <String, dynamic>{};
    for (final entry in _rules.entries) {
      map[entry.key.name] = entry.value.toJson();
    }
    return jsonEncode(map);
  }

  /// Import rules from backup JSON string
  Future<void> importAll(String jsonStr) async {
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      for (final entry in map.entries) {
        final event = MuhurtaEvent.values.firstWhere(
          (e) => e.name == entry.key,
          orElse: () => MuhurtaEvent.vivaha,
        );
        final rules = UserMuhurtaRules.fromJson(entry.value);
        await saveRules(event, rules);
      }
    } catch (_) {}
  }
}
