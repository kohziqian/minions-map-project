import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/qr_codec.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/profile_field_tile.dart';

// Profile Page
// Only the secondary email and phone number can be edited
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

                // Return to the root first so no page stays stacked above the AuthGate once the user is signed out.
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Personal QR containing matric no. on profile
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
                          data: studentQrData(matric),  // QR contains student matric no.
                          version: QrVersions.auto,
                        ),
                ),

                const SizedBox(height: 20),

                Text(
                  user.fullName.trim().isEmpty ? 'Not set' : user.fullName,
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
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        // ---- read-only ----
                        ProfileFieldTile(
                          icon: Icons.badge_outlined,
                          label: user.isInvigilator
                              ? 'Staff ID'
                              : 'Matric Number',
                          value: user.matricNo,
                        ),
                        const Divider(height: 1),
                        ProfileFieldTile(
                          icon: Icons.school_outlined,
                          label: 'Faculty',
                          value: user.faculty,
                        ),
                        const Divider(height: 1),
                        ProfileFieldTile(
                          icon: Icons.email_outlined,
                          label: 'Primary Email',
                          value: primaryEmail,
                        ),
                        const Divider(height: 1),

                        // editable (pen icon)
                        ProfileFieldTile(
                          icon: Icons.alternate_email,
                          label: 'Secondary Email',
                          value: user.secondaryEmail,
                          keyboardType: TextInputType.emailAddress, 
                          onSave: (value) async { // Turns value into editable
                            final ok = await vm.saveSecondaryEmail(value);
                            return ok ? null : vm.error;
                          },
                        ),
                        const Divider(height: 1),
                        ProfileFieldTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: user.phoneNumber,
                          keyboardType: TextInputType.phone,  
                          hint: 'e.g. +60123456789',
                          onSave: (value) async { // Turns value into editable
                            final ok = await vm.savePhone(value);
                            return ok ? null : vm.error;
                          },
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
