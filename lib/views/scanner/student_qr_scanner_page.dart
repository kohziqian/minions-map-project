import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/scanner_viewmodel.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/scanner_frame.dart';
import 'attendance_success_page.dart';

// Student scans the exam QR (contains session id)
 
class StudentQRScannerPage extends StatefulWidget {
  const StudentQRScannerPage({super.key});

  @override
  State<StudentQRScannerPage> createState() => _StudentQRScannerPageState();
}

class _StudentQRScannerPageState extends State<StudentQRScannerPage> {
  @override
  void initState() {
    super.initState();
    context.read<ScannerViewModel>().reset();
  }

  Future<void> _handleQRCode(
    BuildContext context,
    BarcodeCapture capture,
  ) async {
    final vm = context.read<ScannerViewModel>();

    final values = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .toList();

    final outcome = await vm.scanStudentQr(values);

    if (!context.mounted) return;

    switch (outcome.status) {
      case StudentScanStatus.ignored:
        return;

      case StudentScanStatus.invalidQr:
      case StudentScanStatus.noStudentId:
      case StudentScanStatus.error:
        showMessage(context, outcome.message!);

      case StudentScanStatus.success:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AttendanceSuccessPage(
              session: outcome.session!,
              checkInTime: outcome.result!.time,
              alreadyRecorded: !outcome.result!.created,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Exam QR')),
      body: ScannerFrame(
        onDetect: (capture) => _handleQRCode(context, capture),
        message: 'Place the examination QR code inside the box.',
        messageAtBottom: true,
      ),
    );
  }
}
