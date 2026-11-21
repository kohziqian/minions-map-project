import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Camera view + square frame + instruction label.
class ScannerFrame extends StatelessWidget {
  final void Function(BarcodeCapture capture) onDetect;
  final String message;
  final bool messageAtBottom;

  const ScannerFrame({
    super.key,
    required this.onDetect,
    required this.message,
    this.messageAtBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(onDetect: onDetect),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Positioned(
          top: messageAtBottom ? null : 30,
          bottom: messageAtBottom ? 50 : null,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
