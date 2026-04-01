import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../models/library_models.dart';
import '../services/library_service.dart';
import '../widgets/common.dart';

class ShlokaReaderScreen extends StatefulWidget {
  final String bookTitle;
  final Chapter chapter;
  final String? highlightShlokaId;

  const ShlokaReaderScreen({
    super.key,
    required this.bookTitle,
    required this.chapter,
    this.highlightShlokaId,
  });

  @override
  State<ShlokaReaderScreen> createState() => _ShlokaReaderScreenState();
}

class _ShlokaReaderScreenState extends State<ShlokaReaderScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _shlokaKeys = {};

  @override
  void initState() {
    super.initState();
    for (var s in widget.chapter.shlokas) {
      _shlokaKeys[s.id] = GlobalKey();
    }
    
    if (widget.highlightShlokaId != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollToShloka(widget.highlightShlokaId!);
      });
    }
  }

  void _scrollToShloka(String id) {
    final key = _shlokaKeys[id];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.2, // leave some padding at the top
      );
    }
  }

  void _onWordTapped(String rawWord) {
    final entry = LibraryService.lookupWord(rawWord);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AmaraKoshaSheet(word: rawWord, entry: entry),
    );
  }

  Widget _buildInteractiveSanskrit(String text) {
    // Split by spaces but preserve newlines
    // Basically we want to extract every contiguous string of non-whitespace characters as a word
    final RegExp wordRegExp = RegExp(r'\S+|\s+');
    final matches = wordRegExp.allMatches(text);

    return Wrap(
      children: matches.map((m) {
        final token = m.group(0)!;
        if (token.trim().isEmpty) {
          // It's just whitespace/newline, preserve it visually
          if (token.contains('\n')) {
            return const SizedBox(width: double.infinity, height: 4); // Line break approximation
          }
          return Container(width: 6, height: 1); // Space approximation
        }

        // It's a readable word
        return GestureDetector(
          onLongPress: () => _onWordTapped(token),
          onTap: () => _onWordTapped(token),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            color: Colors.transparent, // to ensure tap area is filled
            child: Text(
              token, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w600,
                color: kPurple2,
                height: 1.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.chapter.title, style: const TextStyle(fontSize: 16)),
            Text(widget.bookTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: widget.chapter.shlokas.length,
        itemBuilder: (context, i) {
          final shloka = widget.chapter.shlokas[i];
          final isHighlighted = shloka.id == widget.highlightShlokaId;

          return Container(
            key: _shlokaKeys[shloka.id],
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighlighted ? kOrange : kBorder,
                width: isHighlighted ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ಶ್ಲೋಕ ${shloka.id}', style: TextStyle(color: kMuted, fontWeight: FontWeight.bold)),
                      Icon(Icons.touch_app, color: kMuted.withOpacity(0.5), size: 16),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // The Interactive Text
                  _buildInteractiveSanskrit(shloka.sanskrit),
                  
                  if (shloka.kannada != null && shloka.kannada!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: kOrange, width: 4)),
                        color: kOrange.withOpacity(0.05),
                      ),
                      child: Text(
                        shloka.kannada!,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kText,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shloka.translation,
                      style: TextStyle(fontSize: 15, color: kText, height: 1.5),
                    ),
                  ),
                  
                  if (shloka.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: shloka.tags.map((t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        backgroundColor: kPurple2.withOpacity(0.1),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The Bottom Sheet that shows Amara Kosha dictionary meanings
class _AmaraKoshaSheet extends StatelessWidget {
  final String word;
  final AmaraKoshaEntry? entry;

  const _AmaraKoshaSheet({required this.word, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ]
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: kPurple2.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.book, color: kPurple2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ಅಮರಕೋಶ (Amara Kosha)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(word, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 24),
            
            if (entry != null) ...[
              const Text('ಅರ್ಥ (Meaning):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(entry!.meaning, style: const TextStyle(fontSize: 18)),
              
              if (entry!.synonyms.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('ಪರ್ಯಾಯ ಪದಗಳು (Synonyms):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: entry!.synonyms.map((s) => Chip(
                    label: Text(s),
                    backgroundColor: kGreen.withOpacity(0.1),
                    side: BorderSide(color: kGreen.withOpacity(0.3)),
                  )).toList(),
                ),
              ],
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('ಈ ಪದದ ಅರ್ಥ ಅಮರಕೋಶದಲ್ಲಿ ಸಿಗಲಿಲ್ಲ.\n\n(Word not mapped in dictionary yet)', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
