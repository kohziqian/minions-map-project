import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_viewmodel.dart';

import 'login_page.dart';
import 'role_gate.dart';

// Cached login: Firebase restores the session on restart
// Signed out -> LoginPage
// Signed in -> RoleGate -> respective home page
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final initializing =
        context.select<AuthViewModel, bool>((vm) => vm.initializing); // select: only rebuild when these two values change,
    final uid = context.select<AuthViewModel, String?>((vm) => vm.uid);

    if (initializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (uid == null) {
      return const LoginPage();
    }

    return const RoleGate();
  }
}
