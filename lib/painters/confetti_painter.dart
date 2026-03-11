import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';

class ConfettiParticle {
  const ConfettiParticle({
    required this.x,
    required this.speed,
    required this.startDelay,
    required this.color,
    required this.size,
    required this.rotSpeed,
    required this.wobblePhase,
    required this.isRect,
  });

  final double x; // 0–1 horizontal start fraction
  final double speed; // rise-speed multiplier
  final double startDelay; // 0–1 fraction of total duration before appearing
  final Color color;
  final double size;
  final double rotSpeed; // full rotations over the animation
  final double wobblePhase; // horizontal wobble phase offset (radians)
  final bool isRect; // rectangle (true) or oval (false)
}

class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.particles, required this.animation})
      : super(repaint: animation);

  final List<ConfettiParticle> particles;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value; // 0.0 → 1.0 over 5 s
    for (final p in particles) {
      if (t < p.startDelay) continue;
      final pt = ((t - p.startDelay) / (1.0 - p.startDelay)).clamp(0.0, 1.0);

      // Fade out in the last 25 % of the animation.
      final alpha = pt > 0.75 ? (1.0 - pt) / 0.25 : 1.0;

      final px = p.x * size.width +
          sin(pt * 4 * pi + p.wobblePhase) * 28 +
          cos(pt * 2.5 * pi + p.wobblePhase * 0.7) * 14;
      // Shoot UP from the bottom
      final py = size.height + 28.0 - pt * p.speed * (size.height + 56);
      final rot = pt * 2 * pi * p.rotSpeed;

      canvas
        ..save()
        ..translate(px, py)
        ..rotate(rot);
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.45),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => true;
}
