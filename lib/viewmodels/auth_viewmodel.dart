import 'dart:async';

import '../services/auth_service.dart';
import '../services/service_exception.dart';
import 'base_viewmodel.dart';

// Login state, login, register, forgot password, logout.
class AuthViewModel extends BaseViewModel {
  final AuthService _auth;
  StreamSubscription<String?>? _authSub;

  String? _uid;
  bool _initializing = true;

  AuthViewModel(this._auth) {
    // The ViewModel listens to the login state
    _authSub = _auth.uidChanges.listen((uid) {
      _uid = uid;
      _initializing = false;
      notifyListeners();
    });
  }

  // Cached login: uid of the signed-in user = null when signed out
  String? get uid => _uid;

  // True until user is signed in
  bool get initializing => _initializing;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<bool> login(String email, String password) => run(() async {
        final e = email.trim();

        if (e.isEmpty || password.isEmpty) {
          throw const ServiceException('Please enter email and password.');
        }

        await _auth.login(e, password);
      });

  Future<bool> sendResetEmail(String email) => run(() async {
        final e = email.trim();

        if (e.isEmpty) {
          throw const ServiceException('Please enter your email address.');
        }

        await _auth.sendPasswordReset(e);
      });

  Future<bool> register({
    required String fullName,
    required String idNo,
    required String faculty,
    required String email,
    required String password,
    required String role,
  }) =>
      run(() async {
        final name = fullName.trim();
        final id = idNo.trim().toUpperCase();
        final fac = faculty.trim();
        final mail = email.trim();

        if (name.isEmpty ||
            id.isEmpty ||
            fac.isEmpty ||
            mail.isEmpty ||
            password.isEmpty) {
          throw const ServiceException('Please complete all fields.');
        }

        if (password.length < 6) {
          throw const ServiceException(
            'Password must be at least 6 characters.',
          );
        }

        await _auth.register(
          fullName: name,
          idNo: id,
          faculty: fac,
          email: mail,
          password: password,
          role: role,
        );
      });

  Future<void> logout() => _auth.logout();
}
