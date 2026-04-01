class Book {
  final String id;
  final String title;
  final String author;
  final String category;
  final List<Chapter> chapters;

  Book({required this.id, required this.title, required this.author, required this.category, required this.chapters});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      category: (json['category'] as String?) ?? 'Other',
      chapters: (json['chapters'] as List)
          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Chapter {
  final String id;
  final String title;
  final List<Shloka> shlokas;

  Chapter({required this.id, required this.title, required this.shlokas});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      shlokas: (json['shlokas'] as List)
          .map((s) => Shloka.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Shloka {
  final String id;
  final String sanskrit;
  final String? kannada;
  final String translation;
  final List<String> tags;

  Shloka({
    required this.id,
    required this.sanskrit,
    this.kannada,
    required this.translation,
    required this.tags,
  });

  factory Shloka.fromJson(Map<String, dynamic> json) {
    return Shloka(
      id: json['id'] as String,
      sanskrit: json['sanskrit'] as String,
      kannada: json['kannada'] as String?,
      translation: json['translation'] as String,
      tags: (json['tags'] as List).map((t) => t.toString()).toList(),
    );
  }
}

class AmaraKoshaEntry {
  final String word;
  final String meaning;
  final List<String> synonyms;

  AmaraKoshaEntry({
    required this.word,
    required this.meaning,
    required this.synonyms,
  });

  factory AmaraKoshaEntry.fromJson(Map<String, dynamic> json) {
    return AmaraKoshaEntry(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      synonyms: (json['synonyms'] as List).map((s) => s.toString()).toList(),
    );
  }
}
