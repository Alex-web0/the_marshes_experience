import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Singleton service for foolproof anonymous Firebase authentication.
///
/// Automatically signs in anonymously on app start, and re-authenticates
/// if the session expires, user is signed out, or auth state becomes invalid.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;
  bool _isSigningIn = false;
  DateTime? _lastFailedAt; // Cooldown to prevent rapid retry loops
  static const _retryCooldown = Duration(minutes: 3);

  /// Current authenticated user (may be null briefly during re-auth).
  User? get currentUser => _auth.currentUser;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Initialize auth: sign in anonymously and listen for auth state changes.
  /// This should be called once during app startup.
  Future<void> ensureAuthenticated() async {
    // If already signed in, we're good
    if (_auth.currentUser != null) {
      debugPrint(
          '[AuthService] Already authenticated: ${_auth.currentUser!.uid}');
    } else {
      // Sign in anonymously
      await _signInAnonymously();
    }

    // Listen for auth state changes to auto-re-login
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Called whenever auth state changes.
  void _onAuthStateChanged(User? user) {
    if (user == null && !_isSigningIn) {
      // Check cooldown to avoid infinite retry loops
      if (_lastFailedAt != null &&
          DateTime.now().difference(_lastFailedAt!) < _retryCooldown) {
        debugPrint(
            '[AuthService] Auth state lost but in cooldown — skipping re-auth.');
        return;
      }
      debugPrint('[AuthService] Auth state lost — re-authenticating...');
      _signInAnonymously();
    } else if (user != null) {
      debugPrint('[AuthService] Authenticated as: ${user.uid}');
      _lastFailedAt = null; // Clear cooldown on success
    }
  }

  /// Sign in anonymously with retry logic (exponential backoff, 3 attempts).
  Future<void> _signInAnonymously() async {
    if (_isSigningIn) return; // Prevent concurrent sign-in attempts
    _isSigningIn = true;

    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
            '[AuthService] Anonymous sign-in attempt $attempt/$maxAttempts...');
        final credential = await _auth.signInAnonymously();
        debugPrint(
            '[AuthService] Signed in successfully: ${credential.user?.uid}');
        _isSigningIn = false;
        _lastFailedAt = null; // Clear cooldown on success
        return;
      } catch (e) {
        debugPrint('[AuthService] Sign-in attempt $attempt failed: $e');
        if (attempt < maxAttempts) {
          // Exponential backoff: 1s, 2s, 4s
          final delay = Duration(seconds: 1 << (attempt - 1));
          debugPrint('[AuthService] Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      }
    }

    _isSigningIn = false;
    _lastFailedAt = DateTime.now(); // Set cooldown
    debugPrint(
        '[AuthService] All sign-in attempts failed. Cooldown for ${_retryCooldown.inMinutes}min before retrying.');
  }

  /// Clean up resources.
  void dispose() {
    _authSubscription?.cancel();
  }
}
