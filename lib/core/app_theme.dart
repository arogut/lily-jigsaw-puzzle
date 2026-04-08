import 'package:flutter/material.dart';

/// Application-wide color constants.
abstract final class AppColors {
  /// Deep purple — used for text, strokes, and icon colors.
  static const Color deepPurple = Color(0xFF6A1B9A);

  /// Medium purple — used for back/settings buttons.
  static const Color mediumPurple = Color(0xFF9B59B6);

  /// Hot pink — used for seed color and accents.
  static const Color hotPink = Color(0xFFFF6B9D);

  /// Sky blue — top-left of background gradient.
  static const Color skyBlue = Color(0xFF87CEEB);

  /// Lavender — midpoint of background gradient.
  static const Color lavender = Color(0xFFB39DDB);

  /// Baby pink — bottom-right of background gradient.
  static const Color babyPink = Color(0xFFFFABD0);

  /// Green — easy difficulty and confirm buttons.
  static const Color green = Color(0xFF6BCB77);

  /// Dark green — shadow for green buttons.
  static const Color greenShadow = Color(0xFF3A9E48);

  /// Red — hard difficulty and error states.
  static const Color red = Color(0xFFFF6B6B);

  /// Dark red — shadow for red buttons.
  static const Color redShadow = Color(0xFFCC2222);

  /// Orange — medium difficulty buttons.
  static const Color orange = Color(0xFFFFAB40);

  /// Dark orange — shadow for orange buttons.
  static const Color orangeShadow = Color(0xFFCC7722);

  /// Blue — navigation buttons.
  static const Color blue = Color(0xFF4D96FF);

  /// Dark blue — shadow for blue buttons.
  static const Color blueShadow = Color(0xFF2460CC);

  /// Gold — star icons.
  static const Color gold = Color(0xFFFFD700);

  /// Amber — hint button.
  static const Color amber = Color(0xFFFFB300);
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
