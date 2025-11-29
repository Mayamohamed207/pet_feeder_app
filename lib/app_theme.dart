import 'package:flutter/material.dart';

class AppTheme {
  static const Color oceanBlue = Color.fromARGB(255, 9, 173, 206); 
  static const Color deepOcean = Color.fromARGB(255, 34, 98, 121); 
  static const Color mintGreen = Color.fromARGB(255, 22, 186, 126); 
  static const Color darkOcean = Color(0xFF023E8A);
  static const Color lightMint = Color(0xFFCAFFF8);
  
  static const Color gradientStart = Color(0xFF00D4FF);
  static const Color gradientEnd = Color.fromARGB(255, 13, 174, 115);
  
  static ThemeData modernTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: oceanBlue, 
      brightness: Brightness.light,
      primary: oceanBlue,
      secondary: mintGreen,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: darkOcean,
      titleTextStyle: TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.w800,
        color: darkOcean,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 12,
      shadowColor: oceanBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        shadowColor: oceanBlue.withOpacity(0.5),
        textStyle: TextStyle(
          fontSize: 17, 
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ),
  );
  
  static BoxShadow neonGlow({Color? color}) {
    return BoxShadow(
      color: (color ?? oceanBlue).withOpacity(0.6),
      blurRadius: 20,
      spreadRadius: 2,
    );
  }
  
  static BoxDecoration oceanGradient({double opacity = 1.0}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          gradientStart.withOpacity(opacity),
          const Color.fromARGB(255, 13, 174, 115).withOpacity(opacity),
        ],
      ),
    );
  }
}