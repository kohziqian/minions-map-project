import 'dart:async';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/service_exception.dart';
import '../services/user_service.dart';
import 'base_viewmodel.dart';

// Profile page for signed in user with details
class ProfileViewModel extends BaseViewModel {
  final UserService _users;
  final AuthService _auth;

  StreamSubscription<String?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  String? _uid;
  AppUser? _profile;

  ProfileViewModel(this._users, this._auth) {
    _authSub = _auth.uidChanges.listen(_onUidChanged);
  }
  
  // null while loading (or right after registration, before the profile document exists
  AppUser? get profile => _profile;

  // Primary email, falls back to the Auth email
  String get primaryEmail {
    final email = _profile?.email ?? '';
    return email.isNotEmpty ? email : (_auth.currentEmail ?? '');
  }

  void _onUidChanged(String? uid) {
    _profileSub?.cancel();
    _profileSub = null;

    _uid = uid;
    _profile = null;

    if (uid != null) {
      _profileSub = _users.watchUser(uid).listen(
        (user) {
          _profile = user;
          notifyListeners();
        },
        onError: (_) {},  // Allows user to logout when profile is null
      );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  // Validates and saves secondary email + phone number.
  Future<bool> saveContact({
    required String secondaryEmail,
    required String phone,
  }) =>
      run(() async {
        final uid = _uid;

        if (uid == null) {
          throw const ServiceException('You are not signed in.');
        }

        final secondary = secondaryEmail.trim();
        final phoneNo = phone.trim();

        if (secondary.isNotEmpty) {
          final emailOk =
              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(secondary);

          if (!emailOk) {
            throw const ServiceException(
              'Please enter a valid secondary email address.',
            );
          }

          if (secondary.toLowerCase() == primaryEmail.toLowerCase()) {
            throw const ServiceException(
              'Secondary email must be different from primary email.',
            );
          }
        }

        if (phoneNo.isNotEmpty) {
          final digits = phoneNo.replaceAll(RegExp(r'\D'), '');
          final charsOk = RegExp(r'^\+?[0-9\s\-]+$').hasMatch(phoneNo);

          if (!charsOk || digits.length < 8 || digits.length > 15) {
            throw const ServiceException('Please enter a valid phone number.');
          }
        }

        await _users.updateContact(
          uid: uid,
          secondaryEmail: secondary,
          phoneNumber: phoneNo,
        );
      });
}
