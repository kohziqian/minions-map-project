import 'package:flutter/material.dart';

import '../exams/student_exams_page.dart';
import '../scanner/student_qr_scanner_page.dart';
import '../widgets/profile_icon_button.dart';

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
