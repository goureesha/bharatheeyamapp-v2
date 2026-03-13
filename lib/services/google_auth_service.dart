import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:flutter/foundation.dart';

class GoogleAuthService {
  static const _webClientId =
      '330797161511-h4mb1l0i76ea37s6if93bml6gia4puva.apps.googleusercontent.com';

  static final _scopes = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/calendar',
  ];

  static GoogleSignIn? _googleSignIn;
  static GoogleSignInAccount? _currentUser;

  static GoogleSignIn get _instance {
    _googleSignIn ??= GoogleSignIn(
      scopes: _scopes,
      clientId: _webClientId,
      serverClientId: _webClientId,
    );
    return _googleSignIn!;
  }

  static bool get isSignedIn => _currentUser != null;
  static String? get userEmail => _currentUser?.email;
  static String? get userName => _currentUser?.displayName;
  static String? get userPhoto => _currentUser?.photoUrl;

  static Future<bool> signIn() async {
    try {
      _currentUser = await _instance.signIn();
      if (_currentUser != null) {
        debugPrint('Google Sign-In success: ${_currentUser!.email}');
      }
      return _currentUser != null;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await _instance.signOut();
    _currentUser = null;
  }

  static Future<bool> signInSilently() async {
    try {
      _currentUser = await _instance.signInSilently();
      return _currentUser != null;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return false;
    }
  }

  /// Request additional scopes if needed (call before API operations)
  static Future<bool> ensureScopes() async {
    if (_currentUser == null) return false;
    try {
      final granted = await _instance.requestScopes(_scopes);
      debugPrint('Scopes granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('Scope request error: $e');
      return false;
    }
  }

  static Future<gauth.AuthClient?> getAuthClient() async {
    if (_currentUser == null) return null;
    try {
      // On web, ensure scopes are granted before getting client
      if (kIsWeb) {
        await ensureScopes();
      }
      return await _instance.authenticatedClient();
    } catch (e) {
      debugPrint('Auth client error: $e');
      return null;
    }
  }
}
