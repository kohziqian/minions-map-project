import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/attendance_service.dart';
import 'services/auth_service.dart';
import 'services/exam_service.dart';
import 'services/user_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/exam_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/scanner_viewmodel.dart';
import 'viewmodels/session_viewmodel.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ExamGuardApp());
}

class ExamGuardApp extends StatelessWidget {
  const ExamGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services (Firebase access)
        Provider<UserService>(create: (_) => UserService()),
        Provider<AuthService>(
          create: (ctx) => AuthService(ctx.read<UserService>()),
        ),
        Provider<ExamService>(create: (_) => ExamService()),
        Provider<AttendanceService>(create: (_) => AttendanceService()),

        // ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          lazy: false,
          create: (ctx) => AuthViewModel(ctx.read<AuthService>()),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          lazy: false,
          create: (ctx) => ProfileViewModel(
            ctx.read<UserService>(),
            ctx.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<SessionViewModel>(
          lazy: false,
          create: (ctx) => SessionViewModel(
            ctx.read<ExamService>(),
            ctx.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<ExamViewModel>(
          create: (ctx) => ExamViewModel(ctx.read<AttendanceService>()),
        ),
        ChangeNotifierProvider<ScannerViewModel>(
          create: (ctx) => ScannerViewModel(
            auth: ctx.read<AuthService>(),
            users: ctx.read<UserService>(),
            exams: ctx.read<ExamService>(),
            attendance: ctx.read<AttendanceService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ExamGuard',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
