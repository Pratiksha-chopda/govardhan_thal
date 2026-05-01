import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'token_manager.dart';

/// ─────────────────────────────────────────────────────────────
/// AuthService — Bridges Firebase Auth with our backend JWT system.
///
/// After Firebase Google Sign-In, this sends user data to the
/// backend, receives JWT tokens, and stores them locally.
/// ─────────────────────────────────────────────────────────────
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Firebase Google Sign-In → Backend login → Store tokens
  /// Returns the user data map on success, null on failure/cancel.
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Step 1: Firebase Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      // Step 2: Send Firebase data to our backend
      final result = await ApiService.firebaseLogin(
        firebaseUID: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        profileImage: firebaseUser.photoURL ?? '',
      );

      if ((result['status'] == 'success' || result['success'] == true) && result['data'] != null) {
        final data = result['data'];

        // Step 3: Store JWT tokens + user info locally
        await TokenManager.saveSession(
          accessToken: data['accessToken'] ?? '',
          refreshToken: data['refreshToken'] ?? '',
          user: data['user'] ?? {},
        );

        return data['user'];
      }

      return null;
    } catch (e) {
      // Re-throw so the login screen can display the error
      rethrow;
    }
  }

  /// Mobile login → Store tokens
  static Future<Map<String, dynamic>?> mobileLogin(
      String mobile, String password) async {
    final result = await ApiService.login(mobile, password);

    if ((result['status'] == 'success' || result['success'] == true) && result['data'] != null) {
      final data = result['data'];
      await TokenManager.saveSession(
        accessToken: data['accessToken'] ?? '',
        refreshToken: data['refreshToken'] ?? '',
        user: data['user'] ?? {},
      );
      return data['user'];
    }

    // Return the error result for the UI to display
    throw Exception(result['message'] ?? 'Login failed');
  }

  /// Register new mobile user
  static Future<void> register(
      String name, String email, String mobile, String password) async {
    final result = await ApiService.register(name, email, mobile, password);
    if (result['status'] != 'success') {
      throw Exception(result['message'] ?? 'Registration failed');
    }
  }

  /// Full logout — clear Firebase + backend tokens + local storage
  static Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (_) {
      // Ignore Firebase errors on logout
    }
    await TokenManager.clearAll();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return TokenManager.isLoggedIn();
  }
}
