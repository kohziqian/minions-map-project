import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'service_exception.dart';

/// All reads/writes of the `users/{uid}` collection.
class UserService {
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  AppUser? _toUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return data == null ? null : AppUser.fromMap(doc.id, data);
  }

  /// Live profile. Emits null while the document does not exist
  /// (e.g. right after registration, before it is written).
  Stream<AppUser?> watchUser(String uid) =>
      _users.doc(uid).snapshots().map(_toUser);

  Future<AppUser?> getUser(String uid) => guardFirebase(() async {
        final doc = await _users.doc(uid).get();
        return _toUser(doc);
      });

  Future<void> createProfile(AppUser user) => guardFirebase(
        () => _users.doc(user.uid).set({
          'fullName': user.fullName,
          'matricNo': user.matricNo, // Student ID or Staff ID
          'faculty': user.faculty,
          'email': user.email, // primary email = registered email
          'role': user.role,
          'createdAt': FieldValue.serverTimestamp(),
        }),
        prefix: 'Could not save profile',
      );

  Future<void> updateContact({
    required String uid,
    required String secondaryEmail,
    required String phoneNumber,
  }) =>
      guardFirebase(
        () => _users.doc(uid).update({
          'secondaryEmail': secondaryEmail,
          'phoneNumber': phoneNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        prefix: 'Could not update profile',
      );
}
