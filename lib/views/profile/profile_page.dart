import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/qr_codec.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/info_row.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void showLogoutDialog(BuildContext context) {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthViewModel>();

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
                auth.logout();
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
    final vm = context.watch<ProfileViewModel>();
    final user = vm.profile;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String field(String value) {
      final v = value.trim();
      return v.isEmpty ? 'Not set' : v;
    }

    final matric = user.matricNo.trim();
    final primaryEmail = vm.primaryEmail;

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
              builder: (context) => EditProfilePage(user: user),
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
                // PERSONAL QR (same as matric card)
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
                          data: studentQrData(matric),
                          version: QrVersions.auto,
                        ),
                ),

                const SizedBox(height: 20),

                Text(
                  field(user.fullName),
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
                          user.isInvigilator ? 'Staff ID' : 'Matric Number',
                          field(user.matricNo),
                          flexTitle: 4,
                          flexValue: 6,
                        ),
                        const Divider(),
                        InfoRow(
                          'Faculty',
                          field(user.faculty),
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
                          field(user.secondaryEmail),
                          flexTitle: 4,
                          flexValue: 6,
                        ),
                        const Divider(),
                        InfoRow(
                          'Phone Number',
                          field(user.phoneNumber),
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
  }
}
