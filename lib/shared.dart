// Shared UI for all screens

import 'package:flutter/material.dart';

// =====================================================
// SHARED UI PIECES
// =====================================================

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

// =====================================================
// APP THEME (Inter, iOS-style minimalist)
// =====================================================

const Color kCanvas = Color(0xFFF5F6F8);
const Color kInk = Color(0xFF1F2937);
const Color kSlate = Color(0xFF6B7280);
const Color kBlue = Color(0xFF3B82F6);
const Color kTeal = Color(0xFF14B8A6);
const Color kPurple = Color(0xFF8B5CF6);
const Color kAmber = Color(0xFFF59E0B);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kBlue),
  );

  return base.copyWith(
    scaffoldBackgroundColor: kCanvas,
    textTheme: base.textTheme.apply(
      bodyColor: kInk,
      displayColor: kInk,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCanvas,
      foregroundColor: kInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: kInk,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
