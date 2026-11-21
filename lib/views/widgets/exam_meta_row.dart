import 'package:flutter/material.dart';

import '../../core/theme.dart';

// A small icon + text line on exam cards
class ExamMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const ExamMetaRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kSlate),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: kCardMetaStyle)),
        ],
      ),
    );
  }
}
