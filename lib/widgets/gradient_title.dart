import 'package:flutter/material.dart';
import 'package:lily_jigsaw_puzzle/core/app_theme.dart';

/// A title widget with a gradient fill and purple stroke outline,
/// used consistently across screens.
class GradientTitle extends StatelessWidget {
  const GradientTitle({
    required this.text,
    this.fontSize = 28.0,
    this.strokeWidth = 5.0,
    super.key,
  });

  final String text;
  final double fontSize;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = AppColors.deepPurple,
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD93D), AppColors.hotPink],
          ).createShader(b),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
