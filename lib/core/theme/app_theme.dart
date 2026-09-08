import 'package:flutter/material.dart';

class AppTheme {
  // Brand Identity Colors (Light Mode)
  static const Color primaryBlue = Color(0xFF203864);
  static const Color navyBlue = Color(0xFF203864);
  static const Color orangeAccent = Color(0xFFF76B1C);
  static const Color orangeLight = Color(0xFFFFF4EC);
  static const Color white = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Mode Specialized Colors (Luminous & High Readability)
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF162032);
  static const Color surfaceElevatedDark = Color(0xFF1E2C44);
  static const Color borderDark = Color(0xFF283955);

  static const Color darkPrimaryBlue = Color(0xFF60A5FA); // Sky Azure Blue
  static const Color darkOrangeAccent = Color(0xFFFB923C); // Warm Sunset Orange
  static const Color darkOrangeContainer = Color(0xFF3D2314);
  static const Color darkBlueContainer = Color(0xFF1B2E4B);

  // Curated Harmonic Accents (For tasteful categorization in both themes)
  static const Color emeraldMint = Color(0xFF059669);
  static const Color darkEmeraldMint = Color(0xFF34D399);

  static const Color softViolet = Color(0xFF6366F1);
  static const Color darkSoftViolet = Color(0xFFA78BFA);

  static const Color goldenAmber = Color(0xFFD97706);
  static const Color darkGoldenAmber = Color(0xFFFBBF24);

  static const Color coralRose = Color(0xFFDC2626);
  static const Color darkCoralRose = Color(0xFFF87171);

  // Helper Methods for Adaptive Theme Colors
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryColor(BuildContext context) =>
      isDark(context) ? darkPrimaryBlue : primaryBlue;

  static Color accentColor(BuildContext context) =>
      isDark(context) ? darkOrangeAccent : orangeAccent;

  static Color blueContainer(BuildContext context) =>
      isDark(context) ? darkBlueContainer : primaryBlue.withValues(alpha: 0.08);

  static Color orangeContainer(BuildContext context) =>
      isDark(context) ? darkOrangeContainer : orangeLight;

  static Color mintColor(BuildContext context) =>
      isDark(context) ? darkEmeraldMint : emeraldMint;

  static Color violetColor(BuildContext context) =>
      isDark(context) ? darkSoftViolet : softViolet;

  static Color amberColor(BuildContext context) =>
      isDark(context) ? darkGoldenAmber : goldenAmber;

  static Color coralColor(BuildContext context) =>
      isDark(context) ? darkCoralRose : coralRose;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: orangeAccent,
        surface: white,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        surfaceContainerLowest: backgroundLight,
        onPrimary: white,
        onSecondary: white,
        onSurface: textDark,
        outlineVariant: borderLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: textMuted),
        hintStyle: const TextStyle(fontSize: 14, color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        elevation: 2,
        height: 68,
        indicatorColor: primaryBlue.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryBlue);
          }
          return const TextStyle(fontSize: 12, color: textMuted);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: borderLight),
        backgroundColor: white,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orangeAccent,
        foregroundColor: white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: orangeAccent),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryBlue,
        secondary: darkOrangeAccent,
        surface: surfaceDark,
        surfaceContainerHighest: surfaceElevatedDark,
        surfaceContainerLowest: backgroundDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        outlineVariant: borderDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkPrimaryBlue, width: 1.8),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryBlue,
          side: const BorderSide(color: borderDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        height: 68,
        indicatorColor: darkPrimaryBlue.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkPrimaryBlue);
          }
          return const TextStyle(fontSize: 12, color: Colors.white60);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: borderDark),
        backgroundColor: surfaceDark,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkOrangeAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: darkOrangeAccent),
    );
  }
}
