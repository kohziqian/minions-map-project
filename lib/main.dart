import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'firebase_options.dart';

//  - App initialization        main()
//  - Registration              RegisterPage
//  - Login                     LoginPage
//  - Cached (persistent) login   AuthGate (Firebase remembers the user)
//  - Password recovery           ForgotPasswordPage
//  - Logout                      ProfilePage (showLogoutDialog)
//  - View / edit profile         ProfilePage, EditProfilePage
//  - Role personalization        RoleGate, StudentHomePage,
//                                InvigilatorHomePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ExamGuardApp());
}

// =====================================================
// APP
// =====================================================

class ExamGuardApp extends StatelessWidget {
  const ExamGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamGuard',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}

// =====================================================
// AUTH GATE
// =====================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        return RoleGate(user: user);
      },
    );
  }
}

// =====================================================
// ROLE GATE
// =====================================================

class RoleGate extends StatelessWidget {
  final User user;

  const RoleGate({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')  // Reads "users" table from firestore
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (data == null) {
          // Profile is still being written (right after registration)
          // Allow the user to log out so they are no stucked
          return Scaffold(
            appBar: AppBar(
              title: const Text('ExamGuard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              ],
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userName = (data['fullName'] ?? 'User').toString();

        if (data['role'] == 'Invigilator') {
          return InvigilatorHomePage(userName: userName);
        }

        return StudentHomePage(userName: userName);
      },
    );
  }
}

// =====================================================
// FIREBASE ERROR MESSAGE
// =====================================================

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

// =====================================================
// LOGIN
// =====================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => loading = true);

    try { // Cache Login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {  // Login Failed
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ExamGuard')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.qr_code_scanner, size: 80),
              const SizedBox(height: 20),
              const Text(
                'ExamGuard',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Examination Operation Management',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// FORGOT PASSWORD
// =====================================================

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // New password on Firebase page
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for this email, a password reset link will be sent.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'invalid-email'
                ? 'Please enter a valid email address.'
                : 'Unable to send reset email. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.lock_reset, size: 72),
              const SizedBox(height: 20),
              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the email address linked to your account. '
                'We will send you a link to reset your password.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : sendResetEmail,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// REGISTER
// =====================================================
//
// Collects: full name, role, Student/Staff ID, faculty,
// primary email (= login email) and password.

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  final facultyController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'Student';

  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    facultyController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final idNo = idController.text.trim().toUpperCase();
    final faculty = facultyController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty ||
        idNo.isEmpty ||
        faculty.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      showMessage('Please complete all fields.');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() => loading = true);

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          'fullName': name,
          'matricNo': idNo, // Student ID or Staff ID
          'faculty': faculty,
          'email': email, // primary email = registered email
          'role': selectedRole,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException {
        // Do not leave an account without a profile.
        await cred.user!.delete();
        rethrow;
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showMessage(authErrorMessage(e));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      showMessage('Could not save profile: ${e.message}');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInvigilator = selectedRole == 'Invigilator';

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Student', child: Text('Student')),
                DropdownMenuItem(
                  value: 'Invigilator',
                  child: Text('Invigilator'),
                ),
              ],
              onChanged: (value) {
                setState(() => selectedRole = value!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: idController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText:
                    isInvigilator ? 'Staff ID' : 'Student ID (Matric No.)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: facultyController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Faculty',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Primary Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: hidePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 6 characters',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => hidePassword = !hidePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : register,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PROFILE ACTION (small person icon for app bars)
// =====================================================

class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      },
    );
  }
}

// =====================================================
// STUDENT HOME
// =====================================================

class StudentHomePage extends StatelessWidget {
  final String userName;

  const StudentHomePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExamGuard - Student'),
        actions: const [ProfileIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userName',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Manage your examination attendance'),
            const SizedBox(height: 30),

            // STUDENT SCAN EXAM QR
            Card(
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan Exam QR'),
                subtitle: const Text(
                  'Scan the QR code before entering the exam hall',
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentQRScannerPage(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('My Examinations'),
                subtitle: const Text('View your examination sessions'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentExamsPage(),
                    ),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Attendance History'),
                subtitle: const Text('View your exam entry and exit time'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// INVIGILATOR HOME
// =====================================================

class InvigilatorHomePage extends StatelessWidget {
  final String userName;

  const InvigilatorHomePage({super.key, required this.userName});

  void _openScanner(BuildContext context, ScanMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvigilatorScannerPage(mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExamGuard - Invigilator'),
        actions: const [ProfileIconButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $userName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Manage examination sessions'),
              const SizedBox(height: 30),

              // EXAM SESSIONS (select a session to display its QR code)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Exam Sessions'),
                  subtitle: const Text(
                    'Select a session to display its attendance QR code',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExamSessionsPage(),
                      ),
                    );
                  },
                ),
              ),

              // SCAN STUDENT ATTENDANCE
              Card(
                child: ListTile(
                  leading: const Icon(Icons.how_to_reg),
                  title: const Text('Scan Student Attendance'),
                  subtitle: const Text(
                    'Scan matriculation QR if student does not have a phone',
                  ),
                  onTap: () =>
                      _openScanner(context, ScanMode.attendance),
                ),
              ),

              // SCAN EXAMINATION
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text('Scan Submission'),
                  subtitle: const Text(
                    'Scan student matric QR when receiving the answer script',
                  ),
                  onTap: () =>
                      _openScanner(context, ScanMode.submission),
                ),
              ),

              // ATTENDANCE LIST
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Student Attendance'),
                  subtitle: const Text('View student attendance'),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// PROFILE PAGE
// =====================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void showLogoutDialog(BuildContext context) { // Prevent accidental log out
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                // Return to the root first so no page stays stacked
                // above the AuthGate once the user is signed out.
                navigator.popUntil((route) => route.isFirst);
                FirebaseAuth.instance.signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        String field(String key) {
          final value = (data[key] ?? '').toString().trim();
          return value.isEmpty ? 'Not set' : value;
        }

        final isInvigilator = data['role'] == 'Invigilator';
        final name = field('fullName');
        final matric = (data['matricNo'] ?? '').toString().trim();
        final primaryEmail = (data['email'] ?? user.email ?? '').toString();

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () => showLogoutDialog(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Edit profile',
            child: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfilePage(
                    uid: user.uid,
                    secondaryEmail: (data['secondaryEmail'] ?? '').toString(),
                    phoneNumber: (data['phoneNumber'] ?? '').toString(),
                    primaryEmail: primaryEmail,
                  ),
                ),
              );
            },
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // PERSONAL QR (same as matric card).
                    Container(
                      width: 220,
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: matric.isEmpty
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 96,
                                  color: Colors.black38,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Personal QR\n(placeholder)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ],
                            )
                          : QrImageView(
                              data: 'studentId=$matric',
                              version: QrVersions.auto,
                            ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            InfoRow(
                              isInvigilator ? 'Staff ID' : 'Matric Number',
                              field('matricNo'),
                              flexTitle: 4,
                              flexValue: 6,
                            ),
                            const Divider(),
                            InfoRow(
                              'Faculty',
                              field('faculty'),
                              flexTitle: 4,
                              flexValue: 6,
                            ),
                            const Divider(),
                            InfoRow(
                              'Primary Email',
                              primaryEmail.isEmpty ? 'Not set' : primaryEmail,
                              flexTitle: 4,
                              flexValue: 6,
                            ),
                            const Divider(),
                            InfoRow(
                              'Secondary Email',
                              field('secondaryEmail'),
                              flexTitle: 4,
                              flexValue: 6,
                            ),
                            const Divider(),
                            InfoRow(
                              'Phone Number',
                              field('phoneNumber'),
                              flexTitle: 4,
                              flexValue: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// EDIT PROFILE PAGE (secondary email + phone only)
// =====================================================

class EditProfilePage extends StatefulWidget {
  final String uid;
  final String primaryEmail;
  final String secondaryEmail;
  final String phoneNumber;

  const EditProfilePage({
    super.key,
    required this.uid,
    required this.primaryEmail,
    required this.secondaryEmail,
    required this.phoneNumber,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController secondaryEmailController;
  late final TextEditingController phoneController;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    secondaryEmailController =
        TextEditingController(text: widget.secondaryEmail);
    phoneController = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void dispose() {
    secondaryEmailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> save() async {
    final secondaryEmail = secondaryEmailController.text.trim();
    final phone = phoneController.text.trim();

    if (secondaryEmail.isNotEmpty) {
      final emailOk =
          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(secondaryEmail);

      if (!emailOk) {
        showMessage('Please enter a valid secondary email address.');
        return;
      }

      if (secondaryEmail.toLowerCase() == widget.primaryEmail.toLowerCase()) {
        showMessage('Secondary email must be different from primary email.');
        return;
      }
    }

    if (phone.isNotEmpty) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final charsOk = RegExp(r'^\+?[0-9\s\-]+$').hasMatch(phone);

      if (!charsOk || digits.length < 8 || digits.length > 15) {
        showMessage('Please enter a valid phone number.');
        return;
      }
    }

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'secondaryEmail': secondaryEmail,
        'phoneNumber': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() => saving = false);
      showMessage('Could not update profile: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only your secondary email and phone number can be changed.',
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: secondaryEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Secondary Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +60123456789',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SHARED EXAM SESSION MODEL & FIRESTORE STREAM
// =====================================================
//
// Collection: examSessions/{sessionId}
//   courseCode, courseName, venue, date (Timestamp),
//   startTime, endTime
//
// This ONE collection feeds the Exam Sessions list,
// the QR code, the student scanner and My Examinations.
// The Firestore document ID is the session ID.
//

class ExamSession {
  final String sessionId;
  final String courseCode;
  final String courseName;
  final String venue;
  final DateTime? date; // null when missing / invalid in Firestore
  final String startTime;
  final String endTime;
  final int? registeredStudents; // optional field in Firestore

  const ExamSession({
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    required this.venue,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.registeredStudents,
  });

  factory ExamSession.fromData(String id, Map<String, dynamic> s) {
    final dateValue = s['date'];

    return ExamSession(
      sessionId: id,
      courseCode: (s['courseCode'] ?? '').toString(),
      courseName: (s['courseName'] ?? '').toString(),
      venue: (s['venue'] ?? '').toString(),
      date: dateValue is Timestamp ? dateValue.toDate() : null,
      startTime: (s['startTime'] ?? '').toString(),
      endTime: (s['endTime'] ?? '').toString(),
      registeredStudents: (s['registeredStudents'] as num?)?.toInt(),
    );
  }

  factory ExamSession.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ExamSession.fromData(doc.id, doc.data() ?? {});
  }

  String get title {
    if (courseCode.isNotEmpty && courseName.isNotEmpty) {
      return '$courseCode - $courseName';
    }
    return courseName.isNotEmpty ? courseName : courseCode;
  }

  DateTime? get day {
    final d = date;
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  /// Minutes after midnight of [startTime] / [endTime]; null if unparseable.
  /// Accepts "09:00", "9:00 AM", "9am".
  static int? _parseMinutes(String t) {
    final m = RegExp(r'^\s*(\d{1,2})(?::(\d{2}))?\s*([AaPp][Mm])?')
        .firstMatch(t);
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final ap = m.group(3)?.toLowerCase();
    if (ap == 'pm' && h < 12) h += 12;
    if (ap == 'am' && h == 12) h = 0;
    return h * 60 + min;
  }

  int get startMinutes => _parseMinutes(startTime) ?? 0;

  /// Moment the session ends (falls back to end of day if no end time).
  DateTime? get endsAt {
    final d = day;
    if (d == null) return null;
    final m = _parseMinutes(endTime);
    return m == null
        ? d.add(const Duration(days: 1))
        : d.add(Duration(minutes: m));
  }

  bool get isCompleted {
    final e = endsAt;
    return e != null && DateTime.now().isAfter(e);
  }

  bool get isToday {
    final d = day;
    final n = DateTime.now();
    return d != null && d == DateTime(n.year, n.month, n.day);
  }

  String get longDate {
    final d = date;
    if (d == null) return 'Date not set';
    return '${kWeekdays[d.weekday - 1]}, ${d.day} ${kMonths[d.month - 1]} ${d.year}';
  }

  String get formattedDate {
    final d = date;
    if (d == null) return 'Date not set';
    return '${d.day}/${d.month}/${d.year}';
  }

  String get formattedTime {
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      return '$startTime – $endTime';
    }
    if (startTime.isNotEmpty) return startTime;
    if (endTime.isNotEmpty) return endTime;
    return 'Time not set';
  }
}

class ExamSessionsStreamBuilder extends StatelessWidget {
  final String emptyMessage;
  final String errorPrefix;
  final Widget Function(BuildContext context, List<ExamSession> sessions)
      builder;

  const ExamSessionsStreamBuilder({
    super.key,
    this.emptyMessage = 'No exam sessions available.',
    this.errorPrefix = 'Could not load exam sessions.',
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // No orderBy here: orderBy('date') would silently hide
      // documents that have no date. Callers sort in Dart instead.
      stream:
          FirebaseFirestore.instance.collection('examSessions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '$errorPrefix\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(emptyMessage, textAlign: TextAlign.center),
            ),
          );
        }

        final sessions = docs.map((doc) => ExamSession.fromDoc(doc)).toList();
        return builder(context, sessions);
      },
    );
  }
}

// =====================================================
// SHARED TEXT STYLES (one look for every exam list)
// =====================================================

const List<String> kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

const List<String> kWeekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
  'Sunday',
];

// Section header: "Today", "Upcoming", "Completed", "Mon, 5 Jan 2026"
const TextStyle kSectionStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: kInk,
);

// Sub header: time-slot label
const TextStyle kSubSectionStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: kSlate,
);

// Main line on a card: course code
const TextStyle kCardTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: kInk,
);

// Detail lines on a card: date, time, hall, students
const TextStyle kCardMetaStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: kSlate,
);

/// A small "icon + text" detail line used on exam cards.
class ExamMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const ExamMetaRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kSlate),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: kCardMetaStyle)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  final TextStyle style;

  const SectionHeader(this.text, {super.key, this.style = kSectionStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: style),
    );
  }
}

// =====================================================
// STUDENT: MY EXAMINATIONS (Today / Upcoming / Completed)
// =====================================================

class StudentExamsPage extends StatelessWidget {
  const StudentExamsPage({super.key});

  int _compare(ExamSession a, ExamSession b) {
    final ad = a.day;
    final bd = b.day;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    final c = ad.compareTo(bd);
    return c != 0 ? c : a.startMinutes.compareTo(b.startMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Examinations')),
      body: ExamSessionsStreamBuilder(
        emptyMessage: 'No examination sessions scheduled.',
        errorPrefix: 'Could not load examinations.',
        builder: (context, sessions) {
          final today = <ExamSession>[];
          final upcoming = <ExamSession>[];
          final completed = <ExamSession>[];

          for (final s in sessions) {
            if (s.date == null) continue; // cannot be placed in time
            if (s.isToday) {
              today.add(s);
            } else if (s.isCompleted) {
              completed.add(s);
            } else {
              upcoming.add(s);
            }
          }

          today.sort(_compare);
          upcoming.sort(_compare);
          // Most recently finished first.
          completed.sort((a, b) => _compare(b, a));

          final children = <Widget>[];

          void addSection(String label, List<ExamSession> list,
              {bool dimmed = false}) {
            if (list.isEmpty) return;
            children.add(SectionHeader(label));
            for (final s in list) {
              children.add(_examCard(s, dimmed: dimmed));
            }
          }

          addSection('Today', today);
          addSection('Upcoming', upcoming);
          addSection('Completed', completed, dimmed: true);

          if (children.isEmpty) {
            return const Center(child: Text('No examinations to show.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: children,
          );
        },
      ),
    );
  }

  Widget _examCard(ExamSession s, {bool dimmed = false}) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.courseCode.isEmpty ? s.courseName : s.courseCode,
                  style: kCardTitleStyle),
              if (s.courseCode.isNotEmpty && s.courseName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(s.courseName, style: kCardMetaStyle),
                ),
              ExamMetaRow(
                icon: Icons.calendar_today_outlined,
                text: s.formattedDate,
              ),
              ExamMetaRow(
                icon: Icons.access_time,
                text: s.formattedTime,
              ),
              ExamMetaRow(
                icon: Icons.location_on_outlined,
                text: s.venue.isEmpty ? 'Hall not set' : s.venue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// EXAM SESSIONS LIST (invigilator)
// =====================================================
//
// Grouped by date, then by time slot.
// Tapping an UPCOMING session shows its attendance QR code.
//

class ExamSessionsPage extends StatelessWidget {
  final String title;
  final IconData trailingIcon;

  const ExamSessionsPage({
    super.key,
    this.title = 'Exam Sessions',
    this.trailingIcon = Icons.qr_code,
  });

  int _compare(ExamSession a, ExamSession b) {
    final c = a.day!.compareTo(b.day!);
    return c != 0 ? c : a.startMinutes.compareTo(b.startMinutes);
  }

  String _dayLabel(DateTime d) =>
      '${kWeekdays[d.weekday - 1]}, ${d.day} ${kMonths[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ExamSessionsStreamBuilder(
        builder: (context, sessions) {
          final dated = sessions.where((s) => s.date != null).toList();
          final undated = sessions.where((s) => s.date == null).toList();

          final upcoming = dated.where((s) => !s.isCompleted).toList()
            ..sort(_compare);
          final past = dated.where((s) => s.isCompleted).toList()
            ..sort(_compare);

          final children = <Widget>[];

          void addGroup(List<ExamSession> list, {required bool isPast}) {
            DateTime? lastDay;
            String? lastSlot;

            for (final s in list) {
              if (s.day != lastDay) {
                children.add(SectionHeader(_dayLabel(s.day!)));
                lastDay = s.day;
                lastSlot = null;
              }

              if (s.formattedTime != lastSlot) {
                children.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(s.formattedTime, style: kSubSectionStyle),
                  ),
                );
                lastSlot = s.formattedTime;
              }

              children.add(_sessionCard(context, s, isPast: isPast));
            }
          }

          addGroup(upcoming, isPast: false);

          if (past.isNotEmpty) {
            children.add(const SectionHeader('Completed sessions'));
            addGroup(past, isPast: true);
          }

          if (undated.isNotEmpty) {
            children.add(const SectionHeader('Date not set'));
            for (final s in undated) {
              children.add(_sessionCard(context, s, isPast: false));
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: children,
          );
        },
      ),
    );
  }

  Widget _sessionCard(BuildContext context, ExamSession s,
      {required bool isPast}) {
    // Only upcoming sessions open the QR.
    final enabled = !isPast;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: !enabled
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExamQRPage(session: s),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title, style: kCardTitleStyle),
                      ExamMetaRow(
                        icon: Icons.access_time,
                        text: s.formattedTime,
                      ),
                      ExamMetaRow(
                        icon: Icons.location_on_outlined,
                        text: s.venue.isEmpty ? 'Hall not set' : s.venue,
                      ),
                      _RegisteredStudents(session: s),
                    ],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 12),
                  Icon(trailingIcon),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Registered students: N" line.
/// Uses the session's `registeredStudents` number if it exists,
/// otherwise the number of users registered with role Student.
class _RegisteredStudents extends StatelessWidget {
  final ExamSession session;

  const _RegisteredStudents({required this.session});

  @override
  Widget build(BuildContext context) {
    final fixed = session.registeredStudents;

    if (fixed != null) {
      return ExamMetaRow(
        icon: Icons.people_outline,
        text: 'Registered students: $fixed',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .snapshots(),
      builder: (context, snapshot) {
        final text = snapshot.hasData
            ? 'Registered students: ${snapshot.data!.docs.length}'
            : 'Registered students: …';

        return ExamMetaRow(icon: Icons.people_outline, text: text);
      },
    );
  }
}

// =====================================================
// EXAM QR PAGE
// =====================================================
//
// The QR contains ONLY the session ID. Everything else
// is loaded from Firestore when scanned, so the QR cannot
// be forged with fake course/venue details.
//

class ExamQRPage extends StatelessWidget {
  final ExamSession session;

  const ExamQRPage({super.key, required this.session});

  String get qrData => 'sessionId=${session.sessionId}';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    final double qrSize = isWideScreen
        ? (screenWidth * 0.25).clamp(260.0, 340.0)
        : (screenWidth * 0.65).clamp(220.0, 280.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Exam QR Code')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Exam Session Active',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Students can scan this QR code to record attendance.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                if (isWideScreen)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildExamDetailsCard()),
                      const SizedBox(width: 40),
                      _buildQrSection(qrSize),
                    ],
                  )
                else ...[
                  _buildExamDetailsCard(),
                  const SizedBox(height: 30),
                  _buildQrSection(qrSize),
                ],
                const SizedBox(height: 30),

                // Live count of students who have checked in
                // (QR scans AND invigilator scans use the same collection).
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('attendance')
                      .where('sessionId', isEqualTo: session.sessionId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;

                    return Text(
                      'Students: $count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Attendance will appear here when students scan the QR.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              session.courseCode,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              session.courseName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Venue: ${session.venue}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Date: ${session.formattedDate}',
              textAlign: TextAlign.center,
            ),
            if (session.startTime.isNotEmpty ||
                session.endTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Time: ${session.formattedTime}',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Session ID: ${session.sessionId}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrSection(double qrSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: qrSize,
      ),
    );
  }
}

// =====================================================
// SHARED FIRESTORE WRITERS
// =====================================================
//
// attendance/{sessionId}_{studentId}
// examSubmissions/{sessionId}_{studentId}
//
// studentId is ALWAYS the matric / staff number, whether the
// student scanned the exam QR or the invigilator scanned the
// student's matric QR. The deterministic document ID prevents
// duplicates.
//

class RecordResult {
  final bool created; // false = it already existed
  final dynamic time; // Timestamp of the existing record, if any

  const RecordResult({required this.created, this.time});
}

Future<RecordResult> recordAttendance({
  required String sessionId,
  required String studentId,
  required String studentName,
  required String method, // 'Student QR' | 'Matriculation QR'
  String? recordedBy,
}) async {
  final ref = FirebaseFirestore.instance
      .collection('attendance')
      .doc('${sessionId}_$studentId');

  final existing = await ref.get();

  if (existing.exists) {
    return RecordResult(
      created: false,
      time: existing.data()?['checkInTime'],
    );
  }

  await ref.set({
    'sessionId': sessionId,
    'studentId': studentId,
    'studentName': studentName,
    'method': method,
    'recordedBy': recordedBy,
    'checkInTime': FieldValue.serverTimestamp(),
  });

  return const RecordResult(created: true);
}

Future<RecordResult> recordSubmission({
  required String sessionId,
  required String studentId,
  required String studentQrData,
  String? recordedBy,
}) async {
  final ref = FirebaseFirestore.instance
      .collection('examSubmissions')
      .doc('${sessionId}_$studentId');

  final existing = await ref.get();

  if (existing.exists) {
    return RecordResult(
      created: false,
      time: existing.data()?['submissionTime'],
    );
  }

  await ref.set({
    'sessionId': sessionId,
    'studentId': studentId,
    'studentQrData': studentQrData,
    'invigilatorId': recordedBy,
    'submissionTime': FieldValue.serverTimestamp(),
    'status': 'Submitted',
  });

  return const RecordResult(created: true);
}

// =====================================================
// SHARED UI PIECES
// =====================================================

class InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final int flexTitle;
  final int flexValue;

  const InfoRow(
    this.title,
    this.value, {
    super.key,
    this.flexTitle = 1,
    this.flexValue = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: flexTitle,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: flexValue,
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Camera view + square frame + instruction label.
class ScannerFrame extends StatelessWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final String message;
  final bool messageAtBottom;

  const ScannerFrame({
    super.key,
    required this.onDetect,
    required this.message,
    this.messageAtBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(onDetect: onDetect),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          top: messageAtBottom ? null : 30,
          bottom: messageAtBottom ? 50 : null,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}

String formatTimestamp(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate();

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  return 'Recorded just now';
}

// =====================================================
// STUDENT QR SCANNER
// =====================================================
//
// Student scans the exam QR (sessionId only). The session is
// loaded from Firestore; the student's name and matric number
// come from their profile.
//

class StudentQRScannerPage extends StatefulWidget {
  const StudentQRScannerPage({super.key});

  @override
  State<StudentQRScannerPage> createState() => _StudentQRScannerPageState();
}

class _StudentQRScannerPageState extends State<StudentQRScannerPage> {
  bool busy = false;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> handleQRCode(BarcodeCapture capture) async {
    if (busy) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null || value.isEmpty) continue;

      final sessionId = getQRValue(value, 'sessionId');

      if (sessionId == 'Unknown' ||
          sessionId.isEmpty ||
          sessionId.contains('/')) {
        continue;
      }

      busy = true;

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        busy = false;
        return;
      }

      try {
        // 1. Load the session from the database.
        final sessionDoc = await FirebaseFirestore.instance
            .collection('examSessions')
            .doc(sessionId)
            .get();

        if (!sessionDoc.exists) {
          if (!mounted) return;
          showMessage('Invalid exam QR code.');
          await Future.delayed(const Duration(seconds: 2));
          busy = false;
          return;
        }

        final session = ExamSession.fromDoc(sessionDoc);

        // 2. Load the student's profile (name + matric number).
        final profileDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final profile = profileDoc.data() ?? {};
        final matricNo = (profile['matricNo'] ?? '').toString().trim();
        final fullName = (profile['fullName'] ?? '').toString().trim();

        if (matricNo.isEmpty) {
          if (!mounted) return;
          showMessage('Your profile has no Student ID. Contact the admin.');
          await Future.delayed(const Duration(seconds: 2));
          busy = false;
          return;
        }

        // 3. Record attendance (duplicate-safe).
        final result = await recordAttendance(
          sessionId: sessionId,
          studentId: matricNo,
          studentName: fullName.isEmpty ? (user.email ?? 'Student') : fullName,
          method: 'Student QR',
          recordedBy: user.uid,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceSuccessPage(
              session: session,
              checkInTime: result.time,
              alreadyRecorded: !result.created,
            ),
          ),
        );
      } on FirebaseException catch (e) {
        busy = false;

        if (!mounted) return;
        showMessage('Could not record attendance: ${e.message}');
      }

      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Exam QR')),
      body: ScannerFrame(
        onDetect: handleQRCode,
        message: 'Place the examination QR code inside the box.',
        messageAtBottom: true,
      ),
    );
  }
}

// =====================================================
// ATTENDANCE SUCCESS PAGE (student)
// =====================================================

class AttendanceSuccessPage extends StatelessWidget {
  final ExamSession session;
  final dynamic checkInTime;
  final bool alreadyRecorded;

  const AttendanceSuccessPage({
    super.key,
    required this.session,
    required this.checkInTime,
    this.alreadyRecorded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Recorded')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Attendance Recorded',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              alreadyRecorded
                  ? 'You have already checked in for this exam.'
                  : 'Your examination check-in has been recorded.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    InfoRow('Course Code', session.courseCode),
                    const Divider(),
                    InfoRow('Course', session.courseName),
                    const Divider(),
                    InfoRow('Venue', session.venue),
                    const Divider(),
                    InfoRow('Session ID', session.sessionId),
                    const Divider(),
                    InfoRow('Check-in Time', formatTimestamp(checkInTime)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// INVIGILATOR SCANNER (attendance OR examination)
// =====================================================
//
// ScanMode.attendance  -> student has no phone; scan matric QR
//                         -> writes to attendance (same collection
//                            as the student's own scan).
// ScanMode.submission  -> scan matric QR when receiving the
//                         answer script -> examSubmissions.
//
// For now both only open the camera (no session is picked).
//

enum ScanMode { attendance, submission }

class InvigilatorScannerPage extends StatefulWidget {
  final ScanMode mode;

  const InvigilatorScannerPage({super.key, required this.mode});

  @override
  State<InvigilatorScannerPage> createState() => _InvigilatorScannerPageState();
}

class _InvigilatorScannerPageState extends State<InvigilatorScannerPage> {
  bool get isAttendance => widget.mode == ScanMode.attendance;

  // For now the scanner only opens the camera.
  void handleQRCode(BarcodeCapture capture) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAttendance ? 'Scan Student Attendance' : 'Scan Submission',
        ),
      ),
      body: ScannerFrame(
        onDetect: handleQRCode,
        message: isAttendance
            ? 'Place the student matriculation QR code inside the box.'
            : 'Place the student QR code inside the box.',
        messageAtBottom: true,
      ),
    );
  }
}

// =====================================================
// SCAN RESULT PAGE (invigilator)
// =====================================================

class ScanResultPage extends StatelessWidget {
  final ExamSession session;
  final String studentId;
  final ScanMode mode;
  final bool alreadyRecorded;
  final dynamic time;

  const ScanResultPage({
    super.key,
    required this.session,
    required this.studentId,
    required this.mode,
    required this.alreadyRecorded,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isAttendance = mode == ScanMode.attendance;

    final heading = isAttendance
        ? 'Student Attendance Recorded'
        : 'Answer Script Received';

    final subtitle = alreadyRecorded
        ? (isAttendance
            ? 'This student was already checked in for this session.'
            : 'This student\'s script was already recorded for this session.')
        : (isAttendance
            ? 'Attendance has been saved to the database.'
            : 'The student examination submission has been recorded.');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAttendance ? 'Attendance Recorded' : 'Examination Submitted',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              alreadyRecorded
                  ? Icons.info_outline
                  : (isAttendance
                      ? Icons.check_circle
                      : Icons.assignment_turned_in),
              size: 100,
              color: alreadyRecorded ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 20),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    InfoRow('Student ID', studentId),
                    const Divider(),
                    InfoRow('Session', session.title),
                    const Divider(),
                    InfoRow(
                      'Method',
                      isAttendance ? 'Matriculation QR' : 'Script submission',
                    ),
                    if (alreadyRecorded) ...[
                      const Divider(),
                      InfoRow('First recorded', formatTimestamp(time)),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Scan Next Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// QR HELPER FUNCTIONS
// =====================================================

String getQRValue(String qrData, String key) {
  final lines = qrData.split('\n');

  for (final rawLine in lines) {
    final line = rawLine.trim();

    if (line.startsWith('$key=')) {
      return line.substring(key.length + 1).trim();
    }
  }

  return 'Unknown';
}

// =====================================================
// STUDENT ID EXTRACTION
// =====================================================
//
// The matriculation QR may contain:
//
// studentId=ABC12345
// OR matricNo=ABC12345
// OR simply the matriculation number as the QR value.
//
// IDs are normalised to upper case so they always match the
// matricNo saved at registration.
//

String extractStudentId(String qrData) {
  final studentId = getQRValue(qrData, 'studentId');

  if (studentId != 'Unknown' && studentId.isNotEmpty) {
    return studentId.toUpperCase();
  }

  final matricNo = getQRValue(qrData, 'matricNo');

  if (matricNo != 'Unknown' && matricNo.isNotEmpty) {
    return matricNo.toUpperCase();
  }

  return qrData.trim().toUpperCase();
}

// =====================================================
// APP THEME (Inter, iOS-style minimalist)
// =====================================================

const Color kCanvas = Color(0xFFF5F6F8);
const Color kInk = Color(0xFF1F2937);
const Color kSlate = Color(0xFF6B7280);
const Color kBlue = Color(0xFF3B82F6);
const Color kTeal = Color(0xFF14B8A6);
const Color kPurple = Color(0xFF8B5CF6);
const Color kAmber = Color(0xFFF59E0B);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
  );

  return base.copyWith(
    scaffoldBackgroundColor: kCanvas,
    textTheme: base.textTheme.apply(
      bodyColor: kInk,
      displayColor: kInk,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCanvas,
      foregroundColor: kInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}