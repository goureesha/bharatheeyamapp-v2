import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'tester_service.dart';

/// Google Sign-In service — signs in with Google AND authenticates with Firebase.
/// This ensures Firestore operations have proper auth credentials.
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

  /// Sign in with Google AND authenticate with Firebase Auth.
  /// This gives Firestore the auth token it needs for security rules.
  static Future<bool> signIn() async {
    try {
      _currentUser = await _instance.signIn();
      if (_currentUser != null) {
        // Authenticate with Firebase using the Google credential
        await _firebaseAuthWithGoogle(_currentUser!);
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase sign-out error: $e');
    }
    await _instance.signOut();
    _currentUser = null;
    await TesterService.onSignOut();
  }

  static Future<bool> signInSilently() async {
    try {
      _currentUser = await _instance.signInSilently();
      if (_currentUser != null) {
        // Authenticate with Firebase using the Google credential
        await _firebaseAuthWithGoogle(_currentUser!);
        TesterService.checkTesterStatus(_currentUser!.email);
      }
      return _currentUser != null;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return false;
    }
  }

  /// Bridge Google Sign-In → Firebase Auth.
  /// Gets the Google auth tokens and uses them to sign into Firebase.
  static Future<void> _firebaseAuthWithGoogle(GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase Auth: signed in as ${googleUser.email}');
    } catch (e) {
      debugPrint('Firebase Auth error (non-fatal): $e');
      // Non-fatal — Google Sign-In identity still works for UI,
      // but Firestore writes may fail without Firebase Auth.
    }
  }
}
