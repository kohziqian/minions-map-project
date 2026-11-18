// AuthViewModel, ProfileViewModel, DashboardViewModel

import 'package:flutter/foundation.dart';
import 'services.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._auth, this._users);
  final AuthService _auth;
  final UserService _users;

  bool loading = false;
  String? message; // error text, or info text for the reset email
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<bool> _fail(String text) async {
    message = text;
    notifyListeners();
    return false;
  }

  Future<bool> _run(Future<void> Function() action) async {
    loading = true;
    message = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ServiceException catch (e) {
      message = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) {
      return _fail('Please enter email and password.');
    }
    return _run(() => _auth.signIn(email.trim(), password));
  }

  Future<bool> register({
    required String name,
    required String idNo,
    required String faculty,
    required String email,
    required String password,
    required String role,
  }) {
    if (name.trim().isEmpty ||
        idNo.trim().isEmpty ||
        faculty.trim().isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty) {
      return _fail('Please complete all fields.');
    }
    if (password.length < 6) {
      return _fail('Password must be at least 6 characters.');
    }
    return _run(() async {
      await _auth.register(email.trim(), password);
      try {
        await _users.createProfile(
          uid: _auth.currentUid!,
          fullName: name.trim(),
          idNo: idNo.trim().toUpperCase(),
          faculty: faculty.trim(),
          email: email.trim(),
          role: role,
        );
      } on ServiceException catch (e) {
        await _auth.deleteCurrentUser(); // no account without a profile
        throw ServiceException('Could not save profile: ${e.message}');
      }
    });
  }

  Future<bool> sendResetEmail(String email) async {
    if (email.trim().isEmpty) {
      return _fail('Please enter your email address.');
    }
    final ok = await _run(() => _auth.sendResetEmail(email.trim()));
    if (ok) {
      message =
          'If an account exists for this email, a password reset link will be sent.';
      notifyListeners();
    }
    return ok;
  }
}

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._auth, this._users);
  final AuthService _auth;
  final UserService _users;

  bool saving = false;
  String? message;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String? get uid => _auth.currentUid;
  String get currentEmail => _auth.currentEmail ?? '';
  Stream<Map<String, dynamic>?> get profile => _users.watchProfile(uid!);

  Future<void> logout() => _auth.signOut();

  Future<bool> saveContact({
    required String secondaryEmail,
    required String phone,
    required String primaryEmail,
  }) async {
    final email = secondaryEmail.trim();
    final tel = phone.trim();

    if (email.isNotEmpty) {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        message = 'Please enter a valid secondary email address.';
        notifyListeners();
        return false;
      }
      if (email.toLowerCase() == primaryEmail.toLowerCase()) {
        message = 'Secondary email must be different from primary email.';
        notifyListeners();
        return false;
      }
    }
    if (tel.isNotEmpty) {
      final digits = tel.replaceAll(RegExp(r'\D'), '');
      final charsOk = RegExp(r'^\+?[0-9\s\-]+$').hasMatch(tel);
      if (!charsOk || digits.length < 8 || digits.length > 15) {
        message = 'Please enter a valid phone number.';
        notifyListeners();
        return false;
      }
    }

    saving = true;
    message = null;
    notifyListeners();
    try {
      await _users.updateContact(
          uid: uid!, secondaryEmail: email, phone: tel);
      return true;
    } on ServiceException catch (e) {
      message = 'Could not update profile: ${e.message}';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

class DashboardViewModel {
  DashboardViewModel(this._users);
  final UserService _users;

  Stream<Map<String, dynamic>?> watchProfile(String uid) =>
      _users.watchProfile(uid);
  String nameOf(Map<String, dynamic> data) =>
      (data['fullName'] ?? 'User').toString();
  bool isInvigilator(Map<String, dynamic> data) => data['role'] == 'Invigilator';
}
