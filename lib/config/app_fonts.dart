import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Example of applying Google Fonts to your entire app
///
/// Usage in main.dart:
/// ```dart
/// MaterialApp(
///   theme: AppFonts.lightTheme,
///   darkTheme: AppFonts.darkTheme,
/// )
/// ```

class AppFonts {
  // Define your app's text theme with Google Fonts
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles (largest)
      displayLarge: GoogleFonts.poppins(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 48,
        fontWeight: FontWeight.w400,
      ),

      // Headline styles
      headlineLarge: GoogleFonts.poppins(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w400,
      ),

      // Title styles (app bars, dialogs)
      titleLarge: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),

      // Body styles (main content)
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),

      // Label styles (buttons, inputs)
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      ),
    );
  }

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      textTheme: textTheme,
      brightness: Brightness.light,
      useMaterial3: true,
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      textTheme: textTheme,
      brightness: Brightness.dark,
      useMaterial3: true,
    );
  }
}

/// Example usage in your widgets:
/// 
/// ```dart
/// // AppBar title
/// Text('FreeFilms', style: Theme.of(context).textTheme.titleLarge)
/// 
/// // Section headers
/// Text('New Movies', style: Theme.of(context).textTheme.headlineSmall)
/// 
/// // Movie titles
/// Text(movie.title, style: Theme.of(context).textTheme.titleMedium)
/// 
/// // Descriptions
/// Text(movie.description, style: Theme.of(context).textTheme.bodyMedium)
/// 
/// // Buttons
/// Text('Watch Now', style: Theme.of(context).textTheme.labelLarge)
/// ```
