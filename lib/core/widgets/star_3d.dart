import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// A 3-D cartoon-style star icon matching the visual language of GameButton.
///
/// Renders a stacked shadow-and-face pair: a dark "base" star offset
/// downward, with the face star on top — giving a raised, physical feel.
///
/// Defaults to gold. Pass [color] and [shadowColor] for medal variants
/// (bronze, silver).
class Star3d extends StatelessWidget {
  const Star3d({
    super.key,
    this.size = 28,
    this.color = AppColors.gold,
    this.shadowColor = const Color(0xFFB8860B),
  });

  /// Diameter of the star in logical pixels.
  final double size;

  /// Face colour of the star.
  final Color color;

  /// Shadow / base colour of the star (the 3-D bottom layer).
  final Color shadowColor;

  static const double _shadowOffset = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + _shadowOffset,
      child: Stack(
        children: [
          // Base / shadow star (3-D bottom layer)
          Positioned(
            top: _shadowOffset,
            left: 0,
            child: Icon(Icons.star_rounded, color: shadowColor, size: size),
          ),
          // Face star (top layer)
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              Icons.star_rounded,
              color: color,
              size: size,
              shadows: const [
                Shadow(
                  color: Color(0x55FFFFFF),
                  offset: Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
