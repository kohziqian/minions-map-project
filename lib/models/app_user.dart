// A user profile stored in Firestore: users with document titled {uid}
class AppUser {
  static const String roleStudent = 'Student';
  static const String roleInvigilator = 'Invigilator';

  final String uid;
  final String fullName;
  final String matricNo; // Student ID / Staff ID
  final String faculty;
  final String email; // primary email
  final String role;
  final String secondaryEmail;
  final String phoneNumber;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.matricNo,
    required this.faculty,
    required this.email,
    required this.role,
    this.secondaryEmail = '',
    this.phoneNumber = '',
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) {
    String s(String key) => (m[key] ?? '').toString();

    return AppUser(
      uid: uid,
      fullName: s('fullName'),
      matricNo: s('matricNo'),
      faculty: s('faculty'),
      email: s('email'),
      role: s('role'),
      secondaryEmail: s('secondaryEmail'),
      phoneNumber: s('phoneNumber'),
    );
  }

  bool get isInvigilator => role == roleInvigilator;

  // Name shown on the dashboard as welcome message
  String get displayName => fullName.isEmpty ? 'User' : fullName;
}
