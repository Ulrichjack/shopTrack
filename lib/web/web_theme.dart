import 'package:flutter/material.dart';

/// Identité visuelle du portail web de test. Les couleurs de statut sont
/// réservées aux informations métier (stock disponible, rupture, erreur).
abstract final class WebPalette {
  static const ink = Color(0xFF142C31);
  static const pine = Color(0xFF174E46);
  static const mint = Color(0xFFBCE9D1);
  static const canvas = Color(0xFFE5EEE9);
  static const paper = Color(0xFFFFFFFF);
  static const soft = Color(0xFFD3E5DB);
  static const line = Color(0xFFB4CAC0);
  static const muted = Color(0xFF607773);
  static const amber = Color(0xFFE9AC55);
  static const danger = Color(0xFFA73D36);
}

ThemeData webTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WebPalette.pine,
    primary: WebPalette.pine,
    surface: WebPalette.paper,
    error: WebPalette.danger,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansWeb',
    scaffoldBackgroundColor: WebPalette.canvas,
    colorScheme: scheme,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 38,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: WebPalette.ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.18,
        fontWeight: FontWeight.w700,
        color: WebPalette.ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: WebPalette.ink,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: WebPalette.ink),
      bodyMedium: TextStyle(fontSize: 14, color: WebPalette.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WebPalette.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WebPalette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WebPalette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: WebPalette.pine, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WebPalette.pine,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
