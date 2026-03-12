import 'package:googleapis/docs/v1.dart' as docs;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'google_auth_service.dart';

class DocsService {
  static const _prefPrefix = 'bharatheeyam_doc_';

  /// Sync notes to a Google Doc for this client.
  /// Creates the doc on first use, updates on subsequent calls.
  static Future<bool> syncNotes(String profileName, String notes) async {
    try {
      final client = await GoogleAuthService.getAuthClient();
      if (client == null) return false;

      final api = docs.DocsApi(client);
      final docId = await _getOrCreateDoc(api, profileName);
      if (docId == null) return false;

      // Get current doc to find content length
      final doc = await api.documents.get(docId);
      final endIndex = doc.body?.content?.last.endIndex ?? 1;

      // Clear existing content (except the first newline)
      if (endIndex > 2) {
        await api.documents.batchUpdate(
          docs.BatchUpdateDocumentRequest(requests: [
            docs.Request(
              deleteContentRange: docs.DeleteContentRangeRequest(
                range: docs.Range(
                  startIndex: 1,
                  endIndex: endIndex - 1,
                ),
              ),
            ),
          ]),
          docId,
        );
      }

      // Insert notes content
      final header = '═══ $profileName ═══\n'
          'ಕೊನೆಯ ನವೀಕರಣ: ${DateTime.now().toString().substring(0, 16)}\n'
          '─────────────────────\n\n';

      await api.documents.batchUpdate(
        docs.BatchUpdateDocumentRequest(requests: [
          docs.Request(
            insertText: docs.InsertTextRequest(
              location: docs.Location(index: 1),
              text: '$header$notes',
            ),
          ),
        ]),
        docId,
      );

      return true;
    } catch (e) {
      debugPrint('Docs sync error: $e');
      return false;
    }
  }

  /// Get the Google Doc URL for a client
  static Future<String?> getDocUrl(String profileName) async {
    final prefs = await SharedPreferences.getInstance();
    final docId = prefs.getString('$_prefPrefix${profileName.hashCode}');
    if (docId != null) {
      return 'https://docs.google.com/document/d/$docId/edit';
    }
    return null;
  }

  /// Open the Google Doc in browser
  static Future<bool> openDoc(String profileName) async {
    final url = await getDocUrl(profileName);
    if (url != null) {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<String?> _getOrCreateDoc(docs.DocsApi api, String profileName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefPrefix${profileName.hashCode}';
    final existing = prefs.getString(key);

    if (existing != null) {
      try {
        await api.documents.get(existing);
        return existing;
      } catch (_) {
        // Doc deleted — recreate
      }
    }

    // Create new doc
    try {
      final doc = await api.documents.create(
        docs.Document(title: 'ಜಾತಕ - $profileName'),
      );
      final id = doc.documentId!;
      await prefs.setString(key, id);
      return id;
    } catch (e) {
      debugPrint('Doc creation error: $e');
      return null;
    }
  }
}
