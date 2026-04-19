import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Muted earthy palette: olive, moss, and dark khaki
  static const Color wikilocGreen = Color(0xFF5E6B3E);
  static const Color darkGreen = Color(0xFF323A23);
  static const Color mossGreen = Color(0xFF77835A);
  static const Color darkKhaki = Color(0xFF8C8862);
  static const Color backgroundGrey = Color(0xFFF1F0E7);
  static const Color surfaceOlive = Color(0xFFE8E5D6);
  static const Color surfaceMoss = Color(0xFFDAD7C3);
  static const Color textBlack = Color(0xFF2F3526);
  static const Color textGrey = Color(0xFF6D7359);
  static const Color errorClay = Color(0xFF7A5F45);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGrey,
      dividerColor: surfaceMoss,
      
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: textBlack,
        displayColor: textBlack,
      ),

      colorScheme: ColorScheme.light(
        primary: wikilocGreen,
        secondary: mossGreen,
        tertiary: darkKhaki,
        surface: surfaceOlive,
        onPrimary: backgroundGrey,
        onSurface: textBlack,
        error: errorClay,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceOlive,
        foregroundColor: wikilocGreen,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w800,
          color: wikilocGreen,
          fontFamily: 'Nunito',
        ),
        iconTheme: IconThemeData(color: wikilocGreen),
      ),

      // Kart Teması
      cardTheme: CardThemeData(
        color: surfaceOlive,
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: surfaceMoss),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: wikilocGreen,
          foregroundColor: backgroundGrey,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: darkKhaki,
        contentTextStyle: TextStyle(color: backgroundGrey),
      ),
    );
  }
}