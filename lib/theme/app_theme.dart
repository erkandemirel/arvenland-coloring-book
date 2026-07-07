import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana renkler — çocuklar için araştırma destekli pastel ton
  static const Color primary = Color(0xFFFF8066);     // soft coral
  static const Color secondary = Color(0xFF74B9FF);   // sky blue
  static const Color accent = Color(0xFFFFD166);      // warm yellow
  static const Color success = Color(0xFF6BCB77);     // mint green
  static const Color bgStart = Color(0xFFFFFFFF);     // beyaz
  static const Color bgEnd = Color(0xFFF4F4F6);       // çok açık gri
  static const Color textDark = Color(0xFF3D3D5C);    // dark navy-purple (daha soft than #333)

  // Boya paleti — pastel ve soft tonlar
  static const List<Color> palette = [
    Color(0xFFFF6B6B), // soft coral red
    Color(0xFFF472B6), // rose pink
    Color(0xFFFF8C42), // soft orange
    Color(0xFFFFD166), // warm yellow
    Color(0xFF6BCB77), // mint green
    Color(0xFF2EC4B6), // teal
    Color(0xFF74B9FF), // sky blue
    Color(0xFF4D96FF), // medium blue
    Color(0xFFA78BFA), // soft lavender
    Color(0xFFC084FC), // soft purple
    Color(0xFFC4956A), // warm brown
    Color(0xFF94A3B8), // blue-grey
    Color(0xFF3D3D5C), // dark navy (siyah yerine)
    Color(0xFFFFFFFF), // white
    Color(0xFFA8E6CF), // light mint
    Color(0xFFFFB3B3), // baby pink
  ];

  static TextTheme get _textTheme => GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w800, color: textDark),
        displayMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w800, color: textDark),
        displaySmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: textDark),
        headlineLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w800, color: textDark),
        headlineMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: textDark),
        headlineSmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: textDark),
        titleLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: textDark),
        titleMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: textDark),
        titleSmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w500, color: textDark, fontSize: 16),
        bodyMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w400, color: textDark, fontSize: 14),
        bodySmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w400, color: Color(0xFF6B6B8A), fontSize: 12),
        labelLarge: GoogleFonts.nunito(
            fontWeight: FontWeight.w700, color: textDark, fontSize: 14),
        labelMedium: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: textDark, fontSize: 12),
        labelSmall: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: Color(0xFF6B6B8A), fontSize: 10),
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          secondary: secondary,
        ),
        textTheme: _textTheme,
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
