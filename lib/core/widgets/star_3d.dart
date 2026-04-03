import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// A 3-D cartoon-style star icon matching the visual language of GameButton.
///
/// Renders a stacked shadow-and-face pair: a dark-amber "base" star offset
/// downward, with the gold star face on top — giving a raised, physical feel.
class Star3d extends StatelessWidget {
  const Star3d({super.key, this.size = 28});

  /// Diameter of the star in logical pixels.
  final double size;

  static const double _shadowOffset = 3;
  static const Color _shadowColor = Color(0xFFB8860B); // dark goldenrod

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
            child: Icon(Icons.star_rounded, color: _shadowColor, size: size),
          ),
          // Face star (top layer, brighter gold)
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              Icons.star_rounded,
              color: AppColors.gold,
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
