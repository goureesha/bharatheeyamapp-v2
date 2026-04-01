import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/library_models.dart';

class LibraryService {
  static List<Book> _books = [];
  static Map<String, AmaraKoshaEntry> _amaraKosha = {};

  static bool _initialized = false;

  static List<Book> get books => _books;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Load Books
      final booksString = await rootBundle.loadString('assets/data/books.json');
      final booksJson = json.decode(booksString);
      final booksList = booksJson['books'] as List;
      _books = booksList.map((b) => Book.fromJson(b)).toList();

      // Load Amara Kosha
      final amaraString = await rootBundle.loadString('assets/data/amara_kosha.json');
      final amaraJson = json.decode(amaraString);
      final wordsList = amaraJson['words'] as List;
      
      for (var w in wordsList) {
        final entry = AmaraKoshaEntry.fromJson(w);
        _amaraKosha[entry.word] = entry;
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing LibraryService: $e');
    }
  }

  /// Search Amara Kosha by exact word
  static AmaraKoshaEntry? lookupWord(String word) {
    // Strip punctuation
    final cleanWord = word.replaceAll(RegExp(r'[।॥,\.]'), '').trim();
    return _amaraKosha[cleanWord];
  }

  /// Search Shlokas by Tag across all books
  static List<Map<String, dynamic>> searchShlokasByTag(String tag) {
    List<Map<String, dynamic>> results = [];
    for (var book in _books) {
      for (var chapter in book.chapters) {
        for (var shloka in chapter.shlokas) {
          if (shloka.tags.contains(tag)) {
            results.add({
              'book': book,
              'chapter': chapter,
              'shloka': shloka,
            });
          }
        }
      }
    }
    return results;
  }
}
