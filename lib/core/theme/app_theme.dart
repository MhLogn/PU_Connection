import 'package:flutter/material.dart';

class AppTheme {
  // Brand Identity Colors (Ocean Blue, White & Phenikaa Orange Accents)
  // Xanh nước biển (vibrant ocean azure - không quá đậm, tươi tắn như mạng xã hội hiện đại)
  static const Color oceanBlue = Color(0xFF0284C7); // Sky 600
  static const Color oceanBlueDark = Color(0xFF0369A1); // Sky 700
  static const Color oceanBlueLight = Color(0xFFE0F2FE); // Sky 100
  static const Color oceanBlueSubtle = Color(0xFFF0F9FF); // Sky 50

  // Tương thích ngược với các thành phần cũ
  static const Color primaryBlue = oceanBlue;
  static const Color navyBlue = oceanBlueDark;

  // Họa tiết cam tinh tế (Vibrant Phenikaa Sun Orange)
  static const Color orangeAccent = Color(0xFFFF7A00);
  static const Color orangeLight = Color(0xFFFFF7ED);
  static const Color orangeSubtle = Color(0xFFFFEDD5);

  // Trắng và bề mặt tinh giản chuẩn Social App (Threads / Instagram / X)
  static const Color white = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100

  // Dark Mode Specialized Colors (Sâu lắng & Tương phản cao)
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surfaceDark = Color(0xFF111827); // Gray 900
  static const Color surfaceElevatedDark = Color(0xFF1F2937); // Gray 800
  static const Color borderDark = Color(0xFF2E3A4E);

  static const Color darkPrimaryBlue = Color(0xFF38BDF8); // Electric Sky 400
  static const Color darkOrangeAccent = Color(0xFFFB923C); // Warm Tangerine 400
  static const Color darkOrangeContainer = Color(0xFF431407);
  static const Color darkBlueContainer = Color(0xFF0C4A6E);

  // Gradient Thương Hiệu Mạng Xã Hội Đẳng Cấp
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanToOrangeGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFFFF7A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF7A00), Color(0xFFFF9E44)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const SweepGradient storyRingGradient = SweepGradient(
    colors: [
      Color(0xFF0284C7),
      Color(0xFFFF7A00),
      Color(0xFF38BDF8),
      Color(0xFFFF9E44),
      Color(0xFF0284C7),
    ],
  );

  // Curated Harmonic Accents
  static const Color emeraldMint = Color(0xFF10B981);
  static const Color darkEmeraldMint = Color(0xFF34D399);

  static const Color softViolet = Color(0xFF8B5CF6);
  static const Color darkSoftViolet = Color(0xFFA78BFA);

  static const Color goldenAmber = Color(0xFFF59E0B);
  static const Color darkGoldenAmber = Color(0xFFFBBF24);

  static const Color coralRose = Color(0xFFEF4444);
  static const Color darkCoralRose = Color(0xFFF87171);

  // Helper Methods for Adaptive Theme Colors
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryColor(BuildContext context) =>
      isDark(context) ? darkPrimaryBlue : oceanBlue;

  static Color accentColor(BuildContext context) =>
      isDark(context) ? darkOrangeAccent : orangeAccent;

  static Color blueContainer(BuildContext context) =>
      isDark(context) ? darkBlueContainer : oceanBlueLight;

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
        primary: oceanBlue,
        secondary: orangeAccent,
        surface: white,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        surfaceContainerLowest: backgroundLight,
        onPrimary: white,
        onSecondary: white,
        onSurface: textDark,
        outlineVariant: borderLight,
      ),
      // AppBar hiện đại kiểu Threads / Instagram: Nền trắng sạch sẽ, viền mảnh, chữ slate đậm
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textDark,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: oceanBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: coralRose),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: textMuted),
        hintStyle: const TextStyle(fontSize: 14, color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: oceanBlue,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: oceanBlue,
          side: const BorderSide(color: borderLight, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        elevation: 0,
        height: 68,
        indicatorColor: oceanBlue.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: oceanBlue);
          }
          return const TextStyle(fontSize: 12, color: textMuted);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: borderLight),
        backgroundColor: white,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 10,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orangeAccent,
        foregroundColor: white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: oceanBlue),
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
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryBlue,
          side: const BorderSide(color: borderDark, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: borderDark),
        backgroundColor: surfaceDark,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkOrangeAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: darkPrimaryBlue),
    );
  }
}
