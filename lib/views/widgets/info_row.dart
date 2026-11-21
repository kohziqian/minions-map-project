import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final int flexTitle;
  final int flexValue;

  const InfoRow(
    this.title,
    this.value, {
    super.key,
    this.flexTitle = 1,
    this.flexValue = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: flexTitle,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: flexValue,
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
