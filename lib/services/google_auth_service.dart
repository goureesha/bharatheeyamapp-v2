import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

/// Google Sign-In service — email-only (no sensitive scopes).
/// Used purely for user identity (1-Gmail-1-device binding).
class GoogleAuthService {
  static const _webClientId =
      '330797161511-h4mb1l0i76ea37s6if93bml6gia4puva.apps.googleusercontent.com';

  static GoogleSignIn? _googleSignIn;
  static GoogleSignInAccount? _currentUser;

  static GoogleSignIn get _instance {
    _googleSignIn ??= GoogleSignIn(
      scopes: const ['email'],
      clientId: kIsWeb ? _webClientId : null,
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
}
