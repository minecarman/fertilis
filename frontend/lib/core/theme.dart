import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // colors
  static const Color wikilocGreen = Color(0xFF45A137);
  static const Color darkGreen = Color(0xFF2E6B24);
  static const Color backgroundGrey = Color(0xFFF7F9FC);
  static const Color textBlack = Color(0xFF2D3142);
  static const Color textGrey = Color(0xFF9095A7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGrey,
      
      textTheme: GoogleFonts.nunitoTextTheme().apply(
        bodyColor: textBlack,
        displayColor: textBlack,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
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
        color: Colors.white,
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: wikilocGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}