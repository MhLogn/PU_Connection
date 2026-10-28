import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class AppTheme {
  /// Trả về ImageProvider an toàn tương thích cả URL mạng (http/https), Local File (FileImage) lẫn Data URI (base64)
  static ImageProvider? imageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    if (clean.startsWith('data:image/')) {
      try {
        final base64Part = clean.split(',').last;
        return MemoryImage(base64Decode(base64Part));
      } catch (_) {
        return null;
      }
    }
    if (clean.startsWith('/') ||
        clean.contains(r':\') ||
        clean.contains(':/') ||
        clean.startsWith('file://')) {
      try {
        final filePath = clean.replaceFirst('file://', '');
        final file = File(filePath);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }
    return NetworkImage(clean);
  }

  // =========================================================================
  // Classic Modern Design System - Palette & Surfaces
  // Primary Blue: #1976D2 | Deep Blue: #123B63 | Trắng: #FFFFFF | Nền sáng: #F5F7FA | Cam điểm nhấn: #F28C28
  // =========================================================================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color deepBlue = Color(0xFF123B63);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color canvasLight = backgroundLight;
  static const Color orangeAccent = Color(0xFFF28C28);
  static const Color accentOrange = orangeAccent;

  // Tints & Sub-containers
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color blueSubtle = Color(0xFFF0F7FF);
  static const Color orangeLight = Color(0xFFFFF3E0);
  static const Color orangeSubtle = Color(0xFFFFF8E1);

  // Tương thích ngược với các widget đang gọi tên cũ
  static const Color oceanBlue = primaryBlue;
  static const Color oceanBlueDark = deepBlue;
  static const Color oceanBlueLight = blueLight;
  static const Color oceanBlueSubtle = blueSubtle;
  static const Color navyBlue = deepBlue;

  // Typography & Borders - Classic Modern
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEDF2F7);

  // Dark Mode Surfaces (Sâu lắng, thanh lịch, tương phản chuẩn Classic Modern)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF273549);
  static const Color borderDark = Color(0xFF334155);

  static const Color darkPrimaryBlue = Color(0xFF42A5F5);
  static const Color darkOrangeAccent = Color(0xFFFB923C);
  static const Color darkOrangeContainer = Color(0xFF3A1C08);
  static const Color darkBlueContainer = Color(0xFF102A45);

  // Classic Modern Linear & Gradient References (Hạn chế tối đa dùng gradient, chỉ dùng khi cần thiết)
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF2196F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanToOrangeGradient = LinearGradient(
    colors: [primaryBlue, orangeAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orangeAccent, Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const SweepGradient storyRingGradient = SweepGradient(
    colors: [primaryBlue, deepBlue, primaryBlue],
  );

  // Curated Harmonic Accents
  static const Color emeraldMint = Color(0xFF059669);
  static const Color darkEmeraldMint = Color(0xFF34D399);

  static const Color softViolet = Color(0xFF7C3AED);
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

  static Color deepBlueColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF90CAF9) : deepBlue;

  static Color accentColor(BuildContext context) =>
      isDark(context) ? darkOrangeAccent : orangeAccent;

  static Color blueContainer(BuildContext context) =>
      isDark(context) ? darkBlueContainer : blueLight;

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
      // AppBar Classic Modern: Nền trắng tinh khiết, chữ Deep Blue, đường viền mỏng thanh lịch
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: deepBlue,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: deepBlue,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderLight, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight, width: 0.9),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderLight, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: coralRose, width: 1.0),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: textMuted),
        hintStyle: const TextStyle(fontSize: 14, color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: borderLight, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        elevation: 0,
        height: 64,
        indicatorColor: blueLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textMuted,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: borderLight, width: 0.8),
        backgroundColor: white,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: orangeAccent,
        foregroundColor: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),
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
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDark, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark, width: 0.9),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkPrimaryBlue, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white70),
        hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimaryBlue,
          side: const BorderSide(color: borderDark, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        elevation: 0,
        height: 64,
        indicatorColor: darkPrimaryBlue.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkPrimaryBlue,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: borderDark, width: 0.8),
        backgroundColor: surfaceDark,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: darkOrangeAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimaryBlue,
      ),
    );
  }
}
