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
      _books = booksList.map((b) => Book.fromJson(b as Map<String, dynamic>)).toList();

      // Load Amara Kosha
      final amaraString = await rootBundle.loadString('assets/data/amara_kosha.json');
      final amaraJson = json.decode(amaraString);
      final wordsList = amaraJson['words'] as List;
      
      for (var w in wordsList) {
        final entry = AmaraKoshaEntry.fromJson(w as Map<String, dynamic>);
        _amaraKosha[entry.word] = entry;
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing LibraryService: $e');
    }
  }

  /// Search Amara Kosha intelligently
  static AmaraKoshaEntry? lookupWord(String word) {
    // 1. Clean the word of all punctuation and isolate characters
    final cleanWord = word.replaceAll(RegExp(r'[।॥,\.\-\?\!\s]'), '');
    if (cleanWord.isEmpty) return null;

    // 2. Exact Match (Best case)
    if (_amaraKosha.containsKey(cleanWord)) {
      return _amaraKosha[cleanWord];
    }

    // 3. Known Vibhakti / Suffix Stripping
    // Sanskrit words often end in these inflectional suffixes in Shlokas.
    // By aggressively stripping them, we test if the root maps exactly to a dictionary entry.
    final suffixes = [
      'म्', 'ः', 'े', 'ौ', 'ा', 'ी', 'ू', 'स्य', 'तः', 'ये', 'या', 'वान्',
      'ेपु', 'ाणाम्', 'ाः', 'ान्', 'ौ', 'म्', 'न्', 'त्'
    ];

    for (var suffix in suffixes) {
      if (cleanWord.endsWith(suffix)) {
        final stripped = cleanWord.substring(0, cleanWord.length - suffix.length);
        if (stripped.isNotEmpty && _amaraKosha.containsKey(stripped)) {
          return _amaraKosha[stripped];
        }
      }
    }

    // 4. Aggressive prefix partial match (e.g. "नमस्तुभ्यं" -> "नमः" or "सरस्वति" -> "सरस्वती")
    for (var key in _amaraKosha.keys) {
      // If the entry root is at least 3 characters and is present at the START of the cleanWord
      if (key.length >= 3 && cleanWord.startsWith(key)) {
         return _amaraKosha[key];
      }
      // Conversely, if the cleanWord (at least 3 chars) is the START of the dictionary root
      if (cleanWord.length >= 3 && key.startsWith(cleanWord)) {
         return _amaraKosha[key];
      }
    }

    // Nothing found
    return null;
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
