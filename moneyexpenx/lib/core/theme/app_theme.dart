import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Colors
  static const Color blackBg = Color(0xFF09090B);
  static const Color cardBg = Color(0xFF18181B);
  static const Color primaryYellow = Color(0xFFFFD700); // Yellow gold
  static const Color secondaryYellow = Color(0xFFFFE054);
  static const Color textPrimary = Color(0xFFF4F4F5);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: blackBg,
      primaryColor: primaryYellow,
      cardColor: cardBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        secondary: secondaryYellow,
        background: blackBg,
        surface: cardBg,
        error: alertRed,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.beVietnamPro(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.beVietnamPro(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.beVietnamPro(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.beVietnamPro(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryYellow,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
