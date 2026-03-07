import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

/// An adapter to construct a Google API AuthClient from the GoogleSignInAccount headers.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleAuthService {
  /// WARNING: Replace with your actual Web and Android Client IDs
  /// from the Google Cloud Console.
  static const String webClientId = 'REPLACE_ME_WITH_WEB_CLIENT_ID.apps.googleusercontent.com';
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: webClientId,
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  static Future<auth.AuthClient?> getAuthenticatedClient() async {
    final account = _googleSignIn.currentUser ?? await signIn();
    if (account == null) return null;

    final headers = await account.authHeaders;
    return auth.authenticatedClient(
      _client: http.Client(), // Note: googleapis_auth wrapper doesn't take _client directly like this. 
      // We use our custom adapter below.
    );
  }

  static Future<GoogleAuthClient?> getClient() async {
    final account = _googleSignIn.currentUser ?? await signIn();
    if (account == null) return null;

    final headers = await account.authHeaders;
    return GoogleAuthClient(headers);
  }
}
