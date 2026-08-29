import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TifoTheme {
  static const Color darkBackground = Color(0xFF090D16);
  static const Color cardSurface = Color(0xFF131B2E);
  static const Color cardBorder = Color(0xFF1F2D4A);
  
  static const Color stadiumGreen = Color(0xFF00E676);
  static const Color stadiumCyan = Color(0xFF00E5FF);
  static const Color stadiumGold = Color(0xFFFFD700);
  static const Color alertRed = Color(0xFFFF1744);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: stadiumGreen,
        secondary: stadiumCyan,
        surface: cardSurface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: GoogleFonts.outfit(color: Colors.white70),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }
}
