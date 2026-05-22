import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis_auth;
import 'tester_service.dart';

/// Google Sign-In service — email + calendar scopes.
/// Used for user identity and Google Calendar 2-way sync.
class GoogleAuthService {
  static const _webClientId =
      '330797161511-h4mb1l0i76ea37s6if93bml6gia4puva.apps.googleusercontent.com';

  static GoogleSignIn? _googleSignIn;
  static GoogleSignInAccount? _currentUser;

  static GoogleSignIn get _instance {
    _googleSignIn ??= GoogleSignIn(
      scopes: const [
        'email',
        'https://www.googleapis.com/auth/drive.appdata',
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events',
      ],
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: _webClientId,
    );
    return _googleSignIn!;
  }

  static bool get isSignedIn => _currentUser != null;
  static String? get userEmail => _currentUser?.email;
  static String? get userName => _currentUser?.displayName;
  static String? get userPhoto => _currentUser?.photoUrl;

  /// Get auth headers for Google API calls (e.g., Drive API)
  static Future<Map<String, String>?> getAuthHeaders() async {
    return _currentUser?.authHeaders;
  }

  /// Get an authenticated HTTP client for googleapis (Calendar, etc.)
  /// Returns null if not signed in or auth fails.
  static Future<gapis_auth.AuthClient?> getAuthenticatedClient() async {
    if (_currentUser == null) return null;
    try {
      final client = await _instance.authenticatedClient();
      return client;
    } catch (e) {
      debugPrint('GoogleAuthService: getAuthenticatedClient error: $e');
      return null;
    }
  }

  /// Request Drive scope if not already granted (for existing sessions).
  /// Returns true if scope is available, false if user denied.
  static Future<bool> ensureDriveScope() async {
    if (_currentUser == null) return false;
    try {
      final granted = await _instance.requestScopes([
        'https://www.googleapis.com/auth/drive.appdata',
      ]);
      return granted;
    } catch (e) {
      debugPrint('Drive scope request failed: $e');
      return false;
    }
  }

  /// Request Calendar scopes if not already granted.
  /// Returns true if scopes are available, false if user denied.
  static Future<bool> ensureCalendarScope() async {
    if (_currentUser == null) return false;
    try {
      final granted = await _instance.requestScopes([
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events',
      ]);
      return granted;
    } catch (e) {
      debugPrint('Calendar scope request failed: $e');
      return false;
    }
  }

  static Future<bool> signIn() async {
    try {
      _currentUser = await _instance.signIn();
      if (_currentUser != null) {
        debugPrint('Google Sign-In success: ${_currentUser!.email}');
        TesterService.checkTesterStatus(_currentUser!.email);
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
    await TesterService.onSignOut();
  }

  static Future<bool> signInSilently() async {
    try {
      _currentUser = await _instance.signInSilently();
      if (_currentUser != null) {
        TesterService.checkTesterStatus(_currentUser!.email);
      }
      return _currentUser != null;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return false;
    }
  }
}
