import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'tester_service.dart';

/// Google Sign-In service — email-only (no sensitive scopes).
/// Used for user identity (1-Gmail-1-device binding) + Firebase Auth for Firestore rules.
class GoogleAuthService {
  static const _webClientId =
      '212430902387-ko5eqtpf1044c7bs0jok7uldqbpnu8a2.apps.googleusercontent.com';

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

  /// Check if Firebase Auth is active (needed for Firestore rules)
  static bool get isFirebaseAuthActive =>
      FirebaseAuth.instance.currentUser != null;

  /// Get the Firebase Auth email (may differ from Google Sign-In email if bridge failed)
  static String? get firebaseAuthEmail =>
      FirebaseAuth.instance.currentUser?.email;

  /// Get auth headers for Google API calls (e.g., Drive API)
  static Future<Map<String, String>?> getAuthHeaders() async {
    return _currentUser?.authHeaders;
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

  /// Bridge Google Sign-In credentials to Firebase Auth.
  /// Returns true if Firebase Auth is now active.
  static Future<bool> _signInToFirebaseAuth(GoogleSignInAccount account) async {
    try {
      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final ok = result.user != null;
      debugPrint('Firebase Auth: ${ok ? "✅ signed in" : "❌ failed"} as ${account.email}');
      return ok;
    } catch (e) {
      debugPrint('Firebase Auth bridge error: $e');
      return false;
    }
  }

  /// Ensure Firebase Auth is active. If not, attempt to re-bridge.
  /// Call this before any Firestore operation that needs auth.
  static Future<bool> ensureFirebaseAuth() async {
    // Already active
    if (FirebaseAuth.instance.currentUser != null) return true;

    // Try to re-bridge from current Google Sign-In account
    if (_currentUser != null) {
      debugPrint('Firebase Auth: re-bridging from existing Google Sign-In...');
      final ok = await _signInToFirebaseAuth(_currentUser!);
      if (ok) return true;
    }

    // Try silent sign-in as last resort
    try {
      final account = await _instance.signInSilently();
      if (account != null) {
        _currentUser = account;
        return await _signInToFirebaseAuth(account);
      }
    } catch (e) {
      debugPrint('Firebase Auth: silent re-auth failed: $e');
    }

    debugPrint('Firebase Auth: ❌ could not establish auth session');
    return false;
  }

  static Future<bool> signIn() async {
    try {
      _currentUser = await _instance.signIn();
      if (_currentUser != null) {
        debugPrint('Google Sign-In success: ${_currentUser!.email}');
        final authOk = await _signInToFirebaseAuth(_currentUser!);
        if (!authOk) {
          debugPrint('WARNING: Google Sign-In OK but Firebase Auth bridge FAILED');
        }
        TesterService.checkTesterStatus(_currentUser!.email);
      }
      return _currentUser != null;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await _instance.disconnect(); // Fully clear cached account so user can pick a different Gmail
    } catch (_) {
      await _instance.signOut(); // Fallback if disconnect fails
    }
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    await TesterService.onSignOut();
  }

  static Future<bool> signInSilently() async {
    try {
      _currentUser = await _instance.signInSilently();
      if (_currentUser != null) {
        final authOk = await _signInToFirebaseAuth(_currentUser!);
        if (!authOk) {
          debugPrint('WARNING: Silent sign-in OK but Firebase Auth bridge FAILED');
        }
        TesterService.checkTesterStatus(_currentUser!.email);
      }
      return _currentUser != null;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return false;
    }
  }
}
