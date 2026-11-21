import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'service_exception.dart';
import 'user_service.dart';

/// Firebase Authentication only (login, register, reset, logout).
class AuthService {
  final UserService _users;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthService(this._users);

  /// Emits the signed-in user's uid, or null when signed out.
  Stream<String?> get uidChanges =>
      _auth.authStateChanges().map((user) => user?.uid);

  String? get currentUid => _auth.currentUser?.uid;

  String? get currentEmail => _auth.currentUser?.email;

  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw ServiceException(authErrorMessage(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(
        e.code == 'invalid-email'
            ? 'Please enter a valid email address.'
            : 'Unable to send reset email. Please try again.',
      );
    }
  }

  /// Creates the Auth account AND the users/{uid} profile.
  Future<void> register({
    required String fullName,
    required String idNo,
    required String faculty,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        await _users.createProfile(
          AppUser(
            uid: cred.user!.uid,
            fullName: fullName,
            matricNo: idNo,
            faculty: faculty,
            email: email,
            role: role,
          ),
        );
      } on ServiceException {
        // Do not leave an account without a profile.
        await cred.user!.delete();
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw ServiceException(authErrorMessage(e));
    }
  }

  Future<void> logout() => _auth.signOut();
}
