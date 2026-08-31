import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color mediumSeverity = Color(0xFFFFC107);
  static const Color highSeverity = Color(0xFFF44336);
  static const Color lowSeverity = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF1F8E9);
  static const Color cardColor = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: background,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.outfitTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // cardTheme: CardTheme(
      //   color: cardColor,
      //   elevation: 2,
      //   shadowColor: Colors.black.withOpacity(0.1),
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16),
      //   ),
      // ),
    );
  }
}
