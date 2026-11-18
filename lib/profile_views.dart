// ProfilePage, EditProfilePage

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'services.dart';
import 'viewmodels.dart';
import 'shared.dart';

// =====================================================
// PROFILE PAGE
// =====================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void showLogoutDialog(BuildContext context) {
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
                ProfileViewModel(AuthService(), UserService()).logout();
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
    final vm = ProfileViewModel(AuthService(), UserService());
    final uid = vm.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: vm.profile,
      builder: (context, snapshot) {
        final data = snapshot.data;

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
        final primaryEmail = (data['email'] ?? vm.currentEmail).toString();

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
                    uid: uid,
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

  late final ProfileViewModel vm;
  bool get saving => vm.saving;

  @override
  void initState() {
    super.initState();
    vm = ProfileViewModel(AuthService(), UserService());
    vm.addListener(() {
      if (mounted) setState(() {});
    });
    secondaryEmailController =
        TextEditingController(text: widget.secondaryEmail);
    phoneController = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void dispose() {
    secondaryEmailController.dispose();
    phoneController.dispose();
    vm.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> save() async {
    final ok = await vm.saveContact(
      secondaryEmail: secondaryEmailController.text,
      phone: phoneController.text,
      primaryEmail: widget.primaryEmail,
    );
    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } else {
      showMessage(vm.message!);
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
