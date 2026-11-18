// ServiceException, authErrorMessage(), AuthService, UserService

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceException implements Exception {
  final String message;
  const ServiceException(this.message);
}

String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Wrong email or password. No account yet? Tap "Create an account".';

    case 'invalid-email':
      return 'Please enter a valid email address.';

    case 'email-already-in-use':
      return 'This email is already registered. Please login instead.';

    case 'weak-password':
      return 'Password must be at least 6 characters.';

    case 'network-request-failed':
      return 'No internet connection.';

    default:
      return e.message ?? 'Something went wrong (${e.code}).';
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<String?> get uidChanges =>
      _auth.authStateChanges().map((user) => user?.uid);
  String? get currentUid => _auth.currentUser?.uid;
  String? get currentEmail => _auth.currentUser?.email;

  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(authErrorMessage(e));
    }
  }

  Future<void> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(authErrorMessage(e));
    }
  }

  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (_) {}
  }

  Future<void> sendResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServiceException(e.code == 'invalid-email'
          ? 'Please enter a valid email address.'
          : 'Unable to send reset email. Please try again.');
    }
  }

  Future<void> signOut() => _auth.signOut();
}

class UserService {
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Stream<Map<String, dynamic>?> watchProfile(String uid) =>
      _users.doc(uid).snapshots().map((doc) => doc.data());

  Future<void> createProfile({
    required String uid,
    required String fullName,
    required String idNo,
    required String faculty,
    required String email,
    required String role,
  }) async {
    try {
      await _users.doc(uid).set({
        'fullName': fullName,
        'matricNo': idNo,
        'faculty': faculty,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Could not save profile.');
    }
  }

  Future<void> updateContact({
    required String uid,
    required String secondaryEmail,
    required String phone,
  }) async {
    try {
      await _users.doc(uid).update({
        'secondaryEmail': secondaryEmail,
        'phoneNumber': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServiceException(e.message ?? 'Could not update profile.');
    }
  }
}
