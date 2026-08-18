import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single item inside a pooja list.
class PoojaItem {
  String name;
  String quantity;
  bool checked;

  PoojaItem({required this.name, this.quantity = '', this.checked = false});

  Map<String, dynamic> toJson() => {
    'n': name,
    'q': quantity,
    'c': checked,
  };

  factory PoojaItem.fromJson(Map<String, dynamic> j) => PoojaItem(
    name: j['n'] ?? '',
    quantity: j['q'] ?? '',
    checked: j['c'] ?? false,
  );
}

/// A named pooja list containing multiple items.
class PoojaList {
  String id;
  String name;
  String purohitName;
  String purohitPhone;
  String purohitAddress;
  List<PoojaItem> items;
  DateTime createdAt;

  PoojaList({
    required this.id,
    required this.name,
    this.purohitName = '',
    this.purohitPhone = '',
    this.purohitAddress = '',
    List<PoojaItem>? items,
    DateTime? createdAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    'pn': purohitName,
    'pp': purohitPhone,
    'pa': purohitAddress,
    'items': items.map((i) => i.toJson()).toList(),
    'ts': createdAt.millisecondsSinceEpoch,
  };

  factory PoojaList.fromJson(Map<String, dynamic> j) => PoojaList(
    id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: j['n'] ?? '',
    purohitName: j['pn'] ?? '',
    purohitPhone: j['pp'] ?? '',
    purohitAddress: j['pa'] ?? '',
    items: (j['items'] as List?)?.map((i) => PoojaItem.fromJson(i as Map<String, dynamic>)).toList() ?? [],
    createdAt: j['ts'] != null ? DateTime.fromMillisecondsSinceEpoch(j['ts']) : DateTime.now(),
  );

  int get checkedCount => items.where((i) => i.checked).length;
}

/// Persists pooja lists to SharedPreferences.
class PoojaListService {
  static const String _key = 'bharatheeyam_pooja_lists_v1';

  static Future<List<PoojaList>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((j) => PoojaList.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('PoojaListService: load error: $e');
      return [];
    }
  }

  static Future<void> saveAll(List<PoojaList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(lists.map((l) => l.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  static Future<void> addList(PoojaList list) async {
    final lists = await loadAll();
    lists.insert(0, list);
    await saveAll(lists);
  }

  static Future<void> updateList(PoojaList updated) async {
    final lists = await loadAll();
    final idx = lists.indexWhere((l) => l.id == updated.id);
    if (idx >= 0) {
      lists[idx] = updated;
    } else {
      lists.insert(0, updated);
    }
    await saveAll(lists);
  }

  static Future<void> deleteList(String id) async {
    final lists = await loadAll();
    lists.removeWhere((l) => l.id == id);
    await saveAll(lists);
  }
}
