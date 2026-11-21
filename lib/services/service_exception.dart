import 'package:firebase_auth/firebase_auth.dart';

// Services translate Firebase errors for Views and ViewModel

class ServiceException implements Exception {
  final String message;

  const ServiceException(this.message);

  @override
  String toString() => message;
}

// Converts FirebaseException into a ServiceException
Future<T> guardFirebase<T>(
  Future<T> Function() action, {
  String prefix = '',
}) async {
  try {
    return await action();
  } on FirebaseException catch (e) {
    final msg = e.message ?? e.code;
    throw ServiceException(prefix.isEmpty ? msg : '$prefix: $msg');
  }
}

// Firebase auth error message
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
