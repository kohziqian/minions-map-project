import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/scan_mode.dart';
import '../widgets/scanner_frame.dart';

// Invigilator scanner (attendance & examination)
// Not implemented yet: only open the camera
// Later sprint: add an InvigilatorScannerViewModel

class InvigilatorScannerPage extends StatefulWidget {
  final ScanMode mode;

  const InvigilatorScannerPage({super.key, required this.mode});

  @override
  State<InvigilatorScannerPage> createState() => _InvigilatorScannerPageState();
}

class _InvigilatorScannerPageState extends State<InvigilatorScannerPage> {
  bool get isAttendance => widget.mode == ScanMode.attendance;

  // For now the scanner only opens the camera.
  void handleQRCode(BarcodeCapture capture) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAttendance ? 'Scan Student Attendance' : 'Scan Submission',
        ),
      ),
      body: ScannerFrame(
        onDetect: handleQRCode,
        message: isAttendance
            ? 'Place the student matriculation QR code inside the box.'
            : 'Place the student QR code inside the box.',
        messageAtBottom: true,
      ),
    );
  }
}
