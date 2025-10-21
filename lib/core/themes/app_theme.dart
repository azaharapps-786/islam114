import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - Adaptive to light/dark mode
  static const Color primaryColor = Color(0xFF1A5C3A); // Dark Green
  static const Color secondaryColor = Color(0xFFD4AF37); // Gold
  static const Color surfaceColor = Color(0xFFF5F5F5);   // Light Surface
  static const Color cardColor = Colors.white;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black87,
    ),
    scaffoldBackgroundColor: const Color(0xFFE8F5E9), // Very light green
    // FIX: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: GoogleFonts.latoTextTheme().copyWith(
      displayLarge: GoogleFonts.lato(fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.lato(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.lato(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4CAF50), // Lighter green for dark mode
      secondary: secondaryColor,
      surface: Color(0xFF121212),
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1F0D), // Very dark green
    // FIX: Changed CardTheme to CardThemeData
    cardTheme: CardThemeData(
      color: const Color(0xFF1E2E1E),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.lato(fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.lato(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
  );
}