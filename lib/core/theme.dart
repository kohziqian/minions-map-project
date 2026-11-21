import 'package:flutter/material.dart';

// APP THEME
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

// TEXT STYLES
// Section header: "Today", "Upcoming", "Completed", "Mon, 5 Jan 2026"
const TextStyle kSectionStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: kInk,
);

// Sub header: time-slot label
const TextStyle kSubSectionStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: kSlate,
);

// Main line on a card: course code
const TextStyle kCardTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: kInk,
);

// Detail lines on a card: date, time, hall, students
const TextStyle kCardMetaStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: kSlate,
);
