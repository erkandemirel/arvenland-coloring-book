import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Arvenland marka paleti
  static const Color primary = Color(0xFFFF7A59); // coral
  static const Color secondary = Color(0xFF63B3FF); // sky
  static const Color accent = Color(0xFFFFD35C); // sunshine
  static const Color success = Color(0xFF6FD39B); // mint
  static const Color lavender = Color(0xFFA88BFF);
  static const Color pink = Color(0xFFFF8DB6);
  // Almost white with the barest warm tint — lets the soft rainbow overlay show.
  static const Color bgStart = Color(0xFFFFFDFB);
  static const Color bgEnd = Color(0xFFF7F9FF);

  // Very subtle rainbow wash used across full-page backgrounds.
  static const List<Color> softRainbowBg = [
    Color(0xFFFFF4F2), // whisper coral
    Color(0xFFFFF7EC), // whisper peach
    Color(0xFFFDFBEC), // whisper lemon
    Color(0xFFEEFBF3), // whisper mint
    Color(0xFFEDF6FF), // whisper sky
    Color(0xFFF3EEFF), // whisper lavender
    Color(0xFFFFF0F6), // whisper pink
  ];
  static const Color textDark = Color(0xFF3D3D5C);
  static const Color textSoft = Color(0xFF777799);

  static const List<Color> brandRainbow = [
    Color(0xFFFF7A59),
    Color(0xFFFFA24C),
    Color(0xFFFFD35C),
    Color(0xFF6FD39B),
    Color(0xFF63B3FF),
    Color(0xFFA88BFF),
    Color(0xFFFF8DB6),
  ];

  // Boya paleti — çocuk dostu, yüksek ayrışan tonlar
  static const List<Color> palette = [
    Color(0xFFFF5A5A),
    Color(0xFFFF7A59),
    Color(0xFFFFA24C),
    Color(0xFFFFD35C),
    Color(0xFFB6E33B),
    Color(0xFF6FD39B),
    Color(0xFF2EC4B6),
    Color(0xFF60D0E4),
    Color(0xFF63B3FF),
    Color(0xFF4D96FF),
    Color(0xFFA88BFF),
    Color(0xFFC084FC),
    Color(0xFFFF8DB6),
    Color(0xFF8B5E3C),
    Color(0xFF94A3B8),
    Color(0xFF3D3D5C),
    Color(0xFFFFFFFF),
  ];

  static TextTheme get _textTheme => GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge:
            GoogleFonts.nunito(fontWeight: FontWeight.w800, color: textDark),
        displayMedium:
            GoogleFonts.nunito(fontWeight: FontWeight.w800, color: textDark),
        displaySmall:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, color: textDark),
        headlineLarge:
            GoogleFonts.nunito(fontWeight: FontWeight.w800, color: textDark),
        headlineMedium:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, color: textDark),
        headlineSmall:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, color: textDark),
        titleLarge:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, color: textDark),
        titleMedium:
            GoogleFonts.nunito(fontWeight: FontWeight.w600, color: textDark),
        titleSmall:
            GoogleFonts.nunito(fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w500, color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w400, color: textDark, fontSize: 14),
        bodySmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w400, color: textSoft, fontSize: 12),
        labelLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: textDark, fontSize: 14),
        labelMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: textDark, fontSize: 12),
        labelSmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: textSoft, fontSize: 10),
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: Colors.white,
        ),
        textTheme: _textTheme,
        scaffoldBackgroundColor: bgStart,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: textDark,
          titleTextStyle: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textDark,
            letterSpacing: 0.3,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          labelStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

