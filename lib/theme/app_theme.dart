import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData ligthTheme = ThemeData(
    primaryColor: const Color(0xFF222222),
    scaffoldBackgroundColor: const Color.fromARGB(255, 34, 34, 34),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F2F2),
      foregroundColor: Color(0xFF262626),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF262626),
        foregroundColor: const Color(0xFFF2F2F2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 230, 209, 28),
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFF2F2F2)),
      bodySmall: TextStyle(color: Color(0xFFF2F2F2)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF262626),
      selectedItemColor: Color.fromARGB(255, 230, 209, 28),
      unselectedItemColor: Color(0xFF888888),
      unselectedLabelStyle: TextStyle(color: Color(0xFF262626)),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF2F2F2),
        side: const BorderSide(color: Color(0xFFF2F2F2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
