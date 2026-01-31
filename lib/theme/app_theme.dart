import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Colors.amber;
  static const Color accent = Colors.amberAccent;
  static const Color backgroundDark = Color.fromARGB(255, 7, 7, 7);
  static const Color surfaceDark = Color.fromARGB(255, 20, 20, 20);
  static const Color backgroundLight = Color.fromARGB(255, 241, 241, 241);
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        onPrimary: primary,
        seedColor: accent,
        brightness: Brightness.light,
        surface: surfaceLight,
        onSurface: const Color(0xFF0F172A),
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Color(0xFF334155)),
        bodyMedium: TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        onPrimary: primary,
        seedColor: primary,
        brightness: Brightness.dark,
        surface: surfaceDark,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
