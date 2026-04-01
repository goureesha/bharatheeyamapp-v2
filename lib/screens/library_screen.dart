import 'package:flutter/material.dart';
import '../services/library_service.dart';
import '../models/library_models.dart';
import '../widgets/common.dart';
import 'shloka_reader.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Book> _books = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _books = LibraryService.books;
  }

  Set<String> get _categories {
    final cats = {'All'};
    for (var b in _books) {
      if (b.category.isNotEmpty) cats.add(b.category);
    }
    return cats;
  }

  List<Book> get _filteredBooks {
    if (_selectedCategory == 'All') return _books;
    return _books.where((b) => b.category == _selectedCategory).toList();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
      return;
    }

    // A very simple search: look through shloka tags and translations
    final lq = query.toLowerCase();
    final results = <Map<String, dynamic>>[];
    
    // First check exact tag match (using the service method)
    results.addAll(LibraryService.searchShlokasByTag(lq));

    // Then rudimentary text search on translation for demo purposes
    if (results.isEmpty) {
      for (var b in _books) {
        for (var c in b.chapters) {
          for (var s in c.shlokas) {
            if (s.translation.toLowerCase().contains(lq) || 
                s.sanskrit.toLowerCase().contains(lq)) {
              if (!results.any((r) => r['shloka'].id == s.id)) {
                 results.add({'book': b, 'chapter': c, 'shloka': s});
              }
            }
          }
        }
      }
    }

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ಗ್ರಂಥಾಲಯ (Granthaalaya)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search tag (e.g., mangala) or translation...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () { 
                        _searchCtrl.clear(); 
                        _onSearch(''); 
                      }
                    ) 
                  : null,
              ),
            ),
          ),
          
          if (!_isSearching) // Only show category filters if not actively searching
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat, style: TextStyle(
                        color: isSelected ? Colors.white : kText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      )),
                      selected: isSelected,
                      selectedColor: kOrange,
                      backgroundColor: kBg,
                      side: BorderSide(color: isSelected ? kOrange : kBorder),
                      onSelected: (val) {
                        setState(() { _selectedCategory = cat; });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            
          Expanded(
            child: _isSearching 
              ? _buildSearchResults() 
              : _buildBooksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList() {
    final currentBooks = _filteredBooks;
    
    if (currentBooks.isEmpty) {
      return const Center(child: Text('ಗ್ರಂಥಾಲಯ ಖಾಲಿಯಾಗಿದೆ (Library is empty)'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: currentBooks.length,
      itemBuilder: (context, i) {
        final book = currentBooks[i];
        return AppCard(
          child: ListTile(
            leading: Icon(Icons.menu_book, color: kPurple2, size: 32),
            title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('ಲೇಖಕರು: ${book.author}\nಅಧ್ಯಾಯಗಳು: ${book.chapters.length}'),
            isThreeLine: true,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => BookDetailScreen(book: book),
              ));
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('ಫಲಿತಾಂಶಗಳು ಸಿಗಲಿಲ್ಲ (No results found)'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final r = _searchResults[i];
        final book = r['book'] as Book;
        final chapter = r['chapter'] as Chapter;
        final shloka = r['shloka'] as Shloka;

        return AppCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(shloka.sanskrit.split('\n').first, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shloka.translation, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${book.title} - ${chapter.title}', style: TextStyle(color: kMuted, fontSize: 12)),
                  if (shloka.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: shloka.tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    )
                  ]
                ],
              ),
            ),
            onTap: () {
              // Navigate to the reading view for this chapter, pre-scrolled to the shloka ideally
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ShlokaReaderScreen(
                  bookTitle: book.title, 
                  chapter: chapter, 
                  highlightShlokaId: shloka.id
                ),
              ));
            },
          ),
        );
      },
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: book.chapters.length,
        itemBuilder: (context, i) {
          final chapter = book.chapters[i];
          return AppCard(
            child: ListTile(
              title: Text(chapter.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ಶ್ಲೋಕಗಳು: ${chapter.shlokas.length}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ShlokaReaderScreen(
                    bookTitle: book.title, 
                    chapter: chapter
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}
