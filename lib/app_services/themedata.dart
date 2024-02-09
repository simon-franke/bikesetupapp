import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    primaryColor: const Color(0xFF4D7EA8),
    scaffoldBackgroundColor: const Color(0xFFE7EEEB),
    cardTheme: const CardTheme(color: Color(0xFF8EAFB6)),
    appBarTheme: const AppBarTheme(
        elevation: 0,
        color: Color(0xFF4D7EA8),
        iconTheme: IconThemeData(color: Colors.white)),
    cardColor: const Color(0xFF3A546D), //Positioned Circles
    iconTheme: IconThemeData(color: Colors.grey[800]),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontSize: 22),
      titleMedium: TextStyle(color: Colors.white, fontSize: 18),
      titleSmall: TextStyle(color: Colors.white, fontSize: 14),
      bodyLarge: TextStyle(color: Color(0xFF424242), fontSize: 18),
      bodyMedium: TextStyle(color: Color(0xFF424242), fontSize: 16),
      bodySmall: TextStyle(color: Color(0xFF424242), fontSize: 14),
      labelLarge: TextStyle(color: Color(0xFF424242), fontSize: 22),
      labelMedium: TextStyle(color: Color(0xFF424242), fontSize: 20),
      labelSmall: TextStyle(color: Color(0xFF424242), fontSize: 16),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFF4A259),
    ),
    dividerColor: Colors.transparent,
  );

  static final ThemeData darkTheme = ThemeData(
      primaryColor: const Color(0xFF4D7EA8),
      scaffoldBackgroundColor: const Color(0xFF272932),
      cardTheme: const CardTheme(color: Color(0xFF3A546D)),
      appBarTheme: const AppBarTheme(
          elevation: 0,
          color: Color(0xFF4D7EA8),
          iconTheme: IconThemeData(color: Colors.white)),
      cardColor: const Color(0xFF8EAFB6), //Positioned Circles
      iconTheme: const IconThemeData(color: Colors.white),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 22),
        titleMedium: TextStyle(color: Colors.white, fontSize: 18),
        titleSmall: TextStyle(color: Colors.white, fontSize: 14),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
        bodySmall: TextStyle(color: Colors.white, fontSize: 14),
        labelLarge: TextStyle(color: Colors.white, fontSize: 22),
        labelMedium: TextStyle(color: Colors.white, fontSize: 20),
        labelSmall: TextStyle(color: Colors.white, fontSize: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFF4A259),
      ),
      dividerColor: Colors.transparent);
}
