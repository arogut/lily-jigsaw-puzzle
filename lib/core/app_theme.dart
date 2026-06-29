import 'package:flutter/material.dart';

/// Application-wide color constants derived from the pastel design palette.
abstract final class AppColors {
  // ── Core palette ──────────────────────────────────────────────────────────

  /// Pastel pink — primary accent, pink buttons.
  static const Color pastelPink = Color(0xFFFA9AC1);

  /// Pastel pink shadow — 3-D base for pink buttons.
  static const Color pastelPinkShadow = Color(0xFFD96895);

  /// Sky blue — blue buttons, board background.
  static const Color skyBlue = Color(0xFF80D4F7);

  /// Sky blue shadow — 3-D base for blue buttons.
  static const Color skyBlueShadow = Color(0xFF4AAAD4);

  /// Mint green — green/confirm buttons.
  static const Color mintGreen = Color(0xFF99EEC4);

  /// Mint green shadow — 3-D base for mint buttons.
  static const Color mintGreenShadow = Color(0xFF55C990);

  /// Sunny yellow — yellow/highlight buttons.
  static const Color sunnyYellow = Color(0xFFFEE668);

  /// Sunny yellow shadow — 3-D base for yellow buttons.
  static const Color sunnyYellowShadow = Color(0xFFD4B830);

  // ── Additional colours ────────────────────────────────────────────────────

  /// Deep purple — text strokes, outlines.
  static const Color deepPurple = Color(0xFF5B2D8E);

  /// Medium purple — settings / secondary buttons.
  static const Color mediumPurple = Color(0xFF9B6DD4);

  /// Lavender — midpoint of background gradient.
  static const Color lavender = Color(0xFFCEB4F0);

  /// Baby pink — bottom of background gradient.
  static const Color babyPink = Color(0xFFFFCCE5);

  /// Red — quit / destructive actions.
  static const Color red = Color(0xFFFF7BAC);

  /// Dark red — shadow for red buttons.
  static const Color redShadow = Color(0xFFCC4480);

  /// Gold — star icons.
  static const Color gold = Color(0xFFFFD700);
}

/// Shared decoration constants.
abstract final class AppTheme {
  /// The standard three-stop background gradient used on most screens.
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.skyBlue, AppColors.lavender, AppColors.babyPink],
      stops: [0.0, 0.50, 1.0],
    ),
  );
}
