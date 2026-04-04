import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// A 3-D cartoon-style star icon matching the visual language of GameButton.
///
/// Renders a stacked shadow-and-face pair: a dark "base" star offset
/// downward, with the face star on top — giving a raised, physical feel.
///
/// Defaults to gold with a glossy top highlight. Pass [color] and
/// [shadowColor] to customise the appearance.
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
          // Face star with glossy gradient (top layer)
          Positioned(
            top: 0,
            left: 0,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(Colors.white, color, 0.35)!,
                  color,
                ],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Icon(Icons.star_rounded, color: Colors.white, size: size),
            ),
          ),
        ],
      ),
    );
  }
}
