import 'package:flutter/material.dart';

abstract final class AdminTheme {
  static const brand = Color(0xFF0875CE);
  static const brandDark = Color(0xFF0875CE);
  static const brandActive = Color(0xFF0875CE);
  static const success = Color(0xFF007A59);
  static const brandSoft = Color(0xFFEAF4FD);
  static const canvas = Color(0xFFF6F6F7);
  static const surface = Colors.white;
  static const border = Color(0xFFD7D7DA);
  static const tableHeader = Color(0xFFF6F6F7);
  static const textMuted = Color(0xFF626269);

  static ThemeData get data => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: brand, surface: surface),
    useMaterial3: true,
    scaffoldBackgroundColor: canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: brandDark,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: brand, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
