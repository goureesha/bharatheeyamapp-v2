import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'tester_service.dart';

/// Google Sign-In service — email-only (no sensitive scopes).
/// Used purely for user identity (1-Gmail-1-device binding).
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

