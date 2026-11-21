import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../viewmodels/auth_viewmodel.dart';

import '../widgets/app_snackbar.dart';

// Register: full name, role, Student/Staff ID, faculty
// Authentication: primary email, password
// Everything is saved to users according to generated {uid}

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

  String selectedRole = AppUser.roleStudent;

  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    facultyController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final vm = context.read<AuthViewModel>();

    final ok = await vm.register(
      fullName: nameController.text,
      idNo: idController.text,
      faculty: facultyController.text,
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
    } else {
      showMessage(context, vm.error ?? 'Registration failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthViewModel>().loading;
    final isInvigilator = selectedRole == AppUser.roleInvigilator;

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
                DropdownMenuItem(
                  value: AppUser.roleStudent,
                  child: Text('Student'),
                ),
                DropdownMenuItem(
                  value: AppUser.roleInvigilator,
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
