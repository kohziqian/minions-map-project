import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

import '../dashboard/invigilator_home_page.dart';
import '../dashboard/student_home_page.dart';

// Chooses the dashboard from the user's role in users using {uid}
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewModel>().profile;

    if (user == null) {
      // Allow the user to log out while waiting profile loads
      return Scaffold(
        appBar: AppBar(
          title: const Text('ExamGuard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthViewModel>().logout(),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user.isInvigilator) {
      return InvigilatorHomePage(userName: user.displayName);
    }

    return StudentHomePage(userName: user.displayName);
  }
}
