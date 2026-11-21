import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../widgets/app_snackbar.dart';

// Only the secondary email&phone number can be changed

class EditProfilePage extends StatefulWidget {
  final AppUser user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController secondaryEmailController;
  late final TextEditingController phoneController;

  @override
  void initState() {
    super.initState();
    secondaryEmailController =
        TextEditingController(text: widget.user.secondaryEmail);
    phoneController = TextEditingController(text: widget.user.phoneNumber);
  }

  @override
  void dispose() {
    secondaryEmailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final vm = context.read<ProfileViewModel>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await vm.saveContact(
      secondaryEmail: secondaryEmailController.text,
      phone: phoneController.text,
    );

    if (!mounted) return;

    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } else {
      showMessage(context, vm.error ?? 'Could not update profile.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<ProfileViewModel>().loading;

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
