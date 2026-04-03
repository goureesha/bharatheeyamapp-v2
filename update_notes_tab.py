import sys

file_path = "lib/screens/dashboard_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

start_marker = "  Widget _buildNotesTab() {"
end_marker = "  void _showPrintPreview(String text) {"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("Markers not found!")
    sys.exit(1)

new_code = """  final Map<String, TextEditingController> _noteControllers = {};

  TextEditingController _getNoteController(String name) {
    if (!_noteControllers.containsKey(name)) {
      _noteControllers[name] = TextEditingController();
    }
    return _noteControllers[name]!;
  }
  
  void _saveIndividualNote(String name, bool isPrimary, _PersonEntry? entry, String newNotes) {
    final cId = widget.extraInfo['clientId'] ?? '';
    
    if (isPrimary) {
      StorageService.save(Profile(
        name: widget.name, date: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}',
        hour: widget.hour, minute: widget.minute, ampm: widget.ampm, lat: widget.lat, lon: widget.lon, place: widget.place,
        tzOffset: LocationService.tzOffset, notes: newNotes, aroodhas: _aroodhas, janmaNakshatraIdx: _janmaNakshatraIdx, clientId: (cId is String && cId.isNotEmpty) ? cId : null,
      ));
      if (cId is String && cId.isNotEmpty) {
        ClientService.updateFamilyMember(FamilyMember(clientId: cId, memberName: widget.name, relation: 'Self', dob: '${widget.dob.year}-${widget.dob.month.toString().padLeft(2, '0')}-${widget.dob.day.toString().padLeft(2, '0')}', birthTime: '${widget.hour.toString().padLeft(2,'0')}:${widget.minute.toString().padLeft(2,'0')} ${widget.ampm}', birthPlace: widget.place, lat: widget.lat, lon: widget.lon, notes: newNotes));
      }
    } else if (entry != null) {
       final dateStr = '${entry.dob.year}-${entry.dob.month.toString().padLeft(2, '0')}-${entry.dob.day.toString().padLeft(2, '0')}';
       StorageService.save(Profile(
         name: entry.name, date: dateStr, hour: entry.hour, minute: entry.minute, ampm: entry.ampm, lat: entry.lat, lon: entry.lon, place: entry.place,
         tzOffset: LocationService.tzOffset, notes: newNotes, clientId: (cId is String && cId.isNotEmpty) ? cId : null,
       ));
       if (cId is String && cId.isNotEmpty) {
         ClientService.updateFamilyMember(FamilyMember(clientId: cId, memberName: entry.name, relation: 'Group Member', dob: dateStr, birthTime: '${entry.hour.toString().padLeft(2,'0')}:${entry.minute.toString().padLeft(2,'0')} ${entry.ampm}', birthPlace: entry.place, lat: entry.lat, lon: entry.lon, notes: newNotes));
       }
    }
  }

  Widget _buildIndividualNoteSection({required String name, required bool isPrimary, required _PersonEntry? entry}) {
    final currentNotes = isPrimary ? _notes : (entry?.notes ?? '');
    final entries = _parseNoteEntries(currentNotes);
    final ctrl = _getNoteController(name);
    
    void shareNotes() {
      final dobDate = isPrimary ? widget.dob : entry!.dob;
      final dobStr = '${dobDate.day.toString().padLeft(2, '0')}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.year}';
      final buf = StringBuffer();
      buf.writeln('═══════════════════════════');
      buf.writeln('   ✨ ${tr('ಭಾರತೀಯಮ್')} ✨');
      buf.writeln('═══════════════════════════\\n');
      buf.writeln('👤 ${tr('ಹೆಸರು')}: $name');
      buf.writeln('📅 ${tr('ಜನ್ಮ ದಿನಾಂಕ')}: $dobStr\\n');
      buf.writeln('───────────────────────────');
      buf.writeln('   📝 ${tr('ಟಿಪ್ಪಣಿಗಳು')}');
      buf.writeln('───────────────────────────\\n');
      if (entries.isEmpty) {
        buf.writeln(tr('ಯಾವುದೇ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ'));
      } else {
        for (int i = 0; i < entries.length; i++) {
          buf.writeln('🕐 ${entries[i]['date']}\\n   ${entries[i]['text']}');
          if (i < entries.length - 1) buf.writeln();
        }
      }
      buf.writeln('\\n═══════════════════════════');
      final text = buf.toString();
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('ಕ್ಲಿಪ್‌ಬೋರ್ಡ್‌ಗೆ ನಕಲಿಸಲಾಗಿದೆ! ✅'))));
      final encoded = Uri.encodeComponent(text);
      launchUrl(Uri.parse('https://wa.me/?text=$encoded'), mode: LaunchMode.externalApplication);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: isPrimary,
        backgroundColor: kCard,
        collapsedBackgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kBorder)),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w900, color: kTeal)),
        subtitle: Text(isPrimary ? tr('ಮುಖ್ಯ ವ್ಯಕ್ತಿ ಟಿಪ್ಪಣಿಗಳು') : tr('ಗುಂಪು ಸದಸ್ಯರ ಟಿಪ್ಪಣಿಗಳು'), style: TextStyle(fontSize: 12, color: kMuted)),
        childrenPadding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: shareNotes,
                  icon: Icon(Icons.share, size: 18),
                  label: Text(tr('ಹಂಚಿಕೊಳ್ಳಿ'), style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  maxLines: 8,
                  minLines: 3,
                  decoration: InputDecoration(
                    hintText: tr('ಹೊಸ ಟಿಪ್ಪಣಿ ಸೇರಿಸಿ...'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                    fillColor: kBg, filled: true, contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(fontSize: 14, height: 1.5, color: kText),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) return;
                  final now = DateTime.now();
                  final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                  final newEntry = '[$stamp] $text';
                  setState(() {
                    String updatedNotes = currentNotes.isEmpty ? newEntry : '$newEntry\\n---\\n$currentNotes';
                    if (isPrimary) {
                      _notes = updatedNotes;
                    } else if (entry != null) {
                      entry.notes = updatedNotes;
                    }
                    ctrl.clear();
                    _saveIndividualNote(name, isPrimary, entry, updatedNotes);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ ${tr('ಟಿಪ್ಪಣಿ ಉಳಿಸಲಾಗಿದೆ')}'), backgroundColor: Colors.green));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(tr('ಇನ್ನೂ ಟಿಪ್ಪಣಿಗಳಿಲ್ಲ'), style: TextStyle(color: kMuted))))
          else
            ...entries.asMap().entries.map((en) {
              final i = en.key;
              final e = en.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: kTeal), const SizedBox(width: 6),
                        Text(e['date'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTeal)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            ctrl.text = e['text'] ?? '';
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              String updatedNotes = updatedEntries.map((enx) => '[${enx['date']}] ${enx['text']}').join('\\n---\\n');
                              if (isPrimary) _notes = updatedNotes;
                              else if (entry != null) entry.notes = updatedNotes;
                            });
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.edit, size: 18, color: kPurple2)),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final updatedEntries = List<Map<String, String>>.from(entries);
                            updatedEntries.removeAt(i);
                            setState(() {
                              String updatedNotes = updatedEntries.map((enx) => '[${enx['date']}] ${enx['text']}').join('\\n---\\n');
                              if (isPrimary) _notes = updatedNotes;
                              else if (entry != null) entry.notes = updatedNotes;
                              _saveIndividualNote(name, isPrimary, entry, updatedNotes);
                            });
                          },
                          child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(e['text'] ?? '', style: TextStyle(fontSize: 14, height: 1.4, color: kText)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    final allPersons = <Map<String, dynamic>>[
      {'name': widget.name, 'isPrimary': true, 'entry': null},
      ..._extraPersons.map((p) => {'name': p.name, 'isPrimary': false, 'entry': p}),
    ];

    return ListView.builder(
      itemCount: allPersons.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (ctx, i) {
        final pData = allPersons[i];
        return _buildIndividualNoteSection(
           name: pData['name'] as String,
           isPrimary: pData['isPrimary'] as bool,
           entry: pData['entry'] as _PersonEntry?,
        );
      },
    );
  }

"""

new_content = content[:start_idx] + new_code + content[end_idx:]
with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)

print("Replacement successful!")
