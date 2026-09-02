import 'package:flutter/material.dart';

class AppTheme {
  static const Color navyBlue = Color(0xFF203864);
  static const Color orangeAccent = Color(0xFFF76B1C);
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color textDark = Color(0xFF1F2937);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: white,

      colorScheme: const ColorScheme.light(
        primary: navyBlue,
        secondary: orangeAccent,
        surface: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: textDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: navyBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navyBlue,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orangeAccent,
        foregroundColor: white,
        elevation: 4,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: orangeAccent,
      ),
    );
  }
}
