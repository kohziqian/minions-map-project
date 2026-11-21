import 'package:flutter/material.dart';

import '../../core/theme.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  final TextStyle style;

  const SectionHeader(this.text, {super.key, this.style = kSectionStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: style),
    );
  }
}
